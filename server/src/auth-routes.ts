import { type FastifyInstance } from 'fastify';
import { z } from 'zod';

import { type AuthStore } from './auth-store.js';

const registerDeviceBodySchema = z
  .object({
    deviceLabel: z.string().trim().min(1).max(100).optional()
  })
  .strict();

type AuthRouteOptions = {
  authStore: AuthStore;
};

export async function registerAuthRoutes(
  app: FastifyInstance,
  options: AuthRouteOptions
): Promise<void> {
  app.post('/v1/devices/register', async (request, reply) => {
    const body = parseRegisterDeviceBody(app, request.body);
    const registration = await options.authStore.registerDevice(body);

    return reply.code(201).send(registration);
  });
}

function parseRegisterDeviceBody(app: FastifyInstance, body: unknown) {
  const parsed = registerDeviceBodySchema.safeParse(body ?? {});
  if (!parsed.success) {
    throw app.httpErrors.badRequest('Device registration request is invalid.');
  }

  return parsed.data;
}
