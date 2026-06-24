import { type FastifyInstance } from 'fastify';
import { z } from 'zod';

import { requireAuthenticatedDevice } from './auth-request.js';
import { type AuthStore, normalizeDeviceLinkCode } from './auth-store.js';
import { type AppConfig } from './config.js';

const registerDeviceBodySchema = z
  .object({
    deviceLabel: z.string().trim().min(1).max(100).optional()
  })
  .strict();

const createDeviceLinkCodeBodySchema = z.object({}).strict();

const redeemDeviceLinkCodeBodySchema = z
  .object({
    code: z.string().trim().min(1).max(80),
    deviceLabel: z.string().trim().min(1).max(100).optional()
  })
  .strict();

type AuthRouteOptions = {
  authStore: AuthStore;
  config: AppConfig;
};

export async function registerAuthRoutes(
  app: FastifyInstance,
  options: AuthRouteOptions
): Promise<void> {
  app.post(
    '/v1/devices/register',
    {
      config: {
        rateLimit: {
          groupId: 'device-registration',
          max: options.config.rateLimit.registrationMax,
          timeWindow: options.config.rateLimit.registrationTimeWindowMs
        }
      }
    },
    async (request, reply) => {
      const body = parseRegisterDeviceBody(app, request.body);
      const registration = await options.authStore.registerDevice(body);

      return reply.code(201).send(registration);
    }
  );

  app.post(
    '/v1/devices/link-codes',
    async (request, reply) => {
      parseCreateDeviceLinkCodeBody(app, request.body);
      const device = await requireAuthenticatedDevice(
        app,
        options.authStore,
        request
      );
      const expiresAt = new Date(
        Date.now() + options.config.deviceLinkCodeTtlMs
      );
      const linkCode = await options.authStore.createDeviceLinkCode(device, {
        expiresAt
      });

      return reply.code(201).send(linkCode);
    }
  );

  app.post(
    '/v1/devices/link',
    {
      config: {
        rateLimit: {
          groupId: 'device-link',
          max: options.config.rateLimit.registrationMax,
          timeWindow: options.config.rateLimit.registrationTimeWindowMs
        }
      }
    },
    async (request, reply) => {
      const body = parseRedeemDeviceLinkCodeBody(app, request.body);
      const registration = await options.authStore.redeemDeviceLinkCode(body);
      if (registration == null) {
        throw app.httpErrors.unauthorized(
          'Device link code is invalid or expired.'
        );
      }

      return reply.code(201).send(registration);
    }
  );
}

function parseRegisterDeviceBody(app: FastifyInstance, body: unknown) {
  const parsed = registerDeviceBodySchema.safeParse(body ?? {});
  if (!parsed.success) {
    throw app.httpErrors.badRequest('Device registration request is invalid.');
  }

  return parsed.data;
}

function parseCreateDeviceLinkCodeBody(app: FastifyInstance, body: unknown) {
  const parsed = createDeviceLinkCodeBodySchema.safeParse(body ?? {});
  if (!parsed.success) {
    throw app.httpErrors.badRequest(
      'Device link-code request is invalid.'
    );
  }
}

function parseRedeemDeviceLinkCodeBody(app: FastifyInstance, body: unknown) {
  const parsed = redeemDeviceLinkCodeBodySchema.safeParse(body ?? {});
  if (!parsed.success) {
    throw app.httpErrors.badRequest(
      'Device link-code redemption request is invalid.'
    );
  }

  try {
    normalizeDeviceLinkCode(parsed.data.code);
  } catch {
    throw app.httpErrors.badRequest('Device link code is invalid.');
  }

  return parsed.data;
}
