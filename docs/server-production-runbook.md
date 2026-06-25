# Server Production Runbook

Last updated: 2026-06-24

This runbook covers the All Of Me cloud-save API running on Vultr.

## Production Topology

- Public API: `https://api.allofmeapp.com`
- Health check: `https://api.allofmeapp.com/healthz`
- Container image: `ghcr.io/kopitarfan/all-of-me-server:latest`
- Host: Vultr Ubuntu instance
- Reverse proxy: Caddy
- Runtime: Docker Compose
- App storage: SQLite metadata plus encrypted cloud-save package files
- Object Storage bucket: `allofme-backup-data`
- Object Storage endpoint: `https://sjc1.vultrobjects.com`

The Fastify app listens inside Docker on port `3000`. Docker publishes that
port on `127.0.0.1:3000` only. Caddy listens publicly on ports `80` and `443`
and proxies HTTPS traffic to `127.0.0.1:3000`.

Production sets `TRUST_PROXY=true` so Fastify uses the original client IP from
Caddy's forwarded headers for rate limiting. Keep Docker bound to
`127.0.0.1:3000`; do not expose port `3000` publicly with trusted proxy headers
enabled.

## Host Paths

- App directory: `/opt/allofme/app`
- Docker Compose file: `/opt/allofme/app/docker-compose.yml`
- Production env file: `/opt/allofme/app/.env.production`
- Persistent app data: `/opt/allofme/cloud-saves`
- Local backup archives: `/opt/allofme/backups`
- Backup script: `/usr/local/sbin/allofme-backup`
- Backup env file: `/etc/allofme-backup.env`
- Caddy config: `/etc/caddy/Caddyfile`
- Backup cron: `/etc/cron.d/allofme-backup`
- Backup log: `/var/log/allofme-backup.log`

Do not commit production secrets. The checked-in production env example should
only contain non-secret defaults.

## Admin Commands

Run admin commands from the server app directory on the host. They inspect
metadata only; encrypted cloud-save package contents stay opaque.

```sh
cd /opt/allofme/app/server
pnpm admin stats --data-dir /opt/allofme/cloud-saves
pnpm admin accounts list --data-dir /opt/allofme/cloud-saves
pnpm admin account show ACCOUNT_ID --data-dir /opt/allofme/cloud-saves
pnpm admin device revoke DEVICE_ID --data-dir /opt/allofme/cloud-saves --yes
pnpm admin account delete ACCOUNT_ID --data-dir /opt/allofme/cloud-saves --yes
```

Use `--json` when copying output into another tool. Destructive commands require
`--yes` and should be preceded by a production backup.

## GitHub Workflows

- `Flutter CI`: analyzes and tests the Flutter app.
- `Server CI`: installs server dependencies, typechecks, tests, builds, and
  builds the Docker image.
- `Server Image`: publishes the production image to GitHub Container Registry
  after `Server CI` succeeds on `main`, when run manually, or when a
  `server-v*` tag is pushed.
- `Server Deploy`: manual production deploy. It can run the production backup
  script, update the Compose image tag, restart the API service, and smoke test
  the public health endpoint.

## Manual Deploy Workflow

`Server Deploy` requires these GitHub repository secrets:

- `ALLOFME_DEPLOY_HOST`: Vultr host name or IP, for example
  `api.allofmeapp.com`.
- `ALLOFME_DEPLOY_USER`: SSH user on the Vultr host.
- `ALLOFME_DEPLOY_SSH_KEY`: private SSH key for that user.

Create a deploy SSH key from a local machine:

```sh
ssh-keygen -t ed25519 -f ~/.ssh/allofme_github_deploy -C github-actions-allofme
```

Install the public key for the Vultr deploy user:

```sh
ssh-copy-id -i ~/.ssh/allofme_github_deploy.pub DEPLOY_USER@api.allofmeapp.com
```

Verify the key can connect:

```sh
ssh -i ~/.ssh/allofme_github_deploy DEPLOY_USER@api.allofmeapp.com 'hostname'
```

Add repository secrets in GitHub:

1. Open the repository on GitHub.
2. Go to `Settings`.
3. Go to `Secrets and variables`.
4. Go to `Actions`.
5. Add `ALLOFME_DEPLOY_HOST`.
6. Add `ALLOFME_DEPLOY_USER`.
7. Add `ALLOFME_DEPLOY_SSH_KEY` using the full contents of
   `~/.ssh/allofme_github_deploy`.

The deploy user must be able to run these commands through `sudo` without an
interactive password prompt:

- `/usr/local/sbin/allofme-backup`
- `docker compose`
- `sed`
- `tee`

If the workflow deploys as `root`, no extra sudoers file is needed. If it
deploys as a non-root user, configure passwordless sudo for the deploy commands
before running the workflow.

To deploy from GitHub:

1. Open the repository on GitHub.
2. Go to `Actions`.
3. Choose `Server Deploy`.
4. Click `Run workflow`.
5. Choose the image tag. Use `latest` for the normal path.
6. Leave `run_backup` enabled unless there is a specific reason to skip it.
7. Start the workflow and wait for the smoke test to pass.

## Production Compose

The production Compose service must keep port `3000` bound to localhost:

```yaml
ports:
  - "127.0.0.1:${ALLOFME_SERVER_PORT:-3000}:3000"
```

The data volume must point at the persistent host directory:

```yaml
volumes:
  - ${ALLOFME_DATA_DIR:-/opt/allofme/cloud-saves}:/app/data/cloud-saves
```

The data directory must be writable by the container's `node` user:

```sh
sudo mkdir -p /opt/allofme/cloud-saves
sudo chown -R 1000:1000 /opt/allofme/cloud-saves
```

## Abuse Controls

The API has two layers of abuse protection:

- Body-size cap through `CLOUD_SAVE_MAX_PAYLOAD_BYTES`.
- In-memory rate limiting through `@fastify/rate-limit`.

Current production defaults:

```sh
TRUST_PROXY=true
CLOUD_SAVE_MAX_PAYLOAD_BYTES=10485760
DEVICE_LINK_CODE_TTL_MS=600000
RATE_LIMIT_MAX=300
RATE_LIMIT_TIME_WINDOW_MS=60000
RATE_LIMIT_REGISTRATION_MAX=5
RATE_LIMIT_REGISTRATION_TIME_WINDOW_MS=900000
RATE_LIMIT_SAVE_MAX=30
RATE_LIMIT_SAVE_TIME_WINDOW_MS=60000
```

Rate-limit behavior:

- Global `/v1` limit: `300` requests per client IP per minute.
- `POST /v1/devices/register`: `5` registrations per client IP per 15 minutes.
- `POST /v1/devices/link`: `5` link-code redemptions per client IP per 15 minutes.
- `POST /v1/saves`: `30` uploads per bearer token per minute.
- `GET /healthz`: not rate limited.

The rate-limit store is in memory and is appropriate for the current single
container. If production moves to multiple API containers, switch rate limiting
to a shared store such as Redis so limits apply across all replicas.

Clients that exceed a limit receive HTTP `429 Too Many Requests` with
rate-limit headers, including `retry-after`.

## Deploy Or Restart

On the Vultr host:

```sh
cd /opt/allofme/app
sudo docker compose --env-file .env.production pull
sudo docker compose --env-file .env.production up -d
sudo docker compose --env-file .env.production ps
```

Check logs:

```sh
sudo docker logs --tail=120 allofme-server
sudo journalctl -u caddy --no-pager -n 120
```

## Smoke Tests

From the Vultr host:

```sh
curl http://127.0.0.1:3000/healthz
curl https://api.allofmeapp.com/healthz
```

From a local machine:

```sh
curl https://api.allofmeapp.com/healthz
```

Expected response:

```json
{"ok":true}
```

Confirm public port `3000` is closed from a local machine:

```sh
curl -v --connect-timeout 5 http://api.allofmeapp.com:3000/healthz
nc -vz -w 5 api.allofmeapp.com 3000
```

Good results are `connection refused`, `timed out`, or similar failures.
Getting `{"ok":true}` from public port `3000` means the Docker port binding or
firewall needs to be fixed.

On the Vultr host, this should show `127.0.0.1:3000`, not `0.0.0.0:3000`:

```sh
sudo ss -tulpn | grep :3000
```

## Caddy

Expected Caddyfile shape:

```caddyfile
api.allofmeapp.com {
	reverse_proxy 127.0.0.1:3000
}
```

After editing Caddy:

```sh
sudo caddy fmt --overwrite /etc/caddy/Caddyfile
sudo caddy validate --config /etc/caddy/Caddyfile
sudo systemctl reload caddy
sudo systemctl status caddy --no-pager
```

If TLS fails, check that DNS points to the Vultr IP and inbound ports `80` and
`443` are open.

## Firewall

Inbound rules:

- `22/tcp`: SSH, preferably restricted to the admin IP
- `80/tcp`: HTTP, anywhere
- `443/tcp`: HTTPS, anywhere

Do not open inbound `3000/tcp` publicly. Leave outbound traffic allowed so the
host can pull GHCR images, install updates, renew TLS certificates, and upload
backups.

## Backups

The important data is `/opt/allofme/cloud-saves`. It contains SQLite database
files and encrypted package JSON files.

Run a manual backup:

```sh
sudo /usr/local/sbin/allofme-backup
```

Check local backup archives:

```sh
ls -lh /opt/allofme/backups
```

Check remote Object Storage backups:

```sh
sudo bash -lc '
set -euo pipefail
source /etc/allofme-backup.env
aws --profile "${S3_PROFILE:-allofme-vultr}" \
  --region "${S3_REGION:-us-east-1}" \
  --endpoint-url "$S3_ENDPOINT" \
  s3 ls "s3://$S3_BUCKET/cloud-saves/"
'
```

Expected backup env values:

```sh
S3_PROFILE=allofme-vultr
S3_ENDPOINT=https://sjc1.vultrobjects.com
S3_BUCKET=allofme-backup-data
S3_REGION=us-east-1
```

The secret access key belongs in `/root/.aws/credentials`, not in the repo.

The scheduled backup should be in `/etc/cron.d/allofme-backup`. Check its log:

```sh
sudo tail -120 /var/log/allofme-backup.log
```

## Backup Restore Drill

Download a backup archive from Object Storage:

```sh
sudo bash -lc '
set -euo pipefail
source /etc/allofme-backup.env
aws --profile "${S3_PROFILE:-allofme-vultr}" \
  --region "${S3_REGION:-us-east-1}" \
  --endpoint-url "$S3_ENDPOINT" \
  s3 cp "s3://$S3_BUCKET/cloud-saves/BACKUP_FILE.tgz" /tmp/
'
```

Inspect the archive before restoring:

```sh
tar -tzf /tmp/BACKUP_FILE.tgz | head
```

Restore only during a maintenance window:

```sh
cd /opt/allofme/app
sudo docker compose --env-file .env.production stop api
sudo cp -a /opt/allofme/cloud-saves "/opt/allofme/cloud-saves.before-restore.$(date -u +%Y%m%dT%H%M%SZ)"
sudo tar -C /opt/allofme -xzf /tmp/BACKUP_FILE.tgz
sudo chown -R 1000:1000 /opt/allofme/cloud-saves
sudo docker compose --env-file .env.production up -d api
curl https://api.allofmeapp.com/healthz
```

## Common Failure Checks

Container is restarting:

```sh
sudo docker logs --tail=120 allofme-server
sudo chown -R 1000:1000 /opt/allofme/cloud-saves
```

Caddy cannot get a certificate:

```sh
dig +short api.allofmeapp.com
sudo ss -tulpn | grep -E ':80|:443'
sudo journalctl -u caddy --no-pager -n 120
```

Backups do not upload:

```sh
sudo cat /etc/allofme-backup.env
sudo aws --profile allofme-vultr \
  --region us-east-1 \
  --endpoint-url https://sjc1.vultrobjects.com \
  s3api head-bucket \
  --bucket allofme-backup-data
```

Redact access keys before sharing logs or config.
