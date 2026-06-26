# All Of Me Privacy Policy

Last updated: June 26, 2026

All Of Me is a local-first app for private system tracking. The current build is
designed so the current device is the source of truth: core app data is stored
on the device, and core workflows do not require an account, server connection,
or network access. Users can optionally connect Cloud Save to store encrypted
manual restore points on All Of Me Cloud or another compatible server.

## Summary

- Core app data is stored locally on the device by default.
- Cloud Save is optional and user-initiated. It stores encrypted backup packages
  and operational metadata on the configured server.
- Cloud Save packages are encrypted on the device before upload. The recovery key
  is not sent to All Of Me Cloud.
- All Of Me does not use third-party advertising.
- All Of Me does not track users across apps or websites.
- All Of Me does not currently include analytics.
- Backups, imports, Cloud Save, profile images, demo data, and app lock are
  explicit user actions.

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
- Cloud Save connection settings and access credentials if the user connects a
  device to Cloud Save.

On iOS and other device builds, this data is stored in app-owned local storage,
including a local SQLite database and app-owned image/backup files. On web, the
current build uses browser-local storage appropriate for the browser platform.

## Optional Cloud Save

Cloud Save is a manual backup and restore feature. It is not live sync, and it
does not make the server the source of truth. A user must connect Cloud Save and
choose to save or restore.

When a user connects Cloud Save to All Of Me Cloud, the developer-operated server
may process and store:

- Encrypted Cloud Save packages containing backup data.
- Cloud Save metadata such as save ID, creation time, app name and version,
  snapshot schema version, device label, payload byte count, and payload
  checksum.
- Random Cloud Save account and device identifiers, hashed device access tokens,
  link-code metadata, creation timestamps, and last-used timestamps.
- Standard service logs such as request time, request path, status code, IP
  address, request ID, and error ID.

The recovery key used to encrypt and decrypt a Cloud Save package is entered on
the device and is not sent to All Of Me Cloud. The server is not designed to
decrypt Cloud Save package contents.

Users may also configure another compatible server. If a user connects All Of Me
to a third-party or self-hosted server, that server operator's privacy and
security practices apply to data sent to that server.

## Data Sent To The Developer

In local-only use, All Of Me does not automatically send system, member, group,
fronting, timeline, backup, image, or app-lock data to the developer.

If a user connects All Of Me Cloud, the Cloud Save data described above is sent
to the developer-operated Cloud Save service when the user checks Cloud Save
status, saves, restores, registers a device, creates a device link code, or links
another device.

The developer may receive information only if a user intentionally sends it, for
example by contacting support, attaching screenshots, submitting TestFlight
feedback, opening a GitHub issue, or sharing a backup file. Users should avoid
sending sensitive app data in support requests unless they intentionally choose
to share it.

## Photos And Profile Images

All Of Me may request access to the photo library so a user can choose a member
profile image. Chosen images are copied into app-owned local storage for use by
the app and may be included in a user-created backup for portability. If the user
creates a Cloud Save restore point, profile images included in the backup are
part of the encrypted Cloud Save package.

## App Lock And Biometrics

All Of Me may use Face ID or the device passcode to unlock local app data when
app lock is enabled. Biometric authentication is handled by the operating system.
All Of Me does not receive or store Face ID biometric data.

## Backups, Imports, Cloud Save, And Sharing

Users can export a readable JSON backup and import that backup later. Exported
backup files are controlled by the user after export. If a user shares a backup
through the system share sheet, saves it to another location, or sends it to
someone else, that copy is outside All Of Me's app-owned storage.

To delete exported backups, users must delete those files from wherever they
saved or shared them.

Cloud Save restore points are stored on the configured server. They are encrypted
before upload, but users should still treat Cloud Save access credentials and
recovery keys as sensitive.

## Third Parties

The current app build does not include third-party advertising, third-party
analytics, or a bundled third-party sync service.

The app uses platform services such as the operating system photo picker/share
sheet, local authentication, local file storage, and TestFlight when installed as
a beta. Those services are governed by the platform provider's terms and privacy
practices.

If a user visits the project website, GitHub repository, support page, or issue
tracker, those web services may process standard web request or account
information according to their own policies.

If a user configures a self-hosted or third-party Cloud Save server, that server
is outside the developer-operated All Of Me Cloud service.

## Retention And Deletion

Local app data remains on the device until the user deletes it, clears local app
data inside All Of Me, removes specific records, deletes exported backups, or
uninstalls the app.

All Of Me includes a clear-local-data action that removes app-owned members,
groups, sessions, notes, backups, and profile images from the current device.
Recently deleted items can be restored or removed according to the controls
available in the app.

Disconnecting Cloud Save removes the saved Cloud Save session and access token
from the current device. It does not automatically delete encrypted restore
points already stored on the configured server.

All Of Me Cloud may retain encrypted Cloud Save packages and metadata until they
are removed by service retention limits or deleted by support. Users can request
deletion of All Of Me Cloud data through the support process. The developer
cannot remotely delete data that remains only on a user's device, in exported
backup files, or on a self-hosted or third-party server.

## Children's Privacy

All Of Me is not designed for the Kids category and is not directed specifically
to children. The developer does not knowingly collect children's personal
information. Users should not send children's personal information through
support requests or Cloud Save.

## Security

All Of Me is designed to keep app data local by default and can hide local app
data behind device authentication when app lock is enabled. Users should also
protect their device passcode, backups, Cloud Save recovery key, and any files
they export from the app.

Cloud Save packages are encrypted on the device before upload. If the recovery
key is lost, the server is not designed to recover or decrypt the backup.

No storage or security system can be guaranteed to be perfect, especially once a
user exports files, shares backup files, connects a server, or stores recovery
keys outside the app.

## Changes To This Policy

This policy may be updated as All Of Me changes. Material changes, especially
changes involving accounts, analytics, tracking, live sync, sharing, or new
server-side storage, should be reflected in this document before those features
are released.

## Contact

For support, see [Support](support.md).
