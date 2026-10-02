import 'package:drift/drift.dart';

class SyncQueue extends Table {
  TextColumn get id => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get operation => text().withDefault(const Constant('upsert'))();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class SyncStatus {
  SyncStatus._();
  static const String pending = 'pending';
  static const String synced = 'synced';
  static const String failed = 'failed';
}

class SyncOperation {
  SyncOperation._();
  static const String upsert = 'upsert';
  static const String insert = 'insert';
  static const String delete = 'delete';
}

class SyncEntityType {
  SyncEntityType._();
  static const String screenTimeDaily = 'screen_time_daily';
  static const String appUsageDaily = 'app_usage_daily';
  static const String doomscrollSession = 'doomscroll_session';
  static const String eyeMonitoringSession = 'eye_monitoring_session';
}
