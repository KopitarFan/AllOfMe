# All Of Me App Store Metadata Draft

Last updated: June 14, 2026

This draft is for App Store Connect and TestFlight setup. It is written for the
current local-first iOS build: no account system, no server sync, no tracking,
no advertising, no third-party analytics, and explicit local import/export.

Apple field notes checked June 14, 2026:

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
Private system tracking built around local data ownership, optional backups, member organization, fronting history, and on-device insights.
```

### Short Description

Use this for informal notes, repository descriptions, or screenshot planning.
App Store Connect does not have a separate "short description" field for iOS.

```text
Private, local-first tracking for members, groups, fronting history, backups, and insights.
```

### Full Description

```text
All Of Me is a private, local-first space for system tracking.

Create members, organize them into groups, track who is fronting, add timeline notes, and review local insights without needing an account or a network connection.

The app is designed around device-owned data. Your local device is the source of truth, and core workflows continue to work offline. Export and import are explicit actions, so you stay in control of backups and portability.

Features in this release:

- First-run setup for starting fresh, importing a backup, or loading demo data.
- Local system profile, member, and group management.
- Member profile images from the device photo library.
- Fronting toggles for one or more active members.
- Fronting sessions, timeline notes, and local insights.
- Backup export and import using readable JSON.
- Recently Deleted recovery for archived members, archived groups, and deleted timeline entries.
- Optional app lock with Face ID or device passcode.
- Clear all local data for the current device.

All Of Me does not include sync, accounts, collaboration, advertising, or analytics in this build.
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
All Of Me is a local-first system tracking app. This beta focuses on private on-device setup, member and group management, fronting history, local insights, backup import/export, and optional app lock.
```

### What To Test

```text
Please test first-run setup, starting fresh, loading demo data, importing a backup, adding/editing members, adding groups, choosing member profile images, toggling fronting, reviewing insights, exporting/importing backups, restoring recently deleted items, enabling app lock, and clearing local data.
```

### Beta Review Notes

```text
This build does not require an account, network connection, subscription, or demo login. To review populated screens, use the first-run "Use demo data" option. App data is stored locally on the device. Sync, sharing, collaboration, advertising, and analytics are not included in this build.
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
All Of Me is local-first and does not require login. The reviewer can start fresh or select "Use demo data" during first-run setup to see members, groups, timeline, and insights. App lock can be enabled from the main-screen lock button or Settings & Privacy and uses Face ID/device passcode where supported.
```

## Privacy Nutrition Draft

Suggested App Privacy answer for the current build:

- Tracking: no
- Data linked to the user: none collected by the app developer
- Data not linked to the user: none collected by the app developer
- Data used to track: none
- Third-party advertising: none
- Third-party analytics: none

Rationale:

- Member, group, fronting, timeline, profile-image, backup, and app-lock data
  stay in app-owned local storage unless the user explicitly exports or shares
  it.
- The app does not currently send this data to a developer server.
- TestFlight feedback, GitHub Issues, email, or support requests may send
  information only when the user intentionally provides it outside normal app
  operation.

Revisit before submission if any of these change:

- Sync is added.
- Accounts are added.
- Analytics or crash reporting is added.
- Support is built into the app and sends data to a service.
- Backups are uploaded to any server.

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

Capture iPhone screenshots after final signed build is available:

- First-run setup.
- Empty local system after "Start fresh".
- Member list with demo data.
- Member detail/edit form with profile image.
- Group organization/filtering.
- Insights dashboard.
- Settings & Privacy.
- Recently Deleted.
- App lock screen.

Avoid screenshots containing real personal/member data. Use demo data only.
