import { createPrivateKey, sign } from 'node:crypto';
import { connect } from 'node:http2';
import { readFileSync } from 'node:fs';

export type PushSender = (token: string, environment: 'sandbox' | 'production') => Promise<void>;

// Only an opaque wake-up alert crosses APNs. Front names remain behind receiver authentication.
export function createPushSender(): PushSender | undefined {
  const { APNS_KEY_ID: keyId, APNS_TEAM_ID: teamId, APNS_BUNDLE_ID: bundleId, APNS_KEY_PATH: keyPath } = process.env;
  if (![keyId, teamId, bundleId, keyPath].some(Boolean)) return undefined;
  if (!keyId || !teamId || !bundleId || !keyPath) throw new Error('All APNS_* settings are required.');
  const key = createPrivateKey(readFileSync(keyPath));
  let cached = '';
  let issuedAt = 0;
  return async (token, environment) => {
    const now = Math.floor(Date.now() / 1000);
    if (now - issuedAt > 3000 || !cached) {
      const head = Buffer.from(JSON.stringify({ alg: 'ES256', kid: keyId })).toString('base64url');
      const body = Buffer.from(JSON.stringify({ iss: teamId, iat: now })).toString('base64url');
      const data = head + '.' + body;
      cached = data + '.' + sign('sha256', Buffer.from(data), { key, dsaEncoding: 'ieee-p1363' }).toString('base64url');
      issuedAt = now;
    }
    await new Promise<void>((resolve, reject) => {
      const session = connect(environment === 'production' ? 'https://api.push.apple.com' : 'https://api.sandbox.push.apple.com');
      const done = (error?: Error) => {
        clearTimeout(timeout);
        session.destroy();
        error ? reject(error) : resolve();
      };
      const timeout = setTimeout(() => done(new Error('APNs timeout')), 10_000);
      session.on('error', () => done(new Error('APNs connection failed')));
      const request = session.request({
        ':method': 'POST', ':path': '/3/device/' + token,
        authorization: 'bearer ' + cached,
        'apns-topic': bundleId, 'apns-push-type': 'alert',
        'apns-priority': '10', 'apns-expiration': String(now + 300),
        'apns-collapse-id': 'front-status',
      });
      let status = 0;
      request.on('response', headers => { status = Number(headers[':status']); });
      request.on('data', () => {});
      request.on('error', () => done(new Error('APNs request failed')));
      request.on('end', () => done(status === 200 ? undefined : new Error('APNs rejected notification')));
      request.end(JSON.stringify({ aps: {
        alert: { title: 'All Of Me', body: 'A shared update is available.' },
        sound: 'default',
      } }));
    });
  };
}
