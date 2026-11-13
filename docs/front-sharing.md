# Front sharing and AOM Companion

This is an opt-in extension to the Flutter app plus a separate SwiftUI iPhone
receiver. Core local tracking remains independent of network availability.
There is no email/password account flow: the sender creates a private device
identity, and receivers redeem a scoped, one-time invitation.

## User flow

1. In All Of Me, open Settings & privacy → Front sharing.
2. Turn on sharing, choose Invite someone, and enter a recipient label.
3. In AOM Companion, enter the one-time invitation within ten minutes.
4. Allow notifications on the receiver.
5. Change the front in All Of Me. After a two-second debounce, the latest front
   names and timestamp publish; the receiver receives a generic alert.
6. Open the companion to fetch authoritative current status. Multiple fronting
   members and an empty front are supported.
7. Pause sharing to hide the server status, or revoke individual recipients.
   The companion can also disconnect itself.

Invitations use copy/paste in this first version; there is no QR scanner.
There is no per-change private toggle; pause sharing before a private change.
Changing sharing settings cancels outstanding invitations.

## Server setup

The feature is disabled by default. Deploy the existing server with:

- `FRONT_SHARING_ENABLED=true`
- `APNS_KEY_ID`: the signing key ID from Apple Developer
- `APNS_TEAM_ID`: your Apple Developer team ID
- `APNS_BUNDLE_ID=com.allofme.companion`, or the final receiver bundle ID
- `APNS_KEY_PATH`: an absolute path to a mounted APNs .p8 key readable by the server

All four APNs settings must be supplied together. Without APNs settings, status
sharing works but push delivery is not configured; the sender shows that state.
Never put the .p8 key in the repository or either app.
The key must be authorized for the receiver's bundle ID and environments.
Production Docker deployments need an additional Compose override, for example:

```yaml
services:
  api:
    environment:
      FRONT_SHARING_ENABLED: "true"
      APNS_KEY_ID: ${APNS_KEY_ID}
      APNS_TEAM_ID: ${APNS_TEAM_ID}
      APNS_BUNDLE_ID: com.allofme.companion
      APNS_KEY_PATH: /run/secrets/apns-key.p8
    volumes:
      - /opt/allofme/secrets/apns-key.p8:/run/secrets/apns-key.p8:ro
```

Keep that override and credentials on the server. Run it together with the
existing production Compose file. The feature uses `front-sharing.sqlite`
beside the existing Cloud Save database, in the same persistent data directory.
Back up this database along with the existing auth database. Run one API process
against this database in v1. Receiver access also checks that the sender's account still exists.
Deleting an account through the admin CLI immediately invalidates receiver reads;
the running sharing worker removes orphaned sharing rows on its next pass.
If the API is stopped, that cleanup waits until it runs again.

## Client configuration

Both clients default to `https://api.allofmeapp.com/`.
For a staging sender use
`--dart-define=ALLOFME_FRONT_SHARING_BASE_URL=https://your-staging-host/`.
For a staging receiver change `SHARING_BASE_URL` in
`companion/project.yml` and regenerate the project. HTTPS is required.
Sender credentials are separate from Cloud Save credentials and partitioned by
server URL. This does not enable or upload Cloud Save backups.

## TestFlight

1. Open `companion/AllOfMeCompanion.xcodeproj` in Xcode. The project is checked in;
   regenerate it with `xcodegen generate` from `companion/` after changing YAML.
2. Select your signing team and confirm the final bundle identifier.
3. Enable Push Notifications for that App ID in Apple Developer.
4. Create the corresponding app record in App Store Connect.
5. Archive the Release scheme for a generic iOS device; upload with Organizer.
6. Add the desired TestFlight testers. External testers may require Beta App
   Review. Keep Apple account roles restricted to the access each person needs.
7. Build/upload the modified Flutter app using its existing release process.
8. Install both builds, pair on real phones, and test a front change while the
   receiver is locked and the app is closed.

Debug registers sandbox device tokens; Release/TestFlight registers production
tokens. The APNs provider uses the device's registered environment. Focus,
notification settings, connectivity, and APNs delivery can affect alert timing.
Foreground refresh works without push permission.

No signed archive, App Store Connect record, backend deployment, or live APNs
delivery was performed as part of the initial implementation.

## Reliability and privacy

Only front names, update timestamp, and an opaque event UUID leave the sender.
Notes, full profiles, pictures, history, and backup ciphertext are excluded.
Names on this service are **not end-to-end encrypted**; they are readable by the
server operator. The privacy policy and sharing screen disclose this.

Sender credentials and the latest pending update use secure storage; receiver
credentials use the iOS Keychain. Invitations and bearer credentials are stored
as hashes on the server. Receiver credentials cannot use sender or backup APIs.
Endpoints return `Cache-Control: no-store`.

A successful local save precedes publishing. The sender queues the latest update,
coalesces rapid toggles, and retries failures every thirty seconds while active,
and at launch/resume. iOS can suspend the sender; offline publication may wait
until it is reopened. A failed pause stays pending and retries before any further
status publication. A pause is only confirmed once the server accepts it.

The durable server outbox retries APNs failures with capped exponential backoff.
Each recipient has only the latest job; superseded front alerts are coalesced.
APNs payloads contain a generic message and no member names. A successful APNs
request means accepted by Apple, not confirmed receipt by the person.
The receiver always fetches status on open and displays last changed / checked
times. Revocation cannot erase details already seen on a recipient's device.

## Verification

- Server: `pnpm typecheck`, `pnpm test`, `pnpm build`.
- Flutter: `dart format lib test`, `flutter analyze`, `flutter test`.
- Native: `xcodebuild -project companion/AllOfMeCompanion.xcodeproj -scheme AllOfMeCompanion -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO build`.
- Real phones: confirm initial pairing, multi-front changes, offline sender retry,
  failed-pause recovery, locked-screen notification, denied notification permission,
  expired/reused invitations, recipient revocation, receiver disconnection, and
  persistence after server restart.

The initial workspace had no Flutter SDK; Flutter formatting, analysis, and tests
must run before merging. The native simulator SDK build and server checks are
recorded in the implementation handoff. Real-device/APNs checks remain necessary.

## Initial implementation checks

- Server TypeScript checking and production compilation passed.
- All 44 server tests passed, including nine new sharing tests.
- The Swift receiver compiled for the simulator and as an unsigned iPhone Release
  build. The final built Info.plist was checked for the configured sharing URL.
- The sandboxed build required the compiler-only flag
  `OTHER_SWIFT_FLAGS='-Xfrontend -disable-sandbox'` because nested compiler plugin
  sandboxes could not start. This is a local build-environment workaround, not
  a required project setting.
- The installed CoreSimulator service could not run the current simulator
  runtime, so no interactive simulator or real-device session was verified.
- Flutter SDK tooling is absent; the three new Dart service tests, existing
  Flutter tests, formatting, and analysis have not run.
- GitHub branch creation returned HTTP 403 (integration lacks write access).
  The changes were not pushed and no pull request was created.
