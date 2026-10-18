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

import '../../domain/interface/agent_facade.dart';
import 'assistant_history_store.dart';
import 'assistant_service.dart';

/// The agent side of a lesson's private assistant lane.
///
/// A host's lesson assistant bridge (lms_sdk's `LessonAssistantBridge`,
/// implemented in the host's composed lesson route, ADR-005) wraps this:
/// agent_sdk never imports lms_sdk, so the lane speaks agent_sdk's own
/// [ChatMessage] and the host maps it onto the lesson's message type.
///
/// Every question goes through [AssistantService.forLesson], so it carries
/// `in_lesson: true` and the current [subtopicRef] (empty until the lesson
/// reports one) to `api.ask_assistant` on the platform gateway, and the
/// transcript is kept under the lesson's session id.
class LessonAssistantLane {
  /// The lesson session this lane belongs to; also the history session.
  final String lessonSessionId;
  final String serverBaseUrl;
  final String displayName;
  final String studentId;

  final AgentFacade? _facade;
  final AssistantHistoryStore? _history;

  // Owned by the lane (not a host transport), so closed on dispose.
  final StreamController<ChatMessage> _incoming =
      StreamController<ChatMessage>.broadcast();
  final StreamController<ChatMessage> _outgoing =
      StreamController<ChatMessage>.broadcast();
  final StreamController<AssistantChatError> _errors =
      StreamController<AssistantChatError>.broadcast();

  late AssistantService _service;
  StreamSubscription<AssistantChatError>? _errorSub;
  String _subtopicRef;
  bool _disposed = false;

  LessonAssistantLane({
    required this.lessonSessionId,
    required this.serverBaseUrl,
    this.displayName = 'Assistant',
    this.studentId = '',
    String subtopicRef = '',
    AgentFacade? facade,
    AssistantHistoryStore? history,
  })  : _facade = facade,
        _history = history,
        _subtopicRef = subtopicRef {
    _service = _build();
  }

  /// The assistant's answers, in arrival order.
  Stream<ChatMessage> get replies => _outgoing.stream;

  /// Failures of a question (network, server, not configured). The server's
  /// detail is for diagnostics only; AssistantService already logs it to
  /// telemetry. Student-facing hosts show their own friendly text.
  Stream<AssistantChatError> get errors => _errors.stream;

  /// The service questions currently go through. Exposed for tests.
  AssistantService get service => _service;

  /// Whether the lane can still take questions.
  bool get isOpen => !_disposed;

  /// The subtopic the lesson is in (or last reported), sent as
  /// `subtopic_ref`. Empty when the lesson has not reported one yet.
  String get subtopicRef => _subtopicRef;

  /// Points later questions at [ref]. A blank ref is ignored, so a lesson
  /// event without a ref never clears a known subtopic.
  set subtopicRef(String ref) {
    final next = ref.trim();
    if (_disposed || next.isEmpty || next == _subtopicRef) return;
    _subtopicRef = next;
    // AssistantService fixes its subtopic at construction: rebuild it on
    // the same lane-owned controllers.
    _service.dispose();
    _errorSub?.cancel();
    _service = _build();
  }

  AssistantService _build() {
    final service = AssistantService.forLesson(
      incomingChat: _incoming,
      outgoingChat: _outgoing,
      serverBaseUrl: serverBaseUrl,
      lessonSessionId: lessonSessionId,
      displayName: displayName,
      subtopicRef: _subtopicRef,
      studentId: studentId,
      facade: _facade,
      history: _history,
    );
    _errorSub = service.errors.listen((e) {
      if (!_errors.isClosed) _errors.add(e);
    });
    return service;
  }

  /// Asks [text]. Completes when the answer has arrived on [replies], or
  /// the failure on [errors]; never throws for a backend failure.
  Future<void> ask(String text) async {
    final trimmed = text.trim();
    if (_disposed || trimmed.isEmpty) return;
    final now = DateTime.now();
    await _service.processIncomingMessage(ChatMessage(
      id: '${now.millisecondsSinceEpoch}',
      text: trimmed,
      sender: 'Student',
      timestamp: now,
    ));
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _service.dispose();
    _errorSub?.cancel();
    _incoming.close();
    _outgoing.close();
    _errors.close();
  }
}
