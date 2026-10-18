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


import 'dart:async';
import 'package:base_sdk/base_sdk.dart';

import '../../infrastructure/models/response/assistant_response.dart';

abstract class AgentFacade {
  /// Submits homework photos for help: uploads each of [filePaths] through
  /// core's `api.upload.upload_file` door, then files an lms homework
  /// question (`api.lms.submit_homework_question`) carrying the returned
  /// file URLs. Resolves to the new question's id. [questionText] is the
  /// student's own words when they typed any; a photos-only submission is
  /// labelled with [lessonId]. [studentId] is kept for the call shape only
  /// — the server binds the question to the authenticated session.
  Future<ApiResult<String>> submitHomework({
    required String studentId,
    required String lessonId,
    required List<String> filePaths,
    String? questionText,
  });

  /// Asks the real backend assistant (`agent.api.ask_assistant`) a question.
  /// The server answers with an LLM response or fails with its own error
  /// (e.g. "Assistant Not Configured") — there is no client-side fallback
  /// answer.
  ///
  /// [inLesson] is sent explicitly on every call (`in_lesson`): true when
  /// the question is asked from inside a lesson, where the server's plan
  /// gate fails closed. It does not depend on [subtopicRef], which is empty
  /// before a lesson's first subtopic.
  Future<ApiResult<AssistantQuestionResponse>> askAssistant({
    required String studentId,
    required String questionText,
    required String subtopicRef,
    bool inLesson = false,
  });
}
