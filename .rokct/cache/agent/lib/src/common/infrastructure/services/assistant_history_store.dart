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


import 'package:base_sdk/base_sdk.dart' show OwnerScope, kUnownedOwner;
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../database/drift_tables.dart';
import 'assistant_service.dart' show ChatMessage;

/// The `session` the standalone assistant chat keeps its transcript under.
/// A lesson's private lane passes its own session id instead, so the two
/// conversations stay apart.
const String kAssistantChatHistorySession = 'assistant_chat';

/// Reads and writes [AssistantHistoryTable] for the signed-in account - the
/// "assistant chat history saved per account" that agent_sdk 1.0.4 scoped
/// but nothing used.
///
/// Speaks plain SQL through [GeneratedDatabase] (radio_sdk's
/// `DriftListenStatsStore` precedent): the generated
/// `assistantHistoryTable` accessor only exists on base_sdk's composed
/// AppDatabase, while custom statements compile and unit test standalone
/// against any database holding the table. Date values go through drift
/// [Variable]s and [QueryRow.read], so they follow the database's own
/// date-time storage setting.
///
/// Owner-scoped:
///  * a write stamps `OwnerScope.instance.current`, resolved per call (the
///    store outlives sign-ins). With nobody signed in nothing is written:
///    an unowned row would be visible to whoever signs in next.
///  * a read is base_sdk's `ownerVisible` rule as SQL: this account's rows
///    plus unowned (pre-scoping) ones. Another account's messages are never
///    returned.
///
/// Local and best-effort: no network, and every failure is logged and
/// swallowed. A chat that cannot save or load its history still works, and
/// offline it works exactly as online.
class AssistantHistoryStore {
  AssistantHistoryStore(this._db);

  final GeneratedDatabase _db;

  /// Most messages [load] returns: the latest ones, oldest first.
  static const int defaultLimit = 200;

  Future<List<String>>? _floor;

  /// The owner-column floor (see [ensureAgentOwnerScopeColumns]), for a file
  /// whose stored version already equals the composed maximum and so ran no
  /// migration. Idempotent, memoised per process.
  Future<void> _ensureSchema() => _floor ??= ensureAgentOwnerScopeColumns(_db);

  String get _owner => OwnerScope.instance.current;

  /// Saves [message] to the signed-in account's transcript for [session].
  /// Saving the same id again updates it rather than adding a row. Returns
  /// whether a row was written.
  Future<bool> save(
    ChatMessage message, {
    String session = kAssistantChatHistorySession,
  }) async {
    final String owner = _owner;
    if (owner == kUnownedOwner || message.id.isEmpty) return false;
    try {
      await _ensureSchema();
      await _db.customInsert(
        'INSERT INTO assistant_history_table '
        '(id, session, sender, message, timestamp, owner) '
        'VALUES (?1, ?2, ?3, ?4, ?5, ?6) '
        'ON CONFLICT(id, owner) DO UPDATE SET '
        'session = excluded.session, sender = excluded.sender, '
        'message = excluded.message, timestamp = excluded.timestamp',
        variables: [
          Variable<String>(message.id),
          Variable<String>(session),
          Variable<String>(message.sender),
          Variable<String>(message.text),
          Variable<DateTime>(message.timestamp),
          Variable<String>(owner),
        ],
      );
      return true;
    } catch (e) {
      debugPrint('==> AssistantHistoryStore: save failed: $e');
      return false;
    }
  }

  /// The signed-in account's latest [limit] messages in [session], oldest
  /// first. Empty when there are none or they cannot be read.
  Future<List<ChatMessage>> load({
    String session = kAssistantChatHistorySession,
    int limit = defaultLimit,
  }) async {
    final String owner = _owner;
    final bool named = owner != kUnownedOwner;
    try {
      await _ensureSchema();
      final rows = await _db.customSelect(
        'SELECT id, sender, message, timestamp FROM assistant_history_table '
        'WHERE session = ?1 AND '
        '${named ? "(owner = '' OR owner = ?3)" : "owner = ''"} '
        'ORDER BY timestamp DESC, rowid DESC LIMIT ?2',
        variables: [
          Variable<String>(session),
          Variable<int>(limit),
          if (named) Variable<String>(owner),
        ],
      ).get();
      return rows.reversed
          .map((row) => ChatMessage(
                id: row.read<String>('id'),
                sender: row.read<String>('sender'),
                text: row.read<String>('message'),
                timestamp: row.read<DateTime>('timestamp'),
              ))
          .toList();
    } catch (e) {
      debugPrint('==> AssistantHistoryStore: load failed: $e');
      return const <ChatMessage>[];
    }
  }
}
