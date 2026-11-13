import { randomBytes, randomUUID } from 'node:crypto';
import { mkdir } from 'node:fs/promises';
import { join } from 'node:path';
import Database from 'better-sqlite3';
import { z } from 'zod';
import type { FastifyInstance, FastifyRequest } from 'fastify';
import type { AuthStore } from './auth-store.js';
import { hashAuthToken } from './auth-store.js';
import { requireAuthenticatedDevice } from './auth-request.js';
import type { AppConfig } from './config.js';
import { createPushSender, type PushSender } from './front-sharing-push.js';

const statusSchema = z.object({
  eventId: z.string().uuid(),
  changedAt: z.iso.datetime({ offset: true }),
  members: z.array(z.object({
    name: z.string().trim().min(1).max(100),
  }).strict()).max(50),
}).strict();
const labelSchema = z.object({ label: z.string().trim().min(1).max(80) }).strict();
type OwnerRow = { account: string; paused: number; status: string | null; version: number };
type RecipientRow = { id: string; account: string; label: string; token_hash: string; push_token: string | null; environment: string | null };
type InviteRow = { account: string; label: string; expires: number };

export async function registerFrontSharing(
  app: FastifyInstance, config: AppConfig, auth: AuthStore,
  options: { database?: Database.Database; push?: PushSender } = {},
): Promise<void> {
  if (process.env.FRONT_SHARING_ENABLED !== 'true' && !options.database) return;
  if (!options.database && config.cloudSaveStore === 'local') {
    await mkdir(config.cloudSaveDataDirectory, { recursive: true });
  }
  const db = options.database ?? new Database(config.cloudSaveStore === 'memory'
    ? ':memory:' : join(config.cloudSaveDataDirectory, 'front-sharing.sqlite'));
  db.pragma('journal_mode = WAL');
  db.exec(`
    CREATE TABLE IF NOT EXISTS front_owners (
      account TEXT PRIMARY KEY, paused INTEGER NOT NULL DEFAULT 1,
      status TEXT, version INTEGER NOT NULL DEFAULT 0
    );
    CREATE TABLE IF NOT EXISTS front_invites (
      hash TEXT PRIMARY KEY, account TEXT NOT NULL, label TEXT NOT NULL, expires INTEGER NOT NULL
    );
    CREATE TABLE IF NOT EXISTS front_recipients (
      id TEXT PRIMARY KEY, account TEXT NOT NULL, label TEXT NOT NULL,
      token_hash TEXT NOT NULL UNIQUE, push_token TEXT, environment TEXT
    );
    CREATE TABLE IF NOT EXISTS front_jobs (
      recipient TEXT PRIMARY KEY, version INTEGER NOT NULL,
      attempts INTEGER NOT NULL DEFAULT 0, next_at INTEGER NOT NULL DEFAULT 0
    );
  `);
  const push = options.push ?? createPushSender();
  // Scope validation failures to this feature; never echo submitted names or tokens.
  app.addHook('preValidation', async (request) => {
    if (!request.url.startsWith('/v1/front-sharing/')) return;
    const path = request.url.split('?')[0];
    let schema: z.ZodType | undefined;
    if (path.endsWith('/status') && request.method === 'PUT') schema = statusSchema;
    if (path.endsWith('/invitations') && request.method === 'POST') schema = labelSchema;
    if (path.endsWith('/settings') && request.method === 'PUT') schema = z.object({ paused: z.boolean() }).strict();
    if (path.endsWith('/pair') && request.method === 'POST') schema = z.object({ code: z.string().min(20).max(100) }).strict();
    if (path.endsWith('/device') && request.method === 'PUT') schema = z.object({
      token: z.string().regex(/^[a-f0-9]{64,200}$/),
      environment: z.enum(['sandbox', 'production']),
    }).strict();
    if (schema && !schema.safeParse(request.body).success) throw app.httpErrors.badRequest('Sharing request is invalid.');
  });
  const owner = async (request: FastifyRequest) => {
    const device = await requireAuthenticatedDevice(app, auth, request);
    db.prepare('INSERT OR IGNORE INTO front_owners (account) VALUES (?)').run(device.accountId);
    return device.accountId;
  };
  const purgeAccount = (account: string) => db.transaction(() => {
    db.prepare('DELETE FROM front_jobs WHERE recipient IN (SELECT id FROM front_recipients WHERE account = ?)').run(account);
    db.prepare('DELETE FROM front_recipients WHERE account = ?').run(account);
    db.prepare('DELETE FROM front_invites WHERE account = ?').run(account);
    db.prepare('DELETE FROM front_owners WHERE account = ?').run(account);
  })();
  const recipient = async (request: FastifyRequest): Promise<RecipientRow> => {
    const match = /^Bearer (aom_receiver_[A-Za-z0-9_-]+)$/.exec(request.headers.authorization ?? '');
    const row = match ? db.prepare('SELECT * FROM front_recipients WHERE token_hash = ?')
      .get(hashAuthToken(match[1])) as RecipientRow | undefined : undefined;
    if (!row) throw app.httpErrors.unauthorized('Receiver credentials are invalid or revoked.');
    if (!await auth.accountExists(row.account)) {
      purgeAccount(row.account);
      throw app.httpErrors.unauthorized('Receiver credentials are invalid or revoked.');
    }
    return row;
  };
  const ownerState = (account: string) => db.prepare('SELECT * FROM front_owners WHERE account = ?').get(account) as OwnerRow;
  const queue = (account: string, version: number) => {
    db.prepare(`INSERT INTO front_jobs (recipient, version)
      SELECT id, ? FROM front_recipients WHERE account = ? AND push_token IS NOT NULL
      ON CONFLICT(recipient) DO UPDATE SET version = excluded.version, attempts = 0, next_at = 0`).run(version, account);
  };
  app.addHook('onSend', async (request, reply, payload) => {
    if (request.url.startsWith('/v1/front-sharing/')) reply.header('cache-control', 'no-store');
    return payload;
  });
  app.get('/v1/front-sharing/settings', async request => {
    const account = await owner(request);
    const state = ownerState(account);
    return {
      paused: Boolean(state.paused), pushConfigured: Boolean(push),
      recipients: db.prepare('SELECT id, label FROM front_recipients WHERE account = ?').all(account),
    };
  });
  app.put('/v1/front-sharing/settings', async request => {
    const account = await owner(request);
    const { paused } = z.object({ paused: z.boolean() }).strict().parse(request.body);
    db.transaction(() => {
      db.prepare('UPDATE front_owners SET paused = ?, status = NULL, version = version + 1 WHERE account = ?')
        .run(Number(paused), account);
      db.prepare('DELETE FROM front_invites WHERE account = ?').run(account);
      queue(account, ownerState(account).version);
    })();
    return { paused };
  });
  app.post('/v1/front-sharing/invitations', async request => {
    const account = await owner(request);
    const { label } = labelSchema.parse(request.body);
    const code = randomBytes(24).toString('base64url');
    const expires = Date.now() + 10 * 60 * 1000;
    db.transaction(() => {
      db.prepare('DELETE FROM front_invites WHERE expires <= ? OR account = ?').run(Date.now(), account);
      db.prepare('INSERT INTO front_invites VALUES (?, ?, ?, ?)').run(hashAuthToken(code), account, label, expires);
    })();
    return { code, expiresAt: new Date(expires).toISOString() };
  });
  app.post('/v1/front-sharing/pair', {
    config: { rateLimit: { max: 10, timeWindow: 60_000 } },
  }, async request => {
    const { code } = z.object({ code: z.string().min(20).max(100) }).strict().parse(request.body);
    return db.transaction(() => {
      const hash = hashAuthToken(code);
      const invite = db.prepare('SELECT * FROM front_invites WHERE hash = ?').get(hash) as InviteRow | undefined;
      if (!invite || invite.expires <= Date.now()) throw app.httpErrors.badRequest('Invitation is invalid or expired.');
      const id = randomUUID();
      const token = 'aom_receiver_' + randomBytes(32).toString('base64url');
      db.prepare('INSERT INTO front_recipients (id, account, label, token_hash) VALUES (?, ?, ?, ?)')
        .run(id, invite.account, invite.label, hashAuthToken(token));
      db.prepare('DELETE FROM front_invites WHERE hash = ?').run(hash);
      return { recipientId: id, token };
    })();
  });
  app.delete<{ Params: { id: string } }>('/v1/front-sharing/recipients/:id', async (request, reply) => {
    const account = await owner(request);
    db.transaction(() => {
      const result = db.prepare('DELETE FROM front_recipients WHERE id = ? AND account = ?').run(request.params.id, account);
      if (!result.changes) throw app.httpErrors.notFound('Recipient not found.');
      db.prepare('DELETE FROM front_jobs WHERE recipient = ?').run(request.params.id);
    })();
    return reply.code(204).send();
  });
  app.put('/v1/front-sharing/status', async request => {
    const account = await owner(request);
    const status = statusSchema.parse(request.body);
    if (Date.parse(status.changedAt) > Date.now() + 60_000) throw app.httpErrors.badRequest('Update time is in the future.');
    return db.transaction(() => {
      const state = ownerState(account);
      if (state.paused) throw app.httpErrors.conflict('Front sharing is paused.');
      if (state.status) {
        const previous = statusSchema.parse(JSON.parse(state.status));
        if (previous.eventId === status.eventId) return { accepted: true };
        if (Date.parse(previous.changedAt) >= Date.parse(status.changedAt)) return { accepted: false };
      }
      db.prepare('UPDATE front_owners SET status = ?, version = version + 1 WHERE account = ?')
        .run(JSON.stringify(status), account);
      queue(account, ownerState(account).version);
      return { accepted: true };
    })();
  });
  app.get('/v1/front-sharing/current', async request => {
    const receiver = await recipient(request);
    const state = ownerState(receiver.account);
    return { paused: Boolean(state.paused), status: state.paused || !state.status ? null : JSON.parse(state.status) };
  });
  app.put('/v1/front-sharing/device', async request => {
    const receiver = await recipient(request);
    const { token, environment } = z.object({
      token: z.string().regex(/^[a-f0-9]{64,200}$/),
      environment: z.enum(['sandbox', 'production']),
    }).strict().parse(request.body);
    db.transaction(() => {
      // One installation's APNs token must not fan out to former pairings.
      db.prepare('UPDATE front_recipients SET push_token = NULL, environment = NULL WHERE push_token = ?').run(token);
      db.prepare('UPDATE front_recipients SET push_token = ?, environment = ? WHERE id = ?').run(token, environment, receiver.id);
    })();
    return { registered: true };
  });
  app.delete('/v1/front-sharing/device', async (request, reply) => {
    const receiver = await recipient(request);
    db.transaction(() => {
      db.prepare('DELETE FROM front_recipients WHERE id = ?').run(receiver.id);
      db.prepare('DELETE FROM front_jobs WHERE recipient = ?').run(receiver.id);
    })();
    return reply.code(204).send();
  });
  let running = false;
  let stopped = false;
  const drain = async () => {
    if (running || stopped) return;
    running = true;
    try {
      const accounts = db.prepare('SELECT account FROM front_owners').all() as { account: string }[];
      for (const row of accounts) {
        if (!await auth.accountExists(row.account)) purgeAccount(row.account);
      }
      if (!push) return;
      const jobs = db.prepare(`SELECT j.*, r.push_token, r.environment FROM front_jobs j
        JOIN front_recipients r ON r.id = j.recipient WHERE j.next_at <= ? LIMIT 20`).all(Date.now()) as
        { recipient: string; version: number; attempts: number; push_token: string | null; environment: string }[];
      for (const job of jobs) {
        if (stopped) break;
        try {
          if (job.push_token) await push(job.push_token, job.environment as 'sandbox' | 'production');
          db.prepare('DELETE FROM front_jobs WHERE recipient = ? AND version = ?').run(job.recipient, job.version);
        } catch {
          db.prepare('UPDATE front_jobs SET attempts = attempts + 1, next_at = ? WHERE recipient = ? AND version = ?')
            .run(Date.now() + Math.min(3600_000, 1000 * 2 ** Math.min(job.attempts, 12)), job.recipient, job.version);
        }
      }
    } finally { running = false; }
  };
  const timer = setInterval(() => { void drain(); }, 2000);
  timer.unref();
  app.addHook('onClose', async () => {
    stopped = true;
    clearInterval(timer);
    while (running) await new Promise(resolve => setTimeout(resolve, 20));
    db.close();
  });
}
