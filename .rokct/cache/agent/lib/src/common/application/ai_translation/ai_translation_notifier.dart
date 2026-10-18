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
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/models/response/languages_response.dart';

import '../../domain/interface/ai_translation_provider.dart';
import '../../infrastructure/models/request/ai_translation_request.dart';
import 'ai_translation_state.dart';

class AiTranslationNotifier extends StateNotifier<AiTranslationState> {
  final AiTranslationProvider _translationRepository;

  AiTranslationNotifier(this._translationRepository)
      : super(const AiTranslationState());

  Future<void> getAiTranslation({
    required AiTranslationRequest model,
    ValueChanged<String?>? onSuccess,
  }) async {
    state = state.copyWith(isLoading: true);
    final response = await _translationRepository.getAiTranslation(
      model: model,
    );
    response.when(
      success: (data) {
        state = state.copyWith(isLoading: false, translatedUsingAi: true);
        onSuccess?.call(data.data?.title);
      },
      failure: (failure, status) {
        state = state.copyWith(isLoading: false);
      },
    );
  }

  void setLanguage(LanguageData language) {
    if (state.selectedLanguage == language) return;
    state = state.copyWith(
      selectedLanguage: language,
      translatedUsingAi: false,
    );
  }

  void setTranslatedUsingAi(bool value) {
    if (state.translatedUsingAi == value) return;
    state = state.copyWith(translatedUsingAi: value);
  }
}
