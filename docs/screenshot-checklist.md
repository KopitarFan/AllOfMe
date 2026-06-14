# All Of Me Screenshot Checklist

Last updated: June 14, 2026

This checklist is for App Store Connect screenshots and TestFlight/App Review
visual QA. Use demo data only. Do not capture real member names, notes, backups,
or other personal data.

Apple screenshot notes checked June 14, 2026:

- Upload one to ten screenshots in `.png`, `.jpg`, or `.jpeg` format.
- If the same UI works across device sizes and localizations, the highest
  required resolution screenshots can scale down to smaller sizes.
- For iPhone, capture the 6.9-inch display set first.
- This Flutter target currently supports both iPhone and iPad
  (`TARGETED_DEVICE_FAMILY = 1,2`), so iPad screenshots are required unless the
  target is changed to iPhone-only before submission.

## Required Capture Sets

### iPhone

Primary target: 6.9-inch display.

Accepted portrait sizes:

- `1260 x 2736`
- `1290 x 2796`
- `1320 x 2868`

Accepted landscape sizes:

- `2736 x 1260`
- `2796 x 1290`
- `2868 x 1320`

Recommended device/simulator:

- iPhone 17 Pro Max
- iPhone 16 Pro Max
- iPhone 15 Pro Max
- iPhone 15 Plus
- iPhone 14 Pro Max

The current iPhone 17 simulator is useful for planning and UI QA, but it is a
6.3-inch device. Use a 6.9-inch simulator or real device for final App Store
screenshots.

### iPad

Primary target: 13-inch display.

Accepted portrait sizes:

- `2064 x 2752`
- `2048 x 2732`

Accepted landscape sizes:

- `2752 x 2064`
- `2732 x 2048`

Recommended device/simulator:

- iPad Pro 13-inch
- iPad Air 13-inch

If we decide the first iOS release should be iPhone-only, update the Xcode target
before submission and revisit this checklist.

## Shot List

Capture six to eight polished screenshots for the first submission. App Store
Connect accepts up to ten, but a focused set will usually read better.

### 1. First-Run Setup

Purpose: show the local-first setup choices.

State:

- Fresh install or cleared local data.
- First-run setup dialog visible.
- Buttons visible: Start fresh, Use demo data, Import backup.

Caption idea:

```text
Start fresh, import a backup, or try demo data.
```

Checklist:

- No overflow on smaller text.
- App name reads `All Of Me`.
- Local/no-account framing is visible or implied.

### 2. Member Overview

Purpose: show the main daily workspace.

State:

- Demo data loaded.
- Member list visible.
- At least one member fronting.
- Groups row visible if possible.

Caption idea:

```text
Track members, groups, and who is fronting.
```

Checklist:

- Demo member names only.
- Group chips are visible.
- Local status chip does not distract from the main content.

### 3. Member Profile

Purpose: show profile images and member details.

State:

- Edit or detail view for one demo member.
- Profile image assigned.
- Groups and notes visible.

Caption idea:

```text
Add details and profile images for each member.
```

Checklist:

- Use generated/demo imagery only.
- No personal notes.
- Form controls are not cut off.

### 4. Groups

Purpose: show organization by groups.

State:

- Group view/filter visible.
- Multiple groups present.
- A selected group displays matching members.

Caption idea:

```text
Organize your system with local groups.
```

Checklist:

- Selected state is clear without relying on color alone.
- No labels are truncated awkwardly.

### 5. Insights

Purpose: show analytics value.

State:

- Demo insights/sample sessions loaded.
- Insights screen visible with fronting time, switching, trends, or recent
  sessions.

Caption idea:

```text
Review local insights without a server.
```

Checklist:

- Charts/data are legible.
- Avoid implying medical or diagnostic claims.
- Use only demo-generated sessions.

### 6. Timeline And Recently Deleted

Purpose: show recovery and local history.

State:

- Timeline note or fronting event visible.
- Recently Deleted visible, or a restore action visible.

Caption idea:

```text
Keep history recoverable with Recently Deleted.
```

Checklist:

- No sensitive timeline note text.
- Restore/delete language is clear.

### 7. Settings And Privacy

Purpose: show trust, local storage, backup/import, and data controls.

State:

- Settings & Privacy screen open.
- Privacy policy notice and storage/backup actions visible.

Caption idea:

```text
Export, import, and manage local data intentionally.
```

Checklist:

- No bottom overflow.
- Storage path is not too visually dominant.
- Backup/import actions are visible.

### 8. App Lock

Purpose: show optional device authentication.

State:

- App lock enabled.
- Locked screen visible.

Caption idea:

```text
Optional app lock with Face ID or device passcode.
```

Checklist:

- Lock screen hides member/system data.
- No biometric prompt overlay is needed for App Store screenshots.

## Capture Preparation

Before capturing final screenshots:

- Install the final signed/TestFlight candidate or a build from the same commit.
- Clear local data.
- Load demo data through first-run setup.
- Refresh sample insights data if charts look sparse.
- Assign only demo/generated profile images.
- Set Dynamic Type to default size for primary screenshots.
- Set appearance to light mode, since the app currently ships a light theme.
- Use a clean simulator/device with no personal notifications.
- Confirm app version/build matches the submission.

Optional QA passes before final screenshots:

- Large text pass for overflow.
- iPad layout pass.
- Dark mode pass only if we later claim dark-mode support.
- Accessibility contrast pass for charts and chips.

## Capture Commands

Example simulator screenshot command:

```sh
mkdir -p screenshots/app-store/iphone-6.9
xcrun simctl io booted screenshot screenshots/app-store/iphone-6.9/01-first-run.png
```

Check dimensions:

```sh
sips -g pixelWidth -g pixelHeight screenshots/app-store/iphone-6.9/01-first-run.png
```

Suggested file names:

```text
01-first-run.png
02-member-overview.png
03-member-profile.png
04-groups.png
05-insights.png
06-recently-deleted.png
07-settings-privacy.png
08-app-lock.png
```

Do not commit captured screenshots unless we intentionally want to keep a public
marketing/screenshot source set in the repository. App Store screenshots may
contain UI state and should be reviewed before publishing anywhere.

## Final Review

For each screenshot:

- Uses only demo data.
- No real names, notes, backups, file paths, or support details.
- Text is readable at App Store thumbnail size.
- No visible simulator debug banners or Flutter debug labels.
- No clipped text, overflow warnings, or loading spinners.
- No competitor names or clone language.
- No medical, therapy, diagnosis, crisis, or treatment claims.
- Caption, if added later, matches the exact current feature set.
- Screenshot dimensions match an accepted App Store size.

