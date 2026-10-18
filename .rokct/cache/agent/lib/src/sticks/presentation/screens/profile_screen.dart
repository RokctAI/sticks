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
import 'stick_screen.dart';

/// A Stick's profile: shift, what it owns, its inbox.
class ProfileScreen extends StatelessWidget {
  final String stickId;
  const ProfileScreen({super.key, required this.stickId});

  @override
  Widget build(BuildContext context) {
    final s = SticksScope.of(context);
    final p = StickPalette.of(context);
    return SticksFuture<Stick?>(
      future: s.data.stick(stickId),
      builder: (context, stick) {
        if (stick == null) return const SizedBox.shrink();
        return ListView(padding: EdgeInsets.zero, children: [
          StickHero(stick: stick, subtitle: stick.role),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SticksSectionLabel('Shift'),
              Text(stick.hours.isEmpty ? 'Default hours' : stick.hours, style: sticksLabel(context, 14.5)),
              const SticksSectionLabel('Owns'),
              for (final c in stick.owns)
                Padding(padding: const EdgeInsets.only(bottom: 4), child: Text('•  $c', style: const TextStyle(fontSize: 14))),
              const SizedBox(height: 18),
              SticksButton('Inbox', filled: false, onTap: () => s.nav.openInbox(forWho: stick.id)),
              const SizedBox(height: 8),
              SticksButton('Give a task', onTap: () => s.nav.openGiveTask(stickId: stick.id)),
              const SizedBox(height: 8),
              Text('A Stick asks you or another Stick for what it needs; it never uses your account.', style: TextStyle(color: p.soft, fontSize: 12.5)),
            ]),
          ),
        ]);
      },
    );
  }
}
