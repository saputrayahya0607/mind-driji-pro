import 'package:drift/drift.dart';
import 'package:get/get.dart' hide Value;
import '../../../core/utils/uuid_generator.dart';
import '../../models/app_usage_model.dart';
import '../../services/device_service.dart';
import '../app_database.dart';
import '../tables/sync_queue.dart';

class LocalUsageRepository {
  final AppDatabase _db;

  LocalUsageRepository({AppDatabase? db}) : _db = db ?? AppDatabase();

  AppDatabase get db => _db;

  String _resolveDeviceId([String? deviceId]) {
    if (deviceId != null && deviceId.isNotEmpty) return deviceId;
    try {
      if (Get.isRegistered<DeviceService>()) {
        return DeviceService.to.deviceId;
      }
    } catch (_) {}
    return 'legacy';
  }

  /// Menyimpan data Screen Time dan App Usage hari ini ke database SQLite lokal secara UPSERT
  /// Sekaligus mendaftarkan antrean ke sync_queue agar siap disinkronkan ke Supabase.
  Future<void> saveTodayUsage({
    required String userId,
    String? deviceId,
    required String date,
    required int totalUsageMillis,
    required List<AppUsageModel> apps,
  }) async {
    final devId = _resolveDeviceId(deviceId);
    final now = DateTime.now();

    await _db.transaction(() async {
      // 1. UPSERT screen_time_daily (unique pada userId, deviceId, date)
      final existingScreenTime = await (_db.select(_db.screenTimeDaily)
            ..where((tbl) =>
                tbl.userId.equals(userId) &
                tbl.deviceId.equals(devId) &
                tbl.date.equals(date)))
          .getSingleOrNull();

      String screenTimeId;
      if (existingScreenTime != null) {
        screenTimeId = existingScreenTime.id;
        await (_db.update(_db.screenTimeDaily)
              ..where((tbl) => tbl.id.equals(screenTimeId)))
            .write(
          ScreenTimeDailyCompanion(
            totalUsageMillis: Value(BigInt.from(totalUsageMillis)),
            collectedAt: Value(now),
            syncStatus: const Value(SyncStatus.pending),
            updatedAt: Value(now),
          ),
        );
      } else {
        screenTimeId = UuidGenerator.v4();
        await _db.into(_db.screenTimeDaily).insert(
              ScreenTimeDailyCompanion.insert(
                id: screenTimeId,
                userId: userId,
                deviceId: Value(devId),
                date: date,
                totalUsageMillis: BigInt.from(totalUsageMillis),
                collectedAt: now,
                syncStatus: const Value(SyncStatus.pending),
                syncAttempts: const Value(0),
                createdAt: now,
                updatedAt: now,
              ),
            );
      }

      // Enqueue sync untuk screen_time_daily
      await _enqueueSync(
        entityType: SyncEntityType.screenTimeDaily,
        entityId: screenTimeId,
      );

      // 2. UPSERT app_usage_daily untuk setiap aplikasi (unique pada userId, deviceId, date, packageName)
      for (final app in apps) {
        if (app.usageMillis <= 0) continue;

        final existingApp = await (_db.select(_db.appUsageDaily)
              ..where((tbl) =>
                  tbl.userId.equals(userId) &
                  tbl.deviceId.equals(devId) &
                  tbl.date.equals(date) &
                  tbl.packageName.equals(app.packageName)))
            .getSingleOrNull();

        String appUsageId;
        if (existingApp != null) {
          appUsageId = existingApp.id;
          await (_db.update(_db.appUsageDaily)
                ..where((tbl) => tbl.id.equals(appUsageId)))
              .write(
            AppUsageDailyCompanion(
              appName: Value(app.appName),
              usageMillis: Value(BigInt.from(app.usageMillis)),
              collectedAt: Value(now),
              syncStatus: const Value(SyncStatus.pending),
              updatedAt: Value(now),
            ),
          );
        } else {
          appUsageId = UuidGenerator.v4();
          await _db.into(_db.appUsageDaily).insert(
                AppUsageDailyCompanion.insert(
                  id: appUsageId,
                  userId: userId,
                  deviceId: Value(devId),
                  date: date,
                  packageName: app.packageName,
                  appName: app.appName,
                  usageMillis: BigInt.from(app.usageMillis),
                  collectedAt: now,
                  syncStatus: const Value(SyncStatus.pending),
                  syncAttempts: const Value(0),
                  createdAt: now,
                  updatedAt: now,
                ),
              );
        }

        // Enqueue sync untuk app_usage_daily
        await _enqueueSync(
          entityType: SyncEntityType.appUsageDaily,
          entityId: appUsageId,
        );
      }
    });
  }

  /// Mendaftarkan antrean sync jika entitas belum mengantre
  Future<void> _enqueueSync({
    required String entityType,
    required String entityId,
  }) async {
    final existingQueue = await (_db.select(_db.syncQueue)
          ..where((tbl) =>
              tbl.entityType.equals(entityType) &
              tbl.entityId.equals(entityId)))
        .getSingleOrNull();

    if (existingQueue == null) {
      await _db.into(_db.syncQueue).insert(
            SyncQueueCompanion.insert(
              id: UuidGenerator.v4(),
              entityType: entityType,
              entityId: entityId,
              operation: const Value(SyncOperation.upsert),
              createdAt: DateTime.now(),
              retryCount: const Value(0),
            ),
          );
    }
  }

  /// Mengambil data Screen Time lokal pada tanggal tertentu
  Future<ScreenTimeDailyData?> getScreenTime(
    String userId,
    String date, {
    String? deviceId,
  }) {
    final devId = _resolveDeviceId(deviceId);
    return (_db.select(_db.screenTimeDaily)
          ..where((tbl) =>
              (tbl.userId.equals(userId) | tbl.userId.equals('local_user')) &
              (tbl.deviceId.equals(devId) | tbl.deviceId.equals('legacy')) &
              tbl.date.equals(date)))
        .getSingleOrNull();
  }

  /// Mengambil daftar penggunaan aplikasi lokal pada tanggal tertentu, diurutkan DESC
  Future<List<AppUsageDailyData>> getAppUsages(
    String userId,
    String date, {
    String? deviceId,
  }) {
    final devId = _resolveDeviceId(deviceId);
    return (_db.select(_db.appUsageDaily)
          ..where((tbl) =>
              (tbl.userId.equals(userId) | tbl.userId.equals('local_user')) &
              (tbl.deviceId.equals(devId) | tbl.deviceId.equals('legacy')) &
              tbl.date.equals(date))
          ..orderBy([
            (t) => OrderingTerm(
                expression: t.usageMillis, mode: OrderingMode.desc)
          ]))
        .get();
  }

  /// Mengambil antrean sinkronisasi
  Future<List<SyncQueueData>> getPendingQueue() {
    return (_db.select(_db.syncQueue)
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  /// Menghitung jumlah data yang belum tersinkronisasi (pending / failed)
  Future<int> getPendingSyncCount(String userId) async {
    final pendingQueue = await _db.select(_db.syncQueue).get();
    return pendingQueue.length;
  }

  /// Mengambil single data screen_time_daily berdasarkan ID
  Future<ScreenTimeDailyData?> getScreenTimeById(String id) {
    return (_db.select(_db.screenTimeDaily)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  /// Mengambil single data app_usage_daily berdasarkan ID
  Future<AppUsageDailyData?> getAppUsageById(String id) {
    return (_db.select(_db.appUsageDaily)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  /// Menandai data screen_time_daily berhasil tersinkron
  Future<void> markScreenTimeSynced(String id) async {
    await (_db.update(_db.screenTimeDaily)..where((tbl) => tbl.id.equals(id)))
        .write(
      const ScreenTimeDailyCompanion(
        syncStatus: Value(SyncStatus.synced),
        lastSyncError: Value(null),
      ),
    );
    await (_db.delete(_db.syncQueue)
          ..where((tbl) =>
              tbl.entityType.equals(SyncEntityType.screenTimeDaily) &
              tbl.entityId.equals(id)))
        .go();
  }

  /// Menandai data screen_time_daily gagal tersinkron
  Future<void> markScreenTimeFailed(String id, String error) async {
    final current = await getScreenTimeById(id);
    final attempts = (current?.syncAttempts ?? 0) + 1;

    await (_db.update(_db.screenTimeDaily)..where((tbl) => tbl.id.equals(id)))
        .write(
      ScreenTimeDailyCompanion(
        syncStatus: const Value(SyncStatus.failed),
        syncAttempts: Value(attempts),
        lastSyncError: Value(error),
      ),
    );
  }

  /// Menandai data app_usage_daily berhasil tersinkron
  Future<void> markAppUsageSynced(String id) async {
    await (_db.update(_db.appUsageDaily)..where((tbl) => tbl.id.equals(id)))
        .write(
      const AppUsageDailyCompanion(
        syncStatus: Value(SyncStatus.synced),
        lastSyncError: Value(null),
      ),
    );
    await (_db.delete(_db.syncQueue)
          ..where((tbl) =>
              tbl.entityType.equals(SyncEntityType.appUsageDaily) &
              tbl.entityId.equals(id)))
        .go();
  }

  /// Menandai data app_usage_daily gagal tersinkron
  Future<void> markAppUsageFailed(String id, String error) async {
    final current = await getAppUsageById(id);
    final attempts = (current?.syncAttempts ?? 0) + 1;

    await (_db.update(_db.appUsageDaily)..where((tbl) => tbl.id.equals(id)))
        .write(
      AppUsageDailyCompanion(
        syncStatus: const Value(SyncStatus.failed),
        syncAttempts: Value(attempts),
        lastSyncError: Value(error),
      ),
    );
  }

  /// Memperbarui retry count dan error di sync_queue
  Future<void> updateQueueRetry(String queueId, String error) async {
    final queue = await (_db.select(_db.syncQueue)
          ..where((tbl) => tbl.id.equals(queueId)))
        .getSingleOrNull();
    final count = (queue?.retryCount ?? 0) + 1;
    await (_db.update(_db.syncQueue)..where((tbl) => tbl.id.equals(queueId)))
        .write(
      SyncQueueCompanion(
        retryCount: Value(count),
        lastError: Value(error),
      ),
    );
  }

  /// Menghapus antrean sync berdasarkan ID antrean
  Future<void> removeQueueItem(String queueId) async {
    await (_db.delete(_db.syncQueue)..where((tbl) => tbl.id.equals(queueId)))
        .go();
  }

  /// Mengambil semua riwayat Screen Time lokal untuk seorang pengguna
  Future<List<ScreenTimeDailyData>> getAllScreenTimes(String userId) {
    return (_db.select(_db.screenTimeDaily)
          ..where((tbl) => tbl.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  /// Mengambil riwayat Screen Time lokal dalam rentang tanggal tertentu [startDate .. endDate]
  Future<List<ScreenTimeDailyData>> getScreenTimesBetween({
    required String userId,
    required String startDate,
    required String endDate,
  }) {
    return (_db.select(_db.screenTimeDaily)
          ..where((tbl) =>
              (tbl.userId.equals(userId) | tbl.userId.equals('local_user')) &
              tbl.date.isBiggerOrEqualValue(startDate) &
              tbl.date.isSmallerOrEqualValue(endDate))
          ..orderBy([(t) => OrderingTerm.asc(t.date)]))
        .get();
  }

  /// Mengambil data penggunaan aplikasi dalam rentang tanggal tertentu [startDate .. endDate]
  Future<List<AppUsageDailyData>> getAppUsagesBetween({
    required String userId,
    required String startDate,
    required String endDate,
  }) {
    return (_db.select(_db.appUsageDaily)
          ..where((tbl) =>
              (tbl.userId.equals(userId) | tbl.userId.equals('local_user')) &
              tbl.date.isBiggerOrEqualValue(startDate) &
              tbl.date.isSmallerOrEqualValue(endDate))
          ..orderBy([
            (t) => OrderingTerm(
                expression: t.usageMillis, mode: OrderingMode.desc)
          ]))
        .get();
  }

  /// Mengaitkan seluruh data screen time dan app usage berlabel 'local_user' ke userId user yang sedang login
  Future<int> claimLocalUsage(String authenticatedUserId) async {
    if (authenticatedUserId.isEmpty || authenticatedUserId == 'local_user') return 0;
    final now = DateTime.now();
    var count = 0;
    await _db.transaction(() async {
      final stCount = await (_db.update(_db.screenTimeDaily)
            ..where((t) => t.userId.equals('local_user')))
          .write(
        ScreenTimeDailyCompanion(
          userId: Value(authenticatedUserId),
          updatedAt: Value(now),
        ),
      );
      final auCount = await (_db.update(_db.appUsageDaily)
            ..where((t) => t.userId.equals('local_user')))
          .write(
        AppUsageDailyCompanion(
          userId: Value(authenticatedUserId),
          updatedAt: Value(now),
        ),
      );
      count = stCount + auCount;
    });
    return count;
  }
}
