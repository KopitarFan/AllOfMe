import 'dart:convert';
import 'dart:io';

import 'package:all_of_me_demo/database.dart';
import 'package:all_of_me_demo/models.dart';
import 'package:all_of_me_demo/storage.dart';
import 'package:all_of_me_demo/storage_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

void main() {
  late Directory tempDirectory;
  late AllOfMeDatabase database;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'allofme_database_test_',
    );
    database = AllOfMeDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  LocalDatabaseAppStore store({AppStore? legacyStore}) {
    return LocalDatabaseAppStore(
      database: database,
      rootDirectory: tempDirectory,
      databaseFile: File(
        '${tempDirectory.path}${Platform.pathSeparator}${LocalDatabaseAppStore.databaseFileName}',
      ),
      legacyStore: legacyStore,
    );
  }

  test('database store saves and reloads local snapshots', () async {
    final seeded = AppSnapshot.seeded();
    final snapshot = seeded.copyWith(
      security: const SecuritySettings(appLockEnabled: true),
      frontingMemberIds: [seeded.members.last.id, seeded.members.first.id],
      frontSessions: [
        FrontSession(
          id: 'session-river',
          memberId: seeded.members.last.id,
          memberName: seeded.members.last.name,
          startedAt: DateTime(2026, 6, 11, 7),
          endedAt: DateTime(2026, 6, 11, 8),
        ),
        ...seeded.frontSessions,
      ],
      timeline: [
        TimelineEntry(
          id: 'entry-deleted-note',
          type: 'note',
          action: 'Note',
          note: 'Recoverable local note.',
          createdAt: DateTime(2026, 6, 11, 9),
          deletedAt: DateTime(2026, 6, 11, 9, 30),
        ),
        TimelineEntry(
          id: 'entry-note',
          type: 'note',
          action: 'Note',
          note: 'Important local note.',
          createdAt: DateTime(2026, 6, 11, 8),
        ),
        ...seeded.timeline,
      ],
    );

    final saved = await store().save(snapshot);
    final reloaded = await store().load();

    expect(saved.profile.displayName, snapshot.profile.displayName);
    expect(reloaded?.security.appLockEnabled, isTrue);
    expect(reloaded?.frontingMemberIds, snapshot.frontingMemberIds);
    expect(reloaded?.frontSessions.map((session) => session.id), [
      'session-river',
      'session-seed-front',
    ]);
    expect(reloaded?.frontSessions.first.endedAt, DateTime(2026, 6, 11, 8));
    expect(reloaded?.members.map((member) => member.id), [
      'member-mara',
      'member-sol',
      'member-river',
    ]);
    expect(reloaded?.timeline.map((entry) => entry.id), [
      'entry-deleted-note',
      'entry-note',
      'entry-seed-front',
    ]);
    expect(reloaded?.deletedTimeline.single.id, 'entry-deleted-note');
    expect(
      reloaded?.deletedTimeline.single.deletedAt,
      DateTime(2026, 6, 11, 9, 30),
    );
  });

  test('database store migrates from a legacy app store', () async {
    final legacySnapshot = AppSnapshot.seeded().copyWith(
      profile: AppSnapshot.seeded().profile.copyWith(
        displayName: 'Migrated System',
        updatedAt: DateTime(2026, 6, 11),
      ),
    );

    final migrated = await store(
      legacyStore: MemoryAppStore(legacySnapshot),
    ).load();
    final reloaded = await store().load();

    expect(migrated?.profile.displayName, 'Migrated System');
    expect(reloaded?.profile.displayName, 'Migrated System');
  });

  test('database store upgrades the legacy default display name', () async {
    final snapshot = AppSnapshot.seeded().copyWith(
      profile: AppSnapshot.seeded().profile.copyWith(
        displayName: legacyAppDisplayName,
        updatedAt: DateTime(2026, 6, 12),
      ),
    );

    await store().save(snapshot);
    final reloaded = await store().load();

    expect(reloaded?.profile.displayName, appDisplayName);
  });

  test('database migrates schema 1 fixtures to front sessions', () async {
    await database.close();
    final databaseFile = File(
      '${tempDirectory.path}${Platform.pathSeparator}${LocalDatabaseAppStore.databaseFileName}',
    );
    _createSchema1DatabaseFixture(databaseFile);
    database = AllOfMeDatabase(NativeDatabase(databaseFile));

    final migrated = await store().load();

    expect(migrated?.profile.displayName, 'Legacy SQLite');
    expect(migrated?.schemaVersion, appSchemaVersion);
    expect(migrated?.frontingMemberIds, ['member-mara']);
    expect(migrated?.frontSessions, hasLength(1));
    expect(migrated?.deletedTimeline, isEmpty);
    expect(migrated?.frontSessions.single.memberId, 'member-mara');
    expect(migrated?.frontSessions.single.memberName, 'Mara');
    expect(
      migrated?.frontSessions.single.startedAt,
      DateTime(2026, 6, 10, 9, 30),
    );
  });

  test('database store clears rows and app-owned files', () async {
    final snapshot = AppSnapshot.seeded();
    final saved = await store().save(snapshot);
    await store().createBackup(saved);
    expect(await store().load(), isNotNull);

    await store().clear();

    expect(await store().load(), isNull);
    expect(await database.select(database.memberTable).get(), isEmpty);
    expect(
      Directory(
        '${tempDirectory.path}${Platform.pathSeparator}${LocalDatabaseAppStore.backupsDirectoryName}',
      ).existsSync(),
      isFalse,
    );
  });

  test(
    'database store keeps profile images as files and backups portable',
    () async {
      const imageDataUri =
          'data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///ywAAAAAAQABAAACAUwAOw==';
      final snapshot = AppSnapshot.seeded();
      final member = snapshot.members.first.copyWith(
        profileImageDataUri: imageDataUri,
      );

      final saved = await store().save(snapshot.copyWith(members: [member]));
      final reloaded = await store().load();
      final backup = await store().createBackup(saved);
      final imagePath =
          '${tempDirectory.path}${Platform.pathSeparator}${LocalDatabaseAppStore.profileImagesDirectoryName}${Platform.pathSeparator}${saved.members.single.profileImageId}';

      expect(saved.members.single.profileImageId, isNotNull);
      expect(saved.members.single.profileImageDataUri, imageDataUri);
      expect(File(imagePath).existsSync(), isTrue);
      expect(reloaded?.members.single.profileImageDataUri, imageDataUri);
      expect(
        snapshotFromBackupJson(
          backup.contents,
        ).members.single.profileImageDataUri,
        imageDataUri,
      );

      final backupJson = jsonDecode(backup.contents) as Map<String, Object?>;
      expect(backupJson['snapshot'], isA<Map>());
    },
  );
}

void _createSchema1DatabaseFixture(File file) {
  final db = sqlite.sqlite3.open(file.path);
  try {
    db.execute('PRAGMA foreign_keys = ON;');
    db.execute('''
      CREATE TABLE system_profile (
        id INTEGER NOT NULL DEFAULT 1 PRIMARY KEY,
        display_name TEXT NOT NULL,
        description TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      );
    ''');
    db.execute('''
      CREATE TABLE security_settings (
        id INTEGER NOT NULL DEFAULT 1 PRIMARY KEY,
        app_lock_enabled INTEGER NOT NULL DEFAULT 0
      );
    ''');
    db.execute('''
      CREATE TABLE member_groups (
        id TEXT NOT NULL PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        color_value INTEGER NOT NULL,
        archived INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        sort_order INTEGER NOT NULL DEFAULT 0
      );
    ''');
    db.execute('''
      CREATE TABLE members (
        id TEXT NOT NULL PRIMARY KEY,
        name TEXT NOT NULL,
        role TEXT NOT NULL,
        note TEXT NOT NULL,
        color_value INTEGER NOT NULL,
        archived INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        profile_image_id TEXT,
        sort_order INTEGER NOT NULL DEFAULT 0
      );
    ''');
    db.execute('''
      CREATE TABLE member_group_links (
        member_id TEXT NOT NULL REFERENCES members(id),
        group_id TEXT NOT NULL REFERENCES member_groups(id),
        sort_order INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (member_id, group_id)
      );
    ''');
    db.execute('''
      CREATE TABLE fronting_members (
        member_id TEXT NOT NULL REFERENCES members(id) PRIMARY KEY,
        sort_order INTEGER NOT NULL
      );
    ''');
    db.execute('''
      CREATE TABLE timeline_entries (
        id TEXT NOT NULL PRIMARY KEY,
        type TEXT NOT NULL,
        action TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        member_id TEXT,
        member_name TEXT,
        note TEXT,
        sort_order INTEGER NOT NULL DEFAULT 0
      );
    ''');

    final createdAt = _driftDateTime(DateTime(2026, 6, 10, 8));
    final frontStartedAt = _driftDateTime(DateTime(2026, 6, 10, 9, 30));
    db.execute(
      '''
      INSERT INTO system_profile (
        id,
        display_name,
        description,
        created_at,
        updated_at
      ) VALUES (?, ?, ?, ?, ?);
      ''',
      [1, 'Legacy SQLite', 'Schema 1 fixture', createdAt, createdAt],
    );
    db.execute(
      'INSERT INTO security_settings (id, app_lock_enabled) VALUES (?, ?);',
      [1, 0],
    );
    db.execute(
      '''
      INSERT INTO member_groups (
        id,
        name,
        description,
        color_value,
        archived,
        created_at,
        updated_at,
        sort_order
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?);
      ''',
      [
        'group-daily',
        'Daily',
        'Everyday support',
        0xFF24786D,
        0,
        createdAt,
        createdAt,
        0,
      ],
    );
    db.execute(
      '''
      INSERT INTO members (
        id,
        name,
        role,
        note,
        color_value,
        archived,
        created_at,
        updated_at,
        profile_image_id,
        sort_order
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
      ''',
      [
        'member-mara',
        'Mara',
        'Organizer',
        'Legacy row',
        0xFF24786D,
        0,
        createdAt,
        createdAt,
        null,
        0,
      ],
    );
    db.execute(
      '''
      INSERT INTO member_group_links (
        member_id,
        group_id,
        sort_order
      ) VALUES (?, ?, ?);
      ''',
      ['member-mara', 'group-daily', 0],
    );
    db.execute(
      'INSERT INTO fronting_members (member_id, sort_order) VALUES (?, ?);',
      ['member-mara', 0],
    );
    db.execute(
      '''
      INSERT INTO timeline_entries (
        id,
        type,
        action,
        created_at,
        member_id,
        member_name,
        note,
        sort_order
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?);
      ''',
      [
        'entry-front',
        'front',
        'Started fronting',
        frontStartedAt,
        'member-mara',
        'Mara',
        null,
        0,
      ],
    );
    db.execute('PRAGMA user_version = 1;');
  } finally {
    db.close();
  }
}

int _driftDateTime(DateTime value) {
  return value.millisecondsSinceEpoch ~/ 1000;
}
