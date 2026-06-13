# All Of Me

All Of Me is an original local-first Flutter prototype for plural system tracking. It draws broad inspiration from the workflow category served by apps like Simply Plural, while using its own product direction, UI, code, data model, and assets.

All Of Me is not affiliated with, endorsed by, or derived from Simply Plural.

The core paradigm is inverted from client-server:

- The client owns the canonical data.
- The app works without an account or network connection.
- Sync is optional replication to another device or server.
- Server availability must never block local tracking.

## Workspace

- Flutter app: `lib/`
- Tests: `test/`
- Product milestones: `docs/milestones.md`
- Architecture notes: `docs/local-first-architecture.md`
- iOS release packaging: `docs/release-packaging.md`

## Run

```sh
flutter test
flutter run
```

## Current Scope

The app now has a first pass at Milestone 1:

- Local system profile editing.
- First-run setup that starts with a blank local system, with optional demo data or backup import.
- Local member create/edit/archive/restore with color swatches.
- Optional member profile images chosen from the device photo library, stored as local app files on device builds.
- Local groups for organizing members, including group filters and member assignment.
- Fronting toggles for one or more active members.
- Local insights for fronting time, switching frequency, member trends, group trends, and recent sessions.
- Refreshable sample insights data from first-run setup, Insights, and Settings & Privacy for simulator/demo testing.
- Timeline entries for front changes and notes, with soft delete and restore through Recently Deleted.
- On-device persistence through a local SQLite/Drift database on device builds, with migration from the earlier app-support JSON file and original `shared_preferences` store.
- Readable JSON backup export to a local backup file where supported, with platform share-sheet and copy/paste fallback.
- Backup import from a native JSON file picker or pasted JSON.
- Settings & Privacy hub for privacy policy, storage details, backup/restore, app lock, demo data, and local reset.
- Clear all local data action for removing app-owned members, groups, sessions, notes, backups, and profile images on the device.
- Main-screen app lock using Face ID or the device passcode where supported.
