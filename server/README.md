# All Of Me Server

Node.js and Fastify API for optional All Of Me cloud saves.

## Local Development

This service uses pnpm.

```sh
pnpm install
pnpm dev
```

The default local API address is `http://127.0.0.1:3000`.

By default, development and production use local persistent cloud-save storage:

```sh
CLOUD_SAVE_STORE=local
CLOUD_SAVE_DATA_DIR=.data/cloud-saves
```

The local store keeps save metadata in SQLite and encrypted package JSON files
under the configured data directory. Tests default to the in-memory store unless
a test injects a specific store.

Production runs behind Caddy, so `TRUST_PROXY=true` lets Fastify rate-limit by
the original client IP forwarded by the reverse proxy. Port `3000` must stay
bound to localhost only when this is enabled.

## Abuse Controls

The server rejects cloud-save payloads over `CLOUD_SAVE_MAX_PAYLOAD_BYTES` and
uses in-memory rate limits for the single production container:

- `RATE_LIMIT_MAX`: global API requests per IP per window, default `300`.
- `RATE_LIMIT_TIME_WINDOW_MS`: global API window, default `60000`.
- `RATE_LIMIT_REGISTRATION_MAX`: device registrations per IP per window,
  default `5`.
- `RATE_LIMIT_REGISTRATION_TIME_WINDOW_MS`: registration window, default
  `900000`.
- `RATE_LIMIT_SAVE_MAX`: save uploads per bearer token per window, default
  `30`.
- `RATE_LIMIT_SAVE_TIME_WINDOW_MS`: save-upload window, default `60000`.

## Checks

```sh
pnpm typecheck
pnpm test
pnpm build
```

GitHub Actions runs the same checks, plus a production Docker image build, in
`Server CI`.

## Image Publishing

`Server Image` publishes the production image to GitHub Container Registry
after `Server CI` succeeds on `main`, when it is run manually, or when a
`server-v*` tag is pushed.

Published image:

```sh
ghcr.io/kopitarfan/all-of-me-server:latest
```

## Docker

Build the production image from the server directory:

```sh
docker build -t all-of-me-server:local .
```

Run it locally with persistent cloud-save storage mounted from the host:

```sh
mkdir -p .data/docker-cloud-saves
docker run --rm \
  -p 3000:3000 \
  -v "$(pwd)/.data/docker-cloud-saves:/app/data/cloud-saves" \
  all-of-me-server:local
```

For a Vultr host, use Docker Compose with a persistent host directory:

```sh
cp .env.production.example .env.production
sudo mkdir -p /opt/allofme/cloud-saves
sudo chown -R 1000:1000 /opt/allofme/cloud-saves
docker compose --env-file .env.production -f docker-compose.production.yml up -d
```

The production Compose file expects `ALLOFME_SERVER_IMAGE` to point at the
image to run. During local testing, override it with `all-of-me-server:local`.

```sh
ALLOFME_SERVER_IMAGE=all-of-me-server:local \
  docker compose --env-file .env.production -f docker-compose.production.yml up -d
```

## Current Endpoints

- `GET /healthz` returns `{ "ok": true }`.
- `POST /v1/devices/register` creates a new account/device pair and returns a
  bearer token once. The server stores only a token hash.
- `POST /v1/saves` requires `Authorization: Bearer <token>`, accepts one
  encrypted `CloudSavePackage`, and returns metadata when the package passes
  envelope, payload size, and checksum validation.
- `GET /v1/saves` requires bearer auth and returns account-scoped saved-version
  metadata.
- `GET /v1/saves/latest` requires bearer auth and returns the newest saved
  `CloudSavePackage` for the authenticated account.
- `GET /v1/saves/:saveId` requires bearer auth and returns one saved
  `CloudSavePackage` for the authenticated account.

The cloud-save API will build on the Flutter app's encrypted
`CloudSavePackage` shape. The server should store encrypted restore points and
metadata, not plaintext app data.
