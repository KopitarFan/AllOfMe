import 'dart:convert';
import 'dart:io';

import 'package:all_of_me_demo/models.dart';
import 'package:all_of_me_demo/storage.dart';
import 'package:all_of_me_demo/storage_io.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDirectory;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'allofme_store_test_',
    );
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('local file store migrates from a legacy store', () async {
    final snapshot = AppSnapshot.seeded();
    final store = LocalFileAppStore(
      rootDirectory: tempDirectory,
      legacyStore: MemoryAppStore(snapshot),
    );

    final loaded = await store.load();

    expect(loaded?.profile.displayName, snapshot.profile.displayName);
    expect(
      File(
        '${tempDirectory.path}${Platform.pathSeparator}${LocalFileAppStore.snapshotFileName}',
      ).existsSync(),
      isTrue,
    );
  });

  test('local file store saves, reloads, and creates backup files', () async {
    final snapshot = AppSnapshot.seeded();
    final store = LocalFileAppStore(rootDirectory: tempDirectory);
    final updated = snapshot.copyWith(
      profile: snapshot.profile.copyWith(
        displayName: 'File Store',
        updatedAt: DateTime(2026, 6, 8),
      ),
    );

    await store.save(updated);
    final reloaded = await store.load();
    final backup = await store.createBackup(updated);

    expect(reloaded?.profile.displayName, 'File Store');
    expect(backup.path, isNotNull);
    expect(File(backup.path!).existsSync(), isTrue);
    expect(
      snapshotFromBackupJson(backup.contents).profile.displayName,
      'File Store',
    );
  });

  test('local file store clears local snapshot and app files', () async {
    final snapshot = AppSnapshot.seeded();
    final store = LocalFileAppStore(rootDirectory: tempDirectory);

    await store.save(snapshot);
    await store.createBackup(snapshot);
    expect(await store.load(), isNotNull);

    await store.clear();

    expect(await store.load(), isNull);
    expect(await tempDirectory.exists(), isFalse);
  });

  test('local file store moves profile image data into image files', () async {
    const imageDataUri =
        'data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///ywAAAAAAQABAAACAUwAOw==';
    final snapshot = AppSnapshot.seeded();
    final member = snapshot.members.first.copyWith(
      profileImageDataUri: imageDataUri,
    );
    final store = LocalFileAppStore(rootDirectory: tempDirectory);

    final saved = await store.save(snapshot.copyWith(members: [member]));
    final snapshotFile = File(
      '${tempDirectory.path}${Platform.pathSeparator}${LocalFileAppStore.snapshotFileName}',
    );
    final diskJson = jsonDecode(await snapshotFile.readAsString()) as Map;
    final diskMember = (diskJson['members'] as List).single as Map;
    final reloaded = await store.load();
    final backup = await store.createBackup(saved);
    final imagePath =
        '${tempDirectory.path}${Platform.pathSeparator}${LocalFileAppStore.profileImagesDirectoryName}${Platform.pathSeparator}${saved.members.single.profileImageId}';

    expect(saved.members.single.profileImageId, isNotNull);
    expect(saved.members.single.profileImageDataUri, imageDataUri);
    expect(diskMember['profileImageId'], saved.members.single.profileImageId);
    expect(diskMember['profileImageDataUri'], isNull);
    expect(File(imagePath).existsSync(), isTrue);
    expect(reloaded?.members.single.profileImageDataUri, imageDataUri);
    expect(
      snapshotFromBackupJson(
        backup.contents,
      ).members.single.profileImageDataUri,
      imageDataUri,
    );
  });
}
