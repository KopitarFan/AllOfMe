import {
  type CloudSaveMetadata,
  type CloudSavePackage
} from './cloud-save-package.js';
import { type AuthenticatedDevice } from './auth-store.js';

export interface CloudSaveStore {
  save(
    device: AuthenticatedDevice,
    cloudSavePackage: CloudSavePackage
  ): Promise<CloudSaveMetadata>;
  latest(device: AuthenticatedDevice): Promise<CloudSavePackage | null>;
  findBySaveId(
    device: AuthenticatedDevice,
    saveId: string
  ): Promise<CloudSavePackage | null>;
  listVersions(device: AuthenticatedDevice): Promise<CloudSaveMetadata[]>;
  close?(): Promise<void> | void;
}

export class MemoryCloudSaveStore implements CloudSaveStore {
  private readonly maxVersions: number;
  private readonly packages: Array<{
    accountId: string;
    deviceId: string;
    cloudSavePackage: CloudSavePackage;
  }> = [];

  constructor(options: { maxVersions?: number } = {}) {
    this.maxVersions = options.maxVersions ?? 5;
  }

  async save(
    device: AuthenticatedDevice,
    cloudSavePackage: CloudSavePackage
  ): Promise<CloudSaveMetadata> {
    const saveId = cloudSavePackage.metadata.saveId;
    const existingIndex = this.packages.findIndex(
      (candidate) =>
        candidate.accountId === device.accountId &&
        candidate.cloudSavePackage.metadata.saveId === saveId
    );

    if (existingIndex >= 0) {
      this.packages.splice(existingIndex, 1);
    }

    this.packages.unshift({
      accountId: device.accountId,
      deviceId: device.deviceId,
      cloudSavePackage
    });
    this.enforceRetention(device.accountId);

    return cloudSavePackage.metadata;
  }

  async latest(device: AuthenticatedDevice): Promise<CloudSavePackage | null> {
    return (
      this.packages.find((entry) => entry.accountId === device.accountId)
        ?.cloudSavePackage ?? null
    );
  }

  async findBySaveId(
    device: AuthenticatedDevice,
    saveId: string
  ): Promise<CloudSavePackage | null> {
    return (
      this.packages.find(
        (entry) =>
          entry.accountId === device.accountId &&
          entry.cloudSavePackage.metadata.saveId === saveId
      )?.cloudSavePackage ?? null
    );
  }

  async listVersions(device: AuthenticatedDevice): Promise<CloudSaveMetadata[]> {
    return this.packages
      .filter((entry) => entry.accountId === device.accountId)
      .map((entry) => entry.cloudSavePackage.metadata);
  }

  private enforceRetention(accountId: string): void {
    const accountEntries = this.packages.filter(
      (entry) => entry.accountId === accountId
    );
    const staleEntries = accountEntries.slice(this.maxVersions);

    for (const staleEntry of staleEntries) {
      const index = this.packages.indexOf(staleEntry);
      if (index >= 0) {
        this.packages.splice(index, 1);
      }
    }
  }
}
