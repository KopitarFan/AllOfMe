import {
  MemoryCloudSaveStore,
  type CloudSaveStore
} from './cloud-save-store.js';
import { MemoryAuthStore, type AuthStore } from './auth-store.js';
import { type AppConfig } from './config.js';
import { createLocalCloudSaveStore } from './local-cloud-save-store.js';

export type ServerStores = {
  authStore: AuthStore;
  cloudSaveStore: CloudSaveStore;
};

export async function createDefaultStores(
  config: AppConfig
): Promise<ServerStores> {
  if (config.cloudSaveStore === 'memory') {
    return {
      authStore: new MemoryAuthStore(),
      cloudSaveStore: new MemoryCloudSaveStore({
        maxVersions: config.cloudSaveMaxVersions
      })
    };
  }

  const localStore = await createLocalCloudSaveStore({
    dataDirectory: config.cloudSaveDataDirectory,
    maxVersions: config.cloudSaveMaxVersions
  });

  return {
    authStore: localStore,
    cloudSaveStore: localStore
  };
}
