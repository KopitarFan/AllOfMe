import fastifyRateLimit from '@fastify/rate-limit';
import sensible from '@fastify/sensible';
import Fastify, { type FastifyInstance } from 'fastify';

import { type AuthStore } from './auth-store.js';
import { registerAuthRoutes } from './auth-routes.js';
import { registerCloudSaveRoutes } from './cloud-save-routes.js';
import { type CloudSaveStore } from './cloud-save-store.js';
import { createDefaultStores } from './cloud-save-store-factory.js';
import { type AppConfig } from './config.js';

export type AppDependencies = {
  authStore?: AuthStore;
  cloudSaveStore?: CloudSaveStore;
};

export async function buildApp(
  config: AppConfig,
  dependencies: AppDependencies = {}
): Promise<FastifyInstance> {
  const app = Fastify({
    bodyLimit: config.cloudSaveMaxPayloadBytes * 2 + 16 * 1024,
    trustProxy: config.trustProxy,
    logger:
      config.nodeEnv === 'test'
        ? false
        : {
            level: config.logLevel
          }
  });

  const defaultStores =
    dependencies.authStore != null && dependencies.cloudSaveStore != null
      ? null
      : await createDefaultStores(config);
  const authStore = dependencies.authStore ?? defaultStores!.authStore;
  const cloudSaveStore =
    dependencies.cloudSaveStore ?? defaultStores!.cloudSaveStore;

  app.addHook('onClose', async () => {
    const stores = new Set([authStore, cloudSaveStore]);
    for (const store of stores) {
      await store.close?.();
    }
  });

  await app.register(sensible);
  await app.register(fastifyRateLimit, {
    global: true,
    max: config.rateLimit.max,
    timeWindow: config.rateLimit.timeWindowMs,
    keyGenerator: (request) => `ip:${request.ip}`
  });

  await registerAuthRoutes(app, { authStore, config });
  await registerCloudSaveRoutes(app, {
    authStore,
    config,
    store: cloudSaveStore
  });

  app.get(
    '/healthz',
    {
      config: {
        rateLimit: false
      }
    },
    async () => {
      return { ok: true };
    }
  );

  return app;
}
