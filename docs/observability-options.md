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

### Better Stack

Use for: quickest all-in-one 1.0 monitoring.

Current useful facts from pricing:

- Free personal tier includes 10 monitors/heartbeats and 1 status page.
- Free tier includes email/Slack alerts.
- Free tier includes small log, trace, and metrics allowances.
- Paid incident-management and telemetry plans are available later.

Fit for All Of Me:

- Good first choice for external `/healthz` checks, TLS checks, backup heartbeat,
  and a simple public/private status page.
- Can receive logs later, but we should avoid shipping sensitive request bodies.
- Adds a third-party processor for operational logs if log shipping is enabled.

Source: <https://betterstack.com/pricing>

### Healthchecks.io

Use for: very focused backup/cron monitoring.

Current useful facts from pricing:

- Free Hobbyist plan monitors 20 jobs.
- Paid Business plan monitors 100 jobs and adds email support plus SMS/WhatsApp
  and phone-call credits.

Fit for All Of Me:

- Excellent for `allofme-backup` success/failure heartbeats.
- Pair it with a separate uptime monitor if we do not use Better Stack.
- Very low complexity.

Source: <https://healthchecks.io/pricing/>

### Cronitor

Use for: cron, uptime, heartbeat, and simple status-page monitoring.

Current useful facts from pricing:

- Free Hacker plan includes 5 monitors, email/Slack alerts, and a basic status
  page.
- Business pricing starts from per-monitor and per-user usage.

Fit for All Of Me:

- Similar role to Better Stack/Healthchecks.
- Strong if we want one product for uptime plus backup jobs, with less log focus.

Source: <https://cronitor.io/pricing>

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

For 1.0, use one external hosted monitor, not a full observability stack.

Recommended first setup:

- Better Stack Free for:
  - `https://api.allofmeapp.com/healthz`
  - TLS expiry
  - backup heartbeat
  - optional status page
- A small host-side script or cron output that records:
  - disk usage
  - newest backup age
  - `docker compose ps`
  - `node dist/admin-cli.js stats --json`

If Better Stack feels too broad, use Healthchecks.io for backup heartbeat and a
separate simple uptime monitor. The important bit is that at least one monitor is
external to the VPS.

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

The next small implementation slice should be:

1. Add an observability section to the production runbook.
2. Add a backup heartbeat URL placeholder to the production backup env file docs.
3. Add a host-side `allofme-ops-summary` command or documented shell snippet that
   prints disk usage, backup age, Docker status, and admin stats.
4. Configure one external uptime check for `/healthz`.

That gives us useful alerting without changing app behavior or adding mobile
telemetry.
