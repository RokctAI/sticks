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

/// The lock screen: how an ask or a result reaches the user as a
/// notification. A preview of the push the backend will send.
class LockScreen extends StatelessWidget {
  const LockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = SticksScope.of(context);
    final p = StickPalette.of(context);
    final now = DateTime.now();
    const wd = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const mo = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    return SticksFuture<(List<StickNotification>, List<Stick>)>(
      future: Future.wait([s.data.notifications(), s.data.sticks()])
          .then((v) => (v[0] as List<StickNotification>, v[1] as List<Stick>)),
      builder: (context, r) {
        final (items, sticks) = r;
        if (items.isEmpty) return const Center(child: Text('Nothing has reached you yet.'));
        return ListView(padding: const EdgeInsets.fromLTRB(16, 6, 16, 24), children: [
          GestureDetector(
            onTap: s.nav.back,
            behavior: HitTestBehavior.opaque,
            child: Text('‹ Settings', style: sticksLabel(context, 13, color: p.soft)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 22),
            child: Column(children: [
              Text('$hh:$mm', style: sticksHead(context, 54)),
              Text('${wd[now.weekday - 1]} ${now.day} ${mo[now.month - 1]}', style: sticksLabel(context, 14, color: p.soft)),
            ]),
          ),
          for (final n in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SticksCard(
                radius: 18,
                padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  PartyAvatar(Party.of(n.stickId, sticks), size: 44),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(n.title, style: sticksLabel(context, 13.5)),
                    Text(n.body, style: TextStyle(fontSize: 13, height: 1.3, color: p.ink2)),
                  ])),
                  const SizedBox(width: 8),
                  Text(clockTime(n.when), style: sticksLabel(context, 11, color: p.soft)),
                ]),
              ),
            ),
        ]);
      },
    );
  }
}
