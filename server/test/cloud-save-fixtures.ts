import { Buffer } from 'node:buffer';

import {
  cloudSaveCompressionNone,
  cloudSaveEncryptionXchacha20Poly1305,
  cloudSaveFormatVersion,
  cloudSaveKeyDerivationPbkdf2HmacSha256,
  cloudSavePayloadChecksum,
  cloudSavePayloadEncodingBase64,
  type CloudSavePackage
} from '../src/cloud-save-package.js';

export function createCloudSavePackage(
  options: {
    saveId?: string;
    createdAt?: string;
    payloadBytes?: Buffer;
  } = {}
): CloudSavePackage {
  const payloadBytes = options.payloadBytes ?? Buffer.from('encrypted-backup');

  return {
    formatVersion: cloudSaveFormatVersion,
    metadata: {
      saveId: options.saveId ?? 'cloud-save-1782177600000000',
      createdAt: options.createdAt ?? '2026-06-22T18:40:00.000',
      appName: 'All Of Me',
      appVersion: '1.0.0+10',
      snapshotSchemaVersion: 3,
      deviceLabel: 'Miguel iPhone',
      payloadByteCount: payloadBytes.byteLength,
      payloadChecksum: cloudSavePayloadChecksum(payloadBytes)
    },
    payload: {
      encoding: cloudSavePayloadEncodingBase64,
      compression: cloudSaveCompressionNone,
      encryption: {
        algorithm: cloudSaveEncryptionXchacha20Poly1305,
        keyDerivationAlgorithm: cloudSaveKeyDerivationPbkdf2HmacSha256,
        keyDerivationIterations: 120000,
        keyLengthBits: 256,
        keyId: 'passphrase-recovery-key-v1',
        nonceBase64: Buffer.alloc(24, 1).toString('base64'),
        saltBase64: Buffer.alloc(16, 2).toString('base64'),
        macBase64: Buffer.alloc(16, 3).toString('base64')
      },
      data: payloadBytes.toString('base64')
    }
  };
}
