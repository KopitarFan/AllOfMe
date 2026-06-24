import { type FastifyInstance } from 'fastify';
import { z } from 'zod';

import { type AuthStore } from './auth-store.js';
import { type AppConfig } from './config.js';

const registerDeviceBodySchema = z
  .object({
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
}

function parseRegisterDeviceBody(app: FastifyInstance, body: unknown) {
  const parsed = registerDeviceBodySchema.safeParse(body ?? {});
  if (!parsed.success) {
    throw app.httpErrors.badRequest('Device registration request is invalid.');
  }

  return parsed.data;
}
