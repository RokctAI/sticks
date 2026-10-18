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
import 'ask_screen.dart';
import 'stick_screen.dart';

/// The Tasks tab: everything the team has been given, newest steps first.
class TasksTab extends StatelessWidget {
  const TasksTab({super.key});

  @override
  Widget build(BuildContext context) {
    final s = SticksScope.of(context);
    final p = StickPalette.of(context);
    return SticksFuture<(List<StickTask>, List<Stick>)>(
      future: Future.wait([s.data.tasks(), s.data.sticks()])
          .then((v) => (v[0] as List<StickTask>, v[1] as List<Stick>)),
      builder: (context, r) {
        final (tasks, sticks) = r;
        if (tasks.isEmpty) {
          return const Column(children: [
            Padding(padding: EdgeInsets.fromLTRB(16, 6, 16, 0), child: Align(alignment: Alignment.centerLeft, child: StickTop(title: 'Tasks', sub: 'Nothing waiting'))),
            Expanded(child: EmptyState(title: 'All caught up', line: 'Your Sticks have nothing waiting on you.')),
          ]);
        }
        return ListView(padding: const EdgeInsets.fromLTRB(16, 6, 16, 24), children: [
          StickTop(title: 'Tasks', sub: '${tasks.where((t) => t.state != TaskState.done).length} open'),
          const SizedBox(height: 10),
          for (final t in tasks)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => s.nav.openTask(t.id),
                behavior: HitTestBehavior.opaque,
                child: SticksCard(
                  padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
                  child: Row(children: [
                    StickRing(stick: sticks.firstWhere((x) => x.id == t.stickId, orElse: () => sticks.first), size: 44),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(t.title, style: sticksLabel(context, 14)),
                      const SizedBox(height: 5),
                      SticksBar(TaskCard.progress(t.state)),
                      const SizedBox(height: 4),
                      Text(TaskCard.label(t), style: TextStyle(color: p.soft, fontSize: 12)),
                    ])),
                  ]),
                ),
              ),
            ),
        ]);
      },
    );
  }
}
