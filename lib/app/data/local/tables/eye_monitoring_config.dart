import 'package:drift/drift.dart';

/// Tabel SQLite lokal untuk menyimpan konfigurasi dan state persisten
/// dari Automatic Periodic Eye Monitoring (MIND DRIJI).
///
/// Memastikan status monitoring tetap bertahan setelah app restart,
/// navigasi antar halaman, atau background lifecycle.
@DataClassName('EyeMonitoringConfigData')
class EyeMonitoringConfig extends Table {
  TextColumn get id => text()(); // Fixed id misal 'current_config'
  BoolColumn get monitoringEnabled =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastSessionStartedAt => dateTime().nullable()();
  DateTimeColumn get lastSessionCompletedAt => dateTime().nullable()();
  DateTimeColumn get nextScheduledAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
