import { z, type ZodError } from 'zod';

export const cloudSaveFormatVersion = 1;
export const cloudSavePayloadEncodingBase64 = 'base64';
export const cloudSaveCompressionNone = 'none';
export const cloudSaveEncryptionXchacha20Poly1305 = 'xchacha20-poly1305';
export const cloudSaveKeyDerivationPbkdf2HmacSha256 =
  'pbkdf2-hmac-sha256';

const cloudSaveEncryptionSchema = z
  .object({
    algorithm: z.literal(cloudSaveEncryptionXchacha20Poly1305),
    keyDerivationAlgorithm: z.literal(
      cloudSaveKeyDerivationPbkdf2HmacSha256
    ),
    keyDerivationIterations: z.number().int().positive(),
    keyLengthBits: z.number().int().positive(),
    keyId: z.string().trim().min(1).max(128),
    nonceBase64: z.string().trim().min(1),
    saltBase64: z.string().trim().min(1),
    macBase64: z.string().trim().min(1)
  })
  .strict();

export const cloudSaveIdSchema = z
  .string()
  .trim()
  .min(1)
  .max(128)
  .regex(/^[A-Za-z0-9][A-Za-z0-9._:-]*$/);

const cloudSaveMetadataSchema = z
  .object({
    saveId: cloudSaveIdSchema,
    createdAt: z
      .string()
      .trim()
      .min(1)
      .refine((value) => !Number.isNaN(Date.parse(value))),
    appName: z.string().trim().min(1).max(100),
    appVersion: z.string().trim().min(1).max(50).optional(),
    snapshotSchemaVersion: z.number().int().positive(),
    deviceLabel: z.string().trim().min(1).max(100).optional(),
    payloadByteCount: z.number().int().positive(),
    payloadChecksum: z.string().regex(/^fnv1a32:[0-9a-f]{8}$/)
  })
  .strict();

const cloudSavePayloadSchema = z
  .object({
    encoding: z.literal(cloudSavePayloadEncodingBase64),
    compression: z.literal(cloudSaveCompressionNone),
    encryption: cloudSaveEncryptionSchema,
    data: z.string().trim().min(1)
  })
  .strict();

export const cloudSavePackageSchema = z
  .object({
    formatVersion: z.literal(cloudSaveFormatVersion),
    metadata: cloudSaveMetadataSchema,
    payload: cloudSavePayloadSchema
  })
  .strict();

export type CloudSavePackage = z.infer<typeof cloudSavePackageSchema>;
export type CloudSaveMetadata = z.infer<typeof cloudSaveMetadataSchema>;

export class CloudSavePackageValidationError extends Error {
  constructor(
    message: string,
    readonly statusCode = 400
  ) {
    super(message);
  }
}

export function parseCloudSavePackage(
  input: unknown,
  options: { maxPayloadBytes: number }
): CloudSavePackage {
  const parsed = cloudSavePackageSchema.safeParse(input);
  if (!parsed.success) {
    throw new CloudSavePackageValidationError(zodMessage(parsed.error));
  }

  validateCloudSavePackage(parsed.data, options);
  return parsed.data;
}

export function parseCloudSaveId(input: unknown): string {
  const parsed = cloudSaveIdSchema.safeParse(input);
  if (!parsed.success) {
    throw new CloudSavePackageValidationError(
      'Cloud save field "saveId" is invalid.'
    );
  }

  return parsed.data;
}

export function cloudSavePayloadChecksum(bytes: Uint8Array): string {
  let hash = 0x811c9dc5;
  for (const byte of bytes) {
    hash ^= byte;
    hash = Math.imul(hash, 0x01000193) >>> 0;
  }

  return `fnv1a32:${hash.toString(16).padStart(8, '0')}`;
}

function validateCloudSavePackage(
  cloudSavePackage: CloudSavePackage,
  options: { maxPayloadBytes: number }
): void {
  const { metadata, payload } = cloudSavePackage;

  if (metadata.payloadByteCount > options.maxPayloadBytes) {
    throw new CloudSavePackageValidationError(
      'Cloud save payload is too large.',
      413
    );
  }

  const maxPayloadEncodedLength = base64EncodedLength(
    options.maxPayloadBytes
  );
  if (payload.data.length > maxPayloadEncodedLength) {
    throw new CloudSavePackageValidationError(
      'Cloud save payload is too large.',
      413
    );
  }

  const expectedPayloadEncodedLength = base64EncodedLength(
    metadata.payloadByteCount
  );
  if (payload.data.length !== expectedPayloadEncodedLength) {
    throw new CloudSavePackageValidationError(
      'Cloud save payload byte count does not match metadata.'
    );
  }

  const payloadBytes = decodeBase64(payload.data, 'payload.data');
  if (payloadBytes.byteLength !== metadata.payloadByteCount) {
    throw new CloudSavePackageValidationError(
      'Cloud save payload byte count does not match metadata.'
    );
  }

  if (cloudSavePayloadChecksum(payloadBytes) !== metadata.payloadChecksum) {
    throw new CloudSavePackageValidationError(
      'Cloud save payload checksum does not match metadata.'
    );
  }

  const nonce = decodeBase64(payload.encryption.nonceBase64, 'nonceBase64');
  if (nonce.byteLength !== 24) {
    throw new CloudSavePackageValidationError(
      'Cloud save encryption nonce is invalid.'
    );
  }

  const salt = decodeBase64(payload.encryption.saltBase64, 'saltBase64');
  if (salt.byteLength !== 16) {
    throw new CloudSavePackageValidationError(
      'Cloud save encryption salt is invalid.'
    );
  }

  const mac = decodeBase64(payload.encryption.macBase64, 'macBase64');
  if (mac.byteLength !== 16) {
    throw new CloudSavePackageValidationError(
      'Cloud save encryption MAC is invalid.'
    );
  }
}

function decodeBase64(value: string, fieldName: string): Buffer {
  if (!isCanonicalBase64Text(value)) {
    throw new CloudSavePackageValidationError(
      `Cloud save field "${fieldName}" must be base64.`
    );
  }

  const bytes = Buffer.from(value, 'base64');
  if (bytes.toString('base64') !== value) {
    throw new CloudSavePackageValidationError(
      `Cloud save field "${fieldName}" must be base64.`
    );
  }

  return bytes;
}

function base64EncodedLength(byteLength: number): number {
  return Math.ceil(byteLength / 3) * 4;
}

function isCanonicalBase64Text(value: string): boolean {
  if (value.length === 0 || value.length % 4 !== 0) {
    return false;
  }

  let paddingCount = 0;
  for (let index = value.length - 1; index >= 0; index -= 1) {
    if (value[index] !== '=') {
      break;
    }
    paddingCount += 1;
  }

  if (paddingCount > 2) {
    return false;
  }

  const dataLength = value.length - paddingCount;
  for (let index = 0; index < value.length; index += 1) {
    const charCode = value.charCodeAt(index);
    if (index >= dataLength) {
      if (charCode !== 61) {
        return false;
      }
      continue;
    }

    if (!isBase64DataCharacter(charCode)) {
      return false;
    }
  }

  return true;
}

function isBase64DataCharacter(charCode: number): boolean {
  return (
    (charCode >= 65 && charCode <= 90) ||
    (charCode >= 97 && charCode <= 122) ||
    (charCode >= 48 && charCode <= 57) ||
    charCode === 43 ||
    charCode === 47
  );
}

function zodMessage(error: ZodError): string {
  const [issue] = error.issues;
  if (!issue) {
    return 'Cloud save package is invalid.';
  }

  const path = issue.path.join('.');
  return path.length > 0
    ? `Cloud save field "${path}" is invalid.`
    : 'Cloud save package is invalid.';
}
