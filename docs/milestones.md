# All Of Me Milestones

All Of Me is a local-first Flutter app for plural system tracking. The client owns the canonical data. Server sync is optional, explicit, and treated as replication rather than the primary source of truth.

## Milestone 0 - Workspace Foundations

Status: started

- Flutter app scaffolded for Android, iOS, and web.
- Product direction captured in docs.
- Starter local-first home screen replaces the stock Flutter counter app.
- Baseline widget tests cover the first home screen interactions.

## Milestone 1 - Local Core MVP

Status: first pass

Goal: make the app useful with no account, no network, and no server.

- Create and edit a local system profile. Done in first pass.
- Add first-run setup for starting fresh, importing a backup, or explicitly loading demo data. Done in release-polish pass.
- Create, edit, archive, color-code, and assign profile images to members. Done in first pass.
- Create and edit local groups for organizing members. Done in first pass.
- Mark one or more members as fronting. Done in first pass.
- Record fronting events in a local timeline. Done in first pass.
- Track fronting sessions for local analytics. Done in first pass with member/group insights and recent sessions.
- Add short notes to members and timeline entries. Done in first pass.
- Persist data on-device across app restarts. Done in first pass with `shared_preferences`; upgraded in Milestone 2 to app-support JSON and then a SQLite/Drift database on device builds.
- Export a readable local backup file. Done in the Milestone 2 data-safety pass with local backup files, platform share-sheet export, and copy fallback.

Acceptance criteria:

- A new user can install the app, create members, record front changes, close the app, reopen it, and see the same data.
- A user can organize members into local groups and filter the member list without needing sync.
- The app never blocks core workflows on login or network state.
- Fresh installs start with user-owned blank data rather than silently seeding demo members.
- The local data format has a schema version; SQLite/Drift schema version 3 stores fronting sessions and recoverable timeline deletes on device builds.

## Milestone 2 - Local Data Safety

Goal: make local ownership trustworthy before introducing sync.

- Add import from the local backup format. Done in the Milestone 2 data-safety pass with native JSON file import and pasted JSON fallback.
- Move device builds off key-value storage and into an explicit app data file. Done; device builds now use SQLite/Drift and migrate from the previous app-support JSON file.
- Store member profile images as local app files instead of embedding them in the main snapshot. Done in first Milestone 2 pass for device builds; backups still embed image data for portability.
- Add app-level lock support where the platform allows it. Done in the Milestone 2 data-safety pass with Face ID/device passcode unlock on iOS.
- Add Settings & Privacy as the release-facing home for privacy policy, storage diagnostics, backup/restore, app lock, demo data, and local reset. Done in release-hardening pass.
- Add clear all local data. Done with app-store rows, app-owned backup files, and profile-image files removed from the current device.
- Add soft delete and restore for members, groups, and timeline entries. Done with Recently Deleted in Settings & Privacy.
- Add database migrations and migration tests. Drift schema 3 adds recoverable timeline deletion, and the schema 1 fixture migration test now verifies migration to the current schema.
- Add a diagnostic screen for storage location, database version, and last backup. Settings & Privacy shows storage location, schema, last save, backups location, and record counts.

Acceptance criteria:

- Users can recover from accidental deletion.
- Backup and restore round trips preserve member identities and timeline order. First pass covered by JSON import, shareable backup export, and local backup file tests.
- Users can clear all local app data on the current device.
- When app lock is enabled, local system data stays hidden until device authentication succeeds.
- Schema migrations are tested with fixture data before each future schema-version bump.

## Milestone 3 - Optional Sync Foundation

Goal: sync between devices without demoting the client.

- Introduce stable device IDs and record IDs.
- Store local changes as an operation log.
- Add a sync adapter boundary behind an interface.
- Implement a mock sync target for tests.
- Define conflict rules for member edits, fronting events, and deletes.

Acceptance criteria:

- The app works exactly the same with sync disabled.
- Sync can be enabled or disabled without data loss.
- Conflicts resolve deterministically and leave an audit trail.

## Milestone 4 - Private Server Sync

Goal: add a server as an optional relay and backup target.

- Add account creation only for users who opt into sync.
- Upload encrypted client data or encrypted operations where practical.
- Download remote operations into the local store.
- Show sync health, last sync time, and pending outbound changes.
- Add manual sync and background sync controls.

Acceptance criteria:

- The local device can continue recording changes while offline.
- Reconnecting syncs queued changes without overwriting newer local work.
- Server failure does not block local usage.

## Milestone 5 - Sharing and Collaboration

Goal: support consent-based sharing after local and sync foundations are solid.

- Share selected member profiles or front status with trusted people.
- Add per-contact visibility controls.
- Add revocation and local audit history.
- Add notifications for opted-in status changes.

Acceptance criteria:

- Sharing is opt-in per audience and per data category.
- Revoking access prevents future updates from being shared.
- Private local notes remain local unless explicitly shared.
