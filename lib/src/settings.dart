part of '../main.dart';

enum _RecoveryKeyDialogMode { save, restore }

class _SettingsPrivacyDialog extends StatelessWidget {
  const _SettingsPrivacyDialog({
    required this.snapshot,
    required this.storeInfo,
    required this.cloudSaveMetadata,
    required this.lockStatus,
    required this.themeMode,
  });

  final AppSnapshot snapshot;
  final AppStoreInfo storeInfo;
  final CloudSaveMetadata? cloudSaveMetadata;
  final AppLockStatus lockStatus;
  final ThemeMode themeMode;

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
                const _SettingsSectionTitle('Privacy'),
                const _SettingsNotice(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy policy',
                  message:
                      'All Of Me stores system data on this device. Export and import are explicit actions.',
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
                const _SettingsSectionTitle('Cloud save preview'),
                const _SettingsNotice(
                  icon: Icons.cloud_queue_outlined,
                  title: 'Preview only',
                  message:
                      'This encrypts a CloudSavePackage with a recovery key and stores it locally until the server exists.',
                ),
                _SafetyRow(
                  label: 'Status',
                  value: cloudSaveMetadata == null
                      ? 'No cloud save yet'
                      : 'Saved ${_formatDateTime(cloudSaveMetadata!.createdAt)}',
                ),
                if (cloudSaveMetadata != null) ...[
                  _SafetyRow(
                    label: 'Schema',
                    value: cloudSaveMetadata!.snapshotSchemaVersion.toString(),
                  ),
                  _SafetyRow(
                    label: 'Size',
                    value: '${cloudSaveMetadata!.payloadByteCount} bytes',
                  ),
                ],
                _SettingsActionTile(
                  icon: Icons.cloud_upload_outlined,
                  title: 'Save now',
                  subtitle:
                      'Encrypt and create a local mock cloud save from this device.',
                  onTap: () => Navigator.of(
                    context,
                  ).pop(_SettingsPrivacyAction.saveCloudSave),
                ),
                _SettingsActionTile(
                  icon: Icons.cloud_download_outlined,
                  title: 'Restore cloud save',
                  subtitle: cloudSaveMetadata == null
                      ? 'Save this device before restoring.'
                      : 'Restore the latest preview save.',
                  onTap: cloudSaveMetadata == null
                      ? null
                      : () => Navigator.of(
                          context,
                        ).pop(_SettingsPrivacyAction.restoreCloudSave),
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
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
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
