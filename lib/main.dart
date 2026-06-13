import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import 'app_lock.dart';
import 'models.dart';
import 'storage.dart';
import 'storage_factory.dart';

const String _frontingFilterId = '__fronting';
const String _allGroupsFilterId = '__all';
const String _ungroupedInsightGroupId = '__ungrouped';
const String _sampleInsightsSessionPrefix = 'sample-insights-session-';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await createDefaultAppStore();
  runApp(AllOfMeApp(store: store));
}

class AllOfMeApp extends StatelessWidget {
  const AllOfMeApp({
    super.key,
    required this.store,
    this.authenticator = const LocalAppAuthenticator(),
  });

  final AppStore store;
  final AppAuthenticator authenticator;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appDisplayName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF24786D),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F8F5),
        useMaterial3: true,
      ),
      home: HomeScreen(store: store, authenticator: authenticator),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.store,
    required this.authenticator,
  });

  final AppStore store;
  final AppAuthenticator authenticator;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  AppSnapshot? _snapshot;
  AppStoreInfo? _storeInfo;
  String? _loadError;
  bool _saving = false;
  bool _isLocked = false;
  bool _authInProgress = false;
  String? _lockError;
  String? _selectedGroupId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSnapshot();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final snapshot = _snapshot;
    if (snapshot == null || !snapshot.security.appLockEnabled) {
      return;
    }
    if (_authInProgress) {
      return;
    }

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        if (mounted) {
          setState(() {
            _isLocked = true;
            _lockError = null;
          });
        }
      case AppLifecycleState.resumed:
        if (_isLocked) {
          _unlockApp();
        }
      case AppLifecycleState.inactive:
        break;
    }
  }

  Future<void> _loadSnapshot() async {
    try {
      final loaded = await widget.store.load();
      final isFirstRun = loaded == null;
      var snapshot = loaded ?? AppSnapshot.empty();
      if (loaded == null) {
        snapshot = await widget.store.save(snapshot);
      }
      final shouldLock = snapshot.security.appLockEnabled;
      final storeInfo = await widget.store.info();
      if (mounted) {
        setState(() {
          _snapshot = snapshot;
          _storeInfo = storeInfo;
          _loadError = null;
          _isLocked = shouldLock;
          _lockError = null;
        });
      }
      if (shouldLock) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _unlockApp();
          }
        });
      } else if (isFirstRun) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showFirstRunSetup();
          }
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _snapshot = AppSnapshot.empty();
          _loadError = 'Local data could not be loaded.';
          _isLocked = false;
          _lockError = null;
        });
      }
    }
  }

  Future<void> _showFirstRunSetup() async {
    final snapshot = _snapshot;
    if (snapshot == null || _isLocked) {
      return;
    }

    final result = await showDialog<_FirstRunSetupResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          _FirstRunSetupDialog(initialName: snapshot.profile.displayName),
    );
    if (result == null || !mounted) {
      return;
    }

    switch (result.action) {
      case _FirstRunAction.startFresh:
        await _persist(_firstRunSnapshot(AppSnapshot.empty(), result));
      case _FirstRunAction.useDemoData:
        await _persist(_firstRunSnapshot(AppSnapshot.seeded(), result));
      case _FirstRunAction.importBackup:
        await _importBackupFile();
    }
  }

  AppSnapshot _firstRunSnapshot(
    AppSnapshot snapshot,
    _FirstRunSetupResult result,
  ) {
    final now = DateTime.now();
    return snapshot.copyWith(
      profile: snapshot.profile.copyWith(
        displayName: result.systemName,
        description: 'Local-only system',
        updatedAt: now,
      ),
    );
  }

  Future<void> _unlockApp() async {
    final snapshot = _snapshot;
    if (snapshot == null || !snapshot.security.appLockEnabled) {
      if (mounted) {
        setState(() {
          _isLocked = false;
          _lockError = null;
        });
      }
      return;
    }
    if (_authInProgress) {
      return;
    }

    setState(() {
      _authInProgress = true;
      _lockError = null;
    });

    final status = await widget.authenticator.status();
    if (!mounted) {
      return;
    }
    if (!status.isSupported) {
      await _persist(
        snapshot.copyWith(
          security: snapshot.security.copyWith(appLockEnabled: false),
        ),
      );
      if (mounted) {
        setState(() {
          _authInProgress = false;
          _isLocked = false;
          _lockError = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('App lock is unavailable on this device.'),
          ),
        );
      }
      return;
    }

    final unlocked = await widget.authenticator.authenticate(
      reason: 'Unlock $appDisplayName with Face ID or your device passcode.',
    );
    if (!mounted) {
      return;
    }

    setState(() {
      _authInProgress = false;
      _isLocked = !unlocked;
      _lockError = unlocked ? null : 'Authentication was canceled.';
    });
  }

  void _lockApp() {
    final snapshot = _snapshot;
    if (snapshot == null || !snapshot.security.appLockEnabled) {
      return;
    }
    setState(() {
      _isLocked = true;
      _lockError = null;
    });
  }

  Future<void> _handleAppLockButton() async {
    final snapshot = _snapshot;
    if (snapshot == null) {
      return;
    }

    if (snapshot.security.appLockEnabled) {
      _lockApp();
      return;
    }

    await _setAppLockEnabled(true);
  }

  Future<void> _persist(AppSnapshot snapshot) async {
    setState(() {
      _snapshot = snapshot;
      _saving = true;
    });

    AppSnapshot? savedSnapshot;
    AppStoreInfo? storeInfo;
    try {
      savedSnapshot = await widget.store.save(snapshot);
      storeInfo = await widget.store.info();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Local save failed.')));
      }
    } finally {
      if (mounted) {
        setState(() {
          if (savedSnapshot != null) {
            _snapshot = savedSnapshot;
          }
          if (storeInfo != null) {
            _storeInfo = storeInfo;
          }
          _saving = false;
        });
      }
    }
  }

  Future<void> _editProfile() async {
    final snapshot = _snapshot;
    if (snapshot == null) {
      return;
    }

    final updated = await showDialog<SystemProfile>(
      context: context,
      builder: (context) => _ProfileDialog(profile: snapshot.profile),
    );

    if (updated != null) {
      await _persist(snapshot.copyWith(profile: updated));
    }
  }

  Future<void> _showMemberForm([Member? member]) async {
    final snapshot = _snapshot;
    if (snapshot == null) {
      return;
    }

    final result = await showDialog<_MemberFormResult>(
      context: context,
      builder: (context) =>
          _MemberDialog(member: member, groups: snapshot.activeGroups),
    );

    if (result == null) {
      return;
    }

    final now = DateTime.now();
    if (result.archive != null && member != null) {
      final archived = result.archive!;
      final updatedMember = member.copyWith(archived: archived, updatedAt: now);
      final frontingIds = snapshot.frontingMemberIds
          .where((id) => id != member.id || !archived)
          .toList();
      final frontSessions = archived
          ? _closeOpenFrontSessions(snapshot.frontSessions, member.id, now)
          : snapshot.frontSessions;
      final timeline = [
        TimelineEntry(
          id: createId('entry'),
          type: 'member',
          action: archived ? 'Archived member' : 'Restored member',
          memberId: member.id,
          memberName: member.name,
          createdAt: now,
        ),
        ...snapshot.timeline,
      ];

      await _persist(
        snapshot.copyWith(
          members: snapshot.members
              .map((item) => item.id == member.id ? updatedMember : item)
              .toList(),
          frontingMemberIds: frontingIds,
          frontSessions: frontSessions,
          timeline: timeline,
        ),
      );
      return;
    }

    final form = result.member;
    if (form == null) {
      return;
    }

    if (member == null) {
      final newMember = form.copyWith(updatedAt: now);
      await _persist(
        snapshot.copyWith(members: [...snapshot.members, newMember]),
      );
      return;
    }

    await _persist(
      snapshot.copyWith(
        members: snapshot.members
            .map(
              (item) =>
                  item.id == form.id ? form.copyWith(updatedAt: now) : item,
            )
            .toList(),
      ),
    );
  }

  Future<void> _showGroupForm([MemberGroup? group]) async {
    final snapshot = _snapshot;
    if (snapshot == null) {
      return;
    }

    final result = await showDialog<_GroupFormResult>(
      context: context,
      builder: (context) => _GroupDialog(group: group),
    );

    if (result == null) {
      return;
    }

    final now = DateTime.now();
    if (result.archive != null && group != null) {
      final archived = result.archive!;
      final updatedGroup = group.copyWith(archived: archived, updatedAt: now);

      await _persist(
        snapshot.copyWith(
          groups: snapshot.groups
              .map((item) => item.id == group.id ? updatedGroup : item)
              .toList(),
        ),
      );

      if (archived && _selectedGroupId == group.id) {
        setState(() {
          _selectedGroupId = null;
        });
      }
      return;
    }

    final form = result.group;
    if (form == null) {
      return;
    }

    if (group == null) {
      await _persist(
        snapshot.copyWith(
          groups: [
            ...snapshot.groups,
            form.copyWith(updatedAt: now),
          ],
        ),
      );
      return;
    }

    await _persist(
      snapshot.copyWith(
        groups: snapshot.groups
            .map(
              (item) =>
                  item.id == form.id ? form.copyWith(updatedAt: now) : item,
            )
            .toList(),
      ),
    );
  }

  void _selectGroup(String? groupId) {
    setState(() {
      _selectedGroupId = groupId;
    });
  }

  Future<void> _toggleFront(Member member) async {
    final snapshot = _snapshot;
    if (snapshot == null) {
      return;
    }

    final now = DateTime.now();
    final frontingIds = snapshot.frontingMemberIds.toList();
    final isFronting = frontingIds.contains(member.id);
    final frontSessions = snapshot.frontSessions.toList();
    if (isFronting) {
      frontingIds.remove(member.id);
      for (var index = 0; index < frontSessions.length; index += 1) {
        final session = frontSessions[index];
        if (session.memberId == member.id && session.isOpen) {
          frontSessions[index] = session.copyWith(endedAt: now);
        }
      }
    } else {
      frontingIds.add(member.id);
      frontSessions.insert(
        0,
        FrontSession(
          id: createId('session'),
          memberId: member.id,
          memberName: member.name,
          startedAt: now,
        ),
      );
    }

    await _persist(
      snapshot.copyWith(
        frontingMemberIds: frontingIds,
        frontSessions: frontSessions,
        timeline: [
          TimelineEntry(
            id: createId('entry'),
            type: 'front',
            action: isFronting ? 'Stepped back' : 'Started fronting',
            memberId: member.id,
            memberName: member.name,
            createdAt: now,
          ),
          ...snapshot.timeline,
        ],
      ),
    );
  }

  Future<void> _showInsights() async {
    while (mounted) {
      final snapshot = _snapshot;
      if (snapshot == null) {
        return;
      }
      if (!mounted) {
        return;
      }

      final action = await showDialog<_InsightsAction>(
        context: context,
        builder: (context) =>
            _InsightsDialog(snapshot: snapshot, now: DateTime.now()),
      );

      switch (action) {
        case _InsightsAction.refreshSampleData:
          await _persist(
            _snapshotWithSampleInsightsData(snapshot, DateTime.now()),
          );
        case _InsightsAction.clearSampleData:
          await _persist(_snapshotWithoutSampleInsightsData(snapshot));
        case null:
          return;
      }
    }
  }

  Future<void> _addTimelineNote() async {
    final snapshot = _snapshot;
    if (snapshot == null) {
      return;
    }

    final note = await showDialog<String>(
      context: context,
      builder: (context) => const _TimelineNoteDialog(),
    );

    if (note == null || note.trim().isEmpty) {
      return;
    }

    await _persist(
      snapshot.copyWith(
        timeline: [
          TimelineEntry(
            id: createId('entry'),
            type: 'note',
            action: 'Note',
            note: note.trim(),
            createdAt: DateTime.now(),
          ),
          ...snapshot.timeline,
        ],
      ),
    );
  }

  Future<void> _deleteTimelineEntry(TimelineEntry entry) async {
    final snapshot = _snapshot;
    if (snapshot == null || entry.isDeleted) {
      return;
    }

    final deletedAt = DateTime.now();
    await _persist(
      snapshot.copyWith(
        timeline: snapshot.timeline
            .map(
              (item) => item.id == entry.id
                  ? item.copyWith(deletedAt: deletedAt)
                  : item,
            )
            .toList(),
      ),
    );

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Timeline entry moved to Recently Deleted.'),
      ),
    );
  }

  Future<void> _showRecentlyDeleted() async {
    while (true) {
      if (!mounted) {
        return;
      }
      final snapshot = _snapshot;
      if (snapshot == null) {
        return;
      }

      final item = await showDialog<_DeletedItemReference>(
        context: context,
        builder: (context) => _RecentlyDeletedDialog(snapshot: snapshot),
      );
      if (item == null) {
        return;
      }

      await _restoreDeletedItem(item);
    }
  }

  Future<void> _restoreDeletedItem(_DeletedItemReference item) async {
    final snapshot = _snapshot;
    if (snapshot == null) {
      return;
    }

    final now = DateTime.now();
    switch (item.kind) {
      case _DeletedItemKind.member:
        final member = snapshot.members
            .where((candidate) => candidate.id == item.id)
            .firstOrNull;
        if (member == null) {
          return;
        }
        await _persist(
          snapshot.copyWith(
            members: snapshot.members
                .map(
                  (candidate) => candidate.id == member.id
                      ? candidate.copyWith(archived: false, updatedAt: now)
                      : candidate,
                )
                .toList(),
            timeline: [
              TimelineEntry(
                id: createId('entry'),
                type: 'member',
                action: 'Restored member',
                memberId: member.id,
                memberName: member.name,
                createdAt: now,
              ),
              ...snapshot.timeline,
            ],
          ),
        );
      case _DeletedItemKind.group:
        final group = snapshot.groups
            .where((candidate) => candidate.id == item.id)
            .firstOrNull;
        if (group == null) {
          return;
        }
        await _persist(
          snapshot.copyWith(
            groups: snapshot.groups
                .map(
                  (candidate) => candidate.id == group.id
                      ? candidate.copyWith(archived: false, updatedAt: now)
                      : candidate,
                )
                .toList(),
          ),
        );
      case _DeletedItemKind.timelineEntry:
        await _persist(
          snapshot.copyWith(
            timeline: snapshot.timeline
                .map(
                  (entry) => entry.id == item.id
                      ? entry.copyWith(deletedAt: null)
                      : entry,
                )
                .toList(),
          ),
        );
    }

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Item restored.')));
  }

  Future<void> _exportBackup() async {
    final snapshot = _snapshot;
    if (snapshot == null) {
      return;
    }

    final backup = await widget.store.createBackup(snapshot);
    final storeInfo = await widget.store.info();
    if (mounted) {
      setState(() {
        _storeInfo = storeInfo;
      });
    }
    if (!mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (context) => _BackupDialog(receipt: backup),
    );
  }

  Future<void> _setAppLockEnabled(bool enabled) async {
    final snapshot = _snapshot;
    if (snapshot == null || snapshot.security.appLockEnabled == enabled) {
      return;
    }

    if (enabled) {
      final status = await widget.authenticator.status();
      if (!mounted) {
        return;
      }
      if (!status.isSupported) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('App lock is unavailable on this device.'),
          ),
        );
        return;
      }

      final unlocked = await widget.authenticator.authenticate(
        reason: 'Use Face ID or your device passcode to turn on app lock.',
      );
      if (!mounted) {
        return;
      }
      if (!unlocked) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('App lock was not enabled.')),
        );
        return;
      }
    }

    await _persist(
      snapshot.copyWith(
        security: snapshot.security.copyWith(appLockEnabled: enabled),
      ),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _isLocked = false;
      _lockError = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(enabled ? 'App lock enabled.' : 'App lock off.')),
    );
  }

  Future<void> _showSettingsPrivacy() async {
    while (mounted) {
      final snapshot = _snapshot;
      if (snapshot == null) {
        return;
      }

      final info = await widget.store.info();
      final lockStatus = await widget.authenticator.status();
      if (!mounted) {
        return;
      }
      setState(() {
        _storeInfo = info;
      });

      final action = await showDialog<_SettingsPrivacyAction>(
        context: context,
        builder: (context) => _SettingsPrivacyDialog(
          snapshot: snapshot,
          storeInfo: info,
          lockStatus: lockStatus,
        ),
      );

      switch (action) {
        case _SettingsPrivacyAction.createBackup:
          await _exportBackup();
          return;
        case _SettingsPrivacyAction.importBackupFile:
          await _importBackupFile();
          return;
        case _SettingsPrivacyAction.pasteBackupJson:
          await _pasteBackupJson();
          return;
        case _SettingsPrivacyAction.openRecentlyDeleted:
          await _showRecentlyDeleted();
          return;
        case _SettingsPrivacyAction.enableAppLock:
          await _setAppLockEnabled(true);
        case _SettingsPrivacyAction.disableAppLock:
          await _setAppLockEnabled(false);
        case _SettingsPrivacyAction.refreshSampleData:
          await _persist(
            _snapshotWithSampleInsightsData(snapshot, DateTime.now()),
          );
        case _SettingsPrivacyAction.clearSampleData:
          await _persist(_snapshotWithoutSampleInsightsData(snapshot));
        case _SettingsPrivacyAction.clearAllData:
          await _clearLocalData();
          return;
        case null:
          return;
      }
    }
  }

  Future<void> _clearLocalData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const _ConfirmClearDataDialog(),
    );
    if (confirmed != true) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await widget.store.clear();
      final freshSnapshot = await widget.store.save(AppSnapshot.empty());
      final storeInfo = await widget.store.info();
      if (!mounted) {
        return;
      }
      setState(() {
        _snapshot = freshSnapshot;
        _storeInfo = storeInfo;
        _selectedGroupId = null;
        _loadError = null;
        _isLocked = false;
        _lockError = null;
        _saving = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Local data cleared.')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not clear local data.')),
      );
    }
  }

  Future<void> _pasteBackupJson() async {
    final rawBackup = await showDialog<String>(
      context: context,
      builder: (context) => const _ImportBackupDialog(),
    );
    if (rawBackup == null || rawBackup.trim().isEmpty) {
      return;
    }

    await _restoreBackup(rawBackup);
  }

  Future<void> _importBackupFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        return;
      }

      final file = result.files.single;
      final bytes = file.bytes;
      final rawBackup = bytes == null
          ? await result.xFiles.single.readAsString()
          : utf8.decode(bytes);
      await _restoreBackup(rawBackup);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not open backup.')));
      }
    }
  }

  Future<void> _restoreBackup(String rawBackup) async {
    final snapshot = _snapshot;
    if (snapshot == null) {
      return;
    }

    try {
      final imported = snapshotFromBackupJson(rawBackup);
      if (!mounted) {
        return;
      }

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => _ConfirmImportDialog(snapshot: imported),
      );
      if (confirmed != true) {
        return;
      }

      await widget.store.createBackup(snapshot);
      await _persist(imported);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Backup imported.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Backup import failed.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    final isLocked = snapshot != null && _isLocked;
    final showLocalChip = MediaQuery.sizeOf(context).width >= 520;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isLocked
              ? appDisplayName
              : snapshot?.profile.displayName ?? appDisplayName,
        ),
        actions: isLocked
            ? null
            : [
                IconButton(
                  onPressed: snapshot == null ? null : _editProfile,
                  icon: const Icon(Icons.tune),
                  tooltip: 'Edit system',
                ),
                IconButton(
                  onPressed: snapshot == null ? null : _showInsights,
                  icon: const Icon(Icons.insights_outlined),
                  tooltip: 'Insights',
                ),
                IconButton(
                  onPressed: snapshot == null ? null : _handleAppLockButton,
                  icon: Icon(
                    snapshot?.security.appLockEnabled == true
                        ? Icons.lock_outline
                        : Icons.lock_open_outlined,
                  ),
                  tooltip: 'App lock',
                ),
                IconButton(
                  onPressed: snapshot == null ? null : _showSettingsPrivacy,
                  icon: const Icon(Icons.settings_outlined),
                  tooltip: 'Settings and privacy',
                ),
                if (showLocalChip)
                  Tooltip(
                    message: 'Local-only mode',
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Chip(
                        avatar: Icon(
                          _saving
                              ? Icons.save_outlined
                              : Icons.cloud_off_outlined,
                          size: 18,
                        ),
                        label: Text(_saving ? 'Saving' : 'Local'),
                        visualDensity: VisualDensity.compact,
                        side: BorderSide.none,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  ),
              ],
      ),
      body: SafeArea(
        child: snapshot == null
            ? const Center(child: CircularProgressIndicator())
            : isLocked
            ? _LockedScreen(
                authenticating: _authInProgress,
                errorMessage: _lockError,
                onUnlock: _unlockApp,
              )
            : _HomeContent(
                snapshot: snapshot,
                storeInfo: _storeInfo,
                loadError: _loadError,
                onEditProfile: _editProfile,
                onEditMember: _showMemberForm,
                onEditGroup: _showGroupForm,
                selectedGroupId: _selectedGroupId,
                onSelectGroup: _selectGroup,
                onToggleFront: _toggleFront,
                onAddTimelineNote: _addTimelineNote,
                onDeleteTimelineEntry: _deleteTimelineEntry,
              ),
      ),
      floatingActionButton: snapshot == null || isLocked
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showMemberForm(),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Member'),
              tooltip: 'Add member',
            ),
    );
  }
}

class _LockedScreen extends StatelessWidget {
  const _LockedScreen({
    required this.authenticating,
    required this.errorMessage,
    required this.onUnlock,
  });

  final bool authenticating;
  final String? errorMessage;
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(
                  Icons.lock_outline,
                  size: 34,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'All Of Me is locked',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                authenticating
                    ? 'Waiting for Face ID or device passcode.'
                    : errorMessage ?? 'Unlock to view local system data.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: authenticating ? null : onUnlock,
                icon: authenticating
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.lock_open_outlined),
                label: Text(authenticating ? 'Unlocking' : 'Unlock'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({
    required this.snapshot,
    required this.storeInfo,
    required this.loadError,
    required this.onEditProfile,
    required this.onEditMember,
    required this.onEditGroup,
    required this.selectedGroupId,
    required this.onSelectGroup,
    required this.onToggleFront,
    required this.onAddTimelineNote,
    required this.onDeleteTimelineEntry,
  });

  final AppSnapshot snapshot;
  final AppStoreInfo? storeInfo;
  final String? loadError;
  final VoidCallback onEditProfile;
  final ValueChanged<Member?> onEditMember;
  final ValueChanged<MemberGroup?> onEditGroup;
  final String? selectedGroupId;
  final ValueChanged<String?> onSelectGroup;
  final ValueChanged<Member> onToggleFront;
  final VoidCallback onAddTimelineNote;
  final ValueChanged<TimelineEntry> onDeleteTimelineEntry;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 900;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
      children: [
        if (loadError != null) ...[
          _InlineNotice(message: loadError!),
          const SizedBox(height: 12),
        ],
        _DailyOverview(snapshot: snapshot, onEditProfile: onEditProfile),
        const SizedBox(height: 12),
        _DataSafetyStrip(storeInfo: storeInfo),
        const SizedBox(height: 18),
        if (isWide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _MembersSection(
                  snapshot: snapshot,
                  onEditMember: onEditMember,
                  onEditGroup: onEditGroup,
                  selectedGroupId: selectedGroupId,
                  onSelectGroup: onSelectGroup,
                  onToggleFront: onToggleFront,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                flex: 2,
                child: _TimelineSection(
                  events: snapshot.activeTimeline,
                  onAddNote: onAddTimelineNote,
                  onDeleteEntry: onDeleteTimelineEntry,
                ),
              ),
            ],
          )
        else ...[
          _MembersSection(
            snapshot: snapshot,
            onEditMember: onEditMember,
            onEditGroup: onEditGroup,
            selectedGroupId: selectedGroupId,
            onSelectGroup: onSelectGroup,
            onToggleFront: onToggleFront,
          ),
          const SizedBox(height: 18),
          _TimelineSection(
            events: snapshot.activeTimeline,
            onAddNote: onAddTimelineNote,
            onDeleteEntry: onDeleteTimelineEntry,
          ),
        ],
      ],
    );
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: TextStyle(color: colorScheme.onErrorContainer),
      ),
    );
  }
}

class _DataSafetyStrip extends StatelessWidget {
  const _DataSafetyStrip({required this.storeInfo});

  final AppStoreInfo? storeInfo;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final info = storeInfo;
    final detail = info?.lastSavedAt == null
        ? 'Preparing local store'
        : 'Saved ${_formatDateTime(info!.lastSavedAt!)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.health_and_safety_outlined, color: colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info?.label ?? 'Local storage',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyOverview extends StatelessWidget {
  const _DailyOverview({required this.snapshot, required this.onEditProfile});

  final AppSnapshot snapshot;
  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final profile = snapshot.profile;
    final frontingMembers = snapshot.members
        .where((member) => snapshot.frontingMemberIds.contains(member.id))
        .toList(growable: false);
    final latestEntry = snapshot.activeTimeline.firstOrNull;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (profile.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        profile.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: onEditProfile,
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit system',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _OverviewTile(
                icon: Icons.radio_button_checked,
                label: 'Current front',
                value: _frontingSummary(frontingMembers),
                detail: '${snapshot.activeMembers.length} active members',
              ),
              _OverviewTile(
                icon: Icons.history,
                label: 'Latest update',
                value: latestEntry == null
                    ? 'No timeline entries'
                    : _entryTitle(latestEntry),
                detail: latestEntry == null
                    ? 'Add a note or front change'
                    : _entrySubtitle(latestEntry),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InsightsDialog extends StatelessWidget {
  const _InsightsDialog({required this.snapshot, required this.now});

  final AppSnapshot snapshot;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final summary = _InsightsSummary.fromSnapshot(snapshot, now);
    final maxContentHeight = MediaQuery.sizeOf(context).height * 0.72;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.insights_outlined),
          SizedBox(width: 10),
          Text('Insights'),
        ],
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 640,
          maxHeight: maxContentHeight < 340 ? 340 : maxContentHeight,
        ),
        child: Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Last 7 days',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _InsightMetricCard(
                      icon: Icons.timer_outlined,
                      label: 'Front time',
                      value: _formatDurationCompact(summary.frontTime7Days),
                      detail: 'Tracked locally',
                    ),
                    _InsightMetricCard(
                      icon: Icons.swap_horiz_outlined,
                      label: 'Switches',
                      value: summary.switches7Days.toString(),
                      detail: 'Session starts',
                    ),
                    _InsightMetricCard(
                      icon: Icons.radio_button_checked,
                      label: 'Active now',
                      value: _frontingNameSummary(summary.activeFrontNames),
                      detail: _formatDurationCompact(summary.activeFrontTime),
                    ),
                    _InsightMetricCard(
                      icon: Icons.history_toggle_off_outlined,
                      label: 'All time',
                      value: _formatDurationCompact(summary.totalTracked),
                      detail: '${snapshot.frontSessions.length} sessions',
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _InsightBarSection(
                  title: 'Member front time',
                  slices: summary.memberSlices,
                  emptyLabel: 'No member front time in this window',
                ),
                const SizedBox(height: 22),
                _InsightBarSection(
                  title: 'Group front time',
                  slices: summary.groupSlices,
                  emptyLabel: 'No group front time in this window',
                ),
                const SizedBox(height: 22),
                Text(
                  'Recent sessions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                if (summary.recentSessions.isEmpty)
                  const _EmptySurface(label: 'No front sessions yet')
                else
                  ...summary.recentSessions.map(
                    (session) => _InsightSessionTile(
                      session: session,
                      colorValue: summary.colorForMember(session.memberId),
                      now: now,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        if (snapshot.frontSessions.any(_isSampleInsightsSession))
          TextButton.icon(
            onPressed: () =>
                Navigator.of(context).pop(_InsightsAction.clearSampleData),
            icon: const Icon(Icons.delete_sweep_outlined),
            label: const Text('Clear samples'),
          ),
        TextButton.icon(
          onPressed: () =>
              Navigator.of(context).pop(_InsightsAction.refreshSampleData),
          icon: const Icon(Icons.auto_graph_outlined),
          label: Text(
            snapshot.frontSessions.any(_isSampleInsightsSession)
                ? 'Refresh samples'
                : 'Sample data',
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

enum _InsightsAction { refreshSampleData, clearSampleData }

class _InsightsSummary {
  const _InsightsSummary({
    required this.frontTime7Days,
    required this.switches7Days,
    required this.activeFrontTime,
    required this.totalTracked,
    required this.activeFrontNames,
    required this.memberSlices,
    required this.groupSlices,
    required this.recentSessions,
    required this.memberColorsById,
  });

  final Duration frontTime7Days;
  final int switches7Days;
  final Duration activeFrontTime;
  final Duration totalTracked;
  final List<String> activeFrontNames;
  final List<_InsightSlice> memberSlices;
  final List<_InsightSlice> groupSlices;
  final List<FrontSession> recentSessions;
  final Map<String, int> memberColorsById;

  int colorForMember(String memberId) {
    return memberColorsById[memberId] ?? memberColorChoices.first;
  }

  factory _InsightsSummary.fromSnapshot(AppSnapshot snapshot, DateTime now) {
    final windowStart = now.subtract(const Duration(days: 7));
    final membersById = {
      for (final member in snapshot.members) member.id: member,
    };
    final groupsById = {for (final group in snapshot.groups) group.id: group};
    final sessionNamesByMemberId = <String, String>{};
    final memberDurations = <String, Duration>{};
    final groupDurations = <String, Duration>{};
    var frontTime7Days = Duration.zero;
    var activeFrontTime = Duration.zero;
    var totalTracked = Duration.zero;

    for (final session in snapshot.frontSessions) {
      sessionNamesByMemberId[session.memberId] = session.memberName;
      final totalDuration = session.durationUntil(now);
      totalTracked += totalDuration;
      if (session.isOpen) {
        activeFrontTime += totalDuration;
      }

      final windowDuration = _sessionDurationWithin(session, windowStart, now);
      if (windowDuration == Duration.zero) {
        continue;
      }

      frontTime7Days += windowDuration;
      memberDurations[session.memberId] =
          (memberDurations[session.memberId] ?? Duration.zero) + windowDuration;

      final member = membersById[session.memberId];
      final groupIds = member?.groupIds ?? const <String>[];
      if (groupIds.isEmpty) {
        groupDurations[_ungroupedInsightGroupId] =
            (groupDurations[_ungroupedInsightGroupId] ?? Duration.zero) +
            windowDuration;
      } else {
        for (final groupId in groupIds) {
          groupDurations[groupId] =
              (groupDurations[groupId] ?? Duration.zero) + windowDuration;
        }
      }
    }

    final memberSlices = memberDurations.entries.map((entry) {
      final member = membersById[entry.key];
      return _InsightSlice(
        label:
            member?.name ??
            sessionNamesByMemberId[entry.key] ??
            'Unknown member',
        colorValue: member?.colorValue ?? memberColorChoices.first,
        duration: entry.value,
      );
    }).toList()..sort((left, right) => right.duration.compareTo(left.duration));

    final groupSlices = groupDurations.entries.map((entry) {
      if (entry.key == _ungroupedInsightGroupId) {
        return _InsightSlice(
          label: 'Ungrouped',
          colorValue: memberColorChoices.last,
          duration: entry.value,
        );
      }
      final group = groupsById[entry.key];
      return _InsightSlice(
        label: group?.name ?? 'Unknown group',
        colorValue: group?.colorValue ?? memberColorChoices.first,
        duration: entry.value,
      );
    }).toList()..sort((left, right) => right.duration.compareTo(left.duration));

    final recentSessions = [...snapshot.frontSessions]
      ..sort((left, right) => right.startedAt.compareTo(left.startedAt));
    final switches7Days = snapshot.frontSessions
        .where(
          (session) =>
              !session.startedAt.isBefore(windowStart) &&
              !session.startedAt.isAfter(now),
        )
        .length;
    final activeFrontNames = snapshot.frontingMemberIds
        .map((memberId) {
          return membersById[memberId]?.name ??
              sessionNamesByMemberId[memberId] ??
              'Unknown member';
        })
        .toList(growable: false);

    return _InsightsSummary(
      frontTime7Days: frontTime7Days,
      switches7Days: switches7Days,
      activeFrontTime: activeFrontTime,
      totalTracked: totalTracked,
      activeFrontNames: activeFrontNames,
      memberSlices: memberSlices.take(6).toList(growable: false),
      groupSlices: groupSlices.take(6).toList(growable: false),
      recentSessions: recentSessions.take(5).toList(growable: false),
      memberColorsById: {
        for (final member in snapshot.members) member.id: member.colorValue,
      },
    );
  }
}

class _InsightSlice {
  const _InsightSlice({
    required this.label,
    required this.colorValue,
    required this.duration,
  });

  final String label;
  final int colorValue;
  final Duration duration;
}

class _InsightMetricCard extends StatelessWidget {
  const _InsightMetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
  });

  final IconData icon;
  final String label;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 142,
      constraints: const BoxConstraints(minHeight: 108),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: colorScheme.primary),
          const SizedBox(height: 10),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _InsightBarSection extends StatelessWidget {
  const _InsightBarSection({
    required this.title,
    required this.slices,
    required this.emptyLabel,
  });

  final String title;
  final List<_InsightSlice> slices;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    final maxDuration = slices.isEmpty ? Duration.zero : slices.first.duration;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        if (slices.isEmpty)
          _EmptySurface(label: emptyLabel)
        else
          ...slices.map(
            (slice) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _InsightBar(slice: slice, maxDuration: maxDuration),
            ),
          ),
      ],
    );
  }
}

class _InsightBar extends StatelessWidget {
  const _InsightBar({required this.slice, required this.maxDuration});

  final _InsightSlice slice;
  final Duration maxDuration;

  @override
  Widget build(BuildContext context) {
    final color = Color(slice.colorValue);
    final fraction = maxDuration.inMilliseconds == 0
        ? 0.0
        : (slice.duration.inMilliseconds / maxDuration.inMilliseconds)
              .clamp(0.0, 1.0)
              .toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                slice.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _formatDurationCompact(slice.duration),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Stack(
            children: [
              Container(height: 10, color: color.withValues(alpha: 0.16)),
              FractionallySizedBox(
                widthFactor: fraction,
                child: Container(height: 10, color: color),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InsightSessionTile extends StatelessWidget {
  const _InsightSessionTile({
    required this.session,
    required this.colorValue,
    required this.now,
  });

  final FrontSession session;
  final int colorValue;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final duration = session.durationUntil(now);
    final trailing = session.isOpen ? 'Ongoing' : 'Ended';

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(radius: 10, backgroundColor: Color(colorValue)),
      title: Text(session.memberName),
      subtitle: Text(
        '${_formatDateTime(session.startedAt)} - ${_formatDurationCompact(duration)}',
      ),
      trailing: Text(trailing, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

class _OverviewTile extends StatelessWidget {
  const _OverviewTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
  });

  final IconData icon;
  final String label;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 220,
      constraints: const BoxConstraints(minHeight: 96),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

String _frontingSummary(List<Member> frontingMembers) {
  if (frontingMembers.isEmpty) {
    return 'No one fronting';
  }
  if (frontingMembers.length <= 2) {
    return frontingMembers.map((member) => member.name).join(', ');
  }
  return '${frontingMembers.take(2).map((member) => member.name).join(', ')} +${frontingMembers.length - 2}';
}

List<FrontSession> _closeOpenFrontSessions(
  List<FrontSession> sessions,
  String memberId,
  DateTime endedAt,
) {
  return sessions
      .map((session) {
        if (session.memberId == memberId && session.isOpen) {
          return session.copyWith(endedAt: endedAt);
        }
        return session;
      })
      .toList(growable: false);
}

AppSnapshot _snapshotWithSampleInsightsData(
  AppSnapshot snapshot,
  DateTime now,
) {
  final members = snapshot.activeMembers.isEmpty
      ? snapshot.members
      : snapshot.activeMembers;
  if (members.isEmpty) {
    return snapshot;
  }

  final realSessions = snapshot.frontSessions
      .where((session) => !_isSampleInsightsSession(session))
      .toList(growable: false);
  final sampleSessions = _sampleInsightsSessions(members, now);
  final frontSessions = [...sampleSessions, ...realSessions]
    ..sort((left, right) => right.startedAt.compareTo(left.startedAt));

  return snapshot.copyWith(frontSessions: frontSessions);
}

AppSnapshot _snapshotWithoutSampleInsightsData(AppSnapshot snapshot) {
  return snapshot.copyWith(
    frontSessions: snapshot.frontSessions
        .where((session) => !_isSampleInsightsSession(session))
        .toList(growable: false),
  );
}

List<FrontSession> _sampleInsightsSessions(List<Member> members, DateTime now) {
  const startOffsets = [
    Duration(hours: 7, minutes: 45),
    Duration(hours: 10, minutes: 30),
    Duration(hours: 14, minutes: 15),
    Duration(hours: 19),
  ];
  const durations = [
    Duration(hours: 1, minutes: 35),
    Duration(hours: 2, minutes: 20),
    Duration(hours: 3, minutes: 5),
    Duration(hours: 1, minutes: 10),
  ];

  final today = DateTime(now.year, now.month, now.day);
  final sessions = <FrontSession>[];

  for (var dayOffset = 0; dayOffset < 14; dayOffset += 1) {
    final slotsForDay = 2 + (dayOffset % 3);
    final day = today.subtract(Duration(days: dayOffset));

    for (var slot = 0; slot < slotsForDay; slot += 1) {
      final startedAt = day.add(startOffsets[slot]);
      if (!startedAt.isBefore(now)) {
        continue;
      }

      var endedAt = startedAt.add(
        durations[(dayOffset + slot) % durations.length],
      );
      if (endedAt.isAfter(now)) {
        endedAt = now.subtract(const Duration(minutes: 5));
      }
      if (!endedAt.isAfter(startedAt)) {
        continue;
      }

      final member = members[(dayOffset + (slot * 2)) % members.length];
      sessions.add(
        FrontSession(
          id: '$_sampleInsightsSessionPrefix${dayOffset.toString().padLeft(2, '0')}-$slot',
          memberId: member.id,
          memberName: member.name,
          startedAt: startedAt,
          endedAt: endedAt,
        ),
      );
    }
  }

  return sessions;
}

bool _isSampleInsightsSession(FrontSession session) {
  return session.id.startsWith(_sampleInsightsSessionPrefix);
}

List<Member> _visibleMembers(AppSnapshot snapshot, String? selectedGroupId) {
  final activeMembers = snapshot.activeMembers;
  if (selectedGroupId == null) {
    return activeMembers;
  }
  if (selectedGroupId == _frontingFilterId) {
    return activeMembers
        .where((member) => snapshot.frontingMemberIds.contains(member.id))
        .toList(growable: false);
  }
  return activeMembers
      .where((member) => member.groupIds.contains(selectedGroupId))
      .toList(growable: false);
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class _MembersSection extends StatelessWidget {
  const _MembersSection({
    required this.snapshot,
    required this.onEditMember,
    required this.onEditGroup,
    required this.selectedGroupId,
    required this.onSelectGroup,
    required this.onToggleFront,
  });

  final AppSnapshot snapshot;
  final ValueChanged<Member?> onEditMember;
  final ValueChanged<MemberGroup?> onEditGroup;
  final String? selectedGroupId;
  final ValueChanged<String?> onSelectGroup;
  final ValueChanged<Member> onToggleFront;

  @override
  Widget build(BuildContext context) {
    final activeGroups = snapshot.activeGroups;
    final visibleMembers = _visibleMembers(snapshot, selectedGroupId);
    final archivedMembers = snapshot.archivedMembers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          icon: Icons.radio_button_checked,
          title: 'Members',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => onEditGroup(null),
                icon: const Icon(Icons.folder_shared_outlined),
                tooltip: 'Add group',
              ),
              IconButton(
                onPressed: () => onEditMember(null),
                icon: const Icon(Icons.person_add_alt_1),
                tooltip: 'Add member',
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _GroupFilterRow(
          groups: activeGroups,
          selectedGroupId: selectedGroupId,
          onSelectGroup: onSelectGroup,
          onEditGroup: onEditGroup,
        ),
        if (snapshot.archivedGroups.isNotEmpty) ...[
          const SizedBox(height: 8),
          _ArchivedGroupsRow(
            groups: snapshot.archivedGroups,
            onEditGroup: onEditGroup,
          ),
        ],
        const SizedBox(height: 10),
        if (visibleMembers.isEmpty)
          _EmptySurface(
            icon: selectedGroupId == _frontingFilterId
                ? Icons.radio_button_unchecked
                : Icons.person_add_alt_1,
            label: selectedGroupId == null
                ? 'No members yet'
                : selectedGroupId == _frontingFilterId
                ? 'No one is fronting'
                : 'No members in this group',
            message: selectedGroupId == null
                ? 'Add the first member of this system. Everything stays local unless you export or sync later.'
                : selectedGroupId == _frontingFilterId
                ? 'Use the Front button on a member when someone is active.'
                : 'Assign a member to this group from their profile.',
            action: selectedGroupId == null
                ? FilledButton.icon(
                    onPressed: () => onEditMember(null),
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('Add member'),
                  )
                : TextButton.icon(
                    onPressed: () => onSelectGroup(null),
                    icon: const Icon(Icons.all_inclusive),
                    label: const Text('Show all'),
                  ),
          )
        else
          ...visibleMembers.map(
            (member) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _MemberTile(
                member: member,
                groups: activeGroups
                    .where((group) => member.groupIds.contains(group.id))
                    .toList(growable: false),
                isFronting: snapshot.frontingMemberIds.contains(member.id),
                onToggleFront: () => onToggleFront(member),
                onEdit: () => onEditMember(member),
                onSelectGroup: (group) => onSelectGroup(group.id),
              ),
            ),
          ),
        if (archivedMembers.isNotEmpty) ...[
          const SizedBox(height: 8),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text('Archived (${archivedMembers.length})'),
            children: archivedMembers
                .map(
                  (member) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _MemberTile(
                      member: member,
                      groups: activeGroups
                          .where((group) => member.groupIds.contains(group.id))
                          .toList(growable: false),
                      isFronting: false,
                      onToggleFront: () {},
                      onEdit: () => onEditMember(member),
                      onSelectGroup: (group) => onSelectGroup(group.id),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}

class _GroupFilterRow extends StatefulWidget {
  const _GroupFilterRow({
    required this.groups,
    required this.selectedGroupId,
    required this.onSelectGroup,
    required this.onEditGroup,
  });

  final List<MemberGroup> groups;
  final String? selectedGroupId;
  final ValueChanged<String?> onSelectGroup;
  final ValueChanged<MemberGroup?> onEditGroup;

  @override
  State<_GroupFilterRow> createState() => _GroupFilterRowState();
}

class _GroupFilterRowState extends State<_GroupFilterRow> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _chipKeys = {};

  @override
  void initState() {
    super.initState();
    _scrollSelectedChipIntoView();
  }

  @override
  void didUpdateWidget(_GroupFilterRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedGroupId != widget.selectedGroupId) {
      _scrollSelectedChipIntoView();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  GlobalKey _keyFor(String chipId) {
    return _chipKeys.putIfAbsent(chipId, GlobalKey.new);
  }

  void _scrollSelectedChipIntoView() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final selectedChipId = widget.selectedGroupId ?? _allGroupsFilterId;
      final selectedContext = _chipKeys[selectedChipId]?.currentContext;
      if (selectedContext == null) {
        return;
      }

      Scrollable.ensureVisible(
        selectedContext,
        alignment: 0.5,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Padding(
            key: _keyFor(_allGroupsFilterId),
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: widget.selectedGroupId == null,
              avatar: const Icon(Icons.all_inclusive, size: 18),
              label: const Text('All'),
              onSelected: (_) => widget.onSelectGroup(null),
            ),
          ),
          Padding(
            key: _keyFor(_frontingFilterId),
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: widget.selectedGroupId == _frontingFilterId,
              avatar: const Icon(Icons.radio_button_checked, size: 18),
              label: const Text('Fronting'),
              onSelected: (_) => widget.onSelectGroup(_frontingFilterId),
            ),
          ),
          ...widget.groups.map(
            (group) => Padding(
              key: _keyFor(group.id),
              padding: const EdgeInsets.only(right: 8),
              child: InputChip(
                selected: widget.selectedGroupId == group.id,
                avatar: CircleAvatar(backgroundColor: Color(group.colorValue)),
                label: Text(group.name),
                onPressed: () => widget.onSelectGroup(group.id),
                onDeleted: () => widget.onEditGroup(group),
                deleteIcon: const Icon(Icons.edit_outlined, size: 18),
                deleteButtonTooltipMessage: 'Edit group',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArchivedGroupsRow extends StatelessWidget {
  const _ArchivedGroupsRow({required this.groups, required this.onEditGroup});

  final List<MemberGroup> groups;
  final ValueChanged<MemberGroup?> onEditGroup;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text('Archived groups (${groups.length})'),
      children: groups.map((group) {
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            radius: 8,
            backgroundColor: Color(group.colorValue),
          ),
          title: Text(group.name),
          subtitle: group.description.isEmpty ? null : Text(group.description),
          trailing: IconButton(
            onPressed: () => onEditGroup(group),
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit group',
          ),
        );
      }).toList(),
    );
  }
}

class _GroupChip extends StatelessWidget {
  const _GroupChip({
    required this.group,
    this.compact = false,
    this.selected = false,
    this.onPressed,
  });

  final MemberGroup group;
  final bool compact;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final label = Text(group.name);
    final avatar = CircleAvatar(backgroundColor: Color(group.colorValue));

    if (onPressed != null) {
      return FilterChip(
        selected: selected,
        avatar: avatar,
        label: label,
        onSelected: (_) => onPressed?.call(),
        visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
      );
    }

    return Chip(
      avatar: avatar,
      label: label,
      side: BorderSide.none,
      visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.member,
    required this.groups,
    required this.isFronting,
    required this.onToggleFront,
    required this.onEdit,
    required this.onSelectGroup,
  });

  final Member member;
  final List<MemberGroup> groups;
  final bool isFronting;
  final VoidCallback onToggleFront;
  final VoidCallback onEdit;
  final ValueChanged<MemberGroup> onSelectGroup;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final note = member.note.trim().isEmpty ? member.role : member.note;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _MemberAvatar(member: member, size: 44),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    note,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (groups.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: groups
                          .map(
                            (group) => _GroupChip(
                              group: group,
                              compact: true,
                              onPressed: () => onSelectGroup(group),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (!member.archived)
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 112),
                child: FilledButton.tonalIcon(
                  onPressed: onToggleFront,
                  icon: Icon(
                    isFronting ? Icons.check_circle : Icons.login,
                    color: isFronting ? colorScheme.primary : null,
                  ),
                  label: Text(isFronting ? 'Fronting' : 'Front'),
                ),
              ),
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit member',
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineSection extends StatelessWidget {
  const _TimelineSection({
    required this.events,
    required this.onAddNote,
    required this.onDeleteEntry,
  });

  final List<TimelineEntry> events;
  final VoidCallback onAddNote;
  final ValueChanged<TimelineEntry> onDeleteEntry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          icon: Icons.history,
          title: 'Timeline',
          trailing: IconButton(
            onPressed: onAddNote,
            icon: const Icon(Icons.note_add_outlined),
            tooltip: 'Add note',
          ),
        ),
        const SizedBox(height: 10),
        if (events.isEmpty)
          _EmptySurface(
            icon: Icons.history_toggle_off_outlined,
            label: 'No timeline entries yet',
            message:
                'Front changes and notes will appear here as you use the app.',
            action: TextButton.icon(
              onPressed: onAddNote,
              icon: const Icon(Icons.note_add_outlined),
              label: const Text('Add note'),
            ),
          )
        else
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.separated(
              itemCount: events.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final event = events[index];
                return ListTile(
                  leading: Icon(
                    event.type == 'note'
                        ? Icons.sticky_note_2_outlined
                        : Icons.bolt_outlined,
                  ),
                  title: Text(_entryTitle(event)),
                  subtitle: Text(_entrySubtitle(event)),
                  trailing: IconButton(
                    onPressed: () => onDeleteEntry(event),
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Delete timeline entry',
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({required this.member, required this.size});

  final Member member;
  final double size;

  @override
  Widget build(BuildContext context) {
    return _AvatarPreview(
      imageDataUri: member.profileImageDataUri,
      colorValue: member.colorValue,
      initial: member.initial,
      size: size,
    );
  }
}

class _AvatarPreview extends StatelessWidget {
  const _AvatarPreview({
    required this.imageDataUri,
    required this.colorValue,
    required this.initial,
    required this.size,
  });

  final String? imageDataUri;
  final int colorValue;
  final String initial;
  final double size;

  @override
  Widget build(BuildContext context) {
    final bytes = _imageBytesFromDataUri(imageDataUri);

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: Color(colorValue),
      backgroundImage: bytes == null ? null : MemoryImage(bytes),
      child: bytes == null
          ? Text(
              initial,
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.4,
                fontWeight: FontWeight.w700,
              ),
            )
          : null,
    );
  }
}

class _EmptySurface extends StatelessWidget {
  const _EmptySurface({
    required this.label,
    this.message,
    this.icon,
    this.action,
  });

  final String label;
  final String? message;
  final IconData? icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            CircleAvatar(
              radius: 18,
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(
                icon,
                size: 20,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (message != null) ...[
            const SizedBox(height: 4),
            Text(message!, style: Theme.of(context).textTheme.bodyMedium),
          ],
          if (action != null) ...[const SizedBox(height: 14), action!],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class _FirstRunSetupDialog extends StatefulWidget {
  const _FirstRunSetupDialog({required this.initialName});

  final String initialName;

  @override
  State<_FirstRunSetupDialog> createState() => _FirstRunSetupDialogState();
}

class _FirstRunSetupDialogState extends State<_FirstRunSetupDialog> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String get _systemName {
    final trimmed = _nameController.text.trim();
    return trimmed.isEmpty ? appDisplayName : trimmed;
  }

  void _complete(_FirstRunAction action) {
    Navigator.of(
      context,
    ).pop(_FirstRunSetupResult(action: action, systemName: _systemName));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.favorite_outline),
          SizedBox(width: 10),
          Expanded(child: Text('Welcome to All Of Me')),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Set up a local space for this system. Nothing here needs an account or a network connection.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'System name'),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _complete(_FirstRunAction.startFresh),
              ),
              const SizedBox(height: 18),
              _SettingsNotice(
                icon: Icons.cloud_off_outlined,
                title: 'Local first',
                message:
                    'This device stores the canonical copy. Export, import, app lock, and future sync stay optional.',
              ),
              const SizedBox(height: 14),
              _FirstRunChoiceTile(
                icon: Icons.person_add_alt_1,
                title: 'Start fresh',
                subtitle: 'Create members, groups, and notes yourself.',
                color: colorScheme.primary,
                onTap: () => _complete(_FirstRunAction.startFresh),
              ),
              _FirstRunChoiceTile(
                icon: Icons.auto_awesome_outlined,
                title: 'Use demo data',
                subtitle: 'Load a small sample system for exploring the app.',
                color: colorScheme.tertiary,
                onTap: () => _complete(_FirstRunAction.useDemoData),
              ),
              _FirstRunChoiceTile(
                icon: Icons.upload_file_outlined,
                title: 'Import backup',
                subtitle: 'Restore from a JSON backup on this device.',
                color: colorScheme.secondary,
                onTap: () => _complete(_FirstRunAction.importBackup),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Later'),
        ),
        FilledButton.icon(
          onPressed: () => _complete(_FirstRunAction.startFresh),
          icon: const Icon(Icons.check),
          label: const Text('Start fresh'),
        ),
      ],
    );
  }
}

class _FirstRunChoiceTile extends StatelessWidget {
  const _FirstRunChoiceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      minLeadingWidth: 32,
      leading: Icon(icon, color: color),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _ProfileDialog extends StatefulWidget {
  const _ProfileDialog({required this.profile});

  final SystemProfile profile;

  @override
  State<_ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<_ProfileDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.displayName);
    _descriptionController = TextEditingController(
      text: widget.profile.description,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      return;
    }
    Navigator.of(context).pop(
      widget.profile.copyWith(
        displayName: name,
        description: _descriptionController.text.trim(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('System'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

class _MemberDialog extends StatefulWidget {
  const _MemberDialog({this.member, required this.groups});

  final Member? member;
  final List<MemberGroup> groups;

  @override
  State<_MemberDialog> createState() => _MemberDialogState();
}

class _MemberDialogState extends State<_MemberDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _roleController;
  late final TextEditingController _noteController;
  late int _colorValue;
  String? _profileImageId;
  String? _profileImageDataUri;
  late Set<String> _groupIds;
  bool _pickingImage = false;

  bool get _isEditing => widget.member != null;

  @override
  void initState() {
    super.initState();
    final member = widget.member;
    _nameController = TextEditingController(text: member?.name ?? '');
    _roleController = TextEditingController(text: member?.role ?? '');
    _noteController = TextEditingController(text: member?.note ?? '');
    _colorValue = member?.colorValue ?? memberColorChoices.first;
    _profileImageId = member?.profileImageId;
    _profileImageDataUri = member?.profileImageDataUri;
    _groupIds = {...?member?.groupIds};
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      return;
    }

    final now = DateTime.now();
    final existing = widget.member;
    Navigator.of(context).pop(
      _MemberFormResult(
        member: Member(
          id: existing?.id ?? createId('member'),
          name: name,
          role: _roleController.text.trim().isEmpty
              ? 'Member'
              : _roleController.text.trim(),
          note: _noteController.text.trim(),
          groupIds: _groupIds.toList(growable: false),
          colorValue: _colorValue,
          archived: existing?.archived ?? false,
          createdAt: existing?.createdAt ?? now,
          updatedAt: now,
          profileImageId: _profileImageDataUri == null ? null : _profileImageId,
          profileImageDataUri: _profileImageDataUri,
        ),
      ),
    );
  }

  Future<void> _pickProfileImage() async {
    if (_pickingImage) {
      return;
    }

    setState(() {
      _pickingImage = true;
    });

    try {
      final pickedImage = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 82,
      );
      if (pickedImage == null) {
        return;
      }

      final bytes = await pickedImage.readAsBytes();
      final mimeType =
          pickedImage.mimeType ?? _mimeTypeFromPath(pickedImage.name);
      setState(() {
        _profileImageId = null;
        _profileImageDataUri =
            'data:${mimeType ?? 'image/jpeg'};base64,${base64Encode(bytes)}';
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load that image.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _pickingImage = false;
        });
      }
    }
  }

  void _clearProfileImage() {
    setState(() {
      _profileImageId = null;
      _profileImageDataUri = null;
    });
  }

  void _archiveToggle() {
    final member = widget.member;
    if (member == null) {
      return;
    }
    Navigator.of(context).pop(_MemberFormResult(archive: !member.archived));
  }

  @override
  Widget build(BuildContext context) {
    final member = widget.member;

    return AlertDialog(
      title: Text(_isEditing ? 'Member' : 'New member'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _nameController,
                      builder: (context, value, _) {
                        return _AvatarPreview(
                          imageDataUri: _profileImageDataUri,
                          colorValue: _colorValue,
                          initial: _initialFromName(value.text),
                          size: 88,
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: _pickingImage ? null : _pickProfileImage,
                          icon: Icon(
                            _pickingImage
                                ? Icons.hourglass_empty
                                : Icons.add_photo_alternate_outlined,
                          ),
                          label: Text(_pickingImage ? 'Loading' : 'Image'),
                        ),
                        if (_profileImageDataUri != null)
                          TextButton.icon(
                            onPressed: _clearProfileImage,
                            icon: const Icon(Icons.close),
                            label: const Text('Remove'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _roleController,
                decoration: const InputDecoration(labelText: 'Role'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: 'Notes'),
                minLines: 2,
                maxLines: 4,
              ),
              if (widget.groups.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text('Groups', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.groups.map((group) {
                    final selected = _groupIds.contains(group.id);
                    return _GroupChip(
                      group: group,
                      selected: selected,
                      onPressed: () {
                        setState(() {
                          if (selected) {
                            _groupIds.remove(group.id);
                          } else {
                            _groupIds.add(group.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 18),
              Text('Color', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: memberColorChoices.map((value) {
                  final selected = value == _colorValue;
                  return Tooltip(
                    message: selected ? 'Selected color' : 'Color',
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _colorValue = value;
                        });
                      },
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Color(value),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected
                                ? Theme.of(context).colorScheme.onSurface
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: selected
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (member != null)
          TextButton.icon(
            onPressed: _archiveToggle,
            icon: Icon(
              member.archived
                  ? Icons.unarchive_outlined
                  : Icons.archive_outlined,
            ),
            label: Text(member.archived ? 'Restore' : 'Archive'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

class _GroupDialog extends StatefulWidget {
  const _GroupDialog({this.group});

  final MemberGroup? group;

  @override
  State<_GroupDialog> createState() => _GroupDialogState();
}

class _GroupDialogState extends State<_GroupDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late int _colorValue;

  bool get _isEditing => widget.group != null;

  @override
  void initState() {
    super.initState();
    final group = widget.group;
    _nameController = TextEditingController(text: group?.name ?? '');
    _descriptionController = TextEditingController(
      text: group?.description ?? '',
    );
    _colorValue = group?.colorValue ?? memberColorChoices.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      return;
    }

    final now = DateTime.now();
    final existing = widget.group;
    Navigator.of(context).pop(
      _GroupFormResult(
        group: MemberGroup(
          id: existing?.id ?? createId('group'),
          name: name,
          description: _descriptionController.text.trim(),
          colorValue: _colorValue,
          archived: existing?.archived ?? false,
          createdAt: existing?.createdAt ?? now,
          updatedAt: now,
        ),
      ),
    );
  }

  void _archiveToggle() {
    final group = widget.group;
    if (group == null) {
      return;
    }
    Navigator.of(context).pop(_GroupFormResult(archive: !group.archived));
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.group;

    return AlertDialog(
      title: Text(_isEditing ? 'Group' : 'New group'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                minLines: 2,
                maxLines: 3,
              ),
              const SizedBox(height: 18),
              Text('Color', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: memberColorChoices.map((value) {
                  final selected = value == _colorValue;
                  return Tooltip(
                    message: selected ? 'Selected color' : 'Color',
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _colorValue = value;
                        });
                      },
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Color(value),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected
                                ? Theme.of(context).colorScheme.onSurface
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: selected
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (group != null)
          TextButton.icon(
            onPressed: _archiveToggle,
            icon: Icon(
              group.archived
                  ? Icons.unarchive_outlined
                  : Icons.archive_outlined,
            ),
            label: Text(group.archived ? 'Restore' : 'Archive'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

class _TimelineNoteDialog extends StatefulWidget {
  const _TimelineNoteDialog();

  @override
  State<_TimelineNoteDialog> createState() => _TimelineNoteDialogState();
}

class _TimelineNoteDialogState extends State<_TimelineNoteDialog> {
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _save() {
    Navigator.of(context).pop(_noteController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Timeline note'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: TextField(
          controller: _noteController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Note'),
          minLines: 3,
          maxLines: 6,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

class _RecentlyDeletedDialog extends StatelessWidget {
  const _RecentlyDeletedDialog({required this.snapshot});

  final AppSnapshot snapshot;

  void _restore(BuildContext context, _DeletedItemReference item) {
    Navigator.of(context).pop(item);
  }

  @override
  Widget build(BuildContext context) {
    final archivedMembers = snapshot.archivedMembers;
    final archivedGroups = snapshot.archivedGroups;
    final deletedTimeline = snapshot.deletedTimeline;
    final hasItems =
        archivedMembers.isNotEmpty ||
        archivedGroups.isNotEmpty ||
        deletedTimeline.isNotEmpty;
    final maxContentHeight = MediaQuery.sizeOf(context).height * 0.72;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.restore_from_trash_outlined),
          SizedBox(width: 10),
          Expanded(child: Text('Recently deleted')),
        ],
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: maxContentHeight < 320 ? 320 : maxContentHeight,
        ),
        child: Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            child: hasItems
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (archivedMembers.isNotEmpty)
                        _DeletedItemsSection(
                          title: 'Members',
                          children: archivedMembers
                              .map(
                                (member) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: _MemberAvatar(
                                    member: member,
                                    size: 36,
                                  ),
                                  title: Text(
                                    member.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    'Archived ${_formatDateTime(member.updatedAt)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: IconButton(
                                    onPressed: () => _restore(
                                      context,
                                      _DeletedItemReference(
                                        _DeletedItemKind.member,
                                        member.id,
                                      ),
                                    ),
                                    icon: const Icon(Icons.restore_outlined),
                                    tooltip: 'Restore member',
                                  ),
                                  onTap: () => _restore(
                                    context,
                                    _DeletedItemReference(
                                      _DeletedItemKind.member,
                                      member.id,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      if (archivedGroups.isNotEmpty)
                        _DeletedItemsSection(
                          title: 'Groups',
                          children: archivedGroups
                              .map(
                                (group) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    radius: 18,
                                    backgroundColor: Color(group.colorValue),
                                  ),
                                  title: Text(
                                    group.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    'Archived ${_formatDateTime(group.updatedAt)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: IconButton(
                                    onPressed: () => _restore(
                                      context,
                                      _DeletedItemReference(
                                        _DeletedItemKind.group,
                                        group.id,
                                      ),
                                    ),
                                    icon: const Icon(Icons.restore_outlined),
                                    tooltip: 'Restore group',
                                  ),
                                  onTap: () => _restore(
                                    context,
                                    _DeletedItemReference(
                                      _DeletedItemKind.group,
                                      group.id,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      if (deletedTimeline.isNotEmpty)
                        _DeletedItemsSection(
                          title: 'Timeline',
                          children: deletedTimeline
                              .map(
                                (entry) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(
                                    entry.type == 'note'
                                        ? Icons.sticky_note_2_outlined
                                        : Icons.bolt_outlined,
                                  ),
                                  title: Text(
                                    _entryTitle(entry),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    'Deleted ${_formatDateTime(entry.deletedAt!)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: IconButton(
                                    onPressed: () => _restore(
                                      context,
                                      _DeletedItemReference(
                                        _DeletedItemKind.timelineEntry,
                                        entry.id,
                                      ),
                                    ),
                                    icon: const Icon(Icons.restore_outlined),
                                    tooltip: 'Restore timeline entry',
                                  ),
                                  onTap: () => _restore(
                                    context,
                                    _DeletedItemReference(
                                      _DeletedItemKind.timelineEntry,
                                      entry.id,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                    ],
                  )
                : const _EmptySurface(label: 'No deleted items'),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _DeletedItemsSection extends StatelessWidget {
  const _DeletedItemsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var index = 0; index < children.length; index += 1) ...[
                  children[index],
                  if (index < children.length - 1) const Divider(height: 1),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsPrivacyDialog extends StatelessWidget {
  const _SettingsPrivacyDialog({
    required this.snapshot,
    required this.storeInfo,
    required this.lockStatus,
  });

  final AppSnapshot snapshot;
  final AppStoreInfo storeInfo;
  final AppLockStatus lockStatus;

  @override
  Widget build(BuildContext context) {
    final lockEnabled = snapshot.security.appLockEnabled;
    final canChangeLock = lockStatus.isSupported || lockEnabled;
    final hasSampleData = snapshot.frontSessions.any(_isSampleInsightsSession);
    final recoverableCount =
        snapshot.archivedMembers.length +
        snapshot.archivedGroups.length +
        snapshot.deletedTimeline.length;
    final maxContentHeight = MediaQuery.sizeOf(context).height * 0.72;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.settings_outlined),
          SizedBox(width: 10),
          Expanded(child: Text('Settings & privacy')),
        ],
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: maxContentHeight < 360 ? 360 : maxContentHeight,
        ),
        child: Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SettingsSectionTitle('Privacy'),
                const _SettingsNotice(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy policy',
                  message:
                      'All Of Me stores system data on this device. Export and import are explicit actions.',
                ),
                const SizedBox(height: 18),
                const _SettingsSectionTitle('Storage'),
                _SafetyRow(label: 'Storage', value: storeInfo.label),
                _SafetyRow(label: 'Location', value: storeInfo.location),
                _SafetyRow(
                  label: 'Last saved',
                  value: storeInfo.lastSavedAt == null
                      ? 'Not saved yet'
                      : _formatDateTime(storeInfo.lastSavedAt!),
                ),
                if (storeInfo.backupsLocation != null)
                  _SafetyRow(
                    label: 'Backups',
                    value: storeInfo.backupsLocation!,
                  ),
                _SafetyRow(
                  label: 'Records',
                  value:
                      '${snapshot.members.length} members, ${snapshot.groups.length} groups, ${snapshot.frontSessions.length} sessions, ${snapshot.timeline.length} timeline entries',
                ),
                _SafetyRow(
                  label: 'Schema',
                  value: snapshot.schemaVersion.toString(),
                ),
                const SizedBox(height: 18),
                const _SettingsSectionTitle('Backup & restore'),
                _SettingsActionTile(
                  icon: Icons.file_download_outlined,
                  title: 'Export backup',
                  subtitle: 'Create a portable JSON backup.',
                  onTap: () => Navigator.of(
                    context,
                  ).pop(_SettingsPrivacyAction.createBackup),
                ),
                _SettingsActionTile(
                  icon: Icons.upload_file_outlined,
                  title: 'Import file',
                  subtitle: 'Restore from a local JSON backup file.',
                  onTap: () => Navigator.of(
                    context,
                  ).pop(_SettingsPrivacyAction.importBackupFile),
                ),
                _SettingsActionTile(
                  icon: Icons.content_paste_go_outlined,
                  title: 'Paste JSON',
                  subtitle: 'Restore from backup text.',
                  onTap: () => Navigator.of(
                    context,
                  ).pop(_SettingsPrivacyAction.pasteBackupJson),
                ),
                const SizedBox(height: 18),
                const _SettingsSectionTitle('Recovery'),
                _SettingsActionTile(
                  icon: Icons.restore_from_trash_outlined,
                  title: 'Recently deleted',
                  subtitle: recoverableCount == 0
                      ? 'No deleted items.'
                      : '$recoverableCount items available to restore.',
                  onTap: () => Navigator.of(
                    context,
                  ).pop(_SettingsPrivacyAction.openRecentlyDeleted),
                ),
                const SizedBox(height: 18),
                const _SettingsSectionTitle('Security'),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: Icon(
                    lockEnabled ? Icons.lock_outline : Icons.lock_open_outlined,
                  ),
                  title: const Text('App lock'),
                  subtitle: Text(
                    lockEnabled
                        ? 'On - unlock required on launch and resume'
                        : lockStatus.availabilityLabel,
                  ),
                  value: lockEnabled,
                  onChanged: canChangeLock
                      ? (value) => Navigator.of(context).pop(
                          value
                              ? _SettingsPrivacyAction.enableAppLock
                              : _SettingsPrivacyAction.disableAppLock,
                        )
                      : null,
                ),
                const SizedBox(height: 18),
                const _SettingsSectionTitle('Demo data'),
                _SettingsActionTile(
                  icon: Icons.auto_graph_outlined,
                  title: hasSampleData
                      ? 'Refresh sample data'
                      : 'Add sample data',
                  subtitle: hasSampleData
                      ? 'Replace generated fronting sessions.'
                      : 'Generate local sessions for insights testing.',
                  onTap: () => Navigator.of(
                    context,
                  ).pop(_SettingsPrivacyAction.refreshSampleData),
                ),
                if (hasSampleData)
                  _SettingsActionTile(
                    icon: Icons.delete_sweep_outlined,
                    title: 'Clear sample data',
                    subtitle: 'Remove generated sessions only.',
                    onTap: () => Navigator.of(
                      context,
                    ).pop(_SettingsPrivacyAction.clearSampleData),
                  ),
                const SizedBox(height: 18),
                const _SettingsSectionTitle('Reset'),
                _SettingsActionTile(
                  icon: Icons.delete_forever_outlined,
                  title: 'Clear all local data',
                  subtitle:
                      'Remove members, groups, sessions, notes, backups, and profile images from this device.',
                  destructive: true,
                  onTap: () => Navigator.of(
                    context,
                  ).pop(_SettingsPrivacyAction.clearAllData),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _SettingsSectionTitle extends StatelessWidget {
  const _SettingsSectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _SettingsNotice extends StatelessWidget {
  const _SettingsNotice({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 2),
                Text(message, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsActionTile extends StatelessWidget {
  const _SettingsActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconColor = destructive ? colorScheme.error : colorScheme.primary;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      minLeadingWidth: 32,
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: destructive
            ? TextStyle(color: colorScheme.error, fontWeight: FontWeight.w700)
            : null,
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _SafetyRow extends StatelessWidget {
  const _SafetyRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SelectableText(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _BackupDialog extends StatelessWidget {
  const _BackupDialog({required this.receipt});

  final BackupReceipt receipt;

  Future<void> _share(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    final fileName = _backupShareFileName(receipt.createdAt);
    final file = receipt.path == null
        ? XFile.fromData(
            utf8.encode(receipt.contents),
            mimeType: 'application/json',
          )
        : XFile(receipt.path!);

    await SharePlus.instance.share(
      ShareParams(
        title: 'All Of Me backup',
        subject: 'All Of Me backup',
        text: 'All Of Me backup created ${_formatDateTime(receipt.createdAt)}',
        files: [file],
        fileNameOverrides: [fileName],
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Backup'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 420),
        child: Scrollbar(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SafetyRow(
                  label: 'Created',
                  value: _formatDateTime(receipt.createdAt),
                ),
                if (receipt.path != null)
                  _SafetyRow(label: 'File', value: receipt.path!),
                const SizedBox(height: 8),
                SelectableText(
                  receipt.contents,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () => _share(context),
          icon: const Icon(Icons.ios_share_outlined),
          label: const Text('Share'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        FilledButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: receipt.contents));
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Backup copied.')));
              Navigator.of(context).pop();
            }
          },
          icon: const Icon(Icons.copy),
          label: const Text('Copy'),
        ),
      ],
    );
  }
}

String _backupShareFileName(DateTime createdAt) {
  final safeTimestamp = createdAt
      .toIso8601String()
      .replaceAll(':', '-')
      .replaceAll('.', '-');
  return 'allofme-backup-$safeTimestamp.json';
}

class _ImportBackupDialog extends StatefulWidget {
  const _ImportBackupDialog();

  @override
  State<_ImportBackupDialog> createState() => _ImportBackupDialogState();
}

class _ImportBackupDialogState extends State<_ImportBackupDialog> {
  final TextEditingController _backupController = TextEditingController();

  @override
  void dispose() {
    _backupController.dispose();
    super.dispose();
  }

  void _import() {
    Navigator.of(context).pop(_backupController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Import backup'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: TextField(
          controller: _backupController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Backup JSON'),
          minLines: 8,
          maxLines: 12,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _import, child: const Text('Import')),
      ],
    );
  }
}

class _ConfirmImportDialog extends StatelessWidget {
  const _ConfirmImportDialog({required this.snapshot});

  final AppSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Restore backup?'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SafetyRow(label: 'System', value: snapshot.profile.displayName),
            _SafetyRow(
              label: 'Records',
              value:
                  '${snapshot.members.length} members, ${snapshot.groups.length} groups, ${snapshot.frontSessions.length} sessions, ${snapshot.timeline.length} timeline entries',
            ),
            _SafetyRow(
              label: 'Schema',
              value: snapshot.schemaVersion.toString(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(true),
          icon: const Icon(Icons.restore_outlined),
          label: const Text('Restore'),
        ),
      ],
    );
  }
}

class _ConfirmClearDataDialog extends StatelessWidget {
  const _ConfirmClearDataDialog();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('Clear local data?'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This removes members, groups, front sessions, timeline notes, backups, and profile images stored by this app on this device.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'Export a backup first if you want to keep a copy.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          icon: const Icon(Icons.delete_forever_outlined),
          label: const Text('Clear data'),
        ),
      ],
    );
  }
}

class _FirstRunSetupResult {
  const _FirstRunSetupResult({required this.action, required this.systemName});

  final _FirstRunAction action;
  final String systemName;
}

enum _FirstRunAction { startFresh, useDemoData, importBackup }

class _MemberFormResult {
  const _MemberFormResult({this.member, this.archive});

  final Member? member;
  final bool? archive;
}

class _GroupFormResult {
  const _GroupFormResult({this.group, this.archive});

  final MemberGroup? group;
  final bool? archive;
}

class _DeletedItemReference {
  const _DeletedItemReference(this.kind, this.id);

  final _DeletedItemKind kind;
  final String id;
}

enum _DeletedItemKind { member, group, timelineEntry }

enum _SettingsPrivacyAction {
  createBackup,
  importBackupFile,
  pasteBackupJson,
  openRecentlyDeleted,
  enableAppLock,
  disableAppLock,
  refreshSampleData,
  clearSampleData,
  clearAllData,
}

String _entryTitle(TimelineEntry entry) {
  if (entry.type == 'note') {
    return entry.note ?? entry.action;
  }
  final memberName = entry.memberName;
  return memberName == null ? entry.action : '$memberName - ${entry.action}';
}

String _entrySubtitle(TimelineEntry entry) {
  return _formatTime(entry.createdAt);
}

Duration _sessionDurationWithin(
  FrontSession session,
  DateTime start,
  DateTime end,
) {
  final clippedStart = session.startedAt.isBefore(start)
      ? start
      : session.startedAt;
  final rawEnd = session.endedAt ?? end;
  final clippedEnd = rawEnd.isAfter(end) ? end : rawEnd;

  if (!clippedEnd.isAfter(clippedStart)) {
    return Duration.zero;
  }
  return clippedEnd.difference(clippedStart);
}

String _frontingNameSummary(List<String> names) {
  if (names.isEmpty) {
    return 'No one';
  }
  if (names.length <= 2) {
    return names.join(', ');
  }
  return '${names.take(2).join(', ')} +${names.length - 2}';
}

String _formatDurationCompact(Duration duration) {
  if (duration <= Duration.zero) {
    return '0m';
  }

  final days = duration.inDays;
  final hours = duration.inHours.remainder(24);
  final minutes = duration.inMinutes.remainder(60);

  if (days > 0) {
    return hours > 0 ? '${days}d ${hours}h' : '${days}d';
  }
  if (hours > 0) {
    return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
  }
  if (minutes > 0) {
    return '${minutes}m';
  }
  return '<1m';
}

String _formatDateTime(DateTime value) {
  return '${value.month}/${value.day}/${value.year} ${_formatTime(value)}';
}

String _formatTime(DateTime value) {
  final hour = value.hour == 0
      ? 12
      : value.hour > 12
      ? value.hour - 12
      : value.hour;
  final minute = value.minute.toString().padLeft(2, '0');
  final suffix = value.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $suffix';
}

String _initialFromName(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? '?' : trimmed.characters.first;
}

Uint8List? _imageBytesFromDataUri(String? dataUri) {
  if (dataUri == null || dataUri.isEmpty) {
    return null;
  }

  final marker = dataUri.indexOf('base64,');
  final encoded = marker == -1 ? dataUri : dataUri.substring(marker + 7);
  try {
    return base64Decode(encoded);
  } catch (_) {
    return null;
  }
}

String? _mimeTypeFromPath(String path) {
  final lower = path.toLowerCase();
  if (lower.endsWith('.png')) {
    return 'image/png';
  }
  if (lower.endsWith('.webp')) {
    return 'image/webp';
  }
  if (lower.endsWith('.gif')) {
    return 'image/gif';
  }
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
    return 'image/jpeg';
  }
  return null;
}
