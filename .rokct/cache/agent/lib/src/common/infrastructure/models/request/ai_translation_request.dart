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


import 'package:base_sdk/src/services/enums.dart'
    show AiTranslationModel;
import 'package:base_sdk/src/models/response/languages_response.dart';

class AiTranslationRequest {
  final AiTranslationModel model;
  final int? modelId;
  final LanguageData? lang;
  final String? content;

  AiTranslationRequest({
    required this.model,
    required this.modelId,
    required this.lang,
    this.content,
  });

  Map<String, Object?> toJson() {
    return {
      'model_type': model.type,
      if (modelId != null) 'model_id': modelId,
      'content': content,
      'lang': lang?.locale,
    };
  }
}
