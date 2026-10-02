import 'package:drift/drift.dart';

@DataClassName('DoomscrollSessionData')
class DoomscrollSessions extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get deviceId => text().withDefault(const Constant('legacy'))();
  TextColumn get packageName => text()();
  TextColumn get appName => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  Int64Column get durationMillis => int64()();
  IntColumn get swipeCount => integer()();
  IntColumn get downwardSwipeCount => integer()();
  IntColumn get upwardSwipeCount => integer()();
  Int64Column get avgInterSwipeMillis => int64()();
  DateTimeColumn get collectedAt => dateTime()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  IntColumn get syncAttempts => integer().withDefault(const Constant(0))();
  TextColumn get lastSyncError => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
