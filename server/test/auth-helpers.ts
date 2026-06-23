import { type FastifyInstance } from 'fastify';

import { type DeviceRegistration } from '../src/auth-store.js';

export type RegisteredDevice = {
  registration: DeviceRegistration;
  authorization: string;
};

export async function registerDevice(
  app: FastifyInstance,
  options: { deviceLabel?: string } = {}
): Promise<RegisteredDevice> {
  const response = await app.inject({
    method: 'POST',
    url: '/v1/devices/register',
    payload: options
  });

  if (response.statusCode !== 201) {
    throw new Error(`Device registration failed: ${response.body}`);
  }

  const registration = response.json<DeviceRegistration>();
  return {
    registration,
    authorization: `Bearer ${registration.token}`
  };
}
