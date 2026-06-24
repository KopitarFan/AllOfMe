import { Buffer } from 'node:buffer';
import { mkdtemp, readdir, rm } from 'node:fs/promises';
import { join } from 'node:path';
import { tmpdir } from 'node:os';

import { describe, expect, test } from 'vitest';

import { createLocalCloudSaveStore } from '../src/local-cloud-save-store.js';
import { createCloudSavePackage } from './cloud-save-fixtures.js';

describe('LocalCloudSaveStore', () => {
  test('persists cloud saves across store instances', async () => {
    const dataDirectory = await createTempDataDirectory();
    const cloudSavePackage = createCloudSavePackage({
      saveId: 'cloud-save-1782264000000000',
      createdAt: '2026-06-23T18:40:00.000'
    });

    try {
      const firstStore = await createLocalCloudSaveStore({
        dataDirectory,
        maxVersions: 5
      });
      const device = await firstStore.registerDevice({
        deviceLabel: 'Miguel iPhone'
      });
      await firstStore.save(device, cloudSavePackage);
      firstStore.close();

      const secondStore = await createLocalCloudSaveStore({
        dataDirectory,
        maxVersions: 5
      });
      try {
        await expect(secondStore.authenticateToken(device.token)).resolves.toEqual({
          accountId: device.accountId,
          deviceId: device.deviceId,
          deviceLabel: 'Miguel iPhone'
        });
        await expect(secondStore.latest(device)).resolves.toEqual(cloudSavePackage);
        await expect(
          secondStore.findBySaveId(device, cloudSavePackage.metadata.saveId)
        ).resolves.toEqual(cloudSavePackage);
        await expect(secondStore.listVersions(device)).resolves.toEqual([
          cloudSavePackage.metadata
        ]);
      } finally {
        secondStore.close();
      }
    } finally {
      await rm(dataDirectory, { force: true, recursive: true });
    }
  });

  test('keeps only the configured number of versions', async () => {
    const dataDirectory = await createTempDataDirectory();
    const firstPackage = createCloudSavePackage({
      saveId: 'cloud-save-1782177600000000',
      createdAt: '2026-06-22T18:40:00.000',
      payloadBytes: Buffer.from('first-encrypted-backup')
    });
    const secondPackage = createCloudSavePackage({
      saveId: 'cloud-save-1782264000000000',
      createdAt: '2026-06-23T18:40:00.000',
      payloadBytes: Buffer.from('second-encrypted-backup')
    });
    const thirdPackage = createCloudSavePackage({
      saveId: 'cloud-save-1782350400000000',
      createdAt: '2026-06-24T18:40:00.000',
      payloadBytes: Buffer.from('third-encrypted-backup')
    });

    try {
      const store = await createLocalCloudSaveStore({
        dataDirectory,
        maxVersions: 2
      });
      try {
        const device = await store.registerDevice({});
        await store.save(device, firstPackage);
        await store.save(device, secondPackage);
        await store.save(device, thirdPackage);

        await expect(
          store.findBySaveId(device, firstPackage.metadata.saveId)
        ).resolves.toBeNull();
        await expect(store.listVersions(device)).resolves.toEqual([
          thirdPackage.metadata,
          secondPackage.metadata
        ]);
        const accountPackages = await readdir(
          join(dataDirectory, 'packages', encodeURIComponent(device.accountId))
        );
        expect(accountPackages).toHaveLength(2);
      } finally {
        store.close();
      }
    } finally {
      await rm(dataDirectory, { force: true, recursive: true });
    }
  });

  test('persists and redeems one-time device link codes', async () => {
    const dataDirectory = await createTempDataDirectory();

    try {
      const firstStore = await createLocalCloudSaveStore({
        dataDirectory,
        maxVersions: 5
      });
      const owner = await firstStore.registerDevice({
        deviceLabel: 'Miguel iPhone'
      });
      const linkCode = await firstStore.createDeviceLinkCode(owner, {
        expiresAt: new Date(Date.now() + 10 * 60 * 1000)
      });
      firstStore.close();

      const secondStore = await createLocalCloudSaveStore({
        dataDirectory,
        maxVersions: 5
      });
      try {
        const linkedDevice = await secondStore.redeemDeviceLinkCode({
          code: linkCode.code.toLowerCase(),
          deviceLabel: 'Miguel iPad'
        });
        expect(linkedDevice).toMatchObject({
          accountId: owner.accountId,
          deviceLabel: 'Miguel iPad',
          tokenType: 'Bearer'
        });
        expect(linkedDevice?.deviceId).not.toBe(owner.deviceId);
        await expect(
          secondStore.authenticateToken(linkedDevice!.token)
        ).resolves.toMatchObject({
          accountId: owner.accountId,
          deviceId: linkedDevice!.deviceId,
          deviceLabel: 'Miguel iPad'
        });
        await expect(
          secondStore.redeemDeviceLinkCode({ code: linkCode.code })
        ).resolves.toBeNull();
      } finally {
        secondStore.close();
      }
    } finally {
      await rm(dataDirectory, { force: true, recursive: true });
    }
  });

  test('rejects expired device link codes', async () => {
    const dataDirectory = await createTempDataDirectory();

    try {
      const store = await createLocalCloudSaveStore({
        dataDirectory,
        maxVersions: 5
      });
      try {
        const owner = await store.registerDevice({});
        const linkCode = await store.createDeviceLinkCode(owner, {
          expiresAt: new Date(Date.now() - 1000)
        });

        await expect(
          store.redeemDeviceLinkCode({ code: linkCode.code })
        ).resolves.toBeNull();
      } finally {
        store.close();
      }
    } finally {
      await rm(dataDirectory, { force: true, recursive: true });
    }
  });
});

function createTempDataDirectory(): Promise<string> {
  return mkdtemp(join(tmpdir(), 'all-of-me-server-'));
}
