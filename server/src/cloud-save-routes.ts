import { type FastifyInstance, type FastifyRequest } from 'fastify';

import { type AuthStore, hashAuthToken } from './auth-store.js';
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
  // Register literal read routes before /:saveId so "latest" is not parsed as
  // a save ID.
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

  app.post(
    '/v1/saves',
    {
      config: {
        rateLimit: {
          groupId: 'cloud-save-upload',
          keyGenerator: cloudSaveUploadRateLimitKey,
          max: options.config.rateLimit.saveMax,
          timeWindow: options.config.rateLimit.saveTimeWindowMs
        }
      }
    },
    async (request, reply) => {
      const device = await requireAuthenticatedDevice(
        app,
        options.authStore,
        request
      );
      const cloudSavePackage = parseRequestBody(request.body, options.config);
      const metadata = await options.store.save(device, cloudSavePackage);

      return reply.code(201).send(metadata);
    }
  );
}

function parseRequestBody(body: unknown, config: AppConfig) {
  return parseCloudSavePackage(body, {
    maxPayloadBytes: config.cloudSaveMaxPayloadBytes
  });
}

function cloudSaveUploadRateLimitKey(request: FastifyRequest): string {
  const authorization = request.headers.authorization;
  const token = parseBearerToken(authorization);

  // Valid-looking bearer tokens get their own upload bucket, which avoids one
  // active device throttling another behind the same home or mobile network.
  return token == null ? `ip:${request.ip}` : `device:${hashAuthToken(token)}`;
}

function parseBearerToken(authorization: string | undefined): string | null {
  if (authorization == null) {
    return null;
  }

  const [scheme, token, ...extra] = authorization.split(/\s+/);
  if (
    scheme !== 'Bearer' ||
    token == null ||
    token.length === 0 ||
    extra.length > 0
  ) {
    return null;
  }

  return token;
}
