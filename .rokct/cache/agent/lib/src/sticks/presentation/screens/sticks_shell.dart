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
import 'report_screen.dart';
import 'tasks_tab.dart';
import 'team_screen.dart';

/// The four tabs: Team, Tasks, Asks, Reports.
class SticksShell extends StatefulWidget {
  final int initialTab;
  const SticksShell({super.key, this.initialTab = 0});

  @override
  State<SticksShell> createState() => _SticksShellState();
}

class _SticksShellState extends State<SticksShell> {
  late int _tab = widget.initialTab;
  static const _labels = ['Team', 'Tasks', 'Asks', 'Reports'];

  @override
  Widget build(BuildContext context) {
    final p = StickPalette.of(context);
    final s = SticksScope.of(context);
    return Column(children: [
      Expanded(
        child: IndexedStack(index: _tab, children: const [TeamScreen(), TasksTab(), AsksTab(), ReportScreen()]),
      ),
      Container(
        padding: const EdgeInsets.fromLTRB(4, 10, 4, 12),
        decoration: BoxDecoration(color: p.card, border: Border(top: BorderSide(color: p.rule))),
        child: Row(children: [
          for (var i = 0; i < _labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _tab = i),
                behavior: HitTestBehavior.opaque,
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(_labels[i], style: sticksLabel(context, 12.5, color: i == _tab ? p.ink : p.soft)),
                  if (i == 2)
                    FutureBuilder<List<Stick>>(
                      future: s.data.sticks(),
                      builder: (context, snap) {
                        final n = (snap.data ?? const <Stick>[]).fold<int>(0, (a, x) => a + x.openConfirms);
                        if (n == 0) return const SizedBox.shrink();
                        return Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          decoration: BoxDecoration(color: StickPalette.alert, borderRadius: BorderRadius.circular(999)),
                          child: Text('$n', style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w800)),
                        );
                      },
                    ),
                ]),
              ),
            ),
        ]),
      ),
    ]);
  }
}
