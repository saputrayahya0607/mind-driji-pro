// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ScreenTimeDailyTable extends ScreenTimeDaily
    with TableInfo<$ScreenTimeDailyTable, ScreenTimeDailyData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScreenTimeDailyTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('legacy'),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalUsageMillisMeta = const VerificationMeta(
    'totalUsageMillis',
  );
  @override
  late final GeneratedColumn<BigInt> totalUsageMillis = GeneratedColumn<BigInt>(
    'total_usage_millis',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _collectedAtMeta = const VerificationMeta(
    'collectedAt',
  );
  @override
  late final GeneratedColumn<DateTime> collectedAt = GeneratedColumn<DateTime>(
    'collected_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _syncAttemptsMeta = const VerificationMeta(
    'syncAttempts',
  );
  @override
  late final GeneratedColumn<int> syncAttempts = GeneratedColumn<int>(
    'sync_attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastSyncErrorMeta = const VerificationMeta(
    'lastSyncError',
  );
  @override
  late final GeneratedColumn<String> lastSyncError = GeneratedColumn<String>(
    'last_sync_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    userId,
    deviceId,
    date,
    totalUsageMillis,
    collectedAt,
    syncStatus,
    syncAttempts,
    lastSyncError,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'screen_time_daily';
  @override
  VerificationContext validateIntegrity(
    Insertable<ScreenTimeDailyData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('total_usage_millis')) {
      context.handle(
        _totalUsageMillisMeta,
        totalUsageMillis.isAcceptableOrUnknown(
          data['total_usage_millis']!,
          _totalUsageMillisMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalUsageMillisMeta);
    }
    if (data.containsKey('collected_at')) {
      context.handle(
        _collectedAtMeta,
        collectedAt.isAcceptableOrUnknown(
          data['collected_at']!,
          _collectedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_collectedAtMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('sync_attempts')) {
      context.handle(
        _syncAttemptsMeta,
        syncAttempts.isAcceptableOrUnknown(
          data['sync_attempts']!,
          _syncAttemptsMeta,
        ),
      );
    }
    if (data.containsKey('last_sync_error')) {
      context.handle(
        _lastSyncErrorMeta,
        lastSyncError.isAcceptableOrUnknown(
          data['last_sync_error']!,
          _lastSyncErrorMeta,
        ),
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {userId, deviceId, date},
  ];
  @override
  ScreenTimeDailyData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScreenTimeDailyData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      totalUsageMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}total_usage_millis'],
      )!,
      collectedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}collected_at'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      syncAttempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_attempts'],
      )!,
      lastSyncError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_sync_error'],
      ),
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
  $ScreenTimeDailyTable createAlias(String alias) {
    return $ScreenTimeDailyTable(attachedDatabase, alias);
  }
}

class ScreenTimeDailyData extends DataClass
    implements Insertable<ScreenTimeDailyData> {
  final String id;
  final String userId;
  final String deviceId;
  final String date;
  final BigInt totalUsageMillis;
  final DateTime collectedAt;
  final String syncStatus;
  final int syncAttempts;
  final String? lastSyncError;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ScreenTimeDailyData({
    required this.id,
    required this.userId,
    required this.deviceId,
    required this.date,
    required this.totalUsageMillis,
    required this.collectedAt,
    required this.syncStatus,
    required this.syncAttempts,
    this.lastSyncError,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['device_id'] = Variable<String>(deviceId);
    map['date'] = Variable<String>(date);
    map['total_usage_millis'] = Variable<BigInt>(totalUsageMillis);
    map['collected_at'] = Variable<DateTime>(collectedAt);
    map['sync_status'] = Variable<String>(syncStatus);
    map['sync_attempts'] = Variable<int>(syncAttempts);
    if (!nullToAbsent || lastSyncError != null) {
      map['last_sync_error'] = Variable<String>(lastSyncError);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ScreenTimeDailyCompanion toCompanion(bool nullToAbsent) {
    return ScreenTimeDailyCompanion(
      id: Value(id),
      userId: Value(userId),
      deviceId: Value(deviceId),
      date: Value(date),
      totalUsageMillis: Value(totalUsageMillis),
      collectedAt: Value(collectedAt),
      syncStatus: Value(syncStatus),
      syncAttempts: Value(syncAttempts),
      lastSyncError: lastSyncError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncError),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ScreenTimeDailyData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScreenTimeDailyData(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      date: serializer.fromJson<String>(json['date']),
      totalUsageMillis: serializer.fromJson<BigInt>(json['totalUsageMillis']),
      collectedAt: serializer.fromJson<DateTime>(json['collectedAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      syncAttempts: serializer.fromJson<int>(json['syncAttempts']),
      lastSyncError: serializer.fromJson<String?>(json['lastSyncError']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'deviceId': serializer.toJson<String>(deviceId),
      'date': serializer.toJson<String>(date),
      'totalUsageMillis': serializer.toJson<BigInt>(totalUsageMillis),
      'collectedAt': serializer.toJson<DateTime>(collectedAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'syncAttempts': serializer.toJson<int>(syncAttempts),
      'lastSyncError': serializer.toJson<String?>(lastSyncError),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ScreenTimeDailyData copyWith({
    String? id,
    String? userId,
    String? deviceId,
    String? date,
    BigInt? totalUsageMillis,
    DateTime? collectedAt,
    String? syncStatus,
    int? syncAttempts,
    Value<String?> lastSyncError = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ScreenTimeDailyData(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    deviceId: deviceId ?? this.deviceId,
    date: date ?? this.date,
    totalUsageMillis: totalUsageMillis ?? this.totalUsageMillis,
    collectedAt: collectedAt ?? this.collectedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    syncAttempts: syncAttempts ?? this.syncAttempts,
    lastSyncError: lastSyncError.present
        ? lastSyncError.value
        : this.lastSyncError,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ScreenTimeDailyData copyWithCompanion(ScreenTimeDailyCompanion data) {
    return ScreenTimeDailyData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      date: data.date.present ? data.date.value : this.date,
      totalUsageMillis: data.totalUsageMillis.present
          ? data.totalUsageMillis.value
          : this.totalUsageMillis,
      collectedAt: data.collectedAt.present
          ? data.collectedAt.value
          : this.collectedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      syncAttempts: data.syncAttempts.present
          ? data.syncAttempts.value
          : this.syncAttempts,
      lastSyncError: data.lastSyncError.present
          ? data.lastSyncError.value
          : this.lastSyncError,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScreenTimeDailyData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('deviceId: $deviceId, ')
          ..write('date: $date, ')
          ..write('totalUsageMillis: $totalUsageMillis, ')
          ..write('collectedAt: $collectedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('syncAttempts: $syncAttempts, ')
          ..write('lastSyncError: $lastSyncError, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    deviceId,
    date,
    totalUsageMillis,
    collectedAt,
    syncStatus,
    syncAttempts,
    lastSyncError,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScreenTimeDailyData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.deviceId == this.deviceId &&
          other.date == this.date &&
          other.totalUsageMillis == this.totalUsageMillis &&
          other.collectedAt == this.collectedAt &&
          other.syncStatus == this.syncStatus &&
          other.syncAttempts == this.syncAttempts &&
          other.lastSyncError == this.lastSyncError &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ScreenTimeDailyCompanion extends UpdateCompanion<ScreenTimeDailyData> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> deviceId;
  final Value<String> date;
  final Value<BigInt> totalUsageMillis;
  final Value<DateTime> collectedAt;
  final Value<String> syncStatus;
  final Value<int> syncAttempts;
  final Value<String?> lastSyncError;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ScreenTimeDailyCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.date = const Value.absent(),
    this.totalUsageMillis = const Value.absent(),
    this.collectedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.syncAttempts = const Value.absent(),
    this.lastSyncError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ScreenTimeDailyCompanion.insert({
    required String id,
    required String userId,
    this.deviceId = const Value.absent(),
    required String date,
    required BigInt totalUsageMillis,
    required DateTime collectedAt,
    this.syncStatus = const Value.absent(),
    this.syncAttempts = const Value.absent(),
    this.lastSyncError = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       date = Value(date),
       totalUsageMillis = Value(totalUsageMillis),
       collectedAt = Value(collectedAt),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ScreenTimeDailyData> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? deviceId,
    Expression<String>? date,
    Expression<BigInt>? totalUsageMillis,
    Expression<DateTime>? collectedAt,
    Expression<String>? syncStatus,
    Expression<int>? syncAttempts,
    Expression<String>? lastSyncError,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (deviceId != null) 'device_id': deviceId,
      if (date != null) 'date': date,
      if (totalUsageMillis != null) 'total_usage_millis': totalUsageMillis,
      if (collectedAt != null) 'collected_at': collectedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (syncAttempts != null) 'sync_attempts': syncAttempts,
      if (lastSyncError != null) 'last_sync_error': lastSyncError,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ScreenTimeDailyCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? deviceId,
    Value<String>? date,
    Value<BigInt>? totalUsageMillis,
    Value<DateTime>? collectedAt,
    Value<String>? syncStatus,
    Value<int>? syncAttempts,
    Value<String?>? lastSyncError,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ScreenTimeDailyCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      deviceId: deviceId ?? this.deviceId,
      date: date ?? this.date,
      totalUsageMillis: totalUsageMillis ?? this.totalUsageMillis,
      collectedAt: collectedAt ?? this.collectedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      syncAttempts: syncAttempts ?? this.syncAttempts,
      lastSyncError: lastSyncError ?? this.lastSyncError,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (totalUsageMillis.present) {
      map['total_usage_millis'] = Variable<BigInt>(totalUsageMillis.value);
    }
    if (collectedAt.present) {
      map['collected_at'] = Variable<DateTime>(collectedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (syncAttempts.present) {
      map['sync_attempts'] = Variable<int>(syncAttempts.value);
    }
    if (lastSyncError.present) {
      map['last_sync_error'] = Variable<String>(lastSyncError.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScreenTimeDailyCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('deviceId: $deviceId, ')
          ..write('date: $date, ')
          ..write('totalUsageMillis: $totalUsageMillis, ')
          ..write('collectedAt: $collectedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('syncAttempts: $syncAttempts, ')
          ..write('lastSyncError: $lastSyncError, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppUsageDailyTable extends AppUsageDaily
    with TableInfo<$AppUsageDailyTable, AppUsageDailyData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppUsageDailyTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('legacy'),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _packageNameMeta = const VerificationMeta(
    'packageName',
  );
  @override
  late final GeneratedColumn<String> packageName = GeneratedColumn<String>(
    'package_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _appNameMeta = const VerificationMeta(
    'appName',
  );
  @override
  late final GeneratedColumn<String> appName = GeneratedColumn<String>(
    'app_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usageMillisMeta = const VerificationMeta(
    'usageMillis',
  );
  @override
  late final GeneratedColumn<BigInt> usageMillis = GeneratedColumn<BigInt>(
    'usage_millis',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _collectedAtMeta = const VerificationMeta(
    'collectedAt',
  );
  @override
  late final GeneratedColumn<DateTime> collectedAt = GeneratedColumn<DateTime>(
    'collected_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _syncAttemptsMeta = const VerificationMeta(
    'syncAttempts',
  );
  @override
  late final GeneratedColumn<int> syncAttempts = GeneratedColumn<int>(
    'sync_attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastSyncErrorMeta = const VerificationMeta(
    'lastSyncError',
  );
  @override
  late final GeneratedColumn<String> lastSyncError = GeneratedColumn<String>(
    'last_sync_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    userId,
    deviceId,
    date,
    packageName,
    appName,
    usageMillis,
    collectedAt,
    syncStatus,
    syncAttempts,
    lastSyncError,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_usage_daily';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppUsageDailyData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('package_name')) {
      context.handle(
        _packageNameMeta,
        packageName.isAcceptableOrUnknown(
          data['package_name']!,
          _packageNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_packageNameMeta);
    }
    if (data.containsKey('app_name')) {
      context.handle(
        _appNameMeta,
        appName.isAcceptableOrUnknown(data['app_name']!, _appNameMeta),
      );
    } else if (isInserting) {
      context.missing(_appNameMeta);
    }
    if (data.containsKey('usage_millis')) {
      context.handle(
        _usageMillisMeta,
        usageMillis.isAcceptableOrUnknown(
          data['usage_millis']!,
          _usageMillisMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_usageMillisMeta);
    }
    if (data.containsKey('collected_at')) {
      context.handle(
        _collectedAtMeta,
        collectedAt.isAcceptableOrUnknown(
          data['collected_at']!,
          _collectedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_collectedAtMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('sync_attempts')) {
      context.handle(
        _syncAttemptsMeta,
        syncAttempts.isAcceptableOrUnknown(
          data['sync_attempts']!,
          _syncAttemptsMeta,
        ),
      );
    }
    if (data.containsKey('last_sync_error')) {
      context.handle(
        _lastSyncErrorMeta,
        lastSyncError.isAcceptableOrUnknown(
          data['last_sync_error']!,
          _lastSyncErrorMeta,
        ),
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {userId, deviceId, date, packageName},
  ];
  @override
  AppUsageDailyData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppUsageDailyData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      packageName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}package_name'],
      )!,
      appName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}app_name'],
      )!,
      usageMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}usage_millis'],
      )!,
      collectedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}collected_at'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      syncAttempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_attempts'],
      )!,
      lastSyncError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_sync_error'],
      ),
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
  $AppUsageDailyTable createAlias(String alias) {
    return $AppUsageDailyTable(attachedDatabase, alias);
  }
}

class AppUsageDailyData extends DataClass
    implements Insertable<AppUsageDailyData> {
  final String id;
  final String userId;
  final String deviceId;
  final String date;
  final String packageName;
  final String appName;
  final BigInt usageMillis;
  final DateTime collectedAt;
  final String syncStatus;
  final int syncAttempts;
  final String? lastSyncError;
  final DateTime createdAt;
  final DateTime updatedAt;
  const AppUsageDailyData({
    required this.id,
    required this.userId,
    required this.deviceId,
    required this.date,
    required this.packageName,
    required this.appName,
    required this.usageMillis,
    required this.collectedAt,
    required this.syncStatus,
    required this.syncAttempts,
    this.lastSyncError,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['device_id'] = Variable<String>(deviceId);
    map['date'] = Variable<String>(date);
    map['package_name'] = Variable<String>(packageName);
    map['app_name'] = Variable<String>(appName);
    map['usage_millis'] = Variable<BigInt>(usageMillis);
    map['collected_at'] = Variable<DateTime>(collectedAt);
    map['sync_status'] = Variable<String>(syncStatus);
    map['sync_attempts'] = Variable<int>(syncAttempts);
    if (!nullToAbsent || lastSyncError != null) {
      map['last_sync_error'] = Variable<String>(lastSyncError);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AppUsageDailyCompanion toCompanion(bool nullToAbsent) {
    return AppUsageDailyCompanion(
      id: Value(id),
      userId: Value(userId),
      deviceId: Value(deviceId),
      date: Value(date),
      packageName: Value(packageName),
      appName: Value(appName),
      usageMillis: Value(usageMillis),
      collectedAt: Value(collectedAt),
      syncStatus: Value(syncStatus),
      syncAttempts: Value(syncAttempts),
      lastSyncError: lastSyncError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncError),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory AppUsageDailyData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppUsageDailyData(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      date: serializer.fromJson<String>(json['date']),
      packageName: serializer.fromJson<String>(json['packageName']),
      appName: serializer.fromJson<String>(json['appName']),
      usageMillis: serializer.fromJson<BigInt>(json['usageMillis']),
      collectedAt: serializer.fromJson<DateTime>(json['collectedAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      syncAttempts: serializer.fromJson<int>(json['syncAttempts']),
      lastSyncError: serializer.fromJson<String?>(json['lastSyncError']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'deviceId': serializer.toJson<String>(deviceId),
      'date': serializer.toJson<String>(date),
      'packageName': serializer.toJson<String>(packageName),
      'appName': serializer.toJson<String>(appName),
      'usageMillis': serializer.toJson<BigInt>(usageMillis),
      'collectedAt': serializer.toJson<DateTime>(collectedAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'syncAttempts': serializer.toJson<int>(syncAttempts),
      'lastSyncError': serializer.toJson<String?>(lastSyncError),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AppUsageDailyData copyWith({
    String? id,
    String? userId,
    String? deviceId,
    String? date,
    String? packageName,
    String? appName,
    BigInt? usageMillis,
    DateTime? collectedAt,
    String? syncStatus,
    int? syncAttempts,
    Value<String?> lastSyncError = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => AppUsageDailyData(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    deviceId: deviceId ?? this.deviceId,
    date: date ?? this.date,
    packageName: packageName ?? this.packageName,
    appName: appName ?? this.appName,
    usageMillis: usageMillis ?? this.usageMillis,
    collectedAt: collectedAt ?? this.collectedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    syncAttempts: syncAttempts ?? this.syncAttempts,
    lastSyncError: lastSyncError.present
        ? lastSyncError.value
        : this.lastSyncError,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AppUsageDailyData copyWithCompanion(AppUsageDailyCompanion data) {
    return AppUsageDailyData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      date: data.date.present ? data.date.value : this.date,
      packageName: data.packageName.present
          ? data.packageName.value
          : this.packageName,
      appName: data.appName.present ? data.appName.value : this.appName,
      usageMillis: data.usageMillis.present
          ? data.usageMillis.value
          : this.usageMillis,
      collectedAt: data.collectedAt.present
          ? data.collectedAt.value
          : this.collectedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      syncAttempts: data.syncAttempts.present
          ? data.syncAttempts.value
          : this.syncAttempts,
      lastSyncError: data.lastSyncError.present
          ? data.lastSyncError.value
          : this.lastSyncError,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppUsageDailyData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('deviceId: $deviceId, ')
          ..write('date: $date, ')
          ..write('packageName: $packageName, ')
          ..write('appName: $appName, ')
          ..write('usageMillis: $usageMillis, ')
          ..write('collectedAt: $collectedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('syncAttempts: $syncAttempts, ')
          ..write('lastSyncError: $lastSyncError, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    deviceId,
    date,
    packageName,
    appName,
    usageMillis,
    collectedAt,
    syncStatus,
    syncAttempts,
    lastSyncError,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppUsageDailyData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.deviceId == this.deviceId &&
          other.date == this.date &&
          other.packageName == this.packageName &&
          other.appName == this.appName &&
          other.usageMillis == this.usageMillis &&
          other.collectedAt == this.collectedAt &&
          other.syncStatus == this.syncStatus &&
          other.syncAttempts == this.syncAttempts &&
          other.lastSyncError == this.lastSyncError &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AppUsageDailyCompanion extends UpdateCompanion<AppUsageDailyData> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> deviceId;
  final Value<String> date;
  final Value<String> packageName;
  final Value<String> appName;
  final Value<BigInt> usageMillis;
  final Value<DateTime> collectedAt;
  final Value<String> syncStatus;
  final Value<int> syncAttempts;
  final Value<String?> lastSyncError;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AppUsageDailyCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.date = const Value.absent(),
    this.packageName = const Value.absent(),
    this.appName = const Value.absent(),
    this.usageMillis = const Value.absent(),
    this.collectedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.syncAttempts = const Value.absent(),
    this.lastSyncError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppUsageDailyCompanion.insert({
    required String id,
    required String userId,
    this.deviceId = const Value.absent(),
    required String date,
    required String packageName,
    required String appName,
    required BigInt usageMillis,
    required DateTime collectedAt,
    this.syncStatus = const Value.absent(),
    this.syncAttempts = const Value.absent(),
    this.lastSyncError = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       date = Value(date),
       packageName = Value(packageName),
       appName = Value(appName),
       usageMillis = Value(usageMillis),
       collectedAt = Value(collectedAt),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<AppUsageDailyData> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? deviceId,
    Expression<String>? date,
    Expression<String>? packageName,
    Expression<String>? appName,
    Expression<BigInt>? usageMillis,
    Expression<DateTime>? collectedAt,
    Expression<String>? syncStatus,
    Expression<int>? syncAttempts,
    Expression<String>? lastSyncError,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (deviceId != null) 'device_id': deviceId,
      if (date != null) 'date': date,
      if (packageName != null) 'package_name': packageName,
      if (appName != null) 'app_name': appName,
      if (usageMillis != null) 'usage_millis': usageMillis,
      if (collectedAt != null) 'collected_at': collectedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (syncAttempts != null) 'sync_attempts': syncAttempts,
      if (lastSyncError != null) 'last_sync_error': lastSyncError,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppUsageDailyCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? deviceId,
    Value<String>? date,
    Value<String>? packageName,
    Value<String>? appName,
    Value<BigInt>? usageMillis,
    Value<DateTime>? collectedAt,
    Value<String>? syncStatus,
    Value<int>? syncAttempts,
    Value<String?>? lastSyncError,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return AppUsageDailyCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      deviceId: deviceId ?? this.deviceId,
      date: date ?? this.date,
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      usageMillis: usageMillis ?? this.usageMillis,
      collectedAt: collectedAt ?? this.collectedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      syncAttempts: syncAttempts ?? this.syncAttempts,
      lastSyncError: lastSyncError ?? this.lastSyncError,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (packageName.present) {
      map['package_name'] = Variable<String>(packageName.value);
    }
    if (appName.present) {
      map['app_name'] = Variable<String>(appName.value);
    }
    if (usageMillis.present) {
      map['usage_millis'] = Variable<BigInt>(usageMillis.value);
    }
    if (collectedAt.present) {
      map['collected_at'] = Variable<DateTime>(collectedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (syncAttempts.present) {
      map['sync_attempts'] = Variable<int>(syncAttempts.value);
    }
    if (lastSyncError.present) {
      map['last_sync_error'] = Variable<String>(lastSyncError.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppUsageDailyCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('deviceId: $deviceId, ')
          ..write('date: $date, ')
          ..write('packageName: $packageName, ')
          ..write('appName: $appName, ')
          ..write('usageMillis: $usageMillis, ')
          ..write('collectedAt: $collectedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('syncAttempts: $syncAttempts, ')
          ..write('lastSyncError: $lastSyncError, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTable extends SyncQueue
    with TableInfo<$SyncQueueTable, SyncQueueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationMeta = const VerificationMeta(
    'operation',
  );
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
    'operation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('upsert'),
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
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entityType,
    entityId,
    operation,
    createdAt,
    retryCount,
    lastError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncQueueData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(
        _operationMeta,
        operation.isAcceptableOrUnknown(data['operation']!, _operationMeta),
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
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      operation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
    );
  }

  @override
  $SyncQueueTable createAlias(String alias) {
    return $SyncQueueTable(attachedDatabase, alias);
  }
}

class SyncQueueData extends DataClass implements Insertable<SyncQueueData> {
  final String id;
  final String entityType;
  final String entityId;
  final String operation;
  final DateTime createdAt;
  final int retryCount;
  final String? lastError;
  const SyncQueueData({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.createdAt,
    required this.retryCount,
    this.lastError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['operation'] = Variable<String>(operation);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['retry_count'] = Variable<int>(retryCount);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  SyncQueueCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueCompanion(
      id: Value(id),
      entityType: Value(entityType),
      entityId: Value(entityId),
      operation: Value(operation),
      createdAt: Value(createdAt),
      retryCount: Value(retryCount),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory SyncQueueData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueData(
      id: serializer.fromJson<String>(json['id']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      operation: serializer.fromJson<String>(json['operation']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'operation': serializer.toJson<String>(operation),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'retryCount': serializer.toJson<int>(retryCount),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  SyncQueueData copyWith({
    String? id,
    String? entityType,
    String? entityId,
    String? operation,
    DateTime? createdAt,
    int? retryCount,
    Value<String?> lastError = const Value.absent(),
  }) => SyncQueueData(
    id: id ?? this.id,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    operation: operation ?? this.operation,
    createdAt: createdAt ?? this.createdAt,
    retryCount: retryCount ?? this.retryCount,
    lastError: lastError.present ? lastError.value : this.lastError,
  );
  SyncQueueData copyWithCompanion(SyncQueueCompanion data) {
    return SyncQueueData(
      id: data.id.present ? data.id.value : this.id,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      operation: data.operation.present ? data.operation.value : this.operation,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueData(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    entityType,
    entityId,
    operation,
    createdAt,
    retryCount,
    lastError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueData &&
          other.id == this.id &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.operation == this.operation &&
          other.createdAt == this.createdAt &&
          other.retryCount == this.retryCount &&
          other.lastError == this.lastError);
}

class SyncQueueCompanion extends UpdateCompanion<SyncQueueData> {
  final Value<String> id;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> operation;
  final Value<DateTime> createdAt;
  final Value<int> retryCount;
  final Value<String?> lastError;
  final Value<int> rowid;
  const SyncQueueCompanion({
    this.id = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.operation = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncQueueCompanion.insert({
    required String id,
    required String entityType,
    required String entityId,
    this.operation = const Value.absent(),
    required DateTime createdAt,
    this.retryCount = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       entityType = Value(entityType),
       entityId = Value(entityId),
       createdAt = Value(createdAt);
  static Insertable<SyncQueueData> custom({
    Expression<String>? id,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? operation,
    Expression<DateTime>? createdAt,
    Expression<int>? retryCount,
    Expression<String>? lastError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (operation != null) 'operation': operation,
      if (createdAt != null) 'created_at': createdAt,
      if (retryCount != null) 'retry_count': retryCount,
      if (lastError != null) 'last_error': lastError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncQueueCompanion copyWith({
    Value<String>? id,
    Value<String>? entityType,
    Value<String>? entityId,
    Value<String>? operation,
    Value<DateTime>? createdAt,
    Value<int>? retryCount,
    Value<String?>? lastError,
    Value<int>? rowid,
  }) {
    return SyncQueueCompanion(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      operation: operation ?? this.operation,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueCompanion(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastError: $lastError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DoomscrollSessionsTable extends DoomscrollSessions
    with TableInfo<$DoomscrollSessionsTable, DoomscrollSessionData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DoomscrollSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('legacy'),
  );
  static const VerificationMeta _packageNameMeta = const VerificationMeta(
    'packageName',
  );
  @override
  late final GeneratedColumn<String> packageName = GeneratedColumn<String>(
    'package_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _appNameMeta = const VerificationMeta(
    'appName',
  );
  @override
  late final GeneratedColumn<String> appName = GeneratedColumn<String>(
    'app_name',
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
  static const VerificationMeta _durationMillisMeta = const VerificationMeta(
    'durationMillis',
  );
  @override
  late final GeneratedColumn<BigInt> durationMillis = GeneratedColumn<BigInt>(
    'duration_millis',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _swipeCountMeta = const VerificationMeta(
    'swipeCount',
  );
  @override
  late final GeneratedColumn<int> swipeCount = GeneratedColumn<int>(
    'swipe_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _downwardSwipeCountMeta =
      const VerificationMeta('downwardSwipeCount');
  @override
  late final GeneratedColumn<int> downwardSwipeCount = GeneratedColumn<int>(
    'downward_swipe_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _upwardSwipeCountMeta = const VerificationMeta(
    'upwardSwipeCount',
  );
  @override
  late final GeneratedColumn<int> upwardSwipeCount = GeneratedColumn<int>(
    'upward_swipe_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _avgInterSwipeMillisMeta =
      const VerificationMeta('avgInterSwipeMillis');
  @override
  late final GeneratedColumn<BigInt> avgInterSwipeMillis =
      GeneratedColumn<BigInt>(
        'avg_inter_swipe_millis',
        aliasedName,
        false,
        type: DriftSqlType.bigInt,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _collectedAtMeta = const VerificationMeta(
    'collectedAt',
  );
  @override
  late final GeneratedColumn<DateTime> collectedAt = GeneratedColumn<DateTime>(
    'collected_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _syncAttemptsMeta = const VerificationMeta(
    'syncAttempts',
  );
  @override
  late final GeneratedColumn<int> syncAttempts = GeneratedColumn<int>(
    'sync_attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastSyncErrorMeta = const VerificationMeta(
    'lastSyncError',
  );
  @override
  late final GeneratedColumn<String> lastSyncError = GeneratedColumn<String>(
    'last_sync_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    userId,
    deviceId,
    packageName,
    appName,
    startedAt,
    endedAt,
    durationMillis,
    swipeCount,
    downwardSwipeCount,
    upwardSwipeCount,
    avgInterSwipeMillis,
    collectedAt,
    syncStatus,
    syncAttempts,
    lastSyncError,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'doomscroll_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<DoomscrollSessionData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    }
    if (data.containsKey('package_name')) {
      context.handle(
        _packageNameMeta,
        packageName.isAcceptableOrUnknown(
          data['package_name']!,
          _packageNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_packageNameMeta);
    }
    if (data.containsKey('app_name')) {
      context.handle(
        _appNameMeta,
        appName.isAcceptableOrUnknown(data['app_name']!, _appNameMeta),
      );
    } else if (isInserting) {
      context.missing(_appNameMeta);
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
    if (data.containsKey('duration_millis')) {
      context.handle(
        _durationMillisMeta,
        durationMillis.isAcceptableOrUnknown(
          data['duration_millis']!,
          _durationMillisMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_durationMillisMeta);
    }
    if (data.containsKey('swipe_count')) {
      context.handle(
        _swipeCountMeta,
        swipeCount.isAcceptableOrUnknown(data['swipe_count']!, _swipeCountMeta),
      );
    } else if (isInserting) {
      context.missing(_swipeCountMeta);
    }
    if (data.containsKey('downward_swipe_count')) {
      context.handle(
        _downwardSwipeCountMeta,
        downwardSwipeCount.isAcceptableOrUnknown(
          data['downward_swipe_count']!,
          _downwardSwipeCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_downwardSwipeCountMeta);
    }
    if (data.containsKey('upward_swipe_count')) {
      context.handle(
        _upwardSwipeCountMeta,
        upwardSwipeCount.isAcceptableOrUnknown(
          data['upward_swipe_count']!,
          _upwardSwipeCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_upwardSwipeCountMeta);
    }
    if (data.containsKey('avg_inter_swipe_millis')) {
      context.handle(
        _avgInterSwipeMillisMeta,
        avgInterSwipeMillis.isAcceptableOrUnknown(
          data['avg_inter_swipe_millis']!,
          _avgInterSwipeMillisMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_avgInterSwipeMillisMeta);
    }
    if (data.containsKey('collected_at')) {
      context.handle(
        _collectedAtMeta,
        collectedAt.isAcceptableOrUnknown(
          data['collected_at']!,
          _collectedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_collectedAtMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('sync_attempts')) {
      context.handle(
        _syncAttemptsMeta,
        syncAttempts.isAcceptableOrUnknown(
          data['sync_attempts']!,
          _syncAttemptsMeta,
        ),
      );
    }
    if (data.containsKey('last_sync_error')) {
      context.handle(
        _lastSyncErrorMeta,
        lastSyncError.isAcceptableOrUnknown(
          data['last_sync_error']!,
          _lastSyncErrorMeta,
        ),
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DoomscrollSessionData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DoomscrollSessionData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      packageName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}package_name'],
      )!,
      appName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}app_name'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      durationMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}duration_millis'],
      )!,
      swipeCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}swipe_count'],
      )!,
      downwardSwipeCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}downward_swipe_count'],
      )!,
      upwardSwipeCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}upward_swipe_count'],
      )!,
      avgInterSwipeMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}avg_inter_swipe_millis'],
      )!,
      collectedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}collected_at'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      syncAttempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_attempts'],
      )!,
      lastSyncError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_sync_error'],
      ),
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
  $DoomscrollSessionsTable createAlias(String alias) {
    return $DoomscrollSessionsTable(attachedDatabase, alias);
  }
}

class DoomscrollSessionData extends DataClass
    implements Insertable<DoomscrollSessionData> {
  final String id;
  final String userId;
  final String deviceId;
  final String packageName;
  final String appName;
  final DateTime startedAt;
  final DateTime? endedAt;
  final BigInt durationMillis;
  final int swipeCount;
  final int downwardSwipeCount;
  final int upwardSwipeCount;
  final BigInt avgInterSwipeMillis;
  final DateTime collectedAt;
  final String syncStatus;
  final int syncAttempts;
  final String? lastSyncError;
  final DateTime createdAt;
  final DateTime updatedAt;
  const DoomscrollSessionData({
    required this.id,
    required this.userId,
    required this.deviceId,
    required this.packageName,
    required this.appName,
    required this.startedAt,
    this.endedAt,
    required this.durationMillis,
    required this.swipeCount,
    required this.downwardSwipeCount,
    required this.upwardSwipeCount,
    required this.avgInterSwipeMillis,
    required this.collectedAt,
    required this.syncStatus,
    required this.syncAttempts,
    this.lastSyncError,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['device_id'] = Variable<String>(deviceId);
    map['package_name'] = Variable<String>(packageName);
    map['app_name'] = Variable<String>(appName);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    map['duration_millis'] = Variable<BigInt>(durationMillis);
    map['swipe_count'] = Variable<int>(swipeCount);
    map['downward_swipe_count'] = Variable<int>(downwardSwipeCount);
    map['upward_swipe_count'] = Variable<int>(upwardSwipeCount);
    map['avg_inter_swipe_millis'] = Variable<BigInt>(avgInterSwipeMillis);
    map['collected_at'] = Variable<DateTime>(collectedAt);
    map['sync_status'] = Variable<String>(syncStatus);
    map['sync_attempts'] = Variable<int>(syncAttempts);
    if (!nullToAbsent || lastSyncError != null) {
      map['last_sync_error'] = Variable<String>(lastSyncError);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DoomscrollSessionsCompanion toCompanion(bool nullToAbsent) {
    return DoomscrollSessionsCompanion(
      id: Value(id),
      userId: Value(userId),
      deviceId: Value(deviceId),
      packageName: Value(packageName),
      appName: Value(appName),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      durationMillis: Value(durationMillis),
      swipeCount: Value(swipeCount),
      downwardSwipeCount: Value(downwardSwipeCount),
      upwardSwipeCount: Value(upwardSwipeCount),
      avgInterSwipeMillis: Value(avgInterSwipeMillis),
      collectedAt: Value(collectedAt),
      syncStatus: Value(syncStatus),
      syncAttempts: Value(syncAttempts),
      lastSyncError: lastSyncError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncError),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory DoomscrollSessionData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DoomscrollSessionData(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      packageName: serializer.fromJson<String>(json['packageName']),
      appName: serializer.fromJson<String>(json['appName']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      durationMillis: serializer.fromJson<BigInt>(json['durationMillis']),
      swipeCount: serializer.fromJson<int>(json['swipeCount']),
      downwardSwipeCount: serializer.fromJson<int>(json['downwardSwipeCount']),
      upwardSwipeCount: serializer.fromJson<int>(json['upwardSwipeCount']),
      avgInterSwipeMillis: serializer.fromJson<BigInt>(
        json['avgInterSwipeMillis'],
      ),
      collectedAt: serializer.fromJson<DateTime>(json['collectedAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      syncAttempts: serializer.fromJson<int>(json['syncAttempts']),
      lastSyncError: serializer.fromJson<String?>(json['lastSyncError']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'deviceId': serializer.toJson<String>(deviceId),
      'packageName': serializer.toJson<String>(packageName),
      'appName': serializer.toJson<String>(appName),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'durationMillis': serializer.toJson<BigInt>(durationMillis),
      'swipeCount': serializer.toJson<int>(swipeCount),
      'downwardSwipeCount': serializer.toJson<int>(downwardSwipeCount),
      'upwardSwipeCount': serializer.toJson<int>(upwardSwipeCount),
      'avgInterSwipeMillis': serializer.toJson<BigInt>(avgInterSwipeMillis),
      'collectedAt': serializer.toJson<DateTime>(collectedAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'syncAttempts': serializer.toJson<int>(syncAttempts),
      'lastSyncError': serializer.toJson<String?>(lastSyncError),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DoomscrollSessionData copyWith({
    String? id,
    String? userId,
    String? deviceId,
    String? packageName,
    String? appName,
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
    BigInt? durationMillis,
    int? swipeCount,
    int? downwardSwipeCount,
    int? upwardSwipeCount,
    BigInt? avgInterSwipeMillis,
    DateTime? collectedAt,
    String? syncStatus,
    int? syncAttempts,
    Value<String?> lastSyncError = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => DoomscrollSessionData(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    deviceId: deviceId ?? this.deviceId,
    packageName: packageName ?? this.packageName,
    appName: appName ?? this.appName,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    durationMillis: durationMillis ?? this.durationMillis,
    swipeCount: swipeCount ?? this.swipeCount,
    downwardSwipeCount: downwardSwipeCount ?? this.downwardSwipeCount,
    upwardSwipeCount: upwardSwipeCount ?? this.upwardSwipeCount,
    avgInterSwipeMillis: avgInterSwipeMillis ?? this.avgInterSwipeMillis,
    collectedAt: collectedAt ?? this.collectedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    syncAttempts: syncAttempts ?? this.syncAttempts,
    lastSyncError: lastSyncError.present
        ? lastSyncError.value
        : this.lastSyncError,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  DoomscrollSessionData copyWithCompanion(DoomscrollSessionsCompanion data) {
    return DoomscrollSessionData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      packageName: data.packageName.present
          ? data.packageName.value
          : this.packageName,
      appName: data.appName.present ? data.appName.value : this.appName,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      durationMillis: data.durationMillis.present
          ? data.durationMillis.value
          : this.durationMillis,
      swipeCount: data.swipeCount.present
          ? data.swipeCount.value
          : this.swipeCount,
      downwardSwipeCount: data.downwardSwipeCount.present
          ? data.downwardSwipeCount.value
          : this.downwardSwipeCount,
      upwardSwipeCount: data.upwardSwipeCount.present
          ? data.upwardSwipeCount.value
          : this.upwardSwipeCount,
      avgInterSwipeMillis: data.avgInterSwipeMillis.present
          ? data.avgInterSwipeMillis.value
          : this.avgInterSwipeMillis,
      collectedAt: data.collectedAt.present
          ? data.collectedAt.value
          : this.collectedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      syncAttempts: data.syncAttempts.present
          ? data.syncAttempts.value
          : this.syncAttempts,
      lastSyncError: data.lastSyncError.present
          ? data.lastSyncError.value
          : this.lastSyncError,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DoomscrollSessionData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('deviceId: $deviceId, ')
          ..write('packageName: $packageName, ')
          ..write('appName: $appName, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('durationMillis: $durationMillis, ')
          ..write('swipeCount: $swipeCount, ')
          ..write('downwardSwipeCount: $downwardSwipeCount, ')
          ..write('upwardSwipeCount: $upwardSwipeCount, ')
          ..write('avgInterSwipeMillis: $avgInterSwipeMillis, ')
          ..write('collectedAt: $collectedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('syncAttempts: $syncAttempts, ')
          ..write('lastSyncError: $lastSyncError, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    deviceId,
    packageName,
    appName,
    startedAt,
    endedAt,
    durationMillis,
    swipeCount,
    downwardSwipeCount,
    upwardSwipeCount,
    avgInterSwipeMillis,
    collectedAt,
    syncStatus,
    syncAttempts,
    lastSyncError,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DoomscrollSessionData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.deviceId == this.deviceId &&
          other.packageName == this.packageName &&
          other.appName == this.appName &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.durationMillis == this.durationMillis &&
          other.swipeCount == this.swipeCount &&
          other.downwardSwipeCount == this.downwardSwipeCount &&
          other.upwardSwipeCount == this.upwardSwipeCount &&
          other.avgInterSwipeMillis == this.avgInterSwipeMillis &&
          other.collectedAt == this.collectedAt &&
          other.syncStatus == this.syncStatus &&
          other.syncAttempts == this.syncAttempts &&
          other.lastSyncError == this.lastSyncError &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DoomscrollSessionsCompanion
    extends UpdateCompanion<DoomscrollSessionData> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> deviceId;
  final Value<String> packageName;
  final Value<String> appName;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<BigInt> durationMillis;
  final Value<int> swipeCount;
  final Value<int> downwardSwipeCount;
  final Value<int> upwardSwipeCount;
  final Value<BigInt> avgInterSwipeMillis;
  final Value<DateTime> collectedAt;
  final Value<String> syncStatus;
  final Value<int> syncAttempts;
  final Value<String?> lastSyncError;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const DoomscrollSessionsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.packageName = const Value.absent(),
    this.appName = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.durationMillis = const Value.absent(),
    this.swipeCount = const Value.absent(),
    this.downwardSwipeCount = const Value.absent(),
    this.upwardSwipeCount = const Value.absent(),
    this.avgInterSwipeMillis = const Value.absent(),
    this.collectedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.syncAttempts = const Value.absent(),
    this.lastSyncError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DoomscrollSessionsCompanion.insert({
    required String id,
    required String userId,
    this.deviceId = const Value.absent(),
    required String packageName,
    required String appName,
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
    required BigInt durationMillis,
    required int swipeCount,
    required int downwardSwipeCount,
    required int upwardSwipeCount,
    required BigInt avgInterSwipeMillis,
    required DateTime collectedAt,
    this.syncStatus = const Value.absent(),
    this.syncAttempts = const Value.absent(),
    this.lastSyncError = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       packageName = Value(packageName),
       appName = Value(appName),
       startedAt = Value(startedAt),
       durationMillis = Value(durationMillis),
       swipeCount = Value(swipeCount),
       downwardSwipeCount = Value(downwardSwipeCount),
       upwardSwipeCount = Value(upwardSwipeCount),
       avgInterSwipeMillis = Value(avgInterSwipeMillis),
       collectedAt = Value(collectedAt),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<DoomscrollSessionData> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? deviceId,
    Expression<String>? packageName,
    Expression<String>? appName,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<BigInt>? durationMillis,
    Expression<int>? swipeCount,
    Expression<int>? downwardSwipeCount,
    Expression<int>? upwardSwipeCount,
    Expression<BigInt>? avgInterSwipeMillis,
    Expression<DateTime>? collectedAt,
    Expression<String>? syncStatus,
    Expression<int>? syncAttempts,
    Expression<String>? lastSyncError,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (deviceId != null) 'device_id': deviceId,
      if (packageName != null) 'package_name': packageName,
      if (appName != null) 'app_name': appName,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (durationMillis != null) 'duration_millis': durationMillis,
      if (swipeCount != null) 'swipe_count': swipeCount,
      if (downwardSwipeCount != null)
        'downward_swipe_count': downwardSwipeCount,
      if (upwardSwipeCount != null) 'upward_swipe_count': upwardSwipeCount,
      if (avgInterSwipeMillis != null)
        'avg_inter_swipe_millis': avgInterSwipeMillis,
      if (collectedAt != null) 'collected_at': collectedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (syncAttempts != null) 'sync_attempts': syncAttempts,
      if (lastSyncError != null) 'last_sync_error': lastSyncError,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DoomscrollSessionsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? deviceId,
    Value<String>? packageName,
    Value<String>? appName,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
    Value<BigInt>? durationMillis,
    Value<int>? swipeCount,
    Value<int>? downwardSwipeCount,
    Value<int>? upwardSwipeCount,
    Value<BigInt>? avgInterSwipeMillis,
    Value<DateTime>? collectedAt,
    Value<String>? syncStatus,
    Value<int>? syncAttempts,
    Value<String?>? lastSyncError,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return DoomscrollSessionsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      deviceId: deviceId ?? this.deviceId,
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      durationMillis: durationMillis ?? this.durationMillis,
      swipeCount: swipeCount ?? this.swipeCount,
      downwardSwipeCount: downwardSwipeCount ?? this.downwardSwipeCount,
      upwardSwipeCount: upwardSwipeCount ?? this.upwardSwipeCount,
      avgInterSwipeMillis: avgInterSwipeMillis ?? this.avgInterSwipeMillis,
      collectedAt: collectedAt ?? this.collectedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      syncAttempts: syncAttempts ?? this.syncAttempts,
      lastSyncError: lastSyncError ?? this.lastSyncError,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (packageName.present) {
      map['package_name'] = Variable<String>(packageName.value);
    }
    if (appName.present) {
      map['app_name'] = Variable<String>(appName.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (durationMillis.present) {
      map['duration_millis'] = Variable<BigInt>(durationMillis.value);
    }
    if (swipeCount.present) {
      map['swipe_count'] = Variable<int>(swipeCount.value);
    }
    if (downwardSwipeCount.present) {
      map['downward_swipe_count'] = Variable<int>(downwardSwipeCount.value);
    }
    if (upwardSwipeCount.present) {
      map['upward_swipe_count'] = Variable<int>(upwardSwipeCount.value);
    }
    if (avgInterSwipeMillis.present) {
      map['avg_inter_swipe_millis'] = Variable<BigInt>(
        avgInterSwipeMillis.value,
      );
    }
    if (collectedAt.present) {
      map['collected_at'] = Variable<DateTime>(collectedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (syncAttempts.present) {
      map['sync_attempts'] = Variable<int>(syncAttempts.value);
    }
    if (lastSyncError.present) {
      map['last_sync_error'] = Variable<String>(lastSyncError.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DoomscrollSessionsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('deviceId: $deviceId, ')
          ..write('packageName: $packageName, ')
          ..write('appName: $appName, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('durationMillis: $durationMillis, ')
          ..write('swipeCount: $swipeCount, ')
          ..write('downwardSwipeCount: $downwardSwipeCount, ')
          ..write('upwardSwipeCount: $upwardSwipeCount, ')
          ..write('avgInterSwipeMillis: $avgInterSwipeMillis, ')
          ..write('collectedAt: $collectedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('syncAttempts: $syncAttempts, ')
          ..write('lastSyncError: $lastSyncError, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EyeMonitoringSessionsTable extends EyeMonitoringSessions
    with TableInfo<$EyeMonitoringSessionsTable, EyeMonitoringSessionData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EyeMonitoringSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('legacy'),
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
  static const VerificationMeta _durationMillisMeta = const VerificationMeta(
    'durationMillis',
  );
  @override
  late final GeneratedColumn<BigInt> durationMillis = GeneratedColumn<BigInt>(
    'duration_millis',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _averageEarMeta = const VerificationMeta(
    'averageEar',
  );
  @override
  late final GeneratedColumn<double> averageEar = GeneratedColumn<double>(
    'average_ear',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minEarMeta = const VerificationMeta('minEar');
  @override
  late final GeneratedColumn<double> minEar = GeneratedColumn<double>(
    'min_ear',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eyeClosureEventsMeta = const VerificationMeta(
    'eyeClosureEvents',
  );
  @override
  late final GeneratedColumn<int> eyeClosureEvents = GeneratedColumn<int>(
    'eye_closure_events',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _blinkCountMeta = const VerificationMeta(
    'blinkCount',
  );
  @override
  late final GeneratedColumn<int> blinkCount = GeneratedColumn<int>(
    'blink_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _collectedAtMeta = const VerificationMeta(
    'collectedAt',
  );
  @override
  late final GeneratedColumn<DateTime> collectedAt = GeneratedColumn<DateTime>(
    'collected_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _syncAttemptsMeta = const VerificationMeta(
    'syncAttempts',
  );
  @override
  late final GeneratedColumn<int> syncAttempts = GeneratedColumn<int>(
    'sync_attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastSyncErrorMeta = const VerificationMeta(
    'lastSyncError',
  );
  @override
  late final GeneratedColumn<String> lastSyncError = GeneratedColumn<String>(
    'last_sync_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    userId,
    deviceId,
    startedAt,
    endedAt,
    durationMillis,
    averageEar,
    minEar,
    eyeClosureEvents,
    blinkCount,
    collectedAt,
    syncStatus,
    syncAttempts,
    lastSyncError,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'eye_monitoring_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<EyeMonitoringSessionData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
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
    if (data.containsKey('duration_millis')) {
      context.handle(
        _durationMillisMeta,
        durationMillis.isAcceptableOrUnknown(
          data['duration_millis']!,
          _durationMillisMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_durationMillisMeta);
    }
    if (data.containsKey('average_ear')) {
      context.handle(
        _averageEarMeta,
        averageEar.isAcceptableOrUnknown(data['average_ear']!, _averageEarMeta),
      );
    } else if (isInserting) {
      context.missing(_averageEarMeta);
    }
    if (data.containsKey('min_ear')) {
      context.handle(
        _minEarMeta,
        minEar.isAcceptableOrUnknown(data['min_ear']!, _minEarMeta),
      );
    } else if (isInserting) {
      context.missing(_minEarMeta);
    }
    if (data.containsKey('eye_closure_events')) {
      context.handle(
        _eyeClosureEventsMeta,
        eyeClosureEvents.isAcceptableOrUnknown(
          data['eye_closure_events']!,
          _eyeClosureEventsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_eyeClosureEventsMeta);
    }
    if (data.containsKey('blink_count')) {
      context.handle(
        _blinkCountMeta,
        blinkCount.isAcceptableOrUnknown(data['blink_count']!, _blinkCountMeta),
      );
    } else if (isInserting) {
      context.missing(_blinkCountMeta);
    }
    if (data.containsKey('collected_at')) {
      context.handle(
        _collectedAtMeta,
        collectedAt.isAcceptableOrUnknown(
          data['collected_at']!,
          _collectedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_collectedAtMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('sync_attempts')) {
      context.handle(
        _syncAttemptsMeta,
        syncAttempts.isAcceptableOrUnknown(
          data['sync_attempts']!,
          _syncAttemptsMeta,
        ),
      );
    }
    if (data.containsKey('last_sync_error')) {
      context.handle(
        _lastSyncErrorMeta,
        lastSyncError.isAcceptableOrUnknown(
          data['last_sync_error']!,
          _lastSyncErrorMeta,
        ),
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EyeMonitoringSessionData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EyeMonitoringSessionData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      durationMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}duration_millis'],
      )!,
      averageEar: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}average_ear'],
      )!,
      minEar: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}min_ear'],
      )!,
      eyeClosureEvents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}eye_closure_events'],
      )!,
      blinkCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}blink_count'],
      )!,
      collectedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}collected_at'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      syncAttempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_attempts'],
      )!,
      lastSyncError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_sync_error'],
      ),
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
  $EyeMonitoringSessionsTable createAlias(String alias) {
    return $EyeMonitoringSessionsTable(attachedDatabase, alias);
  }
}

class EyeMonitoringSessionData extends DataClass
    implements Insertable<EyeMonitoringSessionData> {
  final String id;
  final String userId;
  final String deviceId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final BigInt durationMillis;
  final double averageEar;
  final double minEar;
  final int eyeClosureEvents;
  final int blinkCount;
  final DateTime collectedAt;
  final String syncStatus;
  final int syncAttempts;
  final String? lastSyncError;
  final DateTime createdAt;
  final DateTime updatedAt;
  const EyeMonitoringSessionData({
    required this.id,
    required this.userId,
    required this.deviceId,
    required this.startedAt,
    this.endedAt,
    required this.durationMillis,
    required this.averageEar,
    required this.minEar,
    required this.eyeClosureEvents,
    required this.blinkCount,
    required this.collectedAt,
    required this.syncStatus,
    required this.syncAttempts,
    this.lastSyncError,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['device_id'] = Variable<String>(deviceId);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    map['duration_millis'] = Variable<BigInt>(durationMillis);
    map['average_ear'] = Variable<double>(averageEar);
    map['min_ear'] = Variable<double>(minEar);
    map['eye_closure_events'] = Variable<int>(eyeClosureEvents);
    map['blink_count'] = Variable<int>(blinkCount);
    map['collected_at'] = Variable<DateTime>(collectedAt);
    map['sync_status'] = Variable<String>(syncStatus);
    map['sync_attempts'] = Variable<int>(syncAttempts);
    if (!nullToAbsent || lastSyncError != null) {
      map['last_sync_error'] = Variable<String>(lastSyncError);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  EyeMonitoringSessionsCompanion toCompanion(bool nullToAbsent) {
    return EyeMonitoringSessionsCompanion(
      id: Value(id),
      userId: Value(userId),
      deviceId: Value(deviceId),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      durationMillis: Value(durationMillis),
      averageEar: Value(averageEar),
      minEar: Value(minEar),
      eyeClosureEvents: Value(eyeClosureEvents),
      blinkCount: Value(blinkCount),
      collectedAt: Value(collectedAt),
      syncStatus: Value(syncStatus),
      syncAttempts: Value(syncAttempts),
      lastSyncError: lastSyncError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncError),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory EyeMonitoringSessionData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EyeMonitoringSessionData(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      durationMillis: serializer.fromJson<BigInt>(json['durationMillis']),
      averageEar: serializer.fromJson<double>(json['averageEar']),
      minEar: serializer.fromJson<double>(json['minEar']),
      eyeClosureEvents: serializer.fromJson<int>(json['eyeClosureEvents']),
      blinkCount: serializer.fromJson<int>(json['blinkCount']),
      collectedAt: serializer.fromJson<DateTime>(json['collectedAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      syncAttempts: serializer.fromJson<int>(json['syncAttempts']),
      lastSyncError: serializer.fromJson<String?>(json['lastSyncError']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'deviceId': serializer.toJson<String>(deviceId),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'durationMillis': serializer.toJson<BigInt>(durationMillis),
      'averageEar': serializer.toJson<double>(averageEar),
      'minEar': serializer.toJson<double>(minEar),
      'eyeClosureEvents': serializer.toJson<int>(eyeClosureEvents),
      'blinkCount': serializer.toJson<int>(blinkCount),
      'collectedAt': serializer.toJson<DateTime>(collectedAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'syncAttempts': serializer.toJson<int>(syncAttempts),
      'lastSyncError': serializer.toJson<String?>(lastSyncError),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  EyeMonitoringSessionData copyWith({
    String? id,
    String? userId,
    String? deviceId,
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
    BigInt? durationMillis,
    double? averageEar,
    double? minEar,
    int? eyeClosureEvents,
    int? blinkCount,
    DateTime? collectedAt,
    String? syncStatus,
    int? syncAttempts,
    Value<String?> lastSyncError = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => EyeMonitoringSessionData(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    deviceId: deviceId ?? this.deviceId,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    durationMillis: durationMillis ?? this.durationMillis,
    averageEar: averageEar ?? this.averageEar,
    minEar: minEar ?? this.minEar,
    eyeClosureEvents: eyeClosureEvents ?? this.eyeClosureEvents,
    blinkCount: blinkCount ?? this.blinkCount,
    collectedAt: collectedAt ?? this.collectedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    syncAttempts: syncAttempts ?? this.syncAttempts,
    lastSyncError: lastSyncError.present
        ? lastSyncError.value
        : this.lastSyncError,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  EyeMonitoringSessionData copyWithCompanion(
    EyeMonitoringSessionsCompanion data,
  ) {
    return EyeMonitoringSessionData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      durationMillis: data.durationMillis.present
          ? data.durationMillis.value
          : this.durationMillis,
      averageEar: data.averageEar.present
          ? data.averageEar.value
          : this.averageEar,
      minEar: data.minEar.present ? data.minEar.value : this.minEar,
      eyeClosureEvents: data.eyeClosureEvents.present
          ? data.eyeClosureEvents.value
          : this.eyeClosureEvents,
      blinkCount: data.blinkCount.present
          ? data.blinkCount.value
          : this.blinkCount,
      collectedAt: data.collectedAt.present
          ? data.collectedAt.value
          : this.collectedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      syncAttempts: data.syncAttempts.present
          ? data.syncAttempts.value
          : this.syncAttempts,
      lastSyncError: data.lastSyncError.present
          ? data.lastSyncError.value
          : this.lastSyncError,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EyeMonitoringSessionData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('deviceId: $deviceId, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('durationMillis: $durationMillis, ')
          ..write('averageEar: $averageEar, ')
          ..write('minEar: $minEar, ')
          ..write('eyeClosureEvents: $eyeClosureEvents, ')
          ..write('blinkCount: $blinkCount, ')
          ..write('collectedAt: $collectedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('syncAttempts: $syncAttempts, ')
          ..write('lastSyncError: $lastSyncError, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    deviceId,
    startedAt,
    endedAt,
    durationMillis,
    averageEar,
    minEar,
    eyeClosureEvents,
    blinkCount,
    collectedAt,
    syncStatus,
    syncAttempts,
    lastSyncError,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EyeMonitoringSessionData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.deviceId == this.deviceId &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.durationMillis == this.durationMillis &&
          other.averageEar == this.averageEar &&
          other.minEar == this.minEar &&
          other.eyeClosureEvents == this.eyeClosureEvents &&
          other.blinkCount == this.blinkCount &&
          other.collectedAt == this.collectedAt &&
          other.syncStatus == this.syncStatus &&
          other.syncAttempts == this.syncAttempts &&
          other.lastSyncError == this.lastSyncError &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class EyeMonitoringSessionsCompanion
    extends UpdateCompanion<EyeMonitoringSessionData> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> deviceId;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<BigInt> durationMillis;
  final Value<double> averageEar;
  final Value<double> minEar;
  final Value<int> eyeClosureEvents;
  final Value<int> blinkCount;
  final Value<DateTime> collectedAt;
  final Value<String> syncStatus;
  final Value<int> syncAttempts;
  final Value<String?> lastSyncError;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const EyeMonitoringSessionsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.durationMillis = const Value.absent(),
    this.averageEar = const Value.absent(),
    this.minEar = const Value.absent(),
    this.eyeClosureEvents = const Value.absent(),
    this.blinkCount = const Value.absent(),
    this.collectedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.syncAttempts = const Value.absent(),
    this.lastSyncError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EyeMonitoringSessionsCompanion.insert({
    required String id,
    required String userId,
    this.deviceId = const Value.absent(),
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
    required BigInt durationMillis,
    required double averageEar,
    required double minEar,
    required int eyeClosureEvents,
    required int blinkCount,
    required DateTime collectedAt,
    this.syncStatus = const Value.absent(),
    this.syncAttempts = const Value.absent(),
    this.lastSyncError = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       startedAt = Value(startedAt),
       durationMillis = Value(durationMillis),
       averageEar = Value(averageEar),
       minEar = Value(minEar),
       eyeClosureEvents = Value(eyeClosureEvents),
       blinkCount = Value(blinkCount),
       collectedAt = Value(collectedAt),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<EyeMonitoringSessionData> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? deviceId,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<BigInt>? durationMillis,
    Expression<double>? averageEar,
    Expression<double>? minEar,
    Expression<int>? eyeClosureEvents,
    Expression<int>? blinkCount,
    Expression<DateTime>? collectedAt,
    Expression<String>? syncStatus,
    Expression<int>? syncAttempts,
    Expression<String>? lastSyncError,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (deviceId != null) 'device_id': deviceId,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (durationMillis != null) 'duration_millis': durationMillis,
      if (averageEar != null) 'average_ear': averageEar,
      if (minEar != null) 'min_ear': minEar,
      if (eyeClosureEvents != null) 'eye_closure_events': eyeClosureEvents,
      if (blinkCount != null) 'blink_count': blinkCount,
      if (collectedAt != null) 'collected_at': collectedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (syncAttempts != null) 'sync_attempts': syncAttempts,
      if (lastSyncError != null) 'last_sync_error': lastSyncError,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EyeMonitoringSessionsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? deviceId,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
    Value<BigInt>? durationMillis,
    Value<double>? averageEar,
    Value<double>? minEar,
    Value<int>? eyeClosureEvents,
    Value<int>? blinkCount,
    Value<DateTime>? collectedAt,
    Value<String>? syncStatus,
    Value<int>? syncAttempts,
    Value<String?>? lastSyncError,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return EyeMonitoringSessionsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      deviceId: deviceId ?? this.deviceId,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      durationMillis: durationMillis ?? this.durationMillis,
      averageEar: averageEar ?? this.averageEar,
      minEar: minEar ?? this.minEar,
      eyeClosureEvents: eyeClosureEvents ?? this.eyeClosureEvents,
      blinkCount: blinkCount ?? this.blinkCount,
      collectedAt: collectedAt ?? this.collectedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      syncAttempts: syncAttempts ?? this.syncAttempts,
      lastSyncError: lastSyncError ?? this.lastSyncError,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (durationMillis.present) {
      map['duration_millis'] = Variable<BigInt>(durationMillis.value);
    }
    if (averageEar.present) {
      map['average_ear'] = Variable<double>(averageEar.value);
    }
    if (minEar.present) {
      map['min_ear'] = Variable<double>(minEar.value);
    }
    if (eyeClosureEvents.present) {
      map['eye_closure_events'] = Variable<int>(eyeClosureEvents.value);
    }
    if (blinkCount.present) {
      map['blink_count'] = Variable<int>(blinkCount.value);
    }
    if (collectedAt.present) {
      map['collected_at'] = Variable<DateTime>(collectedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (syncAttempts.present) {
      map['sync_attempts'] = Variable<int>(syncAttempts.value);
    }
    if (lastSyncError.present) {
      map['last_sync_error'] = Variable<String>(lastSyncError.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EyeMonitoringSessionsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('deviceId: $deviceId, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('durationMillis: $durationMillis, ')
          ..write('averageEar: $averageEar, ')
          ..write('minEar: $minEar, ')
          ..write('eyeClosureEvents: $eyeClosureEvents, ')
          ..write('blinkCount: $blinkCount, ')
          ..write('collectedAt: $collectedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('syncAttempts: $syncAttempts, ')
          ..write('lastSyncError: $lastSyncError, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalDeviceInfoTable extends LocalDeviceInfo
    with TableInfo<$LocalDeviceInfoTable, LocalDeviceInfoData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalDeviceInfoTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceNameMeta = const VerificationMeta(
    'deviceName',
  );
  @override
  late final GeneratedColumn<String> deviceName = GeneratedColumn<String>(
    'device_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _manufacturerMeta = const VerificationMeta(
    'manufacturer',
  );
  @override
  late final GeneratedColumn<String> manufacturer = GeneratedColumn<String>(
    'manufacturer',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
    'model',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _androidVersionMeta = const VerificationMeta(
    'androidVersion',
  );
  @override
  late final GeneratedColumn<String> androidVersion = GeneratedColumn<String>(
    'android_version',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _appVersionMeta = const VerificationMeta(
    'appVersion',
  );
  @override
  late final GeneratedColumn<String> appVersion = GeneratedColumn<String>(
    'app_version',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _lastSeenAtMeta = const VerificationMeta(
    'lastSeenAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSeenAt = GeneratedColumn<DateTime>(
    'last_seen_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    deviceId,
    deviceName,
    manufacturer,
    model,
    androidVersion,
    appVersion,
    createdAt,
    lastSeenAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_device_info';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalDeviceInfoData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('device_name')) {
      context.handle(
        _deviceNameMeta,
        deviceName.isAcceptableOrUnknown(data['device_name']!, _deviceNameMeta),
      );
    }
    if (data.containsKey('manufacturer')) {
      context.handle(
        _manufacturerMeta,
        manufacturer.isAcceptableOrUnknown(
          data['manufacturer']!,
          _manufacturerMeta,
        ),
      );
    }
    if (data.containsKey('model')) {
      context.handle(
        _modelMeta,
        model.isAcceptableOrUnknown(data['model']!, _modelMeta),
      );
    }
    if (data.containsKey('android_version')) {
      context.handle(
        _androidVersionMeta,
        androidVersion.isAcceptableOrUnknown(
          data['android_version']!,
          _androidVersionMeta,
        ),
      );
    }
    if (data.containsKey('app_version')) {
      context.handle(
        _appVersionMeta,
        appVersion.isAcceptableOrUnknown(data['app_version']!, _appVersionMeta),
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
    if (data.containsKey('last_seen_at')) {
      context.handle(
        _lastSeenAtMeta,
        lastSeenAt.isAcceptableOrUnknown(
          data['last_seen_at']!,
          _lastSeenAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastSeenAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalDeviceInfoData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalDeviceInfoData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      deviceName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_name'],
      ),
      manufacturer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}manufacturer'],
      ),
      model: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model'],
      ),
      androidVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}android_version'],
      ),
      appVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}app_version'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      lastSeenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_seen_at'],
      )!,
    );
  }

  @override
  $LocalDeviceInfoTable createAlias(String alias) {
    return $LocalDeviceInfoTable(attachedDatabase, alias);
  }
}

class LocalDeviceInfoData extends DataClass
    implements Insertable<LocalDeviceInfoData> {
  final String id;
  final String deviceId;
  final String? deviceName;
  final String? manufacturer;
  final String? model;
  final String? androidVersion;
  final String? appVersion;
  final DateTime createdAt;
  final DateTime lastSeenAt;
  const LocalDeviceInfoData({
    required this.id,
    required this.deviceId,
    this.deviceName,
    this.manufacturer,
    this.model,
    this.androidVersion,
    this.appVersion,
    required this.createdAt,
    required this.lastSeenAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['device_id'] = Variable<String>(deviceId);
    if (!nullToAbsent || deviceName != null) {
      map['device_name'] = Variable<String>(deviceName);
    }
    if (!nullToAbsent || manufacturer != null) {
      map['manufacturer'] = Variable<String>(manufacturer);
    }
    if (!nullToAbsent || model != null) {
      map['model'] = Variable<String>(model);
    }
    if (!nullToAbsent || androidVersion != null) {
      map['android_version'] = Variable<String>(androidVersion);
    }
    if (!nullToAbsent || appVersion != null) {
      map['app_version'] = Variable<String>(appVersion);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['last_seen_at'] = Variable<DateTime>(lastSeenAt);
    return map;
  }

  LocalDeviceInfoCompanion toCompanion(bool nullToAbsent) {
    return LocalDeviceInfoCompanion(
      id: Value(id),
      deviceId: Value(deviceId),
      deviceName: deviceName == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceName),
      manufacturer: manufacturer == null && nullToAbsent
          ? const Value.absent()
          : Value(manufacturer),
      model: model == null && nullToAbsent
          ? const Value.absent()
          : Value(model),
      androidVersion: androidVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(androidVersion),
      appVersion: appVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(appVersion),
      createdAt: Value(createdAt),
      lastSeenAt: Value(lastSeenAt),
    );
  }

  factory LocalDeviceInfoData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalDeviceInfoData(
      id: serializer.fromJson<String>(json['id']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      deviceName: serializer.fromJson<String?>(json['deviceName']),
      manufacturer: serializer.fromJson<String?>(json['manufacturer']),
      model: serializer.fromJson<String?>(json['model']),
      androidVersion: serializer.fromJson<String?>(json['androidVersion']),
      appVersion: serializer.fromJson<String?>(json['appVersion']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastSeenAt: serializer.fromJson<DateTime>(json['lastSeenAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'deviceId': serializer.toJson<String>(deviceId),
      'deviceName': serializer.toJson<String?>(deviceName),
      'manufacturer': serializer.toJson<String?>(manufacturer),
      'model': serializer.toJson<String?>(model),
      'androidVersion': serializer.toJson<String?>(androidVersion),
      'appVersion': serializer.toJson<String?>(appVersion),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastSeenAt': serializer.toJson<DateTime>(lastSeenAt),
    };
  }

  LocalDeviceInfoData copyWith({
    String? id,
    String? deviceId,
    Value<String?> deviceName = const Value.absent(),
    Value<String?> manufacturer = const Value.absent(),
    Value<String?> model = const Value.absent(),
    Value<String?> androidVersion = const Value.absent(),
    Value<String?> appVersion = const Value.absent(),
    DateTime? createdAt,
    DateTime? lastSeenAt,
  }) => LocalDeviceInfoData(
    id: id ?? this.id,
    deviceId: deviceId ?? this.deviceId,
    deviceName: deviceName.present ? deviceName.value : this.deviceName,
    manufacturer: manufacturer.present ? manufacturer.value : this.manufacturer,
    model: model.present ? model.value : this.model,
    androidVersion: androidVersion.present
        ? androidVersion.value
        : this.androidVersion,
    appVersion: appVersion.present ? appVersion.value : this.appVersion,
    createdAt: createdAt ?? this.createdAt,
    lastSeenAt: lastSeenAt ?? this.lastSeenAt,
  );
  LocalDeviceInfoData copyWithCompanion(LocalDeviceInfoCompanion data) {
    return LocalDeviceInfoData(
      id: data.id.present ? data.id.value : this.id,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      deviceName: data.deviceName.present
          ? data.deviceName.value
          : this.deviceName,
      manufacturer: data.manufacturer.present
          ? data.manufacturer.value
          : this.manufacturer,
      model: data.model.present ? data.model.value : this.model,
      androidVersion: data.androidVersion.present
          ? data.androidVersion.value
          : this.androidVersion,
      appVersion: data.appVersion.present
          ? data.appVersion.value
          : this.appVersion,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastSeenAt: data.lastSeenAt.present
          ? data.lastSeenAt.value
          : this.lastSeenAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalDeviceInfoData(')
          ..write('id: $id, ')
          ..write('deviceId: $deviceId, ')
          ..write('deviceName: $deviceName, ')
          ..write('manufacturer: $manufacturer, ')
          ..write('model: $model, ')
          ..write('androidVersion: $androidVersion, ')
          ..write('appVersion: $appVersion, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastSeenAt: $lastSeenAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    deviceId,
    deviceName,
    manufacturer,
    model,
    androidVersion,
    appVersion,
    createdAt,
    lastSeenAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalDeviceInfoData &&
          other.id == this.id &&
          other.deviceId == this.deviceId &&
          other.deviceName == this.deviceName &&
          other.manufacturer == this.manufacturer &&
          other.model == this.model &&
          other.androidVersion == this.androidVersion &&
          other.appVersion == this.appVersion &&
          other.createdAt == this.createdAt &&
          other.lastSeenAt == this.lastSeenAt);
}

class LocalDeviceInfoCompanion extends UpdateCompanion<LocalDeviceInfoData> {
  final Value<String> id;
  final Value<String> deviceId;
  final Value<String?> deviceName;
  final Value<String?> manufacturer;
  final Value<String?> model;
  final Value<String?> androidVersion;
  final Value<String?> appVersion;
  final Value<DateTime> createdAt;
  final Value<DateTime> lastSeenAt;
  final Value<int> rowid;
  const LocalDeviceInfoCompanion({
    this.id = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.deviceName = const Value.absent(),
    this.manufacturer = const Value.absent(),
    this.model = const Value.absent(),
    this.androidVersion = const Value.absent(),
    this.appVersion = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastSeenAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalDeviceInfoCompanion.insert({
    required String id,
    required String deviceId,
    this.deviceName = const Value.absent(),
    this.manufacturer = const Value.absent(),
    this.model = const Value.absent(),
    this.androidVersion = const Value.absent(),
    this.appVersion = const Value.absent(),
    required DateTime createdAt,
    required DateTime lastSeenAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       deviceId = Value(deviceId),
       createdAt = Value(createdAt),
       lastSeenAt = Value(lastSeenAt);
  static Insertable<LocalDeviceInfoData> custom({
    Expression<String>? id,
    Expression<String>? deviceId,
    Expression<String>? deviceName,
    Expression<String>? manufacturer,
    Expression<String>? model,
    Expression<String>? androidVersion,
    Expression<String>? appVersion,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastSeenAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (deviceId != null) 'device_id': deviceId,
      if (deviceName != null) 'device_name': deviceName,
      if (manufacturer != null) 'manufacturer': manufacturer,
      if (model != null) 'model': model,
      if (androidVersion != null) 'android_version': androidVersion,
      if (appVersion != null) 'app_version': appVersion,
      if (createdAt != null) 'created_at': createdAt,
      if (lastSeenAt != null) 'last_seen_at': lastSeenAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalDeviceInfoCompanion copyWith({
    Value<String>? id,
    Value<String>? deviceId,
    Value<String?>? deviceName,
    Value<String?>? manufacturer,
    Value<String?>? model,
    Value<String?>? androidVersion,
    Value<String?>? appVersion,
    Value<DateTime>? createdAt,
    Value<DateTime>? lastSeenAt,
    Value<int>? rowid,
  }) {
    return LocalDeviceInfoCompanion(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      manufacturer: manufacturer ?? this.manufacturer,
      model: model ?? this.model,
      androidVersion: androidVersion ?? this.androidVersion,
      appVersion: appVersion ?? this.appVersion,
      createdAt: createdAt ?? this.createdAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (deviceName.present) {
      map['device_name'] = Variable<String>(deviceName.value);
    }
    if (manufacturer.present) {
      map['manufacturer'] = Variable<String>(manufacturer.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (androidVersion.present) {
      map['android_version'] = Variable<String>(androidVersion.value);
    }
    if (appVersion.present) {
      map['app_version'] = Variable<String>(appVersion.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastSeenAt.present) {
      map['last_seen_at'] = Variable<DateTime>(lastSeenAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalDeviceInfoCompanion(')
          ..write('id: $id, ')
          ..write('deviceId: $deviceId, ')
          ..write('deviceName: $deviceName, ')
          ..write('manufacturer: $manufacturer, ')
          ..write('model: $model, ')
          ..write('androidVersion: $androidVersion, ')
          ..write('appVersion: $appVersion, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EyeMonitoringConfigTable extends EyeMonitoringConfig
    with TableInfo<$EyeMonitoringConfigTable, EyeMonitoringConfigData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EyeMonitoringConfigTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _monitoringEnabledMeta = const VerificationMeta(
    'monitoringEnabled',
  );
  @override
  late final GeneratedColumn<bool> monitoringEnabled = GeneratedColumn<bool>(
    'monitoring_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("monitoring_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastSessionStartedAtMeta =
      const VerificationMeta('lastSessionStartedAt');
  @override
  late final GeneratedColumn<DateTime> lastSessionStartedAt =
      GeneratedColumn<DateTime>(
        'last_session_started_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastSessionCompletedAtMeta =
      const VerificationMeta('lastSessionCompletedAt');
  @override
  late final GeneratedColumn<DateTime> lastSessionCompletedAt =
      GeneratedColumn<DateTime>(
        'last_session_completed_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _nextScheduledAtMeta = const VerificationMeta(
    'nextScheduledAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextScheduledAt =
      GeneratedColumn<DateTime>(
        'next_scheduled_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
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
    monitoringEnabled,
    lastSessionStartedAt,
    lastSessionCompletedAt,
    nextScheduledAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'eye_monitoring_config';
  @override
  VerificationContext validateIntegrity(
    Insertable<EyeMonitoringConfigData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('monitoring_enabled')) {
      context.handle(
        _monitoringEnabledMeta,
        monitoringEnabled.isAcceptableOrUnknown(
          data['monitoring_enabled']!,
          _monitoringEnabledMeta,
        ),
      );
    }
    if (data.containsKey('last_session_started_at')) {
      context.handle(
        _lastSessionStartedAtMeta,
        lastSessionStartedAt.isAcceptableOrUnknown(
          data['last_session_started_at']!,
          _lastSessionStartedAtMeta,
        ),
      );
    }
    if (data.containsKey('last_session_completed_at')) {
      context.handle(
        _lastSessionCompletedAtMeta,
        lastSessionCompletedAt.isAcceptableOrUnknown(
          data['last_session_completed_at']!,
          _lastSessionCompletedAtMeta,
        ),
      );
    }
    if (data.containsKey('next_scheduled_at')) {
      context.handle(
        _nextScheduledAtMeta,
        nextScheduledAt.isAcceptableOrUnknown(
          data['next_scheduled_at']!,
          _nextScheduledAtMeta,
        ),
      );
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
  EyeMonitoringConfigData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EyeMonitoringConfigData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      monitoringEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}monitoring_enabled'],
      )!,
      lastSessionStartedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_session_started_at'],
      ),
      lastSessionCompletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_session_completed_at'],
      ),
      nextScheduledAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_scheduled_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $EyeMonitoringConfigTable createAlias(String alias) {
    return $EyeMonitoringConfigTable(attachedDatabase, alias);
  }
}

class EyeMonitoringConfigData extends DataClass
    implements Insertable<EyeMonitoringConfigData> {
  final String id;
  final bool monitoringEnabled;
  final DateTime? lastSessionStartedAt;
  final DateTime? lastSessionCompletedAt;
  final DateTime? nextScheduledAt;
  final DateTime updatedAt;
  const EyeMonitoringConfigData({
    required this.id,
    required this.monitoringEnabled,
    this.lastSessionStartedAt,
    this.lastSessionCompletedAt,
    this.nextScheduledAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['monitoring_enabled'] = Variable<bool>(monitoringEnabled);
    if (!nullToAbsent || lastSessionStartedAt != null) {
      map['last_session_started_at'] = Variable<DateTime>(lastSessionStartedAt);
    }
    if (!nullToAbsent || lastSessionCompletedAt != null) {
      map['last_session_completed_at'] = Variable<DateTime>(
        lastSessionCompletedAt,
      );
    }
    if (!nullToAbsent || nextScheduledAt != null) {
      map['next_scheduled_at'] = Variable<DateTime>(nextScheduledAt);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  EyeMonitoringConfigCompanion toCompanion(bool nullToAbsent) {
    return EyeMonitoringConfigCompanion(
      id: Value(id),
      monitoringEnabled: Value(monitoringEnabled),
      lastSessionStartedAt: lastSessionStartedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSessionStartedAt),
      lastSessionCompletedAt: lastSessionCompletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSessionCompletedAt),
      nextScheduledAt: nextScheduledAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextScheduledAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory EyeMonitoringConfigData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EyeMonitoringConfigData(
      id: serializer.fromJson<String>(json['id']),
      monitoringEnabled: serializer.fromJson<bool>(json['monitoringEnabled']),
      lastSessionStartedAt: serializer.fromJson<DateTime?>(
        json['lastSessionStartedAt'],
      ),
      lastSessionCompletedAt: serializer.fromJson<DateTime?>(
        json['lastSessionCompletedAt'],
      ),
      nextScheduledAt: serializer.fromJson<DateTime?>(json['nextScheduledAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'monitoringEnabled': serializer.toJson<bool>(monitoringEnabled),
      'lastSessionStartedAt': serializer.toJson<DateTime?>(
        lastSessionStartedAt,
      ),
      'lastSessionCompletedAt': serializer.toJson<DateTime?>(
        lastSessionCompletedAt,
      ),
      'nextScheduledAt': serializer.toJson<DateTime?>(nextScheduledAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  EyeMonitoringConfigData copyWith({
    String? id,
    bool? monitoringEnabled,
    Value<DateTime?> lastSessionStartedAt = const Value.absent(),
    Value<DateTime?> lastSessionCompletedAt = const Value.absent(),
    Value<DateTime?> nextScheduledAt = const Value.absent(),
    DateTime? updatedAt,
  }) => EyeMonitoringConfigData(
    id: id ?? this.id,
    monitoringEnabled: monitoringEnabled ?? this.monitoringEnabled,
    lastSessionStartedAt: lastSessionStartedAt.present
        ? lastSessionStartedAt.value
        : this.lastSessionStartedAt,
    lastSessionCompletedAt: lastSessionCompletedAt.present
        ? lastSessionCompletedAt.value
        : this.lastSessionCompletedAt,
    nextScheduledAt: nextScheduledAt.present
        ? nextScheduledAt.value
        : this.nextScheduledAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  EyeMonitoringConfigData copyWithCompanion(EyeMonitoringConfigCompanion data) {
    return EyeMonitoringConfigData(
      id: data.id.present ? data.id.value : this.id,
      monitoringEnabled: data.monitoringEnabled.present
          ? data.monitoringEnabled.value
          : this.monitoringEnabled,
      lastSessionStartedAt: data.lastSessionStartedAt.present
          ? data.lastSessionStartedAt.value
          : this.lastSessionStartedAt,
      lastSessionCompletedAt: data.lastSessionCompletedAt.present
          ? data.lastSessionCompletedAt.value
          : this.lastSessionCompletedAt,
      nextScheduledAt: data.nextScheduledAt.present
          ? data.nextScheduledAt.value
          : this.nextScheduledAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EyeMonitoringConfigData(')
          ..write('id: $id, ')
          ..write('monitoringEnabled: $monitoringEnabled, ')
          ..write('lastSessionStartedAt: $lastSessionStartedAt, ')
          ..write('lastSessionCompletedAt: $lastSessionCompletedAt, ')
          ..write('nextScheduledAt: $nextScheduledAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    monitoringEnabled,
    lastSessionStartedAt,
    lastSessionCompletedAt,
    nextScheduledAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EyeMonitoringConfigData &&
          other.id == this.id &&
          other.monitoringEnabled == this.monitoringEnabled &&
          other.lastSessionStartedAt == this.lastSessionStartedAt &&
          other.lastSessionCompletedAt == this.lastSessionCompletedAt &&
          other.nextScheduledAt == this.nextScheduledAt &&
          other.updatedAt == this.updatedAt);
}

class EyeMonitoringConfigCompanion
    extends UpdateCompanion<EyeMonitoringConfigData> {
  final Value<String> id;
  final Value<bool> monitoringEnabled;
  final Value<DateTime?> lastSessionStartedAt;
  final Value<DateTime?> lastSessionCompletedAt;
  final Value<DateTime?> nextScheduledAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const EyeMonitoringConfigCompanion({
    this.id = const Value.absent(),
    this.monitoringEnabled = const Value.absent(),
    this.lastSessionStartedAt = const Value.absent(),
    this.lastSessionCompletedAt = const Value.absent(),
    this.nextScheduledAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EyeMonitoringConfigCompanion.insert({
    required String id,
    this.monitoringEnabled = const Value.absent(),
    this.lastSessionStartedAt = const Value.absent(),
    this.lastSessionCompletedAt = const Value.absent(),
    this.nextScheduledAt = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       updatedAt = Value(updatedAt);
  static Insertable<EyeMonitoringConfigData> custom({
    Expression<String>? id,
    Expression<bool>? monitoringEnabled,
    Expression<DateTime>? lastSessionStartedAt,
    Expression<DateTime>? lastSessionCompletedAt,
    Expression<DateTime>? nextScheduledAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (monitoringEnabled != null) 'monitoring_enabled': monitoringEnabled,
      if (lastSessionStartedAt != null)
        'last_session_started_at': lastSessionStartedAt,
      if (lastSessionCompletedAt != null)
        'last_session_completed_at': lastSessionCompletedAt,
      if (nextScheduledAt != null) 'next_scheduled_at': nextScheduledAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EyeMonitoringConfigCompanion copyWith({
    Value<String>? id,
    Value<bool>? monitoringEnabled,
    Value<DateTime?>? lastSessionStartedAt,
    Value<DateTime?>? lastSessionCompletedAt,
    Value<DateTime?>? nextScheduledAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return EyeMonitoringConfigCompanion(
      id: id ?? this.id,
      monitoringEnabled: monitoringEnabled ?? this.monitoringEnabled,
      lastSessionStartedAt: lastSessionStartedAt ?? this.lastSessionStartedAt,
      lastSessionCompletedAt:
          lastSessionCompletedAt ?? this.lastSessionCompletedAt,
      nextScheduledAt: nextScheduledAt ?? this.nextScheduledAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (monitoringEnabled.present) {
      map['monitoring_enabled'] = Variable<bool>(monitoringEnabled.value);
    }
    if (lastSessionStartedAt.present) {
      map['last_session_started_at'] = Variable<DateTime>(
        lastSessionStartedAt.value,
      );
    }
    if (lastSessionCompletedAt.present) {
      map['last_session_completed_at'] = Variable<DateTime>(
        lastSessionCompletedAt.value,
      );
    }
    if (nextScheduledAt.present) {
      map['next_scheduled_at'] = Variable<DateTime>(nextScheduledAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EyeMonitoringConfigCompanion(')
          ..write('id: $id, ')
          ..write('monitoringEnabled: $monitoringEnabled, ')
          ..write('lastSessionStartedAt: $lastSessionStartedAt, ')
          ..write('lastSessionCompletedAt: $lastSessionCompletedAt, ')
          ..write('nextScheduledAt: $nextScheduledAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InterventionHistoriesTable extends InterventionHistories
    with TableInfo<$InterventionHistoriesTable, InterventionHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InterventionHistoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
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
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMinutesMeta = const VerificationMeta(
    'durationMinutes',
  );
  @override
  late final GeneratedColumn<int> durationMinutes = GeneratedColumn<int>(
    'duration_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cancelledAtMeta = const VerificationMeta(
    'cancelledAt',
  );
  @override
  late final GeneratedColumn<DateTime> cancelledAt = GeneratedColumn<DateTime>(
    'cancelled_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceRecommendationIdMeta =
      const VerificationMeta('sourceRecommendationId');
  @override
  late final GeneratedColumn<String> sourceRecommendationId =
      GeneratedColumn<String>(
        'source_recommendation_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
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
    userId,
    type,
    title,
    durationMinutes,
    startedAt,
    endedAt,
    status,
    cancelledAt,
    sourceRecommendationId,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'intervention_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<InterventionHistoryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('duration_minutes')) {
      context.handle(
        _durationMinutesMeta,
        durationMinutes.isAcceptableOrUnknown(
          data['duration_minutes']!,
          _durationMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_durationMinutesMeta);
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
    } else if (isInserting) {
      context.missing(_endedAtMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('cancelled_at')) {
      context.handle(
        _cancelledAtMeta,
        cancelledAt.isAcceptableOrUnknown(
          data['cancelled_at']!,
          _cancelledAtMeta,
        ),
      );
    }
    if (data.containsKey('source_recommendation_id')) {
      context.handle(
        _sourceRecommendationIdMeta,
        sourceRecommendationId.isAcceptableOrUnknown(
          data['source_recommendation_id']!,
          _sourceRecommendationIdMeta,
        ),
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InterventionHistoryData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InterventionHistoryData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      durationMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_minutes'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      cancelledAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cancelled_at'],
      ),
      sourceRecommendationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_recommendation_id'],
      ),
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
  $InterventionHistoriesTable createAlias(String alias) {
    return $InterventionHistoriesTable(attachedDatabase, alias);
  }
}

class InterventionHistoryData extends DataClass
    implements Insertable<InterventionHistoryData> {
  final String id;
  final String userId;
  final String type;
  final String title;
  final int durationMinutes;
  final DateTime startedAt;
  final DateTime endedAt;
  final String status;
  final DateTime? cancelledAt;
  final String? sourceRecommendationId;
  final DateTime createdAt;
  final DateTime updatedAt;
  const InterventionHistoryData({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.durationMinutes,
    required this.startedAt,
    required this.endedAt,
    required this.status,
    this.cancelledAt,
    this.sourceRecommendationId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['type'] = Variable<String>(type);
    map['title'] = Variable<String>(title);
    map['duration_minutes'] = Variable<int>(durationMinutes);
    map['started_at'] = Variable<DateTime>(startedAt);
    map['ended_at'] = Variable<DateTime>(endedAt);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || cancelledAt != null) {
      map['cancelled_at'] = Variable<DateTime>(cancelledAt);
    }
    if (!nullToAbsent || sourceRecommendationId != null) {
      map['source_recommendation_id'] = Variable<String>(
        sourceRecommendationId,
      );
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  InterventionHistoriesCompanion toCompanion(bool nullToAbsent) {
    return InterventionHistoriesCompanion(
      id: Value(id),
      userId: Value(userId),
      type: Value(type),
      title: Value(title),
      durationMinutes: Value(durationMinutes),
      startedAt: Value(startedAt),
      endedAt: Value(endedAt),
      status: Value(status),
      cancelledAt: cancelledAt == null && nullToAbsent
          ? const Value.absent()
          : Value(cancelledAt),
      sourceRecommendationId: sourceRecommendationId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceRecommendationId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory InterventionHistoryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InterventionHistoryData(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      type: serializer.fromJson<String>(json['type']),
      title: serializer.fromJson<String>(json['title']),
      durationMinutes: serializer.fromJson<int>(json['durationMinutes']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime>(json['endedAt']),
      status: serializer.fromJson<String>(json['status']),
      cancelledAt: serializer.fromJson<DateTime?>(json['cancelledAt']),
      sourceRecommendationId: serializer.fromJson<String?>(
        json['sourceRecommendationId'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'type': serializer.toJson<String>(type),
      'title': serializer.toJson<String>(title),
      'durationMinutes': serializer.toJson<int>(durationMinutes),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime>(endedAt),
      'status': serializer.toJson<String>(status),
      'cancelledAt': serializer.toJson<DateTime?>(cancelledAt),
      'sourceRecommendationId': serializer.toJson<String?>(
        sourceRecommendationId,
      ),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  InterventionHistoryData copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    int? durationMinutes,
    DateTime? startedAt,
    DateTime? endedAt,
    String? status,
    Value<DateTime?> cancelledAt = const Value.absent(),
    Value<String?> sourceRecommendationId = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => InterventionHistoryData(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    type: type ?? this.type,
    title: title ?? this.title,
    durationMinutes: durationMinutes ?? this.durationMinutes,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt ?? this.endedAt,
    status: status ?? this.status,
    cancelledAt: cancelledAt.present ? cancelledAt.value : this.cancelledAt,
    sourceRecommendationId: sourceRecommendationId.present
        ? sourceRecommendationId.value
        : this.sourceRecommendationId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  InterventionHistoryData copyWithCompanion(
    InterventionHistoriesCompanion data,
  ) {
    return InterventionHistoryData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      type: data.type.present ? data.type.value : this.type,
      title: data.title.present ? data.title.value : this.title,
      durationMinutes: data.durationMinutes.present
          ? data.durationMinutes.value
          : this.durationMinutes,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      status: data.status.present ? data.status.value : this.status,
      cancelledAt: data.cancelledAt.present
          ? data.cancelledAt.value
          : this.cancelledAt,
      sourceRecommendationId: data.sourceRecommendationId.present
          ? data.sourceRecommendationId.value
          : this.sourceRecommendationId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InterventionHistoryData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('status: $status, ')
          ..write('cancelledAt: $cancelledAt, ')
          ..write('sourceRecommendationId: $sourceRecommendationId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    type,
    title,
    durationMinutes,
    startedAt,
    endedAt,
    status,
    cancelledAt,
    sourceRecommendationId,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InterventionHistoryData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.type == this.type &&
          other.title == this.title &&
          other.durationMinutes == this.durationMinutes &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.status == this.status &&
          other.cancelledAt == this.cancelledAt &&
          other.sourceRecommendationId == this.sourceRecommendationId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class InterventionHistoriesCompanion
    extends UpdateCompanion<InterventionHistoryData> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> type;
  final Value<String> title;
  final Value<int> durationMinutes;
  final Value<DateTime> startedAt;
  final Value<DateTime> endedAt;
  final Value<String> status;
  final Value<DateTime?> cancelledAt;
  final Value<String?> sourceRecommendationId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const InterventionHistoriesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.type = const Value.absent(),
    this.title = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.status = const Value.absent(),
    this.cancelledAt = const Value.absent(),
    this.sourceRecommendationId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InterventionHistoriesCompanion.insert({
    required String id,
    required String userId,
    required String type,
    required String title,
    required int durationMinutes,
    required DateTime startedAt,
    required DateTime endedAt,
    required String status,
    this.cancelledAt = const Value.absent(),
    this.sourceRecommendationId = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       type = Value(type),
       title = Value(title),
       durationMinutes = Value(durationMinutes),
       startedAt = Value(startedAt),
       endedAt = Value(endedAt),
       status = Value(status),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<InterventionHistoryData> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? type,
    Expression<String>? title,
    Expression<int>? durationMinutes,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<String>? status,
    Expression<DateTime>? cancelledAt,
    Expression<String>? sourceRecommendationId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (type != null) 'type': type,
      if (title != null) 'title': title,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (status != null) 'status': status,
      if (cancelledAt != null) 'cancelled_at': cancelledAt,
      if (sourceRecommendationId != null)
        'source_recommendation_id': sourceRecommendationId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InterventionHistoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? type,
    Value<String>? title,
    Value<int>? durationMinutes,
    Value<DateTime>? startedAt,
    Value<DateTime>? endedAt,
    Value<String>? status,
    Value<DateTime?>? cancelledAt,
    Value<String?>? sourceRecommendationId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return InterventionHistoriesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      status: status ?? this.status,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      sourceRecommendationId:
          sourceRecommendationId ?? this.sourceRecommendationId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (durationMinutes.present) {
      map['duration_minutes'] = Variable<int>(durationMinutes.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (cancelledAt.present) {
      map['cancelled_at'] = Variable<DateTime>(cancelledAt.value);
    }
    if (sourceRecommendationId.present) {
      map['source_recommendation_id'] = Variable<String>(
        sourceRecommendationId.value,
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InterventionHistoriesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('status: $status, ')
          ..write('cancelledAt: $cancelledAt, ')
          ..write('sourceRecommendationId: $sourceRecommendationId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ScreenTimeDailyTable screenTimeDaily = $ScreenTimeDailyTable(
    this,
  );
  late final $AppUsageDailyTable appUsageDaily = $AppUsageDailyTable(this);
  late final $SyncQueueTable syncQueue = $SyncQueueTable(this);
  late final $DoomscrollSessionsTable doomscrollSessions =
      $DoomscrollSessionsTable(this);
  late final $EyeMonitoringSessionsTable eyeMonitoringSessions =
      $EyeMonitoringSessionsTable(this);
  late final $LocalDeviceInfoTable localDeviceInfo = $LocalDeviceInfoTable(
    this,
  );
  late final $EyeMonitoringConfigTable eyeMonitoringConfig =
      $EyeMonitoringConfigTable(this);
  late final $InterventionHistoriesTable interventionHistories =
      $InterventionHistoriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    screenTimeDaily,
    appUsageDaily,
    syncQueue,
    doomscrollSessions,
    eyeMonitoringSessions,
    localDeviceInfo,
    eyeMonitoringConfig,
    interventionHistories,
  ];
}

typedef $$ScreenTimeDailyTableCreateCompanionBuilder =
    ScreenTimeDailyCompanion Function({
      required String id,
      required String userId,
      Value<String> deviceId,
      required String date,
      required BigInt totalUsageMillis,
      required DateTime collectedAt,
      Value<String> syncStatus,
      Value<int> syncAttempts,
      Value<String?> lastSyncError,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ScreenTimeDailyTableUpdateCompanionBuilder =
    ScreenTimeDailyCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> deviceId,
      Value<String> date,
      Value<BigInt> totalUsageMillis,
      Value<DateTime> collectedAt,
      Value<String> syncStatus,
      Value<int> syncAttempts,
      Value<String?> lastSyncError,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$ScreenTimeDailyTableFilterComposer
    extends Composer<_$AppDatabase, $ScreenTimeDailyTable> {
  $$ScreenTimeDailyTableFilterComposer({
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

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get totalUsageMillis => $composableBuilder(
    column: $table.totalUsageMillis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get collectedAt => $composableBuilder(
    column: $table.collectedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncAttempts => $composableBuilder(
    column: $table.syncAttempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastSyncError => $composableBuilder(
    column: $table.lastSyncError,
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

class $$ScreenTimeDailyTableOrderingComposer
    extends Composer<_$AppDatabase, $ScreenTimeDailyTable> {
  $$ScreenTimeDailyTableOrderingComposer({
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

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get totalUsageMillis => $composableBuilder(
    column: $table.totalUsageMillis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get collectedAt => $composableBuilder(
    column: $table.collectedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncAttempts => $composableBuilder(
    column: $table.syncAttempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastSyncError => $composableBuilder(
    column: $table.lastSyncError,
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

class $$ScreenTimeDailyTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScreenTimeDailyTable> {
  $$ScreenTimeDailyTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<BigInt> get totalUsageMillis => $composableBuilder(
    column: $table.totalUsageMillis,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get collectedAt => $composableBuilder(
    column: $table.collectedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get syncAttempts => $composableBuilder(
    column: $table.syncAttempts,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastSyncError => $composableBuilder(
    column: $table.lastSyncError,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ScreenTimeDailyTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ScreenTimeDailyTable,
          ScreenTimeDailyData,
          $$ScreenTimeDailyTableFilterComposer,
          $$ScreenTimeDailyTableOrderingComposer,
          $$ScreenTimeDailyTableAnnotationComposer,
          $$ScreenTimeDailyTableCreateCompanionBuilder,
          $$ScreenTimeDailyTableUpdateCompanionBuilder,
          (
            ScreenTimeDailyData,
            BaseReferences<
              _$AppDatabase,
              $ScreenTimeDailyTable,
              ScreenTimeDailyData
            >,
          ),
          ScreenTimeDailyData,
          PrefetchHooks Function()
        > {
  $$ScreenTimeDailyTableTableManager(
    _$AppDatabase db,
    $ScreenTimeDailyTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScreenTimeDailyTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScreenTimeDailyTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScreenTimeDailyTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<BigInt> totalUsageMillis = const Value.absent(),
                Value<DateTime> collectedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> syncAttempts = const Value.absent(),
                Value<String?> lastSyncError = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScreenTimeDailyCompanion(
                id: id,
                userId: userId,
                deviceId: deviceId,
                date: date,
                totalUsageMillis: totalUsageMillis,
                collectedAt: collectedAt,
                syncStatus: syncStatus,
                syncAttempts: syncAttempts,
                lastSyncError: lastSyncError,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                Value<String> deviceId = const Value.absent(),
                required String date,
                required BigInt totalUsageMillis,
                required DateTime collectedAt,
                Value<String> syncStatus = const Value.absent(),
                Value<int> syncAttempts = const Value.absent(),
                Value<String?> lastSyncError = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ScreenTimeDailyCompanion.insert(
                id: id,
                userId: userId,
                deviceId: deviceId,
                date: date,
                totalUsageMillis: totalUsageMillis,
                collectedAt: collectedAt,
                syncStatus: syncStatus,
                syncAttempts: syncAttempts,
                lastSyncError: lastSyncError,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ScreenTimeDailyTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ScreenTimeDailyTable,
      ScreenTimeDailyData,
      $$ScreenTimeDailyTableFilterComposer,
      $$ScreenTimeDailyTableOrderingComposer,
      $$ScreenTimeDailyTableAnnotationComposer,
      $$ScreenTimeDailyTableCreateCompanionBuilder,
      $$ScreenTimeDailyTableUpdateCompanionBuilder,
      (
        ScreenTimeDailyData,
        BaseReferences<
          _$AppDatabase,
          $ScreenTimeDailyTable,
          ScreenTimeDailyData
        >,
      ),
      ScreenTimeDailyData,
      PrefetchHooks Function()
    >;
typedef $$AppUsageDailyTableCreateCompanionBuilder =
    AppUsageDailyCompanion Function({
      required String id,
      required String userId,
      Value<String> deviceId,
      required String date,
      required String packageName,
      required String appName,
      required BigInt usageMillis,
      required DateTime collectedAt,
      Value<String> syncStatus,
      Value<int> syncAttempts,
      Value<String?> lastSyncError,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$AppUsageDailyTableUpdateCompanionBuilder =
    AppUsageDailyCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> deviceId,
      Value<String> date,
      Value<String> packageName,
      Value<String> appName,
      Value<BigInt> usageMillis,
      Value<DateTime> collectedAt,
      Value<String> syncStatus,
      Value<int> syncAttempts,
      Value<String?> lastSyncError,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$AppUsageDailyTableFilterComposer
    extends Composer<_$AppDatabase, $AppUsageDailyTable> {
  $$AppUsageDailyTableFilterComposer({
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

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get appName => $composableBuilder(
    column: $table.appName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get usageMillis => $composableBuilder(
    column: $table.usageMillis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get collectedAt => $composableBuilder(
    column: $table.collectedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncAttempts => $composableBuilder(
    column: $table.syncAttempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastSyncError => $composableBuilder(
    column: $table.lastSyncError,
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

class $$AppUsageDailyTableOrderingComposer
    extends Composer<_$AppDatabase, $AppUsageDailyTable> {
  $$AppUsageDailyTableOrderingComposer({
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

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get appName => $composableBuilder(
    column: $table.appName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get usageMillis => $composableBuilder(
    column: $table.usageMillis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get collectedAt => $composableBuilder(
    column: $table.collectedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncAttempts => $composableBuilder(
    column: $table.syncAttempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastSyncError => $composableBuilder(
    column: $table.lastSyncError,
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

class $$AppUsageDailyTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppUsageDailyTable> {
  $$AppUsageDailyTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get appName =>
      $composableBuilder(column: $table.appName, builder: (column) => column);

  GeneratedColumn<BigInt> get usageMillis => $composableBuilder(
    column: $table.usageMillis,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get collectedAt => $composableBuilder(
    column: $table.collectedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get syncAttempts => $composableBuilder(
    column: $table.syncAttempts,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastSyncError => $composableBuilder(
    column: $table.lastSyncError,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AppUsageDailyTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppUsageDailyTable,
          AppUsageDailyData,
          $$AppUsageDailyTableFilterComposer,
          $$AppUsageDailyTableOrderingComposer,
          $$AppUsageDailyTableAnnotationComposer,
          $$AppUsageDailyTableCreateCompanionBuilder,
          $$AppUsageDailyTableUpdateCompanionBuilder,
          (
            AppUsageDailyData,
            BaseReferences<
              _$AppDatabase,
              $AppUsageDailyTable,
              AppUsageDailyData
            >,
          ),
          AppUsageDailyData,
          PrefetchHooks Function()
        > {
  $$AppUsageDailyTableTableManager(_$AppDatabase db, $AppUsageDailyTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppUsageDailyTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppUsageDailyTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppUsageDailyTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String> packageName = const Value.absent(),
                Value<String> appName = const Value.absent(),
                Value<BigInt> usageMillis = const Value.absent(),
                Value<DateTime> collectedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> syncAttempts = const Value.absent(),
                Value<String?> lastSyncError = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppUsageDailyCompanion(
                id: id,
                userId: userId,
                deviceId: deviceId,
                date: date,
                packageName: packageName,
                appName: appName,
                usageMillis: usageMillis,
                collectedAt: collectedAt,
                syncStatus: syncStatus,
                syncAttempts: syncAttempts,
                lastSyncError: lastSyncError,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                Value<String> deviceId = const Value.absent(),
                required String date,
                required String packageName,
                required String appName,
                required BigInt usageMillis,
                required DateTime collectedAt,
                Value<String> syncStatus = const Value.absent(),
                Value<int> syncAttempts = const Value.absent(),
                Value<String?> lastSyncError = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => AppUsageDailyCompanion.insert(
                id: id,
                userId: userId,
                deviceId: deviceId,
                date: date,
                packageName: packageName,
                appName: appName,
                usageMillis: usageMillis,
                collectedAt: collectedAt,
                syncStatus: syncStatus,
                syncAttempts: syncAttempts,
                lastSyncError: lastSyncError,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppUsageDailyTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppUsageDailyTable,
      AppUsageDailyData,
      $$AppUsageDailyTableFilterComposer,
      $$AppUsageDailyTableOrderingComposer,
      $$AppUsageDailyTableAnnotationComposer,
      $$AppUsageDailyTableCreateCompanionBuilder,
      $$AppUsageDailyTableUpdateCompanionBuilder,
      (
        AppUsageDailyData,
        BaseReferences<_$AppDatabase, $AppUsageDailyTable, AppUsageDailyData>,
      ),
      AppUsageDailyData,
      PrefetchHooks Function()
    >;
typedef $$SyncQueueTableCreateCompanionBuilder =
    SyncQueueCompanion Function({
      required String id,
      required String entityType,
      required String entityId,
      Value<String> operation,
      required DateTime createdAt,
      Value<int> retryCount,
      Value<String?> lastError,
      Value<int> rowid,
    });
typedef $$SyncQueueTableUpdateCompanionBuilder =
    SyncQueueCompanion Function({
      Value<String> id,
      Value<String> entityType,
      Value<String> entityId,
      Value<String> operation,
      Value<DateTime> createdAt,
      Value<int> retryCount,
      Value<String?> lastError,
      Value<int> rowid,
    });

class $$SyncQueueTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableFilterComposer({
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

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableOrderingComposer({
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

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);
}

class $$SyncQueueTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncQueueTable,
          SyncQueueData,
          $$SyncQueueTableFilterComposer,
          $$SyncQueueTableOrderingComposer,
          $$SyncQueueTableAnnotationComposer,
          $$SyncQueueTableCreateCompanionBuilder,
          $$SyncQueueTableUpdateCompanionBuilder,
          (
            SyncQueueData,
            BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueData>,
          ),
          SyncQueueData,
          PrefetchHooks Function()
        > {
  $$SyncQueueTableTableManager(_$AppDatabase db, $SyncQueueTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> operation = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncQueueCompanion(
                id: id,
                entityType: entityType,
                entityId: entityId,
                operation: operation,
                createdAt: createdAt,
                retryCount: retryCount,
                lastError: lastError,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String entityType,
                required String entityId,
                Value<String> operation = const Value.absent(),
                required DateTime createdAt,
                Value<int> retryCount = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncQueueCompanion.insert(
                id: id,
                entityType: entityType,
                entityId: entityId,
                operation: operation,
                createdAt: createdAt,
                retryCount: retryCount,
                lastError: lastError,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncQueueTable,
      SyncQueueData,
      $$SyncQueueTableFilterComposer,
      $$SyncQueueTableOrderingComposer,
      $$SyncQueueTableAnnotationComposer,
      $$SyncQueueTableCreateCompanionBuilder,
      $$SyncQueueTableUpdateCompanionBuilder,
      (
        SyncQueueData,
        BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueData>,
      ),
      SyncQueueData,
      PrefetchHooks Function()
    >;
typedef $$DoomscrollSessionsTableCreateCompanionBuilder =
    DoomscrollSessionsCompanion Function({
      required String id,
      required String userId,
      Value<String> deviceId,
      required String packageName,
      required String appName,
      required DateTime startedAt,
      Value<DateTime?> endedAt,
      required BigInt durationMillis,
      required int swipeCount,
      required int downwardSwipeCount,
      required int upwardSwipeCount,
      required BigInt avgInterSwipeMillis,
      required DateTime collectedAt,
      Value<String> syncStatus,
      Value<int> syncAttempts,
      Value<String?> lastSyncError,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$DoomscrollSessionsTableUpdateCompanionBuilder =
    DoomscrollSessionsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> deviceId,
      Value<String> packageName,
      Value<String> appName,
      Value<DateTime> startedAt,
      Value<DateTime?> endedAt,
      Value<BigInt> durationMillis,
      Value<int> swipeCount,
      Value<int> downwardSwipeCount,
      Value<int> upwardSwipeCount,
      Value<BigInt> avgInterSwipeMillis,
      Value<DateTime> collectedAt,
      Value<String> syncStatus,
      Value<int> syncAttempts,
      Value<String?> lastSyncError,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$DoomscrollSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $DoomscrollSessionsTable> {
  $$DoomscrollSessionsTableFilterComposer({
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

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get appName => $composableBuilder(
    column: $table.appName,
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

  ColumnFilters<BigInt> get durationMillis => $composableBuilder(
    column: $table.durationMillis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get swipeCount => $composableBuilder(
    column: $table.swipeCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get downwardSwipeCount => $composableBuilder(
    column: $table.downwardSwipeCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get upwardSwipeCount => $composableBuilder(
    column: $table.upwardSwipeCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get avgInterSwipeMillis => $composableBuilder(
    column: $table.avgInterSwipeMillis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get collectedAt => $composableBuilder(
    column: $table.collectedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncAttempts => $composableBuilder(
    column: $table.syncAttempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastSyncError => $composableBuilder(
    column: $table.lastSyncError,
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

class $$DoomscrollSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $DoomscrollSessionsTable> {
  $$DoomscrollSessionsTableOrderingComposer({
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

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get appName => $composableBuilder(
    column: $table.appName,
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

  ColumnOrderings<BigInt> get durationMillis => $composableBuilder(
    column: $table.durationMillis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get swipeCount => $composableBuilder(
    column: $table.swipeCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get downwardSwipeCount => $composableBuilder(
    column: $table.downwardSwipeCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get upwardSwipeCount => $composableBuilder(
    column: $table.upwardSwipeCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get avgInterSwipeMillis => $composableBuilder(
    column: $table.avgInterSwipeMillis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get collectedAt => $composableBuilder(
    column: $table.collectedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncAttempts => $composableBuilder(
    column: $table.syncAttempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastSyncError => $composableBuilder(
    column: $table.lastSyncError,
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

class $$DoomscrollSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DoomscrollSessionsTable> {
  $$DoomscrollSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get appName =>
      $composableBuilder(column: $table.appName, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<BigInt> get durationMillis => $composableBuilder(
    column: $table.durationMillis,
    builder: (column) => column,
  );

  GeneratedColumn<int> get swipeCount => $composableBuilder(
    column: $table.swipeCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get downwardSwipeCount => $composableBuilder(
    column: $table.downwardSwipeCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get upwardSwipeCount => $composableBuilder(
    column: $table.upwardSwipeCount,
    builder: (column) => column,
  );

  GeneratedColumn<BigInt> get avgInterSwipeMillis => $composableBuilder(
    column: $table.avgInterSwipeMillis,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get collectedAt => $composableBuilder(
    column: $table.collectedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get syncAttempts => $composableBuilder(
    column: $table.syncAttempts,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastSyncError => $composableBuilder(
    column: $table.lastSyncError,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DoomscrollSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DoomscrollSessionsTable,
          DoomscrollSessionData,
          $$DoomscrollSessionsTableFilterComposer,
          $$DoomscrollSessionsTableOrderingComposer,
          $$DoomscrollSessionsTableAnnotationComposer,
          $$DoomscrollSessionsTableCreateCompanionBuilder,
          $$DoomscrollSessionsTableUpdateCompanionBuilder,
          (
            DoomscrollSessionData,
            BaseReferences<
              _$AppDatabase,
              $DoomscrollSessionsTable,
              DoomscrollSessionData
            >,
          ),
          DoomscrollSessionData,
          PrefetchHooks Function()
        > {
  $$DoomscrollSessionsTableTableManager(
    _$AppDatabase db,
    $DoomscrollSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DoomscrollSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DoomscrollSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DoomscrollSessionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<String> packageName = const Value.absent(),
                Value<String> appName = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<BigInt> durationMillis = const Value.absent(),
                Value<int> swipeCount = const Value.absent(),
                Value<int> downwardSwipeCount = const Value.absent(),
                Value<int> upwardSwipeCount = const Value.absent(),
                Value<BigInt> avgInterSwipeMillis = const Value.absent(),
                Value<DateTime> collectedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> syncAttempts = const Value.absent(),
                Value<String?> lastSyncError = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DoomscrollSessionsCompanion(
                id: id,
                userId: userId,
                deviceId: deviceId,
                packageName: packageName,
                appName: appName,
                startedAt: startedAt,
                endedAt: endedAt,
                durationMillis: durationMillis,
                swipeCount: swipeCount,
                downwardSwipeCount: downwardSwipeCount,
                upwardSwipeCount: upwardSwipeCount,
                avgInterSwipeMillis: avgInterSwipeMillis,
                collectedAt: collectedAt,
                syncStatus: syncStatus,
                syncAttempts: syncAttempts,
                lastSyncError: lastSyncError,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                Value<String> deviceId = const Value.absent(),
                required String packageName,
                required String appName,
                required DateTime startedAt,
                Value<DateTime?> endedAt = const Value.absent(),
                required BigInt durationMillis,
                required int swipeCount,
                required int downwardSwipeCount,
                required int upwardSwipeCount,
                required BigInt avgInterSwipeMillis,
                required DateTime collectedAt,
                Value<String> syncStatus = const Value.absent(),
                Value<int> syncAttempts = const Value.absent(),
                Value<String?> lastSyncError = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => DoomscrollSessionsCompanion.insert(
                id: id,
                userId: userId,
                deviceId: deviceId,
                packageName: packageName,
                appName: appName,
                startedAt: startedAt,
                endedAt: endedAt,
                durationMillis: durationMillis,
                swipeCount: swipeCount,
                downwardSwipeCount: downwardSwipeCount,
                upwardSwipeCount: upwardSwipeCount,
                avgInterSwipeMillis: avgInterSwipeMillis,
                collectedAt: collectedAt,
                syncStatus: syncStatus,
                syncAttempts: syncAttempts,
                lastSyncError: lastSyncError,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DoomscrollSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DoomscrollSessionsTable,
      DoomscrollSessionData,
      $$DoomscrollSessionsTableFilterComposer,
      $$DoomscrollSessionsTableOrderingComposer,
      $$DoomscrollSessionsTableAnnotationComposer,
      $$DoomscrollSessionsTableCreateCompanionBuilder,
      $$DoomscrollSessionsTableUpdateCompanionBuilder,
      (
        DoomscrollSessionData,
        BaseReferences<
          _$AppDatabase,
          $DoomscrollSessionsTable,
          DoomscrollSessionData
        >,
      ),
      DoomscrollSessionData,
      PrefetchHooks Function()
    >;
typedef $$EyeMonitoringSessionsTableCreateCompanionBuilder =
    EyeMonitoringSessionsCompanion Function({
      required String id,
      required String userId,
      Value<String> deviceId,
      required DateTime startedAt,
      Value<DateTime?> endedAt,
      required BigInt durationMillis,
      required double averageEar,
      required double minEar,
      required int eyeClosureEvents,
      required int blinkCount,
      required DateTime collectedAt,
      Value<String> syncStatus,
      Value<int> syncAttempts,
      Value<String?> lastSyncError,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$EyeMonitoringSessionsTableUpdateCompanionBuilder =
    EyeMonitoringSessionsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> deviceId,
      Value<DateTime> startedAt,
      Value<DateTime?> endedAt,
      Value<BigInt> durationMillis,
      Value<double> averageEar,
      Value<double> minEar,
      Value<int> eyeClosureEvents,
      Value<int> blinkCount,
      Value<DateTime> collectedAt,
      Value<String> syncStatus,
      Value<int> syncAttempts,
      Value<String?> lastSyncError,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$EyeMonitoringSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $EyeMonitoringSessionsTable> {
  $$EyeMonitoringSessionsTableFilterComposer({
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

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
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

  ColumnFilters<BigInt> get durationMillis => $composableBuilder(
    column: $table.durationMillis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get averageEar => $composableBuilder(
    column: $table.averageEar,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get minEar => $composableBuilder(
    column: $table.minEar,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get eyeClosureEvents => $composableBuilder(
    column: $table.eyeClosureEvents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get blinkCount => $composableBuilder(
    column: $table.blinkCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get collectedAt => $composableBuilder(
    column: $table.collectedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncAttempts => $composableBuilder(
    column: $table.syncAttempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastSyncError => $composableBuilder(
    column: $table.lastSyncError,
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

class $$EyeMonitoringSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $EyeMonitoringSessionsTable> {
  $$EyeMonitoringSessionsTableOrderingComposer({
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

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
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

  ColumnOrderings<BigInt> get durationMillis => $composableBuilder(
    column: $table.durationMillis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get averageEar => $composableBuilder(
    column: $table.averageEar,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get minEar => $composableBuilder(
    column: $table.minEar,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get eyeClosureEvents => $composableBuilder(
    column: $table.eyeClosureEvents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get blinkCount => $composableBuilder(
    column: $table.blinkCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get collectedAt => $composableBuilder(
    column: $table.collectedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncAttempts => $composableBuilder(
    column: $table.syncAttempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastSyncError => $composableBuilder(
    column: $table.lastSyncError,
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

class $$EyeMonitoringSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EyeMonitoringSessionsTable> {
  $$EyeMonitoringSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<BigInt> get durationMillis => $composableBuilder(
    column: $table.durationMillis,
    builder: (column) => column,
  );

  GeneratedColumn<double> get averageEar => $composableBuilder(
    column: $table.averageEar,
    builder: (column) => column,
  );

  GeneratedColumn<double> get minEar =>
      $composableBuilder(column: $table.minEar, builder: (column) => column);

  GeneratedColumn<int> get eyeClosureEvents => $composableBuilder(
    column: $table.eyeClosureEvents,
    builder: (column) => column,
  );

  GeneratedColumn<int> get blinkCount => $composableBuilder(
    column: $table.blinkCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get collectedAt => $composableBuilder(
    column: $table.collectedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get syncAttempts => $composableBuilder(
    column: $table.syncAttempts,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastSyncError => $composableBuilder(
    column: $table.lastSyncError,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$EyeMonitoringSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EyeMonitoringSessionsTable,
          EyeMonitoringSessionData,
          $$EyeMonitoringSessionsTableFilterComposer,
          $$EyeMonitoringSessionsTableOrderingComposer,
          $$EyeMonitoringSessionsTableAnnotationComposer,
          $$EyeMonitoringSessionsTableCreateCompanionBuilder,
          $$EyeMonitoringSessionsTableUpdateCompanionBuilder,
          (
            EyeMonitoringSessionData,
            BaseReferences<
              _$AppDatabase,
              $EyeMonitoringSessionsTable,
              EyeMonitoringSessionData
            >,
          ),
          EyeMonitoringSessionData,
          PrefetchHooks Function()
        > {
  $$EyeMonitoringSessionsTableTableManager(
    _$AppDatabase db,
    $EyeMonitoringSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EyeMonitoringSessionsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$EyeMonitoringSessionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$EyeMonitoringSessionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<BigInt> durationMillis = const Value.absent(),
                Value<double> averageEar = const Value.absent(),
                Value<double> minEar = const Value.absent(),
                Value<int> eyeClosureEvents = const Value.absent(),
                Value<int> blinkCount = const Value.absent(),
                Value<DateTime> collectedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> syncAttempts = const Value.absent(),
                Value<String?> lastSyncError = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EyeMonitoringSessionsCompanion(
                id: id,
                userId: userId,
                deviceId: deviceId,
                startedAt: startedAt,
                endedAt: endedAt,
                durationMillis: durationMillis,
                averageEar: averageEar,
                minEar: minEar,
                eyeClosureEvents: eyeClosureEvents,
                blinkCount: blinkCount,
                collectedAt: collectedAt,
                syncStatus: syncStatus,
                syncAttempts: syncAttempts,
                lastSyncError: lastSyncError,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                Value<String> deviceId = const Value.absent(),
                required DateTime startedAt,
                Value<DateTime?> endedAt = const Value.absent(),
                required BigInt durationMillis,
                required double averageEar,
                required double minEar,
                required int eyeClosureEvents,
                required int blinkCount,
                required DateTime collectedAt,
                Value<String> syncStatus = const Value.absent(),
                Value<int> syncAttempts = const Value.absent(),
                Value<String?> lastSyncError = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => EyeMonitoringSessionsCompanion.insert(
                id: id,
                userId: userId,
                deviceId: deviceId,
                startedAt: startedAt,
                endedAt: endedAt,
                durationMillis: durationMillis,
                averageEar: averageEar,
                minEar: minEar,
                eyeClosureEvents: eyeClosureEvents,
                blinkCount: blinkCount,
                collectedAt: collectedAt,
                syncStatus: syncStatus,
                syncAttempts: syncAttempts,
                lastSyncError: lastSyncError,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EyeMonitoringSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EyeMonitoringSessionsTable,
      EyeMonitoringSessionData,
      $$EyeMonitoringSessionsTableFilterComposer,
      $$EyeMonitoringSessionsTableOrderingComposer,
      $$EyeMonitoringSessionsTableAnnotationComposer,
      $$EyeMonitoringSessionsTableCreateCompanionBuilder,
      $$EyeMonitoringSessionsTableUpdateCompanionBuilder,
      (
        EyeMonitoringSessionData,
        BaseReferences<
          _$AppDatabase,
          $EyeMonitoringSessionsTable,
          EyeMonitoringSessionData
        >,
      ),
      EyeMonitoringSessionData,
      PrefetchHooks Function()
    >;
typedef $$LocalDeviceInfoTableCreateCompanionBuilder =
    LocalDeviceInfoCompanion Function({
      required String id,
      required String deviceId,
      Value<String?> deviceName,
      Value<String?> manufacturer,
      Value<String?> model,
      Value<String?> androidVersion,
      Value<String?> appVersion,
      required DateTime createdAt,
      required DateTime lastSeenAt,
      Value<int> rowid,
    });
typedef $$LocalDeviceInfoTableUpdateCompanionBuilder =
    LocalDeviceInfoCompanion Function({
      Value<String> id,
      Value<String> deviceId,
      Value<String?> deviceName,
      Value<String?> manufacturer,
      Value<String?> model,
      Value<String?> androidVersion,
      Value<String?> appVersion,
      Value<DateTime> createdAt,
      Value<DateTime> lastSeenAt,
      Value<int> rowid,
    });

class $$LocalDeviceInfoTableFilterComposer
    extends Composer<_$AppDatabase, $LocalDeviceInfoTable> {
  $$LocalDeviceInfoTableFilterComposer({
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

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceName => $composableBuilder(
    column: $table.deviceName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get manufacturer => $composableBuilder(
    column: $table.manufacturer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get androidVersion => $composableBuilder(
    column: $table.androidVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get appVersion => $composableBuilder(
    column: $table.appVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalDeviceInfoTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalDeviceInfoTable> {
  $$LocalDeviceInfoTableOrderingComposer({
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

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceName => $composableBuilder(
    column: $table.deviceName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get manufacturer => $composableBuilder(
    column: $table.manufacturer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get androidVersion => $composableBuilder(
    column: $table.androidVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get appVersion => $composableBuilder(
    column: $table.appVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalDeviceInfoTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalDeviceInfoTable> {
  $$LocalDeviceInfoTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get deviceName => $composableBuilder(
    column: $table.deviceName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get manufacturer => $composableBuilder(
    column: $table.manufacturer,
    builder: (column) => column,
  );

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<String> get androidVersion => $composableBuilder(
    column: $table.androidVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get appVersion => $composableBuilder(
    column: $table.appVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => column,
  );
}

class $$LocalDeviceInfoTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalDeviceInfoTable,
          LocalDeviceInfoData,
          $$LocalDeviceInfoTableFilterComposer,
          $$LocalDeviceInfoTableOrderingComposer,
          $$LocalDeviceInfoTableAnnotationComposer,
          $$LocalDeviceInfoTableCreateCompanionBuilder,
          $$LocalDeviceInfoTableUpdateCompanionBuilder,
          (
            LocalDeviceInfoData,
            BaseReferences<
              _$AppDatabase,
              $LocalDeviceInfoTable,
              LocalDeviceInfoData
            >,
          ),
          LocalDeviceInfoData,
          PrefetchHooks Function()
        > {
  $$LocalDeviceInfoTableTableManager(
    _$AppDatabase db,
    $LocalDeviceInfoTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalDeviceInfoTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalDeviceInfoTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalDeviceInfoTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<String?> deviceName = const Value.absent(),
                Value<String?> manufacturer = const Value.absent(),
                Value<String?> model = const Value.absent(),
                Value<String?> androidVersion = const Value.absent(),
                Value<String?> appVersion = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> lastSeenAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalDeviceInfoCompanion(
                id: id,
                deviceId: deviceId,
                deviceName: deviceName,
                manufacturer: manufacturer,
                model: model,
                androidVersion: androidVersion,
                appVersion: appVersion,
                createdAt: createdAt,
                lastSeenAt: lastSeenAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String deviceId,
                Value<String?> deviceName = const Value.absent(),
                Value<String?> manufacturer = const Value.absent(),
                Value<String?> model = const Value.absent(),
                Value<String?> androidVersion = const Value.absent(),
                Value<String?> appVersion = const Value.absent(),
                required DateTime createdAt,
                required DateTime lastSeenAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalDeviceInfoCompanion.insert(
                id: id,
                deviceId: deviceId,
                deviceName: deviceName,
                manufacturer: manufacturer,
                model: model,
                androidVersion: androidVersion,
                appVersion: appVersion,
                createdAt: createdAt,
                lastSeenAt: lastSeenAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalDeviceInfoTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalDeviceInfoTable,
      LocalDeviceInfoData,
      $$LocalDeviceInfoTableFilterComposer,
      $$LocalDeviceInfoTableOrderingComposer,
      $$LocalDeviceInfoTableAnnotationComposer,
      $$LocalDeviceInfoTableCreateCompanionBuilder,
      $$LocalDeviceInfoTableUpdateCompanionBuilder,
      (
        LocalDeviceInfoData,
        BaseReferences<
          _$AppDatabase,
          $LocalDeviceInfoTable,
          LocalDeviceInfoData
        >,
      ),
      LocalDeviceInfoData,
      PrefetchHooks Function()
    >;
typedef $$EyeMonitoringConfigTableCreateCompanionBuilder =
    EyeMonitoringConfigCompanion Function({
      required String id,
      Value<bool> monitoringEnabled,
      Value<DateTime?> lastSessionStartedAt,
      Value<DateTime?> lastSessionCompletedAt,
      Value<DateTime?> nextScheduledAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$EyeMonitoringConfigTableUpdateCompanionBuilder =
    EyeMonitoringConfigCompanion Function({
      Value<String> id,
      Value<bool> monitoringEnabled,
      Value<DateTime?> lastSessionStartedAt,
      Value<DateTime?> lastSessionCompletedAt,
      Value<DateTime?> nextScheduledAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$EyeMonitoringConfigTableFilterComposer
    extends Composer<_$AppDatabase, $EyeMonitoringConfigTable> {
  $$EyeMonitoringConfigTableFilterComposer({
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

  ColumnFilters<bool> get monitoringEnabled => $composableBuilder(
    column: $table.monitoringEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSessionStartedAt => $composableBuilder(
    column: $table.lastSessionStartedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSessionCompletedAt => $composableBuilder(
    column: $table.lastSessionCompletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextScheduledAt => $composableBuilder(
    column: $table.nextScheduledAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EyeMonitoringConfigTableOrderingComposer
    extends Composer<_$AppDatabase, $EyeMonitoringConfigTable> {
  $$EyeMonitoringConfigTableOrderingComposer({
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

  ColumnOrderings<bool> get monitoringEnabled => $composableBuilder(
    column: $table.monitoringEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSessionStartedAt => $composableBuilder(
    column: $table.lastSessionStartedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSessionCompletedAt => $composableBuilder(
    column: $table.lastSessionCompletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextScheduledAt => $composableBuilder(
    column: $table.nextScheduledAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EyeMonitoringConfigTableAnnotationComposer
    extends Composer<_$AppDatabase, $EyeMonitoringConfigTable> {
  $$EyeMonitoringConfigTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get monitoringEnabled => $composableBuilder(
    column: $table.monitoringEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSessionStartedAt => $composableBuilder(
    column: $table.lastSessionStartedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSessionCompletedAt => $composableBuilder(
    column: $table.lastSessionCompletedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get nextScheduledAt => $composableBuilder(
    column: $table.nextScheduledAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$EyeMonitoringConfigTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EyeMonitoringConfigTable,
          EyeMonitoringConfigData,
          $$EyeMonitoringConfigTableFilterComposer,
          $$EyeMonitoringConfigTableOrderingComposer,
          $$EyeMonitoringConfigTableAnnotationComposer,
          $$EyeMonitoringConfigTableCreateCompanionBuilder,
          $$EyeMonitoringConfigTableUpdateCompanionBuilder,
          (
            EyeMonitoringConfigData,
            BaseReferences<
              _$AppDatabase,
              $EyeMonitoringConfigTable,
              EyeMonitoringConfigData
            >,
          ),
          EyeMonitoringConfigData,
          PrefetchHooks Function()
        > {
  $$EyeMonitoringConfigTableTableManager(
    _$AppDatabase db,
    $EyeMonitoringConfigTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EyeMonitoringConfigTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EyeMonitoringConfigTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$EyeMonitoringConfigTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<bool> monitoringEnabled = const Value.absent(),
                Value<DateTime?> lastSessionStartedAt = const Value.absent(),
                Value<DateTime?> lastSessionCompletedAt = const Value.absent(),
                Value<DateTime?> nextScheduledAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EyeMonitoringConfigCompanion(
                id: id,
                monitoringEnabled: monitoringEnabled,
                lastSessionStartedAt: lastSessionStartedAt,
                lastSessionCompletedAt: lastSessionCompletedAt,
                nextScheduledAt: nextScheduledAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<bool> monitoringEnabled = const Value.absent(),
                Value<DateTime?> lastSessionStartedAt = const Value.absent(),
                Value<DateTime?> lastSessionCompletedAt = const Value.absent(),
                Value<DateTime?> nextScheduledAt = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => EyeMonitoringConfigCompanion.insert(
                id: id,
                monitoringEnabled: monitoringEnabled,
                lastSessionStartedAt: lastSessionStartedAt,
                lastSessionCompletedAt: lastSessionCompletedAt,
                nextScheduledAt: nextScheduledAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EyeMonitoringConfigTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EyeMonitoringConfigTable,
      EyeMonitoringConfigData,
      $$EyeMonitoringConfigTableFilterComposer,
      $$EyeMonitoringConfigTableOrderingComposer,
      $$EyeMonitoringConfigTableAnnotationComposer,
      $$EyeMonitoringConfigTableCreateCompanionBuilder,
      $$EyeMonitoringConfigTableUpdateCompanionBuilder,
      (
        EyeMonitoringConfigData,
        BaseReferences<
          _$AppDatabase,
          $EyeMonitoringConfigTable,
          EyeMonitoringConfigData
        >,
      ),
      EyeMonitoringConfigData,
      PrefetchHooks Function()
    >;
typedef $$InterventionHistoriesTableCreateCompanionBuilder =
    InterventionHistoriesCompanion Function({
      required String id,
      required String userId,
      required String type,
      required String title,
      required int durationMinutes,
      required DateTime startedAt,
      required DateTime endedAt,
      required String status,
      Value<DateTime?> cancelledAt,
      Value<String?> sourceRecommendationId,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$InterventionHistoriesTableUpdateCompanionBuilder =
    InterventionHistoriesCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> type,
      Value<String> title,
      Value<int> durationMinutes,
      Value<DateTime> startedAt,
      Value<DateTime> endedAt,
      Value<String> status,
      Value<DateTime?> cancelledAt,
      Value<String?> sourceRecommendationId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$InterventionHistoriesTableFilterComposer
    extends Composer<_$AppDatabase, $InterventionHistoriesTable> {
  $$InterventionHistoriesTableFilterComposer({
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

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
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

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cancelledAt => $composableBuilder(
    column: $table.cancelledAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceRecommendationId => $composableBuilder(
    column: $table.sourceRecommendationId,
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

class $$InterventionHistoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $InterventionHistoriesTable> {
  $$InterventionHistoriesTableOrderingComposer({
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

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
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

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cancelledAt => $composableBuilder(
    column: $table.cancelledAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceRecommendationId => $composableBuilder(
    column: $table.sourceRecommendationId,
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

class $$InterventionHistoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $InterventionHistoriesTable> {
  $$InterventionHistoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get cancelledAt => $composableBuilder(
    column: $table.cancelledAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceRecommendationId => $composableBuilder(
    column: $table.sourceRecommendationId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$InterventionHistoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InterventionHistoriesTable,
          InterventionHistoryData,
          $$InterventionHistoriesTableFilterComposer,
          $$InterventionHistoriesTableOrderingComposer,
          $$InterventionHistoriesTableAnnotationComposer,
          $$InterventionHistoriesTableCreateCompanionBuilder,
          $$InterventionHistoriesTableUpdateCompanionBuilder,
          (
            InterventionHistoryData,
            BaseReferences<
              _$AppDatabase,
              $InterventionHistoriesTable,
              InterventionHistoryData
            >,
          ),
          InterventionHistoryData,
          PrefetchHooks Function()
        > {
  $$InterventionHistoriesTableTableManager(
    _$AppDatabase db,
    $InterventionHistoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InterventionHistoriesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$InterventionHistoriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$InterventionHistoriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> durationMinutes = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime> endedAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> cancelledAt = const Value.absent(),
                Value<String?> sourceRecommendationId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InterventionHistoriesCompanion(
                id: id,
                userId: userId,
                type: type,
                title: title,
                durationMinutes: durationMinutes,
                startedAt: startedAt,
                endedAt: endedAt,
                status: status,
                cancelledAt: cancelledAt,
                sourceRecommendationId: sourceRecommendationId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String type,
                required String title,
                required int durationMinutes,
                required DateTime startedAt,
                required DateTime endedAt,
                required String status,
                Value<DateTime?> cancelledAt = const Value.absent(),
                Value<String?> sourceRecommendationId = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => InterventionHistoriesCompanion.insert(
                id: id,
                userId: userId,
                type: type,
                title: title,
                durationMinutes: durationMinutes,
                startedAt: startedAt,
                endedAt: endedAt,
                status: status,
                cancelledAt: cancelledAt,
                sourceRecommendationId: sourceRecommendationId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$InterventionHistoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InterventionHistoriesTable,
      InterventionHistoryData,
      $$InterventionHistoriesTableFilterComposer,
      $$InterventionHistoriesTableOrderingComposer,
      $$InterventionHistoriesTableAnnotationComposer,
      $$InterventionHistoriesTableCreateCompanionBuilder,
      $$InterventionHistoriesTableUpdateCompanionBuilder,
      (
        InterventionHistoryData,
        BaseReferences<
          _$AppDatabase,
          $InterventionHistoriesTable,
          InterventionHistoryData
        >,
      ),
      InterventionHistoryData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ScreenTimeDailyTableTableManager get screenTimeDaily =>
      $$ScreenTimeDailyTableTableManager(_db, _db.screenTimeDaily);
  $$AppUsageDailyTableTableManager get appUsageDaily =>
      $$AppUsageDailyTableTableManager(_db, _db.appUsageDaily);
  $$SyncQueueTableTableManager get syncQueue =>
      $$SyncQueueTableTableManager(_db, _db.syncQueue);
  $$DoomscrollSessionsTableTableManager get doomscrollSessions =>
      $$DoomscrollSessionsTableTableManager(_db, _db.doomscrollSessions);
  $$EyeMonitoringSessionsTableTableManager get eyeMonitoringSessions =>
      $$EyeMonitoringSessionsTableTableManager(_db, _db.eyeMonitoringSessions);
  $$LocalDeviceInfoTableTableManager get localDeviceInfo =>
      $$LocalDeviceInfoTableTableManager(_db, _db.localDeviceInfo);
  $$EyeMonitoringConfigTableTableManager get eyeMonitoringConfig =>
      $$EyeMonitoringConfigTableTableManager(_db, _db.eyeMonitoringConfig);
  $$InterventionHistoriesTableTableManager get interventionHistories =>
      $$InterventionHistoriesTableTableManager(_db, _db.interventionHistories);
}
