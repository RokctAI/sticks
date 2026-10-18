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

import '../domain/stick_data.dart';

/// Where a Sticks screen can go. The host's router implements this (see the
/// installed `sticks_pages.dart`); [SticksApp] has a Navigator-based one so
/// the screens also run on their own.
abstract class SticksNav {
  void openStick(String id);
  void openProfile(String id);
  void openTask(String id);
  void openAsk(String stickId);
  void openGiveTask({String? stickId});
  void openHire();

  /// The setup panel for a new Stick. [animated] plays the first-run intro:
  /// a beam of light, a naked Stick, then the room lights up.
  void openSetup({String? role, bool animated = false});
  void openReport();
  void openTalk();
  void openInbox({String? forWho});
  void openCalls();
  void openSettings();
  void openLock();
  void back();
}

/// Carries the data source and navigation to every Sticks screen, and
/// rebuilds them when the data source reports a change.
class SticksScope extends StatefulWidget {
  final StickData data;
  final SticksNav nav;
  final Widget child;

  const SticksScope({super.key, required this.data, required this.nav, required this.child});

  static SticksScope of(BuildContext context) {
    final s = context.dependOnInheritedWidgetOfExactType<_Inherited>();
    assert(s != null, 'No SticksScope above this screen');
    return s!.scope;
  }

  @override
  State<SticksScope> createState() => _SticksScopeState();
}

class _SticksScopeState extends State<SticksScope> {
  int _version = 0;

  void _bump() => setState(() => _version++);

  @override
  void initState() {
    super.initState();
    widget.data.changes.addListener(_bump);
  }

  @override
  void didUpdateWidget(SticksScope old) {
    super.didUpdateWidget(old);
    if (old.data != widget.data) {
      old.data.changes.removeListener(_bump);
      widget.data.changes.addListener(_bump);
    }
  }

  @override
  void dispose() {
    widget.data.changes.removeListener(_bump);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _Inherited(scope: widget, version: _version, child: widget.child);
}

class _Inherited extends InheritedWidget {
  final SticksScope scope;
  final int version;
  const _Inherited({required this.scope, required this.version, required super.child});

  @override
  bool updateShouldNotify(_Inherited o) => version != o.version || scope.data != o.scope.data || scope.nav != o.scope.nav;
}

/// The app's paper, ink and rules in light and dark. The Sticks themselves
/// never change with the theme.
class StickPalette {
  final Color paper, ink, soft, rule, card, onInk, ink2;
  final bool dark;

  const StickPalette._(this.paper, this.ink, this.soft, this.rule, this.card,
      this.onInk, this.ink2, this.dark);

  static const light = StickPalette._(Color(0xFFF6F5F2), Color(0xFF1C1C1C),
      Color(0xFF7A766E), Color(0xFFE2DED6), Color(0xFFFFFFFF), Color(0xFFFFFFFF),
      Color(0xFF45423C), false);
  static const darkSet = StickPalette._(Color(0xFF161615), Color(0xFFF2F0EA),
      Color(0xFF9A968E), Color(0xFF2C2B28), Color(0xFF1F1F1D), Color(0xFF161615),
      Color(0xFFCFCBC2), true);

  static StickPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkSet : light;

  static const working = Color(0xFF3A8F5C);
  static const waiting = Color(0xFFE0A21B);
  static const off = Color(0xFFB7B2A8);
  static const alert = Color(0xFFD6453D);
}
