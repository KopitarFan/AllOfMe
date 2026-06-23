// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $SystemProfileTableTable extends SystemProfileTable
    with TableInfo<$SystemProfileTableTable, SystemProfileRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SystemProfileTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    displayName,
    description,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'system_profile';
  @override
  VerificationContext validateIntegrity(
    Insertable<SystemProfileRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SystemProfileRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SystemProfileRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SystemProfileTableTable createAlias(String alias) {
    return $SystemProfileTableTable(attachedDatabase, alias);
  }
}

class SystemProfileRow extends DataClass
    implements Insertable<SystemProfileRow> {
  final int id;
  final String displayName;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;
  const SystemProfileRow({
    required this.id,
    required this.displayName,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['display_name'] = Variable<String>(displayName);
    map['description'] = Variable<String>(description);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SystemProfileTableCompanion toCompanion(bool nullToAbsent) {
    return SystemProfileTableCompanion(
      id: Value(id),
      displayName: Value(displayName),
      description: Value(description),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SystemProfileRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SystemProfileRow(
      id: serializer.fromJson<int>(json['id']),
      displayName: serializer.fromJson<String>(json['displayName']),
      description: serializer.fromJson<String>(json['description']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'displayName': serializer.toJson<String>(displayName),
      'description': serializer.toJson<String>(description),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SystemProfileRow copyWith({
    int? id,
    String? displayName,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => SystemProfileRow(
    id: id ?? this.id,
    displayName: displayName ?? this.displayName,
    description: description ?? this.description,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SystemProfileRow copyWithCompanion(SystemProfileTableCompanion data) {
    return SystemProfileRow(
      id: data.id.present ? data.id.value : this.id,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      description: data.description.present
          ? data.description.value
          : this.description,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SystemProfileRow(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, displayName, description, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SystemProfileRow &&
          other.id == this.id &&
          other.displayName == this.displayName &&
          other.description == this.description &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SystemProfileTableCompanion extends UpdateCompanion<SystemProfileRow> {
  final Value<int> id;
  final Value<String> displayName;
  final Value<String> description;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const SystemProfileTableCompanion({
    this.id = const Value.absent(),
    this.displayName = const Value.absent(),
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  SystemProfileTableCompanion.insert({
    this.id = const Value.absent(),
    required String displayName,
    required String description,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : displayName = Value(displayName),
       description = Value(description),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<SystemProfileRow> custom({
    Expression<int>? id,
    Expression<String>? displayName,
    Expression<String>? description,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (displayName != null) 'display_name': displayName,
      if (description != null) 'description': description,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  SystemProfileTableCompanion copyWith({
    Value<int>? id,
    Value<String>? displayName,
    Value<String>? description,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return SystemProfileTableCompanion(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SystemProfileTableCompanion(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $SecuritySettingsTableTable extends SecuritySettingsTable
    with TableInfo<$SecuritySettingsTableTable, SecuritySettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SecuritySettingsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _appLockEnabledMeta = const VerificationMeta(
    'appLockEnabled',
  );
  @override
  late final GeneratedColumn<bool> appLockEnabled = GeneratedColumn<bool>(
    'app_lock_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("app_lock_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [id, appLockEnabled];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'security_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SecuritySettingsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('app_lock_enabled')) {
      context.handle(
        _appLockEnabledMeta,
        appLockEnabled.isAcceptableOrUnknown(
          data['app_lock_enabled']!,
          _appLockEnabledMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SecuritySettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SecuritySettingsRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      appLockEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}app_lock_enabled'],
      )!,
    );
  }

  @override
  $SecuritySettingsTableTable createAlias(String alias) {
    return $SecuritySettingsTableTable(attachedDatabase, alias);
  }
}

class SecuritySettingsRow extends DataClass
    implements Insertable<SecuritySettingsRow> {
  final int id;
  final bool appLockEnabled;
  const SecuritySettingsRow({required this.id, required this.appLockEnabled});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['app_lock_enabled'] = Variable<bool>(appLockEnabled);
    return map;
  }

  SecuritySettingsTableCompanion toCompanion(bool nullToAbsent) {
    return SecuritySettingsTableCompanion(
      id: Value(id),
      appLockEnabled: Value(appLockEnabled),
    );
  }

  factory SecuritySettingsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SecuritySettingsRow(
      id: serializer.fromJson<int>(json['id']),
      appLockEnabled: serializer.fromJson<bool>(json['appLockEnabled']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'appLockEnabled': serializer.toJson<bool>(appLockEnabled),
    };
  }

  SecuritySettingsRow copyWith({int? id, bool? appLockEnabled}) =>
      SecuritySettingsRow(
        id: id ?? this.id,
        appLockEnabled: appLockEnabled ?? this.appLockEnabled,
      );
  SecuritySettingsRow copyWithCompanion(SecuritySettingsTableCompanion data) {
    return SecuritySettingsRow(
      id: data.id.present ? data.id.value : this.id,
      appLockEnabled: data.appLockEnabled.present
          ? data.appLockEnabled.value
          : this.appLockEnabled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SecuritySettingsRow(')
          ..write('id: $id, ')
          ..write('appLockEnabled: $appLockEnabled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, appLockEnabled);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SecuritySettingsRow &&
          other.id == this.id &&
          other.appLockEnabled == this.appLockEnabled);
}

class SecuritySettingsTableCompanion
    extends UpdateCompanion<SecuritySettingsRow> {
  final Value<int> id;
  final Value<bool> appLockEnabled;
  const SecuritySettingsTableCompanion({
    this.id = const Value.absent(),
    this.appLockEnabled = const Value.absent(),
  });
  SecuritySettingsTableCompanion.insert({
    this.id = const Value.absent(),
    this.appLockEnabled = const Value.absent(),
  });
  static Insertable<SecuritySettingsRow> custom({
    Expression<int>? id,
    Expression<bool>? appLockEnabled,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (appLockEnabled != null) 'app_lock_enabled': appLockEnabled,
    });
  }

  SecuritySettingsTableCompanion copyWith({
    Value<int>? id,
    Value<bool>? appLockEnabled,
  }) {
    return SecuritySettingsTableCompanion(
      id: id ?? this.id,
      appLockEnabled: appLockEnabled ?? this.appLockEnabled,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (appLockEnabled.present) {
      map['app_lock_enabled'] = Variable<bool>(appLockEnabled.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SecuritySettingsTableCompanion(')
          ..write('id: $id, ')
          ..write('appLockEnabled: $appLockEnabled')
          ..write(')'))
        .toString();
  }
}

class $MemberTableTable extends MemberTable
    with TableInfo<$MemberTableTable, MemberRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MemberTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorValueMeta = const VerificationMeta(
    'colorValue',
  );
  @override
  late final GeneratedColumn<int> colorValue = GeneratedColumn<int>(
    'color_value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _profileImageIdMeta = const VerificationMeta(
    'profileImageId',
  );
  @override
  late final GeneratedColumn<String> profileImageId = GeneratedColumn<String>(
    'profile_image_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _profileImageScaleMeta = const VerificationMeta(
    'profileImageScale',
  );
  @override
  late final GeneratedColumn<double> profileImageScale =
      GeneratedColumn<double>(
        'profile_image_scale',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(1.0),
      );
  static const VerificationMeta _profileImageOffsetXMeta =
      const VerificationMeta('profileImageOffsetX');
  @override
  late final GeneratedColumn<double> profileImageOffsetX =
      GeneratedColumn<double>(
        'profile_image_offset_x',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(0.0),
      );
  static const VerificationMeta _profileImageOffsetYMeta =
      const VerificationMeta('profileImageOffsetY');
  @override
  late final GeneratedColumn<double> profileImageOffsetY =
      GeneratedColumn<double>(
        'profile_image_offset_y',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(0.0),
      );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    role,
    note,
    colorValue,
    archived,
    createdAt,
    updatedAt,
    profileImageId,
    profileImageScale,
    profileImageOffsetX,
    profileImageOffsetY,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'members';
  @override
  VerificationContext validateIntegrity(
    Insertable<MemberRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    } else if (isInserting) {
      context.missing(_noteMeta);
    }
    if (data.containsKey('color_value')) {
      context.handle(
        _colorValueMeta,
        colorValue.isAcceptableOrUnknown(data['color_value']!, _colorValueMeta),
      );
    } else if (isInserting) {
      context.missing(_colorValueMeta);
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('profile_image_id')) {
      context.handle(
        _profileImageIdMeta,
        profileImageId.isAcceptableOrUnknown(
          data['profile_image_id']!,
          _profileImageIdMeta,
        ),
      );
    }
    if (data.containsKey('profile_image_scale')) {
      context.handle(
        _profileImageScaleMeta,
        profileImageScale.isAcceptableOrUnknown(
          data['profile_image_scale']!,
          _profileImageScaleMeta,
        ),
      );
    }
    if (data.containsKey('profile_image_offset_x')) {
      context.handle(
        _profileImageOffsetXMeta,
        profileImageOffsetX.isAcceptableOrUnknown(
          data['profile_image_offset_x']!,
          _profileImageOffsetXMeta,
        ),
      );
    }
    if (data.containsKey('profile_image_offset_y')) {
      context.handle(
        _profileImageOffsetYMeta,
        profileImageOffsetY.isAcceptableOrUnknown(
          data['profile_image_offset_y']!,
          _profileImageOffsetYMeta,
        ),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MemberRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MemberRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      colorValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_value'],
      )!,
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      profileImageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile_image_id'],
      ),
      profileImageScale: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}profile_image_scale'],
      )!,
      profileImageOffsetX: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}profile_image_offset_x'],
      )!,
      profileImageOffsetY: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}profile_image_offset_y'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $MemberTableTable createAlias(String alias) {
    return $MemberTableTable(attachedDatabase, alias);
  }
}

class MemberRow extends DataClass implements Insertable<MemberRow> {
  final String id;
  final String name;
  final String role;
  final String note;
  final int colorValue;
  final bool archived;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? profileImageId;
  final double profileImageScale;
  final double profileImageOffsetX;
  final double profileImageOffsetY;
  final int sortOrder;
  const MemberRow({
    required this.id,
    required this.name,
    required this.role,
    required this.note,
    required this.colorValue,
    required this.archived,
    required this.createdAt,
    required this.updatedAt,
    this.profileImageId,
    required this.profileImageScale,
    required this.profileImageOffsetX,
    required this.profileImageOffsetY,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['role'] = Variable<String>(role);
    map['note'] = Variable<String>(note);
    map['color_value'] = Variable<int>(colorValue);
    map['archived'] = Variable<bool>(archived);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || profileImageId != null) {
      map['profile_image_id'] = Variable<String>(profileImageId);
    }
    map['profile_image_scale'] = Variable<double>(profileImageScale);
    map['profile_image_offset_x'] = Variable<double>(profileImageOffsetX);
    map['profile_image_offset_y'] = Variable<double>(profileImageOffsetY);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  MemberTableCompanion toCompanion(bool nullToAbsent) {
    return MemberTableCompanion(
      id: Value(id),
      name: Value(name),
      role: Value(role),
      note: Value(note),
      colorValue: Value(colorValue),
      archived: Value(archived),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      profileImageId: profileImageId == null && nullToAbsent
          ? const Value.absent()
          : Value(profileImageId),
      profileImageScale: Value(profileImageScale),
      profileImageOffsetX: Value(profileImageOffsetX),
      profileImageOffsetY: Value(profileImageOffsetY),
      sortOrder: Value(sortOrder),
    );
  }

  factory MemberRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MemberRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      role: serializer.fromJson<String>(json['role']),
      note: serializer.fromJson<String>(json['note']),
      colorValue: serializer.fromJson<int>(json['colorValue']),
      archived: serializer.fromJson<bool>(json['archived']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      profileImageId: serializer.fromJson<String?>(json['profileImageId']),
      profileImageScale: serializer.fromJson<double>(json['profileImageScale']),
      profileImageOffsetX: serializer.fromJson<double>(
        json['profileImageOffsetX'],
      ),
      profileImageOffsetY: serializer.fromJson<double>(
        json['profileImageOffsetY'],
      ),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'role': serializer.toJson<String>(role),
      'note': serializer.toJson<String>(note),
      'colorValue': serializer.toJson<int>(colorValue),
      'archived': serializer.toJson<bool>(archived),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'profileImageId': serializer.toJson<String?>(profileImageId),
      'profileImageScale': serializer.toJson<double>(profileImageScale),
      'profileImageOffsetX': serializer.toJson<double>(profileImageOffsetX),
      'profileImageOffsetY': serializer.toJson<double>(profileImageOffsetY),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  MemberRow copyWith({
    String? id,
    String? name,
    String? role,
    String? note,
    int? colorValue,
    bool? archived,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<String?> profileImageId = const Value.absent(),
    double? profileImageScale,
    double? profileImageOffsetX,
    double? profileImageOffsetY,
    int? sortOrder,
  }) => MemberRow(
    id: id ?? this.id,
    name: name ?? this.name,
    role: role ?? this.role,
    note: note ?? this.note,
    colorValue: colorValue ?? this.colorValue,
    archived: archived ?? this.archived,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    profileImageId: profileImageId.present
        ? profileImageId.value
        : this.profileImageId,
    profileImageScale: profileImageScale ?? this.profileImageScale,
    profileImageOffsetX: profileImageOffsetX ?? this.profileImageOffsetX,
    profileImageOffsetY: profileImageOffsetY ?? this.profileImageOffsetY,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  MemberRow copyWithCompanion(MemberTableCompanion data) {
    return MemberRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      role: data.role.present ? data.role.value : this.role,
      note: data.note.present ? data.note.value : this.note,
      colorValue: data.colorValue.present
          ? data.colorValue.value
          : this.colorValue,
      archived: data.archived.present ? data.archived.value : this.archived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      profileImageId: data.profileImageId.present
          ? data.profileImageId.value
          : this.profileImageId,
      profileImageScale: data.profileImageScale.present
          ? data.profileImageScale.value
          : this.profileImageScale,
      profileImageOffsetX: data.profileImageOffsetX.present
          ? data.profileImageOffsetX.value
          : this.profileImageOffsetX,
      profileImageOffsetY: data.profileImageOffsetY.present
          ? data.profileImageOffsetY.value
          : this.profileImageOffsetY,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MemberRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('role: $role, ')
          ..write('note: $note, ')
          ..write('colorValue: $colorValue, ')
          ..write('archived: $archived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('profileImageId: $profileImageId, ')
          ..write('profileImageScale: $profileImageScale, ')
          ..write('profileImageOffsetX: $profileImageOffsetX, ')
          ..write('profileImageOffsetY: $profileImageOffsetY, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    role,
    note,
    colorValue,
    archived,
    createdAt,
    updatedAt,
    profileImageId,
    profileImageScale,
    profileImageOffsetX,
    profileImageOffsetY,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MemberRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.role == this.role &&
          other.note == this.note &&
          other.colorValue == this.colorValue &&
          other.archived == this.archived &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.profileImageId == this.profileImageId &&
          other.profileImageScale == this.profileImageScale &&
          other.profileImageOffsetX == this.profileImageOffsetX &&
          other.profileImageOffsetY == this.profileImageOffsetY &&
          other.sortOrder == this.sortOrder);
}

class MemberTableCompanion extends UpdateCompanion<MemberRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> role;
  final Value<String> note;
  final Value<int> colorValue;
  final Value<bool> archived;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String?> profileImageId;
  final Value<double> profileImageScale;
  final Value<double> profileImageOffsetX;
  final Value<double> profileImageOffsetY;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const MemberTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.role = const Value.absent(),
    this.note = const Value.absent(),
    this.colorValue = const Value.absent(),
    this.archived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.profileImageId = const Value.absent(),
    this.profileImageScale = const Value.absent(),
    this.profileImageOffsetX = const Value.absent(),
    this.profileImageOffsetY = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MemberTableCompanion.insert({
    required String id,
    required String name,
    required String role,
    required String note,
    required int colorValue,
    this.archived = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.profileImageId = const Value.absent(),
    this.profileImageScale = const Value.absent(),
    this.profileImageOffsetX = const Value.absent(),
    this.profileImageOffsetY = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       role = Value(role),
       note = Value(note),
       colorValue = Value(colorValue),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<MemberRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? role,
    Expression<String>? note,
    Expression<int>? colorValue,
    Expression<bool>? archived,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? profileImageId,
    Expression<double>? profileImageScale,
    Expression<double>? profileImageOffsetX,
    Expression<double>? profileImageOffsetY,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (role != null) 'role': role,
      if (note != null) 'note': note,
      if (colorValue != null) 'color_value': colorValue,
      if (archived != null) 'archived': archived,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (profileImageId != null) 'profile_image_id': profileImageId,
      if (profileImageScale != null) 'profile_image_scale': profileImageScale,
      if (profileImageOffsetX != null)
        'profile_image_offset_x': profileImageOffsetX,
      if (profileImageOffsetY != null)
        'profile_image_offset_y': profileImageOffsetY,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MemberTableCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? role,
    Value<String>? note,
    Value<int>? colorValue,
    Value<bool>? archived,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String?>? profileImageId,
    Value<double>? profileImageScale,
    Value<double>? profileImageOffsetX,
    Value<double>? profileImageOffsetY,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return MemberTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      note: note ?? this.note,
      colorValue: colorValue ?? this.colorValue,
      archived: archived ?? this.archived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      profileImageId: profileImageId ?? this.profileImageId,
      profileImageScale: profileImageScale ?? this.profileImageScale,
      profileImageOffsetX: profileImageOffsetX ?? this.profileImageOffsetX,
      profileImageOffsetY: profileImageOffsetY ?? this.profileImageOffsetY,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (colorValue.present) {
      map['color_value'] = Variable<int>(colorValue.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (profileImageId.present) {
      map['profile_image_id'] = Variable<String>(profileImageId.value);
    }
    if (profileImageScale.present) {
      map['profile_image_scale'] = Variable<double>(profileImageScale.value);
    }
    if (profileImageOffsetX.present) {
      map['profile_image_offset_x'] = Variable<double>(
        profileImageOffsetX.value,
      );
    }
    if (profileImageOffsetY.present) {
      map['profile_image_offset_y'] = Variable<double>(
        profileImageOffsetY.value,
      );
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MemberTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('role: $role, ')
          ..write('note: $note, ')
          ..write('colorValue: $colorValue, ')
          ..write('archived: $archived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('profileImageId: $profileImageId, ')
          ..write('profileImageScale: $profileImageScale, ')
          ..write('profileImageOffsetX: $profileImageOffsetX, ')
          ..write('profileImageOffsetY: $profileImageOffsetY, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MemberGroupTableTable extends MemberGroupTable
    with TableInfo<$MemberGroupTableTable, MemberGroupRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MemberGroupTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorValueMeta = const VerificationMeta(
    'colorValue',
  );
  @override
  late final GeneratedColumn<int> colorValue = GeneratedColumn<int>(
    'color_value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    description,
    colorValue,
    archived,
    createdAt,
    updatedAt,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'member_groups';
  @override
  VerificationContext validateIntegrity(
    Insertable<MemberGroupRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('color_value')) {
      context.handle(
        _colorValueMeta,
        colorValue.isAcceptableOrUnknown(data['color_value']!, _colorValueMeta),
      );
    } else if (isInserting) {
      context.missing(_colorValueMeta);
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MemberGroupRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MemberGroupRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      colorValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_value'],
      )!,
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $MemberGroupTableTable createAlias(String alias) {
    return $MemberGroupTableTable(attachedDatabase, alias);
  }
}

class MemberGroupRow extends DataClass implements Insertable<MemberGroupRow> {
  final String id;
  final String name;
  final String description;
  final int colorValue;
  final bool archived;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int sortOrder;
  const MemberGroupRow({
    required this.id,
    required this.name,
    required this.description,
    required this.colorValue,
    required this.archived,
    required this.createdAt,
    required this.updatedAt,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    map['color_value'] = Variable<int>(colorValue);
    map['archived'] = Variable<bool>(archived);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  MemberGroupTableCompanion toCompanion(bool nullToAbsent) {
    return MemberGroupTableCompanion(
      id: Value(id),
      name: Value(name),
      description: Value(description),
      colorValue: Value(colorValue),
      archived: Value(archived),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      sortOrder: Value(sortOrder),
    );
  }

  factory MemberGroupRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MemberGroupRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      colorValue: serializer.fromJson<int>(json['colorValue']),
      archived: serializer.fromJson<bool>(json['archived']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'colorValue': serializer.toJson<int>(colorValue),
      'archived': serializer.toJson<bool>(archived),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  MemberGroupRow copyWith({
    String? id,
    String? name,
    String? description,
    int? colorValue,
    bool? archived,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? sortOrder,
  }) => MemberGroupRow(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    colorValue: colorValue ?? this.colorValue,
    archived: archived ?? this.archived,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  MemberGroupRow copyWithCompanion(MemberGroupTableCompanion data) {
    return MemberGroupRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      colorValue: data.colorValue.present
          ? data.colorValue.value
          : this.colorValue,
      archived: data.archived.present ? data.archived.value : this.archived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MemberGroupRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('colorValue: $colorValue, ')
          ..write('archived: $archived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    colorValue,
    archived,
    createdAt,
    updatedAt,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MemberGroupRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.colorValue == this.colorValue &&
          other.archived == this.archived &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.sortOrder == this.sortOrder);
}

class MemberGroupTableCompanion extends UpdateCompanion<MemberGroupRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> description;
  final Value<int> colorValue;
  final Value<bool> archived;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const MemberGroupTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.colorValue = const Value.absent(),
    this.archived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MemberGroupTableCompanion.insert({
    required String id,
    required String name,
    required String description,
    required int colorValue,
    this.archived = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       description = Value(description),
       colorValue = Value(colorValue),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<MemberGroupRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<int>? colorValue,
    Expression<bool>? archived,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (colorValue != null) 'color_value': colorValue,
      if (archived != null) 'archived': archived,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MemberGroupTableCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? description,
    Value<int>? colorValue,
    Value<bool>? archived,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return MemberGroupTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      colorValue: colorValue ?? this.colorValue,
      archived: archived ?? this.archived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (colorValue.present) {
      map['color_value'] = Variable<int>(colorValue.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MemberGroupTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('colorValue: $colorValue, ')
          ..write('archived: $archived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MemberGroupLinkTableTable extends MemberGroupLinkTable
    with TableInfo<$MemberGroupLinkTableTable, MemberGroupLinkRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MemberGroupLinkTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  @override
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES members (id)',
    ),
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES member_groups (id)',
    ),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [memberId, groupId, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'member_group_links';
  @override
  VerificationContext validateIntegrity(
    Insertable<MemberGroupLinkRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {memberId, groupId};
  @override
  MemberGroupLinkRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MemberGroupLinkRow(
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_id'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $MemberGroupLinkTableTable createAlias(String alias) {
    return $MemberGroupLinkTableTable(attachedDatabase, alias);
  }
}

class MemberGroupLinkRow extends DataClass
    implements Insertable<MemberGroupLinkRow> {
  final String memberId;
  final String groupId;
  final int sortOrder;
  const MemberGroupLinkRow({
    required this.memberId,
    required this.groupId,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['member_id'] = Variable<String>(memberId);
    map['group_id'] = Variable<String>(groupId);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  MemberGroupLinkTableCompanion toCompanion(bool nullToAbsent) {
    return MemberGroupLinkTableCompanion(
      memberId: Value(memberId),
      groupId: Value(groupId),
      sortOrder: Value(sortOrder),
    );
  }

  factory MemberGroupLinkRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MemberGroupLinkRow(
      memberId: serializer.fromJson<String>(json['memberId']),
      groupId: serializer.fromJson<String>(json['groupId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'memberId': serializer.toJson<String>(memberId),
      'groupId': serializer.toJson<String>(groupId),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  MemberGroupLinkRow copyWith({
    String? memberId,
    String? groupId,
    int? sortOrder,
  }) => MemberGroupLinkRow(
    memberId: memberId ?? this.memberId,
    groupId: groupId ?? this.groupId,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  MemberGroupLinkRow copyWithCompanion(MemberGroupLinkTableCompanion data) {
    return MemberGroupLinkRow(
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MemberGroupLinkRow(')
          ..write('memberId: $memberId, ')
          ..write('groupId: $groupId, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(memberId, groupId, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MemberGroupLinkRow &&
          other.memberId == this.memberId &&
          other.groupId == this.groupId &&
          other.sortOrder == this.sortOrder);
}

class MemberGroupLinkTableCompanion
    extends UpdateCompanion<MemberGroupLinkRow> {
  final Value<String> memberId;
  final Value<String> groupId;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const MemberGroupLinkTableCompanion({
    this.memberId = const Value.absent(),
    this.groupId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MemberGroupLinkTableCompanion.insert({
    required String memberId,
    required String groupId,
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : memberId = Value(memberId),
       groupId = Value(groupId);
  static Insertable<MemberGroupLinkRow> custom({
    Expression<String>? memberId,
    Expression<String>? groupId,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (memberId != null) 'member_id': memberId,
      if (groupId != null) 'group_id': groupId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MemberGroupLinkTableCompanion copyWith({
    Value<String>? memberId,
    Value<String>? groupId,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return MemberGroupLinkTableCompanion(
      memberId: memberId ?? this.memberId,
      groupId: groupId ?? this.groupId,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MemberGroupLinkTableCompanion(')
          ..write('memberId: $memberId, ')
          ..write('groupId: $groupId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FrontingMemberTableTable extends FrontingMemberTable
    with TableInfo<$FrontingMemberTableTable, FrontingMemberRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FrontingMemberTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  @override
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES members (id)',
    ),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [memberId, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fronting_members';
  @override
  VerificationContext validateIntegrity(
    Insertable<FrontingMemberRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {memberId};
  @override
  FrontingMemberRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FrontingMemberRow(
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_id'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $FrontingMemberTableTable createAlias(String alias) {
    return $FrontingMemberTableTable(attachedDatabase, alias);
  }
}

class FrontingMemberRow extends DataClass
    implements Insertable<FrontingMemberRow> {
  final String memberId;
  final int sortOrder;
  const FrontingMemberRow({required this.memberId, required this.sortOrder});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['member_id'] = Variable<String>(memberId);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  FrontingMemberTableCompanion toCompanion(bool nullToAbsent) {
    return FrontingMemberTableCompanion(
      memberId: Value(memberId),
      sortOrder: Value(sortOrder),
    );
  }

  factory FrontingMemberRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FrontingMemberRow(
      memberId: serializer.fromJson<String>(json['memberId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'memberId': serializer.toJson<String>(memberId),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  FrontingMemberRow copyWith({String? memberId, int? sortOrder}) =>
      FrontingMemberRow(
        memberId: memberId ?? this.memberId,
        sortOrder: sortOrder ?? this.sortOrder,
      );
  FrontingMemberRow copyWithCompanion(FrontingMemberTableCompanion data) {
    return FrontingMemberRow(
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FrontingMemberRow(')
          ..write('memberId: $memberId, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(memberId, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FrontingMemberRow &&
          other.memberId == this.memberId &&
          other.sortOrder == this.sortOrder);
}

class FrontingMemberTableCompanion extends UpdateCompanion<FrontingMemberRow> {
  final Value<String> memberId;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const FrontingMemberTableCompanion({
    this.memberId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FrontingMemberTableCompanion.insert({
    required String memberId,
    required int sortOrder,
    this.rowid = const Value.absent(),
  }) : memberId = Value(memberId),
       sortOrder = Value(sortOrder);
  static Insertable<FrontingMemberRow> custom({
    Expression<String>? memberId,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (memberId != null) 'member_id': memberId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FrontingMemberTableCompanion copyWith({
    Value<String>? memberId,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return FrontingMemberTableCompanion(
      memberId: memberId ?? this.memberId,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FrontingMemberTableCompanion(')
          ..write('memberId: $memberId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FrontSessionTableTable extends FrontSessionTable
    with TableInfo<$FrontSessionTableTable, FrontSessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FrontSessionTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  @override
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _memberNameMeta = const VerificationMeta(
    'memberName',
  );
  @override
  late final GeneratedColumn<String> memberName = GeneratedColumn<String>(
    'member_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    memberId,
    memberName,
    startedAt,
    endedAt,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'front_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<FrontSessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('member_name')) {
      context.handle(
        _memberNameMeta,
        memberName.isAcceptableOrUnknown(data['member_name']!, _memberNameMeta),
      );
    } else if (isInserting) {
      context.missing(_memberNameMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FrontSessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FrontSessionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_id'],
      )!,
      memberName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_name'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $FrontSessionTableTable createAlias(String alias) {
    return $FrontSessionTableTable(attachedDatabase, alias);
  }
}

class FrontSessionRow extends DataClass implements Insertable<FrontSessionRow> {
  final String id;
  final String memberId;
  final String memberName;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int sortOrder;
  const FrontSessionRow({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.startedAt,
    this.endedAt,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['member_id'] = Variable<String>(memberId);
    map['member_name'] = Variable<String>(memberName);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  FrontSessionTableCompanion toCompanion(bool nullToAbsent) {
    return FrontSessionTableCompanion(
      id: Value(id),
      memberId: Value(memberId),
      memberName: Value(memberName),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      sortOrder: Value(sortOrder),
    );
  }

  factory FrontSessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FrontSessionRow(
      id: serializer.fromJson<String>(json['id']),
      memberId: serializer.fromJson<String>(json['memberId']),
      memberName: serializer.fromJson<String>(json['memberName']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'memberId': serializer.toJson<String>(memberId),
      'memberName': serializer.toJson<String>(memberName),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  FrontSessionRow copyWith({
    String? id,
    String? memberId,
    String? memberName,
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
    int? sortOrder,
  }) => FrontSessionRow(
    id: id ?? this.id,
    memberId: memberId ?? this.memberId,
    memberName: memberName ?? this.memberName,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  FrontSessionRow copyWithCompanion(FrontSessionTableCompanion data) {
    return FrontSessionRow(
      id: data.id.present ? data.id.value : this.id,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      memberName: data.memberName.present
          ? data.memberName.value
          : this.memberName,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FrontSessionRow(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('memberName: $memberName, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, memberId, memberName, startedAt, endedAt, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FrontSessionRow &&
          other.id == this.id &&
          other.memberId == this.memberId &&
          other.memberName == this.memberName &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.sortOrder == this.sortOrder);
}

class FrontSessionTableCompanion extends UpdateCompanion<FrontSessionRow> {
  final Value<String> id;
  final Value<String> memberId;
  final Value<String> memberName;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const FrontSessionTableCompanion({
    this.id = const Value.absent(),
    this.memberId = const Value.absent(),
    this.memberName = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FrontSessionTableCompanion.insert({
    required String id,
    required String memberId,
    required String memberName,
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       memberId = Value(memberId),
       memberName = Value(memberName),
       startedAt = Value(startedAt);
  static Insertable<FrontSessionRow> custom({
    Expression<String>? id,
    Expression<String>? memberId,
    Expression<String>? memberName,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (memberId != null) 'member_id': memberId,
      if (memberName != null) 'member_name': memberName,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FrontSessionTableCompanion copyWith({
    Value<String>? id,
    Value<String>? memberId,
    Value<String>? memberName,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return FrontSessionTableCompanion(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      memberName: memberName ?? this.memberName,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (memberName.present) {
      map['member_name'] = Variable<String>(memberName.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FrontSessionTableCompanion(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('memberName: $memberName, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TimelineEntryTableTable extends TimelineEntryTable
    with TableInfo<$TimelineEntryTableTable, TimelineEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TimelineEntryTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
    'action',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  @override
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
    'member_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _memberNameMeta = const VerificationMeta(
    'memberName',
  );
  @override
  late final GeneratedColumn<String> memberName = GeneratedColumn<String>(
    'member_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    action,
    createdAt,
    memberId,
    memberName,
    note,
    deletedAt,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'timeline_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<TimelineEntryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('action')) {
      context.handle(
        _actionMeta,
        action.isAcceptableOrUnknown(data['action']!, _actionMeta),
      );
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    }
    if (data.containsKey('member_name')) {
      context.handle(
        _memberNameMeta,
        memberName.isAcceptableOrUnknown(data['member_name']!, _memberNameMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TimelineEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TimelineEntryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      action: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_id'],
      ),
      memberName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_name'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $TimelineEntryTableTable createAlias(String alias) {
    return $TimelineEntryTableTable(attachedDatabase, alias);
  }
}

class TimelineEntryRow extends DataClass
    implements Insertable<TimelineEntryRow> {
  final String id;
  final String type;
  final String action;
  final DateTime createdAt;
  final String? memberId;
  final String? memberName;
  final String? note;
  final DateTime? deletedAt;
  final int sortOrder;
  const TimelineEntryRow({
    required this.id,
    required this.type,
    required this.action,
    required this.createdAt,
    this.memberId,
    this.memberName,
    this.note,
    this.deletedAt,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['type'] = Variable<String>(type);
    map['action'] = Variable<String>(action);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || memberId != null) {
      map['member_id'] = Variable<String>(memberId);
    }
    if (!nullToAbsent || memberName != null) {
      map['member_name'] = Variable<String>(memberName);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  TimelineEntryTableCompanion toCompanion(bool nullToAbsent) {
    return TimelineEntryTableCompanion(
      id: Value(id),
      type: Value(type),
      action: Value(action),
      createdAt: Value(createdAt),
      memberId: memberId == null && nullToAbsent
          ? const Value.absent()
          : Value(memberId),
      memberName: memberName == null && nullToAbsent
          ? const Value.absent()
          : Value(memberName),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      sortOrder: Value(sortOrder),
    );
  }

  factory TimelineEntryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TimelineEntryRow(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      action: serializer.fromJson<String>(json['action']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      memberId: serializer.fromJson<String?>(json['memberId']),
      memberName: serializer.fromJson<String?>(json['memberName']),
      note: serializer.fromJson<String?>(json['note']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(type),
      'action': serializer.toJson<String>(action),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'memberId': serializer.toJson<String?>(memberId),
      'memberName': serializer.toJson<String?>(memberName),
      'note': serializer.toJson<String?>(note),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  TimelineEntryRow copyWith({
    String? id,
    String? type,
    String? action,
    DateTime? createdAt,
    Value<String?> memberId = const Value.absent(),
    Value<String?> memberName = const Value.absent(),
    Value<String?> note = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
    int? sortOrder,
  }) => TimelineEntryRow(
    id: id ?? this.id,
    type: type ?? this.type,
    action: action ?? this.action,
    createdAt: createdAt ?? this.createdAt,
    memberId: memberId.present ? memberId.value : this.memberId,
    memberName: memberName.present ? memberName.value : this.memberName,
    note: note.present ? note.value : this.note,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  TimelineEntryRow copyWithCompanion(TimelineEntryTableCompanion data) {
    return TimelineEntryRow(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      action: data.action.present ? data.action.value : this.action,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      memberName: data.memberName.present
          ? data.memberName.value
          : this.memberName,
      note: data.note.present ? data.note.value : this.note,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TimelineEntryRow(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('action: $action, ')
          ..write('createdAt: $createdAt, ')
          ..write('memberId: $memberId, ')
          ..write('memberName: $memberName, ')
          ..write('note: $note, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    action,
    createdAt,
    memberId,
    memberName,
    note,
    deletedAt,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TimelineEntryRow &&
          other.id == this.id &&
          other.type == this.type &&
          other.action == this.action &&
          other.createdAt == this.createdAt &&
          other.memberId == this.memberId &&
          other.memberName == this.memberName &&
          other.note == this.note &&
          other.deletedAt == this.deletedAt &&
          other.sortOrder == this.sortOrder);
}

class TimelineEntryTableCompanion extends UpdateCompanion<TimelineEntryRow> {
  final Value<String> id;
  final Value<String> type;
  final Value<String> action;
  final Value<DateTime> createdAt;
  final Value<String?> memberId;
  final Value<String?> memberName;
  final Value<String?> note;
  final Value<DateTime?> deletedAt;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const TimelineEntryTableCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.action = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.memberId = const Value.absent(),
    this.memberName = const Value.absent(),
    this.note = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TimelineEntryTableCompanion.insert({
    required String id,
    required String type,
    required String action,
    required DateTime createdAt,
    this.memberId = const Value.absent(),
    this.memberName = const Value.absent(),
    this.note = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       type = Value(type),
       action = Value(action),
       createdAt = Value(createdAt);
  static Insertable<TimelineEntryRow> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<String>? action,
    Expression<DateTime>? createdAt,
    Expression<String>? memberId,
    Expression<String>? memberName,
    Expression<String>? note,
    Expression<DateTime>? deletedAt,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (action != null) 'action': action,
      if (createdAt != null) 'created_at': createdAt,
      if (memberId != null) 'member_id': memberId,
      if (memberName != null) 'member_name': memberName,
      if (note != null) 'note': note,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TimelineEntryTableCompanion copyWith({
    Value<String>? id,
    Value<String>? type,
    Value<String>? action,
    Value<DateTime>? createdAt,
    Value<String?>? memberId,
    Value<String?>? memberName,
    Value<String?>? note,
    Value<DateTime?>? deletedAt,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return TimelineEntryTableCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      action: action ?? this.action,
      createdAt: createdAt ?? this.createdAt,
      memberId: memberId ?? this.memberId,
      memberName: memberName ?? this.memberName,
      note: note ?? this.note,
      deletedAt: deletedAt ?? this.deletedAt,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (memberName.present) {
      map['member_name'] = Variable<String>(memberName.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TimelineEntryTableCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('action: $action, ')
          ..write('createdAt: $createdAt, ')
          ..write('memberId: $memberId, ')
          ..write('memberName: $memberName, ')
          ..write('note: $note, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AllOfMeDatabase extends GeneratedDatabase {
  _$AllOfMeDatabase(QueryExecutor e) : super(e);
  $AllOfMeDatabaseManager get managers => $AllOfMeDatabaseManager(this);
  late final $SystemProfileTableTable systemProfileTable =
      $SystemProfileTableTable(this);
  late final $SecuritySettingsTableTable securitySettingsTable =
      $SecuritySettingsTableTable(this);
  late final $MemberTableTable memberTable = $MemberTableTable(this);
  late final $MemberGroupTableTable memberGroupTable = $MemberGroupTableTable(
    this,
  );
  late final $MemberGroupLinkTableTable memberGroupLinkTable =
      $MemberGroupLinkTableTable(this);
  late final $FrontingMemberTableTable frontingMemberTable =
      $FrontingMemberTableTable(this);
  late final $FrontSessionTableTable frontSessionTable =
      $FrontSessionTableTable(this);
  late final $TimelineEntryTableTable timelineEntryTable =
      $TimelineEntryTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    systemProfileTable,
    securitySettingsTable,
    memberTable,
    memberGroupTable,
    memberGroupLinkTable,
    frontingMemberTable,
    frontSessionTable,
    timelineEntryTable,
  ];
}

typedef $$SystemProfileTableTableCreateCompanionBuilder =
    SystemProfileTableCompanion Function({
      Value<int> id,
      required String displayName,
      required String description,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$SystemProfileTableTableUpdateCompanionBuilder =
    SystemProfileTableCompanion Function({
      Value<int> id,
      Value<String> displayName,
      Value<String> description,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$SystemProfileTableTableFilterComposer
    extends Composer<_$AllOfMeDatabase, $SystemProfileTableTable> {
  $$SystemProfileTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SystemProfileTableTableOrderingComposer
    extends Composer<_$AllOfMeDatabase, $SystemProfileTableTable> {
  $$SystemProfileTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SystemProfileTableTableAnnotationComposer
    extends Composer<_$AllOfMeDatabase, $SystemProfileTableTable> {
  $$SystemProfileTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SystemProfileTableTableTableManager
    extends
        RootTableManager<
          _$AllOfMeDatabase,
          $SystemProfileTableTable,
          SystemProfileRow,
          $$SystemProfileTableTableFilterComposer,
          $$SystemProfileTableTableOrderingComposer,
          $$SystemProfileTableTableAnnotationComposer,
          $$SystemProfileTableTableCreateCompanionBuilder,
          $$SystemProfileTableTableUpdateCompanionBuilder,
          (
            SystemProfileRow,
            BaseReferences<
              _$AllOfMeDatabase,
              $SystemProfileTableTable,
              SystemProfileRow
            >,
          ),
          SystemProfileRow,
          PrefetchHooks Function()
        > {
  $$SystemProfileTableTableTableManager(
    _$AllOfMeDatabase db,
    $SystemProfileTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SystemProfileTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SystemProfileTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SystemProfileTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => SystemProfileTableCompanion(
                id: id,
                displayName: displayName,
                description: description,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String displayName,
                required String description,
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => SystemProfileTableCompanion.insert(
                id: id,
                displayName: displayName,
                description: description,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SystemProfileTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AllOfMeDatabase,
      $SystemProfileTableTable,
      SystemProfileRow,
      $$SystemProfileTableTableFilterComposer,
      $$SystemProfileTableTableOrderingComposer,
      $$SystemProfileTableTableAnnotationComposer,
      $$SystemProfileTableTableCreateCompanionBuilder,
      $$SystemProfileTableTableUpdateCompanionBuilder,
      (
        SystemProfileRow,
        BaseReferences<
          _$AllOfMeDatabase,
          $SystemProfileTableTable,
          SystemProfileRow
        >,
      ),
      SystemProfileRow,
      PrefetchHooks Function()
    >;
typedef $$SecuritySettingsTableTableCreateCompanionBuilder =
    SecuritySettingsTableCompanion Function({
      Value<int> id,
      Value<bool> appLockEnabled,
    });
typedef $$SecuritySettingsTableTableUpdateCompanionBuilder =
    SecuritySettingsTableCompanion Function({
      Value<int> id,
      Value<bool> appLockEnabled,
    });

class $$SecuritySettingsTableTableFilterComposer
    extends Composer<_$AllOfMeDatabase, $SecuritySettingsTableTable> {
  $$SecuritySettingsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get appLockEnabled => $composableBuilder(
    column: $table.appLockEnabled,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SecuritySettingsTableTableOrderingComposer
    extends Composer<_$AllOfMeDatabase, $SecuritySettingsTableTable> {
  $$SecuritySettingsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get appLockEnabled => $composableBuilder(
    column: $table.appLockEnabled,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SecuritySettingsTableTableAnnotationComposer
    extends Composer<_$AllOfMeDatabase, $SecuritySettingsTableTable> {
  $$SecuritySettingsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get appLockEnabled => $composableBuilder(
    column: $table.appLockEnabled,
    builder: (column) => column,
  );
}

class $$SecuritySettingsTableTableTableManager
    extends
        RootTableManager<
          _$AllOfMeDatabase,
          $SecuritySettingsTableTable,
          SecuritySettingsRow,
          $$SecuritySettingsTableTableFilterComposer,
          $$SecuritySettingsTableTableOrderingComposer,
          $$SecuritySettingsTableTableAnnotationComposer,
          $$SecuritySettingsTableTableCreateCompanionBuilder,
          $$SecuritySettingsTableTableUpdateCompanionBuilder,
          (
            SecuritySettingsRow,
            BaseReferences<
              _$AllOfMeDatabase,
              $SecuritySettingsTableTable,
              SecuritySettingsRow
            >,
          ),
          SecuritySettingsRow,
          PrefetchHooks Function()
        > {
  $$SecuritySettingsTableTableTableManager(
    _$AllOfMeDatabase db,
    $SecuritySettingsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SecuritySettingsTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$SecuritySettingsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$SecuritySettingsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> appLockEnabled = const Value.absent(),
              }) => SecuritySettingsTableCompanion(
                id: id,
                appLockEnabled: appLockEnabled,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> appLockEnabled = const Value.absent(),
              }) => SecuritySettingsTableCompanion.insert(
                id: id,
                appLockEnabled: appLockEnabled,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SecuritySettingsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AllOfMeDatabase,
      $SecuritySettingsTableTable,
      SecuritySettingsRow,
      $$SecuritySettingsTableTableFilterComposer,
      $$SecuritySettingsTableTableOrderingComposer,
      $$SecuritySettingsTableTableAnnotationComposer,
      $$SecuritySettingsTableTableCreateCompanionBuilder,
      $$SecuritySettingsTableTableUpdateCompanionBuilder,
      (
        SecuritySettingsRow,
        BaseReferences<
          _$AllOfMeDatabase,
          $SecuritySettingsTableTable,
          SecuritySettingsRow
        >,
      ),
      SecuritySettingsRow,
      PrefetchHooks Function()
    >;
typedef $$MemberTableTableCreateCompanionBuilder =
    MemberTableCompanion Function({
      required String id,
      required String name,
      required String role,
      required String note,
      required int colorValue,
      Value<bool> archived,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<String?> profileImageId,
      Value<double> profileImageScale,
      Value<double> profileImageOffsetX,
      Value<double> profileImageOffsetY,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$MemberTableTableUpdateCompanionBuilder =
    MemberTableCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> role,
      Value<String> note,
      Value<int> colorValue,
      Value<bool> archived,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<String?> profileImageId,
      Value<double> profileImageScale,
      Value<double> profileImageOffsetX,
      Value<double> profileImageOffsetY,
      Value<int> sortOrder,
      Value<int> rowid,
    });

final class $$MemberTableTableReferences
    extends BaseReferences<_$AllOfMeDatabase, $MemberTableTable, MemberRow> {
  $$MemberTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<
    $MemberGroupLinkTableTable,
    List<MemberGroupLinkRow>
  >
  _memberGroupLinkTableRefsTable(_$AllOfMeDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.memberGroupLinkTable,
        aliasName: 'members__id__member_group_links__member_id',
      );

  $$MemberGroupLinkTableTableProcessedTableManager
  get memberGroupLinkTableRefs {
    final manager = $$MemberGroupLinkTableTableTableManager(
      $_db,
      $_db.memberGroupLinkTable,
    ).filter((f) => f.memberId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _memberGroupLinkTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$FrontingMemberTableTable, List<FrontingMemberRow>>
  _frontingMemberTableRefsTable(_$AllOfMeDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.frontingMemberTable,
        aliasName: 'members__id__fronting_members__member_id',
      );

  $$FrontingMemberTableTableProcessedTableManager get frontingMemberTableRefs {
    final manager = $$FrontingMemberTableTableTableManager(
      $_db,
      $_db.frontingMemberTable,
    ).filter((f) => f.memberId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _frontingMemberTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MemberTableTableFilterComposer
    extends Composer<_$AllOfMeDatabase, $MemberTableTable> {
  $$MemberTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get profileImageId => $composableBuilder(
    column: $table.profileImageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get profileImageScale => $composableBuilder(
    column: $table.profileImageScale,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get profileImageOffsetX => $composableBuilder(
    column: $table.profileImageOffsetX,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get profileImageOffsetY => $composableBuilder(
    column: $table.profileImageOffsetY,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> memberGroupLinkTableRefs(
    Expression<bool> Function($$MemberGroupLinkTableTableFilterComposer f) f,
  ) {
    final $$MemberGroupLinkTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.memberGroupLinkTable,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MemberGroupLinkTableTableFilterComposer(
            $db: $db,
            $table: $db.memberGroupLinkTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> frontingMemberTableRefs(
    Expression<bool> Function($$FrontingMemberTableTableFilterComposer f) f,
  ) {
    final $$FrontingMemberTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.frontingMemberTable,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FrontingMemberTableTableFilterComposer(
            $db: $db,
            $table: $db.frontingMemberTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MemberTableTableOrderingComposer
    extends Composer<_$AllOfMeDatabase, $MemberTableTable> {
  $$MemberTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get profileImageId => $composableBuilder(
    column: $table.profileImageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get profileImageScale => $composableBuilder(
    column: $table.profileImageScale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get profileImageOffsetX => $composableBuilder(
    column: $table.profileImageOffsetX,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get profileImageOffsetY => $composableBuilder(
    column: $table.profileImageOffsetY,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MemberTableTableAnnotationComposer
    extends Composer<_$AllOfMeDatabase, $MemberTableTable> {
  $$MemberTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get profileImageId => $composableBuilder(
    column: $table.profileImageId,
    builder: (column) => column,
  );

  GeneratedColumn<double> get profileImageScale => $composableBuilder(
    column: $table.profileImageScale,
    builder: (column) => column,
  );

  GeneratedColumn<double> get profileImageOffsetX => $composableBuilder(
    column: $table.profileImageOffsetX,
    builder: (column) => column,
  );

  GeneratedColumn<double> get profileImageOffsetY => $composableBuilder(
    column: $table.profileImageOffsetY,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  Expression<T> memberGroupLinkTableRefs<T extends Object>(
    Expression<T> Function($$MemberGroupLinkTableTableAnnotationComposer a) f,
  ) {
    final $$MemberGroupLinkTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.memberGroupLinkTable,
          getReferencedColumn: (t) => t.memberId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$MemberGroupLinkTableTableAnnotationComposer(
                $db: $db,
                $table: $db.memberGroupLinkTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> frontingMemberTableRefs<T extends Object>(
    Expression<T> Function($$FrontingMemberTableTableAnnotationComposer a) f,
  ) {
    final $$FrontingMemberTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.frontingMemberTable,
          getReferencedColumn: (t) => t.memberId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$FrontingMemberTableTableAnnotationComposer(
                $db: $db,
                $table: $db.frontingMemberTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$MemberTableTableTableManager
    extends
        RootTableManager<
          _$AllOfMeDatabase,
          $MemberTableTable,
          MemberRow,
          $$MemberTableTableFilterComposer,
          $$MemberTableTableOrderingComposer,
          $$MemberTableTableAnnotationComposer,
          $$MemberTableTableCreateCompanionBuilder,
          $$MemberTableTableUpdateCompanionBuilder,
          (MemberRow, $$MemberTableTableReferences),
          MemberRow,
          PrefetchHooks Function({
            bool memberGroupLinkTableRefs,
            bool frontingMemberTableRefs,
          })
        > {
  $$MemberTableTableTableManager(_$AllOfMeDatabase db, $MemberTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MemberTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MemberTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MemberTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<int> colorValue = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String?> profileImageId = const Value.absent(),
                Value<double> profileImageScale = const Value.absent(),
                Value<double> profileImageOffsetX = const Value.absent(),
                Value<double> profileImageOffsetY = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MemberTableCompanion(
                id: id,
                name: name,
                role: role,
                note: note,
                colorValue: colorValue,
                archived: archived,
                createdAt: createdAt,
                updatedAt: updatedAt,
                profileImageId: profileImageId,
                profileImageScale: profileImageScale,
                profileImageOffsetX: profileImageOffsetX,
                profileImageOffsetY: profileImageOffsetY,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String role,
                required String note,
                required int colorValue,
                Value<bool> archived = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<String?> profileImageId = const Value.absent(),
                Value<double> profileImageScale = const Value.absent(),
                Value<double> profileImageOffsetX = const Value.absent(),
                Value<double> profileImageOffsetY = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MemberTableCompanion.insert(
                id: id,
                name: name,
                role: role,
                note: note,
                colorValue: colorValue,
                archived: archived,
                createdAt: createdAt,
                updatedAt: updatedAt,
                profileImageId: profileImageId,
                profileImageScale: profileImageScale,
                profileImageOffsetX: profileImageOffsetX,
                profileImageOffsetY: profileImageOffsetY,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MemberTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                memberGroupLinkTableRefs = false,
                frontingMemberTableRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (memberGroupLinkTableRefs) db.memberGroupLinkTable,
                    if (frontingMemberTableRefs) db.frontingMemberTable,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (memberGroupLinkTableRefs)
                        await $_getPrefetchedData<
                          MemberRow,
                          $MemberTableTable,
                          MemberGroupLinkRow
                        >(
                          currentTable: table,
                          referencedTable: $$MemberTableTableReferences
                              ._memberGroupLinkTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MemberTableTableReferences(
                                db,
                                table,
                                p0,
                              ).memberGroupLinkTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.memberId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (frontingMemberTableRefs)
                        await $_getPrefetchedData<
                          MemberRow,
                          $MemberTableTable,
                          FrontingMemberRow
                        >(
                          currentTable: table,
                          referencedTable: $$MemberTableTableReferences
                              ._frontingMemberTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MemberTableTableReferences(
                                db,
                                table,
                                p0,
                              ).frontingMemberTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.memberId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$MemberTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AllOfMeDatabase,
      $MemberTableTable,
      MemberRow,
      $$MemberTableTableFilterComposer,
      $$MemberTableTableOrderingComposer,
      $$MemberTableTableAnnotationComposer,
      $$MemberTableTableCreateCompanionBuilder,
      $$MemberTableTableUpdateCompanionBuilder,
      (MemberRow, $$MemberTableTableReferences),
      MemberRow,
      PrefetchHooks Function({
        bool memberGroupLinkTableRefs,
        bool frontingMemberTableRefs,
      })
    >;
typedef $$MemberGroupTableTableCreateCompanionBuilder =
    MemberGroupTableCompanion Function({
      required String id,
      required String name,
      required String description,
      required int colorValue,
      Value<bool> archived,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$MemberGroupTableTableUpdateCompanionBuilder =
    MemberGroupTableCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> description,
      Value<int> colorValue,
      Value<bool> archived,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> sortOrder,
      Value<int> rowid,
    });

final class $$MemberGroupTableTableReferences
    extends
        BaseReferences<
          _$AllOfMeDatabase,
          $MemberGroupTableTable,
          MemberGroupRow
        > {
  $$MemberGroupTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<
    $MemberGroupLinkTableTable,
    List<MemberGroupLinkRow>
  >
  _memberGroupLinkTableRefsTable(_$AllOfMeDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.memberGroupLinkTable,
        aliasName: 'member_groups__id__member_group_links__group_id',
      );

  $$MemberGroupLinkTableTableProcessedTableManager
  get memberGroupLinkTableRefs {
    final manager = $$MemberGroupLinkTableTableTableManager(
      $_db,
      $_db.memberGroupLinkTable,
    ).filter((f) => f.groupId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _memberGroupLinkTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MemberGroupTableTableFilterComposer
    extends Composer<_$AllOfMeDatabase, $MemberGroupTableTable> {
  $$MemberGroupTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> memberGroupLinkTableRefs(
    Expression<bool> Function($$MemberGroupLinkTableTableFilterComposer f) f,
  ) {
    final $$MemberGroupLinkTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.memberGroupLinkTable,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MemberGroupLinkTableTableFilterComposer(
            $db: $db,
            $table: $db.memberGroupLinkTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MemberGroupTableTableOrderingComposer
    extends Composer<_$AllOfMeDatabase, $MemberGroupTableTable> {
  $$MemberGroupTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MemberGroupTableTableAnnotationComposer
    extends Composer<_$AllOfMeDatabase, $MemberGroupTableTable> {
  $$MemberGroupTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  Expression<T> memberGroupLinkTableRefs<T extends Object>(
    Expression<T> Function($$MemberGroupLinkTableTableAnnotationComposer a) f,
  ) {
    final $$MemberGroupLinkTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.memberGroupLinkTable,
          getReferencedColumn: (t) => t.groupId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$MemberGroupLinkTableTableAnnotationComposer(
                $db: $db,
                $table: $db.memberGroupLinkTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$MemberGroupTableTableTableManager
    extends
        RootTableManager<
          _$AllOfMeDatabase,
          $MemberGroupTableTable,
          MemberGroupRow,
          $$MemberGroupTableTableFilterComposer,
          $$MemberGroupTableTableOrderingComposer,
          $$MemberGroupTableTableAnnotationComposer,
          $$MemberGroupTableTableCreateCompanionBuilder,
          $$MemberGroupTableTableUpdateCompanionBuilder,
          (MemberGroupRow, $$MemberGroupTableTableReferences),
          MemberGroupRow,
          PrefetchHooks Function({bool memberGroupLinkTableRefs})
        > {
  $$MemberGroupTableTableTableManager(
    _$AllOfMeDatabase db,
    $MemberGroupTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MemberGroupTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MemberGroupTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MemberGroupTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<int> colorValue = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MemberGroupTableCompanion(
                id: id,
                name: name,
                description: description,
                colorValue: colorValue,
                archived: archived,
                createdAt: createdAt,
                updatedAt: updatedAt,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String description,
                required int colorValue,
                Value<bool> archived = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MemberGroupTableCompanion.insert(
                id: id,
                name: name,
                description: description,
                colorValue: colorValue,
                archived: archived,
                createdAt: createdAt,
                updatedAt: updatedAt,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MemberGroupTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({memberGroupLinkTableRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (memberGroupLinkTableRefs) db.memberGroupLinkTable,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (memberGroupLinkTableRefs)
                    await $_getPrefetchedData<
                      MemberGroupRow,
                      $MemberGroupTableTable,
                      MemberGroupLinkRow
                    >(
                      currentTable: table,
                      referencedTable: $$MemberGroupTableTableReferences
                          ._memberGroupLinkTableRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$MemberGroupTableTableReferences(
                            db,
                            table,
                            p0,
                          ).memberGroupLinkTableRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.groupId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$MemberGroupTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AllOfMeDatabase,
      $MemberGroupTableTable,
      MemberGroupRow,
      $$MemberGroupTableTableFilterComposer,
      $$MemberGroupTableTableOrderingComposer,
      $$MemberGroupTableTableAnnotationComposer,
      $$MemberGroupTableTableCreateCompanionBuilder,
      $$MemberGroupTableTableUpdateCompanionBuilder,
      (MemberGroupRow, $$MemberGroupTableTableReferences),
      MemberGroupRow,
      PrefetchHooks Function({bool memberGroupLinkTableRefs})
    >;
typedef $$MemberGroupLinkTableTableCreateCompanionBuilder =
    MemberGroupLinkTableCompanion Function({
      required String memberId,
      required String groupId,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$MemberGroupLinkTableTableUpdateCompanionBuilder =
    MemberGroupLinkTableCompanion Function({
      Value<String> memberId,
      Value<String> groupId,
      Value<int> sortOrder,
      Value<int> rowid,
    });

final class $$MemberGroupLinkTableTableReferences
    extends
        BaseReferences<
          _$AllOfMeDatabase,
          $MemberGroupLinkTableTable,
          MemberGroupLinkRow
        > {
  $$MemberGroupLinkTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $MemberTableTable _memberIdTable(_$AllOfMeDatabase db) =>
      db.memberTable.createAlias('member_group_links__member_id__members__id');

  $$MemberTableTableProcessedTableManager get memberId {
    final $_column = $_itemColumn<String>('member_id')!;

    final manager = $$MemberTableTableTableManager(
      $_db,
      $_db.memberTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_memberIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $MemberGroupTableTable _groupIdTable(_$AllOfMeDatabase db) => db
      .memberGroupTable
      .createAlias('member_group_links__group_id__member_groups__id');

  $$MemberGroupTableTableProcessedTableManager get groupId {
    final $_column = $_itemColumn<String>('group_id')!;

    final manager = $$MemberGroupTableTableTableManager(
      $_db,
      $_db.memberGroupTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_groupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MemberGroupLinkTableTableFilterComposer
    extends Composer<_$AllOfMeDatabase, $MemberGroupLinkTableTable> {
  $$MemberGroupLinkTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  $$MemberTableTableFilterComposer get memberId {
    final $$MemberTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.memberTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MemberTableTableFilterComposer(
            $db: $db,
            $table: $db.memberTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MemberGroupTableTableFilterComposer get groupId {
    final $$MemberGroupTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.memberGroupTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MemberGroupTableTableFilterComposer(
            $db: $db,
            $table: $db.memberGroupTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MemberGroupLinkTableTableOrderingComposer
    extends Composer<_$AllOfMeDatabase, $MemberGroupLinkTableTable> {
  $$MemberGroupLinkTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  $$MemberTableTableOrderingComposer get memberId {
    final $$MemberTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.memberTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MemberTableTableOrderingComposer(
            $db: $db,
            $table: $db.memberTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MemberGroupTableTableOrderingComposer get groupId {
    final $$MemberGroupTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.memberGroupTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MemberGroupTableTableOrderingComposer(
            $db: $db,
            $table: $db.memberGroupTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MemberGroupLinkTableTableAnnotationComposer
    extends Composer<_$AllOfMeDatabase, $MemberGroupLinkTableTable> {
  $$MemberGroupLinkTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  $$MemberTableTableAnnotationComposer get memberId {
    final $$MemberTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.memberTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MemberTableTableAnnotationComposer(
            $db: $db,
            $table: $db.memberTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MemberGroupTableTableAnnotationComposer get groupId {
    final $$MemberGroupTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.memberGroupTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MemberGroupTableTableAnnotationComposer(
            $db: $db,
            $table: $db.memberGroupTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MemberGroupLinkTableTableTableManager
    extends
        RootTableManager<
          _$AllOfMeDatabase,
          $MemberGroupLinkTableTable,
          MemberGroupLinkRow,
          $$MemberGroupLinkTableTableFilterComposer,
          $$MemberGroupLinkTableTableOrderingComposer,
          $$MemberGroupLinkTableTableAnnotationComposer,
          $$MemberGroupLinkTableTableCreateCompanionBuilder,
          $$MemberGroupLinkTableTableUpdateCompanionBuilder,
          (MemberGroupLinkRow, $$MemberGroupLinkTableTableReferences),
          MemberGroupLinkRow,
          PrefetchHooks Function({bool memberId, bool groupId})
        > {
  $$MemberGroupLinkTableTableTableManager(
    _$AllOfMeDatabase db,
    $MemberGroupLinkTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MemberGroupLinkTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MemberGroupLinkTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$MemberGroupLinkTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> memberId = const Value.absent(),
                Value<String> groupId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MemberGroupLinkTableCompanion(
                memberId: memberId,
                groupId: groupId,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String memberId,
                required String groupId,
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MemberGroupLinkTableCompanion.insert(
                memberId: memberId,
                groupId: groupId,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MemberGroupLinkTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({memberId = false, groupId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (memberId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.memberId,
                                referencedTable:
                                    $$MemberGroupLinkTableTableReferences
                                        ._memberIdTable(db),
                                referencedColumn:
                                    $$MemberGroupLinkTableTableReferences
                                        ._memberIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (groupId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.groupId,
                                referencedTable:
                                    $$MemberGroupLinkTableTableReferences
                                        ._groupIdTable(db),
                                referencedColumn:
                                    $$MemberGroupLinkTableTableReferences
                                        ._groupIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$MemberGroupLinkTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AllOfMeDatabase,
      $MemberGroupLinkTableTable,
      MemberGroupLinkRow,
      $$MemberGroupLinkTableTableFilterComposer,
      $$MemberGroupLinkTableTableOrderingComposer,
      $$MemberGroupLinkTableTableAnnotationComposer,
      $$MemberGroupLinkTableTableCreateCompanionBuilder,
      $$MemberGroupLinkTableTableUpdateCompanionBuilder,
      (MemberGroupLinkRow, $$MemberGroupLinkTableTableReferences),
      MemberGroupLinkRow,
      PrefetchHooks Function({bool memberId, bool groupId})
    >;
typedef $$FrontingMemberTableTableCreateCompanionBuilder =
    FrontingMemberTableCompanion Function({
      required String memberId,
      required int sortOrder,
      Value<int> rowid,
    });
typedef $$FrontingMemberTableTableUpdateCompanionBuilder =
    FrontingMemberTableCompanion Function({
      Value<String> memberId,
      Value<int> sortOrder,
      Value<int> rowid,
    });

final class $$FrontingMemberTableTableReferences
    extends
        BaseReferences<
          _$AllOfMeDatabase,
          $FrontingMemberTableTable,
          FrontingMemberRow
        > {
  $$FrontingMemberTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $MemberTableTable _memberIdTable(_$AllOfMeDatabase db) =>
      db.memberTable.createAlias('fronting_members__member_id__members__id');

  $$MemberTableTableProcessedTableManager get memberId {
    final $_column = $_itemColumn<String>('member_id')!;

    final manager = $$MemberTableTableTableManager(
      $_db,
      $_db.memberTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_memberIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FrontingMemberTableTableFilterComposer
    extends Composer<_$AllOfMeDatabase, $FrontingMemberTableTable> {
  $$FrontingMemberTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  $$MemberTableTableFilterComposer get memberId {
    final $$MemberTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.memberTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MemberTableTableFilterComposer(
            $db: $db,
            $table: $db.memberTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FrontingMemberTableTableOrderingComposer
    extends Composer<_$AllOfMeDatabase, $FrontingMemberTableTable> {
  $$FrontingMemberTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  $$MemberTableTableOrderingComposer get memberId {
    final $$MemberTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.memberTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MemberTableTableOrderingComposer(
            $db: $db,
            $table: $db.memberTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FrontingMemberTableTableAnnotationComposer
    extends Composer<_$AllOfMeDatabase, $FrontingMemberTableTable> {
  $$FrontingMemberTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  $$MemberTableTableAnnotationComposer get memberId {
    final $$MemberTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.memberTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MemberTableTableAnnotationComposer(
            $db: $db,
            $table: $db.memberTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FrontingMemberTableTableTableManager
    extends
        RootTableManager<
          _$AllOfMeDatabase,
          $FrontingMemberTableTable,
          FrontingMemberRow,
          $$FrontingMemberTableTableFilterComposer,
          $$FrontingMemberTableTableOrderingComposer,
          $$FrontingMemberTableTableAnnotationComposer,
          $$FrontingMemberTableTableCreateCompanionBuilder,
          $$FrontingMemberTableTableUpdateCompanionBuilder,
          (FrontingMemberRow, $$FrontingMemberTableTableReferences),
          FrontingMemberRow,
          PrefetchHooks Function({bool memberId})
        > {
  $$FrontingMemberTableTableTableManager(
    _$AllOfMeDatabase db,
    $FrontingMemberTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FrontingMemberTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FrontingMemberTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$FrontingMemberTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> memberId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FrontingMemberTableCompanion(
                memberId: memberId,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String memberId,
                required int sortOrder,
                Value<int> rowid = const Value.absent(),
              }) => FrontingMemberTableCompanion.insert(
                memberId: memberId,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FrontingMemberTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({memberId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (memberId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.memberId,
                                referencedTable:
                                    $$FrontingMemberTableTableReferences
                                        ._memberIdTable(db),
                                referencedColumn:
                                    $$FrontingMemberTableTableReferences
                                        ._memberIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$FrontingMemberTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AllOfMeDatabase,
      $FrontingMemberTableTable,
      FrontingMemberRow,
      $$FrontingMemberTableTableFilterComposer,
      $$FrontingMemberTableTableOrderingComposer,
      $$FrontingMemberTableTableAnnotationComposer,
      $$FrontingMemberTableTableCreateCompanionBuilder,
      $$FrontingMemberTableTableUpdateCompanionBuilder,
      (FrontingMemberRow, $$FrontingMemberTableTableReferences),
      FrontingMemberRow,
      PrefetchHooks Function({bool memberId})
    >;
typedef $$FrontSessionTableTableCreateCompanionBuilder =
    FrontSessionTableCompanion Function({
      required String id,
      required String memberId,
      required String memberName,
      required DateTime startedAt,
      Value<DateTime?> endedAt,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$FrontSessionTableTableUpdateCompanionBuilder =
    FrontSessionTableCompanion Function({
      Value<String> id,
      Value<String> memberId,
      Value<String> memberName,
      Value<DateTime> startedAt,
      Value<DateTime?> endedAt,
      Value<int> sortOrder,
      Value<int> rowid,
    });

class $$FrontSessionTableTableFilterComposer
    extends Composer<_$AllOfMeDatabase, $FrontSessionTableTable> {
  $$FrontSessionTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get memberId => $composableBuilder(
    column: $table.memberId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get memberName => $composableBuilder(
    column: $table.memberName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FrontSessionTableTableOrderingComposer
    extends Composer<_$AllOfMeDatabase, $FrontSessionTableTable> {
  $$FrontSessionTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memberId => $composableBuilder(
    column: $table.memberId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memberName => $composableBuilder(
    column: $table.memberName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FrontSessionTableTableAnnotationComposer
    extends Composer<_$AllOfMeDatabase, $FrontSessionTableTable> {
  $$FrontSessionTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get memberId =>
      $composableBuilder(column: $table.memberId, builder: (column) => column);

  GeneratedColumn<String> get memberName => $composableBuilder(
    column: $table.memberName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$FrontSessionTableTableTableManager
    extends
        RootTableManager<
          _$AllOfMeDatabase,
          $FrontSessionTableTable,
          FrontSessionRow,
          $$FrontSessionTableTableFilterComposer,
          $$FrontSessionTableTableOrderingComposer,
          $$FrontSessionTableTableAnnotationComposer,
          $$FrontSessionTableTableCreateCompanionBuilder,
          $$FrontSessionTableTableUpdateCompanionBuilder,
          (
            FrontSessionRow,
            BaseReferences<
              _$AllOfMeDatabase,
              $FrontSessionTableTable,
              FrontSessionRow
            >,
          ),
          FrontSessionRow,
          PrefetchHooks Function()
        > {
  $$FrontSessionTableTableTableManager(
    _$AllOfMeDatabase db,
    $FrontSessionTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FrontSessionTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FrontSessionTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FrontSessionTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> memberId = const Value.absent(),
                Value<String> memberName = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FrontSessionTableCompanion(
                id: id,
                memberId: memberId,
                memberName: memberName,
                startedAt: startedAt,
                endedAt: endedAt,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String memberId,
                required String memberName,
                required DateTime startedAt,
                Value<DateTime?> endedAt = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FrontSessionTableCompanion.insert(
                id: id,
                memberId: memberId,
                memberName: memberName,
                startedAt: startedAt,
                endedAt: endedAt,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FrontSessionTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AllOfMeDatabase,
      $FrontSessionTableTable,
      FrontSessionRow,
      $$FrontSessionTableTableFilterComposer,
      $$FrontSessionTableTableOrderingComposer,
      $$FrontSessionTableTableAnnotationComposer,
      $$FrontSessionTableTableCreateCompanionBuilder,
      $$FrontSessionTableTableUpdateCompanionBuilder,
      (
        FrontSessionRow,
        BaseReferences<
          _$AllOfMeDatabase,
          $FrontSessionTableTable,
          FrontSessionRow
        >,
      ),
      FrontSessionRow,
      PrefetchHooks Function()
    >;
typedef $$TimelineEntryTableTableCreateCompanionBuilder =
    TimelineEntryTableCompanion Function({
      required String id,
      required String type,
      required String action,
      required DateTime createdAt,
      Value<String?> memberId,
      Value<String?> memberName,
      Value<String?> note,
      Value<DateTime?> deletedAt,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$TimelineEntryTableTableUpdateCompanionBuilder =
    TimelineEntryTableCompanion Function({
      Value<String> id,
      Value<String> type,
      Value<String> action,
      Value<DateTime> createdAt,
      Value<String?> memberId,
      Value<String?> memberName,
      Value<String?> note,
      Value<DateTime?> deletedAt,
      Value<int> sortOrder,
      Value<int> rowid,
    });

class $$TimelineEntryTableTableFilterComposer
    extends Composer<_$AllOfMeDatabase, $TimelineEntryTableTable> {
  $$TimelineEntryTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get memberId => $composableBuilder(
    column: $table.memberId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get memberName => $composableBuilder(
    column: $table.memberName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TimelineEntryTableTableOrderingComposer
    extends Composer<_$AllOfMeDatabase, $TimelineEntryTableTable> {
  $$TimelineEntryTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memberId => $composableBuilder(
    column: $table.memberId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memberName => $composableBuilder(
    column: $table.memberName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TimelineEntryTableTableAnnotationComposer
    extends Composer<_$AllOfMeDatabase, $TimelineEntryTableTable> {
  $$TimelineEntryTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get memberId =>
      $composableBuilder(column: $table.memberId, builder: (column) => column);

  GeneratedColumn<String> get memberName => $composableBuilder(
    column: $table.memberName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$TimelineEntryTableTableTableManager
    extends
        RootTableManager<
          _$AllOfMeDatabase,
          $TimelineEntryTableTable,
          TimelineEntryRow,
          $$TimelineEntryTableTableFilterComposer,
          $$TimelineEntryTableTableOrderingComposer,
          $$TimelineEntryTableTableAnnotationComposer,
          $$TimelineEntryTableTableCreateCompanionBuilder,
          $$TimelineEntryTableTableUpdateCompanionBuilder,
          (
            TimelineEntryRow,
            BaseReferences<
              _$AllOfMeDatabase,
              $TimelineEntryTableTable,
              TimelineEntryRow
            >,
          ),
          TimelineEntryRow,
          PrefetchHooks Function()
        > {
  $$TimelineEntryTableTableTableManager(
    _$AllOfMeDatabase db,
    $TimelineEntryTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TimelineEntryTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TimelineEntryTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TimelineEntryTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> action = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> memberId = const Value.absent(),
                Value<String?> memberName = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TimelineEntryTableCompanion(
                id: id,
                type: type,
                action: action,
                createdAt: createdAt,
                memberId: memberId,
                memberName: memberName,
                note: note,
                deletedAt: deletedAt,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String type,
                required String action,
                required DateTime createdAt,
                Value<String?> memberId = const Value.absent(),
                Value<String?> memberName = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TimelineEntryTableCompanion.insert(
                id: id,
                type: type,
                action: action,
                createdAt: createdAt,
                memberId: memberId,
                memberName: memberName,
                note: note,
                deletedAt: deletedAt,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TimelineEntryTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AllOfMeDatabase,
      $TimelineEntryTableTable,
      TimelineEntryRow,
      $$TimelineEntryTableTableFilterComposer,
      $$TimelineEntryTableTableOrderingComposer,
      $$TimelineEntryTableTableAnnotationComposer,
      $$TimelineEntryTableTableCreateCompanionBuilder,
      $$TimelineEntryTableTableUpdateCompanionBuilder,
      (
        TimelineEntryRow,
        BaseReferences<
          _$AllOfMeDatabase,
          $TimelineEntryTableTable,
          TimelineEntryRow
        >,
      ),
      TimelineEntryRow,
      PrefetchHooks Function()
    >;

class $AllOfMeDatabaseManager {
  final _$AllOfMeDatabase _db;
  $AllOfMeDatabaseManager(this._db);
  $$SystemProfileTableTableTableManager get systemProfileTable =>
      $$SystemProfileTableTableTableManager(_db, _db.systemProfileTable);
  $$SecuritySettingsTableTableTableManager get securitySettingsTable =>
      $$SecuritySettingsTableTableTableManager(_db, _db.securitySettingsTable);
  $$MemberTableTableTableManager get memberTable =>
      $$MemberTableTableTableManager(_db, _db.memberTable);
  $$MemberGroupTableTableTableManager get memberGroupTable =>
      $$MemberGroupTableTableTableManager(_db, _db.memberGroupTable);
  $$MemberGroupLinkTableTableTableManager get memberGroupLinkTable =>
      $$MemberGroupLinkTableTableTableManager(_db, _db.memberGroupLinkTable);
  $$FrontingMemberTableTableTableManager get frontingMemberTable =>
      $$FrontingMemberTableTableTableManager(_db, _db.frontingMemberTable);
  $$FrontSessionTableTableTableManager get frontSessionTable =>
      $$FrontSessionTableTableTableManager(_db, _db.frontSessionTable);
  $$TimelineEntryTableTableTableManager get timelineEntryTable =>
      $$TimelineEntryTableTableTableManager(_db, _db.timelineEntryTable);
}
