import { type FastifyInstance, type FastifyRequest } from 'fastify';

import { type AuthenticatedDevice, type AuthStore } from './auth-store.js';

export async function requireAuthenticatedDevice(
  app: FastifyInstance,
  authStore: AuthStore,
  request: FastifyRequest
): Promise<AuthenticatedDevice> {
  const authorization = request.headers.authorization;
  if (authorization == null) {
    throw app.httpErrors.unauthorized('Bearer token is required.');
  }

  const [scheme, token, ...extra] = authorization.split(/\s+/);
  if (
    scheme !== 'Bearer' ||
    token == null ||
    token.length === 0 ||
    extra.length > 0
  ) {
    throw app.httpErrors.unauthorized('Bearer token is invalid.');
  }

  const device = await authStore.authenticateToken(token);
  if (device == null) {
    throw app.httpErrors.unauthorized('Bearer token is invalid.');
  }

  return device;
}
