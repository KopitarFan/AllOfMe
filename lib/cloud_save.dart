import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'storage.dart';

const int cloudSaveFormatVersion = 1;
const String cloudSavePayloadEncodingBase64 = 'base64';
const String cloudSaveCompressionNone = 'none';
const String cloudSaveEncryptionNone = 'none';
const String cloudSaveEncryptionXchacha20Poly1305 = 'xchacha20-poly1305';
const String cloudSaveKeyDerivationPbkdf2HmacSha256 = 'pbkdf2-hmac-sha256';
const int cloudSaveRecoveryKeyMinLength = 12;
const int cloudSaveRecoveryKeySaltLength = 16;
const int cloudSaveRecoveryKeyBits = 256;
const int cloudSaveRecoveryKeyIterations = 120000;

typedef CloudSavePayloadDecoder =
    FutureOr<List<int>> Function(
      CloudSavePayload payload,
      List<int> payloadBytes,
    );

abstract class CloudSavePayloadEncoder {
  const CloudSavePayloadEncoder();

  FutureOr<CloudSaveEncodedPayload> encode(List<int> backupBytes);
}

class CloudSavePlaintextPayloadEncoder implements CloudSavePayloadEncoder {
  const CloudSavePlaintextPayloadEncoder();

  @override
  CloudSaveEncodedPayload encode(List<int> backupBytes) {
    return CloudSaveEncodedPayload(
      bytes: backupBytes,
      compression: cloudSaveCompressionNone,
      encryption: const CloudSaveEncryptionDescriptor.none(),
    );
  }
}

class CloudSaveRecoveryKey {
  const CloudSaveRecoveryKey._(this.passphrase);

  final String passphrase;

  factory CloudSaveRecoveryKey.fromPassphrase(String passphrase) {
    final normalized = passphrase.trim();
    if (normalized.length < cloudSaveRecoveryKeyMinLength) {
      throw FormatException(
        'Recovery key must be at least $cloudSaveRecoveryKeyMinLength characters.',
      );
    }
    return CloudSaveRecoveryKey._(normalized);
  }
}

class CloudSavePassphrasePayloadCipher implements CloudSavePayloadEncoder {
  CloudSavePassphrasePayloadCipher({
    required this.recoveryKey,
    this.iterations = cloudSaveRecoveryKeyIterations,
    this.keyBits = cloudSaveRecoveryKeyBits,
    this.saltLength = cloudSaveRecoveryKeySaltLength,
    Random? random,
  }) : _random = random ?? Random.secure();

  final CloudSaveRecoveryKey recoveryKey;
  final int iterations;
  final int keyBits;
  final int saltLength;
  final Random _random;

  static final Xchacha20 _cipher = Xchacha20.poly1305Aead();

  @override
  Future<CloudSaveEncodedPayload> encode(List<int> backupBytes) async {
    final salt = _randomBytes(saltLength);
    final nonce = _cipher.newNonce();
    final secretKey = await _deriveKey(salt);
    final secretBox = await _cipher.encrypt(
      backupBytes,
      secretKey: secretKey,
      nonce: nonce,
    );

    return CloudSaveEncodedPayload(
      bytes: secretBox.cipherText,
      compression: cloudSaveCompressionNone,
      encryption: CloudSaveEncryptionDescriptor(
        algorithm: cloudSaveEncryptionXchacha20Poly1305,
        keyDerivationAlgorithm: cloudSaveKeyDerivationPbkdf2HmacSha256,
        keyDerivationIterations: iterations,
        keyLengthBits: keyBits,
        keyId: 'passphrase-recovery-key-v1',
        nonceBase64: base64Encode(secretBox.nonce),
        saltBase64: base64Encode(salt),
        macBase64: base64Encode(secretBox.mac.bytes),
      ),
    );
  }

  Future<List<int>> decode(
    CloudSavePayload payload,
    List<int> payloadBytes,
  ) async {
    final encryption = payload.encryption;
    if (encryption.algorithm != cloudSaveEncryptionXchacha20Poly1305) {
      throw FormatException(
        'Unsupported cloud save encryption: ${encryption.algorithm}.',
      );
    }
    if (encryption.keyDerivationAlgorithm !=
        cloudSaveKeyDerivationPbkdf2HmacSha256) {
      throw FormatException(
        'Unsupported cloud save key derivation: '
        '${encryption.keyDerivationAlgorithm}.',
      );
    }

    final salt = _requiredBase64Bytes(encryption.saltBase64, 'saltBase64');
    final nonce = _requiredBase64Bytes(encryption.nonceBase64, 'nonceBase64');
    final mac = _requiredBase64Bytes(encryption.macBase64, 'macBase64');
    final secretKey = await _deriveKey(
      salt,
      iterationsOverride: encryption.keyDerivationIterations,
      keyBitsOverride: encryption.keyLengthBits,
    );

    return _cipher.decrypt(
      SecretBox(payloadBytes, nonce: nonce, mac: Mac(mac)),
      secretKey: secretKey,
    );
  }

  Future<SecretKey> _deriveKey(
    List<int> salt, {
    int? iterationsOverride,
    int? keyBitsOverride,
  }) {
    final effectiveIterations = iterationsOverride ?? iterations;
    final effectiveKeyBits = keyBitsOverride ?? keyBits;
    if (effectiveIterations <= 0 || effectiveKeyBits <= 0) {
      throw const FormatException('Cloud save key derivation is invalid.');
    }

    return Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: effectiveIterations,
      bits: effectiveKeyBits,
    ).deriveKeyFromPassword(password: recoveryKey.passphrase, nonce: salt);
  }

  List<int> _randomBytes(int length) {
    return List<int>.generate(
      length,
      (_) => _random.nextInt(256),
      growable: false,
    );
  }
}

class CloudSaveEncodedPayload {
  const CloudSaveEncodedPayload({
    required this.bytes,
    required this.compression,
    required this.encryption,
  });

  final List<int> bytes;
  final String compression;
  final CloudSaveEncryptionDescriptor encryption;
}

abstract class CloudSaveAdapter {
  CloudSaveAdapterInfo get info;

  Future<CloudSaveMetadata> saveNow(CloudSavePackage package);

  Future<CloudSaveMetadata?> latestMetadata();

  Future<CloudSavePackage?> downloadLatest();

  Future<List<CloudSaveMetadata>> listVersions();
}

class CloudSaveAdapterInfo {
  const CloudSaveAdapterInfo({
    required this.label,
    required this.location,
    required this.isRemote,
  });

  const CloudSaveAdapterInfo.localPreview()
    : label = 'Local preview',
      location = 'This device',
      isRemote = false;

  final String label;
  final String location;
  final bool isRemote;
}

class MemoryCloudSaveAdapter implements CloudSaveAdapter {
  MemoryCloudSaveAdapter({this.maxVersions = 5});

  final int maxVersions;
  final List<CloudSavePackage> _packages = [];

  @override
  CloudSaveAdapterInfo get info => const CloudSaveAdapterInfo.localPreview();

  @override
  Future<CloudSaveMetadata> saveNow(CloudSavePackage package) async {
    _packages.removeWhere(
      (candidate) => candidate.metadata.saveId == package.metadata.saveId,
    );
    _packages.insert(0, package);
    if (_packages.length > maxVersions) {
      _packages.removeRange(maxVersions, _packages.length);
    }
    return package.metadata;
  }

  @override
  Future<CloudSaveMetadata?> latestMetadata() async {
    return _packages.firstOrNull?.metadata;
  }

  @override
  Future<CloudSavePackage?> downloadLatest() async {
    return _packages.firstOrNull;
  }

  @override
  Future<List<CloudSaveMetadata>> listVersions() async {
    return _packages.map((package) => package.metadata).toList(growable: false);
  }
}

class SharedPreferencesCloudSaveAdapter implements CloudSaveAdapter {
  const SharedPreferencesCloudSaveAdapter({this.maxVersions = 5});

  static const _packagesKey = 'all_of_me.cloud_save.mock.v1.packages';

  final int maxVersions;

  @override
  CloudSaveAdapterInfo get info => const CloudSaveAdapterInfo.localPreview();

  @override
  Future<CloudSaveMetadata> saveNow(CloudSavePackage package) async {
    final packages = await _readPackages();
    packages.removeWhere(
      (candidate) => candidate.metadata.saveId == package.metadata.saveId,
    );
    packages.insert(0, package);
    if (packages.length > maxVersions) {
      packages.removeRange(maxVersions, packages.length);
    }
    await _writePackages(packages);
    return package.metadata;
  }

  @override
  Future<CloudSaveMetadata?> latestMetadata() async {
    return (await downloadLatest())?.metadata;
  }

  @override
  Future<CloudSavePackage?> downloadLatest() async {
    return (await _readPackages()).firstOrNull;
  }

  @override
  Future<List<CloudSaveMetadata>> listVersions() async {
    return (await _readPackages())
        .map((package) => package.metadata)
        .toList(growable: false);
  }

  Future<List<CloudSavePackage>> _readPackages() async {
    final preferences = await SharedPreferences.getInstance();
    final encodedPackages = preferences.getStringList(_packagesKey) ?? const [];
    final packages = <CloudSavePackage>[];
    for (final encodedPackage in encodedPackages) {
      try {
        final decoded = jsonDecode(encodedPackage);
        if (decoded is Map) {
          packages.add(
            CloudSavePackage.fromJson(decoded.cast<String, Object?>()),
          );
        }
      } catch (_) {
        // Ignore corrupted mock saves; the real server adapter should surface
        // download/validation errors explicitly.
      }
    }
    return packages;
  }

  Future<void> _writePackages(List<CloudSavePackage> packages) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _packagesKey,
      packages.map((package) => jsonEncode(package.toJson())).toList(),
    );
  }
}

class CloudSavePackage {
  const CloudSavePackage({
    required this.formatVersion,
    required this.metadata,
    required this.payload,
  });

  final int formatVersion;
  final CloudSaveMetadata metadata;
  final CloudSavePayload payload;

  static Future<CloudSavePackage> fromBackupJson(
    String backupJson, {
    DateTime? createdAt,
    String? saveId,
    String? appVersion,
    String? deviceLabel,
    CloudSavePayloadEncoder payloadEncoder =
        const CloudSavePlaintextPayloadEncoder(),
  }) async {
    final snapshot = snapshotFromBackupJson(backupJson);
    final packagedAt = createdAt ?? DateTime.now();
    final encodedPayload = await payloadEncoder.encode(utf8.encode(backupJson));
    final payloadBytes = List<int>.unmodifiable(encodedPayload.bytes);

    return CloudSavePackage(
      formatVersion: cloudSaveFormatVersion,
      metadata: CloudSaveMetadata(
        saveId: saveId ?? createId('cloud-save'),
        createdAt: packagedAt,
        appName: appDisplayName,
        appVersion: _nullableTrimmed(appVersion),
        snapshotSchemaVersion: snapshot.schemaVersion,
        deviceLabel: _nullableTrimmed(deviceLabel),
        payloadByteCount: payloadBytes.length,
        payloadChecksum: _payloadChecksum(payloadBytes),
      ),
      payload: CloudSavePayload(
        encoding: cloudSavePayloadEncodingBase64,
        compression: encodedPayload.compression,
        encryption: encodedPayload.encryption,
        data: base64Encode(payloadBytes),
      ),
    );
  }

  factory CloudSavePackage.fromJson(Map<String, Object?> json) {
    final formatVersion = _intValue(json['formatVersion']);
    if (formatVersion != cloudSaveFormatVersion) {
      throw FormatException(
        'Unsupported cloud save format version: $formatVersion.',
      );
    }

    return CloudSavePackage(
      formatVersion: formatVersion,
      metadata: CloudSaveMetadata.fromJson(_requiredMap(json, 'metadata')),
      payload: CloudSavePayload.fromJson(_requiredMap(json, 'payload')),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'formatVersion': formatVersion,
      'metadata': metadata.toJson(),
      'payload': payload.toJson(),
    };
  }

  Future<CloudSaveRestoreValidation> validateForRestore({
    CloudSavePayloadDecoder? decoder,
  }) async {
    try {
      final backupJson = await backupJsonForRestore(decoder: decoder);
      final snapshot = snapshotFromBackupJson(backupJson);
      return CloudSaveRestoreValidation.valid(
        backupJson: backupJson,
        snapshot: snapshot,
      );
    } catch (error) {
      return CloudSaveRestoreValidation.invalid(error.toString());
    }
  }

  Future<String> backupJsonForRestore({
    CloudSavePayloadDecoder? decoder,
  }) async {
    final payloadBytes = payload.bytes();
    _validatePayloadIntegrity(payloadBytes);

    final backupBytes = payload.requiresDecoder
        ? await _decodeProtectedPayload(decoder, payloadBytes)
        : payloadBytes;
    return utf8.decode(backupBytes);
  }

  Future<List<int>> _decodeProtectedPayload(
    CloudSavePayloadDecoder? decoder,
    List<int> payloadBytes,
  ) async {
    if (decoder == null) {
      throw const FormatException(
        'Encrypted or compressed cloud save requires a local payload decoder.',
      );
    }
    return decoder(payload, payloadBytes);
  }

  void _validatePayloadIntegrity(List<int> payloadBytes) {
    if (payloadBytes.length != metadata.payloadByteCount) {
      throw FormatException(
        'Cloud save payload size mismatch: expected '
        '${metadata.payloadByteCount}, got ${payloadBytes.length}.',
      );
    }

    final checksum = _payloadChecksum(payloadBytes);
    if (checksum != metadata.payloadChecksum) {
      throw const FormatException('Cloud save payload checksum mismatch.');
    }
  }
}

class CloudSaveMetadata {
  const CloudSaveMetadata({
    required this.saveId,
    required this.createdAt,
    required this.appName,
    required this.snapshotSchemaVersion,
    required this.payloadByteCount,
    required this.payloadChecksum,
    this.appVersion,
    this.deviceLabel,
  });

  final String saveId;
  final DateTime createdAt;
  final String appName;
  final String? appVersion;
  final int snapshotSchemaVersion;
  final String? deviceLabel;
  final int payloadByteCount;
  final String payloadChecksum;

  factory CloudSaveMetadata.fromJson(Map<String, Object?> json) {
    return CloudSaveMetadata(
      saveId: _requiredString(json, 'saveId'),
      createdAt: _requiredDate(json, 'createdAt'),
      appName: _requiredString(json, 'appName'),
      appVersion: _nullableTrimmed(json['appVersion']),
      snapshotSchemaVersion: _intValue(json['snapshotSchemaVersion']),
      deviceLabel: _nullableTrimmed(json['deviceLabel']),
      payloadByteCount: _intValue(json['payloadByteCount']),
      payloadChecksum: _requiredString(json, 'payloadChecksum'),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'saveId': saveId,
      'createdAt': createdAt.toIso8601String(),
      'appName': appName,
      if (appVersion != null) 'appVersion': appVersion,
      'snapshotSchemaVersion': snapshotSchemaVersion,
      if (deviceLabel != null) 'deviceLabel': deviceLabel,
      'payloadByteCount': payloadByteCount,
      'payloadChecksum': payloadChecksum,
    };
  }
}

class CloudSavePayload {
  const CloudSavePayload({
    required this.encoding,
    required this.compression,
    required this.encryption,
    required this.data,
  });

  final String encoding;
  final String compression;
  final CloudSaveEncryptionDescriptor encryption;
  final String data;

  bool get requiresDecoder =>
      encryption.isEncrypted || compression != cloudSaveCompressionNone;

  factory CloudSavePayload.fromJson(Map<String, Object?> json) {
    return CloudSavePayload(
      encoding: _requiredString(json, 'encoding'),
      compression: _requiredString(json, 'compression'),
      encryption: CloudSaveEncryptionDescriptor.fromJson(
        _requiredMap(json, 'encryption'),
      ),
      data: _requiredString(json, 'data'),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'encoding': encoding,
      'compression': compression,
      'encryption': encryption.toJson(),
      'data': data,
    };
  }

  List<int> bytes() {
    if (encoding != cloudSavePayloadEncodingBase64) {
      throw FormatException(
        'Unsupported cloud save payload encoding: $encoding.',
      );
    }
    return base64Decode(data);
  }
}

class CloudSaveEncryptionDescriptor {
  const CloudSaveEncryptionDescriptor({
    required this.algorithm,
    this.keyDerivationAlgorithm,
    this.keyDerivationIterations,
    this.keyLengthBits,
    this.keyId,
    this.nonceBase64,
    this.saltBase64,
    this.macBase64,
  });

  const CloudSaveEncryptionDescriptor.none()
    : algorithm = cloudSaveEncryptionNone,
      keyDerivationAlgorithm = null,
      keyDerivationIterations = null,
      keyLengthBits = null,
      keyId = null,
      nonceBase64 = null,
      saltBase64 = null,
      macBase64 = null;

  final String algorithm;
  final String? keyDerivationAlgorithm;
  final int? keyDerivationIterations;
  final int? keyLengthBits;
  final String? keyId;
  final String? nonceBase64;
  final String? saltBase64;
  final String? macBase64;

  bool get isEncrypted => algorithm != cloudSaveEncryptionNone;

  factory CloudSaveEncryptionDescriptor.fromJson(Map<String, Object?> json) {
    return CloudSaveEncryptionDescriptor(
      algorithm: _requiredString(json, 'algorithm'),
      keyDerivationAlgorithm: _nullableTrimmed(json['keyDerivationAlgorithm']),
      keyDerivationIterations: _nullableIntValue(
        json['keyDerivationIterations'],
      ),
      keyLengthBits: _nullableIntValue(json['keyLengthBits']),
      keyId: _nullableTrimmed(json['keyId']),
      nonceBase64: _nullableTrimmed(json['nonceBase64']),
      saltBase64: _nullableTrimmed(json['saltBase64']),
      macBase64: _nullableTrimmed(json['macBase64']),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'algorithm': algorithm,
      if (keyDerivationAlgorithm != null)
        'keyDerivationAlgorithm': keyDerivationAlgorithm,
      if (keyDerivationIterations != null)
        'keyDerivationIterations': keyDerivationIterations,
      if (keyLengthBits != null) 'keyLengthBits': keyLengthBits,
      if (keyId != null) 'keyId': keyId,
      if (nonceBase64 != null) 'nonceBase64': nonceBase64,
      if (saltBase64 != null) 'saltBase64': saltBase64,
      if (macBase64 != null) 'macBase64': macBase64,
    };
  }
}

class CloudSaveRestoreValidation {
  const CloudSaveRestoreValidation._({
    required this.isValid,
    this.backupJson,
    this.snapshot,
    this.errorMessage,
  });

  final bool isValid;
  final String? backupJson;
  final AppSnapshot? snapshot;
  final String? errorMessage;

  factory CloudSaveRestoreValidation.valid({
    required String backupJson,
    required AppSnapshot snapshot,
  }) {
    return CloudSaveRestoreValidation._(
      isValid: true,
      backupJson: backupJson,
      snapshot: snapshot,
    );
  }

  factory CloudSaveRestoreValidation.invalid(String errorMessage) {
    return CloudSaveRestoreValidation._(
      isValid: false,
      errorMessage: errorMessage,
    );
  }
}

String _payloadChecksum(List<int> bytes) {
  var hash = 0x811c9dc5;
  for (final byte in bytes) {
    hash ^= byte;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return 'fnv1a32:${hash.toRadixString(16).padLeft(8, '0')}';
}

Map<String, Object?> _requiredMap(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is Map<String, Object?>) {
    return value;
  }
  if (value is Map) {
    return value.cast<String, Object?>();
  }
  throw FormatException('Cloud save field "$key" must be a JSON object.');
}

String _requiredString(Map<String, Object?> json, String key) {
  final value = _nullableTrimmed(json[key]);
  if (value == null) {
    throw FormatException('Cloud save field "$key" must be a string.');
  }
  return value;
}

DateTime _requiredDate(Map<String, Object?> json, String key) {
  final value = _requiredString(json, key);
  final date = DateTime.tryParse(value);
  if (date == null) {
    throw FormatException('Cloud save field "$key" must be an ISO date.');
  }
  return date;
}

int _intValue(Object? value) {
  if (value is int) {
    return value;
  }
  throw const FormatException('Cloud save field must be an integer.');
}

int? _nullableIntValue(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  throw const FormatException('Cloud save field must be an integer.');
}

List<int> _requiredBase64Bytes(String? value, String key) {
  if (value == null) {
    throw FormatException('Cloud save encryption field "$key" is missing.');
  }
  try {
    return base64Decode(value);
  } catch (_) {
    throw FormatException('Cloud save encryption field "$key" is invalid.');
  }
}

String? _nullableTrimmed(Object? value) {
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }
  return null;
}
