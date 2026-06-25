import { Buffer } from 'node:buffer';
import { access, mkdtemp, rm } from 'node:fs/promises';
import { join } from 'node:path';
import { tmpdir } from 'node:os';

import { describe, expect, test } from 'vitest';

import {
  deleteAdminAccount,
  getAdminAccount,
  getAdminStats,
  listAdminAccounts,
  revokeAdminDevice
} from '../src/admin.js';
import { createLocalCloudSaveStore } from '../src/local-cloud-save-store.js';
import { createCloudSavePackage } from './cloud-save-fixtures.js';

describe('admin commands', () => {
  test('reports stats and account metadata without reading plaintext data', async () => {
    const dataDirectory = await createTempDataDirectory();

    try {
      const store = await createLocalCloudSaveStore({
        dataDirectory,
        maxVersions: 5
      });
      try {
        const device = await store.registerDevice({
          deviceLabel: 'Miguel iPhone'
        });
        await store.save(
          device,
          createCloudSavePackage({
            saveId: 'cloud-save-admin-stats',
            payloadBytes: Buffer.from('encrypted-admin-stats')
          })
        );
        await store.createDeviceLinkCode(device, {
          expiresAt: new Date(Date.now() + 10 * 60 * 1000)
        });
      } finally {
        store.close();
      }

      const stats = await getAdminStats({ dataDirectory });
      expect(stats.accounts).toBe(1);
      expect(stats.devices).toMatchObject({
        total: 1,
        active: 1,
        revoked: 0
      });
      expect(stats.saves.total).toBe(1);
      expect(stats.saves.payloadBytes).toBeGreaterThan(0);
      expect(stats.saves.packageFileBytes).toBeGreaterThan(0);
      expect(stats.linkCodes.active).toBe(1);

      const accounts = await listAdminAccounts({ dataDirectory });
      expect(accounts).toHaveLength(1);
      expect(accounts[0]).toMatchObject({
        activeDeviceCount: 1,
        saveCount: 1
      });

      const account = await getAdminAccount({
        dataDirectory,
        accountId: accounts[0]!.accountId
      });
      expect(account.devices[0]).toMatchObject({
        deviceLabel: 'Miguel iPhone',
        tokenStatus: 'active'
      });
      expect(account.saves[0]?.saveId).toBe('cloud-save-admin-stats');
      expect(account.linkCodes[0]?.status).toBe('active');
    } finally {
      await rm(dataDirectory, { force: true, recursive: true });
    }
  });

  test('revokes a device token without deleting device metadata', async () => {
    const dataDirectory = await createTempDataDirectory();

    try {
      const store = await createLocalCloudSaveStore({
        dataDirectory,
        maxVersions: 5
      });
      const device = await store.registerDevice({
        deviceLabel: 'Miguel iPhone'
      });
      store.close();

      const result = await revokeAdminDevice({
        dataDirectory,
        deviceId: device.deviceId
      });
      expect(result).toMatchObject({
        accountId: device.accountId,
        deviceId: device.deviceId,
        deviceLabel: 'Miguel iPhone',
        tokenStatus: 'revoked',
        changed: true
      });

      const reopenedStore = await createLocalCloudSaveStore({
        dataDirectory,
        maxVersions: 5
      });
      try {
        await expect(
          reopenedStore.authenticateToken(device.token)
        ).resolves.toBeNull();
      } finally {
        reopenedStore.close();
      }

      const account = await getAdminAccount({
        dataDirectory,
        accountId: device.accountId
      });
      expect(account.devices[0]).toMatchObject({
        deviceId: device.deviceId,
        tokenStatus: 'revoked'
      });
    } finally {
      await rm(dataDirectory, { force: true, recursive: true });
    }
  });

  test('deletes an account and removes encrypted package files', async () => {
    const dataDirectory = await createTempDataDirectory();

    try {
      const store = await createLocalCloudSaveStore({
        dataDirectory,
        maxVersions: 5
      });
      const device = await store.registerDevice({
        deviceLabel: 'Miguel iPhone'
      });
      await store.save(
        device,
        createCloudSavePackage({
          saveId: 'cloud-save-admin-delete'
        })
      );
      await store.createDeviceLinkCode(device, {
        expiresAt: new Date(Date.now() + 10 * 60 * 1000)
      });
      store.close();

      const packagePath = join(
        dataDirectory,
        'packages',
        encodeURIComponent(device.accountId),
        'cloud-save-admin-delete.json'
      );
      await expect(access(packagePath)).resolves.toBeUndefined();

      const result = await deleteAdminAccount({
        dataDirectory,
        accountId: device.accountId
      });
      expect(result).toMatchObject({
        accountId: device.accountId,
        deletedAccount: true,
        deletedDevices: 1,
        deletedSaves: 1,
        deletedLinkCodes: 1,
        deletedPackageFiles: 1,
        missingPackageFiles: 0
      });

      await expect(access(packagePath)).rejects.toMatchObject({
        code: 'ENOENT'
      });
      await expect(listAdminAccounts({ dataDirectory })).resolves.toEqual([]);
      await expect(
        getAdminAccount({ dataDirectory, accountId: device.accountId })
      ).rejects.toThrow(`Account not found: ${device.accountId}`);
    } finally {
      await rm(dataDirectory, { force: true, recursive: true });
    }
  });
});

function createTempDataDirectory(): Promise<string> {
  return mkdtemp(join(tmpdir(), 'all-of-me-admin-'));
}
