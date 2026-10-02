import 'package:drift/drift.dart';

@DataClassName('EyeMonitoringSessionData')
class EyeMonitoringSessions extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get deviceId => text().withDefault(const Constant('legacy'))();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  Int64Column get durationMillis => int64()();
  RealColumn get averageEar => real()();
  RealColumn get minEar => real()();
  IntColumn get eyeClosureEvents => integer()();
  IntColumn get blinkCount => integer()();
  DateTimeColumn get collectedAt => dateTime()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  IntColumn get syncAttempts => integer().withDefault(const Constant(0))();
  TextColumn get lastSyncError => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
