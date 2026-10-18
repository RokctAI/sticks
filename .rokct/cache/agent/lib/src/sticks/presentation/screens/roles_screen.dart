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

/// Hire a Stick: pick a role first. The Stick is dressed for it afterwards.
class RolesScreen extends StatelessWidget {
  const RolesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = SticksScope.of(context);
    final p = StickPalette.of(context);
    return SticksFuture<(List<Stick>, List<RoleOption>)>(
      future: Future.wait([s.data.sticks(), s.data.roles()])
          .then((v) => (v[0] as List<Stick>, v[1] as List<RoleOption>)),
      builder: (context, r) {
        final (team, roles) = r;
        return ListView(padding: const EdgeInsets.fromLTRB(16, 6, 16, 24), children: [
          const StickTop(title: 'Hire a Stick', sub: 'Pick a role. Your Stick is dressed for it.', back: 'Team'),
          const SizedBox(height: 10),
          for (final r in roles)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => s.nav.openSetup(role: r.key),
                behavior: HitTestBehavior.opaque,
                child: SticksCard(
                  padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
                  child: Row(children: [
                    _RoleHead(role: r.label, team: team),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(r.label, style: sticksLabel(context, 15)),
                      Text(r.owns.take(2).join(', '), style: TextStyle(color: p.ink2, fontSize: 13)),
                    ])),
                    Text('›', style: TextStyle(color: p.soft, fontSize: 22)),
                  ]),
                ),
              ),
            ),
          const SizedBox(height: 4),
          Text('Next: a name, and whether the Stick is a woman or a man.', style: TextStyle(color: p.soft, fontSize: 13)),
        ]);
      },
    );
  }
}

class _RoleHead extends StatelessWidget {
  final String role;
  final List<Stick> team;
  const _RoleHead({required this.role, required this.team});

  @override
  Widget build(BuildContext context) {
    final holder = team.where((x) => x.role == role).firstOrNull;
    if (holder != null) return StickRing(stick: holder);
    final p = StickPalette.of(context);
    return Container(
      width: 56, height: 56,
      decoration: BoxDecoration(shape: BoxShape.circle, color: Color.alphaBlend(const Color(0xFF8A8F98).withValues(alpha: .22), p.card)),
      clipBehavior: Clip.antiAlias,
      child: StickFigure(look: const StickLook.naked(), mood: StickMood.happy, crop: StickCrop.head, dark: p.dark),
    );
  }
}
