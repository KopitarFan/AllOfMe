import 'package:all_of_me_demo/app_lock.dart';
import 'package:all_of_me_demo/cloud_save.dart';
import 'package:all_of_me_demo/main.dart';
import 'package:all_of_me_demo/models.dart';
import 'package:all_of_me_demo/storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('security settings round trip through snapshots', () {
    final snapshot = AppSnapshot.seeded().copyWith(
      security: const SecuritySettings(appLockEnabled: true),
    );
    final restored = AppSnapshot.fromJson(snapshot.toJson());

    expect(restored.security.appLockEnabled, isTrue);
  });

  test('member profile image data round trips through snapshots', () {
    const imageDataUri =
        'data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///ywAAAAAAQABAAACAUwAOw==';
    final snapshot = AppSnapshot.seeded();
    final member = snapshot.members.first.copyWith(
      profileImageDataUri: imageDataUri,
      profileImageScale: 1.8,
      profileImageOffsetX: -0.4,
      profileImageOffsetY: 0.25,
    );
    final restored = AppSnapshot.fromJson(
      snapshot.copyWith(members: [member]).toJson(),
    );

    expect(restored.members.single.profileImageDataUri, imageDataUri);
    expect(restored.members.single.profileImageScale, 1.8);
    expect(restored.members.single.profileImageOffsetX, -0.4);
    expect(restored.members.single.profileImageOffsetY, 0.25);
  });

  test('member groups round trip through snapshots', () {
    final snapshot = AppSnapshot.seeded();
    final group = snapshot.groups.first;
    final member = snapshot.members.first.copyWith(groupIds: [group.id]);
    final restored = AppSnapshot.fromJson(
      snapshot.copyWith(members: [member], groups: [group]).toJson(),
    );

    expect(restored.groups.single.name, group.name);
    expect(restored.members.single.groupIds, [group.id]);
  });

  test('front sessions round trip through snapshots', () {
    final snapshot = AppSnapshot.seeded();
    final member = snapshot.members[1];
    final session = FrontSession(
      id: 'session-sol',
      memberId: member.id,
      memberName: member.name,
      startedAt: DateTime(2026, 6, 11, 8, 30),
      endedAt: DateTime(2026, 6, 11, 9, 45),
    );
    final restored = AppSnapshot.fromJson(
      snapshot.copyWith(frontSessions: [session]).toJson(),
    );

    expect(restored.frontSessions.single.id, 'session-sol');
    expect(restored.frontSessions.single.memberName, 'Sol');
    expect(restored.frontSessions.single.endedAt, DateTime(2026, 6, 11, 9, 45));
  });

  test('timeline deletion state round trips through snapshots', () {
    final snapshot = AppSnapshot.seeded();
    final deletedAt = DateTime(2026, 6, 11, 10, 15);
    final deletedEntry = snapshot.timeline.single.copyWith(
      deletedAt: deletedAt,
    );
    final restored = AppSnapshot.fromJson(
      snapshot.copyWith(timeline: [deletedEntry]).toJson(),
    );

    expect(restored.activeTimeline, isEmpty);
    expect(restored.deletedTimeline.single.id, 'entry-seed-front');
    expect(restored.deletedTimeline.single.deletedAt, deletedAt);
  });

  test('legacy snapshots synthesize front sessions', () {
    final legacyJson = AppSnapshot.seeded().toJson();
    legacyJson.remove('frontSessions');

    final restored = AppSnapshot.fromJson(legacyJson);

    expect(restored.frontSessions, hasLength(1));
    expect(restored.frontSessions.single.memberName, 'Mara');
    expect(restored.frontSessions.single.isOpen, isTrue);
    expect(
      restored.frontSessions.single.startedAt,
      DateTime(2026, 5, 28, 9, 20),
    );
  });

  test('legacy snapshots missing groups receive starter groups', () {
    final legacyJson = AppSnapshot.seeded().toJson();
    legacyJson.remove('groups');
    legacyJson['members'] = AppSnapshot.seeded().members.map((member) {
      final memberJson = member.toJson();
      memberJson.remove('groupIds');
      return memberJson;
    }).toList();

    final restored = AppSnapshot.fromJson(legacyJson);

    expect(
      restored.groups.map((group) => group.name),
      containsAll(['Daily', 'Social', 'Rest']),
    );
    expect(
      restored.members
          .firstWhere((member) => member.id == 'member-mara')
          .groupIds,
      ['group-daily'],
    );
  });

  Future<void> pumpApp(
    WidgetTester tester, {
    AppSnapshot? snapshot,
    AppStore? store,
    CloudSaveAdapter? cloudSaveAdapter,
    CloudSavePayloadEncoder? cloudSavePayloadEncoder,
    CloudSavePayloadDecoder? cloudSavePayloadDecoder,
    AppAuthenticator? authenticator,
    Size size = const Size(1200, 900),
  }) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      AllOfMeApp(
        store: store ?? MemoryAppStore(snapshot ?? AppSnapshot.seeded()),
        cloudSaveAdapter: cloudSaveAdapter ?? MemoryCloudSaveAdapter(),
        cloudSavePayloadEncoder:
            cloudSavePayloadEncoder ?? const CloudSavePlaintextPayloadEncoder(),
        cloudSavePayloadDecoder: cloudSavePayloadDecoder,
        authenticator: authenticator ?? FakeAppAuthenticator(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapSettingsTile(WidgetTester tester, String label) async {
    final tile = find.ancestor(
      of: find.text(label),
      matching: find.byType(ListTile),
    );
    await tester.ensureVisible(tile);
    await tester.pumpAndSettle();
    await tester.tap(tile);
  }

  void expectMemberNotesInOrder(WidgetTester tester, List<String> notes) {
    var previousTop = -double.infinity;
    for (final note in notes) {
      final noteFinder = find.text(note);
      expect(noteFinder, findsOneWidget);
      final top = tester.getTopLeft(noteFinder).dy;
      expect(top, greaterThan(previousTop));
      previousTop = top;
    }
  }

  Future<void> tapCheckedMenuOption(WidgetTester tester, String label) async {
    final key = switch (label) {
      'A-Z' => 'member-sort-nameAscending',
      'Recently fronted' => 'member-sort-recentlyFronted',
      'Most used' => 'member-sort-mostUsed',
      _ => throw ArgumentError.value(label, 'label', 'Unknown sort option'),
    };
    await tester.tap(find.byKey(ValueKey(key)));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the local-first home screen', (tester) async {
    await pumpApp(tester);

    expect(find.text('All Of Me'), findsOneWidget);
    expect(find.text('Local-only system'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'View insights'), findsOneWidget);
    expect(find.text('Current front'), findsOneWidget);
    expect(find.text('Latest update'), findsOneWidget);
    expect(find.byTooltip('Switch to dark mode'), findsOneWidget);
    expect(find.byTooltip('App lock'), findsOneWidget);
    expect(find.text('Device is source of truth'), findsNothing);
    expect(find.text('Members'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Fronting'), findsWidgets);
    expect(find.text('Daily'), findsWidgets);
    expect(find.text('Social'), findsWidgets);
    expect(find.text('Rest'), findsWidgets);

    await tester.drag(find.byType(ListView), const Offset(0, -260));
    await tester.pumpAndSettle();

    expect(find.text('Timeline'), findsOneWidget);
  });

  testWidgets('shows settings and privacy details', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('Settings and privacy'));
    await tester.pumpAndSettle();

    expect(find.text('Settings & privacy'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.widgetWithText(SwitchListTile, 'Dark mode'), findsOneWidget);
    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('Sage'), findsOneWidget);
    expect(find.text('Graphite'), findsOneWidget);
    expect(find.text('Black'), findsOneWidget);
    expect(find.text('Bright blue'), findsOneWidget);
    expect(find.text('Bright green'), findsOneWidget);
    expect(find.text('Bright lime'), findsOneWidget);
    expect(find.text('Bright pink'), findsOneWidget);
    expect(find.text('Hot pink'), findsOneWidget);
    expect(find.text('Bright orange'), findsOneWidget);
    expect(find.text('Bright purple'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('theme-palette-preview-black')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('theme-palette-preview-hot_pink')),
      findsOneWidget,
    );
    final hotPinkGradient = tester.widget<Container>(
      find.byKey(const ValueKey('theme-palette-gradient-hot_pink')),
    );
    final hotPinkDecoration = hotPinkGradient.decoration as BoxDecoration;
    final hotPinkLinearGradient = hotPinkDecoration.gradient as LinearGradient;
    expect(
      hotPinkLinearGradient.colors,
      contains(AppThemePalette.hotPink.seedColor),
    );
    final blackGradient = tester.widget<Container>(
      find.byKey(const ValueKey('theme-palette-gradient-black')),
    );
    final blackDecoration = blackGradient.decoration as BoxDecoration;
    final blackLinearGradient = blackDecoration.gradient as LinearGradient;
    expect(blackLinearGradient.colors.last, AppThemePalette.black.darkScaffold);
    expect(find.text('Information'), findsOneWidget);
    expect(find.text('Privacy & storage'), findsOneWidget);
    expect(find.widgetWithText(SwitchListTile, 'App lock'), findsOneWidget);
    expect(find.text('Face ID available'), findsOneWidget);
    expect(find.text('Beta feedback'), findsOneWidget);
    expect(find.text('Export backup'), findsOneWidget);
    expect(find.text('Import file'), findsOneWidget);
    expect(find.text('Paste JSON'), findsOneWidget);
    expect(find.text('Cloud save preview'), findsOneWidget);
    expect(find.text('Save this device before restoring.'), findsOneWidget);
    expect(find.text('Save now'), findsOneWidget);
    expect(find.text('Restore cloud save'), findsOneWidget);
    expect(find.text('Recently deleted'), findsOneWidget);
    expect(find.text('Clear all local data'), findsOneWidget);
  });

  testWidgets('opens privacy and storage information on its own screen', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('Settings and privacy'));
    await tester.pumpAndSettle();
    await tapSettingsTile(tester, 'Privacy & storage');
    await tester.pumpAndSettle();

    expect(find.text('Privacy policy'), findsOneWidget);
    expect(find.text('On this device'), findsOneWidget);
    expect(find.text('Storage'), findsWidgets);
    expect(find.text('In-memory'), findsOneWidget);
    expect(find.text('Records'), findsOneWidget);
    expect(find.text('Schema'), findsWidgets);
    expect(find.text('Cloud save preview'), findsOneWidget);
    expect(find.text('Preview only'), findsOneWidget);
    expect(find.text('No cloud save yet'), findsOneWidget);
  });

  testWidgets('shows beta feedback support details', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('Settings and privacy'));
    await tester.pumpAndSettle();
    await tapSettingsTile(tester, 'Beta feedback');
    await tester.pumpAndSettle();

    expect(find.text('Beta feedback'), findsOneWidget);
    expect(find.text('Testing All Of Me'), findsOneWidget);
    expect(find.text('Support links'), findsOneWidget);
    expect(
      find.text('https://kopitarfan.github.io/AllOfMe/support.html'),
      findsOneWidget,
    );
    expect(find.widgetWithText(FilledButton, 'Copy template'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Share'), findsOneWidget);
  });

  testWidgets('toggles between light and dark mode', (tester) async {
    await pumpApp(tester);

    expect(find.byTooltip('Switch to dark mode'), findsOneWidget);

    await tester.tap(find.byTooltip('Switch to dark mode'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Switch to light mode'), findsOneWidget);

    await tester.tap(find.byTooltip('Settings and privacy'));
    await tester.pumpAndSettle();

    final darkModeSwitch = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Dark mode'),
    );
    expect(darkModeSwitch.value, isTrue);
  });

  testWidgets('selects a theme palette from settings', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('Settings and privacy'));
    await tester.pumpAndSettle();
    final hotPinkPalette = find.byKey(const ValueKey('theme-palette-hot_pink'));
    await tester.ensureVisible(hotPinkPalette);
    await tester.pumpAndSettle();
    await tester.tap(hotPinkPalette);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Settings and privacy'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Hot pink selected'), findsOneWidget);
  });

  testWidgets('first-run setup starts fresh from an empty store', (
    tester,
  ) async {
    final store = MemoryAppStore();
    await pumpApp(tester, store: store);

    expect(find.text('Welcome to All Of Me'), findsOneWidget);
    expect(find.text('Local first'), findsOneWidget);

    var saved = await store.load();
    expect(saved?.members, isEmpty);

    await tester.enterText(
      find.widgetWithText(TextField, 'System name'),
      'Moonlit House',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Start fresh'));
    await tester.pumpAndSettle();

    saved = await store.load();
    expect(saved?.profile.displayName, 'Moonlit House');
    expect(saved?.members, isEmpty);
    expect(find.text('Moonlit House'), findsOneWidget);
    expect(find.text('No members yet'), findsOneWidget);
  });

  testWidgets('first-run setup can load demo data explicitly', (tester) async {
    final store = MemoryAppStore();
    await pumpApp(tester, store: store);

    await tester.enterText(
      find.widgetWithText(TextField, 'System name'),
      'Demo System',
    );
    await tester.tap(find.text('Use demo data'));
    await tester.pumpAndSettle();

    final saved = await store.load();
    expect(saved?.profile.displayName, 'Demo System');
    expect(saved?.members.map((member) => member.name), contains('Mara'));
    expect(find.text('Mara'), findsWidgets);
  });

  testWidgets('shows local fronting insights', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('Insights'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Insights'),
      ),
      findsOneWidget,
    );
    expect(find.text('Front time'), findsOneWidget);
    expect(find.text('Member front time'), findsOneWidget);
    expect(find.text('Group front time'), findsOneWidget);
    expect(find.text('Recent sessions'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Sample data'), findsOneWidget);
    expect(find.text('Mara'), findsWidgets);
  });

  testWidgets('adds and clears sample insights data', (tester) async {
    final seeded = AppSnapshot.seeded();
    final store = MemoryAppStore(seeded);
    await pumpApp(tester, store: store);

    await tester.tap(find.byTooltip('Insights'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Sample data'));
    await tester.pumpAndSettle();

    final withSamples = await store.load();
    final sampleSessions = withSamples!.frontSessions
        .where((session) => session.id.startsWith('sample-insights-session-'))
        .toList();

    expect(sampleSessions.length, greaterThan(20));
    expect(
      sampleSessions.map((session) => session.memberName).toSet().length,
      greaterThan(1),
    );
    expect(find.widgetWithText(TextButton, 'Refresh samples'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Clear samples'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Clear samples'));
    await tester.pumpAndSettle();

    final withoutSamples = await store.load();
    expect(
      withoutSamples!.frontSessions.any(
        (session) => session.id.startsWith('sample-insights-session-'),
      ),
      isFalse,
    );
    expect(find.widgetWithText(TextButton, 'Sample data'), findsOneWidget);
  });

  testWidgets('settings app lock is reachable on phone screens', (
    tester,
  ) async {
    final store = LongPathMemoryAppStore(AppSnapshot.seeded());
    final authenticator = FakeAppAuthenticator();
    await pumpApp(
      tester,
      store: store,
      authenticator: authenticator,
      size: const Size(390, 640),
    );

    await tester.tap(find.byTooltip('Settings and privacy'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final appLockSwitch = find.widgetWithText(SwitchListTile, 'App lock');
    await tester.ensureVisible(appLockSwitch);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: appLockSwitch, matching: find.byType(Switch)),
    );
    await tester.pumpAndSettle();

    final saved = await store.load();
    expect(authenticator.authenticateCount, 1);
    expect(saved?.security.appLockEnabled, isTrue);
  });

  testWidgets('settings and privacy is usable on phone screens', (
    tester,
  ) async {
    await pumpApp(tester, size: const Size(390, 640));

    await tester.tap(find.byTooltip('Settings and privacy'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.text('Clear all local data'));
    await tester.pumpAndSettle();

    expect(find.text('Clear all local data'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('main app actions expose tooltip labels', (tester) async {
    await pumpApp(tester);

    expect(find.byTooltip('Edit system'), findsWidgets);
    expect(find.byTooltip('Insights'), findsOneWidget);
    expect(find.byTooltip('App lock'), findsOneWidget);
    expect(find.byTooltip('Settings and privacy'), findsOneWidget);
  });

  testWidgets('enables app lock after local authentication', (tester) async {
    final store = MemoryAppStore(AppSnapshot.seeded());
    final authenticator = FakeAppAuthenticator();
    await pumpApp(tester, store: store, authenticator: authenticator);

    await tester.tap(find.byTooltip('Settings and privacy'));
    await tester.pumpAndSettle();
    final appLockSwitch = find.widgetWithText(SwitchListTile, 'App lock');
    await tester.ensureVisible(appLockSwitch);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: appLockSwitch, matching: find.byType(Switch)),
    );
    await tester.pumpAndSettle();

    final saved = await store.load();
    expect(authenticator.authenticateCount, 1);
    expect(saved?.security.appLockEnabled, isTrue);
    expect(find.text('App lock enabled.'), findsOneWidget);
  });

  testWidgets('clears all local data from settings and privacy', (
    tester,
  ) async {
    final seeded = AppSnapshot.seeded();
    final store = MemoryAppStore(seeded);
    await pumpApp(tester, store: store);

    expect(find.text('Mara'), findsWidgets);

    await tester.tap(find.byTooltip('Settings and privacy'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Clear all local data'));
    await tapSettingsTile(tester, 'Clear all local data');
    await tester.pumpAndSettle();

    expect(find.text('Clear local data?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Clear data'));
    await tester.pumpAndSettle();

    final saved = await store.load();
    expect(saved?.members, isEmpty);
    expect(saved?.groups, isEmpty);
    expect(saved?.frontSessions, isEmpty);
    expect(find.text('Mara'), findsNothing);
    expect(find.text('Welcome to All Of Me'), findsOneWidget);
    expect(find.text('Local first'), findsOneWidget);
    expect(find.text('Local data cleared.'), findsOneWidget);
  });

  testWidgets('main app lock button enables app lock', (tester) async {
    final store = MemoryAppStore(AppSnapshot.seeded());
    final authenticator = FakeAppAuthenticator();
    await pumpApp(tester, store: store, authenticator: authenticator);

    await tester.tap(find.byTooltip('App lock'));
    await tester.pumpAndSettle();

    final saved = await store.load();
    expect(authenticator.authenticateCount, 1);
    expect(saved?.security.appLockEnabled, isTrue);
    expect(find.text('App lock enabled.'), findsOneWidget);
  });

  testWidgets('main app lock button locks when enabled', (tester) async {
    final lockedCapableSnapshot = AppSnapshot.seeded().copyWith(
      security: const SecuritySettings(appLockEnabled: true),
    );
    await pumpApp(tester, snapshot: lockedCapableSnapshot);
    expect(find.text('All Of Me is locked'), findsNothing);

    await tester.tap(find.byTooltip('App lock'));
    await tester.pumpAndSettle();

    expect(find.text('All Of Me is locked'), findsOneWidget);
    expect(find.text('Mara'), findsNothing);
  });

  testWidgets('locked app hides system data until unlocked', (tester) async {
    final lockedSnapshot = AppSnapshot.seeded().copyWith(
      security: const SecuritySettings(appLockEnabled: true),
    );
    final authenticator = FakeAppAuthenticator(shouldAuthenticate: false);
    await pumpApp(
      tester,
      snapshot: lockedSnapshot,
      authenticator: authenticator,
    );

    expect(find.text('All Of Me is locked'), findsOneWidget);
    expect(find.text('Mara'), findsNothing);

    authenticator.shouldAuthenticate = true;
    await tester.tap(find.widgetWithText(FilledButton, 'Unlock'));
    await tester.pumpAndSettle();

    expect(find.text('All Of Me is locked'), findsNothing);
    expect(find.text('Mara'), findsWidgets);
  });

  testWidgets('shows share action for backup export', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('Settings and privacy'));
    await tester.pumpAndSettle();
    await tapSettingsTile(tester, 'Export backup');
    await tester.pumpAndSettle();

    expect(find.text('Backup'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Share'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Copy'), findsOneWidget);
  });

  testWidgets('imports backup JSON from settings and privacy', (tester) async {
    final seeded = AppSnapshot.seeded();
    final restored = seeded.copyWith(
      profile: seeded.profile.copyWith(
        displayName: 'Restored System',
        updatedAt: DateTime(2026, 6, 8),
      ),
    );
    await pumpApp(tester, snapshot: seeded);

    await tester.tap(find.byTooltip('Settings and privacy'));
    await tester.pumpAndSettle();
    await tapSettingsTile(tester, 'Paste JSON');
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Backup JSON'),
      restored.toBackupJson(),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Import'));
    await tester.pumpAndSettle();
    expect(find.text('Restore backup?'), findsOneWidget);
    expect(find.text('Restored System'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Restore'));
    await tester.pumpAndSettle();

    expect(find.text('Restored System'), findsOneWidget);
  });

  testWidgets('saves and restores cloud save preview from settings', (
    tester,
  ) async {
    final seeded = AppSnapshot.seeded();
    final sourceSnapshot = seeded.copyWith(
      profile: seeded.profile.copyWith(
        displayName: 'Cloud Source',
        updatedAt: DateTime(2026, 6, 21),
      ),
    );
    final targetSnapshot = seeded.copyWith(
      profile: seeded.profile.copyWith(
        displayName: 'Local Device',
        updatedAt: DateTime(2026, 6, 22),
      ),
      members: seeded.members
          .map(
            (member) => member.id == 'member-mara'
                ? member.copyWith(archived: true)
                : member,
          )
          .toList(),
      frontingMemberIds: const [],
    );
    final cloudSaveAdapter = MemoryCloudSaveAdapter();

    await pumpApp(
      tester,
      store: MemoryAppStore(sourceSnapshot),
      cloudSaveAdapter: cloudSaveAdapter,
      cloudSavePayloadEncoder: const _ReversingCloudSavePayloadEncoder(),
    );
    await tester.tap(find.byTooltip('Settings and privacy'));
    await tester.pumpAndSettle();
    await tapSettingsTile(tester, 'Save now');
    await tester.pumpAndSettle();

    expect(find.textContaining('Cloud save preview saved'), findsOneWidget);
    expect(await cloudSaveAdapter.latestMetadata(), isNotNull);
    expect(
      (await cloudSaveAdapter.downloadLatest())?.payload.encryption.algorithm,
      'test-reverse',
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    final targetStore = MemoryAppStore(targetSnapshot);
    await pumpApp(
      tester,
      store: targetStore,
      cloudSaveAdapter: cloudSaveAdapter,
      cloudSavePayloadDecoder: _reverseCloudSavePayload,
    );

    expect(find.text('Local Device'), findsOneWidget);
    expect(find.text('Mara'), findsNothing);

    await tester.tap(find.widgetWithText(InputChip, 'Social'));
    await tester.pumpAndSettle();
    expect(find.text('Best for calls and errands.'), findsOneWidget);
    expect(find.text('Keeps the day moving.'), findsNothing);

    await tester.tap(find.byTooltip('Settings and privacy'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Latest save:'), findsOneWidget);
    await tapSettingsTile(tester, 'Restore cloud save');
    await tester.pumpAndSettle();

    expect(find.text('Restore backup?'), findsOneWidget);
    expect(find.text('Cloud Source'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Restore'));
    await tester.pumpAndSettle();

    expect(find.text('Cloud Source'), findsOneWidget);
    expect(find.text('Mara'), findsWidgets);
    expect(find.text('Keeps the day moving.'), findsOneWidget);
    expect((await targetStore.load())?.profile.displayName, 'Cloud Source');
  });

  testWidgets('records fronting sessions when a member fronts', (tester) async {
    final seeded = AppSnapshot.seeded();
    final store = MemoryAppStore(seeded);
    final sol = seeded.members[1];
    await pumpApp(tester, store: store);

    final solTile = find
        .ancestor(
          of: find.text('Best for calls and errands.'),
          matching: find.byType(Card),
        )
        .first;
    await tester.tap(
      find.descendant(
        of: solTile,
        matching: find.widgetWithText(FilledButton, 'Front'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sol - Started fronting'), findsWidgets);

    final activeSnapshot = await store.load();
    expect(activeSnapshot?.frontingMemberIds, contains(sol.id));
    expect(activeSnapshot?.frontSessions.first.memberId, sol.id);
    expect(activeSnapshot?.frontSessions.first.isOpen, isTrue);

    await tester.tap(
      find.descendant(
        of: solTile,
        matching: find.widgetWithText(FilledButton, 'Fronting'),
      ),
    );
    await tester.pumpAndSettle();

    final closedSnapshot = await store.load();
    expect(closedSnapshot?.frontingMemberIds, isNot(contains(sol.id)));
    expect(closedSnapshot?.frontSessions.first.memberId, sol.id);
    expect(closedSnapshot?.frontSessions.first.endedAt, isNotNull);
  });

  testWidgets('soft deletes and restores timeline entries', (tester) async {
    final store = MemoryAppStore(AppSnapshot.seeded());
    await pumpApp(tester, store: store);

    expect(find.text('Mara - Started fronting'), findsWidgets);

    await tester.drag(find.byType(ListView), const Offset(0, -260));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete timeline entry'));
    await tester.pumpAndSettle();

    var saved = await store.load();
    expect(saved?.activeTimeline, isEmpty);
    expect(saved?.deletedTimeline.single.id, 'entry-seed-front');
    expect(find.text('Mara - Started fronting'), findsNothing);

    await tester.tap(find.byTooltip('Settings and privacy'));
    await tester.pumpAndSettle();
    await tapSettingsTile(tester, 'Recently deleted');
    await tester.pumpAndSettle();

    expect(find.text('Recently deleted'), findsOneWidget);
    expect(find.text('Mara - Started fronting'), findsOneWidget);

    await tester.tap(find.byTooltip('Restore timeline entry'));
    await tester.pumpAndSettle();

    saved = await store.load();
    expect(saved?.deletedTimeline, isEmpty);
    expect(saved?.activeTimeline.single.id, 'entry-seed-front');
    expect(find.text('No deleted items'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Close'));
    await tester.pumpAndSettle();

    expect(find.text('Mara - Started fronting'), findsWidgets);
  });

  testWidgets('adds a new local member', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('Add member').first);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, 'Image'), findsOneWidget);
    expect(find.text('Groups'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'June');
    await tester.enterText(find.widgetWithText(TextField, 'Role'), 'Grounding');
    await tester.enterText(
      find.widgetWithText(TextField, 'Notes'),
      'Likes lists.',
    );
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilterChip, 'Rest'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('June'), findsOneWidget);
    expect(find.text('Likes lists.'), findsOneWidget);
    expect(find.text('Rest'), findsWidgets);
  });

  testWidgets('long member names wrap on phone screens', (tester) async {
    final seeded = AppSnapshot.seeded();
    final longNameMember = seeded.members.first.copyWith(
      name: 'An Extremely Long Member Name',
    );

    await pumpApp(
      tester,
      size: const Size(390, 760),
      snapshot: seeded.copyWith(members: [longNameMember]),
    );

    final memberCard = find.ancestor(
      of: find.text('Keeps the day moving.'),
      matching: find.byType(Card),
    );
    final nameText = tester.widget<Text>(
      find.descendant(
        of: memberCard,
        matching: find.text('An Extremely Long Member Name'),
      ),
    );
    expect(nameText.maxLines, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('adds a group and uses it in the group filter', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('Add group'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Care Team');
    await tester.enterText(
      find.widgetWithText(TextField, 'Description'),
      'Helpful support roles.',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('Care Team'), findsOneWidget);

    await tester.tap(find.text('Care Team'));
    await tester.pumpAndSettle();

    expect(find.text('No members in this group'), findsOneWidget);
  });

  testWidgets('shows archived groups for restore', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('Edit group').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Archive'));
    await tester.pumpAndSettle();

    expect(find.text('Archived groups (1)'), findsOneWidget);
  });

  testWidgets('filters members by group', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.widgetWithText(InputChip, 'Social'));
    await tester.pumpAndSettle();

    expect(find.text('Best for calls and errands.'), findsOneWidget);
    expect(find.text('Keeps the day moving.'), findsNothing);
    expect(find.text('Likes quiet rooms.'), findsNothing);
  });

  testWidgets('sorts members from the members toolbar', (tester) async {
    final seeded = AppSnapshot.seeded(DateTime(2026, 6, 18));
    final sessions = [
      FrontSession(
        id: 'session-mara',
        memberId: 'member-mara',
        memberName: 'Mara',
        startedAt: DateTime(2026, 6, 19, 8),
        endedAt: DateTime(2026, 6, 19, 10),
      ),
      FrontSession(
        id: 'session-sol',
        memberId: 'member-sol',
        memberName: 'Sol',
        startedAt: DateTime(2026, 6, 20, 9),
        endedAt: DateTime(2026, 6, 20, 13),
      ),
      FrontSession(
        id: 'session-river',
        memberId: 'member-river',
        memberName: 'River',
        startedAt: DateTime(2026, 6, 21, 10),
        endedAt: DateTime(2026, 6, 21, 11),
      ),
    ];

    await pumpApp(
      tester,
      size: const Size(1200, 1100),
      snapshot: seeded.copyWith(
        frontingMemberIds: const [],
        frontSessions: sessions,
      ),
    );

    expect(find.byTooltip('Sort members: A-Z'), findsOneWidget);
    expectMemberNotesInOrder(tester, [
      'Keeps the day moving.',
      'Likes quiet rooms.',
      'Best for calls and errands.',
    ]);

    await tester.tap(find.byTooltip('Sort members: A-Z'));
    await tester.pumpAndSettle();
    await tapCheckedMenuOption(tester, 'Recently fronted');

    expect(find.byTooltip('Sort members: Recently fronted'), findsOneWidget);
    expectMemberNotesInOrder(tester, [
      'Likes quiet rooms.',
      'Best for calls and errands.',
      'Keeps the day moving.',
    ]);

    await tester.tap(find.byTooltip('Sort members: Recently fronted'));
    await tester.pumpAndSettle();
    await tapCheckedMenuOption(tester, 'Most used');

    expect(find.byTooltip('Sort members: Most used'), findsOneWidget);
    expectMemberNotesInOrder(tester, [
      'Best for calls and errands.',
      'Keeps the day moving.',
      'Likes quiet rooms.',
    ]);
  });

  testWidgets('opens group view from a member group label', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.widgetWithText(FilterChip, 'Social'));
    await tester.pumpAndSettle();

    expect(find.text('Best for calls and errands.'), findsOneWidget);
    expect(find.text('Keeps the day moving.'), findsNothing);
    expect(find.text('Likes quiet rooms.'), findsNothing);
  });

  testWidgets('scrolls group row to a member label selection', (tester) async {
    final seeded = AppSnapshot.seeded();
    final now = DateTime(2026, 6, 8);
    final groups = List.generate(12, (index) {
      final isLastGroup = index == 11;
      return MemberGroup(
        id: 'group-$index',
        name: isLastGroup ? 'Far Group' : 'Group $index',
        description: '',
        colorValue: memberColorChoices[index % memberColorChoices.length],
        archived: false,
        createdAt: now,
        updatedAt: now,
      );
    });
    final member = seeded.members.first.copyWith(groupIds: [groups.last.id]);

    await pumpApp(
      tester,
      size: const Size(430, 900),
      snapshot: seeded.copyWith(
        groups: groups,
        members: [member],
        frontingMemberIds: const [],
      ),
    );

    final groupFilterChip = find.widgetWithText(InputChip, 'Far Group');
    expect(tester.getTopLeft(groupFilterChip).dx, greaterThan(430));

    await tester.tap(find.widgetWithText(FilterChip, 'Far Group'));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(groupFilterChip).dx, greaterThanOrEqualTo(0));
    expect(tester.getTopRight(groupFilterChip).dx, lessThanOrEqualTo(430));
    expect(find.text('Keeps the day moving.'), findsOneWidget);
  });
}

class _ReversingCloudSavePayloadEncoder implements CloudSavePayloadEncoder {
  const _ReversingCloudSavePayloadEncoder();

  @override
  CloudSaveEncodedPayload encode(List<int> backupBytes) {
    return CloudSaveEncodedPayload(
      bytes: backupBytes.reversed.toList(),
      compression: cloudSaveCompressionNone,
      encryption: const CloudSaveEncryptionDescriptor(
        algorithm: 'test-reverse',
        keyDerivationAlgorithm: 'test-only',
        keyId: 'widget-test-key',
      ),
    );
  }
}

List<int> _reverseCloudSavePayload(CloudSavePayload _, List<int> payloadBytes) {
  return payloadBytes.reversed.toList();
}

class FakeAppAuthenticator implements AppAuthenticator {
  FakeAppAuthenticator({
    this.shouldAuthenticate = true,
    this.lockStatus = const AppLockStatus(
      isSupported: true,
      availableBiometrics: [BiometricType.face],
    ),
  });

  bool shouldAuthenticate;
  AppLockStatus lockStatus;
  int authenticateCount = 0;

  @override
  Future<bool> authenticate({required String reason}) async {
    authenticateCount += 1;
    return shouldAuthenticate;
  }

  @override
  Future<AppLockStatus> status() async => lockStatus;
}

class LongPathMemoryAppStore extends MemoryAppStore {
  LongPathMemoryAppStore(super.snapshot);

  @override
  Future<AppStoreInfo> info() async {
    const path =
        '/var/mobile/Containers/Data/Application/00000000-0000-0000-0000-000000000000/Library/Application Support/AllOfMe/snapshot.v1.json';
    return AppStoreInfo(
      label: 'Local app file',
      location: path,
      backupsLocation: '$path/backups',
      lastSavedAt: DateTime(2026, 6, 10, 16, 47),
    );
  }
}
