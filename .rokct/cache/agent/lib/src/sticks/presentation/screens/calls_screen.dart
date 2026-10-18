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

import 'package:flutter/material.dart';

import '../../domain/stick_models.dart';
import '../sticks_scope.dart';
import '../widgets.dart';

/// Calls the Sticks make for you: who is called, why, the script you
/// approved and what was said. A call is an outward action, so it reaches
/// the phone only after the draft card (number and purpose) is approved.
class CallsScreen extends StatelessWidget {
  const CallsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = SticksScope.of(context);
    final p = StickPalette.of(context);
    return SticksFuture<(List<StickCall>, List<Stick>)>(
      future: Future.wait([s.data.calls(), s.data.sticks()])
          .then((v) => (v[0] as List<StickCall>, v[1] as List<Stick>)),
      builder: (context, r) {
        final (calls, team) = r;
        return ListView(padding: const EdgeInsets.fromLTRB(16, 6, 16, 24), children: [
          const StickTop(title: 'Calls', sub: 'What your Sticks said on the phone', back: 'Team'),
          const SizedBox(height: 10),
          if (calls.isEmpty) Text('No calls yet.', style: TextStyle(color: p.soft)),
          for (final c in calls)
            Padding(padding: const EdgeInsets.only(bottom: 12), child: _CallCard(call: c, stick: team.where((x) => x.id == c.stickId).firstOrNull)),
        ]);
      },
    );
  }
}

String _label(String status) => switch (status) {
      'draft' => 'Waiting for your approval',
      'ringing' => 'Ringing',
      'in_progress' => 'On the call',
      'done' => 'Completed',
      'no_answer' => 'No answer',
      'declined' => "You didn't allow this",
      _ => status,
    };

class _CallCard extends StatelessWidget {
  final StickCall call;
  final Stick? stick;
  const _CallCard({required this.call, required this.stick});

  @override
  Widget build(BuildContext context) {
    final p = StickPalette.of(context);
    final done = call.transcript.isNotEmpty;
    return SticksCard(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          if (stick != null) StickRing(stick: stick!, size: 40),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${stick?.name ?? 'A Stick'} calls ${call.who}', style: sticksLabel(context, 14)),
            Text('${call.number}  ·  ${_label(call.status)}${call.at == null ? '' : '  ·  ${shortDate(call.at)}'}', style: TextStyle(color: p.soft, fontSize: 12)),
          ])),
        ]),
        const SizedBox(height: 8),
        Text(call.purpose, style: TextStyle(color: p.ink2, fontSize: 13)),
        if (call.outcome != null) ...[
          const SizedBox(height: 4),
          Text(call.outcome!, style: sticksLabel(context, 13)),
        ],
        SticksSectionLabel(done ? 'Transcript' : 'Script to approve'),
        for (final l in (done ? call.transcript : call.script))
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Align(
              alignment: l.stick ? Alignment.centerLeft : Alignment.centerRight,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 270),
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                decoration: BoxDecoration(
                  color: l.stick ? Color.alphaBlend((stick?.accent ?? p.ink).withValues(alpha: .14), p.card) : p.paper,
                  border: l.stick ? null : Border.all(color: p.rule),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(l.text, style: const TextStyle(fontSize: 13.5, height: 1.35)),
              ),
            ),
          ),
      ]),
    );
  }
}
