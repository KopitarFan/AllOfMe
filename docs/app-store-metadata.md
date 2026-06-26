# All Of Me App Store Metadata Draft

Last updated: June 26, 2026

This draft is for App Store Connect and TestFlight setup. It is written for the
current local-first iOS build: no required account, no required server
connection, no tracking, no advertising, no third-party analytics, explicit local
import/export, and optional encrypted Cloud Save backup/restore.

Apple field notes checked June 26, 2026:

- App name: 2-30 characters.
- Subtitle: up to 30 characters.
- Promotional text: up to 170 characters.
- Description: up to 4000 characters, plain text only.
- Keywords: up to 100 bytes; do not duplicate app/company name or include names
  of other apps or companies.
- Support URL must lead to actual contact information users can use for app
  issues, feedback, and feature requests.
- Age rating is determined by the App Store Connect questionnaire and can vary
  by region/OS version.

Sources:

- Apple: <https://developer.apple.com/app-store/product-page/>
- Apple: <https://developer.apple.com/app-store/app-privacy-details/>

## App Information

- Name: `All Of Me`
- Bundle ID: `com.allofme.allofme`
- SKU: `allofme-ios`
- Primary language: `English (U.S.)`
- Primary category: `Lifestyle`
- Secondary category: none for first submission
- Content rights: app contains only original or licensed content
- License agreement: Apple's Standard EULA
- Pricing: free for initial TestFlight; App Store pricing TBD

## URLs

Use these once GitHub Pages is enabled from `main` / `docs`.

- Privacy Policy URL: `https://kopitarfan.github.io/AllOfMe/privacy-policy.html`
- Support URL: `https://kopitarfan.github.io/AllOfMe/support.html`
- Marketing URL: optional; leave blank for first TestFlight

Before external TestFlight or App Store release, update `docs/support.md` with a
public support email or contact form. GitHub Issues alone may not be enough for
customers who do not have GitHub access.

## Product Page Copy

### Subtitle

```text
Local-first system tracking
```

### Promotional Text

```text
Private system tracking built around local data ownership, optional encrypted backups, member organization, fronting history, and on-device insights.
```

### Short Description

Use this for informal notes, repository descriptions, or screenshot planning.
App Store Connect does not have a separate "short description" field for iOS.

```text
Private, local-first tracking for members, groups, fronting history, encrypted backups, and insights.
```

### Full Description

```text
All Of Me is a private, local-first space for system tracking.

Create members, organize them into groups, track who is fronting, add timeline notes, and review local insights without needing an account or a network connection.

The app is designed around device-owned data. Your local device is the source of truth, and core workflows continue to work offline. Export, import, and optional Cloud Save are explicit actions, so you stay in control of backups and portability.

Features in this release:

- First-run setup for starting fresh, importing a backup, or loading demo data.
- Local system profile, member, and group management.
- Member profile images from the device photo library.
- Fronting toggles for one or more active members.
- Fronting sessions, timeline notes, and local insights.
- Backup export and import using readable JSON.
- Optional encrypted Cloud Save backup and restore.
- Recently Deleted recovery for archived members, archived groups, and deleted timeline entries.
- Optional app lock with Face ID or device passcode.
- Clear all local data for the current device.

All Of Me does not include required accounts, live sync, collaboration, advertising, or analytics in this build.
```

### Keywords

Draft under Apple's 100-byte limit. Do not add competitor app names.

```text
plural,system,journal,fronting,members,groups,tracking,privacy,backup,local
```

Approximate byte count: 75.

## What's New

Not required for the first App Store version. Use this for later updates.

```text
Initial release.
```

## TestFlight Beta Information

### Beta App Description

```text
All Of Me is a local-first system tracking app. This beta focuses on private on-device setup, member and group management, fronting history, local insights, backup import/export, optional encrypted Cloud Save, and optional app lock.
```

### What To Test

```text
Please test first-run setup, starting fresh, loading demo data, importing a backup, adding/editing members, adding groups, choosing member profile images, toggling fronting, reviewing insights, exporting/importing backups, connecting Cloud Save, saving/restoring Cloud Save, creating/redeeming a device link code, restoring recently deleted items, enabling app lock, and clearing local data.
```

### Beta Review Notes

```text
This build does not require an account, network connection, subscription, or demo login for core app workflows. To review populated screens, use the first-run "Use demo data" option. App data is stored locally on the device by default. Optional Cloud Save can be tested from Settings & Privacy using the default All Of Me Cloud server; it stores encrypted manual restore points and requires a recovery key to restore. Live sync, sharing, collaboration, advertising, and analytics are not included in this build.
```

## App Review Information

Fill in the real contact details in App Store Connect.

- Contact name: TBD
- Contact email: TBD
- Contact phone: TBD
- Sign-in required: no
- Demo account: not applicable

Review notes:

```text
All Of Me is local-first and does not require login. The reviewer can start fresh or select "Use demo data" during first-run setup to see members, groups, timeline, and insights. Optional Cloud Save can be tested from Settings & Privacy with the default All Of Me Cloud server; no demo account is required. App lock can be enabled from the main-screen lock button or Settings & Privacy and uses Face ID/device passcode where supported.
```

## App Privacy Draft

Suggested App Privacy posture for the current build. Confirm final answers in
App Store Connect against Apple's current definitions before submission.

Apple's current guidance says data can still need to be declared when collection
varies by opt-in feature. Because optional Cloud Save stores encrypted restore
points and related metadata on All Of Me Cloud when enabled, do not use "Data Not
Collected" for the release that includes Cloud Save.

- Tracking: no
- Data used to track: none
- Third-party advertising: none
- Developer advertising or marketing: none
- Third-party analytics: none
- Developer analytics: none

Recommended collected-data entries:

- User Content / Other User Content:
  - Data: encrypted Cloud Save restore-point packages. Packages can contain the
    user's system data and profile images included in the app backup.
  - Linked to user: yes, through the Cloud Save account/device identifiers used
    to retrieve the restore point.
  - Purpose: App Functionality.
  - Tracking: no.
- Identifiers / User ID:
  - Data: random Cloud Save account ID and save/device association metadata.
  - Linked to user: yes.
  - Purpose: App Functionality.
  - Tracking: no.
- Identifiers / Device ID:
  - Data: random Cloud Save device ID and hashed access-token association.
  - Linked to user: yes.
  - Purpose: App Functionality.
  - Tracking: no.
- Diagnostics / Other Diagnostic Data:
  - Data: request IDs, error IDs, request path/status/timing, IP-derived service
    logs, rate-limit events, and operational logs used to run and support Cloud
    Save.
  - Linked to user: treat as yes for the first release because these logs can be
    associated with a Cloud Save account/device during support.
  - Purpose: App Functionality.
  - Tracking: no.

Do not declare these unless the app changes:

- Contact Info: no account email, phone, address, or user name is required by the
  app.
- Location: no location permission or location feature is used by the app. If
  Apple classifies stored IP addresses as Coarse Location in App Store Connect,
  declare them for App Functionality and not tracking.
- Usage Data / Product Interaction: no product analytics SDK is included in the
  app.
- Crash Data or Performance Data from a mobile SDK: not included unless a mobile
  crash-reporting or performance SDK is added.

Server-only observability for All Of Me Cloud should stay limited to service
health, uptime, capacity, support references, abuse prevention, and backup/restore
operations. If mobile crash reporting, product analytics, session replay, or RUM
is added later, revisit this draft and the privacy policy before submitting an
app update.

Rationale:

- Core member, group, fronting, timeline, profile-image, backup, and app-lock
  data stays in app-owned local storage unless the user explicitly exports,
  shares, or uploads an encrypted Cloud Save restore point.
- Cloud Save is optional, but it is part of the app's current behavior. When
  enabled, the app sends encrypted backup packages and operational metadata to
  the configured server.
- All Of Me Cloud does not receive the recovery key and is not designed to
  decrypt package contents.
- TestFlight feedback, GitHub Issues, email, or support requests may send
  information only when the user intentionally provides it outside normal app
  operation.

Revisit before submission if any of these change:

- Required accounts are added.
- Live sync is added.
- Sharing or collaboration is added.
- Analytics, mobile crash reporting, performance monitoring, RUM, or session
  replay is added.
- Support is built into the app and sends data to a service.

## Age Rating Draft

Complete the questionnaire truthfully in App Store Connect.

Recommended answers for the current build:

- Objectionable content: none.
- Violence: none.
- Sexuality or nudity: none.
- Profanity or crude humor: none.
- Alcohol, tobacco, or drug references: none.
- Gambling, simulated gambling, contests, or loot boxes: none.
- Unrestricted web access: no.
- Messaging or chat: no.
- Advertising: no.
- Public user-generated content: no.
- Medical or treatment information: no.
- Health/wellness topics: choose carefully.

Rating expectation:

- If every content/capability answer is "none/no", Apple may assign 4+.
- If Apple treats system tracking as a health/wellness topic, the rating may be
  higher. Based on Apple's current age-rating definitions, health and wellness
  topics can fall under 9+.

Do not describe All Of Me as medical treatment, therapy, diagnosis, or crisis
support. The app is for private organization and tracking.

## Accessibility Nutrition Draft

Accessibility labels can be completed later, but current notes for review:

- VoiceOver: basic Material controls should expose labels; needs device review.
- Voice Control: likely usable for standard buttons/fields; needs device review.
- Larger Text: responsive layout has test coverage for phone-screen overflow;
  needs manual large-text screenshot pass.
- Dark Interface: app currently uses a light Material theme; dark mode is not a
  first-release claim.
- Differentiate Without Color Alone: colors are used with text/icons in core UI;
  verify charts/insights manually.
- Sufficient Contrast: needs manual screenshot pass before public release.
- Reduced Motion: no major custom animations currently; verify manually.
- Captions/Audio Descriptions: not applicable; no video/audio content.

## Screenshot Plan

The full screenshot checklist lives in `docs/screenshot-checklist.md`.

High-priority shots:

- First-run setup.
- Member overview with demo data.
- Member profile with profile image.
- Group organization/filtering.
- Insights dashboard.
- Recently Deleted or timeline recovery.
- Settings & Privacy.
- App lock screen.

Avoid screenshots containing real personal/member data. Use demo data only.
