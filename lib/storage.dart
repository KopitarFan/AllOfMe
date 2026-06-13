import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

abstract class AppStore {
  Future<AppSnapshot?> load();

  Future<AppSnapshot> save(AppSnapshot snapshot);

  Future<AppStoreInfo> info();

  Future<BackupReceipt> createBackup(AppSnapshot snapshot);

  Future<void> clear();
}

class AppStoreInfo {
  const AppStoreInfo({
    required this.label,
    required this.location,
    this.lastSavedAt,
    this.backupsLocation,
  });

  final String label;
  final String location;
  final DateTime? lastSavedAt;
  final String? backupsLocation;
}

class BackupReceipt {
  const BackupReceipt({
    required this.contents,
    required this.createdAt,
    this.path,
  });

  final String contents;
  final DateTime createdAt;
  final String? path;
}

class SharedPreferencesAppStore implements AppStore {
  static const _snapshotKey = 'all_of_me.snapshot.v1';
  static const _snapshotSavedAtKey = 'all_of_me.snapshot.v1.saved_at';

  @override
  Future<AppSnapshot?> load() async {
    final preferences = await SharedPreferences.getInstance();
    final rawSnapshot = preferences.getString(_snapshotKey);
    if (rawSnapshot == null || rawSnapshot.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(rawSnapshot);
    if (decoded is! Map) {
      return null;
    }

    return AppSnapshot.fromJson(decoded.cast<String, Object?>());
  }

  @override
  Future<AppSnapshot> save(AppSnapshot snapshot) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_snapshotKey, jsonEncode(snapshot.toJson()));
    await preferences.setString(
      _snapshotSavedAtKey,
      DateTime.now().toIso8601String(),
    );
    return snapshot;
  }

  @override
  Future<AppStoreInfo> info() async {
    final preferences = await SharedPreferences.getInstance();
    final savedAt = preferences.getString(_snapshotSavedAtKey);
    return AppStoreInfo(
      label: 'Shared preferences',
      location: 'Platform key-value storage',
      lastSavedAt: savedAt == null ? null : DateTime.tryParse(savedAt),
    );
  }

  @override
  Future<BackupReceipt> createBackup(AppSnapshot snapshot) async {
    return BackupReceipt(
      contents: snapshot.toBackupJson(),
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_snapshotKey);
    await preferences.remove(_snapshotSavedAtKey);
  }
}

class MemoryAppStore implements AppStore {
  MemoryAppStore([this._snapshot]);

  AppSnapshot? _snapshot;

  @override
  Future<AppSnapshot?> load() async => _snapshot;

  @override
  Future<AppSnapshot> save(AppSnapshot snapshot) async {
    _snapshot = snapshot;
    return snapshot;
  }

  @override
  Future<AppStoreInfo> info() async {
    return const AppStoreInfo(label: 'In-memory', location: 'Test runtime');
  }

  @override
  Future<BackupReceipt> createBackup(AppSnapshot snapshot) async {
    return BackupReceipt(
      contents: snapshot.toBackupJson(),
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> clear() async {
    _snapshot = null;
  }
}

AppSnapshot snapshotFromBackupJson(String rawBackup) {
  final decoded = jsonDecode(rawBackup);
  final root = _mapValue(decoded);
  if (root == null) {
    throw const FormatException('Backup must be a JSON object.');
  }

  final snapshotJson = _mapValue(root['snapshot']) ?? root;
  return AppSnapshot.fromJson(snapshotJson);
}

Map<String, Object?>? _mapValue(Object? value) {
  if (value is Map<String, Object?>) {
    return value;
  }
  if (value is Map) {
    return value.cast<String, Object?>();
  }
  return null;
}
