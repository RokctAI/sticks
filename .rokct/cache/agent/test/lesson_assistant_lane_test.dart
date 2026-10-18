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

import 'dart:convert';
import 'dart:typed_data';

import 'package:agent_sdk/agent_sdk.dart';
import 'package:base_sdk/base_sdk.dart'
    show HttpService, getIt, kPlatformGatewayPath;
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// The lesson lane is what the host's lesson bridge
/// (lms templates/routes/lms_route_pages.dart, AgentLessonAssistantBridge)
/// asks through. These tests drive it over the REAL AgentRepository and a
/// scripted HTTP client, so they check the wire body itself: one POST to
/// the platform gateway, cmd `api.ask_assistant`, `in_lesson: true`.
class _FakeHttpService implements HttpService {
  _FakeHttpService(this.handle);

  final ResponseBody Function(RequestOptions options) handle;

  @override
  Dio client({bool requireAuth = false, bool routing = false}) =>
      Dio(BaseOptions(baseUrl: 'https://unit.test'))
        ..httpClientAdapter = _ScriptedAdapter(handle);
}

class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this.handle);

  final ResponseBody Function(RequestOptions options) handle;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
          Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async =>
      handle(options);

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object body) => ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

void main() {
  late List<RequestOptions> requests;
  late _FakeHttpService http;

  setUp(() {
    requests = [];
    http = _FakeHttpService((options) {
      requests.add(options);
      return _json({
        'message': {
          'status': 'success',
          'response': 'Factorise first, then set each bracket to zero.',
          'intent': 'question',
        },
      });
    });
    if (getIt.isRegistered<HttpService>()) getIt.unregister<HttpService>();
    getIt.registerSingleton<HttpService>(http);
  });

  tearDown(() {
    if (getIt.isRegistered<HttpService>()) getIt.unregister<HttpService>();
  });

  LessonAssistantLane lane() => LessonAssistantLane(
        lessonSessionId: 'RS-LESSON-1',
        serverBaseUrl: 'https://unit.test',
        displayName: 'Mandy',
        studentId: 'STU-1',
        facade: AgentRepository(http.client(requireAuth: true)),
      );

  test('a question asked before any subtopic sends in_lesson: true through '
      'the platform gateway', () async {
    final l = lane();
    final replies = <ChatMessage>[];
    final sub = l.replies.listen(replies.add);

    await l.ask('  how do I solve x^2 - 5x + 6 = 0?  ');
    await Future<void>.delayed(Duration.zero);

    expect(requests, hasLength(1));
    expect(requests.single.method, 'POST');
    expect(requests.single.path, kPlatformGatewayPath);
    expect(kPlatformGatewayPath, '/api/v1/method/rokct.platform.api');
    final body = requests.single.data as Map;
    expect(body['cmd'], 'api.ask_assistant');
    expect(body['payload'], {
      'student_id': 'STU-1',
      'question': 'how do I solve x^2 - 5x + 6 = 0?',
      'subtopic_ref': '',
      'in_lesson': true,
    });
    expect(l.service.inLesson, isTrue);
    expect(l.service.historySession, 'RS-LESSON-1');

    expect(replies.map((r) => r.text),
        ['Factorise first, then set each bracket to zero.']);
    expect(replies.single.sender, 'Mandy');

    await sub.cancel();
    l.dispose();
  });

  test('a known subtopic rides along as subtopic_ref, still in_lesson',
      () async {
    final l = lane();
    l.subtopicRef = 'maths.gr10.quadratics.factorising';
    // A ref-less lesson event never clears the known subtopic.
    l.subtopicRef = '  ';

    await l.ask('why does that work?');

    final payload = (requests.single.data as Map)['payload'] as Map;
    expect(payload['subtopic_ref'], 'maths.gr10.quadratics.factorising');
    expect(payload['in_lesson'], isTrue);
    expect(l.service.inLesson, isTrue);
    l.dispose();
  });

  test('after dispose the lane is closed and asks nothing', () async {
    final l = lane();
    l.dispose();

    expect(l.isOpen, isFalse);
    await l.ask('anyone there?');
    expect(requests, isEmpty);
  });
}
