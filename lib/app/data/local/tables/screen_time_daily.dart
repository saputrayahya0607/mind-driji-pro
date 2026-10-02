import 'package:drift/drift.dart';

class ScreenTimeDaily extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get deviceId => text().withDefault(const Constant('legacy'))();
  TextColumn get date => text()();
  Int64Column get totalUsageMillis => int64()();
  DateTimeColumn get collectedAt => dateTime()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  IntColumn get syncAttempts => integer().withDefault(const Constant(0))();
  TextColumn get lastSyncError => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {userId, deviceId, date},
      ];
}
