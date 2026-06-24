import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CloudSaveSession {
  const CloudSaveSession._({
    required this.baseUrl,
    required this.accountLabel,
    required this.connectedAt,
    this.accessToken,
  });

  final String baseUrl;
  final String accountLabel;
  final DateTime connectedAt;
  final String? accessToken;

  Uri get baseUri => Uri.parse(baseUrl);

  factory CloudSaveSession.create({
    required String baseUrl,
    String? accountLabel,
    String? accessToken,
    DateTime? connectedAt,
  }) {
    final normalizedBaseUrl = _normalizeBaseUrl(baseUrl);
    final label = _trimmedOrNull(accountLabel) ?? normalizedBaseUrl.host;
    return CloudSaveSession._(
      baseUrl: normalizedBaseUrl.toString(),
      accountLabel: label,
      accessToken: _trimmedOrNull(accessToken),
      connectedAt: connectedAt ?? DateTime.now(),
    );
  }

  factory CloudSaveSession.fromJson(Map<String, Object?> json) {
    final rawBaseUrl = json['baseUrl'];
    final connectedAt = DateTime.tryParse(json['connectedAt'] as String? ?? '');
    if (rawBaseUrl is! String || connectedAt == null) {
      throw const FormatException('Cloud save session is invalid.');
    }
    return CloudSaveSession.create(
      baseUrl: rawBaseUrl,
      accountLabel: json['accountLabel'] as String?,
      accessToken: json['accessToken'] as String?,
      connectedAt: connectedAt,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'baseUrl': baseUrl,
      'accountLabel': accountLabel,
      'connectedAt': connectedAt.toIso8601String(),
      if (accessToken != null) 'accessToken': accessToken,
    };
  }
}

abstract class CloudSaveSessionStore {
  Future<CloudSaveSession?> load();

  Future<void> save(CloudSaveSession session);

  Future<void> clear();
}

class SharedPreferencesCloudSaveSessionStore implements CloudSaveSessionStore {
  const SharedPreferencesCloudSaveSessionStore();

  static const _sessionKey = 'all_of_me.cloud_save.session.v1';

  @override
  Future<CloudSaveSession?> load() async {
    final preferences = await SharedPreferences.getInstance();
    final rawSession = preferences.getString(_sessionKey);
    if (rawSession == null || rawSession.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(rawSession);
      if (decoded is Map) {
        return CloudSaveSession.fromJson(decoded.cast<String, Object?>());
      }
    } catch (_) {
      await preferences.remove(_sessionKey);
    }
    return null;
  }

  @override
  Future<void> save(CloudSaveSession session) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_sessionKey, jsonEncode(session.toJson()));
  }

  @override
  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_sessionKey);
  }
}

class MemoryCloudSaveSessionStore implements CloudSaveSessionStore {
  MemoryCloudSaveSessionStore([this._session]);

  CloudSaveSession? _session;

  @override
  Future<CloudSaveSession?> load() async => _session;

  @override
  Future<void> save(CloudSaveSession session) async {
    _session = session;
  }

  @override
  Future<void> clear() async {
    _session = null;
  }
}

Uri _normalizeBaseUrl(String value) {
  final uri = Uri.parse(value.trim());
  final scheme = uri.scheme.toLowerCase();
  if (scheme != 'http' && scheme != 'https') {
    throw FormatException('Cloud save base URL must use http or https: $value');
  }
  if (uri.host.isEmpty) {
    throw FormatException('Cloud save base URL needs a host: $value');
  }

  final path = uri.path.endsWith('/') ? uri.path : '${uri.path}/';
  return Uri(
    scheme: scheme,
    userInfo: uri.userInfo,
    host: uri.host,
    port: uri.hasPort ? uri.port : null,
    path: path,
  );
}

String? _trimmedOrNull(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
