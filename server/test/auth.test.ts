import { describe, expect, test } from 'vitest';

import { buildApp } from '../src/app.js';
import { loadConfig } from '../src/config.js';
import { registerDevice } from './auth-helpers.js';

describe('POST /v1/devices/register', () => {
  test('registers a device and returns a bearer token once', async () => {
    const app = await buildApp(loadConfig({ NODE_ENV: 'test' }));

    try {
      const { registration } = await registerDevice(app, {
        deviceLabel: 'Miguel iPhone'
      });

      expect(registration.accountId).toMatch(/^account-/);
      expect(registration.deviceId).toMatch(/^device-/);
      expect(registration.deviceLabel).toBe('Miguel iPhone');
      expect(registration.token).toMatch(/^aom_/);
      expect(registration.tokenType).toBe('Bearer');
    } finally {
      await app.close();
    }
  });

  test('rejects invalid device labels', async () => {
    const app = await buildApp(loadConfig({ NODE_ENV: 'test' }));

    try {
      const response = await app.inject({
        method: 'POST',
        url: '/v1/devices/register',
        payload: { deviceLabel: '' }
      });

      expect(response.statusCode).toBe(400);
    } finally {
      await app.close();
    }
  });
});
