import { Buffer } from 'node:buffer';

import { describe, expect, test } from 'vitest';

import { buildApp } from '../src/app.js';
import { MemoryCloudSaveStore } from '../src/cloud-save-store.js';
import { loadConfig } from '../src/config.js';
import { registerDevice } from './auth-helpers.js';
import { createCloudSavePackage } from './cloud-save-fixtures.js';

describe('GET /v1/saves', () => {
  test('lists saved metadata in newest-first order', async () => {
    const store = new MemoryCloudSaveStore();
    const app = await buildApp(loadConfig({ NODE_ENV: 'test' }), {
      cloudSaveStore: store
    });
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

    try {
      const device = await registerDevice(app);
      await store.save(device.registration, firstPackage);
      await store.save(device.registration, secondPackage);

      const response = await app.inject({
        method: 'GET',
        url: '/v1/saves',
        headers: { authorization: device.authorization }
      });

      expect(response.statusCode).toBe(200);
      expect(response.json()).toEqual([
        secondPackage.metadata,
        firstPackage.metadata
      ]);
    } finally {
      await app.close();
    }
  });

  test('returns an empty list when no saves exist', async () => {
    const app = await buildApp(loadConfig({ NODE_ENV: 'test' }));

    try {
      const device = await registerDevice(app);
      const response = await app.inject({
        method: 'GET',
        url: '/v1/saves',
        headers: { authorization: device.authorization }
      });

      expect(response.statusCode).toBe(200);
      expect(response.json()).toEqual([]);
    } finally {
      await app.close();
    }
  });
});

describe('GET /v1/saves/latest', () => {
  test('returns the newest cloud save package', async () => {
    const store = new MemoryCloudSaveStore();
    const app = await buildApp(loadConfig({ NODE_ENV: 'test' }), {
      cloudSaveStore: store
    });
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

    try {
      const device = await registerDevice(app);
      await store.save(device.registration, firstPackage);
      await store.save(device.registration, secondPackage);

      const response = await app.inject({
        method: 'GET',
        url: '/v1/saves/latest',
        headers: { authorization: device.authorization }
      });

      expect(response.statusCode).toBe(200);
      expect(response.json()).toEqual(secondPackage);
    } finally {
      await app.close();
    }
  });

  test('returns 404 when no cloud save exists', async () => {
    const app = await buildApp(loadConfig({ NODE_ENV: 'test' }));

    try {
      const device = await registerDevice(app);
      const response = await app.inject({
        method: 'GET',
        url: '/v1/saves/latest',
        headers: { authorization: device.authorization }
      });

      expect(response.statusCode).toBe(404);
      expect(response.json()).toMatchObject({
        message: 'No cloud save found.'
      });
    } finally {
      await app.close();
    }
  });
});

describe('GET /v1/saves/:saveId', () => {
  test('returns a specific cloud save package', async () => {
    const store = new MemoryCloudSaveStore();
    const app = await buildApp(loadConfig({ NODE_ENV: 'test' }), {
      cloudSaveStore: store
    });
    const cloudSavePackage = createCloudSavePackage({
      saveId: 'cloud-save-1782264000000000',
      createdAt: '2026-06-23T18:40:00.000'
    });

    try {
      const device = await registerDevice(app);
      await store.save(device.registration, cloudSavePackage);

      const response = await app.inject({
        method: 'GET',
        url: `/v1/saves/${cloudSavePackage.metadata.saveId}`,
        headers: { authorization: device.authorization }
      });

      expect(response.statusCode).toBe(200);
      expect(response.json()).toEqual(cloudSavePackage);
    } finally {
      await app.close();
    }
  });

  test('returns 404 when a save ID does not exist', async () => {
    const app = await buildApp(loadConfig({ NODE_ENV: 'test' }));

    try {
      const device = await registerDevice(app);
      const response = await app.inject({
        method: 'GET',
        url: '/v1/saves/cloud-save-missing',
        headers: { authorization: device.authorization }
      });

      expect(response.statusCode).toBe(404);
      expect(response.json()).toMatchObject({
        message: 'Cloud save not found.'
      });
    } finally {
      await app.close();
    }
  });

  test('returns 400 for invalid save IDs', async () => {
    const app = await buildApp(loadConfig({ NODE_ENV: 'test' }));

    try {
      const device = await registerDevice(app);
      const response = await app.inject({
        method: 'GET',
        url: '/v1/saves/bad save id',
        headers: { authorization: device.authorization }
      });

      expect(response.statusCode).toBe(400);
      expect(response.json()).toMatchObject({
        message: 'Cloud save field "saveId" is invalid.'
      });
    } finally {
      await app.close();
    }
  });

  test('does not return cloud saves owned by another account', async () => {
    const store = new MemoryCloudSaveStore();
    const app = await buildApp(loadConfig({ NODE_ENV: 'test' }), {
      cloudSaveStore: store
    });
    const cloudSavePackage = createCloudSavePackage();

    try {
      const owner = await registerDevice(app);
      const stranger = await registerDevice(app);
      await store.save(owner.registration, cloudSavePackage);

      const response = await app.inject({
        method: 'GET',
        url: `/v1/saves/${cloudSavePackage.metadata.saveId}`,
        headers: { authorization: stranger.authorization }
      });

      expect(response.statusCode).toBe(404);
    } finally {
      await app.close();
    }
  });
});

describe('POST /v1/saves', () => {
  test('stores an encrypted cloud save package', async () => {
    const store = new MemoryCloudSaveStore();
    const app = await buildApp(loadConfig({ NODE_ENV: 'test' }), {
      cloudSaveStore: store
    });
    const cloudSavePackage = createCloudSavePackage();

    try {
      const device = await registerDevice(app);
      const response = await app.inject({
        method: 'POST',
        url: '/v1/saves',
        headers: { authorization: device.authorization },
        payload: cloudSavePackage
      });

      expect(response.statusCode).toBe(201);
      expect(response.json()).toEqual(cloudSavePackage.metadata);
      await expect(store.latest(device.registration)).resolves.toMatchObject({
        metadata: { saveId: cloudSavePackage.metadata.saveId }
      });
    } finally {
      await app.close();
    }
  });

  test('rejects payloads with mismatched checksums', async () => {
    const app = await buildApp(loadConfig({ NODE_ENV: 'test' }));
    const cloudSavePackage = createCloudSavePackage();
    cloudSavePackage.metadata.payloadChecksum = 'fnv1a32:00000000';

    try {
      const device = await registerDevice(app);
      const response = await app.inject({
        method: 'POST',
        url: '/v1/saves',
        headers: { authorization: device.authorization },
        payload: cloudSavePackage
      });

      expect(response.statusCode).toBe(400);
      expect(response.json()).toMatchObject({
        message: 'Cloud save payload checksum does not match metadata.'
      });
    } finally {
      await app.close();
    }
  });

  test('rejects plaintext cloud save packages', async () => {
    const app = await buildApp(loadConfig({ NODE_ENV: 'test' }));
    const validPackage = createCloudSavePackage();
    const cloudSavePackage = {
      ...validPackage,
      payload: {
        ...validPackage.payload,
        encryption: {
          algorithm: 'none'
        }
      }
    };

    try {
      const device = await registerDevice(app);
      const response = await app.inject({
        method: 'POST',
        url: '/v1/saves',
        headers: { authorization: device.authorization },
        payload: cloudSavePackage
      });

      expect(response.statusCode).toBe(400);
      expect(response.json()).toMatchObject({
        message: 'Cloud save field "payload.encryption.algorithm" is invalid.'
      });
    } finally {
      await app.close();
    }
  });

  test('rejects cloud save payloads over the configured size cap', async () => {
    const app = await buildApp(
      loadConfig({
        NODE_ENV: 'test',
        CLOUD_SAVE_MAX_PAYLOAD_BYTES: '4'
      })
    );
    const cloudSavePackage = createCloudSavePackage({
      payloadBytes: Buffer.from('encrypted-payload')
    });

    try {
      const device = await registerDevice(app);
      const response = await app.inject({
        method: 'POST',
        url: '/v1/saves',
        headers: { authorization: device.authorization },
        payload: cloudSavePackage
      });

      expect(response.statusCode).toBe(413);
      expect(response.json()).toMatchObject({
        message: 'Cloud save payload is too large.'
      });
    } finally {
      await app.close();
    }
  });

  test('rejects requests without a bearer token', async () => {
    const app = await buildApp(loadConfig({ NODE_ENV: 'test' }));

    try {
      const response = await app.inject({
        method: 'POST',
        url: '/v1/saves',
        payload: createCloudSavePackage()
      });

      expect(response.statusCode).toBe(401);
      expect(response.json()).toMatchObject({
        message: 'Bearer token is required.'
      });
    } finally {
      await app.close();
    }
  });
});
