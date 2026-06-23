import { describe, expect, test } from 'vitest';

import { buildApp } from '../src/app.js';
import { loadConfig } from '../src/config.js';

describe('health endpoint', () => {
  test('returns ok', async () => {
    const app = await buildApp(loadConfig({ NODE_ENV: 'test' }));

    const response = await app.inject({
      method: 'GET',
      url: '/healthz'
    });

    expect(response.statusCode).toBe(200);
    expect(response.json()).toEqual({ ok: true });

    await app.close();
  });
});
