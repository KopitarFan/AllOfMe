# Local-First Architecture

## Principle

The client is the source of truth. Every core workflow must work locally before sync exists, while offline, and after a sync provider outage.

## Data Ownership

- Local database: canonical user data for the current device.
- Local operation log: ordered changes produced by this device.
- Sync service: optional replica transport and backup target.
- Remote account: optional identity for syncing, never required for local use.

## Initial Domain Model

- SystemProfile: display name, preferences, and privacy settings.
- Member: name, color, role, notes, group assignments, archived state, and timestamps.
- MemberGroup: local organization buckets for member lists and filters.
- FrontSession: active or historical fronting interval for one or more members.
- TimelineEntry: durable event record for front changes and notes.
- InsightSummary: derived on-device analytics for session duration, switches, and group/member trends.
- Backup: exported snapshot with app version and schema version.
- SyncPeer: optional server or device replica metadata.

## Storage Direction

Milestone 1 should introduce a real local database. A good default path is SQLite through Drift because it is mature in Flutter, migration-friendly, testable, and works across mobile and web with the right setup. The app should keep storage behind repository interfaces so sync can attach later without rewriting screens.

The first Milestone 1 pass used `shared_preferences` behind an `AppStore` interface. Milestone 2 keeps that interface and now uses SQLite through Drift on device builds, with automatic migration from the intermediate app-support JSON file and the old preferences snapshot. Fresh installs create an empty local snapshot and show first-run setup for starting fresh, importing a backup, or deliberately loading demo data. Member profile images are stored in a sibling `member-images/` folder and hydrated into memory for display and portable JSON backups. Fronting analytics are derived locally from `FrontSession` rows, so charts do not require sync or a server-side reporting layer. Backups can be shared through the platform share sheet or copied as JSON; restores can use a native JSON file picker or pasted JSON. Settings & Privacy centralizes privacy policy text, storage diagnostics, backup/restore, app lock, Recently Deleted recovery, demo data, and current-device reset. Web keeps the browser-safe preferences store until the Drift web worker/WASM setup is introduced deliberately.

## Sync Direction

Sync should replicate changes, not replace the local database.

- Generate stable IDs on the client.
- Write local changes before attempting upload.
- Track pending outbound operations.
- Pull remote operations into a local merge step.
- Resolve conflicts in domain-specific code.
- Surface sync status as health information, not as permission to use the app.

## First Conflict Rules

- Fronting events are append-only and keep their original timestamps.
- Member profile edits use field-level last-writer-wins until richer merge UI exists.
- Archive/delete actions are reversible through Recently Deleted during the local data safety milestone.
- Imports create a backup checkpoint before applying restored data.

## Privacy Defaults

- No account required.
- No network calls in local-only mode.
- No sharing by default.
- No demo members are created unless the user chooses demo data.
- Backups are explicit user actions.
- App lock is opt-in and uses local device authentication.
- Sync status and pending changes are visible when sync is enabled.
