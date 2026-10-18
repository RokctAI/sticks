// Copied at compose time from package:agent_sdk/src/common/infrastructure/database/drift_tables.dart by sdk_installer_base.py's update_database_registration() -
// drift only understands table classes inside its own package.
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


import 'package:base_sdk/base_sdk.dart' show kUnownedOwner;
import 'package:drift/drift.dart';

/// Answers the assistant has already produced, keyed by the question.
///
/// Deliberately NOT owner-scoped: the question and its answer are content,
/// not a record of who asked. Two accounts on one device asking the same
/// thing should share the cached answer rather than each pay for it, and a
/// row here says nothing about either of them. Only the transcript in
/// [AssistantHistoryTable] does.
@DataClassName('AssistantCacheEntity')
class AssistantCacheTable extends Table {
  TextColumn get question => text()();
  TextColumn get answer => text()();
  TextColumn get subtopicRef => text()();

  @override
  Set<Column> get primaryKey => {question};
}

/// One account's chat transcript with the assistant.
///
/// Owner-scoped. One device, one `rokct_app.sqlite`, one process-wide
/// AppDatabase: without an owner on the row, the account that signs in next
/// reads the previous account's conversation. Scoping is a VISIBILITY rule -
/// signing out writes nothing and deletes nothing here, it only stops the
/// next account seeing these rows.
@DataClassName('AssistantHistoryEntity')
class AssistantHistoryTable extends Table {
  TextColumn get id => text()();
  TextColumn get session => text()();
  TextColumn get sender => text()();
  TextColumn get message => text()();
  DateTimeColumn get timestamp => dateTime()();

  /// Account this message belongs to, or [kUnownedOwner] for a message that
  /// belongs to nobody in particular (every row written before scoping
  /// existed, and every row written by an app nobody has signed into).
  ///
  /// NOT NULL with a default rather than nullable: `owner` is part of the
  /// primary key and SQLite does not enforce NOT NULL on the columns of an
  /// ordinary table's composite PRIMARY KEY, so a NULL owner would compare
  /// NULL != NULL in the backing index and every upsert on an unowned row
  /// would append a duplicate instead of updating it. See base_sdk's
  /// [kUnownedOwner].
  TextColumn get owner => text().withDefault(const Constant(kUnownedOwner))();

  /// [owner] joins the key so two accounts can hold rows that collide on
  /// [id] (an offline id is minted from the clock) without one replacing the
  /// other. Reads filter with base_sdk's `ownerVisible`.
  @override
  Set<Column> get primaryKey => {id, owner};
}

/// Brings `assistant_history_table` up to the owner-scoped definition when
/// the opened file predates it, and does nothing at all when it does not.
///
/// A plain `ALTER TABLE ... ADD COLUMN` is not enough: `owner` joins the
/// PRIMARY KEY and SQLite cannot alter a primary key in place. So the table
/// is rebuilt the long way round - rename the old one aside, create the new
/// one from its current Dart definition, copy every column the two have in
/// common, drop the old one. `owner` is not among those columns, so every
/// row already on the device takes its `''` default and comes out unowned,
/// which is exactly the state the visibility rule treats as the current
/// account's. Nothing is deleted and no owner is guessed.
///
/// Idempotent and self-checking, so it is safe in the manifest migration
/// step, in a `beforeOpen` floor, or in both - the same reasoning as
/// base_sdk's `AppDatabase.ensureOwnerScopeColumns`. Returns the tables it
/// actually rebuilt, which is what the tests assert on.
Future<List<String>> ensureAgentOwnerScopeColumns(GeneratedDatabase db) {
  return _rebuildForOwnerScope(db, const <String>['assistant_history_table']);
}

/// The rebuild above, for each of [tableNames] that needs it. Private so two
/// composed SDKs can each carry their own copy without colliding in the
/// single generated app_database.dart that imports both.
///
/// Takes names rather than `TableInfo`s because the generated accessors only
/// exist after composition, while this has to compile - and unit test -
/// standalone. The definition to rebuild from is found on the open database's
/// own `allTables`.
Future<List<String>> _rebuildForOwnerScope(
  GeneratedDatabase db,
  List<String> tableNames,
) async {
  final rebuilt = <String>[];
  for (final name in tableNames) {
    final rows = await db.customSelect(
      'SELECT name FROM pragma_table_info(?1)',
      variables: [Variable<String>(name)],
    ).get();
    final before = rows.map((row) => row.read<String>('name')).toList();
    // An absent table has no columns at all; base_sdk's beforeOpen table
    // floor creates it whole, with the owner column already in it.
    if (before.isEmpty || before.contains('owner')) continue;
    TableInfo<Table, dynamic>? table;
    for (final candidate in db.allTables) {
      if (candidate.actualTableName == name) {
        table = candidate;
        break;
      }
    }
    if (table == null) continue;
    final carried = before
        .where(table.columnsByName.containsKey)
        .map((c) => '"$c"')
        .join(', ');
    final parked = '${name}_pre_owner_scope';
    await db.customStatement('DROP TABLE IF EXISTS "$parked"');
    await db.customStatement('ALTER TABLE "$name" RENAME TO "$parked"');
    // `Migrator(db)` rather than `db.createMigrator()`: the latter is
    // @protected + @visibleForTesting, so it is only callable from inside a
    // GeneratedDatabase subclass, and this helper is deliberately a free
    // function so it compiles and unit-tests standalone. Same object either
    // way. createTable emits CREATE TABLE IF NOT EXISTS, so it is safe even
    // if the rename above has already been undone by a retry.
    await Migrator(db).createTable(table);
    if (carried.isNotEmpty) {
      await db.customStatement(
        'INSERT INTO "$name" ($carried) SELECT $carried FROM "$parked"',
      );
    }
    await db.customStatement('DROP TABLE "$parked"');
    rebuilt.add(name);
  }
  return rebuilt;
}
