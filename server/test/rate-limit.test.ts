import { describe, expect, test } from 'vitest';

import { buildApp } from '../src/app.js';
import { loadConfig } from '../src/config.js';
import { registerDevice } from './auth-helpers.js';
import { createCloudSavePackage } from './cloud-save-fixtures.js';

describe('rate limiting', () => {
  test('does not rate limit health checks', async () => {
    const app = await buildApp(
      loadConfig({
        NODE_ENV: 'test',
        RATE_LIMIT_MAX: '1',
        RATE_LIMIT_TIME_WINDOW_MS: '60000'
      })
    );

    try {
      const first = await app.inject({ method: 'GET', url: '/healthz' });
      const second = await app.inject({ method: 'GET', url: '/healthz' });

      expect(first.statusCode).toBe(200);
      expect(second.statusCode).toBe(200);
    } finally {
      await app.close();
    }
  });

  test('applies a global limit to API routes', async () => {
    const app = await buildApp(
      loadConfig({
        NODE_ENV: 'test',
        RATE_LIMIT_MAX: '1',
        RATE_LIMIT_TIME_WINDOW_MS: '60000'
      })
    );

    try {
      const first = await app.inject({ method: 'GET', url: '/v1/saves' });
      const second = await app.inject({ method: 'GET', url: '/v1/saves' });

      expect(first.statusCode).toBe(401);
      expect(second.statusCode).toBe(429);
      expect(second.json()).toMatchObject({
        error: 'Too Many Requests'
      });
      expect(second.headers['retry-after']).toBeDefined();
    } finally {
      await app.close();
    }
  });

  test('applies a tighter limit to device registration', async () => {
    const app = await buildApp(
      loadConfig({
        NODE_ENV: 'test',
        RATE_LIMIT_MAX: '100',
        RATE_LIMIT_REGISTRATION_MAX: '1',
        RATE_LIMIT_REGISTRATION_TIME_WINDOW_MS: '60000'
      })
    );

    try {
      const first = await app.inject({
        method: 'POST',
        url: '/v1/devices/register'
      });
      const second = await app.inject({
        method: 'POST',
        url: '/v1/devices/register'
      });

      expect(first.statusCode).toBe(201);
      expect(second.statusCode).toBe(429);
    } finally {
      await app.close();
    }
  });

  test('limits save uploads by bearer token', async () => {
    const app = await buildApp(
      loadConfig({
        NODE_ENV: 'test',
        RATE_LIMIT_MAX: '100',
        RATE_LIMIT_REGISTRATION_MAX: '10',
        RATE_LIMIT_SAVE_MAX: '1',
        RATE_LIMIT_SAVE_TIME_WINDOW_MS: '60000'
      })
    );

    try {
      const firstDevice = await registerDevice(app, {
        deviceLabel: 'First test device'
      });
      const secondDevice = await registerDevice(app, {
        deviceLabel: 'Second test device'
      });

      const firstSave = await app.inject({
        method: 'POST',
        url: '/v1/saves',
        headers: { authorization: firstDevice.authorization },
        payload: createCloudSavePackage({
          saveId: 'cloud-save-rate-limit-first'
        })
      });
      const blockedSave = await app.inject({
        method: 'POST',
        url: '/v1/saves',
        headers: { authorization: firstDevice.authorization },
        payload: createCloudSavePackage({
          saveId: 'cloud-save-rate-limit-blocked'
        })
      });
      const secondDeviceSave = await app.inject({
        method: 'POST',
        url: '/v1/saves',
        headers: { authorization: secondDevice.authorization },
        payload: createCloudSavePackage({
          saveId: 'cloud-save-rate-limit-second-device'
        })
      });

      expect(firstSave.statusCode).toBe(201);
      expect(blockedSave.statusCode).toBe(429);
      expect(secondDeviceSave.statusCode).toBe(201);
    } finally {
      await app.close();
    }
  });
});
