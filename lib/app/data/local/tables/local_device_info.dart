import 'package:drift/drift.dart';

/// Tabel SQLite lokal untuk menyimpan identitas perangkat (Device ID)
/// dan informasi metadata perangkat secara persisten.
/// Data ini tetap bertahan meskipun aplikasi di-restart, user logout,
/// atau user login dengan akun yang berbeda.
@DataClassName('LocalDeviceInfoData')
class LocalDeviceInfo extends Table {
  TextColumn get id => text()(); // Fixed single record id, misal 'current_device'
  TextColumn get deviceId => text()(); // UUID v4 yang dibuat pada first app install
  TextColumn get deviceName => text().nullable()();
  TextColumn get manufacturer => text().nullable()();
  TextColumn get model => text().nullable()();
  TextColumn get androidVersion => text().nullable()();
  TextColumn get appVersion => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastSeenAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
