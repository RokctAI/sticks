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


/// Wire model for `agent.api.ask_assistant` — pins the backend's
/// `assistant_rules.success_response` shape:
/// `{"status": "success", "response": <text>, "intent": "question"}`.
class AssistantQuestionResponse {
  final String status;
  final String responseText;
  final String intent;

  AssistantQuestionResponse({
    required this.status,
    required this.responseText,
    required this.intent,
  });

  factory AssistantQuestionResponse.fromJson(Map<String, dynamic> json) {
    return AssistantQuestionResponse(
      status: json['status']?.toString() ?? '',
      responseText: json['response']?.toString() ?? '',
      intent: json['intent']?.toString() ?? 'question',
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status,
    'response': responseText,
    'intent': intent,
  };
}
