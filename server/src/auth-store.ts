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

export interface AuthStore {
  registerDevice(options: {
    deviceLabel?: string;
  }): Promise<DeviceRegistration>;
  authenticateToken(token: string): Promise<AuthenticatedDevice | null>;
  close?(): Promise<void> | void;
}

export class MemoryAuthStore implements AuthStore {
  private readonly devicesByTokenHash = new Map<string, AuthenticatedDevice>();

  async registerDevice(options: {
    deviceLabel?: string;
  }): Promise<DeviceRegistration> {
    const accountId = createServerId('account');
    const deviceId = createServerId('device');
    const token = createAuthToken();
    const device = {
      accountId,
      deviceId,
      ...(options.deviceLabel == null
        ? {}
        : { deviceLabel: options.deviceLabel })
    };

    this.devicesByTokenHash.set(hashAuthToken(token), device);

    return {
      ...device,
      token,
      tokenType: 'Bearer'
    };
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

export function hashAuthToken(token: string): string {
  return createHash('sha256').update(token).digest('base64url');
}

function constantTimeEqual(left: string, right: string): boolean {
  const leftBytes = Buffer.from(left);
  const rightBytes = Buffer.from(right);

  return (
    leftBytes.byteLength === rightBytes.byteLength &&
    timingSafeEqual(leftBytes, rightBytes)
  );
}
