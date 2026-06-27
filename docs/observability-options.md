# Observability Options

Last checked: June 26, 2026

This note covers practical observability choices for the All Of Me Cloud Save
service. The goal is early warning for real operational problems without turning
the 1.0 release into an infrastructure project.

All Of Me remains local-first. Observability should focus on the optional Cloud
Save service: uptime, backups, disk growth, error references, restore health, and
capacity signals.

## Current Baseline

The production runbook already includes:

- External API health endpoint: `https://api.allofmeapp.com/healthz`
- Cronitor external monitoring for API health, TLS expiry, and backup heartbeat.
- Docker and Caddy logs on the host.
- Structured API `requestId` and `errorId` values for support lookup.
- Admin stats for accounts, devices, saves, payload bytes, package-file bytes,
  latest save time, and link-code counts.
- Local backup archives and remote Object Storage backups.

That is enough for manual support, but not enough for quiet confidence. The
missing piece is alerting before a user reports a problem.

## What To Monitor First

For 1.0, monitor these:

- `GET /healthz` from outside the VPS.
- TLS certificate validity for `api.allofmeapp.com`.
- Daily backup job completion.
- Backup age: alert if the newest successful backup is older than expected.
- Disk usage for `/opt/allofme`.
- Container health/restarts.
- Admin stats trend: accounts, saves, payload bytes, package-file bytes.
- 5xx responses and support-reference errors.
- Rate-limit spikes, especially registration and save endpoints.

Capacity tripwires:

- Disk over 70%: watch.
- Disk over 85%: clean up, expand disk, or reduce retention.
- Backup duration doubles from normal: investigate.
- Payload storage over 50-100 GB: start planning object-storage-primary package
  storage.
- Cloud Save users over 1,000 active accounts: review metrics weekly.
- Cloud Save users over 10,000 active accounts: plan Postgres/object storage and
  stateless API hosting.

## Tool Options

### Cronitor

Use for: selected 1.0 monitor for cron, uptime, heartbeat, TLS checks, and a
simple status page.

Current useful facts from pricing:

- Free Hacker plan includes 5 monitors, email/Slack alerts, and a basic status
  page.
- Business pricing starts from per-monitor and per-user usage.

Fit for All Of Me:

- Chosen for 1.0 because one service can cover API health checks, response-body
  assertions, TLS expiry, and backup job heartbeats.
- Good fit for checking `GET /healthz` from outside the VPS with status and body
  assertions.
- Keeps the first monitoring setup small and avoids mobile telemetry.

Source: <https://cronitor.io/pricing>

### Healthchecks.io

Use for: very focused backup/cron monitoring.

Current useful facts from pricing:

- Free Hobbyist plan monitors 20 jobs.
- Paid Business plan monitors 100 jobs and adds email support plus SMS/WhatsApp
  and phone-call credits.

Fit for All Of Me:

- Excellent for `allofme-backup` success/failure heartbeats.
- Pair it with a separate uptime monitor if Cronitor is replaced later.
- Very low complexity.

Source: <https://healthchecks.io/pricing/>

### Better Stack

Use for: broader hosted observability if we later want more than the Cronitor
checks.

Current useful facts from pricing:

- Free personal tier includes 10 monitors/heartbeats and 1 status page.
- Free tier includes email/Slack alerts.
- Free tier includes small log, trace, and metrics allowances.
- Paid incident-management and telemetry plans are available later.

Fit for All Of Me:

- Was considered for the first monitor, but the free tier no longer fit the
  response-body keyword check we wanted for `/healthz`.
- Can receive logs later, but we should avoid shipping sensitive request bodies.
- Adds a third-party processor for operational logs if log shipping is enabled.

Source: <https://betterstack.com/pricing>

### Sentry

Use for: application errors and stack traces.

Current useful facts from pricing:

- Free Developer plan is limited to one user and includes error monitoring,
  tracing, email alerts, and custom dashboards.
- Team and Business plans add unlimited users and broader limits/features.

Fit for All Of Me:

- Server-only Sentry could help group Fastify errors by stack trace.
- A Flutter/mobile Sentry SDK would change the App Store privacy story because
  crash/performance data would leave the device. Do not add mobile crash
  reporting before updating the privacy policy and App Store privacy answers.

Source: <https://sentry.io/pricing/>

### Grafana Cloud

Use for: more serious metrics/logs dashboards.

Current useful facts from pricing:

- Free logs tier includes 50 GB ingested per month and 14-day retention.
- Pro tier adds pay-as-you-go usage above the free tier and longer retention.

Fit for All Of Me:

- Good when we want real dashboards for disk, CPU, memory, request counts,
  latency, and payload growth.
- More setup than a basic uptime/cron service.
- Better as the second step, once Cloud Save usage proves we need trend analysis.

Source: <https://grafana.com/pricing/>

### Uptime Kuma

Use for: self-hosted uptime dashboard.

Current useful facts:

- Open-source, MIT-licensed, self-hosted monitoring app.
- Supports Docker and non-Docker deployment.

Fit for All Of Me:

- Nice internal dashboard, but not ideal as the only monitor if hosted on the
  same VPS as the API.
- If used, host it somewhere independent from the All Of Me API host.

Source: <https://github.com/louislam/uptime-kuma>

## Recommendation

For 1.0, use Cronitor as the external hosted monitor, not a full observability
stack.

Configured first setup:

- Cronitor for:
  - API health: `GET https://api.allofmeapp.com/healthz`
  - Health assertions: status `200` and body contains `{"ok":true}`
  - TLS expiry for `api.allofmeapp.com`
  - Daily backup heartbeat for `allofme-backup`
  - Optional status page
- A small host-side script or cron output that records:
  - disk usage
  - newest backup age
  - `docker compose ps`
  - `node dist/admin-cli.js stats --json`

If Cronitor becomes too limiting later, use Healthchecks.io for backup heartbeat
plus a separate uptime monitor, or move to Better Stack/Grafana Cloud when log or
metrics dashboards become worth the additional setup. The important bit is that
at least one monitor remains external to the VPS.

Defer for later:

- Log shipping.
- Tracing.
- Mobile crash reporting.
- RUM/session replay.
- Full Prometheus/Grafana or OpenTelemetry pipeline.

## Privacy Boundary

Server-side observability is acceptable for 1.0 if it stays focused on operating
All Of Me Cloud:

- uptime checks
- backup heartbeats
- disk/capacity alerts
- request IDs and error IDs
- API status codes and timing
- rate-limit/security signals

Do not send encrypted package contents, backup JSON, recovery keys, request
bodies, member names, notes, or profile images to observability vendors.

If a mobile SDK is added for crash reporting, performance monitoring, analytics,
RUM, or session replay, update:

- `docs/privacy-policy.md`
- `docs/app-store-metadata.md`
- App Store Connect privacy answers

before the app update is submitted.

## First Implementation Slice

Implemented in the repository:

- Production runbook observability setup.
- Backup heartbeat URL placeholders for `/etc/allofme-backup.env`.
- Host-side ops summary script at `scripts/allofme_ops_summary.sh`.

Production setup checklist:

1. Copy `scripts/allofme_ops_summary.sh` to
   `/usr/local/sbin/allofme-ops-summary` on the VPS.
2. Configure one Cronitor external uptime check for `/healthz`.
3. Configure one Cronitor TLS expiry check.
4. Configure one Cronitor backup heartbeat URL and add it to
   `/etc/allofme-backup.env`.
5. Update `/usr/local/sbin/allofme-backup` to ping the Cronitor heartbeat after
   success and optionally after failure.

That gives us useful alerting without changing app behavior or adding mobile
telemetry.
