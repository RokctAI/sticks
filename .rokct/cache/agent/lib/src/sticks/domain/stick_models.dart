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

import 'package:flutter/painting.dart';

enum StickGender { woman, man }

enum StickMood { neutral, happy, worried, focus, glad }

enum StickProp { none, clipboard, folder, calculator, phone, megaphone, toolbox, coffee }

enum StickStatus { working, waiting, off }

/// How a Stick looks. The server may send hints (`look` in `list_sticks`);
/// without them the look comes from [StickLooks] so no two Sticks on a team
/// look alike.
class StickLook {
  final Color skin;
  final Color skinShade;
  final Color clothes;
  final Color clothesShade;
  final Color hair;
  final bool dress;
  final bool glasses;
  final int hairStyle;
  final StickProp prop;

  const StickLook({
    required this.skin,
    required this.skinShade,
    required this.clothes,
    required this.clothesShade,
    required this.hair,
    required this.dress,
    required this.glasses,
    required this.hairStyle,
    required this.prop,
  });

  /// A Stick with nothing on, as in the intro.
  const StickLook.naked()
      : skin = const Color(0xFFF7CD9C),
        skinShade = const Color(0xFFE8AE78),
        clothes = const Color(0xFFF6F4EE),
        clothesShade = const Color(0xFFE1DDD2),
        hair = const Color(0xFF1E1A17),
        dress = false,
        glasses = false,
        hairStyle = -1,
        prop = StickProp.none;
}

/// One Stick as `api.sticks.list_sticks` returns it.
class Stick {
  final String id;
  final String name;
  final String role;
  final StickLook look;
  final Color accent;
  final StickStatus status;
  final StickMood mood;

  /// The server's one-line status ("Needs your approval").
  final String statusText;

  /// Shift as `HH:MM-HH:MM`, display only.
  final String hours;
  final DateTime? backAt;
  final List<String> owns;
  final int openConfirms;

  const Stick({
    required this.id,
    required this.name,
    required this.role,
    required this.look,
    required this.accent,
    required this.status,
    required this.mood,
    required this.statusText,
    this.hours = '',
    this.backAt,
    this.owns = const [],
    this.openConfirms = 0,
  });
}

enum TaskState { todo, inProgress, done }

/// One task as `api.sticks.get_task_feed` returns it.
class StickTask {
  final String id;
  final String stickId;
  final String title;
  final TaskState state;
  final String priority;
  final DateTime? due;
  final String? note;
  final String? confirmId;

  const StickTask({
    required this.id,
    required this.stickId,
    required this.title,
    required this.state,
    this.priority = 'normal',
    this.due,
    this.note,
    this.confirmId,
  });
}

class ConfirmOption {
  final String key;
  final String label;
  final bool primary;
  const ConfirmOption(this.key, this.label, {this.primary = false});
}

enum ConfirmKind { confirm, permission, draft }

/// An outward action a Stick drafted for the owner to approve.
class StickDraft {
  final String channel;
  final List<String> to;
  final String subject;
  final String body;
  final List<String> attachments;
  const StickDraft({
    required this.channel,
    this.to = const [],
    this.subject = '',
    this.body = '',
    this.attachments = const [],
  });
}

/// An ask only the owner can answer, as `api.sticks.get_confirm` returns it:
/// a plain confirm, a permission to share sensitive data, or a draft.
class StickConfirm {
  final String id;
  final ConfirmKind kind;
  final String stickId;
  final String? requesterId;
  final String? dataLabel;
  final String? messageId;
  final String? taskId;
  final String question;
  final DateTime? deadline;
  final List<ConfirmOption> options;
  final StickDraft? draft;

  const StickConfirm({
    required this.id,
    required this.kind,
    required this.stickId,
    required this.question,
    required this.options,
    this.requesterId,
    this.dataLabel,
    this.messageId,
    this.taskId,
    this.deadline,
    this.draft,
  });
}

/// What `api.sticks.answer_confirm` says came of an answer.
class ConfirmAnswered {
  final bool already;
  final String answer;
  const ConfirmAnswered({required this.already, required this.answer});
}

enum MessageKind { ask, handoff, note }

enum MessageStatus { delivered, held, awaitingPermission, declined }

class MessageAttachment {
  final String ref;
  final String label;
  const MessageAttachment(this.ref, this.label);
}

/// One message between two Stick-or-owner parties (`api.sticks.list_inbox`).
class StickMessage {
  final String id;
  final String fromId;
  final String toId;
  final MessageKind kind;
  final String body;
  final DateTime? sentAt;
  final bool read;
  final bool sensitive;
  final MessageStatus status;
  final String? confirmId;
  final String? replyTo;
  final String? taskId;
  final List<MessageAttachment> attachments;

  const StickMessage({
    required this.id,
    required this.fromId,
    required this.toId,
    required this.kind,
    required this.body,
    required this.status,
    this.sentAt,
    this.read = true,
    this.sensitive = false,
    this.confirmId,
    this.replyTo,
    this.taskId,
    this.attachments = const [],
  });
}

class RoleHold {
  final String key;
  final String label;
  final bool sensitive;
  const RoleHold(this.key, this.label, {this.sensitive = false});
}

/// A role choice from `api.sticks.list_roles`.
class RoleOption {
  final String key;
  final String label;
  final List<String> owns;
  final List<RoleHold> holds;
  const RoleOption(this.key, this.label, {this.owns = const [], this.holds = const []});
}

/// Friday report, worked out on the phone from the task feed.
class ReportRow {
  final String stickId;
  final int tasksDone;
  const ReportRow(this.stickId, this.tasksDone);
}

class StickNotification {
  final String stickId;
  final String title;
  final String body;
  final DateTime? when;
  const StickNotification(this.stickId, this.title, this.body, this.when);
}

/// One line of a call, said by the Stick or by the person called.
class CallLine {
  final bool stick;
  final String text;
  const CallLine(this.stick, this.text);
}

/// A call a Stick makes for the owner, as `api.sticks.list_calls` returns it.
/// [outcome] is the server's one-line result. The script is what the owner approved; the transcript is what was said.
class StickCall {
  final String id;
  final String stickId;
  final String who;
  final String number;
  final String purpose;
  /// `draft`, `ringing`, `in_progress`, `done`, `no_answer` or `declined`.
  final String status;
  final String? outcome;
  final DateTime? at;
  final List<CallLine> script;
  final List<CallLine> transcript;

  const StickCall({
    required this.id,
    required this.stickId,
    required this.who,
    required this.number,
    required this.purpose,
    required this.status,
    this.outcome,
    this.at,
    this.script = const [],
    this.transcript = const [],
  });
}
