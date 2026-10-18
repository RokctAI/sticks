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


library agent_sdk;

export 'src/common/infrastructure/models/request/ai_translation_request.dart';
export 'src/common/infrastructure/models/response/ai_translation_response.dart';
export 'src/common/infrastructure/models/data/assistant_models.dart';
export 'src/common/infrastructure/models/request/assistant_request.dart';
export 'src/common/infrastructure/models/response/assistant_response.dart';

export 'src/common/infrastructure/services/assistant_service.dart';
export 'src/common/infrastructure/services/assistant_history_store.dart';
export 'src/common/infrastructure/services/lesson_assistant_lane.dart';

export 'src/common/domain/interface/agent_facade.dart';
export 'src/common/domain/interface/ai_translation_provider.dart';
export 'src/common/infrastructure/repository/agent_repository.dart';
export 'src/common/infrastructure/database/drift_tables.dart';
export 'src/common/di/agent_di.dart';

import 'dart:async';
import 'src/common/infrastructure/services/assistant_service.dart';

class AgentConfig {
  final String studentId;
  final String deviceToken;
  final String serverBaseUrl;

  /// Product-facing name of the assistant persona shown to users. Sourced
  /// from the host app's branding config — the SDK never hardcodes a
  /// product-specific character name.
  final String assistantDisplayName;

  // NOTE (lms_sdk carve-out, 2026-07): break-bridge and office-hours
  // orchestration (and their localCacheDb/backendSynthesizeFn/usersSdk/
  // subscriptionStatusProvider/createProductivityTask wiring) moved to
  // lms_sdk, which owns the lesson/LMS domain. agent_sdk keeps the generic
  // assistant/chat pipeline only.
  AgentConfig({
    required this.studentId,
    required this.deviceToken,
    required this.serverBaseUrl,
    this.assistantDisplayName = 'Assistant',
  });
}

abstract class AgentSDK {
  // Initialize with student profile and system config
  Future<void> init(AgentConfig config);

  // Hook AgentSDK into CommsSDK stream controllers
  void bindChatControllers(StreamController<ChatMessage> incomingChat, StreamController<ChatMessage> outgoingChat);

  // Submit homework for validation loop
  Future<String> submitHomework(String lessonId, List<String> filePaths);

  // Cleanup references
  void dispose();
}

class AgentSDKImpl implements AgentSDK {
  late AgentConfig _config;
  AssistantService? _assistantService;

  @override
  Future<void> init(AgentConfig config) async {
    _config = config;
  }

  @override
  void bindChatControllers(StreamController<ChatMessage> incomingChat, StreamController<ChatMessage> outgoingChat) {
    _assistantService = AssistantService(
      incomingChat: incomingChat,
      outgoingChat: outgoingChat,
      serverBaseUrl: _config.serverBaseUrl,
      displayName: _config.assistantDisplayName,
    );
  }

  @override
  Future<String> submitHomework(String lessonId, List<String> filePaths) async {
    // Decision #47: no fabricated success. This used to return a hardcoded
    // contract id, which read as a completed submission that never
    // happened. The real async homework flow (product log #42 item 1:
    // send-and-wait + guide-don't-solve) lives in the LMS domain —
    // `rlms.api.homework.submit_homework_question` via lms_sdk's
    // HomeworkHelpRepository — and takes the student's question text, not
    // local file paths, so this facade cannot honestly fulfil the call.
    // For the photo-upload path, use AgentRepository.submitHomework, which
    // uploads through core's upload_file door and files the same
    // submit_homework_question, reporting the server's real result.
    throw UnsupportedError(
      'AgentSDKImpl.submitHomework is not wired to a backend. Use lms_sdk\'s '
      'HomeworkHelpRepository (rlms.api.homework) for homework help, or '
      'AgentRepository.submitHomework for the file-upload contract.',
    );
  }

  @override
  void dispose() {
    _assistantService?.dispose();
  }
}
