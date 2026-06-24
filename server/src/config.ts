import 'dotenv/config';

import { z } from 'zod';

const stringBooleanSchema = z
  .string()
  .trim()
  .toLowerCase()
  .pipe(z.enum(['true', 'false']))
  .transform((value) => value === 'true');

const configSchema = z.object({
  NODE_ENV: z
    .enum(['development', 'test', 'production'])
    .default('development'),
  HOST: z.string().min(1).default('127.0.0.1'),
  PORT: z.coerce.number().int().min(1).max(65535).default(3000),
  LOG_LEVEL: z
    .enum(['fatal', 'error', 'warn', 'info', 'debug', 'trace', 'silent'])
    .default('info'),
  CLOUD_SAVE_MAX_PAYLOAD_BYTES: z.coerce
    .number()
    .int()
    .positive()
    .default(10 * 1024 * 1024),
  CLOUD_SAVE_MAX_VERSIONS: z.coerce.number().int().positive().default(5),
  CLOUD_SAVE_STORE: z.enum(['local', 'memory']).optional(),
  CLOUD_SAVE_DATA_DIR: z.string().trim().min(1).default('.data/cloud-saves'),
  TRUST_PROXY: stringBooleanSchema.optional(),
  RATE_LIMIT_MAX: z.coerce.number().int().positive().default(300),
  RATE_LIMIT_TIME_WINDOW_MS: z.coerce
    .number()
    .int()
    .positive()
    .default(60 * 1000),
  RATE_LIMIT_REGISTRATION_MAX: z.coerce.number().int().positive().default(5),
  RATE_LIMIT_REGISTRATION_TIME_WINDOW_MS: z.coerce
    .number()
    .int()
    .positive()
    .default(15 * 60 * 1000),
  RATE_LIMIT_SAVE_MAX: z.coerce.number().int().positive().default(30),
  RATE_LIMIT_SAVE_TIME_WINDOW_MS: z.coerce
    .number()
    .int()
    .positive()
    .default(60 * 1000)
});

export type AppConfig = {
  nodeEnv: 'development' | 'test' | 'production';
  host: string;
  port: number;
  logLevel: 'fatal' | 'error' | 'warn' | 'info' | 'debug' | 'trace' | 'silent';
  trustProxy: boolean;
  cloudSaveMaxPayloadBytes: number;
  cloudSaveMaxVersions: number;
  cloudSaveStore: 'local' | 'memory';
  cloudSaveDataDirectory: string;
  rateLimit: {
    max: number;
    timeWindowMs: number;
    registrationMax: number;
    registrationTimeWindowMs: number;
    saveMax: number;
    saveTimeWindowMs: number;
  };
};

export function loadConfig(env: NodeJS.ProcessEnv = process.env): AppConfig {
  const parsed = configSchema.parse(env);

  return {
    nodeEnv: parsed.NODE_ENV,
    host: parsed.HOST,
    port: parsed.PORT,
    logLevel: parsed.LOG_LEVEL,
    trustProxy: parsed.TRUST_PROXY ?? parsed.NODE_ENV === 'production',
    cloudSaveMaxPayloadBytes: parsed.CLOUD_SAVE_MAX_PAYLOAD_BYTES,
    cloudSaveMaxVersions: parsed.CLOUD_SAVE_MAX_VERSIONS,
    cloudSaveStore:
      parsed.CLOUD_SAVE_STORE ??
      (parsed.NODE_ENV === 'test' ? 'memory' : 'local'),
    cloudSaveDataDirectory: parsed.CLOUD_SAVE_DATA_DIR,
    rateLimit: {
      max: parsed.RATE_LIMIT_MAX,
      timeWindowMs: parsed.RATE_LIMIT_TIME_WINDOW_MS,
      registrationMax: parsed.RATE_LIMIT_REGISTRATION_MAX,
      registrationTimeWindowMs: parsed.RATE_LIMIT_REGISTRATION_TIME_WINDOW_MS,
      saveMax: parsed.RATE_LIMIT_SAVE_MAX,
      saveTimeWindowMs: parsed.RATE_LIMIT_SAVE_TIME_WINDOW_MS
    }
  };
}
