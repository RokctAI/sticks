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


// compliance-ignore-file: flutter-http-timeout (all HTTP rides base_sdk's HttpService/PlatformGateway Dio, whose BaseOptions set connect/receive/send timeouts centrally)

import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:base_sdk/base_sdk.dart' show DemoFixtures;
import 'package:base_sdk/src/database/app_database.dart';
import 'package:base_sdk/src/handlers/http_service.dart';
import '../domain/interface/agent_facade.dart';
import '../infrastructure/repository/agent_repository.dart';
import '../infrastructure/services/assistant_history_store.dart';

/// Host asset directory holding agent_sdk's demo platform fixtures
/// (`<cmd>.json`), installed from `templates/assets/demo/agent`.
const String agentDemoFixtureDirectory = 'assets/demo/agent';

class AgentSdkDependencies {
  /// Installer convention is `register(GetIt.instance)`; the authorized Dio
  /// client defaults to base_sdk's [HttpService] (registered by
  /// BaseSdkDependencies before any feature SDK). Pass [dio] explicitly only
  /// in tests or non-standard hosts.
  static void register(GetIt getIt, [Dio? dio]) {
    // Demo answers for agent cmds (api.ask_assistant), served by base_sdk's
    // DemoGatewayInterceptor only while a demo session is active, so a
    // demo chat runs the real AgentRepository and its history fills the
    // same way a real one does.
    DemoFixtures.registerAssetDirectory(agentDemoFixtureDirectory);
    if (!getIt.isRegistered<AgentFacade>()) {
      final client =
          dio ?? getIt.get<HttpService>().client(requireAuth: true);
      getIt.registerLazySingleton<AgentFacade>(() => AgentRepository(client));
    }
    // The account's assistant chat history (assistant_history_table) on
    // the one shared AppDatabase. AssistantService finds it here.
    if (!getIt.isRegistered<AssistantHistoryStore>()) {
      if (!getIt.isRegistered<AppDatabase>()) {
        getIt.registerLazySingleton<AppDatabase>(() => AppDatabase());
      }
      getIt.registerLazySingleton<AssistantHistoryStore>(
        () => AssistantHistoryStore(getIt.get<AppDatabase>()),
      );
    }
  }
}

// ---------------------------------------------------------------------------
// HOST-APP ADAPTERS (documentation only — not compiled wiring)
//
// agent_sdk owns narrow interfaces and never imports the producer SDKs
// behind them. The HOST APP — the only place where agent_sdk and the
// producer SDKs are installed together — implements and registers small
// adapters in its own composition code (e.g.
// `lib/core/domain/di/dependency_manager.dart` / `main.dart`).
//
// 1. SubscriptionStatusProvider: moved to lms_sdk with the office-hours
//    controller (2026-07 carve-out) — see lms_sdk/src/di/lms_di.dart for
//    the host adapter example.
//
// 2. AiTranslationProvider: the former adapter example here posted to the
//    Laravel-era `/api/v1/dashboard/seller/ai-translations`, a path the
//    Frappe router never served (fix-wave 2026-09-02, item A3 — deleted).
//    If the feature returns, base's `get_ai_translations`
//    (translation.py) needs a manifest alias first; the host adapter then
//    rides the gateway cmd, not a dashboard URL.
// ---------------------------------------------------------------------------
