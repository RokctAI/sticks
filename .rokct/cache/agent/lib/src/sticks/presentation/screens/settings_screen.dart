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

/// Settings: appearance and the team.
class SettingsScreen extends StatelessWidget {
  /// Called when the user picks an appearance. The host owns the theme;
  /// null hides the choice.
  final ValueChanged<ThemeMode>? onThemeMode;
  final ThemeMode themeMode;

  const SettingsScreen({super.key, this.onThemeMode, this.themeMode = ThemeMode.system});

  @override
  Widget build(BuildContext context) {
    final s = SticksScope.of(context);
    final p = StickPalette.of(context);
    return SticksFuture<List<Stick>>(
      future: s.data.sticks(),
      builder: (context, team) {
        final rows = <(String, Widget)>[
          if (onThemeMode != null)
            ('Appearance', Wrap(spacing: 5, children: [
              SticksChip('Auto', on: themeMode == ThemeMode.system, onTap: () => onThemeMode!(ThemeMode.system)),
              SticksChip('Light', on: themeMode == ThemeMode.light, onTap: () => onThemeMode!(ThemeMode.light)),
              SticksChip('Dark', on: themeMode == ThemeMode.dark, onTap: () => onThemeMode!(ThemeMode.dark)),
            ])),
          ('Team', Text('${team.length} Sticks', style: sticksLabel(context, 14.5))),
          ('Asks', Text('Your Sticks ask you before anything leaves the company.', style: sticksLabel(context, 14.5))),
        ];
        return ListView(padding: const EdgeInsets.fromLTRB(16, 6, 16, 24), children: [
          const StickTop(title: 'Settings', back: 'Team'),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(color: p.card, border: Border.all(color: p.rule), borderRadius: BorderRadius.circular(16)),
            clipBehavior: Clip.antiAlias,
            child: Column(children: [
              for (var i = 0; i < rows.length; i++)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(border: i == 0 ? null : Border(top: BorderSide(color: p.rule))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(rows[i].$1.toUpperCase(), style: sticksLabel(context, 10.5, color: p.soft).copyWith(letterSpacing: 1.3)),
                    const SizedBox(height: 4),
                    rows[i].$2,
                  ]),
                ),
            ]),
          ),
          const SizedBox(height: 12),
          SticksButton('See how asks reach you', filled: false, onTap: s.nav.openLock),
        ]);
      },
    );
  }
}
