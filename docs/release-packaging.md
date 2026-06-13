# Release Packaging

This is the iOS/TestFlight packaging checklist for All Of Me.

## Current Package Identity

- App display name: All Of Me
- Bundle identifier: `com.allofme.allofme`
- Version: `0.1.0`
- Build: `1`
- Minimum iOS deployment target: iOS 13.0
- Privacy posture: local-first, no tracking, no collected data declared by the app target

If the Apple Developer account requires a different bundle identifier, update
`PRODUCT_BUNDLE_IDENTIFIER` in `ios/Runner.xcodeproj/project.pbxproj` and the
matching App Store Connect record before archiving.

## Automated Packaging

Regenerate branded iOS assets:

```sh
scripts/generate_release_assets.py
```

Run the release quality gates and create a release iOS app without code signing:

```sh
scripts/package_ios_release.sh
```

Create a signed IPA after Xcode signing is configured:

```sh
CODESIGN=1 scripts/package_ios_release.sh
```

Override version/build for a new upload:

```sh
BUILD_NAME=0.1.1 BUILD_NUMBER=2 scripts/package_ios_release.sh
```

## Manual Xcode/App Store Steps

- Select the Apple Developer team for the Runner target.
- Confirm the bundle identifier exists in Certificates, Identifiers & Profiles.
- Archive from Xcode or run the signed IPA command above.
- Upload to App Store Connect.
- Add TestFlight internal testers first.
- After smoke testing, add external testers if desired.

## App Store Connect Draft

- Name: All Of Me
- Subtitle: Local-first system tracking
- Category: Lifestyle
- SKU: `allofme-ios`
- Age rating notes: no user-generated public sharing, no account system, no network sync in this build
- Privacy summary: data is stored locally on the device; backups, imports, profile images, and app lock are explicit user actions

## TestFlight Smoke Test

Latest local readiness report:
`docs/ios-readiness-pass-2026-06-13.md`

- Fresh install shows first-run setup with Start fresh, Use demo data, and Import backup.
- Start fresh creates an empty local system without demo members.
- Use demo data loads sample members and a fronting timeline.
- Add/edit/archive/restore a member.
- Add/edit/archive/restore a group.
- Toggle fronting and verify Insights updates.
- Add and soft-delete a timeline note, then restore it from Recently Deleted.
- Add a member profile image from Photos.
- Export a backup, import it, and confirm member identity/order survives.
- Enable app lock, background the app, and confirm Face ID/passcode unlock.
- Clear all local data and confirm the app returns to an empty local system.

## Assets

The source icon lives at `assets/brand/allofme-icon.png`.
The generated icon set lives in `ios/Runner/Assets.xcassets/AppIcon.appiconset`.
The launch image lives in `ios/Runner/Assets.xcassets/LaunchImage.imageset`.

The asset generator resizes that source image for iPhone, iPad, marketing, web,
Android, and launch-image slots. Re-run it after visual direction changes so all
required sizes stay in sync.
