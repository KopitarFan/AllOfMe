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

describe('POST /v1/devices/link-codes', () => {
  test('creates a one-time link code for an authenticated device', async () => {
    const app = await buildApp(loadConfig({ NODE_ENV: 'test' }));

    try {
      const owner = await registerDevice(app, {
        deviceLabel: 'Miguel iPhone'
      });
      const response = await app.inject({
        method: 'POST',
        url: '/v1/devices/link-codes',
        headers: { authorization: owner.authorization }
      });

      expect(response.statusCode).toBe(201);
      expect(response.json()).toMatchObject({
        code: expect.stringMatching(/^AOM-[0-9A-F]{5}-[0-9A-F]{5}$/)
      });
      expect(Date.parse(response.json().expiresAt)).toBeGreaterThan(Date.now());
    } finally {
      await app.close();
    }
  });

  test('requires bearer auth before creating a link code', async () => {
    const app = await buildApp(loadConfig({ NODE_ENV: 'test' }));

    try {
      const response = await app.inject({
        method: 'POST',
        url: '/v1/devices/link-codes'
      });

      expect(response.statusCode).toBe(401);
    } finally {
      await app.close();
    }
  });
});

describe('POST /v1/devices/link', () => {
  test('redeems a link code into a new token for the same account', async () => {
    const app = await buildApp(loadConfig({ NODE_ENV: 'test' }));

    try {
      const owner = await registerDevice(app, {
        deviceLabel: 'Miguel iPhone'
      });
      const createResponse = await app.inject({
        method: 'POST',
        url: '/v1/devices/link-codes',
        headers: { authorization: owner.authorization }
      });
      const linkCode = createResponse.json<{ code: string }>();

      const redeemResponse = await app.inject({
        method: 'POST',
        url: '/v1/devices/link',
        payload: {
          code: linkCode.code.toLowerCase(),
          deviceLabel: 'Miguel iPad'
        }
      });

      expect(redeemResponse.statusCode).toBe(201);
      expect(redeemResponse.json()).toMatchObject({
        accountId: owner.registration.accountId,
        deviceLabel: 'Miguel iPad',
        tokenType: 'Bearer'
      });
      expect(redeemResponse.json().deviceId).not.toBe(
        owner.registration.deviceId
      );

      const linkedToken = redeemResponse.json().token;
      const savesResponse = await app.inject({
        method: 'GET',
        url: '/v1/saves',
        headers: { authorization: `Bearer ${linkedToken}` }
      });
      expect(savesResponse.statusCode).toBe(200);
    } finally {
      await app.close();
    }
  });

  test('rejects reused and invalid link codes', async () => {
    const app = await buildApp(loadConfig({ NODE_ENV: 'test' }));

    try {
      const owner = await registerDevice(app);
      const createResponse = await app.inject({
        method: 'POST',
        url: '/v1/devices/link-codes',
        headers: { authorization: owner.authorization }
      });
      const linkCode = createResponse.json<{ code: string }>();
      const firstRedeem = await app.inject({
        method: 'POST',
        url: '/v1/devices/link',
        payload: { code: linkCode.code }
      });
      const secondRedeem = await app.inject({
        method: 'POST',
        url: '/v1/devices/link',
        payload: { code: linkCode.code }
      });
      const invalidRedeem = await app.inject({
        method: 'POST',
        url: '/v1/devices/link',
        payload: { code: 'not-real' }
      });

      expect(firstRedeem.statusCode).toBe(201);
      expect(secondRedeem.statusCode).toBe(401);
      expect(secondRedeem.json()).toMatchObject({
        message: 'Device link code is invalid or expired.'
      });
      expect(invalidRedeem.statusCode).toBe(400);
    } finally {
      await app.close();
    }
  });
});
