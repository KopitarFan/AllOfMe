import { createHash, randomBytes, timingSafeEqual } from 'node:crypto';

export type AuthenticatedDevice = {
  accountId: string;
  deviceId: string;
  deviceLabel?: string;
};

export type DeviceRegistration = AuthenticatedDevice & {
  token: string;
  tokenType: 'Bearer';
};

export type DeviceLinkCode = {
  code: string;
  expiresAt: string;
};

export interface AuthStore {
  registerDevice(options: {
    deviceLabel?: string;
  }): Promise<DeviceRegistration>;
  createDeviceLinkCode(
    device: AuthenticatedDevice,
    options: { expiresAt: Date }
  ): Promise<DeviceLinkCode>;
  redeemDeviceLinkCode(options: {
    code: string;
    deviceLabel?: string;
  }): Promise<DeviceRegistration | null>;
  authenticateToken(token: string): Promise<AuthenticatedDevice | null>;
  close?(): Promise<void> | void;
}

export class MemoryAuthStore implements AuthStore {
  private readonly devicesByTokenHash = new Map<string, AuthenticatedDevice>();
  private readonly linkCodesByHash = new Map<
    string,
    {
      accountId: string;
      createdByDeviceId: string;
      expiresAt: string;
      redeemedAt?: string;
      redeemedByDeviceId?: string;
    }
  >();

  async registerDevice(options: {
    deviceLabel?: string;
  }): Promise<DeviceRegistration> {
    const device = createDeviceRegistration({
      accountId: createServerId('account'),
      deviceLabel: options.deviceLabel
    });

    this.devicesByTokenHash.set(hashAuthToken(device.token), device);
    return device;
  }

  async createDeviceLinkCode(
    device: AuthenticatedDevice,
    options: { expiresAt: Date }
  ): Promise<DeviceLinkCode> {
    const linkCode = createDeviceLinkCode();
    this.linkCodesByHash.set(hashAuthToken(normalizeDeviceLinkCode(linkCode)), {
      accountId: device.accountId,
      createdByDeviceId: device.deviceId,
      expiresAt: options.expiresAt.toISOString()
    });

    return {
      code: linkCode,
      expiresAt: options.expiresAt.toISOString()
    };
  }

  async redeemDeviceLinkCode(options: {
    code: string;
    deviceLabel?: string;
  }): Promise<DeviceRegistration | null> {
    const normalizedCode = normalizeDeviceLinkCode(options.code);
    const codeHash = hashAuthToken(normalizedCode);
    const linkCode = this.linkCodesByHash.get(codeHash);
    if (
      linkCode == null ||
      linkCode.redeemedAt != null ||
      Date.parse(linkCode.expiresAt) <= Date.now()
    ) {
      return null;
    }

    const device = createDeviceRegistration({
      accountId: linkCode.accountId,
      deviceLabel: options.deviceLabel
    });
    this.devicesByTokenHash.set(hashAuthToken(device.token), device);
    linkCode.redeemedAt = new Date().toISOString();
    linkCode.redeemedByDeviceId = device.deviceId;

    return device;
  }

  async authenticateToken(token: string): Promise<AuthenticatedDevice | null> {
    const tokenHash = hashAuthToken(token);
    for (const [storedHash, device] of this.devicesByTokenHash.entries()) {
      if (constantTimeEqual(storedHash, tokenHash)) {
        return device;
      }
    }

    return null;
  }
}

export function createServerId(prefix: string): string {
  return `${prefix}-${Date.now()}-${randomBytes(8).toString('base64url')}`;
}

export function createAuthToken(): string {
  return `aom_${randomBytes(32).toString('base64url')}`;
}

export function createDeviceLinkCode(): string {
  const rawCode = randomBytes(5).toString('hex').toUpperCase();
  return `AOM-${rawCode.slice(0, 5)}-${rawCode.slice(5)}`;
}

export function normalizeDeviceLinkCode(code: string): string {
  const normalized = code.replace(/[\s-]/g, '').toUpperCase();
  if (!/^AOM[0-9A-F]{10}$/.test(normalized)) {
    throw new Error('Device link code is invalid.');
  }
  return normalized;
}

export function hashAuthToken(token: string): string {
  return createHash('sha256').update(token).digest('base64url');
}

function createDeviceRegistration(options: {
  accountId: string;
  deviceLabel?: string;
}): DeviceRegistration {
  const deviceId = createServerId('device');
  const token = createAuthToken();

  return {
    accountId: options.accountId,
    deviceId,
    ...(options.deviceLabel == null
      ? {}
      : { deviceLabel: options.deviceLabel }),
    token,
    tokenType: 'Bearer'
  };
}

function constantTimeEqual(left: string, right: string): boolean {
  const leftBytes = Buffer.from(left);
  const rightBytes = Buffer.from(right);

  return (
    leftBytes.byteLength === rightBytes.byteLength &&
    timingSafeEqual(leftBytes, rightBytes)
  );
}
