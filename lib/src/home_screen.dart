part of '../main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.store,
    required this.cloudSaveAdapter,
    required this.cloudSaveSession,
    required this.onCloudSaveConnect,
    required this.onCloudSaveDisconnect,
    required this.cloudSavePayloadEncoder,
    required this.cloudSavePayloadDecoder,
    required this.authenticator,
    required this.themeMode,
    required this.themePalette,
    required this.onThemeModeChanged,
    required this.onThemePaletteChanged,
    required this.onToggleThemeMode,
  });

  final AppStore store;
  final CloudSaveAdapter cloudSaveAdapter;
  final CloudSaveSession? cloudSaveSession;
  final Future<void> Function(CloudSaveSession session)? onCloudSaveConnect;
  final Future<void> Function()? onCloudSaveDisconnect;
  final CloudSavePayloadEncoder? cloudSavePayloadEncoder;
  final CloudSavePayloadDecoder? cloudSavePayloadDecoder;
  final AppAuthenticator authenticator;
  final ThemeMode themeMode;
  final AppThemePalette themePalette;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final ValueChanged<AppThemePalette> onThemePaletteChanged;
  final VoidCallback onToggleThemeMode;

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
  _MemberSortMode _memberSortMode = _MemberSortMode.nameAscending;
  bool _showFirstRunGuide = false;

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
          _showFirstRunGuide = isFirstRun;
        });
      }
      if (shouldLock) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _unlockApp();
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
          _showFirstRunGuide = false;
        });
      }
    }
  }

  Future<void> _completeFirstRunSetup(_FirstRunSetupResult result) async {
    final snapshot = _snapshot;
    if (snapshot == null || _isLocked) {
      return;
    }

    switch (result.action) {
      case _FirstRunAction.startFresh:
        await _persist(_firstRunSnapshot(AppSnapshot.empty(), result));
      case _FirstRunAction.useDemoData:
        await _persist(_firstRunSnapshot(AppSnapshot.seeded(), result));
      case _FirstRunAction.importBackup:
        final imported = await _importBackupFile();
        if (!imported) {
          return;
        }
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _showFirstRunGuide = false;
    });
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

  void _setMemberSortMode(_MemberSortMode sortMode) {
    setState(() {
      _memberSortMode = sortMode;
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

  Future<void> _addTimelineNote({bool showNotesAction = true}) async {
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
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Note saved.'),
        action: showNotesAction
            ? SnackBarAction(label: 'View notes', onPressed: _showNotes)
            : null,
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
    final deletedMessage = entry.isNote
        ? 'Note moved to Recently Deleted.'
        : 'Timeline entry moved to Recently Deleted.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(deletedMessage)));
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

  Future<void> _showNotes() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => _NotesScreen(
          entries: () => _snapshot?.activeNotes ?? const <TimelineEntry>[],
          onAddNote: () async {
            await _addTimelineNote(showNotesAction: false);
          },
          onDeleteNote: (entry) async {
            await _deleteTimelineEntry(entry);
          },
        ),
      ),
    );
  }

  Future<void> _showTimeline() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => _TimelineEntriesScreen(
          entries: () =>
              _snapshot?.activeTimelineEntries ?? const <TimelineEntry>[],
          onDeleteEntry: (entry) async {
            await _deleteTimelineEntry(entry);
          },
        ),
      ),
    );
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
      final cloudSaveInfo = widget.cloudSaveAdapter.info;
      CloudSaveMetadata? cloudSaveMetadata;
      String? cloudSaveErrorMessage;
      try {
        cloudSaveMetadata = await widget.cloudSaveAdapter.latestMetadata();
      } catch (_) {
        cloudSaveErrorMessage = 'Remote unavailable';
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _storeInfo = info;
      });

      final action = await showDialog<Object>(
        context: context,
        builder: (context) => _SettingsPrivacyDialog(
          snapshot: snapshot,
          storeInfo: info,
          cloudSaveInfo: cloudSaveInfo,
          cloudSaveMetadata: cloudSaveMetadata,
          cloudSaveErrorMessage: cloudSaveErrorMessage,
          canManageCloudSave: _canManageCloudSave,
          lockStatus: lockStatus,
          themeMode: widget.themeMode,
          themePalette: widget.themePalette,
        ),
      );

      if (action is AppThemePalette) {
        widget.onThemePaletteChanged(action);
        return;
      }
      if (action == null || action is! _SettingsPrivacyAction) {
        return;
      }

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
        case _SettingsPrivacyAction.connectCloudSave:
          await _connectCloudSave();
          return;
        case _SettingsPrivacyAction.disconnectCloudSave:
          await _disconnectCloudSave();
          return;
        case _SettingsPrivacyAction.saveCloudSave:
          await _saveCloudSave();
          return;
        case _SettingsPrivacyAction.restoreCloudSave:
          await _restoreCloudSave();
          return;
        case _SettingsPrivacyAction.openRecentlyDeleted:
          await _showRecentlyDeleted();
          return;
        case _SettingsPrivacyAction.showPrivacyStorageInfo:
          await _showPrivacyStorageInfo(
            snapshot: snapshot,
            storeInfo: info,
            cloudSaveInfo: cloudSaveInfo,
            cloudSaveErrorMessage: cloudSaveErrorMessage,
            cloudSaveMetadata: cloudSaveMetadata,
          );
          return;
        case _SettingsPrivacyAction.showBetaFeedback:
          await _showBetaFeedback();
          return;
        case _SettingsPrivacyAction.enableDarkMode:
          widget.onThemeModeChanged(ThemeMode.dark);
        case _SettingsPrivacyAction.disableDarkMode:
          widget.onThemeModeChanged(ThemeMode.light);
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
      }
    }
  }

  bool get _canManageCloudSave =>
      widget.onCloudSaveConnect != null && widget.onCloudSaveDisconnect != null;

  Future<void> _showPrivacyStorageInfo({
    required AppSnapshot snapshot,
    required AppStoreInfo storeInfo,
    required CloudSaveAdapterInfo cloudSaveInfo,
    required String? cloudSaveErrorMessage,
    required CloudSaveMetadata? cloudSaveMetadata,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) => _PrivacyStorageInfoScreen(
          snapshot: snapshot,
          storeInfo: storeInfo,
          cloudSaveInfo: cloudSaveInfo,
          cloudSaveErrorMessage: cloudSaveErrorMessage,
          cloudSaveMetadata: cloudSaveMetadata,
        ),
      ),
    );
  }

  Future<void> _connectCloudSave() async {
    final onConnect = widget.onCloudSaveConnect;
    if (onConnect == null) {
      return;
    }

    final session = await showDialog<CloudSaveSession>(
      context: context,
      builder: (context) =>
          _CloudSaveConnectionDialog(initialSession: widget.cloudSaveSession),
    );
    if (session == null) {
      return;
    }

    await onConnect(session);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cloud save connected to ${session.accountLabel}.'),
      ),
    );
  }

  Future<void> _disconnectCloudSave() async {
    final onDisconnect = widget.onCloudSaveDisconnect;
    if (onDisconnect == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const _ConfirmDisconnectCloudSaveDialog(),
    );
    if (confirmed != true) {
      return;
    }

    await onDisconnect();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Cloud save disconnected.')));
  }

  Future<void> _showBetaFeedback() async {
    final snapshot = _snapshot;
    if (snapshot == null) {
      return;
    }
    final info = await widget.store.info();
    if (!mounted) {
      return;
    }
    setState(() {
      _storeInfo = info;
    });

    await showDialog<void>(
      context: context,
      builder: (context) =>
          _BetaFeedbackDialog(snapshot: snapshot, storeInfo: info),
    );
  }

  Future<void> _saveCloudSave() async {
    final snapshot = _snapshot;
    if (snapshot == null) {
      return;
    }

    try {
      final payloadEncoder = await _cloudSaveEncoderForSave();
      if (payloadEncoder == null) {
        return;
      }

      setState(() {
        _saving = true;
      });

      final package = await CloudSavePackage.fromBackupJson(
        snapshot.toBackupJson(),
        deviceLabel: 'This device',
        payloadEncoder: payloadEncoder,
      );
      final metadata = await widget.cloudSaveAdapter.saveNow(package);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_cloudSaveLabel()} saved ${_formatDateTime(metadata.createdAt)}.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${_cloudSaveLabel()} failed.')));
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<CloudSavePayloadEncoder?> _cloudSaveEncoderForSave() async {
    final injectedEncoder = widget.cloudSavePayloadEncoder;
    if (injectedEncoder != null) {
      return injectedEncoder;
    }

    final recoveryKey = await showDialog<CloudSaveRecoveryKey>(
      context: context,
      builder: (context) =>
          const _CloudSaveRecoveryKeyDialog(mode: _RecoveryKeyDialogMode.save),
    );
    if (recoveryKey == null) {
      return null;
    }
    return CloudSavePassphrasePayloadCipher(recoveryKey: recoveryKey);
  }

  Future<CloudSavePayloadDecoder?> _cloudSaveDecoderForRestore(
    CloudSavePackage package,
  ) async {
    final injectedDecoder = widget.cloudSavePayloadDecoder;
    if (injectedDecoder != null) {
      return injectedDecoder;
    }
    if (!package.payload.requiresDecoder) {
      return null;
    }

    final recoveryKey = await showDialog<CloudSaveRecoveryKey>(
      context: context,
      builder: (context) => const _CloudSaveRecoveryKeyDialog(
        mode: _RecoveryKeyDialogMode.restore,
      ),
    );
    if (recoveryKey == null) {
      return null;
    }
    return CloudSavePassphrasePayloadCipher(recoveryKey: recoveryKey).decode;
  }

  Future<void> _restoreCloudSave() async {
    try {
      final package = await widget.cloudSaveAdapter.downloadLatest();
      if (!mounted) {
        return;
      }
      if (package == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No ${_cloudSaveLabelLower()} found.')),
        );
        return;
      }

      final decoder = await _cloudSaveDecoderForRestore(package);
      if (!mounted || (package.payload.requiresDecoder && decoder == null)) {
        return;
      }

      final validation = await package.validateForRestore(decoder: decoder);
      if (!mounted) {
        return;
      }
      if (!validation.isValid || validation.backupJson == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              package.payload.requiresDecoder
                  ? 'Recovery key did not unlock this cloud save.'
                  : '${_cloudSaveLabel()} could not restore.',
            ),
          ),
        );
        return;
      }

      await _restoreBackup(
        validation.backupJson!,
        successMessage: '${_cloudSaveLabel()} restored.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_cloudSaveLabel()} could not restore.')),
      );
    }
  }

  String _cloudSaveLabel() {
    return widget.cloudSaveAdapter.info.isRemote
        ? 'Cloud save'
        : 'Cloud save preview';
  }

  String _cloudSaveLabelLower() {
    return widget.cloudSaveAdapter.info.isRemote
        ? 'cloud save'
        : 'cloud save preview';
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
        _showFirstRunGuide = true;
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

  Future<bool> _importBackupFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        return false;
      }

      final file = result.files.single;
      final bytes = file.bytes;
      final rawBackup = bytes == null
          ? await result.xFiles.single.readAsString()
          : utf8.decode(bytes);
      return _restoreBackup(rawBackup);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not open backup.')));
      }
      return false;
    }
  }

  Future<bool> _restoreBackup(
    String rawBackup, {
    String successMessage = 'Backup imported.',
  }) async {
    final snapshot = _snapshot;
    if (snapshot == null) {
      return false;
    }

    try {
      final imported = snapshotFromBackupJson(rawBackup);
      if (!mounted) {
        return false;
      }

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => _ConfirmImportDialog(snapshot: imported),
      );
      if (confirmed != true) {
        return false;
      }

      await widget.store.createBackup(snapshot);
      await _persist(imported);
      if (mounted) {
        setState(() {
          _selectedGroupId = null;
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(successMessage)));
      }
      return true;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Backup import failed.')));
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    final isLocked = snapshot != null && _isLocked;
    final showFirstRunGuide =
        snapshot != null && _showFirstRunGuide && !isLocked;
    final showMenuLabels = MediaQuery.sizeOf(context).width >= 680;

    return Scaffold(
      appBar: showFirstRunGuide
          ? null
          : AppBar(
              title: isLocked ? const Text(appDisplayName) : const _AppBrand(),
              actions: isLocked
                  ? null
                  : [
                      IconButton(
                        onPressed: snapshot == null ? null : _showNotes,
                        icon: const Icon(Icons.sticky_note_2_outlined),
                        tooltip: 'Notes',
                      ),
                      if (showMenuLabels)
                        Tooltip(
                          message: 'Insights',
                          child: TextButton.icon(
                            onPressed: snapshot == null ? null : _showInsights,
                            icon: const Icon(Icons.insights_outlined),
                            label: const Text('Insights'),
                          ),
                        )
                      else
                        IconButton(
                          onPressed: snapshot == null ? null : _showInsights,
                          icon: const Icon(Icons.insights_outlined),
                          tooltip: 'Insights',
                        ),
                      IconButton(
                        onPressed: widget.onToggleThemeMode,
                        icon: Icon(
                          widget.themeMode == ThemeMode.dark
                              ? Icons.light_mode_outlined
                              : Icons.dark_mode_outlined,
                        ),
                        tooltip: widget.themeMode == ThemeMode.dark
                            ? 'Switch to light mode'
                            : 'Switch to dark mode',
                      ),
                      IconButton(
                        onPressed: snapshot == null
                            ? null
                            : _handleAppLockButton,
                        icon: Icon(
                          snapshot?.security.appLockEnabled == true
                              ? Icons.lock_outline
                              : Icons.lock_open_outlined,
                        ),
                        tooltip: 'App lock',
                      ),
                      IconButton(
                        onPressed: snapshot == null
                            ? null
                            : _showSettingsPrivacy,
                        icon: const Icon(Icons.settings_outlined),
                        tooltip: 'Settings and privacy',
                      ),
                      const SizedBox(width: 8),
                    ],
            ),
      body: SafeArea(
        child: snapshot == null
            ? const Center(child: CircularProgressIndicator())
            : showFirstRunGuide
            ? _FirstRunSetupScreen(
                initialName: snapshot.profile.displayName,
                themeMode: widget.themeMode,
                onToggleThemeMode: widget.onToggleThemeMode,
                onComplete: _completeFirstRunSetup,
              )
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
                saving: _saving,
                onEditProfile: _editProfile,
                onEditMember: _showMemberForm,
                onEditGroup: _showGroupForm,
                selectedGroupId: _selectedGroupId,
                memberSortMode: _memberSortMode,
                onSelectGroup: _selectGroup,
                onMemberSortModeChanged: _setMemberSortMode,
                onToggleFront: _toggleFront,
                onAddTimelineNote: _addTimelineNote,
                onShowTimeline: _showTimeline,
                onShowInsights: _showInsights,
                onDeleteTimelineEntry: _deleteTimelineEntry,
              ),
      ),
      floatingActionButton: null,
    );
  }
}

class _AppBrand extends StatelessWidget {
  const _AppBrand();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: appDisplayName,
      child: Icon(Icons.favorite_outline, color: colorScheme.primary, size: 22),
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
