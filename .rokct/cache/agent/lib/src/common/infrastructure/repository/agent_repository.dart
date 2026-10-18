// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, version 3.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.


// compliance-ignore-file: flutter-http-timeout (Dio injected from base_sdk HttpService (see the DI), whose BaseOptions set connect/receive/send timeouts centrally)

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:base_sdk/base_sdk.dart';
import '../../domain/interface/agent_facade.dart';
import '../models/response/assistant_response.dart';

class AgentRepository implements AgentFacade {
  final Dio _client;

  static const _gateway = PlatformGateway();

  /// The backend shell app that serves the direct upload endpoint below —
  /// `rcore` for the composed backend. Mirrors lms_sdk's
  /// `HttpHomeworkRepository.uploadAppPrefix` (agent_sdk does not depend on
  /// lms_sdk, so the single override point is duplicated here); a host or
  /// test can override it at boot without an SDK release.
  static String uploadAppPrefix = 'rcore';

  /// Core's shared upload endpoint (`base.api.upload.upload_file` via the
  /// manifest alias). Stays a DIRECT dotted call, not a gateway cmd: the
  /// upload is multipart/form-data (raw file bytes), which cannot ride the
  /// gateway's JSON `{"cmd", "payload"}` envelope (gateway-paths class c).
  /// Derived per call from [uploadAppPrefix] so a boot-time override is
  /// always honoured.
  // bypasses gateway: multipart upload
  static String get uploadPath =>
      '/api/v1/method/$uploadAppPrefix.api.upload.upload_file';

  /// The homework endpoint, prefix-free for the universal gateway:
  /// `{app_name}.api.lms.submit_homework_question` per lms's manifest
  /// (`rlms.api.homework.submit_homework_question(question_text, subject,
  /// grade, attachments)`). The former `agent.api.submit_homework` target
  /// was never aliased in any manifest (fix-wave 2026-09-02, item A2).
  static const String submitCmd = 'api.lms.submit_homework_question';

  AgentRepository(this._client);

  /// The question text the server requires (`homework_rules.
  /// validate_submission` refuses an empty one). [questionText] wins when
  /// the caller has one; otherwise the lesson reference is the question,
  /// so a photos-only submission still names what it is about.
  @visibleForTesting
  static String resolveQuestionText({
    required String lessonId,
    String? questionText,
  }) {
    final text = questionText?.trim() ?? '';
    if (text.isNotEmpty) return text;
    return 'Homework for lesson $lessonId';
  }

  dynamic _unwrap(dynamic data) =>
      data is Map ? (data['message'] ?? data) : data;

  /// Two-step submission (the plan's (c)+(a) split): each photo goes up
  /// through core's multipart upload door and only the returned
  /// `file_url`s ride the JSON gateway call. The server binds the question
  /// to `frappe.session.user`, so [studentId] is not sent — the
  /// authenticated session is the student.
  @override
  Future<ApiResult<String>> submitHomework({
    required String studentId,
    required String lessonId,
    required List<String> filePaths,
    String? questionText,
  }) async {
    try {
      final attachments = <String>[];
      for (final path in filePaths) {
        attachments.add(await _uploadAttachment(path));
      }

      final data = await _gateway.tenant(submitCmd, {
        'question_text': resolveQuestionText(
          lessonId: lessonId,
          questionText: questionText,
        ),
        if (attachments.isNotEmpty) 'attachments': attachments,
      });

      // Frappe wraps whitelisted-method returns in {"message": ...};
      // tolerate an already-unwrapped body for overridden clients. The
      // method answers `{"id": <docname>, "status": "submitted"}`.
      final message = _unwrap(data);
      final id = message is Map ? message['id']?.toString() : null;
      if (id == null || id.isEmpty) {
        throw StateError(
            'Unexpected submit_homework_question response shape: $message');
      }
      return ApiResult.success(data: id);
    } catch (e) {
      return ApiResult.failure(
        error: NetworkHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  /// Field names per core/base/frappe/src/api/upload/upload.py: `file`
  /// (the part), optional `filename`, `is_private`. Private, same as
  /// lms_sdk's homework upload: Frappe serves /private/files/ to the
  /// uploading student and to System Manager operators only.
  Future<String> _uploadAttachment(String localFilePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(localFilePath),
      'is_private': 1,
    });
    final response = await _client.post(uploadPath, data: formData);
    final message = _unwrap(response.data);
    if (message is Map) {
      final url = message['file_url'];
      if (url is String && url.isNotEmpty) return url;
    }
    throw StateError('Unexpected upload_file response shape: $message');
  }

  @override
  Future<ApiResult<AssistantQuestionResponse>> askAssistant({
    required String studentId,
    required String questionText,
    required String subtopicRef,
    bool inLesson = false,
  }) async {
    try {
      // Universal platform gateway (same as the lms_sdk repositories):
      // cmd is the dotted method with the leading app segment dropped
      // (`agent.api.ask_assistant` -> `api.ask_assistant`, see
      // agent/frappe/manifest.json).
      final data = await _gateway.tenant('api.ask_assistant', {
        'student_id': studentId,
        'question': questionText,
        'subtopic_ref': subtopicRef,
        // Always sent, true or false: the server's in-lesson plan gate
        // fails closed on it, with or without a subtopic.
        'in_lesson': inLesson,
      });

      // Frappe wraps whitelisted-method returns in {"message": ...};
      // tolerate an already-unwrapped body for overridden clients.
      final message = data is Map ? (data['message'] ?? data) : data;
      return ApiResult.success(
        data: AssistantQuestionResponse.fromJson(
          Map<String, dynamic>.from(message as Map),
        ),
      );
    } catch (e) {
      return ApiResult.failure(
        error: NetworkHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }
}
