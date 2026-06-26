# All Of Me Support

All Of Me is currently preparing for TestFlight. The current build is local-first
and stores core app data on the user's device by default. Optional Cloud Save can
store encrypted manual restore points on All Of Me Cloud or another compatible
server when the user chooses to connect it.

## Get Help

For TestFlight builds:

- Use TestFlight's built-in feedback feature when reporting beta issues.
- In the app, open Settings & privacy and choose Beta feedback to copy a
  report template with helpful diagnostic details.
- If you have access to the GitHub repository, open an issue:
  <https://github.com/KopitarFan/AllOfMe/issues>

Before external TestFlight testing or App Store release, add a public support
email or contact form here so testers and customers can reach support without
needing GitHub access.

## Helpful Details To Include

When reporting an issue, include:

- Device model and iOS version.
- App version and build number.
- What you were trying to do.
- What happened instead.
- Whether the issue happens every time or only sometimes.
- For Cloud Save issues, the connected server name or URL and any support
  reference shown in the app.
- Screenshots or screen recordings if they do not reveal sensitive information.

Do not send backup files, screenshots, member details, timeline notes, or other
sensitive app data unless you intentionally choose to share that information for
support. Do not send your Cloud Save recovery key.

## Local Data, Backups, And Cloud Save

All Of Me is local-first. The current device is the source of truth unless the
user explicitly imports a backup or restores a Cloud Save restore point.

Cloud Save is optional encrypted backup and restore. It is not a traditional
login account, and it is not live multi-device sync.

To move to a new device with Cloud Save:

- Keep access to an existing connected device.
- Create a one-time device link code on that connected device.
- Enter the link code on the new device.
- Restore the latest Cloud Save package using the recovery key used when saving.

If all connected devices are unavailable, the recovery key is lost, or no backup
exists, support may not be able to restore app data. All Of Me Cloud is not
designed to decrypt encrypted Cloud Save packages.

To protect local data:

- Create backups before deleting app data or switching devices.
- Store exported backups somewhere you trust.
- Treat exported JSON backup files as sensitive.
- Treat Cloud Save recovery keys as sensitive and store them somewhere safe.
- Delete old backups from locations where you no longer want them stored.

Disconnecting Cloud Save on a device clears that device's saved Cloud Save
session and token. It does not automatically delete encrypted restore points
already stored on the configured server. To request deletion of All Of Me Cloud
data, contact support and include the relevant Cloud Save account/device details
or support reference if available. For self-hosted or third-party servers, contact
that server operator.

## Privacy

Read the privacy policy:
[All Of Me Privacy Policy](privacy-policy.md)
