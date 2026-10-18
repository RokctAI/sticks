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

import 'package:flutter/foundation.dart';

import 'stick_models.dart';

/// Everything the Sticks screens read and write. One implementation,
/// [StickRepository], talks to the `api.sticks.*` gateway cmds of the call
/// contract; a demo session is served by the fixtures for those same cmds,
/// so demo and production take the same path.
abstract class StickData {
  /// Fires after any write, so open screens reload.
  Listenable get changes;

  Future<List<Stick>> sticks();
  Future<Stick?> stick(String id);
  Future<List<StickTask>> tasks({String? stickId});

  /// The Stick's oldest open confirm, or null.
  Future<StickConfirm?> confirm(String stickId);
  Future<ConfirmAnswered> answerConfirm(String confirmId, String key, {String? note});

  /// Owner inbox is [forWho] `owner`; `team` is every Stick-to-Stick message
  /// (owner only); otherwise a Stick id, for oversight.
  Future<List<StickMessage>> inbox(String forWho, {bool unreadOnly = false});
  Future<MessageStatus> sendMessage({
    required String to,
    required MessageKind kind,
    required String body,
    String? replyTo,
    String? taskId,
    List<MessageAttachment> attachments = const [],
  });

  Future<List<RoleOption>> roles();
  Future<Stick> createStick({
    required String fullName,
    required bool woman,
    required String roleKey,
    String? hours,
    StickLook? look,
  });

  /// Calls the Sticks made or have lined up for approval.
  Future<List<StickCall>> calls({String? stickId});

  /// Worked out from the task feed; no cmd serves it.
  Future<List<ReportRow>> weeklyReport();

  /// Open confirms and recent messages as the push would show them.
  Future<List<StickNotification>> notifications();
}
