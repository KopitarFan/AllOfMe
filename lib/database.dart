import 'package:drift/drift.dart';

part 'database.g.dart';

@DataClassName('SystemProfileRow')
class SystemProfileTable extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();

  TextColumn get displayName => text()();

  TextColumn get description => text()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  String get tableName => 'system_profile';

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SecuritySettingsRow')
class SecuritySettingsTable extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();

  BoolColumn get appLockEnabled =>
      boolean().withDefault(const Constant(false))();

  @override
  String get tableName => 'security_settings';

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('MemberRow')
class MemberTable extends Table {
  TextColumn get id => text()();

  TextColumn get name => text()();

  TextColumn get role => text()();

  TextColumn get note => text()();

  IntColumn get colorValue => integer()();

  BoolColumn get archived => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  TextColumn get profileImageId => text().nullable()();

  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  String get tableName => 'members';

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('MemberGroupRow')
class MemberGroupTable extends Table {
  TextColumn get id => text()();

  TextColumn get name => text()();

  TextColumn get description => text()();

  IntColumn get colorValue => integer()();

  BoolColumn get archived => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  String get tableName => 'member_groups';

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('MemberGroupLinkRow')
class MemberGroupLinkTable extends Table {
  TextColumn get memberId => text().references(MemberTable, #id)();

  TextColumn get groupId => text().references(MemberGroupTable, #id)();

  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  String get tableName => 'member_group_links';

  @override
  Set<Column> get primaryKey => {memberId, groupId};
}

@DataClassName('FrontingMemberRow')
class FrontingMemberTable extends Table {
  TextColumn get memberId => text().references(MemberTable, #id)();

  IntColumn get sortOrder => integer()();

  @override
  String get tableName => 'fronting_members';

  @override
  Set<Column> get primaryKey => {memberId};
}

@DataClassName('FrontSessionRow')
class FrontSessionTable extends Table {
  TextColumn get id => text()();

  TextColumn get memberId => text()();

  TextColumn get memberName => text()();

  DateTimeColumn get startedAt => dateTime()();

  DateTimeColumn get endedAt => dateTime().nullable()();

  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  String get tableName => 'front_sessions';

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TimelineEntryRow')
class TimelineEntryTable extends Table {
  TextColumn get id => text()();

  TextColumn get type => text()();

  TextColumn get action => text()();

  DateTimeColumn get createdAt => dateTime()();

  TextColumn get memberId => text().nullable()();

  TextColumn get memberName => text().nullable()();

  TextColumn get note => text().nullable()();

  DateTimeColumn get deletedAt => dateTime().nullable()();

  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  String get tableName => 'timeline_entries';

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    SystemProfileTable,
    SecuritySettingsTable,
    MemberTable,
    MemberGroupTable,
    MemberGroupLinkTable,
    FrontingMemberTable,
    FrontSessionTable,
    TimelineEntryTable,
  ],
)
class AllOfMeDatabase extends _$AllOfMeDatabase {
  AllOfMeDatabase(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (migrator) => migrator.createAll(),
      onUpgrade: (migrator, from, to) async {
        if (from < 2) {
          await migrator.createTable(frontSessionTable);
          await customStatement('''
            INSERT INTO front_sessions (
              id,
              member_id,
              member_name,
              started_at,
              ended_at,
              sort_order
            )
            SELECT
              'session-' || fronting_members.member_id || '-' ||
                COALESCE(
                  (
                    SELECT MAX(timeline_entries.created_at)
                    FROM timeline_entries
                    WHERE timeline_entries.member_id = fronting_members.member_id
                      AND timeline_entries.type = 'front'
                      AND timeline_entries.action = 'Started fronting'
                  ),
                  members.updated_at
                ),
              fronting_members.member_id,
              members.name,
              COALESCE(
                (
                  SELECT MAX(timeline_entries.created_at)
                  FROM timeline_entries
                  WHERE timeline_entries.member_id = fronting_members.member_id
                    AND timeline_entries.type = 'front'
                    AND timeline_entries.action = 'Started fronting'
                ),
                members.updated_at
              ),
              NULL,
              fronting_members.sort_order
            FROM fronting_members
            INNER JOIN members ON members.id = fronting_members.member_id
          ''');
        }
        if (from < 3) {
          await migrator.addColumn(
            timelineEntryTable,
            timelineEntryTable.deletedAt,
          );
        }
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }
}
