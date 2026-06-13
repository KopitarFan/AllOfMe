import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'models.dart';
import 'storage.dart';

class LocalFileAppStore implements AppStore {
  LocalFileAppStore({required this.rootDirectory, this.legacyStore});

  static const String snapshotFileName = 'snapshot.v1.json';
  static const String backupsDirectoryName = 'backups';
  static const String profileImagesDirectoryName = 'member-images';

  final Directory rootDirectory;
  final AppStore? legacyStore;

  File get _snapshotFile => File(_join(rootDirectory.path, snapshotFileName));

  Directory get _backupsDirectory =>
      Directory(_join(rootDirectory.path, backupsDirectoryName));

  Directory get _profileImagesDirectory =>
      Directory(_join(rootDirectory.path, profileImagesDirectoryName));

  static Future<LocalFileAppStore> create({AppStore? legacyStore}) async {
    final supportDirectory = await getApplicationSupportDirectory();
    return LocalFileAppStore(
      rootDirectory: Directory(_join(supportDirectory.path, 'AllOfMe')),
      legacyStore: legacyStore,
    );
  }

  @override
  Future<AppSnapshot?> load() async {
    final file = _snapshotFile;
    if (await file.exists()) {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) {
        return null;
      }
      return _hydrateProfileImages(
        AppSnapshot.fromJson(decoded.cast<String, Object?>()),
      );
    }

    final legacySnapshot = await legacyStore?.load();
    if (legacySnapshot != null) {
      return save(legacySnapshot);
    }
    return legacySnapshot;
  }

  @override
  Future<AppSnapshot> save(AppSnapshot snapshot) async {
    await rootDirectory.create(recursive: true);
    final diskSnapshot = await _moveProfileImagesToFiles(snapshot);
    final file = _snapshotFile;
    final tempFile = File('${file.path}.tmp');
    await tempFile.writeAsString(
      jsonEncode(diskSnapshot.toJson()),
      flush: true,
    );
    if (await file.exists()) {
      await file.delete();
    }
    await tempFile.rename(file.path);
    return _hydrateProfileImages(diskSnapshot);
  }

  @override
  Future<AppStoreInfo> info() async {
    final file = _snapshotFile;
    final stat = await file.exists() ? await file.stat() : null;
    return AppStoreInfo(
      label: 'Local app file',
      location: file.path,
      lastSavedAt: stat?.modified,
      backupsLocation: _backupsDirectory.path,
    );
  }

  @override
  Future<BackupReceipt> createBackup(AppSnapshot snapshot) async {
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
    if (await rootDirectory.exists()) {
      await rootDirectory.delete(recursive: true);
    }
  }

  Future<AppSnapshot> _moveProfileImagesToFiles(AppSnapshot snapshot) async {
    final members = <Member>[];
    for (final member in snapshot.members) {
      members.add(await _moveProfileImageToFile(member));
    }
    return snapshot.copyWith(members: members);
  }

  Future<Member> _moveProfileImageToFile(Member member) async {
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

  Future<AppSnapshot> _hydrateProfileImages(AppSnapshot snapshot) async {
    final members = <Member>[];
    for (final member in snapshot.members) {
      members.add(await _hydrateProfileImage(member));
    }
    return snapshot.copyWith(members: members);
  }

  Future<Member> _hydrateProfileImage(Member member) async {
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
