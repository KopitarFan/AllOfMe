part of '../main.dart';

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
  showBetaFeedback,
  chooseThemePalette,
  enableDarkMode,
  disableDarkMode,
  enableAppLock,
  disableAppLock,
  refreshSampleData,
  clearSampleData,
  clearAllData,
}
