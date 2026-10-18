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
import '../stick_figure.dart';
import '../sticks_scope.dart';
import '../widgets.dart';

/// One Stick: the live feed of what it is doing, and its tasks for today.
class StickScreen extends StatelessWidget {
  final String stickId;
  const StickScreen({super.key, required this.stickId});

  @override
  Widget build(BuildContext context) {
    final s = SticksScope.of(context);
    final p = StickPalette.of(context);
    return SticksFuture<Stick?>(
      future: s.data.stick(stickId),
      builder: (context, stick) {
        if (stick == null) {
          return Center(child: Text('This Stick is no longer on your team.', style: TextStyle(color: p.soft)));
        }
        return ListView(padding: EdgeInsets.zero, children: [
          StickHero(stick: stick, subtitle: '${stick.role}${stick.hours.isEmpty ? '' : ' · shift ${stick.hours}'}', onTitleTap: () => s.nav.openProfile(stick.id)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SticksSectionLabel('Now'),
              SticksCard(
                radius: 14,
                child: Text(
                  stick.status == StickStatus.off && stick.backAt != null ? 'Off shift. Back ${shortDate(stick.backAt)}.' : stick.statusText,
                  style: sticksLabel(context, 14),
                ),
              ),
              if (stick.openConfirms > 0) ...[
                const SizedBox(height: 8),
                SticksButton('Open the ask', onTap: () => s.nav.openAsk(stick.id)),
              ],
              const SticksSectionLabel('Tasks'),
              SticksFuture<List<StickTask>>(
                future: s.data.tasks(stickId: stick.id),
                builder: (context, tasks) => Column(children: [
                  if (tasks.isEmpty)
                    Align(alignment: Alignment.centerLeft, child: Text('Nothing given yet.', style: TextStyle(color: p.soft))),
                  for (final t in tasks) TaskCard(task: t),
                ]),
              ),
            ]),
          ),
        ]);
      },
    );
  }
}

/// A task row: title, state bar and the server's note.
class TaskCard extends StatelessWidget {
  final StickTask task;
  const TaskCard({super.key, required this.task});

  static double progress(TaskState s) => switch (s) { TaskState.done => 1, TaskState.inProgress => .5, TaskState.todo => 0 };
  static String label(StickTask t) => switch (t.state) {
        TaskState.done => 'Done',
        TaskState.inProgress => t.note ?? 'In progress',
        TaskState.todo => t.note ?? 'Not started',
      };

  @override
  Widget build(BuildContext context) {
    final s = SticksScope.of(context);
    final p = StickPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => s.nav.openTask(task.id),
        behavior: HitTestBehavior.opaque,
        child: SticksCard(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          radius: 14,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(task.title, style: sticksLabel(context, 14)),
            const SizedBox(height: 6),
            SticksBar(progress(task.state)),
            const SizedBox(height: 6),
            Text(label(task), style: TextStyle(color: p.soft, fontSize: 12)),
          ]),
        ),
      ),
    );
  }
}

/// The tinted band with the full Stick standing on it.
class StickHero extends StatelessWidget {
  final Stick stick;
  final String subtitle;
  final VoidCallback? onTitleTap;
  const StickHero({super.key, required this.stick, required this.subtitle, this.onTitleTap});

  @override
  Widget build(BuildContext context) {
    final p = StickPalette.of(context);
    final nav = SticksScope.of(context).nav;
    return Container(
      color: Color.alphaBlend(stick.accent.withValues(alpha: .16), p.paper),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GestureDetector(
          onTap: nav.back,
          behavior: HitTestBehavior.opaque,
          child: Padding(padding: const EdgeInsets.only(bottom: 4), child: Text('‹ Team', style: sticksLabel(context, 13, color: p.soft))),
        ),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          SizedBox(
            width: 120,
            child: StickFigure(look: stick.look, mood: stick.mood, dark: p.dark),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: onTitleTap,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(stick.name, style: sticksHead(context, 26)),
                  Text(subtitle, style: TextStyle(color: p.soft, fontSize: 13)),
                ]),
              ),
            ),
          ),
        ]),
      ]),
    );
  }
}
