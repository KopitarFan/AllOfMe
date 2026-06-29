import { mkdir, readFile, rename, unlink, writeFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';

import Database from 'better-sqlite3';

import {
  type AuthenticatedDevice,
  type AuthStore,
  type DeviceLinkCode,
  type DeviceRegistration,
  createAuthToken,
  createDeviceLinkCode,
  createServerId,
  hashAuthToken,
  normalizeDeviceLinkCode
} from './auth-store.js';
import {
  type CloudSaveMetadata,
  type CloudSavePackage,
  parseCloudSavePackage
} from './cloud-save-package.js';
import { type CloudSaveStore } from './cloud-save-store.js';

type LocalCloudSaveStoreOptions = {
  dataDirectory: string;
  maxVersions: number;
};

type CloudSaveRow = {
  account_id: string;
  save_id: string;
  device_id: string;
  created_at: string;
  app_name: string;
  app_version: string | null;
  snapshot_schema_version: number;
  device_label: string | null;
  payload_byte_count: number;
  payload_checksum: string;
  package_path: string;
  stored_at: string;
};

type StoredPackageRow = {
  account_id: string;
  save_id: string;
  package_path: string;
};

type DeviceRow = {
  account_id: string;
  device_id: string;
  device_label: string | null;
};

type DeviceLinkCodeRow = {
  account_id: string;
  created_by_device_id: string;
  expires_at: string;
  redeemed_at: string | null;
  redeemed_by_device_id: string | null;
};

export async function createLocalCloudSaveStore(
  options: LocalCloudSaveStoreOptions
): Promise<LocalCloudSaveStore> {
  await mkdir(options.dataDirectory, { recursive: true });
  await mkdir(join(options.dataDirectory, 'packages'), { recursive: true });

  const database = new Database(
    join(options.dataDirectory, 'cloud-saves.sqlite')
  );
  const store = new LocalCloudSaveStore(database, options);
  store.migrate();
  return store;
}

export class LocalCloudSaveStore implements AuthStore, CloudSaveStore {
  private readonly packagesDirectory: string;
  private readonly maxVersions: number;

  constructor(
    private readonly database: Database.Database,
    options: LocalCloudSaveStoreOptions
  ) {
    this.maxVersions = options.maxVersions;
    this.packagesDirectory = join(options.dataDirectory, 'packages');
  }

  migrate(): void {
    this.database.pragma('journal_mode = WAL');
    this.database.pragma('foreign_keys = ON');
    this.dropLegacyCloudSavesTable();
    this.database.exec(`
      CREATE TABLE IF NOT EXISTS accounts (
        account_id TEXT PRIMARY KEY,
        created_at TEXT NOT NULL
      );

      CREATE TABLE IF NOT EXISTS devices (
        device_id TEXT PRIMARY KEY,
        account_id TEXT NOT NULL,
        device_label TEXT,
        token_hash TEXT NOT NULL UNIQUE,
        created_at TEXT NOT NULL,
        last_used_at TEXT,
        FOREIGN KEY (account_id)
          REFERENCES accounts(account_id)
          ON DELETE CASCADE
      );

      CREATE INDEX IF NOT EXISTS idx_devices_account_id
        ON devices (account_id);

      CREATE TABLE IF NOT EXISTS device_link_codes (
        code_hash TEXT PRIMARY KEY,
        account_id TEXT NOT NULL,
        created_by_device_id TEXT NOT NULL,
        expires_at TEXT NOT NULL,
        created_at TEXT NOT NULL,
        redeemed_at TEXT,
        redeemed_by_device_id TEXT,
        FOREIGN KEY (account_id)
          REFERENCES accounts(account_id)
          ON DELETE CASCADE,
        FOREIGN KEY (created_by_device_id)
          REFERENCES devices(device_id)
          ON DELETE CASCADE,
        FOREIGN KEY (redeemed_by_device_id)
          REFERENCES devices(device_id)
          ON DELETE SET NULL
      );

      CREATE INDEX IF NOT EXISTS idx_device_link_codes_account_id
        ON device_link_codes (account_id, expires_at);

      CREATE TABLE IF NOT EXISTS cloud_saves (
        account_id TEXT NOT NULL,
        save_id TEXT NOT NULL,
        device_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        app_name TEXT NOT NULL,
        app_version TEXT,
        snapshot_schema_version INTEGER NOT NULL,
        device_label TEXT,
        payload_byte_count INTEGER NOT NULL,
        payload_checksum TEXT NOT NULL,
        package_path TEXT NOT NULL,
        stored_at TEXT NOT NULL,
        PRIMARY KEY (account_id, save_id),
        FOREIGN KEY (account_id)
          REFERENCES accounts(account_id)
          ON DELETE CASCADE,
        FOREIGN KEY (device_id)
          REFERENCES devices(device_id)
          ON DELETE RESTRICT
      );

      CREATE INDEX IF NOT EXISTS idx_cloud_saves_created_at
        ON cloud_saves (
          account_id,
          created_at DESC,
          stored_at DESC,
          save_id DESC
        );
    `);
  }

  async registerDevice(options: {
    deviceLabel?: string;
  }): Promise<DeviceRegistration> {
    const accountId = createServerId('account');
    const now = new Date().toISOString();
    const device = createLocalDeviceRegistration({
      accountId,
      deviceLabel: options.deviceLabel
    });

    const createDevice = this.database.transaction(() => {
      this.database
        .prepare('INSERT INTO accounts (account_id, created_at) VALUES (?, ?)')
        .run(accountId, now);
      this.database
        .prepare(
          `
            INSERT INTO devices (
              device_id,
              account_id,
              device_label,
              token_hash,
              created_at
            ) VALUES (?, ?, ?, ?, ?)
          `
        )
        .run(
          device.deviceId,
          accountId,
          options.deviceLabel ?? null,
          hashAuthToken(device.token),
          now
        );
    });

    createDevice();

    return device;
  }

  async createDeviceLinkCode(
    device: AuthenticatedDevice,
    options: { expiresAt: Date }
  ): Promise<DeviceLinkCode> {
    const linkCode = createDeviceLinkCode();
    this.database
      .prepare(
        `
          INSERT INTO device_link_codes (
            code_hash,
            account_id,
            created_by_device_id,
            expires_at,
            created_at
          ) VALUES (?, ?, ?, ?, ?)
        `
      )
      .run(
        hashAuthToken(normalizeDeviceLinkCode(linkCode)),
        device.accountId,
        device.deviceId,
        options.expiresAt.toISOString(),
        new Date().toISOString()
      );

    return {
      code: linkCode,
      expiresAt: options.expiresAt.toISOString()
    };
  }

  async redeemDeviceLinkCode(options: {
    code: string;
    deviceLabel?: string;
  }): Promise<DeviceRegistration | null> {
    const codeHash = hashAuthToken(normalizeDeviceLinkCode(options.code));
    const row = this.database
      .prepare(
        `
          SELECT
            account_id,
            created_by_device_id,
            expires_at,
            redeemed_at,
            redeemed_by_device_id
          FROM device_link_codes
          WHERE code_hash = ?
        `
      )
      .get(codeHash) as DeviceLinkCodeRow | undefined;

    if (
      row == null ||
      row.redeemed_at != null ||
      Date.parse(row.expires_at) <= Date.now()
    ) {
      return null;
    }

    const now = new Date().toISOString();
    const device = createLocalDeviceRegistration({
      accountId: row.account_id,
      deviceLabel: options.deviceLabel
    });
    const redeemCode = this.database.transaction(() => {
      this.database
        .prepare(
          `
            INSERT INTO devices (
              device_id,
              account_id,
              device_label,
              token_hash,
              created_at
            ) VALUES (?, ?, ?, ?, ?)
          `
        )
        .run(
          device.deviceId,
          device.accountId,
          options.deviceLabel ?? null,
          hashAuthToken(device.token),
          now
        );
      this.database
        .prepare(
          `
            UPDATE device_link_codes
            SET redeemed_at = ?, redeemed_by_device_id = ?
            WHERE code_hash = ?
          `
        )
        .run(now, device.deviceId, codeHash);
    });

    redeemCode();
    return device;
  }

  async authenticateToken(token: string): Promise<AuthenticatedDevice | null> {
    const row = this.database
      .prepare(
        `
          SELECT account_id, device_id, device_label
          FROM devices
          WHERE token_hash = ?
        `
      )
      .get(hashAuthToken(token)) as DeviceRow | undefined;

    if (row == null) {
      return null;
    }

    this.database
      .prepare('UPDATE devices SET last_used_at = ? WHERE device_id = ?')
      .run(new Date().toISOString(), row.device_id);

    return {
      accountId: row.account_id,
      deviceId: row.device_id,
      ...(row.device_label == null ? {} : { deviceLabel: row.device_label })
    };
  }

  async save(
    device: AuthenticatedDevice,
    cloudSavePackage: CloudSavePackage
  ): Promise<CloudSaveMetadata> {
    const packagePath = packageFileName(
      device.accountId,
      cloudSavePackage.metadata.saveId
    );
    await this.writePackageFile(packagePath, cloudSavePackage);

    this.database
      .prepare(
        `
          INSERT INTO cloud_saves (
            account_id,
            save_id,
            device_id,
            created_at,
            app_name,
            app_version,
            snapshot_schema_version,
            device_label,
            payload_byte_count,
            payload_checksum,
            package_path,
            stored_at
          ) VALUES (
            @accountId,
            @saveId,
            @deviceId,
            @createdAt,
            @appName,
            @appVersion,
            @snapshotSchemaVersion,
            @deviceLabel,
            @payloadByteCount,
            @payloadChecksum,
            @packagePath,
            @storedAt
          )
          ON CONFLICT(account_id, save_id) DO UPDATE SET
            device_id = excluded.device_id,
            created_at = excluded.created_at,
            app_name = excluded.app_name,
            app_version = excluded.app_version,
            snapshot_schema_version = excluded.snapshot_schema_version,
            device_label = excluded.device_label,
            payload_byte_count = excluded.payload_byte_count,
            payload_checksum = excluded.payload_checksum,
            package_path = excluded.package_path,
            stored_at = excluded.stored_at
        `
      )
      .run({
        accountId: device.accountId,
        saveId: cloudSavePackage.metadata.saveId,
        deviceId: device.deviceId,
        createdAt: cloudSavePackage.metadata.createdAt,
        appName: cloudSavePackage.metadata.appName,
        appVersion: cloudSavePackage.metadata.appVersion ?? null,
        snapshotSchemaVersion: cloudSavePackage.metadata.snapshotSchemaVersion,
        deviceLabel: cloudSavePackage.metadata.deviceLabel ?? null,
        payloadByteCount: cloudSavePackage.metadata.payloadByteCount,
        payloadChecksum: cloudSavePackage.metadata.payloadChecksum,
        packagePath,
        storedAt: new Date().toISOString()
      });

    await this.enforceRetention(device.accountId);
    return cloudSavePackage.metadata;
  }

  async latest(device: AuthenticatedDevice): Promise<CloudSavePackage | null> {
    const row = this.database
      .prepare(
        `
          SELECT *
          FROM cloud_saves
          WHERE account_id = ?
          ORDER BY created_at DESC, stored_at DESC, save_id DESC
          LIMIT 1
        `
      )
      .get(device.accountId) as CloudSaveRow | undefined;

    return row == null ? null : this.readPackageFile(row.package_path);
  }

  async findBySaveId(
    device: AuthenticatedDevice,
    saveId: string
  ): Promise<CloudSavePackage | null> {
    const row = this.database
      .prepare(
        'SELECT * FROM cloud_saves WHERE account_id = ? AND save_id = ?'
      )
      .get(device.accountId, saveId) as CloudSaveRow | undefined;

    return row == null ? null : this.readPackageFile(row.package_path);
  }

  async listVersions(device: AuthenticatedDevice): Promise<CloudSaveMetadata[]> {
    const rows = this.database
      .prepare(
        `
          SELECT *
          FROM cloud_saves
          WHERE account_id = ?
          ORDER BY created_at DESC, stored_at DESC, save_id DESC
        `
      )
      .all(device.accountId) as CloudSaveRow[];

    return rows.map(metadataFromRow);
  }

  close(): void {
    this.database.close();
  }

  private async writePackageFile(
    packagePath: string,
    cloudSavePackage: CloudSavePackage
  ): Promise<void> {
    const finalPath = this.absolutePackagePath(packagePath);
    const tempPath = `${finalPath}.${process.pid}.${Date.now()}.tmp`;

    // Write then rename so readers never observe a partial JSON package file.
    await mkdir(dirname(finalPath), { recursive: true });
    await writeFile(tempPath, JSON.stringify(cloudSavePackage, null, 2));
    await rename(tempPath, finalPath);
  }

  private async readPackageFile(packagePath: string): Promise<CloudSavePackage> {
    const contents = await readFile(
      this.absolutePackagePath(packagePath),
      'utf8'
    );
    // Re-parse stored packages to catch disk corruption or manual edits before
    // sending a package back to a client.
    return parseCloudSavePackage(JSON.parse(contents), {
      maxPayloadBytes: Number.MAX_SAFE_INTEGER
    });
  }

  private async enforceRetention(accountId: string): Promise<void> {
    const staleRows = this.database
      .prepare(
        `
          SELECT account_id, save_id, package_path
          FROM cloud_saves
          WHERE account_id = ?
          ORDER BY created_at DESC, stored_at DESC, save_id DESC
          LIMIT -1 OFFSET ?
        `
      )
      .all(accountId, this.maxVersions) as StoredPackageRow[];

    if (staleRows.length === 0) {
      return;
    }

    const deleteSave = this.database.prepare(
      'DELETE FROM cloud_saves WHERE account_id = ? AND save_id = ?'
    );
    const deleteRows = this.database.transaction((rows: StoredPackageRow[]) => {
      for (const row of rows) {
        deleteSave.run(row.account_id, row.save_id);
      }
    });
    deleteRows(staleRows);

    await Promise.all(
      staleRows.map((row) =>
        unlink(this.absolutePackagePath(row.package_path)).catch((error) => {
          if ((error as NodeJS.ErrnoException).code !== 'ENOENT') {
            throw error;
          }
        })
      )
    );
  }

  private absolutePackagePath(packagePath: string): string {
    return join(this.packagesDirectory, packagePath);
  }

  private dropLegacyCloudSavesTable(): void {
    const columns = this.database
      .prepare('PRAGMA table_info(cloud_saves)')
      .all() as Array<{ name: string }>;
    // Early local builds used a non-account-scoped cloud_saves table. Drop it
    // during dev migration rather than exposing global saves through v1 routes.
    if (
      columns.length > 0 &&
      !columns.some((column) => column.name === 'account_id')
    ) {
      this.database.exec('DROP TABLE cloud_saves');
    }
  }
}

function metadataFromRow(row: CloudSaveRow): CloudSaveMetadata {
  return {
    saveId: row.save_id,
    createdAt: row.created_at,
    appName: row.app_name,
    ...(row.app_version == null ? {} : { appVersion: row.app_version }),
    snapshotSchemaVersion: row.snapshot_schema_version,
    ...(row.device_label == null ? {} : { deviceLabel: row.device_label }),
    payloadByteCount: row.payload_byte_count,
    payloadChecksum: row.payload_checksum
  };
}

function packageFileName(accountId: string, saveId: string): string {
  return `${encodeURIComponent(accountId)}/${encodeURIComponent(saveId)}.json`;
}

function createLocalDeviceRegistration(options: {
  accountId: string;
  deviceLabel?: string;
}): DeviceRegistration {
  const token = createAuthToken();
  return {
    accountId: options.accountId,
    deviceId: createServerId('device'),
    ...(options.deviceLabel == null
      ? {}
      : { deviceLabel: options.deviceLabel }),
    token,
    tokenType: 'Bearer'
  };
}
