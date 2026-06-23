import { type FastifyInstance } from 'fastify';

import { type AuthStore } from './auth-store.js';
import { requireAuthenticatedDevice } from './auth-request.js';
import {
  parseCloudSaveId,
  parseCloudSavePackage
} from './cloud-save-package.js';
import { type CloudSaveStore } from './cloud-save-store.js';
import { type AppConfig } from './config.js';

type CloudSaveRouteOptions = {
  authStore: AuthStore;
  config: AppConfig;
  store: CloudSaveStore;
};

export async function registerCloudSaveRoutes(
  app: FastifyInstance,
  options: CloudSaveRouteOptions
): Promise<void> {
  app.get('/v1/saves', async (request) => {
    const device = await requireAuthenticatedDevice(
      app,
      options.authStore,
      request
    );

    return options.store.listVersions(device);
  });

  app.get('/v1/saves/latest', async (request) => {
    const device = await requireAuthenticatedDevice(
      app,
      options.authStore,
      request
    );
    const latestSave = await options.store.latest(device);
    if (latestSave == null) {
      throw app.httpErrors.notFound('No cloud save found.');
    }

    return latestSave;
  });

  app.get<{ Params: { saveId: string } }>(
    '/v1/saves/:saveId',
    async (request) => {
      const device = await requireAuthenticatedDevice(
        app,
        options.authStore,
        request
      );
      const saveId = parseCloudSaveId(request.params.saveId);
      const cloudSavePackage = await options.store.findBySaveId(device, saveId);
      if (cloudSavePackage == null) {
        throw app.httpErrors.notFound('Cloud save not found.');
      }

      return cloudSavePackage;
    }
  );

  app.post('/v1/saves', async (request, reply) => {
    const device = await requireAuthenticatedDevice(
      app,
      options.authStore,
      request
    );
    const cloudSavePackage = parseRequestBody(request.body, options.config);
    const metadata = await options.store.save(device, cloudSavePackage);

    return reply.code(201).send(metadata);
  });
}

function parseRequestBody(body: unknown, config: AppConfig) {
  return parseCloudSavePackage(body, {
    maxPayloadBytes: config.cloudSaveMaxPayloadBytes
  });
}
