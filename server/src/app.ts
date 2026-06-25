import { randomUUID } from 'node:crypto';
import { STATUS_CODES } from 'node:http';

import fastifyRateLimit from '@fastify/rate-limit';
import sensible from '@fastify/sensible';
import Fastify, {
  type FastifyInstance,
  type FastifyReply,
  type FastifyRequest
} from 'fastify';

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

type HttpErrorLike = Error & {
  headers?: Record<string, number | string | string[] | undefined>;
  status?: number;
  statusCode?: number;
};

export async function buildApp(
  config: AppConfig,
  dependencies: AppDependencies = {}
): Promise<FastifyInstance> {
  const app = Fastify({
    bodyLimit: config.cloudSaveMaxPayloadBytes * 2 + 16 * 1024,
    genReqId: (request) => requestIdFromHeader(request.headers['x-request-id']),
    trustProxy: config.trustProxy,
    logger:
      config.nodeEnv === 'test'
        ? false
        : {
            level: config.logLevel
    }
  });

  app.addHook('onRequest', async (request, reply) => {
    reply.header('x-request-id', request.id);
  });

  app.setErrorHandler((error, request, reply) => {
    handleError(error, request, reply);
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

function handleError(
  error: unknown,
  request: FastifyRequest,
  reply: FastifyReply
): void {
  const normalizedError = normalizeError(error);
  const httpError = normalizedError as HttpErrorLike;
  const statusCode = statusCodeForError(httpError);
  const errorId = createSupportId('err');
  const message =
    statusCode >= 500
      ? 'Internal server error.'
      : normalizedError.message || STATUS_CODES[statusCode] || 'Request failed.';

  for (const [header, value] of Object.entries(httpError.headers ?? {})) {
    if (value != null) {
      reply.header(header, value);
    }
  }

  reply.header('x-request-id', request.id);
  reply.header('x-error-id', errorId);

  const logPayload = {
    errorId,
    requestId: request.id,
    statusCode,
    method: request.method,
    url: request.url,
    err: normalizedError
  };
  if (statusCode >= 500) {
    request.log.error(logPayload, 'Request failed with server error.');
  } else {
    request.log.warn(logPayload, 'Request failed with client error.');
  }

  reply.code(statusCode).send({
    statusCode,
    error: STATUS_CODES[statusCode] ?? 'Error',
    message,
    errorId,
    requestId: request.id
  });
}

function normalizeError(error: unknown): Error {
  if (error instanceof Error) {
    return error;
  }
  return new Error(String(error));
}

function statusCodeForError(error: HttpErrorLike): number {
  const statusCode = error.statusCode ?? error.status ?? 500;
  if (statusCode < 400 || statusCode > 599) {
    return 500;
  }
  return statusCode;
}

function requestIdFromHeader(value: string | string[] | undefined): string {
  const candidate = Array.isArray(value) ? value[0] : value;
  if (candidate != null && /^[A-Za-z0-9._:-]{1,128}$/.test(candidate)) {
    return candidate;
  }
  return createSupportId('req');
}

function createSupportId(prefix: string): string {
  return `${prefix}_${randomUUID()}`;
}
