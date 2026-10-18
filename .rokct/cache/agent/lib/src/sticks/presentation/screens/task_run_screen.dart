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

/// One task: what it is, how urgent, when it is due and what the server says
/// about it. When it waits on the owner, the ask is one tap away.
class TaskRunScreen extends StatelessWidget {
  final String taskId;
  const TaskRunScreen({super.key, required this.taskId});

  @override
  Widget build(BuildContext context) {
    final s = SticksScope.of(context);
    return SticksFuture<(StickTask?, Stick?)>(
      future: () async {
        final t = (await s.data.tasks()).where((x) => x.id == taskId).firstOrNull;
        return (t, t == null ? null : await s.data.stick(t.stickId));
      }(),
      builder: (context, r) {
        final (task, stick) = r;
        final p = StickPalette.of(context);
        if (task == null || stick == null) return Center(child: Text('This task is gone.', style: TextStyle(color: p.soft)));
        return Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: StickTop(title: task.title, sub: '${stick.name}${task.due == null ? '' : ' · due ${shortDate(task.due)}'}', back: 'Tasks'),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: CoveredSheet(
              stick: stick,
              child: ListView(children: [
                _Row('Status', switch (task.state) { TaskState.done => 'Done', TaskState.inProgress => 'In progress', TaskState.todo => 'Not started' }),
                _Row('Priority', task.priority[0].toUpperCase() + task.priority.substring(1)),
                if (task.due != null) _Row('Due', shortDate(task.due)),
                if (task.note != null) _Row('Note', task.note!),
                const SizedBox(height: 14),
                if (task.confirmId != null) SticksButton('Open the ask', onTap: () => s.nav.openAsk(stick.id)),
              ]),
            ),
          ),
        ]);
      },
    );
  }
}

class _Row extends StatelessWidget {
  final String k, v;
  const _Row(this.k, this.v);

  @override
  Widget build(BuildContext context) {
    final p = StickPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 76, child: Text(k, style: TextStyle(color: p.soft, fontSize: 13.5))),
        Expanded(child: Text(v, style: sticksLabel(context, 14))),
      ]),
    );
  }
}
