import 'package:drift/drift.dart';

/// Tabel Drift untuk menyimpan riwayat intervensi pengguna secara persisten & offline-first.
@DataClassName('InterventionHistoryData')
class InterventionHistories extends Table {
  @override
  String get tableName => 'intervention_history';

  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get type => text()();
  TextColumn get title => text()();
  IntColumn get durationMinutes => integer()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime()();
  TextColumn get status => text()();
  DateTimeColumn get cancelledAt => dateTime().nullable()();
  TextColumn get sourceRecommendationId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
