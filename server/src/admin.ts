import { stat, unlink } from 'node:fs/promises';
import { join, resolve } from 'node:path';

import Database from 'better-sqlite3';

import { loadConfig } from './config.js';
import { LocalCloudSaveStore } from './local-cloud-save-store.js';

export class AdminCommandError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'AdminCommandError';
  }
}

export type AdminStats = {
  dataDirectory: string;
  databasePath: string;
  accounts: number;
  devices: {
    total: number;
    active: number;
    revoked: number;
  };
  saves: {
    total: number;
    payloadBytes: number;
    packageFileBytes: number;
    latestCreatedAt: string | null;
    latestStoredAt: string | null;
  };
  linkCodes: {
    total: number;
    active: number;
    expired: number;
    redeemed: number;
  };
};

export type AdminAccountSummary = {
  accountId: string;
  createdAt: string;
  deviceCount: number;
  activeDeviceCount: number;
  revokedDeviceCount: number;
  saveCount: number;
  payloadBytes: number;
  latestSaveCreatedAt: string | null;
  latestDeviceLastUsedAt: string | null;
};

export type AdminDevice = {
  deviceId: string;
  accountId: string;
  deviceLabel: string | null;
  createdAt: string;
  lastUsedAt: string | null;
  tokenStatus: 'active' | 'revoked';
};

export type AdminSave = {
  saveId: string;
  accountId: string;
  deviceId: string;
  createdAt: string;
  storedAt: string;
  appName: string;
  appVersion: string | null;
  snapshotSchemaVersion: number;
  deviceLabel: string | null;
  payloadByteCount: number;
  payloadChecksum: string;
  packagePath: string;
};

export type AdminDeviceLinkCode = {
  accountId: string;
  createdByDeviceId: string;
  expiresAt: string;
  createdAt: string;
  redeemedAt: string | null;
  redeemedByDeviceId: string | null;
  status: 'active' | 'expired' | 'redeemed';
};

export type AdminAccountDetails = AdminAccountSummary & {
  devices: AdminDevice[];
  saves: AdminSave[];
  linkCodes: AdminDeviceLinkCode[];
};

export type DeleteAdminAccountResult = {
  accountId: string;
  deletedAccount: boolean;
  deletedDevices: number;
  deletedSaves: number;
  deletedLinkCodes: number;
  deletedPackageFiles: number;
  missingPackageFiles: number;
};

export type RevokeAdminDeviceResult = {
  accountId: string;
  deviceId: string;
  deviceLabel: string | null;
  tokenStatus: 'active' | 'revoked';
  changed: boolean;
};

type AdminDatabaseOptions = {
  dataDirectory: string;
};

type CliIo = {
  stdout: (message: string) => void;
  stderr: (message: string) => void;
};

type ParsedCliArgs = {
  command: string[];
  dataDirectory?: string;
  json: boolean;
  limit?: number;
  yes: boolean;
  help: boolean;
};

type CountRow = { count: number };
type NullableStringMaxRow = { value: string | null };
type SumRow = { value: number | null };
type PackagePathRow = { package_path: string };

const revokedTokenPrefix = 'revoked:';

export async function getAdminStats(
  options: AdminDatabaseOptions
): Promise<AdminStats> {
  return withAdminDatabase(options, { writable: false }, async (database) => {
    const packagePaths = selectPackagePaths(database);
    const linkCodes = selectDeviceLinkCodes(database);

    return {
      dataDirectory: options.dataDirectory,
      databasePath: databasePath(options.dataDirectory),
      accounts: count(database, 'accounts'),
      devices: {
        total: count(database, 'devices'),
        active: countWhere(database, 'devices', "token_hash NOT LIKE 'revoked:%'"),
        revoked: countWhere(database, 'devices', "token_hash LIKE 'revoked:%'")
      },
      saves: {
        total: count(database, 'cloud_saves'),
        payloadBytes: sum(database, 'cloud_saves', 'payload_byte_count'),
        packageFileBytes: await packageFileBytes(
          options.dataDirectory,
          packagePaths
        ),
        latestCreatedAt: maxString(database, 'cloud_saves', 'created_at'),
        latestStoredAt: maxString(database, 'cloud_saves', 'stored_at')
      },
      linkCodes: linkCodeCounts(linkCodes)
    };
  });
}

export async function listAdminAccounts(
  options: AdminDatabaseOptions & { limit?: number }
): Promise<AdminAccountSummary[]> {
  return withAdminDatabase(options, { writable: false }, async (database) =>
    selectAccountSummaries(database, options.limit ?? 50)
  );
}

export async function getAdminAccount(
  options: AdminDatabaseOptions & { accountId: string }
): Promise<AdminAccountDetails> {
  return withAdminDatabase(options, { writable: false }, async (database) => {
    const account = selectAccountSummary(database, options.accountId);
    if (account == null) {
      throw new AdminCommandError(`Account not found: ${options.accountId}`);
    }

    return {
      ...account,
      devices: selectDevices(database, options.accountId),
      saves: selectSaves(database, options.accountId),
      linkCodes: selectDeviceLinkCodes(database, options.accountId)
    };
  });
}

export async function deleteAdminAccount(
  options: AdminDatabaseOptions & { accountId: string }
): Promise<DeleteAdminAccountResult> {
  const packagePaths = await withAdminDatabase(
    options,
    { writable: true },
    async (database) => {
      const account = selectAccountSummary(database, options.accountId);
      if (account == null) {
        throw new AdminCommandError(`Account not found: ${options.accountId}`);
      }

      const paths = selectPackagePaths(database, options.accountId);
      const deletedLinkCodes = selectDeviceLinkCodes(
        database,
        options.accountId
      ).length;
      const deleteRows = database.transaction(() => {
        database
          .prepare('DELETE FROM cloud_saves WHERE account_id = ?')
          .run(options.accountId);
        database
          .prepare('DELETE FROM device_link_codes WHERE account_id = ?')
          .run(options.accountId);
        database
          .prepare('DELETE FROM devices WHERE account_id = ?')
          .run(options.accountId);
        database
          .prepare('DELETE FROM accounts WHERE account_id = ?')
          .run(options.accountId);
      });
      deleteRows();
      return {
        paths,
        deletedDevices: account.deviceCount,
        deletedSaves: account.saveCount,
        deletedLinkCodes
      };
    }
  );

  const deletedFiles = await deletePackageFiles(
    options.dataDirectory,
    packagePaths.paths
  );

  return {
    accountId: options.accountId,
    deletedAccount: true,
    deletedDevices: packagePaths.deletedDevices,
    deletedSaves: packagePaths.deletedSaves,
    deletedLinkCodes: packagePaths.deletedLinkCodes,
    deletedPackageFiles: deletedFiles.deleted,
    missingPackageFiles: deletedFiles.missing
  };
}

export async function revokeAdminDevice(
  options: AdminDatabaseOptions & { deviceId: string }
): Promise<RevokeAdminDeviceResult> {
  return withAdminDatabase(options, { writable: true }, async (database) => {
    const device = selectDeviceById(database, options.deviceId);
    if (device == null) {
      throw new AdminCommandError(`Device not found: ${options.deviceId}`);
    }

    if (device.tokenStatus === 'revoked') {
      return {
        accountId: device.accountId,
        deviceId: device.deviceId,
        deviceLabel: device.deviceLabel,
        tokenStatus: 'revoked',
        changed: false
      };
    }

    database
      .prepare('UPDATE devices SET token_hash = ? WHERE device_id = ?')
      .run(
        `${revokedTokenPrefix}${device.deviceId}:${new Date().toISOString()}`,
        device.deviceId
      );

    return {
      accountId: device.accountId,
      deviceId: device.deviceId,
      deviceLabel: device.deviceLabel,
      tokenStatus: 'revoked',
      changed: true
    };
  });
}

export async function runAdminCli(
  args: string[],
  io: CliIo = {
    stdout: (message) => console.log(message),
    stderr: (message) => console.error(message)
  }
): Promise<number> {
  try {
    const parsed = parseCliArgs(args);
    if (parsed.help || parsed.command.length === 0) {
      io.stdout(usage());
      return 0;
    }

    const dataDirectory = resolveDataDirectory(parsed);
    const command = parsed.command.join(' ');

    if (command === 'stats') {
      const stats = await getAdminStats({ dataDirectory });
      writeOutput(io, parsed.json, stats, formatStats(stats));
      return 0;
    }

    if (command === 'accounts list') {
      const accounts = await listAdminAccounts({
        dataDirectory,
        limit: parsed.limit
      });
      writeOutput(io, parsed.json, accounts, formatAccounts(accounts));
      return 0;
    }

    if (parsed.command[0] === 'account' && parsed.command[1] === 'show') {
      const accountId = requirePositional(parsed.command, 2, 'accountId');
      const account = await getAdminAccount({ dataDirectory, accountId });
      writeOutput(io, parsed.json, account, formatAccountDetails(account));
      return 0;
    }

    if (parsed.command[0] === 'account' && parsed.command[1] === 'delete') {
      requireYes(parsed);
      const accountId = requirePositional(parsed.command, 2, 'accountId');
      const result = await deleteAdminAccount({ dataDirectory, accountId });
      writeOutput(io, parsed.json, result, formatDeleteAccountResult(result));
      return 0;
    }

    if (parsed.command[0] === 'device' && parsed.command[1] === 'revoke') {
      requireYes(parsed);
      const deviceId = requirePositional(parsed.command, 2, 'deviceId');
      const result = await revokeAdminDevice({ dataDirectory, deviceId });
      writeOutput(io, parsed.json, result, formatRevokeDeviceResult(result));
      return 0;
    }

    throw new AdminCommandError(`Unknown admin command: ${command}`);
  } catch (error) {
    io.stderr(error instanceof Error ? error.message : String(error));
    return 1;
  }
}

function withAdminDatabase<T>(
  options: AdminDatabaseOptions,
  mode: { writable: boolean },
  callback: (database: Database.Database) => Promise<T> | T
): Promise<T> {
  const path = databasePath(options.dataDirectory);
  ensureAdminSchema(options);
  const database = openExistingDatabase(path, !mode.writable);
  database.pragma('foreign_keys = ON');

  return Promise.resolve()
    .then(() => callback(database))
    .finally(() => database.close());
}

function ensureAdminSchema(options: AdminDatabaseOptions): void {
  const database = openExistingDatabase(databasePath(options.dataDirectory), false);
  try {
    const store = new LocalCloudSaveStore(database, {
      dataDirectory: options.dataDirectory,
      maxVersions: 1
    });
    store.migrate();
  } finally {
    database.close();
  }
}

function openExistingDatabase(
  path: string,
  readonly: boolean
): Database.Database {
  try {
    return new Database(path, { fileMustExist: true, readonly });
  } catch (error) {
    throw new AdminCommandError(
      `No local cloud-save database found at ${path}. Start the server once or pass --data-dir.`
    );
  }
}

function databasePath(dataDirectory: string): string {
  return join(dataDirectory, 'cloud-saves.sqlite');
}

function count(database: Database.Database, table: string): number {
  return (
    database.prepare(`SELECT COUNT(*) AS count FROM ${table}`).get() as CountRow
  ).count;
}

function countWhere(
  database: Database.Database,
  table: string,
  whereClause: string
): number {
  return (
    database
      .prepare(`SELECT COUNT(*) AS count FROM ${table} WHERE ${whereClause}`)
      .get() as CountRow
  ).count;
}

function sum(database: Database.Database, table: string, column: string): number {
  return (
    (
      database
        .prepare(`SELECT SUM(${column}) AS value FROM ${table}`)
        .get() as SumRow
    ).value ?? 0
  );
}

function maxString(
  database: Database.Database,
  table: string,
  column: string
): string | null {
  return (
    database
      .prepare(`SELECT MAX(${column}) AS value FROM ${table}`)
      .get() as NullableStringMaxRow
  ).value;
}

function selectAccountSummaries(
  database: Database.Database,
  limit: number
): AdminAccountSummary[] {
  return database
    .prepare(
      `
        SELECT
          a.account_id AS accountId,
          a.created_at AS createdAt,
          COALESCE(d.device_count, 0) AS deviceCount,
          COALESCE(d.active_device_count, 0) AS activeDeviceCount,
          COALESCE(d.revoked_device_count, 0) AS revokedDeviceCount,
          COALESCE(s.save_count, 0) AS saveCount,
          COALESCE(s.payload_bytes, 0) AS payloadBytes,
          s.latest_save_created_at AS latestSaveCreatedAt,
          d.latest_device_last_used_at AS latestDeviceLastUsedAt
        FROM accounts a
        LEFT JOIN (
          SELECT
            account_id,
            COUNT(*) AS device_count,
            SUM(CASE WHEN token_hash LIKE 'revoked:%' THEN 0 ELSE 1 END)
              AS active_device_count,
            SUM(CASE WHEN token_hash LIKE 'revoked:%' THEN 1 ELSE 0 END)
              AS revoked_device_count,
            MAX(last_used_at) AS latest_device_last_used_at
          FROM devices
          GROUP BY account_id
        ) d ON d.account_id = a.account_id
        LEFT JOIN (
          SELECT
            account_id,
            COUNT(*) AS save_count,
            SUM(payload_byte_count) AS payload_bytes,
            MAX(created_at) AS latest_save_created_at
          FROM cloud_saves
          GROUP BY account_id
        ) s ON s.account_id = a.account_id
        ORDER BY COALESCE(s.latest_save_created_at, a.created_at) DESC,
          a.created_at DESC,
          a.account_id DESC
        LIMIT ?
      `
    )
    .all(limit) as AdminAccountSummary[];
}

function selectAccountSummary(
  database: Database.Database,
  accountId: string
): AdminAccountSummary | null {
  return (
    selectAccountSummaries(database, Number.MAX_SAFE_INTEGER).find(
      (account) => account.accountId === accountId
    ) ?? null
  );
}

function selectDeviceById(
  database: Database.Database,
  deviceId: string
): AdminDevice | null {
  const row = database
    .prepare(
      `
        SELECT
          device_id AS deviceId,
          account_id AS accountId,
          device_label AS deviceLabel,
          created_at AS createdAt,
          last_used_at AS lastUsedAt,
          CASE WHEN token_hash LIKE 'revoked:%' THEN 'revoked' ELSE 'active' END
            AS tokenStatus
        FROM devices
        WHERE device_id = ?
      `
    )
    .get(deviceId) as AdminDevice | undefined;

  return row ?? null;
}

function selectDevices(
  database: Database.Database,
  accountId: string
): AdminDevice[] {
  return database
    .prepare(
      `
        SELECT
          device_id AS deviceId,
          account_id AS accountId,
          device_label AS deviceLabel,
          created_at AS createdAt,
          last_used_at AS lastUsedAt,
          CASE WHEN token_hash LIKE 'revoked:%' THEN 'revoked' ELSE 'active' END
            AS tokenStatus
        FROM devices
        WHERE account_id = ?
        ORDER BY created_at DESC, device_id DESC
      `
    )
    .all(accountId) as AdminDevice[];
}

function selectSaves(
  database: Database.Database,
  accountId: string
): AdminSave[] {
  return database
    .prepare(
      `
        SELECT
          save_id AS saveId,
          account_id AS accountId,
          device_id AS deviceId,
          created_at AS createdAt,
          stored_at AS storedAt,
          app_name AS appName,
          app_version AS appVersion,
          snapshot_schema_version AS snapshotSchemaVersion,
          device_label AS deviceLabel,
          payload_byte_count AS payloadByteCount,
          payload_checksum AS payloadChecksum,
          package_path AS packagePath
        FROM cloud_saves
        WHERE account_id = ?
        ORDER BY created_at DESC, stored_at DESC, save_id DESC
      `
    )
    .all(accountId) as AdminSave[];
}

function selectDeviceLinkCodes(
  database: Database.Database,
  accountId?: string
): AdminDeviceLinkCode[] {
  const where = accountId == null ? '' : 'WHERE account_id = ?';
  const rows = database
    .prepare(
      `
        SELECT
          account_id AS accountId,
          created_by_device_id AS createdByDeviceId,
          expires_at AS expiresAt,
          created_at AS createdAt,
          redeemed_at AS redeemedAt,
          redeemed_by_device_id AS redeemedByDeviceId
        FROM device_link_codes
        ${where}
        ORDER BY created_at DESC
      `
    )
    .all(...(accountId == null ? [] : [accountId])) as Array<
    Omit<AdminDeviceLinkCode, 'status'>
  >;

  return rows.map((row) => ({ ...row, status: linkCodeStatus(row) }));
}

function selectPackagePaths(
  database: Database.Database,
  accountId?: string
): string[] {
  const where = accountId == null ? '' : 'WHERE account_id = ?';
  const rows = database
    .prepare(
      `
        SELECT package_path
        FROM cloud_saves
        ${where}
      `
    )
    .all(...(accountId == null ? [] : [accountId])) as PackagePathRow[];

  return rows.map((row) => row.package_path);
}

async function packageFileBytes(
  dataDirectory: string,
  packagePaths: string[]
): Promise<number> {
  const sizes = await Promise.all(
    packagePaths.map(async (packagePath) => {
      try {
        return (await stat(absolutePackagePath(dataDirectory, packagePath)))
          .size;
      } catch (error) {
        if ((error as NodeJS.ErrnoException).code === 'ENOENT') {
          return 0;
        }
        throw error;
      }
    })
  );

  return sizes.reduce((total, size) => total + size, 0);
}

async function deletePackageFiles(
  dataDirectory: string,
  packagePaths: string[]
): Promise<{ deleted: number; missing: number }> {
  let deleted = 0;
  let missing = 0;

  for (const packagePath of packagePaths) {
    try {
      await unlink(absolutePackagePath(dataDirectory, packagePath));
      deleted += 1;
    } catch (error) {
      if ((error as NodeJS.ErrnoException).code === 'ENOENT') {
        missing += 1;
      } else {
        throw error;
      }
    }
  }

  return { deleted, missing };
}

function absolutePackagePath(dataDirectory: string, packagePath: string): string {
  const packagesDirectory = resolve(dataDirectory, 'packages');
  const absolutePath = resolve(packagesDirectory, packagePath);
  if (
    absolutePath !== packagesDirectory &&
    !absolutePath.startsWith(`${packagesDirectory}/`)
  ) {
    throw new AdminCommandError(`Unsafe package path in database: ${packagePath}`);
  }
  return absolutePath;
}

function linkCodeCounts(linkCodes: AdminDeviceLinkCode[]): AdminStats['linkCodes'] {
  return {
    total: linkCodes.length,
    active: linkCodes.filter((linkCode) => linkCode.status === 'active').length,
    expired: linkCodes.filter((linkCode) => linkCode.status === 'expired')
      .length,
    redeemed: linkCodes.filter((linkCode) => linkCode.status === 'redeemed')
      .length
  };
}

function linkCodeStatus(
  linkCode: Pick<AdminDeviceLinkCode, 'expiresAt' | 'redeemedAt'>
): AdminDeviceLinkCode['status'] {
  if (linkCode.redeemedAt != null) {
    return 'redeemed';
  }
  return Date.parse(linkCode.expiresAt) <= Date.now() ? 'expired' : 'active';
}

function parseCliArgs(args: string[]): ParsedCliArgs {
  const parsed: ParsedCliArgs = {
    command: [],
    json: false,
    yes: false,
    help: false
  };

  for (let index = 0; index < args.length; index += 1) {
    const arg = args[index]!;
    if (arg === '--help' || arg === '-h') {
      parsed.help = true;
    } else if (arg === '--json') {
      parsed.json = true;
    } else if (arg === '--yes') {
      parsed.yes = true;
    } else if (arg === '--data-dir') {
      parsed.dataDirectory = requireFlagValue(args, (index += 1), '--data-dir');
    } else if (arg.startsWith('--data-dir=')) {
      parsed.dataDirectory = arg.slice('--data-dir='.length);
    } else if (arg === '--limit') {
      parsed.limit = parseLimit(requireFlagValue(args, (index += 1), '--limit'));
    } else if (arg.startsWith('--limit=')) {
      parsed.limit = parseLimit(arg.slice('--limit='.length));
    } else if (arg.startsWith('-')) {
      throw new AdminCommandError(`Unknown flag: ${arg}`);
    } else {
      parsed.command.push(arg);
    }
  }

  return parsed;
}

function requireFlagValue(args: string[], index: number, flag: string): string {
  const value = args[index];
  if (value == null || value.startsWith('-')) {
    throw new AdminCommandError(`Missing value for ${flag}`);
  }
  return value;
}

function parseLimit(value: string): number {
  const limit = Number(value);
  if (!Number.isInteger(limit) || limit < 1) {
    throw new AdminCommandError(`Invalid --limit value: ${value}`);
  }
  return limit;
}

function resolveDataDirectory(parsed: ParsedCliArgs): string {
  if (parsed.dataDirectory != null) {
    return parsed.dataDirectory;
  }

  const config = loadConfig();
  if (config.cloudSaveStore !== 'local') {
    throw new AdminCommandError(
      'Admin commands inspect the local SQLite store. Set CLOUD_SAVE_STORE=local or pass --data-dir.'
    );
  }
  return config.cloudSaveDataDirectory;
}

function requirePositional(
  command: string[],
  index: number,
  name: string
): string {
  const value = command[index];
  if (value == null || value.trim().length === 0) {
    throw new AdminCommandError(`Missing ${name}.`);
  }
  return value;
}

function requireYes(parsed: ParsedCliArgs): void {
  if (!parsed.yes) {
    throw new AdminCommandError(
      'This command changes server state. Re-run it with --yes when you are sure.'
    );
  }
}

function writeOutput(
  io: CliIo,
  asJson: boolean,
  value: unknown,
  formatted: string
): void {
  io.stdout(asJson ? JSON.stringify(value, null, 2) : formatted);
}

function formatStats(stats: AdminStats): string {
  return [
    'Cloud save admin stats',
    `Data directory: ${stats.dataDirectory}`,
    `Database: ${stats.databasePath}`,
    `Accounts: ${stats.accounts}`,
    `Devices: ${stats.devices.active} active, ${stats.devices.revoked} revoked, ${stats.devices.total} total`,
    `Saves: ${stats.saves.total} total, ${formatBytes(stats.saves.payloadBytes)} payload, ${formatBytes(stats.saves.packageFileBytes)} package files`,
    `Latest save: ${stats.saves.latestCreatedAt ?? 'none'}`,
    `Link codes: ${stats.linkCodes.active} active, ${stats.linkCodes.expired} expired, ${stats.linkCodes.redeemed} redeemed, ${stats.linkCodes.total} total`
  ].join('\n');
}

function formatAccounts(accounts: AdminAccountSummary[]): string {
  if (accounts.length === 0) {
    return 'No accounts found.';
  }

  return formatTable(
    accounts.map((account) => ({
      accountId: account.accountId,
      createdAt: account.createdAt,
      devices: String(account.deviceCount),
      activeDevices: String(account.activeDeviceCount),
      saves: String(account.saveCount),
      payload: formatBytes(account.payloadBytes),
      latestSave: account.latestSaveCreatedAt ?? ''
    }))
  );
}

function formatAccountDetails(account: AdminAccountDetails): string {
  return [
    `Account ${account.accountId}`,
    `Created: ${account.createdAt}`,
    `Devices: ${account.activeDeviceCount} active, ${account.revokedDeviceCount} revoked, ${account.deviceCount} total`,
    `Saves: ${account.saveCount} total, ${formatBytes(account.payloadBytes)} payload`,
    '',
    'Devices',
    account.devices.length === 0
      ? 'No devices found.'
      : formatTable(
          account.devices.map((device) => ({
            deviceId: device.deviceId,
            label: device.deviceLabel ?? '',
            status: device.tokenStatus,
            createdAt: device.createdAt,
            lastUsedAt: device.lastUsedAt ?? ''
          }))
        ),
    '',
    'Saves',
    account.saves.length === 0
      ? 'No saves found.'
      : formatTable(
          account.saves.map((save) => ({
            saveId: save.saveId,
            deviceId: save.deviceId,
            createdAt: save.createdAt,
            storedAt: save.storedAt,
            bytes: String(save.payloadByteCount),
            appVersion: save.appVersion ?? ''
          }))
        ),
    '',
    'Link codes',
    account.linkCodes.length === 0
      ? 'No link codes found.'
      : formatTable(
          account.linkCodes.map((linkCode) => ({
            status: linkCode.status,
            createdBy: linkCode.createdByDeviceId,
            createdAt: linkCode.createdAt,
            expiresAt: linkCode.expiresAt,
            redeemedBy: linkCode.redeemedByDeviceId ?? ''
          }))
        )
  ].join('\n');
}

function formatDeleteAccountResult(result: DeleteAdminAccountResult): string {
  return [
    `Deleted account: ${result.accountId}`,
    `Devices deleted: ${result.deletedDevices}`,
    `Saves deleted: ${result.deletedSaves}`,
    `Package files deleted: ${result.deletedPackageFiles}`,
    `Package files already missing: ${result.missingPackageFiles}`
  ].join('\n');
}

function formatRevokeDeviceResult(result: RevokeAdminDeviceResult): string {
  return [
    `${result.changed ? 'Revoked' : 'Already revoked'} device: ${result.deviceId}`,
    `Account: ${result.accountId}`,
    `Label: ${result.deviceLabel ?? 'none'}`
  ].join('\n');
}

function formatTable(rows: Array<Record<string, string>>): string {
  if (rows.length === 0) {
    return '';
  }

  const headers = Object.keys(rows[0]!);
  const widths = headers.map((header) =>
    Math.max(
      header.length,
      ...rows.map((row) => String(row[header] ?? '').length)
    )
  );
  const renderRow = (values: string[]) =>
    values.map((value, index) => value.padEnd(widths[index]!)).join('  ');

  return [
    renderRow(headers),
    renderRow(widths.map((width) => '-'.repeat(width))),
    ...rows.map((row) =>
      renderRow(headers.map((header) => String(row[header] ?? '')))
    )
  ].join('\n');
}

function formatBytes(bytes: number): string {
  if (bytes < 1024) {
    return `${bytes} B`;
  }
  const kib = bytes / 1024;
  if (kib < 1024) {
    return `${kib.toFixed(1)} KiB`;
  }
  return `${(kib / 1024).toFixed(1)} MiB`;
}

function usage(): string {
  return `
All Of Me cloud-save admin commands

Usage:
  pnpm admin stats [--json] [--data-dir DIR]
  pnpm admin accounts list [--limit N] [--json] [--data-dir DIR]
  pnpm admin account show <accountId> [--json] [--data-dir DIR]
  pnpm admin account delete <accountId> --yes [--json] [--data-dir DIR]
  pnpm admin device revoke <deviceId> --yes [--json] [--data-dir DIR]

These commands inspect the local SQLite cloud-save store only. They show
metadata and never decrypt cloud-save package contents.
`.trim();
}
