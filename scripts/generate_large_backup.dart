import 'dart:convert';
import 'dart:io';

import 'package:all_of_me_demo/models.dart';

void main(List<String> arguments) {
  final options = _GeneratorOptions.fromArguments(arguments);
  final snapshot = _buildSnapshot(options);
  final backupJson = snapshot.toBackupJson();
  final restoredSnapshot = _snapshotFromBackupJson(backupJson);
  final outputFile = File(options.outputPath);

  outputFile.parent.createSync(recursive: true);
  outputFile.writeAsStringSync(backupJson, flush: true);

  final bytes = outputFile.lengthSync();
  stdout.writeln('Wrote ${outputFile.path}');
  stdout.writeln('Backup size: ${_formatBytes(bytes)}');
  stdout.writeln('Members: ${options.memberCount}');
  stdout.writeln('Groups: ${options.groupCount}');
  stdout.writeln('Front sessions: ${options.sessionCount}');
  stdout.writeln('Timeline entries: ${options.timelineCount}');
  stdout.writeln(
    'Validated import: ${restoredSnapshot.members.length} members, '
    '${restoredSnapshot.groups.length} groups, '
    '${restoredSnapshot.frontSessions.length} sessions, '
    '${restoredSnapshot.timeline.length} timeline entries.',
  );
}

AppSnapshot _snapshotFromBackupJson(String rawBackup) {
  final decoded = jsonDecode(rawBackup);
  final root = _mapValue(decoded);
  if (root == null) {
    throw const FormatException('Backup must be a JSON object.');
  }

  final snapshotJson = _mapValue(root['snapshot']) ?? root;
  return AppSnapshot.fromJson(snapshotJson);
}

Map<String, Object?>? _mapValue(Object? value) {
  if (value is Map<String, Object?>) {
    return value;
  }
  if (value is Map) {
    return value.cast<String, Object?>();
  }
  return null;
}

AppSnapshot _buildSnapshot(_GeneratorOptions options) {
  final now = options.now;
  final groups = List<MemberGroup>.generate(options.groupCount, (index) {
    final groupNumber = index + 1;
    return MemberGroup(
      id: 'load-group-$groupNumber',
      name: 'Load group $groupNumber',
      description: 'Generated group for Cloud Save load testing.',
      colorValue: memberColorChoices[index % memberColorChoices.length],
      archived: index > 0 && index % 17 == 0,
      createdAt: now.subtract(Duration(days: 120 - index)),
      updatedAt: now.subtract(Duration(days: index % 14)),
    );
  });

  final members = List<Member>.generate(options.memberCount, (index) {
    final memberNumber = index + 1;
    final primaryGroup = groups[index % groups.length];
    final secondaryGroup = groups[(index + 3) % groups.length];
    return Member(
      id: 'load-member-$memberNumber',
      name: 'Load Member ${memberNumber.toString().padLeft(3, '0')}',
      role: _roles[index % _roles.length],
      note:
          'Generated member for large backup and Cloud Save validation. '
          'Index $memberNumber; group ${primaryGroup.name}.',
      groupIds: [primaryGroup.id, secondaryGroup.id],
      colorValue: memberColorChoices[index % memberColorChoices.length],
      archived: index > 0 && index % 23 == 0,
      createdAt: now.subtract(Duration(days: 100 - (index % 80))),
      updatedAt: now.subtract(Duration(hours: index % 72)),
    );
  });

  final activeMembers = members
      .where((member) => !member.archived)
      .toList(growable: false);
  final frontingMemberIds = activeMembers.take(3).map((member) => member.id);
  final frontSessions = <FrontSession>[];
  final timeline = <TimelineEntry>[];
  final noteBody = _largeNoteBody(options.noteBytes);

  for (var index = 0; index < options.sessionCount; index += 1) {
    final member = activeMembers[index % activeMembers.length];
    final startedAt = now.subtract(Duration(hours: index * 3 + 1));
    final endedAt = startedAt.add(Duration(minutes: 45 + (index % 180)));
    final sessionId = 'load-session-${index + 1}';

    frontSessions.add(
      FrontSession(
        id: sessionId,
        memberId: member.id,
        memberName: member.name,
        startedAt: startedAt,
        endedAt: endedAt.isBefore(now) ? endedAt : null,
      ),
    );

    timeline.add(
      TimelineEntry(
        id: 'load-front-entry-${index + 1}',
        type: 'front',
        action: index % 2 == 0 ? 'Started fronting' : 'Switched front',
        createdAt: startedAt,
        memberId: member.id,
        memberName: member.name,
      ),
    );
  }

  for (var index = 0; index < options.timelineCount; index += 1) {
    final member = activeMembers[(index * 7) % activeMembers.length];
    final createdAt = now.subtract(Duration(minutes: index * 17 + 5));

    timeline.add(
      TimelineEntry(
        id: 'load-note-entry-${index + 1}',
        type: 'note',
        action: 'Added note',
        createdAt: createdAt,
        memberId: member.id,
        memberName: member.name,
        note:
            'Generated load-test note ${index + 1} for ${member.name}. '
            '$noteBody',
        deletedAt: index % 41 == 0
            ? createdAt.add(const Duration(minutes: 3))
            : null,
      ),
    );
  }

  timeline.sort((first, second) => second.createdAt.compareTo(first.createdAt));

  return AppSnapshot(
    schemaVersion: appSchemaVersion,
    profile: SystemProfile(
      displayName: 'All Of Me Load Test',
      description:
          'Generated large backup for simulator/device Cloud Save validation.',
      createdAt: now.subtract(const Duration(days: 120)),
      updatedAt: now,
    ),
    security: const SecuritySettings(appLockEnabled: false),
    members: members,
    groups: groups,
    frontingMemberIds: frontingMemberIds.toList(growable: false),
    frontSessions: frontSessions,
    timeline: timeline,
  );
}

String _largeNoteBody(int targetBytes) {
  const chunk =
      'This is deterministic filler text for backup-size testing. '
      'It avoids personal data and keeps import/restore behavior repeatable. ';
  final buffer = StringBuffer();
  while (buffer.length < targetBytes) {
    buffer.write(chunk);
  }
  return buffer.toString().substring(0, targetBytes);
}

String _formatBytes(int bytes) {
  const units = ['B', 'KiB', 'MiB'];
  var value = bytes.toDouble();
  var unitIndex = 0;
  while (value >= 1024 && unitIndex < units.length - 1) {
    value /= 1024;
    unitIndex += 1;
  }
  return '${value.toStringAsFixed(unitIndex == 0 ? 0 : 2)} ${units[unitIndex]}';
}

class _GeneratorOptions {
  const _GeneratorOptions({
    required this.outputPath,
    required this.memberCount,
    required this.groupCount,
    required this.sessionCount,
    required this.timelineCount,
    required this.noteBytes,
    required this.now,
  });

  final String outputPath;
  final int memberCount;
  final int groupCount;
  final int sessionCount;
  final int timelineCount;
  final int noteBytes;
  final DateTime now;

  factory _GeneratorOptions.fromArguments(List<String> arguments) {
    final values = _parseArguments(arguments);
    return _GeneratorOptions(
      outputPath:
          values['out'] ?? 'test-data/allofme-large-cloud-save-backup.json',
      memberCount: _positiveInt(values, 'members', 80),
      groupCount: _positiveInt(values, 'groups', 12),
      sessionCount: _positiveInt(values, 'sessions', 6000),
      timelineCount: _positiveInt(values, 'timeline', 6500),
      noteBytes: _positiveInt(values, 'note-bytes', 360),
      now: DateTime.utc(2026, 6, 28, 12),
    );
  }
}

Map<String, String> _parseArguments(List<String> arguments) {
  final values = <String, String>{};
  for (var index = 0; index < arguments.length; index += 1) {
    final argument = arguments[index];
    if (argument == '--help' || argument == '-h') {
      _printUsage();
      exit(0);
    }
    if (!argument.startsWith('--')) {
      stderr.writeln('Unexpected argument: $argument');
      _printUsage();
      exit(64);
    }

    final withoutPrefix = argument.substring(2);
    final equalsIndex = withoutPrefix.indexOf('=');
    if (equalsIndex >= 0) {
      values[withoutPrefix.substring(0, equalsIndex)] = withoutPrefix.substring(
        equalsIndex + 1,
      );
      continue;
    }

    if (index + 1 >= arguments.length) {
      stderr.writeln('Missing value for $argument');
      exit(64);
    }
    values[withoutPrefix] = arguments[index + 1];
    index += 1;
  }
  return values;
}

int _positiveInt(Map<String, String> values, String key, int fallback) {
  final rawValue = values[key];
  if (rawValue == null) {
    return fallback;
  }
  final parsed = int.tryParse(rawValue);
  if (parsed == null || parsed <= 0) {
    stderr.writeln('--$key must be a positive integer.');
    exit(64);
  }
  return parsed;
}

void _printUsage() {
  stdout.writeln('Generate an importable All Of Me backup for load testing.');
  stdout.writeln('');
  stdout.writeln('Usage:');
  stdout.writeln('  dart run scripts/generate_large_backup.dart [options]');
  stdout.writeln('');
  stdout.writeln('Options:');
  stdout.writeln('  --out PATH          Output JSON backup path.');
  stdout.writeln('  --members N         Member count. Default: 80.');
  stdout.writeln('  --groups N          Group count. Default: 12.');
  stdout.writeln('  --sessions N        Front session count. Default: 6000.');
  stdout.writeln(
    '  --timeline N        Extra note timeline count. Default: 6500.',
  );
  stdout.writeln(
    '  --note-bytes N      Filler bytes per generated note. Default: 360.',
  );
}

const _roles = [
  'Organizer',
  'Social support',
  'Rest and recovery',
  'Focus',
  'Planning',
  'Creative',
  'Grounding',
  'Errands',
];
