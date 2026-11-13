import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'models.dart';

// Independent credentials: sharing never requires uploading a backup.
class FrontSharing {
  FrontSharing({
    http.Client? client,
    FlutterSecureStorage? storage,
    String baseUrl = const String.fromEnvironment(
      'ALLOFME_FRONT_SHARING_BASE_URL',
      defaultValue: 'https://api.allofmeapp.com/',
    ),
  }) : _client = client ?? http.Client(),
       _storage = storage ?? const FlutterSecureStorage(),
       _base = Uri.parse(baseUrl) {
    if (_base.scheme != 'https' ||
        _base.host.isEmpty ||
        _base.userInfo.isNotEmpty ||
        _base.hasQuery ||
        _base.hasFragment) {
      throw ArgumentError('Sharing requires an HTTPS server URL.');
    }
  }

  final http.Client _client;
  final FlutterSecureStorage _storage;
  final Uri _base;
  Timer? _timer;
  bool _disposed = false;
  Future<void> _tail = Future.value();
  static const _tokenKey = 'all_of_me.front_sharing.token.v1';
  static const _enabledKey = 'all_of_me.front_sharing.enabled.v1';
  static const _pausePendingKey = 'all_of_me.front_sharing.pause_pending.v1';
  static const _pendingKey = 'all_of_me.front_sharing.pending.v1';
  String get _suffix => _base.toString();
  String _key(String key) => '$key.$_suffix';

  Future<T> _serial<T>(Future<T> Function() task) {
    final next = _tail.then((_) => task());
    _tail = next.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return next;
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Object? body,
    bool register = false,
  }) async {
    var token = await _storage.read(key: _key(_tokenKey));
    if (token == null && register) {
      final response = await _client
          .post(
            _base.resolve('v1/devices/register'),
            headers: {'content-type': 'application/json'},
            body: jsonEncode({'deviceLabel': 'Front sharing'}),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 201) {
        throw StateError('Could not set up sharing.');
      }
      token = (jsonDecode(response.body) as Map)['token'] as String;
      await _storage.write(key: _key(_tokenKey), value: token);
    }
    if (token == null) throw StateError('Sharing is not connected.');
    final request = http.Request(
      method,
      _base.resolve('v1/front-sharing/$path'),
    );
    request.headers.addAll({
      'authorization': 'Bearer $token',
      'content-type': 'application/json',
    });
    if (body != null) request.body = jsonEncode(body);
    final response = await http.Response.fromStream(
      await _client.send(request).timeout(const Duration(seconds: 15)),
    ).timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        response.statusCode == 404
            ? 'Sharing is not available on this server yet.'
            : 'Sharing request failed. Please try again.',
      );
    }
    return response.body.isEmpty
        ? {}
        : (jsonDecode(response.body) as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> settings() async {
    if (await _storage.read(key: _key(_tokenKey)) == null) {
      return {
        'paused': true,
        'recipients': <dynamic>[],
        'pushConfigured': false,
      };
    }
    return _request('GET', 'settings');
  }

  Future<void> setPaused(
    bool paused,
    AppSnapshot snapshot,
  ) => _serial(() async {
    // Stop local publishing first. A server failure is shown, never treated as a successful pause.
    await _storage.write(key: _key(_enabledKey), value: 'false');
    await _storage.delete(key: _key(_pendingKey));
    _timer?.cancel();
    if (paused) {
      await _storage.write(key: _key(_pausePendingKey), value: 'true');
    }
    try {
      await _request(
        'PUT',
        'settings',
        body: {'paused': paused},
        register: true,
      );
      await _storage.delete(key: _key(_pausePendingKey));
    } catch (_) {
      if (paused && !_disposed) {
        _timer = Timer(const Duration(seconds: 30), () {
          unawaited(retry());
        });
      }
      rethrow;
    }
    if (!paused) {
      await _storage.write(key: _key(_enabledKey), value: 'true');
      await _queue(snapshot);
    }
  });

  Future<Map<String, dynamic>> invite(String label) =>
      _request('POST', 'invitations', body: {'label': label}, register: true);

  Future<void> revoke(String id) async {
    await _request('DELETE', 'recipients/$id');
  }

  Future<void> frontChanged(AppSnapshot snapshot) =>
      _serial(() => _queue(snapshot));

  Future<void> _queue(AppSnapshot snapshot) async {
    if (_disposed || await _storage.read(key: _key(_enabledKey)) != 'true') {
      return;
    }
    final bytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    bytes[6] = (bytes[6] & 15) | 64;
    bytes[8] = (bytes[8] & 63) | 128;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    final eventId =
        '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
    await _storage.write(
      key: _key(_pendingKey),
      value: jsonEncode({
        'eventId': eventId,
        'changedAt': DateTime.now().toUtc().toIso8601String(),
        'members': snapshot.activeMembers
            .where((m) => snapshot.frontingMemberIds.contains(m.id))
            .map((m) => {'name': m.name})
            .toList(),
      }),
    );
    // Coalesce rapid toggles when changing from one member to another.
    if (_disposed) return;
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 2), () {
      unawaited(retry());
    });
  }

  Future<void> retry() => _serial(() async {
    try {
      if (_disposed) return;
      if (await _storage.read(key: _key(_pausePendingKey)) == 'true') {
        await _request('PUT', 'settings', body: {'paused': true});
        await _storage.delete(key: _key(_pausePendingKey));
      }
      if (_disposed || await _storage.read(key: _key(_enabledKey)) != 'true') {
        return;
      }
      final raw = await _storage.read(key: _key(_pendingKey));
      if (raw == null) return;
      await _request('PUT', 'status', body: jsonDecode(raw));
      await _storage.delete(key: _key(_pendingKey));
    } catch (_) {
      if (_disposed) return;
      _timer?.cancel();
      _timer = Timer(const Duration(seconds: 30), () {
        unawaited(retry());
      });
    }
  });

  Future<bool> pauseForReset(AppSnapshot snapshot) async {
    try {
      // An unavailable keychain must not prevent clearing the local app store.
      if (await _storage.read(key: _key(_tokenKey)) == null) return true;
      await setPaused(true, snapshot);
      return true;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _client.close();
  }
}
