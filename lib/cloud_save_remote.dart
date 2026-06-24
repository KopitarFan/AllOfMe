import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'cloud_save.dart';

abstract class CloudSaveCredentialsProvider {
  const CloudSaveCredentialsProvider();

  FutureOr<String?> bearerToken();
}

class EmptyCloudSaveCredentialsProvider
    implements CloudSaveCredentialsProvider {
  const EmptyCloudSaveCredentialsProvider();

  @override
  String? bearerToken() => null;
}

class StaticCloudSaveCredentialsProvider
    implements CloudSaveCredentialsProvider {
  const StaticCloudSaveCredentialsProvider(this.token);

  final String? token;

  @override
  String? bearerToken() => _trimmedOrNull(token);
}

class CloudSaveRemoteException implements Exception {
  const CloudSaveRemoteException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() {
    final code = statusCode;
    if (code == null) {
      return 'CloudSaveRemoteException: $message';
    }
    return 'CloudSaveRemoteException($code): $message';
  }
}

class RemoteCloudSaveAdapter implements CloudSaveAdapter {
  RemoteCloudSaveAdapter({
    required Uri baseUrl,
    this.accountLabel,
    this.credentialsProvider = const EmptyCloudSaveCredentialsProvider(),
    http.Client? client,
    this.timeout = const Duration(seconds: 20),
  }) : baseUrl = _normalizeBaseUrl(baseUrl),
       _client = client ?? http.Client();

  static const _savesPath = 'v1/saves';

  final Uri baseUrl;
  final String? accountLabel;
  final CloudSaveCredentialsProvider credentialsProvider;
  final Duration timeout;
  final http.Client _client;

  @override
  CloudSaveAdapterInfo get info => CloudSaveAdapterInfo(
    label: accountLabel == null
        ? 'Remote cloud save'
        : 'Cloud save for $accountLabel',
    location: baseUrl.toString(),
    isRemote: true,
    accountLabel: accountLabel,
  );

  @override
  Future<CloudSaveMetadata> saveNow(CloudSavePackage package) async {
    final response = await _postJson(_savesPath, package.toJson());
    _ensureSuccess(response, action: 'save cloud save');
    if (response.body.trim().isEmpty) {
      return package.metadata;
    }

    final decoded = _decodeObject(response, action: 'read saved metadata');
    return CloudSaveMetadata.fromJson(_metadataMap(decoded));
  }

  @override
  Future<CloudSaveMetadata?> latestMetadata() async {
    final versions = await listVersions();
    return versions.isEmpty ? null : versions.first;
  }

  @override
  Future<CloudSavePackage?> downloadLatest() async {
    final response = await _get('$_savesPath/latest');
    if (response.statusCode == 404) {
      return null;
    }
    _ensureSuccess(response, action: 'download latest cloud save');
    return CloudSavePackage.fromJson(
      _decodeObject(response, action: 'read latest cloud save'),
    );
  }

  @override
  Future<List<CloudSaveMetadata>> listVersions() async {
    final response = await _get(_savesPath);
    if (response.statusCode == 404) {
      return const [];
    }
    _ensureSuccess(response, action: 'list cloud save versions');
    final decoded = _decodeJson(response, action: 'read cloud save versions');
    final items = switch (decoded) {
      final List list => list.cast<Object?>(),
      final Map map =>
        _listValue(_objectMap(map)['versions']) ??
            _listValue(_objectMap(map)['items']),
      _ => null,
    };
    if (items == null) {
      throw const CloudSaveRemoteException(
        'Cloud save versions response was not a JSON list.',
      );
    }

    return items
        .map(
          (item) => CloudSaveMetadata.fromJson(_metadataMap(_objectMap(item))),
        )
        .toList(growable: false);
  }

  Future<http.Response> _get(String path) {
    return _headers()
        .then((headers) => _client.get(_resolve(path), headers: headers))
        .timeout(timeout, onTimeout: () => throw _timeoutException(path));
  }

  Future<http.Response> _postJson(String path, Map<String, Object?> body) {
    return _headers(hasJsonBody: true)
        .then(
          (headers) => _client.post(
            _resolve(path),
            headers: headers,
            body: jsonEncode(body),
          ),
        )
        .timeout(timeout, onTimeout: () => throw _timeoutException(path));
  }

  Future<Map<String, String>> _headers({bool hasJsonBody = false}) async {
    final bearerToken = _trimmedOrNull(await credentialsProvider.bearerToken());
    return {
      'accept': 'application/json',
      if (hasJsonBody) 'content-type': 'application/json; charset=utf-8',
      if (bearerToken != null) 'authorization': 'Bearer $bearerToken',
    };
  }

  Uri _resolve(String path) => baseUrl.resolve(path);

  CloudSaveRemoteException _timeoutException(String path) {
    return CloudSaveRemoteException(
      'Timed out contacting cloud save endpoint ${_resolve(path)}.',
    );
  }

  static Uri _normalizeBaseUrl(Uri baseUrl) {
    final scheme = baseUrl.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') {
      throw FormatException(
        'Cloud save base URL must use http or https: $baseUrl',
      );
    }
    if (baseUrl.host.isEmpty) {
      throw FormatException('Cloud save base URL needs a host: $baseUrl');
    }

    final path = baseUrl.path.endsWith('/') ? baseUrl.path : '${baseUrl.path}/';
    return Uri(
      scheme: scheme,
      userInfo: baseUrl.userInfo,
      host: baseUrl.host,
      port: baseUrl.hasPort ? baseUrl.port : null,
      path: path,
    );
  }
}

void _ensureSuccess(http.Response response, {required String action}) {
  if (response.statusCode >= 200 && response.statusCode < 300) {
    return;
  }
  throw CloudSaveRemoteException(
    'Could not $action.',
    statusCode: response.statusCode,
  );
}

Object? _decodeJson(http.Response response, {required String action}) {
  try {
    return jsonDecode(utf8.decode(response.bodyBytes));
  } catch (error) {
    throw CloudSaveRemoteException('Could not $action: invalid JSON.');
  }
}

Map<String, Object?> _decodeObject(
  http.Response response, {
  required String action,
}) {
  return _objectMap(_decodeJson(response, action: action));
}

Map<String, Object?> _objectMap(Object? value) {
  if (value is Map<String, Object?>) {
    return value;
  }
  if (value is Map) {
    return value.cast<String, Object?>();
  }
  throw const CloudSaveRemoteException(
    'Cloud save response was not an object.',
  );
}

Map<String, Object?> _metadataMap(Map<String, Object?> json) {
  final metadata = json['metadata'];
  if (metadata == null) {
    return json;
  }
  return _objectMap(metadata);
}

List<Object?>? _listValue(Object? value) {
  if (value is List<Object?>) {
    return value;
  }
  if (value is List) {
    return value.cast<Object?>();
  }
  return null;
}

String? _trimmedOrNull(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
