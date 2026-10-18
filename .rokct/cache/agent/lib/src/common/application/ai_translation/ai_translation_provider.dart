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


import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/interface/ai_translation_provider.dart';
import 'ai_translation_notifier.dart';
import 'ai_translation_state.dart';

/// The host app overrides this with an adapter implementing
/// [AiTranslationProvider] around whichever repository serves AI
/// translations (see the commented example in `src/di/agent_di.dart`).
final aiTranslationRepositoryProvider = Provider<AiTranslationProvider>(
  (ref) => throw UnimplementedError(
    'aiTranslationRepositoryProvider is not overridden',
  ),
);

final aiTranslationProvider =
    StateNotifierProvider<AiTranslationNotifier, AiTranslationState>(
      (ref) => AiTranslationNotifier(
        ref.watch(aiTranslationRepositoryProvider),
      ),
    );
