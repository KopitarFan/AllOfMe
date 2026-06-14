# All Of Me Privacy Policy

Last updated: June 14, 2026

All Of Me is a local-first app for private system tracking. The current build is
designed so the device is the source of truth: core app data is stored on the
device, and the app does not require an account, server connection, or network
sync.

## Summary

- All Of Me does not currently collect app data on a server.
- All Of Me does not use third-party advertising.
- All Of Me does not track users across apps or websites.
- All Of Me does not currently include analytics.
- Backups, imports, profile images, demo data, and app lock are explicit user
  actions.
- Optional sync is not included in the current build. If sync is added later,
  this policy will be updated before that feature is released.

## Data Stored By The App

All Of Me stores the information a user enters or chooses inside the app. This
may include:

- System profile name and description.
- Member names, roles, notes, colors, groups, archive state, and profile images.
- Group names, descriptions, colors, and archive state.
- Fronting state, fronting sessions, timeline entries, notes, and recently
  deleted items.
- Local settings, including whether app lock is enabled.
- Local backups created by the user.

On iOS and other device builds, this data is stored in app-owned local storage,
including a local SQLite database and app-owned image/backup files. On web, the
current build uses browser-local storage appropriate for the browser platform.

## Data Sent To The Developer

The current build does not automatically send system, member, group, fronting,
timeline, backup, image, or app-lock data to the developer.

The developer may receive information only if a user intentionally sends it, for
example by contacting support, attaching screenshots, submitting TestFlight
feedback, opening a GitHub issue, or sharing a backup file. Users should avoid
sending sensitive app data in support requests unless they intentionally choose
to share it.

## Photos And Profile Images

All Of Me may request access to the photo library so a user can choose a member
profile image. Chosen images are copied into app-owned local storage for use by
the app and may be included in a user-created backup for portability.

All Of Me does not upload selected profile images to a server in the current
build.

## App Lock And Biometrics

All Of Me may use Face ID or the device passcode to unlock local app data when
app lock is enabled. Biometric authentication is handled by the operating system.
All Of Me does not receive or store Face ID biometric data.

## Backups, Imports, And Sharing

Users can export a readable JSON backup and import that backup later. Exported
backup files are controlled by the user after export. If a user shares a backup
through the system share sheet, saves it to another location, or sends it to
someone else, that copy is outside All Of Me's app-owned storage.

To delete exported backups, users must delete those files from wherever they
saved or shared them.

## Third Parties

The current app build does not include third-party advertising, third-party
analytics, or a third-party sync service.

The app uses platform services such as the operating system photo picker/share
sheet, local authentication, local file storage, and TestFlight when installed as
a beta. Those services are governed by the platform provider's terms and privacy
practices.

If a user visits the project website, GitHub repository, support page, or issue
tracker, those web services may process standard web request or account
information according to their own policies.

## Retention And Deletion

Local app data remains on the device until the user deletes it, clears local app
data inside All Of Me, removes specific records, deletes exported backups, or
uninstalls the app.

All Of Me includes a clear-local-data action that removes app-owned members,
groups, sessions, notes, backups, and profile images from the current device.
Recently deleted items can be restored or removed according to the controls
available in the app.

Because the current build does not store app data on a developer server, the
developer cannot remotely delete data that remains only on a user's device or in
backup files the user has exported.

## Children's Privacy

All Of Me is not designed for the Kids category and is not directed specifically
to children. The app does not knowingly collect children's personal information
on a developer server in the current build.

## Security

All Of Me is designed to keep app data local by default and can hide local app
data behind device authentication when app lock is enabled. Users should also
protect their device passcode, backups, and any files they export from the app.

No storage or security system can be guaranteed to be perfect, especially once a
user exports or shares backup files outside the app.

## Changes To This Policy

This policy may be updated as All Of Me changes. Material changes, especially
changes involving sync, accounts, analytics, tracking, or server-side storage,
should be reflected in this document before those features are released.

## Contact

For support, see [Support](support.md).

