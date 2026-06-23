import 'dart:convert';

const int appSchemaVersion = 4;
const double defaultProfileImageScale = 1.0;
const double defaultProfileImageOffset = 0.0;
const String appDisplayName = 'All Of Me';
const String legacyAppDisplayName = 'AllOfMe';

const List<int> memberColorChoices = [
  0xFF24786D,
  0xFFD86F45,
  0xFF5B6CFF,
  0xFF8B5CF6,
  0xFFE0A11B,
  0xFFB64B6B,
  0xFF2F80A0,
  0xFF4F6F52,
];

class SystemProfile {
  const SystemProfile({
    required this.displayName,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  final String displayName;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;

  SystemProfile copyWith({
    String? displayName,
    String? description,
    DateTime? updatedAt,
  }) {
    return SystemProfile(
      displayName: displayName ?? this.displayName,
      description: description ?? this.description,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'displayName': displayName,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory SystemProfile.fromJson(Map<String, Object?> json) {
    final now = DateTime.now();
    final displayName = _stringValue(json['displayName'], appDisplayName);
    return SystemProfile(
      displayName: normalizeSystemDisplayName(displayName),
      description: _stringValue(json['description'], 'Local-only system'),
      createdAt: _dateValue(json['createdAt'], now),
      updatedAt: _dateValue(json['updatedAt'], now),
    );
  }
}

String normalizeSystemDisplayName(String displayName) {
  if (displayName.trim() == legacyAppDisplayName) {
    return appDisplayName;
  }
  return displayName;
}

class Member {
  const Member({
    required this.id,
    required this.name,
    required this.role,
    required this.note,
    required this.groupIds,
    required this.colorValue,
    required this.archived,
    required this.createdAt,
    required this.updatedAt,
    this.profileImageId,
    this.profileImageDataUri,
    this.profileImageScale = defaultProfileImageScale,
    this.profileImageOffsetX = defaultProfileImageOffset,
    this.profileImageOffsetY = defaultProfileImageOffset,
  });

  final String id;
  final String name;
  final String role;
  final String note;
  final List<String> groupIds;
  final int colorValue;
  final bool archived;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? profileImageId;
  final String? profileImageDataUri;
  final double profileImageScale;
  final double profileImageOffsetX;
  final double profileImageOffsetY;

  String get initial => name.trim().isEmpty ? '?' : name.trim()[0];

  Member copyWith({
    String? name,
    String? role,
    String? note,
    List<String>? groupIds,
    int? colorValue,
    bool? archived,
    DateTime? updatedAt,
    Object? profileImageId = _copySentinel,
    Object? profileImageDataUri = _copySentinel,
    double? profileImageScale,
    double? profileImageOffsetX,
    double? profileImageOffsetY,
  }) {
    return Member(
      id: id,
      name: name ?? this.name,
      role: role ?? this.role,
      note: note ?? this.note,
      groupIds: groupIds ?? this.groupIds,
      colorValue: colorValue ?? this.colorValue,
      archived: archived ?? this.archived,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      profileImageId: profileImageId == _copySentinel
          ? this.profileImageId
          : profileImageId as String?,
      profileImageDataUri: profileImageDataUri == _copySentinel
          ? this.profileImageDataUri
          : profileImageDataUri as String?,
      profileImageScale: profileImageScale ?? this.profileImageScale,
      profileImageOffsetX: profileImageOffsetX ?? this.profileImageOffsetX,
      profileImageOffsetY: profileImageOffsetY ?? this.profileImageOffsetY,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'note': note,
      'groupIds': groupIds,
      'colorValue': colorValue,
      'archived': archived,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'profileImageId': profileImageId,
      'profileImageDataUri': profileImageDataUri,
      'profileImageScale': profileImageScale,
      'profileImageOffsetX': profileImageOffsetX,
      'profileImageOffsetY': profileImageOffsetY,
    };
  }

  factory Member.fromJson(Map<String, Object?> json) {
    final now = DateTime.now();
    return Member(
      id: _stringValue(json['id'], _newId('member')),
      name: _stringValue(json['name'], 'New member'),
      role: _stringValue(json['role'], 'Member'),
      note: _stringValue(json['note'], ''),
      groupIds: _listValue(
        json['groupIds'],
      ).whereType<String>().toList(growable: false),
      colorValue: _intValue(json['colorValue'], memberColorChoices.first),
      archived: json['archived'] == true,
      createdAt: _dateValue(json['createdAt'], now),
      updatedAt: _dateValue(json['updatedAt'], now),
      profileImageId: _nullableString(json['profileImageId']),
      profileImageDataUri: _nullableString(json['profileImageDataUri']),
      profileImageScale: _doubleValue(
        json['profileImageScale'],
        defaultProfileImageScale,
      ),
      profileImageOffsetX: _doubleValue(
        json['profileImageOffsetX'],
        defaultProfileImageOffset,
      ),
      profileImageOffsetY: _doubleValue(
        json['profileImageOffsetY'],
        defaultProfileImageOffset,
      ),
    );
  }
}

class MemberGroup {
  const MemberGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.colorValue,
    required this.archived,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String description;
  final int colorValue;
  final bool archived;
  final DateTime createdAt;
  final DateTime updatedAt;

  MemberGroup copyWith({
    String? name,
    String? description,
    int? colorValue,
    bool? archived,
    DateTime? updatedAt,
  }) {
    return MemberGroup(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      colorValue: colorValue ?? this.colorValue,
      archived: archived ?? this.archived,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'colorValue': colorValue,
      'archived': archived,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory MemberGroup.fromJson(Map<String, Object?> json) {
    final now = DateTime.now();
    return MemberGroup(
      id: _stringValue(json['id'], _newId('group')),
      name: _stringValue(json['name'], 'Group'),
      description: _stringValue(json['description'], ''),
      colorValue: _intValue(json['colorValue'], memberColorChoices.first),
      archived: json['archived'] == true,
      createdAt: _dateValue(json['createdAt'], now),
      updatedAt: _dateValue(json['updatedAt'], now),
    );
  }
}

class TimelineEntry {
  const TimelineEntry({
    required this.id,
    required this.type,
    required this.action,
    required this.createdAt,
    this.memberId,
    this.memberName,
    this.note,
    this.deletedAt,
  });

  final String id;
  final String type;
  final String action;
  final DateTime createdAt;
  final String? memberId;
  final String? memberName;
  final String? note;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  TimelineEntry copyWith({Object? deletedAt = _copySentinel}) {
    return TimelineEntry(
      id: id,
      type: type,
      action: action,
      createdAt: createdAt,
      memberId: memberId,
      memberName: memberName,
      note: note,
      deletedAt: deletedAt == _copySentinel
          ? this.deletedAt
          : deletedAt as DateTime?,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'type': type,
      'action': action,
      'createdAt': createdAt.toIso8601String(),
      'memberId': memberId,
      'memberName': memberName,
      'note': note,
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  factory TimelineEntry.fromJson(Map<String, Object?> json) {
    return TimelineEntry(
      id: _stringValue(json['id'], _newId('entry')),
      type: _stringValue(json['type'], 'front'),
      action: _stringValue(json['action'], 'Recorded event'),
      createdAt: _dateValue(json['createdAt'], DateTime.now()),
      memberId: _nullableString(json['memberId']),
      memberName: _nullableString(json['memberName']),
      note: _nullableString(json['note']),
      deletedAt: _nullableDateValue(json['deletedAt']),
    );
  }
}

class FrontSession {
  const FrontSession({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.startedAt,
    this.endedAt,
  });

  final String id;
  final String memberId;
  final String memberName;
  final DateTime startedAt;
  final DateTime? endedAt;

  bool get isOpen => endedAt == null;

  FrontSession copyWith({
    String? memberName,
    DateTime? startedAt,
    Object? endedAt = _copySentinel,
  }) {
    return FrontSession(
      id: id,
      memberId: memberId,
      memberName: memberName ?? this.memberName,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt == _copySentinel ? this.endedAt : endedAt as DateTime?,
    );
  }

  Duration durationUntil(DateTime now) {
    final end = endedAt ?? now;
    if (!end.isAfter(startedAt)) {
      return Duration.zero;
    }
    return end.difference(startedAt);
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'memberId': memberId,
      'memberName': memberName,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
    };
  }

  factory FrontSession.fromJson(Map<String, Object?> json) {
    final now = DateTime.now();
    final memberId = _stringValue(json['memberId'], 'unknown-member');
    final memberName = _stringValue(json['memberName'], 'Unknown member');
    final startedAt = _dateValue(json['startedAt'], now);

    return FrontSession(
      id: _stringValue(json['id'], _sessionId(memberId, startedAt)),
      memberId: memberId,
      memberName: memberName,
      startedAt: startedAt,
      endedAt: _nullableDateValue(json['endedAt']),
    );
  }
}

class SecuritySettings {
  const SecuritySettings({required this.appLockEnabled});

  final bool appLockEnabled;

  SecuritySettings copyWith({bool? appLockEnabled}) {
    return SecuritySettings(
      appLockEnabled: appLockEnabled ?? this.appLockEnabled,
    );
  }

  Map<String, Object?> toJson() {
    return {'appLockEnabled': appLockEnabled};
  }

  factory SecuritySettings.fromJson(Map<String, Object?> json) {
    return SecuritySettings(appLockEnabled: json['appLockEnabled'] == true);
  }
}

class AppSnapshot {
  AppSnapshot({
    required this.schemaVersion,
    required this.profile,
    required this.security,
    required List<Member> members,
    required List<MemberGroup> groups,
    required List<String> frontingMemberIds,
    required List<FrontSession> frontSessions,
    required List<TimelineEntry> timeline,
  }) : members = List.unmodifiable(members),
       groups = List.unmodifiable(groups),
       frontingMemberIds = List.unmodifiable(frontingMemberIds),
       frontSessions = List.unmodifiable(frontSessions),
       timeline = List.unmodifiable(timeline);

  final int schemaVersion;
  final SystemProfile profile;
  final SecuritySettings security;
  final List<Member> members;
  final List<MemberGroup> groups;
  final List<String> frontingMemberIds;
  final List<FrontSession> frontSessions;
  final List<TimelineEntry> timeline;

  List<Member> get activeMembers =>
      members.where((member) => !member.archived).toList(growable: false);

  List<Member> get archivedMembers =>
      members.where((member) => member.archived).toList(growable: false);

  List<MemberGroup> get activeGroups =>
      groups.where((group) => !group.archived).toList(growable: false);

  List<MemberGroup> get archivedGroups =>
      groups.where((group) => group.archived).toList(growable: false);

  List<TimelineEntry> get activeTimeline =>
      timeline.where((entry) => !entry.isDeleted).toList(growable: false);

  List<TimelineEntry> get deletedTimeline =>
      timeline.where((entry) => entry.isDeleted).toList(growable: false);

  AppSnapshot copyWith({
    SystemProfile? profile,
    SecuritySettings? security,
    List<Member>? members,
    List<MemberGroup>? groups,
    List<String>? frontingMemberIds,
    List<FrontSession>? frontSessions,
    List<TimelineEntry>? timeline,
  }) {
    return AppSnapshot(
      schemaVersion: schemaVersion,
      profile: profile ?? this.profile,
      security: security ?? this.security,
      members: members ?? this.members,
      groups: groups ?? this.groups,
      frontingMemberIds: frontingMemberIds ?? this.frontingMemberIds,
      frontSessions: frontSessions ?? this.frontSessions,
      timeline: timeline ?? this.timeline,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'profile': profile.toJson(),
      'security': security.toJson(),
      'members': members.map((member) => member.toJson()).toList(),
      'groups': groups.map((group) => group.toJson()).toList(),
      'frontingMemberIds': frontingMemberIds,
      'frontSessions': frontSessions
          .map((session) => session.toJson())
          .toList(),
      'timeline': timeline.map((entry) => entry.toJson()).toList(),
    };
  }

  String toBackupJson() {
    return const JsonEncoder.withIndent('  ').convert({
      'app': appDisplayName,
      'exportedAt': DateTime.now().toIso8601String(),
      'snapshot': toJson(),
    });
  }

  factory AppSnapshot.fromJson(Map<String, Object?> json) {
    final seeded = AppSnapshot.seeded();
    final profileJson = _mapValue(json['profile']);
    final securityJson = _mapValue(json['security']);
    final memberJson = _listValue(json['members']);
    final hasGroupsKey = json.containsKey('groups');
    final groupJson = _listValue(json['groups']);
    final frontingJson = _listValue(json['frontingMemberIds']);
    final frontSessionJson = _listValue(json['frontSessions']);
    final timelineJson = _listValue(json['timeline']);
    final members = memberJson
        .map(_mapValue)
        .whereType<Map<String, Object?>>()
        .map(Member.fromJson)
        .map(hasGroupsKey ? (member) => member : _backfillSeededGroupIds)
        .toList();
    final groups = hasGroupsKey
        ? groupJson
              .map(_mapValue)
              .whereType<Map<String, Object?>>()
              .map(MemberGroup.fromJson)
              .toList()
        : seeded.groups;
    final frontingMemberIds = frontingJson
        .map((value) => value is String ? value : null)
        .whereType<String>()
        .toList();
    final timeline = timelineJson
        .map(_mapValue)
        .whereType<Map<String, Object?>>()
        .map(TimelineEntry.fromJson)
        .toList();
    final frontSessions = json.containsKey('frontSessions')
        ? frontSessionJson
              .map(_mapValue)
              .whereType<Map<String, Object?>>()
              .map(FrontSession.fromJson)
              .toList()
        : _legacyFrontSessions(frontingMemberIds, timeline, members);

    return AppSnapshot(
      schemaVersion: _intValue(json['schemaVersion'], appSchemaVersion),
      profile: profileJson == null
          ? seeded.profile
          : SystemProfile.fromJson(profileJson),
      security: securityJson == null
          ? const SecuritySettings(appLockEnabled: false)
          : SecuritySettings.fromJson(securityJson),
      members: members,
      groups: groups,
      frontingMemberIds: frontingMemberIds,
      frontSessions: frontSessions,
      timeline: timeline,
    );
  }

  factory AppSnapshot.seeded([DateTime? timestamp]) {
    final now = timestamp ?? DateTime.now();
    final mara = Member(
      id: 'member-mara',
      name: 'Mara',
      role: 'Organizer',
      note: 'Keeps the day moving.',
      groupIds: const ['group-daily'],
      colorValue: 0xFF24786D,
      archived: false,
      createdAt: now,
      updatedAt: now,
    );
    final sol = Member(
      id: 'member-sol',
      name: 'Sol',
      role: 'Social',
      note: 'Best for calls and errands.',
      groupIds: const ['group-social'],
      colorValue: 0xFFD86F45,
      archived: false,
      createdAt: now,
      updatedAt: now,
    );
    final river = Member(
      id: 'member-river',
      name: 'River',
      role: 'Rest',
      note: 'Likes quiet rooms.',
      groupIds: const ['group-rest'],
      colorValue: 0xFF5B6CFF,
      archived: false,
      createdAt: now,
      updatedAt: now,
    );

    final seededFrontStartedAt = DateTime(2026, 5, 28, 9, 20);

    return AppSnapshot(
      schemaVersion: appSchemaVersion,
      profile: SystemProfile(
        displayName: appDisplayName,
        description: 'Local-only system',
        createdAt: now,
        updatedAt: now,
      ),
      security: const SecuritySettings(appLockEnabled: false),
      members: [mara, sol, river],
      groups: [
        MemberGroup(
          id: 'group-daily',
          name: 'Daily',
          description: 'Everyday support and routines',
          colorValue: 0xFF24786D,
          archived: false,
          createdAt: now,
          updatedAt: now,
        ),
        MemberGroup(
          id: 'group-social',
          name: 'Social',
          description: 'Calls, errands, and people',
          colorValue: 0xFFD86F45,
          archived: false,
          createdAt: now,
          updatedAt: now,
        ),
        MemberGroup(
          id: 'group-rest',
          name: 'Rest',
          description: 'Quiet and recovery',
          colorValue: 0xFF5B6CFF,
          archived: false,
          createdAt: now,
          updatedAt: now,
        ),
      ],
      frontingMemberIds: [mara.id],
      frontSessions: [
        FrontSession(
          id: 'session-seed-front',
          memberId: mara.id,
          memberName: mara.name,
          startedAt: seededFrontStartedAt,
        ),
      ],
      timeline: [
        TimelineEntry(
          id: 'entry-seed-front',
          type: 'front',
          action: 'Started fronting',
          memberId: mara.id,
          memberName: mara.name,
          createdAt: seededFrontStartedAt,
        ),
      ],
    );
  }

  factory AppSnapshot.empty([DateTime? timestamp]) {
    final now = timestamp ?? DateTime.now();
    return AppSnapshot(
      schemaVersion: appSchemaVersion,
      profile: SystemProfile(
        displayName: appDisplayName,
        description: 'Local-only system',
        createdAt: now,
        updatedAt: now,
      ),
      security: const SecuritySettings(appLockEnabled: false),
      members: const [],
      groups: const [],
      frontingMemberIds: const [],
      frontSessions: const [],
      timeline: const [],
    );
  }
}

String createId(String prefix) => _newId(prefix);

const Object _copySentinel = Object();

const Map<String, List<String>> _seededGroupIdsByMemberId = {
  'member-mara': ['group-daily'],
  'member-sol': ['group-social'],
  'member-river': ['group-rest'],
};

Member _backfillSeededGroupIds(Member member) {
  if (member.groupIds.isNotEmpty) {
    return member;
  }
  final groupIds = _seededGroupIdsByMemberId[member.id];
  if (groupIds == null) {
    return member;
  }
  return member.copyWith(groupIds: groupIds);
}

List<FrontSession> _legacyFrontSessions(
  List<String> frontingMemberIds,
  List<TimelineEntry> timeline,
  List<Member> members,
) {
  final membersById = {for (final member in members) member.id: member};

  return frontingMemberIds
      .map((memberId) {
        final member = membersById[memberId];
        final startedAt = _legacyFrontStartedAt(
          memberId: memberId,
          timeline: timeline,
          fallback: member?.updatedAt ?? DateTime.now(),
        );
        final memberName =
            member?.name ?? _legacyFrontMemberName(memberId, timeline);

        return FrontSession(
          id: _sessionId(memberId, startedAt),
          memberId: memberId,
          memberName: memberName,
          startedAt: startedAt,
        );
      })
      .toList(growable: false);
}

DateTime _legacyFrontStartedAt({
  required String memberId,
  required List<TimelineEntry> timeline,
  required DateTime fallback,
}) {
  DateTime? latest;
  for (final entry in timeline) {
    if (entry.type != 'front' ||
        entry.memberId != memberId ||
        entry.action != 'Started fronting') {
      continue;
    }
    if (latest == null || entry.createdAt.isAfter(latest)) {
      latest = entry.createdAt;
    }
  }
  return latest ?? fallback;
}

String _legacyFrontMemberName(String memberId, List<TimelineEntry> timeline) {
  for (final entry in timeline) {
    if (entry.memberId == memberId && entry.memberName != null) {
      return entry.memberName!;
    }
  }
  return 'Unknown member';
}

String _sessionId(String value, DateTime startedAt) {
  return 'session-$value-${startedAt.microsecondsSinceEpoch}';
}

String _newId(String prefix) {
  return '$prefix-${DateTime.now().microsecondsSinceEpoch}';
}

String _stringValue(Object? value, String fallback) {
  if (value is String && value.trim().isNotEmpty) {
    return value;
  }
  return fallback;
}

String? _nullableString(Object? value) {
  if (value is String && value.trim().isNotEmpty) {
    return value;
  }
  return null;
}

int _intValue(Object? value, int fallback) {
  if (value is int) {
    return value;
  }
  return fallback;
}

double _doubleValue(Object? value, double fallback) {
  if (value is double) {
    return value;
  }
  if (value is int) {
    return value.toDouble();
  }
  return fallback;
}

DateTime _dateValue(Object? value, DateTime fallback) {
  if (value is String) {
    return DateTime.tryParse(value) ?? fallback;
  }
  return fallback;
}

DateTime? _nullableDateValue(Object? value) {
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
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

List<Object?> _listValue(Object? value) {
  if (value is List<Object?>) {
    return value;
  }
  if (value is List) {
    return value.cast<Object?>();
  }
  return const [];
}
