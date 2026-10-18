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


import 'package:base_sdk/base_sdk.dart';

import '../../infrastructure/models/request/ai_translation_request.dart';
import '../../infrastructure/models/response/ai_translation_response.dart';

/// Consumer-owned slice of the backend settings/translation surface that
/// agent_sdk's AI-translation feature needs.
///
/// The host app implements this with a small adapter wrapping whichever
/// repository actually serves `/ai-translations` (historically the manager
/// settings repository) and injects it by overriding
/// `aiTranslationRepositoryProvider`. See the commented example in
/// `src/di/agent_di.dart`.
abstract class AiTranslationProvider {
  Future<ApiResult<AiTranslationResponse>> getAiTranslation({
    required AiTranslationRequest model,
  });
}
