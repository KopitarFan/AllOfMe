part of '../main.dart';

enum _RecoveryKeyDialogMode { save, restore }

class _SettingsPrivacyDialog extends StatelessWidget {
  const _SettingsPrivacyDialog({
    required this.snapshot,
    required this.storeInfo,
    required this.cloudSaveInfo,
    required this.cloudSaveMetadata,
    required this.cloudSaveErrorMessage,
    required this.canManageCloudSave,
    required this.lockStatus,
    required this.themeMode,
    required this.themePalette,
  });

  final AppSnapshot snapshot;
  final AppStoreInfo storeInfo;
  final CloudSaveAdapterInfo cloudSaveInfo;
  final CloudSaveMetadata? cloudSaveMetadata;
  final String? cloudSaveErrorMessage;
  final bool canManageCloudSave;
  final AppLockStatus lockStatus;
  final ThemeMode themeMode;
  final AppThemePalette themePalette;

  @override
  Widget build(BuildContext context) {
    final lockEnabled = snapshot.security.appLockEnabled;
    final canChangeLock = lockStatus.isSupported || lockEnabled;
    final darkModeEnabled = themeMode == ThemeMode.dark;
    final hasSampleData = snapshot.frontSessions.any(_isSampleInsightsSession);
    final recoverableCount =
        snapshot.archivedMembers.length +
        snapshot.archivedGroups.length +
        snapshot.deletedTimeline.length;
    final cloudSaveStatus = _cloudSaveStatusLabel(
      cloudSaveInfo: cloudSaveInfo,
      errorMessage: cloudSaveErrorMessage,
    );
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
                const _SettingsSectionTitle('Appearance'),
                _ThemePalettePicker(
                  selectedPalette: themePalette,
                  onSelected: (palette) => Navigator.of(context).pop(palette),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: Icon(
                    darkModeEnabled
                        ? Icons.dark_mode_outlined
                        : Icons.light_mode_outlined,
                  ),
                  title: const Text('Dark mode'),
                  subtitle: Text(darkModeEnabled ? 'On' : 'Off'),
                  value: darkModeEnabled,
                  onChanged: (value) => Navigator.of(context).pop(
                    value
                        ? _SettingsPrivacyAction.enableDarkMode
                        : _SettingsPrivacyAction.disableDarkMode,
                  ),
                ),
                const SizedBox(height: 18),
                const _SettingsSectionTitle('App Lock'),
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
                const _SettingsSectionTitle('Cloud Save'),
                if (canManageCloudSave)
                  _SettingsActionTile(
                    icon: cloudSaveInfo.isRemote
                        ? Icons.link_off_outlined
                        : Icons.cloud_sync_outlined,
                    title: cloudSaveInfo.isRemote
                        ? 'Disconnect cloud save'
                        : 'Connect cloud save',
                    subtitle: cloudSaveInfo.isRemote
                        ? '$cloudSaveStatus - ${cloudSaveInfo.accountLabel ?? cloudSaveInfo.location}'
                        : 'Not connected - save and restore stay on this device.',
                    onTap: () => Navigator.of(context).pop(
                      cloudSaveInfo.isRemote
                          ? _SettingsPrivacyAction.disconnectCloudSave
                          : _SettingsPrivacyAction.connectCloudSave,
                    ),
                  ),
                if (canManageCloudSave && cloudSaveInfo.isRemote)
                  _SettingsActionTile(
                    icon: Icons.link_outlined,
                    title: 'Add another device',
                    subtitle: 'Create a one-time code for a fresh install.',
                    onTap: () => Navigator.of(
                      context,
                    ).pop(_SettingsPrivacyAction.showCloudSaveLinkCode),
                  ),
                _SettingsActionTile(
                  icon: Icons.cloud_upload_outlined,
                  title: 'Save now',
                  subtitle: cloudSaveInfo.isRemote
                      ? 'Create an encrypted restore point from this device.'
                      : 'Encrypt and create a local preview save from this device.',
                  onTap: () => Navigator.of(
                    context,
                  ).pop(_SettingsPrivacyAction.saveCloudSave),
                ),
                _SettingsActionTile(
                  icon: Icons.cloud_download_outlined,
                  title: 'Restore cloud save',
                  subtitle: cloudSaveMetadata == null
                      ? cloudSaveErrorMessage ??
                            (cloudSaveInfo.isRemote
                                ? 'Save this device before restoring.'
                                : 'Create a preview save before restoring.')
                      : 'Latest save: ${_formatDateTime(cloudSaveMetadata!.createdAt)}.',
                  onTap: cloudSaveMetadata == null
                      ? null
                      : () => Navigator.of(
                          context,
                        ).pop(_SettingsPrivacyAction.restoreCloudSave),
                ),
                const SizedBox(height: 18),
                const _SettingsSectionTitle('Backup & Restore'),
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
                const _SettingsSectionTitle('Information'),
                _SettingsActionTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy & storage',
                  subtitle:
                      'Review device storage, records, backups, and cloud-save status.',
                  onTap: () => Navigator.of(
                    context,
                  ).pop(_SettingsPrivacyAction.showPrivacyStorageInfo),
                ),
                _SettingsActionTile(
                  icon: Icons.feedback_outlined,
                  title: 'Beta feedback',
                  subtitle: 'Copy a report template or open support details.',
                  onTap: () => Navigator.of(
                    context,
                  ).pop(_SettingsPrivacyAction.showBetaFeedback),
                ),
                const SizedBox(height: 18),
                const _SettingsSectionTitle('Reset'),
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

class _PrivacyStorageInfoScreen extends StatelessWidget {
  const _PrivacyStorageInfoScreen({
    required this.snapshot,
    required this.storeInfo,
    required this.cloudSaveInfo,
    required this.cloudSaveErrorMessage,
    required this.cloudSaveMetadata,
  });

  final AppSnapshot snapshot;
  final AppStoreInfo storeInfo;
  final CloudSaveAdapterInfo cloudSaveInfo;
  final String? cloudSaveErrorMessage;
  final CloudSaveMetadata? cloudSaveMetadata;

  @override
  Widget build(BuildContext context) {
    final cloudSaveStatus = _cloudSaveStatusLabel(
      cloudSaveInfo: cloudSaveInfo,
      errorMessage: cloudSaveErrorMessage,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & storage')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth > 720
                ? (constraints.maxWidth - 680) / 2
                : 20.0;

            return Scrollbar(
              thumbVisibility: true,
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  20,
                  horizontalPadding,
                  32,
                ),
                children: [
                  const _SettingsSectionTitle('Privacy policy'),
                  const _SettingsNotice(
                    icon: Icons.privacy_tip_outlined,
                    title: 'On this device',
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
                  const _SettingsSectionTitle('Cloud save'),
                  _SettingsNotice(
                    icon: cloudSaveErrorMessage != null
                        ? Icons.cloud_off_outlined
                        : cloudSaveInfo.isRemote
                        ? Icons.cloud_done_outlined
                        : Icons.cloud_queue_outlined,
                    title: cloudSaveStatus,
                    message: cloudSaveErrorMessage != null
                        ? 'The cloud-save endpoint could not be reached. Local data on this device is still available.'
                        : cloudSaveInfo.isRemote
                        ? 'Cloud saves are encrypted with a recovery key before upload. This device remains the source of truth.'
                        : 'Cloud saves are encrypted with a recovery key and stored locally until a remote endpoint is configured.',
                  ),
                  _SafetyRow(label: 'Provider', value: cloudSaveInfo.label),
                  _SafetyRow(label: 'Location', value: cloudSaveInfo.location),
                  if (cloudSaveInfo.accountLabel != null)
                    _SafetyRow(
                      label: 'Account',
                      value: cloudSaveInfo.accountLabel!,
                    ),
                  _SafetyRow(label: 'Connection', value: cloudSaveStatus),
                  _SafetyRow(
                    label: 'Last save',
                    value: cloudSaveMetadata == null
                        ? cloudSaveErrorMessage ?? 'No cloud save yet'
                        : 'Saved ${_formatDateTime(cloudSaveMetadata!.createdAt)}',
                  ),
                  if (cloudSaveMetadata != null) ...[
                    _SafetyRow(
                      label: 'Schema',
                      value: cloudSaveMetadata!.snapshotSchemaVersion
                          .toString(),
                    ),
                    _SafetyRow(
                      label: 'Size',
                      value: '${cloudSaveMetadata!.payloadByteCount} bytes',
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

String _cloudSaveStatusLabel({
  required CloudSaveAdapterInfo cloudSaveInfo,
  required String? errorMessage,
}) {
  if (errorMessage != null) {
    return 'Remote unavailable';
  }
  return cloudSaveInfo.isRemote ? 'Connected' : 'Not connected';
}

String _cloudSaveFailureMessage(String message, Object error) {
  final reference = switch (error) {
    CloudSaveRemoteException(:final supportReference) => supportReference,
    _ => null,
  };
  if (reference == null) {
    return message;
  }
  final separator = RegExp(r'[.!?]$').hasMatch(message) ? ' ' : '. ';
  return '$message${separator}Reference: $reference.';
}

class CloudSaveConnection {
  const CloudSaveConnection({required this.session, required this.accessToken});

  final CloudSaveSession session;
  final String accessToken;
}

enum _CloudSaveConnectionMode { startNew, linkExisting }

class _CloudSaveConnectionDialog extends StatefulWidget {
  const _CloudSaveConnectionDialog({
    this.initialSession,
    required this.registerDevice,
    required this.redeemDeviceLinkCode,
  });

  final CloudSaveSession? initialSession;
  final CloudSaveDeviceRegistrar registerDevice;
  final CloudSaveDeviceLinkRedeemer redeemDeviceLinkCode;

  @override
  State<_CloudSaveConnectionDialog> createState() =>
      _CloudSaveConnectionDialogState();
}

class _CloudSaveConnectionDialogState
    extends State<_CloudSaveConnectionDialog> {
  late final TextEditingController _baseUrlController;
  late final TextEditingController _accountLabelController;
  late final TextEditingController _deviceLabelController;
  late final TextEditingController _accessTokenController;
  late final TextEditingController _linkCodeController;
  _CloudSaveConnectionMode _mode = _CloudSaveConnectionMode.startNew;
  String? _errorText;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final initialSession =
        widget.initialSession ?? defaultCloudSaveConnectionSession();
    _baseUrlController = TextEditingController(text: initialSession.baseUrl);
    _accountLabelController = TextEditingController(
      text: initialSession.accountLabel,
    );
    _deviceLabelController = TextEditingController(text: 'This device');
    _accessTokenController = TextEditingController();
    _linkCodeController = TextEditingController();
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _accountLabelController.dispose();
    _deviceLabelController.dispose();
    _accessTokenController.dispose();
    _linkCodeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }

    late final CloudSaveSession session;
    try {
      session = CloudSaveSession.create(
        baseUrl: _baseUrlController.text,
        accountLabel: _accountLabelController.text,
      );
    } catch (_) {
      setState(() {
        _errorText = 'Enter a valid http or https URL.';
      });
      return;
    }

    if (_mode == _CloudSaveConnectionMode.startNew) {
      final manualAccessToken = _accessTokenController.text.trim();
      if (manualAccessToken.isNotEmpty) {
        Navigator.of(context).pop(
          CloudSaveConnection(session: session, accessToken: manualAccessToken),
        );
        return;
      }
    } else if (_linkCodeController.text.trim().isEmpty) {
      setState(() {
        _errorText = 'Enter a link code.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      final registration = switch (_mode) {
        _CloudSaveConnectionMode.startNew => await widget.registerDevice(
          session,
          deviceLabel: _nullableTrimmed(_deviceLabelController.text),
        ),
        _CloudSaveConnectionMode.linkExisting =>
          await widget.redeemDeviceLinkCode(
            session,
            code: _linkCodeController.text,
            deviceLabel: _nullableTrimmed(_deviceLabelController.text),
          ),
      };
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(
        CloudSaveConnection(session: session, accessToken: registration.token),
      );
    } catch (error) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          final message = _mode == _CloudSaveConnectionMode.linkExisting
              ? 'Could not link this device. Check the server URL and code.'
              : 'Could not register this device. Check the server URL and try again.';
          _errorText = _cloudSaveFailureMessage(message, error);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final modeDescription = _mode == _CloudSaveConnectionMode.startNew
        ? 'Use the default All Of Me Cloud server, or change the URL for a self-hosted server.'
        : 'Enter a one-time code from another connected device.';

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.cloud_sync_outlined),
          SizedBox(width: 10),
          Expanded(child: Text('Connect cloud save')),
        ],
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: MediaQuery.sizeOf(context).height * 0.68,
        ),
        child: Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SettingsNotice(
                  icon: _mode == _CloudSaveConnectionMode.startNew
                      ? Icons.cloud_done_outlined
                      : Icons.link_outlined,
                  title: _mode == _CloudSaveConnectionMode.startNew
                      ? 'All Of Me Cloud is ready'
                      : 'Link an existing cloud save',
                  message: modeDescription,
                ),
                const SizedBox(height: 14),
                SegmentedButton<_CloudSaveConnectionMode>(
                  segments: const [
                    ButtonSegment<_CloudSaveConnectionMode>(
                      value: _CloudSaveConnectionMode.startNew,
                      label: Text('New save'),
                      icon: Icon(Icons.cloud_sync_outlined),
                    ),
                    ButtonSegment<_CloudSaveConnectionMode>(
                      value: _CloudSaveConnectionMode.linkExisting,
                      label: Text('Link device'),
                      icon: Icon(Icons.link_outlined),
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: _isSubmitting
                      ? null
                      : (selection) {
                          setState(() {
                            _mode = selection.single;
                            _errorText = null;
                          });
                        },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _baseUrlController,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Server URL',
                    hintText: officialCloudSaveBaseUrl,
                    helperText:
                        'Already filled for All Of Me Cloud. Change only for another server.',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _accountLabelController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Account label',
                    hintText: officialCloudSaveAccountLabel,
                    helperText: 'Shown on this device only.',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _deviceLabelController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Device label',
                    hintText: 'This device',
                    helperText: 'Helps you recognize this device later.',
                  ),
                ),
                const SizedBox(height: 12),
                if (_mode == _CloudSaveConnectionMode.linkExisting)
                  TextField(
                    controller: _linkCodeController,
                    textInputAction: TextInputAction.done,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Link code',
                      hintText: 'AOM-12345-ABCDE',
                      helperText:
                          'Create this code on a device already connected to Cloud Save.',
                    ),
                    onSubmitted: (_) => _submit(),
                  )
                else
                  TextField(
                    controller: _accessTokenController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Access token (optional)',
                      hintText: 'Leave blank to register this device',
                      helperText:
                          'Advanced: paste a token only for a manual or third-party setup.',
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                if (_errorText != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorText!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  _mode == _CloudSaveConnectionMode.startNew
                      ? 'Connect'
                      : 'Link device',
                ),
        ),
      ],
    );
  }
}

class _CloudSaveDeviceLinkCodeDialog extends StatelessWidget {
  const _CloudSaveDeviceLinkCodeDialog(this.linkCode);

  final CloudSaveDeviceLinkCode linkCode;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.link_outlined),
          SizedBox(width: 10),
          Expanded(child: Text('Add another device')),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SettingsNotice(
              icon: Icons.phone_iphone_outlined,
              title: 'Use this on the new device',
              message:
                  'Open Connect cloud save, choose Link device, enter this code, then restore with the recovery key.',
            ),
            const SizedBox(height: 16),
            Center(
              child: SelectableText(
                linkCode.code,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text('Expires ${_formatDateTime(linkCode.expiresAt.toLocal())}.'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
        FilledButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: linkCode.code));
            if (!context.mounted) {
              return;
            }
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.copy_outlined),
          label: const Text('Copy code'),
        ),
      ],
    );
  }
}

class _ConfirmDisconnectCloudSaveDialog extends StatelessWidget {
  const _ConfirmDisconnectCloudSaveDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Disconnect cloud save?'),
      content: const Text(
        'This removes the cloud-save connection from this device. Local data stays on this device.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Disconnect'),
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

class _ThemePalettePicker extends StatelessWidget {
  const _ThemePalettePicker({
    required this.selectedPalette,
    required this.onSelected,
  });

  final AppThemePalette selectedPalette;
  final ValueChanged<AppThemePalette> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Theme', style: Theme.of(context).textTheme.labelLarge),
            const Spacer(),
            Text(
              selectedPalette.label,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 48,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final palette in AppThemePalette.values) ...[
                  _ThemePaletteSwatch(
                    palette: palette,
                    selected: palette == selectedPalette,
                    onSelected: () => onSelected(palette),
                  ),
                  if (palette != AppThemePalette.values.last)
                    const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ThemePaletteSwatch extends StatelessWidget {
  const _ThemePaletteSwatch({
    required this.palette,
    required this.selected,
    required this.onSelected,
  });

  final AppThemePalette palette;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final lightScheme = _appColorScheme(palette, Brightness.light);
    final darkScheme = _appColorScheme(palette, Brightness.dark);

    return Tooltip(
      message: selected ? '${palette.label} selected' : palette.label,
      child: Semantics(
        button: true,
        selected: selected,
        label: palette.label,
        child: InkWell(
          onTap: onSelected,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            key: ValueKey('theme-palette-${palette.id}'),
            width: 48,
            height: 44,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected
                    ? colorScheme.primary
                    : colorScheme.outlineVariant,
                width: selected ? 2 : 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Positioned.fill(
                  child: _ThemePaletteGradientPreview(
                    key: ValueKey('theme-palette-preview-${palette.id}'),
                    palette: palette,
                    lightScheme: lightScheme,
                    darkScheme: darkScheme,
                    height: 36,
                    showDots: false,
                  ),
                ),
                if (selected)
                  Align(
                    alignment: Alignment.center,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withValues(alpha: 0.88),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemePaletteGradientPreview extends StatelessWidget {
  const _ThemePaletteGradientPreview({
    super.key,
    required this.palette,
    required this.lightScheme,
    required this.darkScheme,
    this.height = 82,
    this.showDots = true,
  });

  final AppThemePalette palette;
  final ColorScheme lightScheme;
  final ColorScheme darkScheme;
  final double height;
  final bool showDots;

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(context).colorScheme.outlineVariant;

    return Container(
      key: ValueKey('theme-palette-gradient-${palette.id}'),
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: outline),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            palette.lightScaffold,
            lightScheme.primaryContainer,
            palette.seedColor,
            lightScheme.primary,
            palette.seedColor,
            darkScheme.secondary,
            darkScheme.primaryContainer,
            palette.darkScaffold,
          ],
          stops: const [0, 0.16, 0.28, 0.42, 0.56, 0.7, 0.84, 1],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: showDots
          ? Padding(
              padding: const EdgeInsets.all(7),
              child: Align(
                alignment: Alignment.bottomRight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: lightScheme.surface.withValues(alpha: 0.84),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: lightScheme.outlineVariant),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ThemePaletteDot(
                          key: ValueKey('theme-palette-seed-${palette.id}'),
                          color: palette.seedColor,
                        ),
                        _ThemePaletteDot(color: lightScheme.primary),
                        _ThemePaletteDot(color: lightScheme.secondary),
                        _ThemePaletteDot(color: darkScheme.primaryContainer),
                        _ThemePaletteDot(
                          key: ValueKey(
                            'theme-palette-background-${palette.id}',
                          ),
                          color: palette.darkScaffold,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

class _ThemePaletteDot extends StatelessWidget {
  const _ThemePaletteDot({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      margin: const EdgeInsets.only(left: 3),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
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
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconColor = destructive ? colorScheme.error : colorScheme.primary;
    final enabled = onTap != null;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      minLeadingWidth: 32,
      enabled: enabled,
      leading: Icon(icon, color: enabled ? iconColor : null),
      title: Text(
        title,
        style: destructive && enabled
            ? TextStyle(color: colorScheme.error, fontWeight: FontWeight.w700)
            : null,
      ),
      subtitle: Text(subtitle),
      trailing: enabled ? const Icon(Icons.chevron_right) : null,
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

class _BetaFeedbackDialog extends StatelessWidget {
  const _BetaFeedbackDialog({required this.snapshot, required this.storeInfo});

  final AppSnapshot snapshot;
  final AppStoreInfo storeInfo;

  String get _feedbackTemplate {
    return [
      'All Of Me beta feedback',
      '',
      'System name: ${snapshot.profile.displayName}',
      'Storage: ${storeInfo.label}',
      'Records: ${snapshot.members.length} members, ${snapshot.groups.length} groups, ${snapshot.frontSessions.length} sessions, ${snapshot.timeline.length} timeline entries',
      '',
      'What I was trying to do:',
      '',
      'What happened:',
      '',
      'What I expected:',
      '',
      'Does it happen every time?',
      '',
      'Device model and iOS version:',
      '',
      'Screenshots or screen recording attached? ',
    ].join('\n');
  }

  Future<void> _copyTemplate(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _feedbackTemplate));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Feedback template copied.')));
  }

  Future<void> _shareTemplate(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        title: 'All Of Me beta feedback',
        subject: 'All Of Me beta feedback',
        text:
            '$_feedbackTemplate\n\nSupport: $_supportUrl\nIssues: $_issuesUrl',
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.feedback_outlined),
          SizedBox(width: 10),
          Expanded(child: Text('Beta feedback')),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SettingsNotice(
                icon: Icons.science_outlined,
                title: 'Testing All Of Me',
                message:
                    'Use TestFlight feedback for beta issues, or copy this template into GitHub Issues or your support message.',
              ),
              const SizedBox(height: 14),
              const _SettingsSectionTitle('Support links'),
              _SafetyRow(label: 'Support', value: _supportUrl),
              _SafetyRow(label: 'Issues', value: _issuesUrl),
              const SizedBox(height: 14),
              const _SettingsSectionTitle('Before sending'),
              Text(
                'Avoid sharing backups, screenshots, member details, or timeline notes unless you intentionally choose to include them for support.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () => _shareTemplate(context),
          icon: const Icon(Icons.ios_share_outlined),
          label: const Text('Share'),
        ),
        FilledButton.icon(
          onPressed: () => _copyTemplate(context),
          icon: const Icon(Icons.copy_outlined),
          label: const Text('Copy template'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
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

class _CloudSaveRecoveryKeyDialog extends StatefulWidget {
  const _CloudSaveRecoveryKeyDialog({required this.mode});

  final _RecoveryKeyDialogMode mode;

  @override
  State<_CloudSaveRecoveryKeyDialog> createState() =>
      _CloudSaveRecoveryKeyDialogState();
}

class _CloudSaveRecoveryKeyDialogState
    extends State<_CloudSaveRecoveryKeyDialog> {
  final TextEditingController _recoveryKeyController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  String? _errorMessage;
  bool _obscureText = true;

  bool get _isSaveMode => widget.mode == _RecoveryKeyDialogMode.save;

  @override
  void dispose() {
    _recoveryKeyController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    final rawPassphrase = _recoveryKeyController.text;
    if (_isSaveMode && rawPassphrase.trim() != _confirmController.text.trim()) {
      setState(() {
        _errorMessage = 'Recovery keys do not match.';
      });
      return;
    }

    try {
      Navigator.of(
        context,
      ).pop(CloudSaveRecoveryKey.fromPassphrase(rawPassphrase));
    } on FormatException catch (error) {
      setState(() {
        _errorMessage = error.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isSaveMode ? 'Set recovery key' : 'Enter recovery key';
    final message = _isSaveMode
        ? 'Choose a phrase you can enter on another device. All Of Me does not store this phrase.'
        : 'Enter the phrase used when this cloud save was created.';

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.key_outlined),
          const SizedBox(width: 10),
          Expanded(child: Text(title)),
        ],
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: MediaQuery.sizeOf(context).height * 0.62,
        ),
        child: Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isSaveMode) ...[
                  const _SettingsNotice(
                    icon: Icons.lock_outline,
                    title: 'Keep this key safe',
                    message:
                        'You will need it to restore on this or another device. All Of Me cannot recover it for you.',
                  ),
                  const SizedBox(height: 14),
                ],
                Text(message, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 14),
                TextField(
                  controller: _recoveryKeyController,
                  autofocus: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  keyboardType: TextInputType.visiblePassword,
                  obscureText: _obscureText,
                  smartDashesType: SmartDashesType.disabled,
                  smartQuotesType: SmartQuotesType.disabled,
                  textCapitalization: TextCapitalization.none,
                  decoration: InputDecoration(
                    labelText: 'Recovery key',
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                      icon: Icon(
                        _obscureText
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      tooltip: _obscureText
                          ? 'Show recovery key'
                          : 'Hide recovery key',
                    ),
                  ),
                  onSubmitted: (_) {
                    if (!_isSaveMode) {
                      _submit();
                    }
                  },
                ),
                if (_isSaveMode) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _confirmController,
                    autocorrect: false,
                    enableSuggestions: false,
                    keyboardType: TextInputType.visiblePassword,
                    obscureText: _obscureText,
                    smartDashesType: SmartDashesType.disabled,
                    smartQuotesType: SmartQuotesType.disabled,
                    textCapitalization: TextCapitalization.none,
                    decoration: const InputDecoration(
                      labelText: 'Confirm recovery key',
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'Use at least $cloudSaveRecoveryKeyMinLength characters.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: Icon(_isSaveMode ? Icons.cloud_upload_outlined : Icons.key),
          label: Text(_isSaveMode ? 'Save encrypted' : 'Unlock'),
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
