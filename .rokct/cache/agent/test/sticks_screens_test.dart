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
import 'dart:io';

import 'package:agent_sdk/sticks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A gateway over the demo fixtures, the way a demo session answers: one
/// file per cmd, `$demo_select` by payload field, `$now_iso` offsets.
class FixtureGateway {
  final List<(String, Map<String, dynamic>)> sent = [];

  Future<dynamic> call(String cmd, Map<String, dynamic> payload) async {
    sent.add((cmd, payload));
    final f = File('templates/assets/demo/sticks/$cmd.json');
    dynamic v = jsonDecode(f.readAsStringSync());
    if (v is Map && v.containsKey(r'$demo_select')) {
      final sel = v[r'$demo_select'] as Map;
      final key = payload[(sel['by'] as String).split('.').last]?.toString();
      v = (sel['cases'] as Map)[key] ?? sel['default'];
    }
    return _time(v);
  }

  dynamic _time(dynamic v) {
    if (v is Map) return v.map((k, x) => MapEntry(k, _time(x)));
    if (v is List) return [for (final x in v) _time(x)];
    if (v is String && v.startsWith(r'$now_iso')) {
      final m = RegExp(r'([+-])(\d+)([dm])').firstMatch(v);
      var t = DateTime.now().toUtc();
      if (m != null) {
        final n = int.parse(m.group(2)!) * (m.group(1) == '-' ? -1 : 1);
        t = t.add(m.group(3) == 'd' ? Duration(days: n) : Duration(minutes: n));
      }
      return t.toIso8601String();
    }
    return v;
  }
}

/// The guided run has a spinner-free page now, but the intro animates, so
/// step the clock instead of settling.
Future<void> _go(WidgetTester t) async {
  for (var i = 0; i < 6; i++) {
    await t.pump(const Duration(milliseconds: 300));
  }
}

Future<FixtureGateway> _pump(WidgetTester t, {bool firstRun = false, ThemeMode mode = ThemeMode.light}) async {
  t.view.physicalSize = const Size(780, 1560);
  t.view.devicePixelRatio = 2;
  addTearDown(t.view.reset);
  final gw = FixtureGateway();
  await t.pumpWidget(SticksApp(data: StickRepository(gw.call), firstRun: firstRun, themeMode: mode));
  await _go(t);
  return gw;
}

void main() {
  group('Sticks screens', () {
    testWidgets('team lists the Sticks and opens one', (t) async {
      await _pump(t);
      expect(find.text('Your team'), findsOneWidget);
      await t.tap(find.textContaining('Tumi', findRichText: true).first);
      await _go(t);
      expect(find.text('Needs your approval'), findsOneWidget);
      expect(find.text('Build bid pack: Musina LM supply of ICT equipment'), findsOneWidget);
    });

    testWidgets('a plain task opens its detail', (t) async {
      await _pump(t);
      await t.tap(find.text('Tasks'));
      await _go(t);
      await t.tap(find.text('Chase invoice INV-0412 with Mokoena Builders'));
      await _go(t);
      expect(find.text('Priority'), findsOneWidget);
      expect(find.text('Open the ask'), findsOneWidget);
    });

    testWidgets('an email draft shows to, subject and body, and Send answers the confirm', (t) async {
      final gw = await _pump(t);
      await t.tap(find.textContaining('Asks').first);
      await _go(t);
      await t.tap(find.textContaining('Tumi drafted an email'));
      await _go(t);
      expect(find.text('bids@musina.example'), findsOneWidget);
      expect(find.text('Musina ICT bid pack'), findsOneWidget);
      expect(find.text("Don't send"), findsOneWidget);
      await t.tap(find.text('Send'));
      await _go(t);
      final answer = gw.sent.firstWhere((c) => c.$1 == 'api.sticks.answer_confirm');
      expect(answer.$2['confirm'], 'CONF-0015');
      expect(answer.$2['answer'], 'send');
    });

    testWidgets('Edit asks what should change and sends the note', (t) async {
      final gw = await _pump(t);
      await t.tap(find.textContaining('Asks').first);
      await _go(t);
      await t.tap(find.textContaining('Tumi drafted an email'));
      await _go(t);
      await t.ensureVisible(find.text('Edit'));
      await t.tap(find.text('Edit'));
      await _go(t);
      await t.enterText(find.byType(TextField), 'Add our CSD number');
      await t.ensureVisible(find.text('Send my changes'));
      await t.tap(find.text('Send my changes'));
      await _go(t);
      final answer = gw.sent.firstWhere((c) => c.$1 == 'api.sticks.answer_confirm');
      expect(answer.$2['answer'], 'edit');
      expect(answer.$2['note'], 'Add our CSD number');
    });

    testWidgets('a call draft shows the number and the purpose for approval', (t) async {
      await _pump(t);
      await t.tap(find.textContaining('Asks').first);
      await _go(t);
      await t.tap(find.textContaining('Kabelo wants to phone'));
      await _go(t);
      expect(find.text('+27 82 555 0147'), findsOneWidget);
      expect(find.textContaining('outstanding R 12 400.00'), findsOneWidget);
      expect(find.text('Make the call'), findsOneWidget);
    });

    testWidgets('a permission ask names who asked, who holds the data, and what', (t) async {
      await _pump(t);
      await t.tap(find.textContaining('Asks').first);
      await _go(t);
      await t.tap(find.textContaining('Kabelo asks Thandi'));
      await _go(t);
      expect(find.text('Tender pricing'), findsOneWidget);
      expect(find.text('Allow this once'), findsOneWidget);
      expect(find.text("Don't share"), findsOneWidget);
    });

    testWidgets('Between Sticks holds a sensitive request until the owner allows it', (t) async {
      await _pump(t);
      await t.tap(find.text('💬'));
      await _go(t);
      expect(find.text('Between Sticks'), findsOneWidget);
      expect(find.text('Waiting for your permission'), findsOneWidget);
      expect(find.textContaining('I need the tender pricing'), findsOneWidget);
    });

    testWidgets('the inbox replies to a message, and can hand back a file', (t) async {
      final gw = await _pump(t);
      await t.tap(find.text('✉'));
      await _go(t);
      await t.tap(find.text('Reply').first);
      await _go(t);
      await t.enterText(find.byType(TextField).first, 'Use the September statement');
      await t.tap(find.text('Hand back with a file'));
      await _go(t);
      await t.enterText(find.byType(TextField).last, 'Statement Sep');
      await t.tap(find.text('Send'));
      await _go(t);
      final sent = gw.sent.firstWhere((c) => c.$1 == 'api.sticks.send_message').$2;
      expect(sent['kind'], 'handoff');
      expect(sent['reply_to'], 'MSG-0031');
      expect((sent['attachments'] as List).single['label'], 'Statement Sep');
    });

    testWidgets("another Stick's inbox is read-only", (t) async {
      await _pump(t);
      await t.tap(find.text('✉'));
      await _go(t);
      await t.tap(find.text('Tumi').last);
      await _go(t);
      expect(find.text('Reply'), findsNothing);
    });

    testWidgets('calls show the script, the transcript and the amount', (t) async {
      await _pump(t);
      await t.tap(find.text('☎'));
      await _go(t);
      expect(find.text("Yes, that's me."), findsOneWidget);
      expect(find.textContaining('outstanding amount of R 12 400.00'), findsWidgets);
      await t.scrollUntilVisible(find.text('SCRIPT TO APPROVE'), 300);
      expect(find.text('SCRIPT TO APPROVE'), findsOneWidget);
    });

    testWidgets('first run plays the intro, then setup dresses the Stick and creates it', (t) async {
      final gw = await _pump(t, firstRun: true);
      await t.pump(const Duration(seconds: 5));
      expect(find.text('New Stick'), findsOneWidget);
      await t.enterText(find.byType(TextField), 'Lindiwe');
      await t.tap(find.text('Woman'));
      await t.tap(find.text('Accounts Clerk'));
      await t.pump();
      expect(find.textContaining('women get a dress'), findsOneWidget);
      expect(find.textContaining('Bank details (asks you first)'), findsOneWidget);
      await t.tap(find.text('Add to team'));
      await t.pump(const Duration(milliseconds: 500));
      final made = gw.sent.firstWhere((c) => c.$1 == 'api.sticks.create_stick').$2;
      expect(made['full_name'], 'Lindiwe');
      expect(made['gender'], 'Female');
      expect(made['role'], 'accounts_clerk');
      expect((made['look'] as Map).keys, containsAll(['skin', 'shirt', 'hair', 'hair_color']));
    });

    testWidgets('settings and the lock preview open', (t) async {
      await _pump(t);
      await t.tap(find.text('⚙'));
      await _go(t);
      expect(find.text('4 Sticks'), findsOneWidget);
      await t.tap(find.text('See how asks reach you'));
      await _go(t);
      expect(find.textContaining('asks'), findsWidgets);
    });

    testWidgets('renders in dark without errors', (t) async {
      await _pump(t, mode: ThemeMode.dark);
      expect(find.text('Your team'), findsOneWidget);
    });
  });

  group('Look assignment', () {
    test('a new Stick never repeats a colour while a free one exists', () {
      final team = <StickLook>[];
      final roles = <String>[];
      for (final n in ['a', 'b', 'c', 'd', 'e', 'f']) {
        final look = StickLooks.assign(gender: StickGender.woman, roleKey: n, roleLabel: 'Accounts Clerk', team: team, teamRoles: roles);
        expect(team.any((x) => x.clothes == look.clothes), isFalse);
        team.add(look);
        roles.add('Accounts Clerk');
      }
    });

    test('women get a dress and men a shirt', () {
      StickLook l(StickGender g) => StickLooks.assign(gender: g, roleKey: 'sales_rep', roleLabel: 'Sales Rep', team: const [], teamRoles: const []);
      expect(l(StickGender.woman).dress, isTrue);
      expect(l(StickGender.man).dress, isFalse);
    });

    test('hints from the server win over the fallback', () {
      final base = StickLooks.assign(gender: StickGender.man, roleKey: 'x', roleLabel: 'Tenders Officer', team: const [], teamRoles: const []);
      final look = StickLooks.fromHints({'shirt': '#6cbf4a', 'hair': 'cap'}, base);
      expect(look.clothes, const Color(0xFF6CBF4A));
      expect(look.hairStyle, 4);
    });
  });
}
