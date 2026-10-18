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


class AssistantMessage {
  final String id;
  final String text;
  final String sender;
  final DateTime timestamp;

  AssistantMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
  });

  factory AssistantMessage.fromJson(Map<String, dynamic> json) {
    return AssistantMessage(
      id: json['id'] as String,
      text: json['text'] as String,
      sender: json['sender'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'sender': sender,
    'timestamp': timestamp.toIso8601String(),
  };
}

class AssistantHomeworkSubmission {
  final String lessonId;
  final String studentId;
  final List<String> filePaths;
  final DateTime submittedAt;

  AssistantHomeworkSubmission({
    required this.lessonId,
    required this.studentId,
    required this.filePaths,
    required this.submittedAt,
  });

  Map<String, dynamic> toJson() => {
    'lesson_id': lessonId,
    'student_id': studentId,
    'file_paths': filePaths,
    'submitted_at': submittedAt.toIso8601String(),
  };
}
