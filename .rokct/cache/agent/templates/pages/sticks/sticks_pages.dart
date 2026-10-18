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

import 'package:agent_sdk/sticks.dart';
import 'package:auto_route/auto_route.dart';
import 'package:base_sdk/base_sdk.dart' show PlatformGateway;
import 'package:flutter/material.dart';

/// Where the Sticks screens read from: the `api.sticks.*` cmds on the
/// platform gateway. A demo session is answered by the fixtures for the same
/// cmds (assets/demo/agent), so demo and production take this one path.
final StickData sticksData = StickRepository(const PlatformGateway().tenant);

/// Routes the Sticks screens through the host's auto_route router.
class _RouterNav implements SticksNav {
  final BuildContext context;
  _RouterNav(this.context);

  StackRouter get _r => context.router;

  @override
  void openStick(String id) => _r.pushNamed('${SticksRoutes.stick}?id=$id');
  @override
  void openProfile(String id) => _r.pushNamed('${SticksRoutes.profile}?id=$id');
  @override
  void openTask(String id) => _r.pushNamed('${SticksRoutes.task}?id=$id');
  @override
  void openAsk(String id) => _r.pushNamed('${SticksRoutes.ask}?id=$id');
  @override
  void openGiveTask({String? stickId}) =>
      _r.pushNamed(stickId == null ? SticksRoutes.give : '${SticksRoutes.give}?id=$stickId');
  @override
  void openHire() => _r.pushNamed(SticksRoutes.hire);
  @override
  void openSetup({String? role, bool animated = false}) =>
      _r.pushNamed('${SticksRoutes.setup}?animated=$animated${role == null ? '' : '&role=${Uri.encodeComponent(role)}'}');
  @override
  void openReport() => _r.pushNamed(SticksRoutes.report);
  @override
  void openSettings() => _r.pushNamed(SticksRoutes.settings);
  @override
  void openLock() => _r.pushNamed(SticksRoutes.lock);
  @override
  void openTalk() => _r.pushNamed(SticksRoutes.talk);
  @override
  void openInbox({String? forWho}) =>
      _r.pushNamed(forWho == null ? SticksRoutes.inbox : '${SticksRoutes.inbox}?for=${Uri.encodeComponent(forWho)}');
  @override
  void openCalls() => _r.pushNamed(SticksRoutes.calls);
  @override
  void back() => _r.maybePop();
}

class _Host extends StatelessWidget {
  final Widget child;
  const _Host({required this.child});

  @override
  Widget build(BuildContext context) => SticksScope(
        data: sticksData,
        nav: _RouterNav(context),
        child: SticksPage(child: child),
      );
}

@RoutePage(name: 'SticksHomeRoute')
class SticksHomePage extends StatelessWidget {
  const SticksHomePage({super.key});
  @override
  Widget build(BuildContext context) => const _Host(child: SticksShell());
}

@RoutePage(name: 'SticksStickRoute')
class SticksStickPage extends StatelessWidget {
  final String id;
  const SticksStickPage({super.key, @QueryParam('id') this.id = ''});
  @override
  Widget build(BuildContext context) => _Host(child: StickScreen(stickId: id));
}

@RoutePage(name: 'SticksProfileRoute')
class SticksProfilePage extends StatelessWidget {
  final String id;
  const SticksProfilePage({super.key, @QueryParam('id') this.id = ''});
  @override
  Widget build(BuildContext context) => _Host(child: ProfileScreen(stickId: id));
}

@RoutePage(name: 'SticksTaskRoute')
class SticksTaskPage extends StatelessWidget {
  final String id;
  const SticksTaskPage({super.key, @QueryParam('id') this.id = ''});
  @override
  Widget build(BuildContext context) => _Host(child: TaskRunScreen(taskId: id));
}

@RoutePage(name: 'SticksAskRoute')
class SticksAskPage extends StatelessWidget {
  final String id;
  const SticksAskPage({super.key, @QueryParam('id') this.id = ''});
  @override
  Widget build(BuildContext context) => _Host(child: AskScreen(stickId: id));
}

@RoutePage(name: 'SticksGiveRoute')
class SticksGivePage extends StatelessWidget {
  final String? id;
  const SticksGivePage({super.key, @QueryParam('id') this.id});
  @override
  Widget build(BuildContext context) => _Host(child: GiveTaskScreen(stickId: id));
}

@RoutePage(name: 'SticksHireRoute')
class SticksHirePage extends StatelessWidget {
  const SticksHirePage({super.key});
  @override
  Widget build(BuildContext context) => const _Host(child: RolesScreen());
}

@RoutePage(name: 'SticksSetupRoute')
class SticksSetupPage extends StatelessWidget {
  final String? role;
  final bool animated;
  const SticksSetupPage({
    super.key,
    @QueryParam('role') this.role,
    @QueryParam('animated') this.animated = false,
  });
  @override
  Widget build(BuildContext context) => _Host(child: SetupScreen(role: role, animated: animated));
}

@RoutePage(name: 'SticksReportRoute')
class SticksReportPage extends StatelessWidget {
  const SticksReportPage({super.key});
  @override
  Widget build(BuildContext context) => const _Host(child: SticksShell(initialTab: 3));
}

@RoutePage(name: 'SticksSettingsRoute')
class SticksSettingsPage extends StatelessWidget {
  const SticksSettingsPage({super.key});
  @override
  Widget build(BuildContext context) => const _Host(child: SettingsScreen());
}

@RoutePage(name: 'SticksLockRoute')
class SticksLockPage extends StatelessWidget {
  const SticksLockPage({super.key});
  @override
  Widget build(BuildContext context) => const _Host(child: LockScreen());
}

@RoutePage(name: 'SticksTalkRoute')
class SticksTalkPage extends StatelessWidget {
  const SticksTalkPage({super.key});
  @override
  Widget build(BuildContext context) => const _Host(child: ConversationsScreen());
}

@RoutePage(name: 'SticksInboxRoute')
class SticksInboxPage extends StatelessWidget {
  final String forWho;
  const SticksInboxPage({super.key, @QueryParam('for') this.forWho = 'owner'});
  @override
  Widget build(BuildContext context) => _Host(child: InboxScreen(forWho: forWho));
}

@RoutePage(name: 'SticksCallsRoute')
class SticksCallsPage extends StatelessWidget {
  const SticksCallsPage({super.key});
  @override
  Widget build(BuildContext context) => const _Host(child: CallsScreen());
}
