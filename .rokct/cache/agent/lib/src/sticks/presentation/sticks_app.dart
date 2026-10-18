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
import 'screens/ask_screen.dart';
import 'screens/calls_screen.dart';
import 'screens/conversations_screen.dart';
import 'screens/inbox_screen.dart';
import 'screens/give_task_screen.dart';
import 'screens/lock_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/roles_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/setup_screen.dart';
import 'screens/stick_screen.dart';
import 'screens/sticks_shell.dart';
import 'screens/task_run_screen.dart';
import 'sticks_scope.dart';

/// Route paths of the Sticks flavor, also the ones in the manifest.
class SticksRoutes {
  const SticksRoutes._();
  static const home = '/sticks';
  static const stick = '/sticks/stick';
  static const profile = '/sticks/profile';
  static const task = '/sticks/task';
  static const ask = '/sticks/ask';
  static const give = '/sticks/give';
  static const hire = '/sticks/hire';
  static const setup = '/sticks/setup';
  static const report = '/sticks/report';
  static const settings = '/sticks/settings';
  static const lock = '/sticks/lock';
  static const talk = '/sticks/talk';
  static const inbox = '/sticks/inbox';
  static const calls = '/sticks/calls';
}

/// Each screen on a paper page with the safe area applied, so a host route
/// page is just `SticksPage(child: ...)`.
class SticksPage extends StatelessWidget {
  final Widget child;
  const SticksPage({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: StickPalette.of(context).paper,
        body: SafeArea(child: child),
      );
}

/// A [SticksNav] on a plain Navigator. [SticksApp] uses it; a host with its
/// own router implements [SticksNav] instead.
class NavigatorSticksNav implements SticksNav {
  final NavigatorState _nav;
  const NavigatorSticksNav(this._nav);

  @override
  void openStick(String id) => _nav.pushNamed(SticksRoutes.stick, arguments: id);
  @override
  void openProfile(String id) => _nav.pushNamed(SticksRoutes.profile, arguments: id);
  @override
  void openTask(String id) => _nav.pushNamed(SticksRoutes.task, arguments: id);
  @override
  void openAsk(String id) => _nav.pushNamed(SticksRoutes.ask, arguments: id);
  @override
  void openGiveTask({String? stickId}) => _nav.pushNamed(SticksRoutes.give, arguments: stickId);
  @override
  void openHire() => _nav.pushNamed(SticksRoutes.hire);
  @override
  void openSetup({String? role, bool animated = false}) =>
      _nav.pushNamed(SticksRoutes.setup, arguments: (role, animated));
  @override
  void openReport() => _nav.pushNamed(SticksRoutes.report);
  @override
  void openSettings() => _nav.pushNamed(SticksRoutes.settings);
  @override
  void openLock() => _nav.pushNamed(SticksRoutes.lock);
  @override
  void openTalk() => _nav.pushNamed(SticksRoutes.talk);
  @override
  void openInbox({String? forWho}) => _nav.pushNamed(SticksRoutes.inbox, arguments: forWho);
  @override
  void openCalls() => _nav.pushNamed(SticksRoutes.calls);
  @override
  void back() => _nav.maybePop();
}

/// The Sticks screens as a small app of their own: used by tests and by a
/// host that wants the whole flavor behind one route.
class SticksApp extends StatefulWidget {
  final StickData data;
  final ThemeMode themeMode;
  final bool firstRun;

  const SticksApp({super.key, required this.data, this.themeMode = ThemeMode.system, this.firstRun = false});

  @override
  State<SticksApp> createState() => _SticksAppState();
}

class _SticksAppState extends State<SticksApp> {
  final _key = GlobalKey<NavigatorState>();
  late ThemeMode _mode = widget.themeMode;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: _mode,
      theme: ThemeData(brightness: Brightness.light),
      darkTheme: ThemeData(brightness: Brightness.dark),
      navigatorKey: _key,
      initialRoute: widget.firstRun ? SticksRoutes.setup : SticksRoutes.home,
      builder: (context, child) => _Scoped(data: widget.data, navKey: _key, child: child!),
      onGenerateRoute: (settings) {
        Widget page;
        final a = settings.arguments;
        switch (settings.name) {
          case SticksRoutes.stick:
            page = StickScreen(stickId: a as String);
          case SticksRoutes.profile:
            page = ProfileScreen(stickId: a as String);
          case SticksRoutes.task:
            page = TaskRunScreen(taskId: a as String);
          case SticksRoutes.ask:
            page = AskScreen(stickId: a as String);
          case SticksRoutes.give:
            page = GiveTaskScreen(stickId: a as String?);
          case SticksRoutes.hire:
            page = const RolesScreen();
          case SticksRoutes.setup:
            final r = a as (String?, bool)?;
            page = SetupScreen(role: r?.$1, animated: r?.$2 ?? widget.firstRun);
          case SticksRoutes.report:
            page = const SticksShell(initialTab: 3);
          case SticksRoutes.settings:
            page = SettingsScreen(themeMode: _mode, onThemeMode: (m) => setState(() => _mode = m));
          case SticksRoutes.inbox:
            page = InboxScreen(forWho: (a as String?) ?? 'owner');
          case SticksRoutes.calls:
            page = const CallsScreen();
          case SticksRoutes.talk:
            page = const ConversationsScreen();
          case SticksRoutes.lock:
            page = const LockScreen();
          default:
            page = const SticksShell();
        }
        return MaterialPageRoute(settings: settings, builder: (_) => SticksPage(child: page));
      },
    );
  }
}

class _Scoped extends StatelessWidget {
  final StickData data;
  final GlobalKey<NavigatorState> navKey;
  final Widget child;
  const _Scoped({required this.data, required this.navKey, required this.child});

  @override
  Widget build(BuildContext context) => SticksScope(
        data: data,
        nav: _LazyNav(navKey),
        child: child,
      );
}

class _LazyNav implements SticksNav {
  final GlobalKey<NavigatorState> key;
  _LazyNav(this.key);
  NavigatorSticksNav get _n => NavigatorSticksNav(key.currentState!);
  @override
  void openStick(String id) => _n.openStick(id);
  @override
  void openProfile(String id) => _n.openProfile(id);
  @override
  void openTask(String id) => _n.openTask(id);
  @override
  void openAsk(String id) => _n.openAsk(id);
  @override
  void openGiveTask({String? stickId}) => _n.openGiveTask(stickId: stickId);
  @override
  void openHire() => _n.openHire();
  @override
  void openSetup({String? role, bool animated = false}) => _n.openSetup(role: role, animated: animated);
  @override
  void openReport() => _n.openReport();
  @override
  void openSettings() => _n.openSettings();
  @override
  void openLock() => _n.openLock();
  @override
  void openTalk() => _n.openTalk();
  @override
  void openInbox({String? forWho}) => _n.openInbox(forWho: forWho);
  @override
  void openCalls() => _n.openCalls();
  @override
  void back() => _n.back();
}
