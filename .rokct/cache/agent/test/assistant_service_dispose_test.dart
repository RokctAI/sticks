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

import 'package:agent_sdk/agent_sdk.dart';
import 'package:flutter_test/flutter_test.dart';

/// Stands in for the backend facade; the dispose contract never calls it.
class _UnusedFacade implements AgentFacade {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('not used by this test');
}

/// AssistantService.dispose must not close the chat controllers it was
/// handed: they belong to the host's comms transport, and closing them
/// broke every other listener and any later service bound to them.
void main() {
  test('dispose leaves the host-owned chat controllers open', () async {
    final incoming = StreamController<ChatMessage>.broadcast();
    final outgoing = StreamController<ChatMessage>.broadcast();
    final service = AssistantService(
      incomingChat: incoming,
      outgoingChat: outgoing,
      serverBaseUrl: 'https://example.invalid',
      facade: _UnusedFacade(),
    );

    service.dispose();

    expect(incoming.isClosed, isFalse);
    expect(outgoing.isClosed, isFalse);
    // The service stopped listening: a message after dispose reaches no
    // backend call (the facade would throw if it were asked).
    incoming.add(ChatMessage(
      id: '1',
      text: 'hello',
      sender: 'Student',
      timestamp: DateTime(2026, 10, 13),
    ));
    await Future<void>.delayed(Duration.zero);

    await incoming.close();
    await outgoing.close();
  });
}
