import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'tables/app_usage_daily.dart';
import 'tables/doomscroll_sessions.dart';
import 'tables/eye_monitoring_config.dart';
import 'tables/eye_monitoring_sessions.dart';
import 'tables/intervention_histories.dart';
import 'tables/local_device_info.dart';
import 'tables/screen_time_daily.dart';
import 'tables/sync_queue.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  ScreenTimeDaily,
  AppUsageDaily,
  SyncQueue,
  DoomscrollSessions,
  EyeMonitoringSessions,
  LocalDeviceInfo,
  EyeMonitoringConfig,
  InterventionHistories,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e])
      : super(e ?? driftDatabase(name: 'mind_drji_local'));

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(doomscrollSessions);
          }
          if (from < 3) {
            await m.createTable(eyeMonitoringSessions);
          }
          if (from < 4) {
            await m.createTable(localDeviceInfo);
            await m.addColumn(screenTimeDaily, screenTimeDaily.deviceId);
            await m.addColumn(appUsageDaily, appUsageDaily.deviceId);
            await m.addColumn(doomscrollSessions, doomscrollSessions.deviceId);
            await m.addColumn(eyeMonitoringSessions, eyeMonitoringSessions.deviceId);
          }
          if (from < 5) {
            await m.createTable(eyeMonitoringConfig);
          }
          if (from < 6) {
            await m.createTable(interventionHistories);
          }
        },
      );
}
