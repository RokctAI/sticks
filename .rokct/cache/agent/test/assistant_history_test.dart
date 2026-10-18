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

// Assistant chat history per account (claimed in agent_sdk 1.0.4, built in
// 1.1.0), and the explicit in_lesson flag on every assistant call.

import 'dart:async';

import 'package:agent_sdk/src/common/domain/interface/agent_facade.dart';
import 'package:agent_sdk/src/common/infrastructure/database/drift_tables.dart';
import 'package:agent_sdk/src/common/infrastructure/models/response/assistant_response.dart';
import 'package:agent_sdk/src/common/infrastructure/services/assistant_history_store.dart';
import 'package:agent_sdk/src/common/infrastructure/services/assistant_service.dart';
// kUnownedOwner: the generated part names it in the owner column default.
import 'package:base_sdk/base_sdk.dart'
    show ApiResult, OwnerScope, kUnownedOwner;
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

part 'assistant_history_test.g.dart';

@DriftDatabase(tables: [AssistantHistoryTable])
class HistoryTestDatabase extends _$HistoryTestDatabase {
  HistoryTestDatabase(super.executor);

  @override
  int get schemaVersion => 21;
}

/// Records each call and answers from [answer] (null = a failure, as when
/// offline).
class _FakeFacade implements AgentFacade {
  _FakeFacade(this.answer);

  final String? answer;
  final List<Map<String, Object?>> calls = [];

  @override
  Future<ApiResult<AssistantQuestionResponse>> askAssistant({
    required String studentId,
    required String questionText,
    required String subtopicRef,
    bool inLesson = false,
  }) async {
    calls.add({
      'question': questionText,
      'subtopic_ref': subtopicRef,
      'in_lesson': inLesson,
    });
    final text = answer;
    if (text == null) {
      return const ApiResult.failure(error: 'offline', statusCode: 0);
    }
    return ApiResult.success(
      data: AssistantQuestionResponse.fromJson(
          {'status': 'success', 'response': text, 'intent': 'question'}),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('not used by this test');
}

ChatMessage _msg(String id, String text, {String sender = 'Student', int s = 0}) =>
    ChatMessage(
      id: id,
      text: text,
      sender: sender,
      timestamp: DateTime(2026, 10, 16, 9, 0, s),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late HistoryTestDatabase db;
  late AssistantHistoryStore store;
  String? account;

  setUp(() {
    db = HistoryTestDatabase(NativeDatabase.memory());
    store = AssistantHistoryStore(db);
    account = 'user-a';
    OwnerScope.instance.debugReset(withResolver: () => account);
  });

  tearDown(() async {
    await db.close();
    OwnerScope.instance.debugReset();
  });

  void signIn(String? who) {
    account = who;
    OwnerScope.instance.debugReset(withResolver: () => account);
  }

  group('AssistantHistoryStore', () {
    test('saves and loads the account\'s messages, oldest first', () async {
      await store.save(_msg('2', 'second', s: 2));
      await store.save(_msg('1', 'first', s: 1));
      final loaded = await store.load();
      expect(loaded.map((m) => m.text), ['first', 'second']);
      expect(loaded.first.timestamp, DateTime(2026, 10, 16, 9, 0, 1));
    });

    test('another account never sees this account\'s history', () async {
      await store.save(_msg('1', 'a asked'));
      signIn('user-b');
      expect(await store.load(), isEmpty);
      await store.save(_msg('1', 'b asked'));
      expect((await store.load()).map((m) => m.text), ['b asked']);
      signIn('user-a');
      expect((await store.load()).map((m) => m.text), ['a asked']);
    });

    test('nothing is saved with nobody signed in', () async {
      signIn(null);
      expect(await store.save(_msg('1', 'anon')), isFalse);
      expect(await db.select(db.assistantHistoryTable).get(), isEmpty);
    });

    test('sessions are kept apart', () async {
      await store.save(_msg('1', 'chat'));
      await store.save(_msg('2', 'lesson'), session: 'lesson-s1');
      expect((await store.load()).map((m) => m.text), ['chat']);
      expect((await store.load(session: 'lesson-s1')).map((m) => m.text),
          ['lesson']);
    });

    test('load keeps the latest messages when over the limit', () async {
      for (var i = 0; i < 5; i++) {
        await store.save(_msg('$i', 'm$i', s: i));
      }
      expect((await store.load(limit: 2)).map((m) => m.text), ['m3', 'm4']);
    });

    test('a broken database is not an error', () async {
      await db.customStatement('DROP TABLE assistant_history_table');
      expect(await store.save(_msg('1', 'x')), isFalse);
      expect(await store.load(), isEmpty);
    });
  });

  group('AssistantService', () {
    late StreamController<ChatMessage> incoming;
    late StreamController<ChatMessage> outgoing;

    setUp(() {
      incoming = StreamController<ChatMessage>.broadcast();
      outgoing = StreamController<ChatMessage>.broadcast();
    });

    tearDown(() async {
      await incoming.close();
      await outgoing.close();
    });

    test('saves the question on send and the answer on receive', () async {
      final service = AssistantService(
        incomingChat: incoming,
        outgoingChat: outgoing,
        serverBaseUrl: 'https://example.invalid',
        displayName: 'Mandy',
        facade: _FakeFacade('A fraction is part of a whole.'),
        history: store,
      );
      final reply = outgoing.stream.first;
      await service.processIncomingMessage(_msg('q1', 'What is a fraction?'));
      await reply;
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final history = await service.loadHistory();
      expect(history.map((m) => '${m.sender}: ${m.text}'), [
        'Student: What is a fraction?',
        'Mandy: A fraction is part of a whole.',
      ]);
      service.dispose();

      // The next account opens the assistant to an empty history.
      signIn('user-b');
      expect(await service.loadHistory(), isEmpty);
    });

    test('offline the question is still kept and nothing throws', () async {
      final service = AssistantService(
        incomingChat: incoming,
        outgoingChat: outgoing,
        serverBaseUrl: 'https://example.invalid',
        facade: _FakeFacade(null),
        history: store,
      );
      await service.processIncomingMessage(_msg('q1', 'Still there?'));
      expect((await service.loadHistory()).map((m) => m.text),
          ['Still there?']);
      service.dispose();
    });

    test('in_lesson is sent on every call: false outside, true in a lesson',
        () async {
      final facade = _FakeFacade('ok');
      final chat = AssistantService(
        incomingChat: incoming,
        outgoingChat: outgoing,
        serverBaseUrl: 'https://example.invalid',
        facade: facade,
        history: store,
      );
      await chat.processIncomingMessage(_msg('q1', 'outside'));
      chat.dispose();

      final lesson = AssistantService.forLesson(
        incomingChat: incoming,
        outgoingChat: outgoing,
        serverBaseUrl: 'https://example.invalid',
        lessonSessionId: 'lesson-s1',
        facade: facade,
        history: store,
      );
      // No subtopic yet: the flag alone tells the server it is a lesson.
      await lesson.processIncomingMessage(_msg('q2', 'inside'));
      lesson.dispose();

      expect(facade.calls.map((c) => c['in_lesson']), [false, true]);
      expect(facade.calls.last['subtopic_ref'], '');
      expect(lesson.historySession, 'lesson-s1');
      expect((await store.load(session: 'lesson-s1')).first.text, 'inside');
    });
  });
}
