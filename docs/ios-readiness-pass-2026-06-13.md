# iOS Readiness Pass - 2026-06-13

## Result

All Of Me is ready for an internal TestFlight candidate after Apple Developer
signing and App Store Connect setup are configured.

This pass did not create a signed IPA because signing credentials and the App
Store Connect record are manual/account-specific.

## Automated Gates

- `scripts/package_ios_release.sh`: passed
- `dart format --set-exit-if-changed lib test`: passed, 0 changed
- `flutter analyze`: passed, no issues found
- `flutter test`: passed, 41 tests
- `flutter build ios --release --no-codesign --build-name 0.1.0 --build-number 1`: passed
- Release app output: `build/ios/iphoneos/Runner.app`
- Release app size: 24.3 MB

## Bundle Metadata

- Display name: `All Of Me`
- Bundle identifier: `com.allofme.allofme`
- Version: `0.1.0`
- Build: `1`
- Encryption declaration: `ITSAppUsesNonExemptEncryption = false`
- Privacy manifest: present and valid
- Photo library usage string: present
- Face ID usage string: present
- iOS deployment target: 13.0

## Simulator Smoke

- Simulator: iPhone 17, iOS 26.5
- Device ID: `B3F44EB8-2ABE-4DDF-9C6D-3EA67161777D`
- `flutter run --no-resident`: passed
- Direct simulator launch: passed
- Launched bundle: `com.allofme.allofme`

The existing simulator install was not wiped during this pass. Fresh install,
first-run setup, demo data, app lock, import/export, recovery, and local reset
paths are covered by the automated widget/storage tests.

## Manual Apple Steps Remaining

- Select the Apple Developer team for the Runner target.
- Confirm `com.allofme.allofme` exists in Certificates, Identifiers & Profiles.
- Create the App Store Connect app record for `All Of Me`.
- Add privacy nutrition answers using the local-first/no-tracking posture.
- Add support URL and privacy policy URL.
- Capture App Store screenshots.
- Run `CODESIGN=1 scripts/package_ios_release.sh` or archive from Xcode.
- Upload the signed IPA/archive to App Store Connect.
- Add internal TestFlight testers and complete a device smoke test.

## Go / No-Go Notes

- Go for internal TestFlight once signing and App Store Connect metadata are in
  place.
- Not ready for external testers until at least one signed build has been
  installed on a real device and the App Store screenshots/privacy URLs are
  finalized.
