import Database from 'better-sqlite3';
import { afterEach, describe, expect, it, vi } from 'vitest';
import { randomUUID } from 'node:crypto';
import { mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { MemoryAuthStore } from '../src/auth-store.js';
import { MemoryCloudSaveStore } from '../src/cloud-save-store.js';
import { buildApp } from '../src/app.js';
import { loadConfig } from '../src/config.js';
import type { FastifyInstance } from 'fastify';

const apps: FastifyInstance[] = [];
afterEach(async () => {
  for (const app of apps.splice(0)) await app.close();
  vi.useRealTimers();
});

async function fixture() {
  const db = new Database(':memory:');
  const push = vi.fn().mockResolvedValue(undefined);
  const authStore = new MemoryAuthStore();
  const app = await buildApp(loadConfig({ NODE_ENV: 'test' }), {
    authStore, cloudSaveStore: new MemoryCloudSaveStore(), frontSharing: { database: db, push },
  });
  apps.push(app);
  const register = await app.inject({ method: 'POST', url: '/v1/devices/register', payload: { deviceLabel: 'Sender' } });
  const owner = { authorization: 'Bearer ' + register.json().token };
  const settings = await app.inject({ method: 'PUT', url: '/v1/front-sharing/settings', headers: owner, payload: { paused: false } });
  expect(settings.statusCode).toBe(200);
  const invite = await app.inject({ method: 'POST', url: '/v1/front-sharing/invitations', headers: owner, payload: { label: 'Migs' } });
  const code = invite.json().code;
  const pair = await app.inject({ method: 'POST', url: '/v1/front-sharing/pair', payload: { code } });
  expect(pair.statusCode).toBe(200);
  const receiver = { authorization: 'Bearer ' + pair.json().token };
  return { app, db, push, owner, receiver, code, authStore, id: pair.json().recipientId };
}
const status = (names = ['A', 'B'], time = Date.now()) => ({
  eventId: randomUUID(), changedAt: new Date(time).toISOString(),
  members: names.map(name => ({ name })),
});

describe('front sharing boundaries', () => {
  it('blocks receiver reads and purges shared data when the sender account is deleted', async () => {
    const { app, db, owner, receiver, authStore } = await fixture();
    await app.inject({ method: 'PUT', url: '/v1/front-sharing/status', headers: owner, payload: status() });
    vi.spyOn(authStore, 'accountExists').mockResolvedValue(false);
    expect((await app.inject({ method: 'GET', url: '/v1/front-sharing/current', headers: receiver })).statusCode).toBe(401);
    expect(db.prepare('SELECT * FROM front_owners').all()).toHaveLength(0);
    expect(db.prepare('SELECT * FROM front_recipients').all()).toHaveLength(0);
  });

  it('pairs once, shares multiple fronts, and prevents receiver access to owner APIs', async () => {
    const { app, owner, receiver, code } = await fixture();
    expect((await app.inject({ method: 'POST', url: '/v1/front-sharing/pair', payload: { code } })).statusCode).toBe(400);
    const value = status();
    expect((await app.inject({ method: 'PUT', url: '/v1/front-sharing/status', headers: owner, payload: value })).statusCode).toBe(200);
    const current = await app.inject({ method: 'GET', url: '/v1/front-sharing/current', headers: receiver });
    expect(current.json()).toEqual({ paused: false, status: value });
    expect(current.headers['cache-control']).toBe('no-store');
    for (const url of ['/v1/front-sharing/settings', '/v1/saves/latest']) {
      expect((await app.inject({ method: 'GET', url, headers: receiver })).statusCode).toBe(401);
    }
    expect((await app.inject({ method: 'GET', url: '/v1/front-sharing/current', headers: owner })).statusCode).toBe(401);
  });

  it('hides status while paused, rejects publication, and resumes without old details', async () => {
    const { app, owner, receiver } = await fixture();
    await app.inject({ method: 'PUT', url: '/v1/front-sharing/status', headers: owner, payload: status() });
    await app.inject({ method: 'PUT', url: '/v1/front-sharing/settings', headers: owner, payload: { paused: true } });
    expect((await app.inject({ method: 'GET', url: '/v1/front-sharing/current', headers: receiver })).json())
      .toEqual({ paused: true, status: null });
    expect((await app.inject({ method: 'PUT', url: '/v1/front-sharing/status', headers: owner, payload: status() })).statusCode).toBe(409);
    await app.inject({ method: 'PUT', url: '/v1/front-sharing/settings', headers: owner, payload: { paused: false } });
    expect((await app.inject({ method: 'GET', url: '/v1/front-sharing/current', headers: receiver })).json().status).toBeNull();
  });

  it('revokes a receiver and rejects cross-account revocation', async () => {
    const { app, owner, receiver, id } = await fixture();
    const stranger = await app.inject({ method: 'POST', url: '/v1/devices/register', payload: {} });
    expect((await app.inject({ method: 'DELETE', url: '/v1/front-sharing/recipients/' + id,
      headers: { authorization: 'Bearer ' + stranger.json().token } })).statusCode).toBe(404);
    expect((await app.inject({ method: 'DELETE', url: '/v1/front-sharing/recipients/' + id, headers: owner })).statusCode).toBe(204);
    expect((await app.inject({ method: 'GET', url: '/v1/front-sharing/current', headers: receiver })).statusCode).toBe(401);
  });

  it('rejects expired invitations, oversized status, and invalid timestamps', async () => {
    const { app, db, owner } = await fixture();
    const invite = await app.inject({ method: 'POST', url: '/v1/front-sharing/invitations', headers: owner, payload: { label: 'Other' } });
    db.prepare('UPDATE front_invites SET expires = 0').run();
    expect((await app.inject({ method: 'POST', url: '/v1/front-sharing/pair', payload: { code: invite.json().code } })).statusCode).toBe(400);
    for (const payload of [status(Array(51).fill('Name')), { ...status(), changedAt: 'yesterday' }, { ...status(), note: 'private' }]) {
      expect((await app.inject({ method: 'PUT', url: '/v1/front-sharing/status', headers: owner, payload })).statusCode).toBe(400);
    }
  });

  it('deduplicates retries and ignores older updates', async () => {
    const { app, db, owner, receiver } = await fixture();
    const value = status(['Latest']);
    for (let i = 0; i < 2; i++) {
      await app.inject({ method: 'PUT', url: '/v1/front-sharing/status', headers: owner, payload: value });
    }
    const row = db.prepare('SELECT version FROM front_owners').get() as { version: number };
    expect(row.version).toBe(2); // One settings change, one actual publication.
    const older = await app.inject({ method: 'PUT', url: '/v1/front-sharing/status', headers: owner,
      payload: status(['Older'], Date.now() - 10_000) });
    expect(older.json()).toEqual({ accepted: false });
    expect((await app.inject({ method: 'GET', url: '/v1/front-sharing/current', headers: receiver })).json().status).toEqual(value);
  });

  it('queues delivery, retries a failure, and uses the production device environment', async () => {
    vi.useFakeTimers({ toFake: ['Date', 'setInterval', 'clearInterval'] });
    const { app, db, owner, receiver, push } = await fixture();
    const token = 'a'.repeat(64);
    await app.inject({ method: 'PUT', url: '/v1/front-sharing/device', headers: receiver,
      payload: { token, environment: 'production' } });
    push.mockRejectedValueOnce(new Error('offline'));
    await app.inject({ method: 'PUT', url: '/v1/front-sharing/status', headers: owner, payload: status() });
    await vi.advanceTimersByTimeAsync(2000);
    expect(push).toHaveBeenCalledWith(token, 'production');
    expect(db.prepare('SELECT * FROM front_jobs').all()).toHaveLength(1);
    await vi.advanceTimersByTimeAsync(2000);
    expect(push).toHaveBeenCalledTimes(2);
    expect(db.prepare('SELECT * FROM front_jobs').all()).toHaveLength(0);
  });

  it('disconnect removes receiver access and pending delivery', async () => {
    const { app, db, receiver } = await fixture();
    expect((await app.inject({ method: 'DELETE', url: '/v1/front-sharing/device', headers: receiver })).statusCode).toBe(204);
    expect((await app.inject({ method: 'GET', url: '/v1/front-sharing/current', headers: receiver })).statusCode).toBe(401);
    expect(db.prepare('SELECT * FROM front_jobs').all()).toHaveLength(0);
  });
});

it('persists pairing, current status, and notification jobs across restarts', async () => {
  const directory = await mkdtemp(join(tmpdir(), 'aom-sharing-'));
  const path = join(directory, 'sharing.sqlite');
  const authStore = new MemoryAuthStore();
  const cloudSaveStore = new MemoryCloudSaveStore();
  try {
    const open = async () => {
      const database = new Database(path);
      const app = await buildApp(loadConfig({ NODE_ENV: 'test' }), {
        authStore, cloudSaveStore, frontSharing: { database, push: vi.fn().mockResolvedValue(undefined) },
      });
      apps.push(app);
      return { app, database };
    };
    const first = await open();
    const registration = await first.app.inject({ method: 'POST', url: '/v1/devices/register', payload: {} });
    const owner = { authorization: 'Bearer ' + registration.json().token };
    await first.app.inject({ method: 'PUT', url: '/v1/front-sharing/settings', headers: owner, payload: { paused: false } });
    const invitation = await first.app.inject({ method: 'POST', url: '/v1/front-sharing/invitations', headers: owner, payload: { label: 'Migs' } });
    const pair = await first.app.inject({ method: 'POST', url: '/v1/front-sharing/pair', payload: { code: invitation.json().code } });
    const receiver = { authorization: 'Bearer ' + pair.json().token };
    await first.app.inject({ method: 'PUT', url: '/v1/front-sharing/device', headers: receiver,
      payload: { token: 'a'.repeat(64), environment: 'production' } });
    const value = status(['Shared']);
    await first.app.inject({ method: 'PUT', url: '/v1/front-sharing/status', headers: owner, payload: value });
    await first.app.close();
    apps.splice(apps.indexOf(first.app), 1);
    const second = await open();
    expect((await second.app.inject({ method: 'GET', url: '/v1/front-sharing/current', headers: receiver })).json().status).toEqual(value);
    expect(second.database.prepare('SELECT * FROM front_jobs').all()).toHaveLength(1);
    await second.app.close();
    apps.splice(apps.indexOf(second.app), 1);
  } finally { await rm(directory, { recursive: true, force: true }); }
});
