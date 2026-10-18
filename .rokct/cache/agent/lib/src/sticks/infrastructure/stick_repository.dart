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

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Color;

import '../domain/stick_data.dart';
import '../domain/stick_looks.dart';
import '../domain/stick_models.dart';

class _Changes extends ChangeNotifier {
  void fire() => notifyListeners();
}

/// Sends one gateway cmd (`api.sticks.<method>`) and returns the reply. A
/// host passes `const PlatformGateway().tenant` from base_sdk; tests pass a
/// function over the demo fixtures.
typedef StickGateway = Future<dynamic> Function(String cmd, Map<String, dynamic> payload);

/// [StickData] over the Sticks call contract. Replies are the value inside
/// Frappe's `message` envelope; an already-unwrapped body is tolerated, as
/// the other agent repositories do. A failure is thrown, never faked: the
/// screens show a retry line.
class StickRepository implements StickData {
  final StickGateway _call;
  final _Changes _changes = _Changes();

  StickRepository(this._call);

  @override
  Listenable get changes => _changes;

  void _notify() => _changes.fire();

  Future<Map<String, dynamic>> _cmd(String method, [Map<String, dynamic> payload = const {}]) async {
    final data = await _call('api.sticks.$method', payload);
    final message = data is Map ? (data['message'] ?? data) : data;
    if (message is! Map) {
      throw StateError('Unexpected api.sticks.$method reply: $message');
    }
    return Map<String, dynamic>.from(message);
  }

  static DateTime? _time(Object? v) => v is String ? DateTime.tryParse(v)?.toLocal() : null;

  static List<T> _list<T>(Object? v, T Function(Map<String, dynamic>) f) => [
        for (final e in (v is List ? v : const []))
          if (e is Map) f(Map<String, dynamic>.from(e)),
      ];

  // ---- sticks ---------------------------------------------------------

  @override
  Future<List<Stick>> sticks() async {
    final raw = (await _cmd('list_sticks'))['sticks'];
    final looks = <StickLook>[];
    final roles = <String>[];
    final out = <Stick>[];
    for (final m in _list(raw, (m) => m)) {
      final role = (m['role'] ?? '').toString();
      final state = switch (m['state']) {
        'waiting' => StickStatus.waiting,
        'off' => StickStatus.off,
        _ => StickStatus.working,
      };
      final id = m['id'].toString();
      final gender = _hash(id).isEven ? StickGender.woman : StickGender.man;
      final base = StickLooks.assign(
        gender: gender,
        roleKey: id,
        roleLabel: role,
        team: looks,
        teamRoles: roles,
      );
      final look = StickLooks.fromHints(m['look'] is Map ? Map<String, dynamic>.from(m['look']) : null, base);
      looks.add(look);
      roles.add(role);
      out.add(Stick(
        id: id,
        name: (m['name'] ?? id).toString(),
        role: role,
        look: look,
        accent: look.clothes,
        status: state,
        mood: switch (state) {
          StickStatus.waiting => StickMood.worried,
          StickStatus.off => StickMood.neutral,
          StickStatus.working => StickMood.happy,
        },
        statusText: (m['status_text'] ?? '').toString(),
        hours: (m['hours'] ?? '').toString(),
        backAt: _time(m['back_at']),
        owns: [for (final o in (m['owns'] is List ? m['owns'] as List : const [])) o.toString()],
        openConfirms: (m['open_confirms'] as num?)?.toInt() ?? 0,
      ));
    }
    return out;
  }

  static int _hash(String s) {
    var h = 7;
    for (final c in s.codeUnits) {
      h = (h * 31 + c) & 0xFFFFFFFF;
    }
    return h;
  }

  @override
  Future<Stick?> stick(String id) async =>
      (await sticks()).where((s) => s.id == id).firstOrNull;

  // ---- tasks ----------------------------------------------------------

  @override
  Future<List<StickTask>> tasks({String? stickId}) async {
    final out = <StickTask>[];
    String? cursor;
    do {
      final r = await _cmd('get_task_feed', {'stick': stickId, 'status': null, 'cursor': cursor});
      out.addAll(_list(r['tasks'], (t) => StickTask(
            id: t['id'].toString(),
            stickId: (t['stick'] ?? '').toString(),
            title: (t['title'] ?? '').toString(),
            state: switch (t['status']) {
              'done' => TaskState.done,
              'in_progress' => TaskState.inProgress,
              _ => TaskState.todo,
            },
            priority: (t['priority'] ?? 'normal').toString(),
            due: _time(t['due']),
            note: t['note'] as String?,
            confirmId: t['confirm'] as String?,
          )));
      cursor = r['next_cursor'] as String?;
    } while (cursor != null);
    return out;
  }

  // ---- confirms -------------------------------------------------------

  @override
  Future<StickConfirm?> confirm(String stickId) async {
    final c = (await _cmd('get_confirm', {'stick': stickId}))['confirm'];
    if (c is! Map) return null;
    final m = Map<String, dynamic>.from(c);
    final d = m['draft'];
    final data = m['data'];
    return StickConfirm(
      id: m['id'].toString(),
      kind: switch (m['kind']) {
        'permission' => ConfirmKind.permission,
        'draft' => ConfirmKind.draft,
        _ => ConfirmKind.confirm,
      },
      stickId: (m['stick'] ?? stickId).toString(),
      requesterId: m['requester'] as String?,
      dataLabel: data is Map ? data['label'] as String? : null,
      messageId: (m['request'] ?? m['message']) as String?,
      taskId: m['task'] as String?,
      question: (m['question'] ?? '').toString(),
      deadline: _time(m['deadline']),
      options: _list(m['options'], (o) => ConfirmOption(
            o['key'].toString(),
            (o['label'] ?? o['key']).toString(),
            primary: o['kind'] == 'primary',
          )),
      draft: d is Map
          ? StickDraft(
              channel: (d['channel'] ?? 'email').toString(),
              to: [for (final t in (d['to'] is List ? d['to'] as List : const [])) t.toString()],
              subject: (d['subject'] ?? '').toString(),
              body: (d['body'] ?? '').toString(),
              attachments: _list(d['attachments'], (a) => (a['name'] ?? '').toString()),
            )
          : null,
    );
  }

  @override
  Future<ConfirmAnswered> answerConfirm(String confirmId, String key, {String? note}) async {
    final r = await _cmd('answer_confirm', {'confirm': confirmId, 'answer': key, 'note': note});
    _notify();
    return ConfirmAnswered(already: r['status'] == 'already_answered', answer: (r['answer'] ?? key).toString());
  }

  // ---- messages -------------------------------------------------------

  @override
  Future<List<StickMessage>> inbox(String forWho, {bool unreadOnly = false}) async {
    final out = <StickMessage>[];
    String? cursor;
    do {
      final r = await _cmd('list_inbox', {'for': forWho, 'status': unreadOnly ? 'unread' : 'all', 'cursor': cursor});
      out.addAll(_list(r['messages'], (m) => StickMessage(
            id: m['id'].toString(),
            fromId: (m['from'] ?? '').toString(),
            toId: (m['to'] ?? '').toString(),
            kind: switch (m['kind']) {
              'handoff' => MessageKind.handoff,
              'note' => MessageKind.note,
              _ => MessageKind.ask,
            },
            body: (m['body'] ?? '').toString(),
            sentAt: _time(m['sent_at']),
            read: m['read'] != false,
            sensitive: m['sensitivity'] == 'sensitive',
            status: _status(m['status']),
            confirmId: m['confirm'] as String?,
            replyTo: m['reply_to'] as String?,
            taskId: m['task'] as String?,
            attachments: _list(m['attachments'], (a) => MessageAttachment(
                  (a['ref'] ?? '').toString(),
                  (a['label'] ?? a['ref'] ?? '').toString(),
                )),
          )));
      cursor = r['next_cursor'] as String?;
    } while (cursor != null);
    return out;
  }

  static MessageStatus _status(Object? v) => switch (v) {
        'held' => MessageStatus.held,
        'awaiting_permission' => MessageStatus.awaitingPermission,
        'declined' => MessageStatus.declined,
        _ => MessageStatus.delivered,
      };

  @override
  Future<MessageStatus> sendMessage({
    required String to,
    required MessageKind kind,
    required String body,
    String? replyTo,
    String? taskId,
    List<MessageAttachment> attachments = const [],
  }) async {
    final r = await _cmd('send_message', {
      'to': to,
      'kind': kind.name,
      'body': body,
      'needs': null,
      'task': taskId,
      'reply_to': replyTo,
      'attachments': [for (final a in attachments) {'type': 'file', 'ref': a.ref, 'label': a.label}],
    });
    _notify();
    final m = r['message'];
    return _status(m is Map ? m['status'] : null);
  }

  // ---- setup ----------------------------------------------------------

  @override
  Future<List<RoleOption>> roles() async {
    final r = await _cmd('list_roles');
    return _list(r['roles'], (m) => RoleOption(
          m['key'].toString(),
          (m['label'] ?? m['key']).toString(),
          owns: [for (final o in (m['owns'] is List ? m['owns'] as List : const [])) o.toString()],
          holds: _list(m['holds'], (h) => RoleHold(
                h['key'].toString(),
                (h['label'] ?? h['key']).toString(),
                sensitive: h['sensitive'] == true,
              )),
        ));
  }

  @override
  Future<Stick> createStick({
    required String fullName,
    required bool woman,
    required String roleKey,
    String? hours,
    StickLook? look,
  }) async {
    String hex(Color c) => '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
    const hairNames = {-1: 'none', 1: 'ponytail', 4: 'cap', 2: 'bob'};
    await _cmd('create_stick', {
      'full_name': fullName,
      'gender': woman ? 'Female' : 'Male',
      'role': roleKey,
      if (hours != null) 'hours': hours,
      if (look != null)
        'look': {
          'skin': hex(look.skin),
          'shirt': hex(look.clothes),
          'hair': hairNames[look.hairStyle] ?? 'bob',
          'hair_color': hex(look.hair),
        },
    });
    _notify();
    return (await sticks()).firstWhere((s) => s.name == fullName,
        orElse: () => throw StateError('Created Stick $fullName is not on the team'));
  }

  // ---- calls ----------------------------------------------------------

  @override
  Future<List<StickCall>> calls({String? stickId}) async {
    List<CallLine> lines(Object? v) => _list(v, (l) => CallLine(l['who'] == 'stick', (l['text'] ?? '').toString()));
    final out = <StickCall>[];
    String? cursor;
    do {
      final r = await _cmd('list_calls', {'stick': stickId, 'cursor': cursor});
      out.addAll(_calls(r, lines));
      cursor = r['next_cursor'] as String?;
    } while (cursor != null);
    return out;
  }

  List<StickCall> _calls(Map<String, dynamic> r, List<CallLine> Function(Object?) lines) {
    return _list(r['calls'], (c) => StickCall(
          id: c['id'].toString(),
          stickId: (c['stick'] ?? '').toString(),
          who: (c['who'] ?? '').toString(),
          number: (c['number'] ?? '').toString(),
          purpose: (c['purpose'] ?? '').toString(),
          status: (c['status'] ?? '').toString(),
          outcome: c['outcome'] as String?,
          at: _time(c['at']),
          script: lines(c['script']),
          transcript: lines(c['transcript']),
        ));
  }

  // ---- worked out here ------------------------------------------------

  @override
  Future<List<ReportRow>> weeklyReport() async {
    final all = await tasks();
    final by = <String, int>{};
    for (final t in all.where((t) => t.state == TaskState.done)) {
      by[t.stickId] = (by[t.stickId] ?? 0) + 1;
    }
    return [for (final s in await sticks()) ReportRow(s.id, by[s.id] ?? 0)];
  }

  @override
  Future<List<StickNotification>> notifications() async {
    final out = <StickNotification>[];
    for (final s in await sticks()) {
      if (s.openConfirms == 0) continue;
      final c = await confirm(s.id);
      if (c != null) out.add(StickNotification(s.id, '${s.name} asks', c.question, c.deadline));
    }
    for (final m in (await inbox('owner', unreadOnly: true)).take(3)) {
      out.add(StickNotification(m.fromId, 'Message', m.body, m.sentAt));
    }
    return out;
  }
}
