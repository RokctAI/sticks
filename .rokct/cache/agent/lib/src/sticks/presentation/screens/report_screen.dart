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

/// Friday report: what the team got done this week.
class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = SticksScope.of(context);
    final p = StickPalette.of(context);
    return SticksFuture<(List<ReportRow>, List<Stick>)>(
      future: Future.wait([s.data.weeklyReport(), s.data.sticks()])
          .then((v) => (v[0] as List<ReportRow>, v[1] as List<Stick>)),
      builder: (context, r) {
        final (rows, sticks) = r;
        final total = rows.fold<int>(0, (a, x) => a + x.tasksDone);
        final most = rows.fold<int>(1, (a, x) => x.tasksDone > a ? x.tasksDone : a);
        return ListView(padding: const EdgeInsets.fromLTRB(16, 6, 16, 24), children: [
          const StickTop(title: 'Friday report', sub: 'Tasks your team finished'),
          const SizedBox(height: 12),
          SticksCard(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
              Text('$total', style: sticksHead(context, 35)),
              const SizedBox(width: 8),
              Text('tasks done', style: sticksLabel(context, 13.5, color: p.soft)),
            ]),
          ),
          const SizedBox(height: 12),
          for (final row in rows)
            Builder(builder: (context) {
              final stick = sticks.where((x) => x.id == row.stickId).firstOrNull;
              if (stick == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  StickRing(stick: stick, size: 44),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(stick.name, style: sticksLabel(context, 14)),
                    Text(stick.role, style: TextStyle(color: p.soft, fontSize: 12.5)),
                    const SizedBox(height: 4),
                    SticksBar(row.tasksDone / most, color: stick.accent),
                  ])),
                  SizedBox(width: 34, child: Text('${row.tasksDone}', textAlign: TextAlign.right, style: sticksHead(context, 17))),
                ]),
              );
            }),
        ]);
      },
    );
  }
}
