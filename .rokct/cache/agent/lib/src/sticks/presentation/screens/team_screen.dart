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

/// Team: who is on shift and on what. The first tab.
class TeamScreen extends StatelessWidget {
  const TeamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = SticksScope.of(context);
    final p = StickPalette.of(context);
    return SticksFuture<List<Stick>>(
      future: s.data.sticks(),
      builder: (context, sticks) {
        final onShift = sticks.where((x) => x.status != StickStatus.off).length;
        return Stack(children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 88),
            children: [
              StickTop(
                title: 'Your team',
                sub: '$onShift of ${sticks.length} on shift',
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  _IconText('✉', () => s.nav.openInbox()),
                  _IconText('💬', s.nav.openTalk),
                  _IconText('☎', s.nav.openCalls),
                  _IconText('+', () => s.nav.openHire()),
                  const SizedBox(width: 6),
                  _IconText('⚙', s.nav.openSettings),
                ]),
              ),
              const SizedBox(height: 10),
              for (final st in sticks) ...[
                _TeamRow(stick: st, onTap: () => s.nav.openStick(st.id)),
                const SizedBox(height: 8),
              ],
            ],
          ),
          Positioned(
            right: 16,
            bottom: 14,
            child: GestureDetector(
              onTap: () => s.nav.openGiveTask(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(color: p.ink, borderRadius: BorderRadius.circular(999)),
                child: Text('+ Give a task', style: sticksLabel(context, 13.5, color: p.onInk)),
              ),
            ),
          ),
        ]);
      },
    );
  }
}

class _IconText extends StatelessWidget {
  final String glyph;
  final VoidCallback onTap;
  const _IconText(this.glyph, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Center(child: Text(glyph, style: sticksHead(context, 22))),
        ),
      );
}

class _TeamRow extends StatelessWidget {
  final Stick stick;
  final VoidCallback onTap;
  const _TeamRow({required this.stick, required this.onTap});

  static const _label = {
    StickStatus.working: 'Working',
    StickStatus.waiting: 'Waiting on you',
    StickStatus.off: 'Off duty',
  };

  @override
  Widget build(BuildContext context) {
    final p = StickPalette.of(context);
    final dot = switch (stick.status) {
      StickStatus.working => StickPalette.working,
      StickStatus.waiting => StickPalette.waiting,
      StickStatus.off => StickPalette.off,
    };
    return Opacity(
      opacity: stick.status == StickStatus.off ? .7 : 1,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SticksCard(
          padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
          child: Row(children: [
            StickRing(stick: stick, live: stick.status == StickStatus.working),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text.rich(TextSpan(children: [
                  TextSpan(text: stick.name, style: sticksLabel(context, 15)),
                  TextSpan(text: '   ${stick.role}', style: TextStyle(color: p.soft, fontSize: 12.5)),
                ])),
                Row(children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(_label[stick.status]!,
                      style: sticksLabel(context, 12.5,
                          color: stick.status == StickStatus.waiting ? const Color(0xFF9A6B00) : p.ink)),
                ]),
                Text(stick.status == StickStatus.off && stick.backAt != null ? 'Back ${shortDate(stick.backAt)}' : stick.statusText, style: TextStyle(color: p.ink2, fontSize: 13, height: 1.3)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
