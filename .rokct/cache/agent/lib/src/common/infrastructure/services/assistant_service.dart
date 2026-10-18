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

import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/services/telemetry.dart';
import 'package:get_it/get_it.dart';

import '../../di/agent_di.dart';
import '../../domain/interface/agent_facade.dart';
import 'assistant_history_store.dart';

class ChatMessage {
  final String id;
  final String text;
  final String sender;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
  });
}

/// An assistant failure surfaced to the UI as an error — never disguised as
/// a chat answer. [message] carries the server's own reason (e.g. the
/// backend's "Assistant Not Configured" text) when one arrived — that detail
/// is for diagnostics/telemetry only: student-facing surfaces must not
/// render it (admin conditions like a missing key are not for students).
class AssistantChatError {
  final String message;
  final int? statusCode;

  AssistantChatError({required this.message, this.statusCode});
}

/// Chat pipeline for the AI assistant.
///
/// Every question is answered by the real backend
/// (`agent.api.ask_assistant`, via [AgentFacade.askAssistant]) — the server
/// owns the LLM call and its credential config. There is no client-side
/// canned-answer path: when the backend fails (including the server's
/// honest "Assistant Not Configured" error), the failure is emitted on
/// [errors] for the host UI to render as an error, and nothing is injected
/// into the chat stream.
///
/// The assistant's display name is configurable per host app (each product
/// brands its own persona) — pass it via [displayName]; it is used as the
/// `sender` on generated responses.
class AssistantService {
  final StreamController<ChatMessage> incomingChat;
  final StreamController<ChatMessage> outgoingChat;
  final String serverBaseUrl;

  /// Product-facing name of the assistant persona, injected by the host app.
  final String displayName;

  /// Optional active-lesson subtopic reference forwarded to the backend so
  /// the assistant stays scoped to the lesson. Empty when the host has no
  /// lesson context.
  final String subtopicRef;

  /// Client-side student identifier forwarded for wire compatibility; the
  /// backend derives the acting student from the authenticated session and
  /// never trusts this field.
  final String studentId;

  /// Whether this service answers from INSIDE a lesson (a host's lesson
  /// assistant bridge). Sent as `in_lesson` on every question, so the
  /// server's plan gate fails closed in a lesson even before the first
  /// subtopic, when [subtopicRef] is still empty. The standalone chat page
  /// leaves it false.
  final bool inLesson;

  /// The transcript this conversation is saved under in the account's
  /// assistant history: [kAssistantChatHistorySession] for the standalone
  /// chat; a lesson bridge passes its lesson session id.
  final String historySession;

  final AgentFacade? _injectedFacade;
  final AssistantHistoryStore? _injectedHistory;

  final StreamController<AssistantChatError> _errors =
      StreamController<AssistantChatError>.broadcast();

  /// Assistant failures (network, server errors, assistant-not-configured).
  /// Hosts listen and surface these as errors — see the assistant chat page
  /// template's error banner.
  Stream<AssistantChatError> get errors => _errors.stream;

  AssistantService({
    required this.incomingChat,
    required this.outgoingChat,
    required this.serverBaseUrl,
    this.displayName = 'Assistant',
    this.subtopicRef = '',
    this.studentId = '',
    this.inLesson = false,
    this.historySession = kAssistantChatHistorySession,
    AgentFacade? facade,
    AssistantHistoryStore? history,
  })  : _injectedFacade = facade,
        _injectedHistory = history {
    _bind();
  }

  /// The service for a lesson's private lane: every question carries
  /// `in_lesson: true`, and the transcript is kept under [lessonSessionId].
  /// Host lesson bridges build their service with this.
  factory AssistantService.forLesson({
    required StreamController<ChatMessage> incomingChat,
    required StreamController<ChatMessage> outgoingChat,
    required String serverBaseUrl,
    required String lessonSessionId,
    String displayName = 'Assistant',
    String subtopicRef = '',
    String studentId = '',
    AgentFacade? facade,
    AssistantHistoryStore? history,
  }) =>
      AssistantService(
        incomingChat: incomingChat,
        outgoingChat: outgoingChat,
        serverBaseUrl: serverBaseUrl,
        displayName: displayName,
        subtopicRef: subtopicRef,
        studentId: studentId,
        inLesson: true,
        historySession: lessonSessionId,
        facade: facade,
        history: history,
      );

  /// The authorized backend facade. Injected in tests; otherwise resolved
  /// from GetIt with an on-demand register, the same lazy-DI pattern the
  /// lms_sdk route adapters use.
  AgentFacade get _facade {
    final injected = _injectedFacade;
    if (injected != null) return injected;
    final getIt = GetIt.instance;
    if (!getIt.isRegistered<AgentFacade>()) {
      AgentSdkDependencies.register(getIt);
    }
    return getIt.get<AgentFacade>();
  }

  /// The account's assistant history: injected in tests, else the store
  /// agent_sdk's DI registered. Null (no history kept) when neither exists.
  AssistantHistoryStore? get _history {
    final injected = _injectedHistory;
    if (injected != null) return injected;
    final getIt = GetIt.instance;
    return getIt.isRegistered<AssistantHistoryStore>()
        ? getIt.get<AssistantHistoryStore>()
        : null;
  }

  /// The signed-in account's saved conversation, oldest first, for the
  /// host to show when the assistant opens. Empty when there is none, no
  /// history store, or it cannot be read - never an error, online or
  /// offline. Another account's messages are never returned.
  Future<List<ChatMessage>> loadHistory() async {
    final history = _history;
    if (history == null) return const <ChatMessage>[];
    return history.load(session: historySession);
  }

  /// Saves [message] to the account's history. Best effort: a failure is
  /// swallowed by the store, so the chat never fails because of it.
  Future<void> _remember(ChatMessage message) async {
    final history = _history;
    if (history == null) return;
    await history.save(message, session: historySession);
  }

  StreamSubscription<ChatMessage>? _incomingSub;

  void _bind() {
    _incomingSub = incomingChat.stream.listen((message) async {
      await processIncomingMessage(message);
    });
  }

  /// Sends an incoming student message to the real assistant backend and
  /// injects the server's answer into [outgoingChat]. On failure the
  /// server's error is emitted on [errors] — never a fabricated answer.
  Future<void> processIncomingMessage(ChatMessage message) async {
    // Saved on send, before the answer: the question is the learner's own
    // and stays in their history even if no answer comes (offline).
    await _remember(message);
    final result = await _facade.askAssistant(
      studentId: studentId,
      questionText: message.text,
      subtopicRef: subtopicRef,
      inLesson: inLesson,
    );

    result.when(
      success: (data) => _injectResponse(data.responseText),
      failure: (error, statusCode) {
        final message = error?.toString() ?? 'Assistant request failed.';
        // Admin/ops visibility goes through the one telemetry door
        // (base_sdk TelemetryClient, ADR-006): the server's own reason —
        // "Assistant Not Configured" (admin action needed) vs a provider
        // outage — reaches the backend error pipeline verbatim. Students
        // never see this detail; the chat page renders only a friendly
        // persona-named banner. Fire-and-forget; the client swallows its
        // own delivery failures.
        unawaited(
          TelemetryClient.I.logError(
            type: 'assistant_chat_failed',
            context: {
              'assistant': displayName,
              'status_code': '${statusCode ?? ''}',
              'server_message': message,
              'subtopic_ref': subtopicRef,
              'in_lesson': '$inLesson',
            },
          ),
        );
        if (_errors.isClosed) return;
        _errors.add(
          AssistantChatError(message: message, statusCode: statusCode),
        );
      },
    );
  }

  void _injectResponse(String text) {
    final now = DateTime.now();
    final responseMsg = ChatMessage(
      // Microseconds, so a reply can never share an id (and so a history
      // row) with the question the page minted in milliseconds.
      id: '${now.microsecondsSinceEpoch}',
      text: text,
      sender: displayName,
      timestamp: now,
    );
    // Saved on receive, whether or not the page is still listening.
    unawaited(_remember(responseMsg));
    // The host may have closed its controller while the answer was in
    // flight; never throw "add after close" from a late reply.
    if (outgoingChat.isClosed) return;
    outgoingChat.add(responseMsg);
  }

  /// Stops listening and closes what this service owns ([errors]). The
  /// chat controllers belong to whoever passed them in (the host's comms
  /// transport), so they are NOT closed here: closing them broke every
  /// other listener and any later service bound to the same controllers.
  void dispose() {
    _incomingSub?.cancel();
    _incomingSub = null;
    _errors.close();
  }
}
