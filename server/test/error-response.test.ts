import { describe, expect, test } from 'vitest';

import { buildApp } from '../src/app.js';
import { loadConfig } from '../src/config.js';
import { createCloudSavePackage } from './cloud-save-fixtures.js';

describe('error responses', () => {
  test('include support IDs for client errors', async () => {
    const app = await buildApp(loadConfig({ NODE_ENV: 'test' }));
    const cloudSavePackage = createCloudSavePackage();
    cloudSavePackage.metadata.payloadChecksum = 'fnv1a32:00000000';

    try {
      const response = await app.inject({
        method: 'POST',
        url: '/v1/saves',
        headers: {
          authorization: 'Bearer invalid-token',
          'x-request-id': 'wife-phone-save-test'
        },
        payload: cloudSavePackage
      });

      expect(response.statusCode).toBe(401);
      expect(response.headers['x-request-id']).toBe('wife-phone-save-test');
      expect(response.headers['x-error-id']).toMatch(/^err_/);
      expect(response.json()).toMatchObject({
        statusCode: 401,
        error: 'Unauthorized',
        message: 'Bearer token is invalid.',
        requestId: 'wife-phone-save-test',
        errorId: response.headers['x-error-id']
      });
    } finally {
      await app.close();
    }
  });
});
