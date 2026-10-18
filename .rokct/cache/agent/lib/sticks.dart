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

/// The Sticks flavor of agent_sdk: the screens, their data interface and a
/// mock source. Import this only from an app composed with the `sticks`
/// app_type; it is deliberately not exported from `agent_sdk.dart`, so the
/// other apps that compose agent_sdk never see it.
library sticks;

export 'src/sticks/domain/stick_data.dart';
export 'src/sticks/domain/stick_looks.dart';
export 'src/sticks/domain/stick_models.dart';
export 'src/sticks/infrastructure/stick_repository.dart';
export 'src/sticks/presentation/stick_figure.dart';
export 'src/sticks/presentation/sticks_app.dart';
export 'src/sticks/presentation/sticks_scope.dart';
export 'src/sticks/presentation/widgets.dart';
export 'src/sticks/presentation/screens/ask_screen.dart';
export 'src/sticks/presentation/screens/calls_screen.dart';
export 'src/sticks/presentation/screens/conversations_screen.dart';
export 'src/sticks/presentation/screens/inbox_screen.dart';
export 'src/sticks/presentation/screens/give_task_screen.dart';
export 'src/sticks/presentation/screens/lock_screen.dart';
export 'src/sticks/presentation/screens/profile_screen.dart';
export 'src/sticks/presentation/screens/report_screen.dart';
export 'src/sticks/presentation/screens/roles_screen.dart';
export 'src/sticks/presentation/screens/settings_screen.dart';
export 'src/sticks/presentation/screens/setup_screen.dart';
export 'src/sticks/presentation/screens/stick_screen.dart';
export 'src/sticks/presentation/screens/sticks_shell.dart';
export 'src/sticks/presentation/screens/task_run_screen.dart';
export 'src/sticks/presentation/screens/tasks_tab.dart';
export 'src/sticks/presentation/screens/team_screen.dart';
