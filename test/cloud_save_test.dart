import 'dart:convert';

import 'package:all_of_me_demo/cloud_save.dart';
import 'package:all_of_me_demo/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds a cloud save package from backup JSON', () async {
    final snapshot = AppSnapshot.seeded(DateTime(2026, 6, 21));
    final backupJson = snapshot.toBackupJson();
    final package = await CloudSavePackage.fromBackupJson(
      backupJson,
      createdAt: DateTime.utc(2026, 6, 22, 1, 2, 3),
      saveId: 'cloud-save-test',
      appVersion: '1.0.0+4',
      deviceLabel: 'iPhone',
    );

    expect(package.formatVersion, cloudSaveFormatVersion);
    expect(package.metadata.saveId, 'cloud-save-test');
    expect(package.metadata.appName, appDisplayName);
    expect(package.metadata.appVersion, '1.0.0+4');
    expect(package.metadata.deviceLabel, 'iPhone');
    expect(package.metadata.snapshotSchemaVersion, snapshot.schemaVersion);
    expect(package.metadata.payloadByteCount, utf8.encode(backupJson).length);
    expect(package.metadata.payloadChecksum, startsWith('fnv1a32:'));
    expect(package.payload.encoding, cloudSavePayloadEncodingBase64);
    expect(package.payload.compression, cloudSaveCompressionNone);
    expect(package.payload.encryption.isEncrypted, isFalse);
  });

  test('serializes without readable snapshot details in metadata', () async {
    final snapshot = AppSnapshot.seeded(DateTime(2026, 6, 21));
    final package = await CloudSavePackage.fromBackupJson(
      snapshot.toBackupJson(),
      saveId: 'cloud-save-test',
      createdAt: DateTime.utc(2026, 6, 22),
    );
    final metadataJson = jsonEncode(package.metadata.toJson());
    final packageJson = jsonEncode(package.toJson());

    expect(metadataJson, isNot(contains(snapshot.members.first.name)));
    expect(metadataJson, isNot(contains(snapshot.profile.description)));
    expect(packageJson, isNot(contains(snapshot.members.first.name)));
  });

  test('round trips through JSON and validates restore locally', () async {
    final snapshot = AppSnapshot.seeded(DateTime(2026, 6, 21));
    final backupJson = snapshot.toBackupJson();
    final package = await CloudSavePackage.fromBackupJson(
      backupJson,
      saveId: 'cloud-save-test',
      createdAt: DateTime.utc(2026, 6, 22),
    );
    final restoredPackage = CloudSavePackage.fromJson(
      (jsonDecode(jsonEncode(package.toJson())) as Map).cast<String, Object?>(),
    );

    final validation = await restoredPackage.validateForRestore();

    expect(validation.isValid, isTrue);
    expect(validation.errorMessage, isNull);
    expect(validation.backupJson, backupJson);
    expect(validation.snapshot?.profile.displayName, appDisplayName);
    expect(validation.snapshot?.members.length, snapshot.members.length);
  });

  test(
    'uses payload encoder before packaging and decoder before restore',
    () async {
      final snapshot = AppSnapshot.seeded(DateTime(2026, 6, 21));
      final backupJson = snapshot.toBackupJson();
      final package = await CloudSavePackage.fromBackupJson(
        backupJson,
        saveId: 'cloud-save-test',
        createdAt: DateTime.utc(2026, 6, 22),
        payloadEncoder: const _ReversingCloudSavePayloadEncoder(),
      );

      expect(package.payload.encryption.algorithm, 'test-reverse');
      expect(package.payload.encryption.isEncrypted, isTrue);
      expect((await package.validateForRestore()).isValid, isFalse);

      final validation = await package.validateForRestore(
        decoder: _reverseCloudSavePayload,
      );

      expect(validation.isValid, isTrue);
      expect(validation.backupJson, backupJson);
      expect(validation.snapshot?.profile.displayName, appDisplayName);
    },
  );

  test('encrypts and decrypts with a passphrase recovery key', () async {
    final snapshot = AppSnapshot.seeded(DateTime(2026, 6, 21));
    final backupJson = snapshot.toBackupJson();
    final recoveryKey = CloudSaveRecoveryKey.fromPassphrase(
      'correct horse battery staple',
    );
    final cipher = CloudSavePassphrasePayloadCipher(
      recoveryKey: recoveryKey,
      iterations: 2,
    );
    final package = await CloudSavePackage.fromBackupJson(
      backupJson,
      saveId: 'cloud-save-test',
      createdAt: DateTime.utc(2026, 6, 22),
      payloadEncoder: cipher,
    );

    expect(
      package.payload.encryption.algorithm,
      cloudSaveEncryptionXchacha20Poly1305,
    );
    expect(
      package.payload.encryption.keyDerivationAlgorithm,
      cloudSaveKeyDerivationPbkdf2HmacSha256,
    );
    expect(package.payload.encryption.keyDerivationIterations, 2);
    expect(package.payload.encryption.saltBase64, isNotNull);
    expect(package.payload.encryption.nonceBase64, isNotNull);
    expect(package.payload.encryption.macBase64, isNotNull);
    expect(
      package.payload.bytes(),
      isNot(orderedEquals(utf8.encode(backupJson))),
    );

    final validation = await package.validateForRestore(decoder: cipher.decode);

    expect(validation.isValid, isTrue);
    expect(validation.backupJson, backupJson);
    expect(validation.snapshot?.profile.displayName, appDisplayName);
  });

  test('rejects invalid backup JSON before packaging', () {
    expect(CloudSavePackage.fromBackupJson('not json'), throwsFormatException);
  });

  test('restore validation catches tampered payload data', () async {
    final snapshot = AppSnapshot.seeded(DateTime(2026, 6, 21));
    final package = await CloudSavePackage.fromBackupJson(
      snapshot.toBackupJson(),
      saveId: 'cloud-save-test',
      createdAt: DateTime.utc(2026, 6, 22),
    );
    final packageJson = package.toJson();
    final payloadJson = packageJson['payload']! as Map<String, Object?>;
    final tamperedPayloadBytes = package.payload.bytes().toList();
    tamperedPayloadBytes[tamperedPayloadBytes.length - 1] =
        tamperedPayloadBytes.last ^ 1;
    payloadJson['data'] = base64Encode(tamperedPayloadBytes);
    final tampered = CloudSavePackage.fromJson(packageJson);

    final validation = await tampered.validateForRestore();

    expect(validation.isValid, isFalse);
    expect(validation.errorMessage, contains('checksum mismatch'));
  });

  test('encrypted payload descriptors require a local decoder', () async {
    final snapshot = AppSnapshot.seeded(DateTime(2026, 6, 21));
    final package = await CloudSavePackage.fromBackupJson(
      snapshot.toBackupJson(),
      saveId: 'cloud-save-test',
      createdAt: DateTime.utc(2026, 6, 22),
    );
    final encrypted = CloudSavePackage(
      formatVersion: package.formatVersion,
      metadata: package.metadata,
      payload: CloudSavePayload(
        encoding: package.payload.encoding,
        compression: package.payload.compression,
        encryption: const CloudSaveEncryptionDescriptor(
          algorithm: 'xchacha20-poly1305',
          keyDerivationAlgorithm: 'argon2id',
          keyId: 'device-local-key',
          nonceBase64: 'bm9uY2U=',
          saltBase64: 'c2FsdA==',
        ),
        data: package.payload.data,
      ),
    );

    expect((await encrypted.validateForRestore()).isValid, isFalse);

    final validation = await encrypted.validateForRestore(
      decoder: (_, payloadBytes) => payloadBytes,
    );

    expect(validation.isValid, isTrue);
    expect(validation.snapshot?.profile.displayName, appDisplayName);
  });

  test('memory adapter stores latest package and caps versions', () async {
    final adapter = MemoryCloudSaveAdapter(maxVersions: 2);
    final snapshot = AppSnapshot.seeded(DateTime(2026, 6, 21));
    final first = await CloudSavePackage.fromBackupJson(
      snapshot.toBackupJson(),
      saveId: 'cloud-save-first',
      createdAt: DateTime.utc(2026, 6, 22, 1),
    );
    final second = await CloudSavePackage.fromBackupJson(
      snapshot.toBackupJson(),
      saveId: 'cloud-save-second',
      createdAt: DateTime.utc(2026, 6, 22, 2),
    );
    final third = await CloudSavePackage.fromBackupJson(
      snapshot.toBackupJson(),
      saveId: 'cloud-save-third',
      createdAt: DateTime.utc(2026, 6, 22, 3),
    );

    await adapter.saveNow(first);
    await adapter.saveNow(second);
    await adapter.saveNow(third);

    expect((await adapter.latestMetadata())?.saveId, 'cloud-save-third');
    expect(
      (await adapter.downloadLatest())?.metadata.saveId,
      'cloud-save-third',
    );
    expect((await adapter.listVersions()).map((metadata) => metadata.saveId), [
      'cloud-save-third',
      'cloud-save-second',
    ]);
  });
}

class _ReversingCloudSavePayloadEncoder implements CloudSavePayloadEncoder {
  const _ReversingCloudSavePayloadEncoder();

  @override
  CloudSaveEncodedPayload encode(List<int> backupBytes) {
    return CloudSaveEncodedPayload(
      bytes: backupBytes.reversed.toList(),
      compression: cloudSaveCompressionNone,
      encryption: const CloudSaveEncryptionDescriptor(
        algorithm: 'test-reverse',
        keyDerivationAlgorithm: 'test-only',
        keyId: 'unit-test-key',
      ),
    );
  }
}

List<int> _reverseCloudSavePayload(CloudSavePayload _, List<int> payloadBytes) {
  return payloadBytes.reversed.toList();
}
