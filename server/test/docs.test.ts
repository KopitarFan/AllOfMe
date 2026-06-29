import { describe, expect, test } from 'vitest';

import { buildApp } from '../src/app.js';
import { loadConfig } from '../src/config.js';

describe('Swagger docs', () => {
  test('serves the OpenAPI document', async () => {
    const app = await buildApp(loadConfig({ NODE_ENV: 'test' }));

    try {
      const response = await app.inject({
        method: 'GET',
        url: '/docs/json'
      });
      const document = response.json<{
        openapi: string;
        paths: Record<string, Record<string, unknown>>;
        components: {
          schemas: Record<string, unknown>;
          securitySchemes: Record<string, unknown>;
        };
      }>();

      expect(response.statusCode).toBe(200);
      expect(document.openapi).toBe('3.0.3');
      expect(document.paths['/healthz']).toHaveProperty('get');
      expect(document.paths['/v1/devices/register']).toHaveProperty('post');
      expect(document.paths['/v1/devices/link-codes']).toHaveProperty('post');
      expect(document.paths['/v1/devices/link']).toHaveProperty('post');
      expect(document.paths['/v1/saves']).toHaveProperty('get');
      expect(document.paths['/v1/saves']).toHaveProperty('post');
      expect(document.paths['/v1/saves/latest']).toHaveProperty('get');
      expect(document.paths['/v1/saves/{saveId}']).toHaveProperty('get');
      expect(document.components.schemas).toHaveProperty('CloudSavePackage');
      expect(document.components.securitySchemes).toHaveProperty('bearerAuth');
    } finally {
      await app.close();
    }
  });

  test('serves Swagger UI', async () => {
    const app = await buildApp(loadConfig({ NODE_ENV: 'test' }));

    try {
      const response = await app.inject({
        method: 'GET',
        url: '/docs/'
      });

      expect(response.statusCode).toBe(200);
      expect(response.headers['content-type']).toContain('text/html');
      expect(response.body).toContain('All Of Me API Docs');
      expect(response.body).toContain('swagger-ui-bundle.js');
    } finally {
      await app.close();
    }
  });
});
