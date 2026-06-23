import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

import 'database.dart';
import 'models.dart' as model;
import 'storage.dart';

class LocalDatabaseAppStore implements AppStore {
  LocalDatabaseAppStore({
    required this.database,
    required this.rootDirectory,
    required this.databaseFile,
    this.legacyStore,
  });

  static const String databaseFileName = 'allofme.sqlite';
  static const String backupsDirectoryName = 'backups';
  static const String profileImagesDirectoryName = 'member-images';

  final AllOfMeDatabase database;
  final Directory rootDirectory;
  final File databaseFile;
  final AppStore? legacyStore;

  Directory get _backupsDirectory =>
      Directory(_join(rootDirectory.path, backupsDirectoryName));

  Directory get _profileImagesDirectory =>
      Directory(_join(rootDirectory.path, profileImagesDirectoryName));

  static Future<LocalDatabaseAppStore> create({AppStore? legacyStore}) async {
    final supportDirectory = await getApplicationSupportDirectory();
    final rootDirectory = Directory(_join(supportDirectory.path, 'AllOfMe'));
    await rootDirectory.create(recursive: true);
    final databaseFile = File(_join(rootDirectory.path, databaseFileName));
    return LocalDatabaseAppStore(
      database: AllOfMeDatabase(
        NativeDatabase.createInBackground(
          databaseFile,
          setup: (rawDatabase) {
            rawDatabase.execute('PRAGMA journal_mode = WAL;');
          },
        ),
      ),
      rootDirectory: rootDirectory,
      databaseFile: databaseFile,
      legacyStore: legacyStore,
    );
  }

  @override
  Future<model.AppSnapshot?> load() async {
    final profile = await database
        .select(database.systemProfileTable)
        .getSingleOrNull();
    if (profile == null) {
      final legacySnapshot = await legacyStore?.load();
      if (legacySnapshot == null) {
        return null;
      }
      return save(legacySnapshot);
    }

    return _hydrateProfileImages(await _snapshotFromDatabase(profile));
  }

  @override
  Future<model.AppSnapshot> save(model.AppSnapshot snapshot) async {
    await rootDirectory.create(recursive: true);
    final diskSnapshot = await _moveProfileImagesToFiles(snapshot);

    await database.transaction(() async {
      await database.delete(database.memberGroupLinkTable).go();
      await database.delete(database.frontingMemberTable).go();
      await database.delete(database.frontSessionTable).go();
      await database.delete(database.timelineEntryTable).go();
      await database.delete(database.memberTable).go();
      await database.delete(database.memberGroupTable).go();
      await database.delete(database.securitySettingsTable).go();
      await database.delete(database.systemProfileTable).go();

      await database
          .into(database.systemProfileTable)
          .insert(
            SystemProfileTableCompanion.insert(
              displayName: diskSnapshot.profile.displayName,
              description: diskSnapshot.profile.description,
              createdAt: diskSnapshot.profile.createdAt,
              updatedAt: diskSnapshot.profile.updatedAt,
            ),
          );
      await database
          .into(database.securitySettingsTable)
          .insert(
            SecuritySettingsTableCompanion.insert(
              appLockEnabled: Value(diskSnapshot.security.appLockEnabled),
            ),
          );

      for (final (index, group) in diskSnapshot.groups.indexed) {
        await database
            .into(database.memberGroupTable)
            .insert(
              MemberGroupTableCompanion.insert(
                id: group.id,
                name: group.name,
                description: group.description,
                colorValue: group.colorValue,
                archived: Value(group.archived),
                createdAt: group.createdAt,
                updatedAt: group.updatedAt,
                sortOrder: Value(index),
              ),
            );
      }

      for (final (index, member) in diskSnapshot.members.indexed) {
        await database
            .into(database.memberTable)
            .insert(
              MemberTableCompanion.insert(
                id: member.id,
                name: member.name,
                role: member.role,
                note: member.note,
                colorValue: member.colorValue,
                archived: Value(member.archived),
                createdAt: member.createdAt,
                updatedAt: member.updatedAt,
                profileImageId: Value(member.profileImageId),
                profileImageScale: Value(member.profileImageScale),
                profileImageOffsetX: Value(member.profileImageOffsetX),
                profileImageOffsetY: Value(member.profileImageOffsetY),
                sortOrder: Value(index),
              ),
            );
        for (final (groupIndex, groupId) in member.groupIds.indexed) {
          await database
              .into(database.memberGroupLinkTable)
              .insert(
                MemberGroupLinkTableCompanion.insert(
                  memberId: member.id,
                  groupId: groupId,
                  sortOrder: Value(groupIndex),
                ),
              );
        }
      }

      for (final (index, memberId) in diskSnapshot.frontingMemberIds.indexed) {
        await database
            .into(database.frontingMemberTable)
            .insert(
              FrontingMemberTableCompanion.insert(
                memberId: memberId,
                sortOrder: index,
              ),
            );
      }

      for (final (index, session) in diskSnapshot.frontSessions.indexed) {
        await database
            .into(database.frontSessionTable)
            .insert(
              FrontSessionTableCompanion.insert(
                id: session.id,
                memberId: session.memberId,
                memberName: session.memberName,
                startedAt: session.startedAt,
                endedAt: Value(session.endedAt),
                sortOrder: Value(index),
              ),
            );
      }

      for (final (index, entry) in diskSnapshot.timeline.indexed) {
        await database
            .into(database.timelineEntryTable)
            .insert(
              TimelineEntryTableCompanion.insert(
                id: entry.id,
                type: entry.type,
                action: entry.action,
                createdAt: entry.createdAt,
                memberId: Value(entry.memberId),
                memberName: Value(entry.memberName),
                note: Value(entry.note),
                deletedAt: Value(entry.deletedAt),
                sortOrder: Value(index),
              ),
            );
      }
    });

    return _hydrateProfileImages(diskSnapshot);
  }

  @override
  Future<AppStoreInfo> info() async {
    final stat = await databaseFile.exists() ? await databaseFile.stat() : null;
    return AppStoreInfo(
      label: 'Local SQLite database',
      location: databaseFile.path,
      lastSavedAt: stat?.modified,
      backupsLocation: _backupsDirectory.path,
    );
  }

  @override
  Future<BackupReceipt> createBackup(model.AppSnapshot snapshot) async {
    await _backupsDirectory.create(recursive: true);
    final createdAt = DateTime.now();
    final contents = (await _hydrateProfileImages(snapshot)).toBackupJson();
    final backupFile = File(
      _join(_backupsDirectory.path, _backupFileName(createdAt)),
    );
    await backupFile.writeAsString(contents, flush: true);
    return BackupReceipt(
      contents: contents,
      createdAt: createdAt,
      path: backupFile.path,
    );
  }

  @override
  Future<void> clear() async {
    await database.transaction(() async {
      await database.delete(database.memberGroupLinkTable).go();
      await database.delete(database.frontingMemberTable).go();
      await database.delete(database.frontSessionTable).go();
      await database.delete(database.timelineEntryTable).go();
      await database.delete(database.memberTable).go();
      await database.delete(database.memberGroupTable).go();
      await database.delete(database.securitySettingsTable).go();
      await database.delete(database.systemProfileTable).go();
    });

    for (final directory in [_profileImagesDirectory, _backupsDirectory]) {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    }
  }

  Future<model.AppSnapshot> _snapshotFromDatabase(
    SystemProfileRow profile,
  ) async {
    final security = await database
        .select(database.securitySettingsTable)
        .getSingleOrNull();
    final members = await (database.select(
      database.memberTable,
    )..orderBy([(table) => OrderingTerm(expression: table.sortOrder)])).get();
    final groups = await (database.select(
      database.memberGroupTable,
    )..orderBy([(table) => OrderingTerm(expression: table.sortOrder)])).get();
    final groupLinks =
        await (database.select(database.memberGroupLinkTable)..orderBy([
              (table) => OrderingTerm(expression: table.memberId),
              (table) => OrderingTerm(expression: table.sortOrder),
            ]))
            .get();
    final frontingMembers = await (database.select(
      database.frontingMemberTable,
    )..orderBy([(table) => OrderingTerm(expression: table.sortOrder)])).get();
    final frontSessions = await (database.select(
      database.frontSessionTable,
    )..orderBy([(table) => OrderingTerm(expression: table.sortOrder)])).get();
    final timeline = await (database.select(
      database.timelineEntryTable,
    )..orderBy([(table) => OrderingTerm(expression: table.sortOrder)])).get();

    final groupIdsByMember = <String, List<String>>{};
    for (final link in groupLinks) {
      groupIdsByMember.putIfAbsent(link.memberId, () => []).add(link.groupId);
    }

    return model.AppSnapshot(
      schemaVersion: model.appSchemaVersion,
      profile: model.SystemProfile(
        displayName: model.normalizeSystemDisplayName(profile.displayName),
        description: profile.description,
        createdAt: profile.createdAt,
        updatedAt: profile.updatedAt,
      ),
      security: model.SecuritySettings(
        appLockEnabled: security?.appLockEnabled ?? false,
      ),
      members: members.map((member) {
        return model.Member(
          id: member.id,
          name: member.name,
          role: member.role,
          note: member.note,
          groupIds: groupIdsByMember[member.id] ?? const [],
          colorValue: member.colorValue,
          archived: member.archived,
          createdAt: member.createdAt,
          updatedAt: member.updatedAt,
          profileImageId: member.profileImageId,
          profileImageScale: member.profileImageScale,
          profileImageOffsetX: member.profileImageOffsetX,
          profileImageOffsetY: member.profileImageOffsetY,
        );
      }).toList(),
      groups: groups.map((group) {
        return model.MemberGroup(
          id: group.id,
          name: group.name,
          description: group.description,
          colorValue: group.colorValue,
          archived: group.archived,
          createdAt: group.createdAt,
          updatedAt: group.updatedAt,
        );
      }).toList(),
      frontingMemberIds: frontingMembers
          .map((frontingMember) => frontingMember.memberId)
          .toList(),
      frontSessions: frontSessions.map((session) {
        return model.FrontSession(
          id: session.id,
          memberId: session.memberId,
          memberName: session.memberName,
          startedAt: session.startedAt,
          endedAt: session.endedAt,
        );
      }).toList(),
      timeline: timeline.map((entry) {
        return model.TimelineEntry(
          id: entry.id,
          type: entry.type,
          action: entry.action,
          createdAt: entry.createdAt,
          memberId: entry.memberId,
          memberName: entry.memberName,
          note: entry.note,
          deletedAt: entry.deletedAt,
        );
      }).toList(),
    );
  }

  Future<model.AppSnapshot> _moveProfileImagesToFiles(
    model.AppSnapshot snapshot,
  ) async {
    final members = <model.Member>[];
    for (final member in snapshot.members) {
      members.add(await _moveProfileImageToFile(member));
    }
    return snapshot.copyWith(members: members);
  }

  Future<model.Member> _moveProfileImageToFile(model.Member member) async {
    final dataUri = member.profileImageDataUri;
    if (dataUri == null || dataUri.isEmpty) {
      return member;
    }

    final imageData = _decodeDataUri(dataUri);
    if (imageData == null) {
      return member;
    }

    await _profileImagesDirectory.create(recursive: true);
    final imageId =
        member.profileImageId ??
        '${member.id}-${DateTime.now().microsecondsSinceEpoch}${_extensionForMimeType(imageData.mimeType)}';
    final imageFile = File(_join(_profileImagesDirectory.path, imageId));
    await imageFile.writeAsBytes(imageData.bytes, flush: true);
    return member.copyWith(profileImageId: imageId, profileImageDataUri: null);
  }

  Future<model.AppSnapshot> _hydrateProfileImages(
    model.AppSnapshot snapshot,
  ) async {
    final members = <model.Member>[];
    for (final member in snapshot.members) {
      members.add(await _hydrateProfileImage(member));
    }
    return snapshot.copyWith(members: members);
  }

  Future<model.Member> _hydrateProfileImage(model.Member member) async {
    if (member.profileImageDataUri != null || member.profileImageId == null) {
      return member;
    }

    final imageFile = File(
      _join(_profileImagesDirectory.path, member.profileImageId!),
    );
    if (!await imageFile.exists()) {
      return member;
    }

    final bytes = await imageFile.readAsBytes();
    final mimeType = _mimeTypeForImageId(member.profileImageId!);
    return member.copyWith(
      profileImageDataUri: 'data:$mimeType;base64,${base64Encode(bytes)}',
    );
  }
}

class _DecodedDataUri {
  const _DecodedDataUri({required this.mimeType, required this.bytes});

  final String mimeType;
  final List<int> bytes;
}

_DecodedDataUri? _decodeDataUri(String dataUri) {
  final marker = dataUri.indexOf('base64,');
  if (!dataUri.startsWith('data:') || marker == -1) {
    return null;
  }

  final mimeType = dataUri.substring(5, marker - 1);
  try {
    return _DecodedDataUri(
      mimeType: mimeType.isEmpty ? 'image/jpeg' : mimeType,
      bytes: base64Decode(dataUri.substring(marker + 7)),
    );
  } catch (_) {
    return null;
  }
}

String _extensionForMimeType(String mimeType) {
  return switch (mimeType.toLowerCase()) {
    'image/png' => '.png',
    'image/gif' => '.gif',
    'image/webp' => '.webp',
    'image/heic' => '.heic',
    'image/heif' => '.heif',
    _ => '.jpg',
  };
}

String _mimeTypeForImageId(String imageId) {
  final lower = imageId.toLowerCase();
  if (lower.endsWith('.png')) {
    return 'image/png';
  }
  if (lower.endsWith('.gif')) {
    return 'image/gif';
  }
  if (lower.endsWith('.webp')) {
    return 'image/webp';
  }
  if (lower.endsWith('.heic')) {
    return 'image/heic';
  }
  if (lower.endsWith('.heif')) {
    return 'image/heif';
  }
  return 'image/jpeg';
}

String _backupFileName(DateTime createdAt) {
  final safeTimestamp = createdAt
      .toIso8601String()
      .replaceAll(':', '-')
      .replaceAll('.', '-');
  return 'allofme-backup-$safeTimestamp.json';
}

String _join(String left, String right) {
  if (left.endsWith(Platform.pathSeparator)) {
    return '$left$right';
  }
  return '$left${Platform.pathSeparator}$right';
}
