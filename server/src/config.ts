import 'dotenv/config';

import { z } from 'zod';

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
  CLOUD_SAVE_DATA_DIR: z.string().trim().min(1).default('.data/cloud-saves')
});

export type AppConfig = {
  nodeEnv: 'development' | 'test' | 'production';
  host: string;
  port: number;
  logLevel: 'fatal' | 'error' | 'warn' | 'info' | 'debug' | 'trace' | 'silent';
  cloudSaveMaxPayloadBytes: number;
  cloudSaveMaxVersions: number;
  cloudSaveStore: 'local' | 'memory';
  cloudSaveDataDirectory: string;
};

export function loadConfig(env: NodeJS.ProcessEnv = process.env): AppConfig {
  const parsed = configSchema.parse(env);

  return {
    nodeEnv: parsed.NODE_ENV,
    host: parsed.HOST,
    port: parsed.PORT,
    logLevel: parsed.LOG_LEVEL,
    cloudSaveMaxPayloadBytes: parsed.CLOUD_SAVE_MAX_PAYLOAD_BYTES,
    cloudSaveMaxVersions: parsed.CLOUD_SAVE_MAX_VERSIONS,
    cloudSaveStore:
      parsed.CLOUD_SAVE_STORE ??
      (parsed.NODE_ENV === 'test' ? 'memory' : 'local'),
    cloudSaveDataDirectory: parsed.CLOUD_SAVE_DATA_DIR
  };
}
