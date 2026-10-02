import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mind_drji/app/data/local/app_database.dart';
import 'package:mind_drji/app/data/local/repositories/local_usage_repository.dart';
import 'package:mind_drji/app/data/local/tables/sync_queue.dart';
import 'package:mind_drji/app/data/models/app_usage_model.dart';
import 'package:mind_drji/app/data/sync/sync_manager.dart';

void main() {
  late AppDatabase db;
  late LocalUsageRepository repository;

  setUp(() {
    Get.reset();
    // Gunakan in-memory SQLite database murni untuk pengujian lokal
    db = AppDatabase(NativeDatabase.memory());
    repository = LocalUsageRepository(db: db);
  });

  tearDown(() async {
    await db.close();
    Get.reset();
  });

  group('LocalUsageRepository - Local First & Offline Tests', () {
    test('saveTodayUsage menyimpan data screen time dan app usage ke SQLite lokal',
        () async {
      const userId = 'user-test-uuid-1';
      const date = '2026-09-28';
      const totalUsageMillis = 7200000; // 2 jam

      final apps = [
        const AppUsageModel(
          packageName: 'com.whatsapp',
          appName: 'WhatsApp',
          usageMillis: 4500000,
        ),
        const AppUsageModel(
          packageName: 'com.instagram.android',
          appName: 'Instagram',
          usageMillis: 2700000,
        ),
      ];

      await repository.saveTodayUsage(
        userId: userId,
        date: date,
        totalUsageMillis: totalUsageMillis,
        apps: apps,
      );

      // Verifikasi Screen Time tersimpan
      final screenTime = await repository.getScreenTime(userId, date);
      expect(screenTime, isNotNull);
      expect(screenTime!.totalUsageMillis.toInt(), totalUsageMillis);
      expect(screenTime.syncStatus, SyncStatus.pending);

      // Verifikasi App Usages tersimpan
      final savedApps = await repository.getAppUsages(userId, date);
      expect(savedApps.length, 2);
      expect(savedApps[0].packageName, 'com.whatsapp');
      expect(savedApps[0].usageMillis.toInt(), 4500000);
      expect(savedApps[1].packageName, 'com.instagram.android');
      expect(savedApps[1].usageMillis.toInt(), 2700000);

      // Verifikasi Sync Queue terisi
      final queue = await repository.getPendingQueue();
      expect(queue.length, 3); // 1 screen_time + 2 apps
      expect(await repository.getPendingSyncCount(userId), 3);
    });

    test('saveTodayUsage berulang kali melakukan UPSERT (tidak duplikat)',
        () async {
      const userId = 'user-test-uuid-2';
      const date = '2026-09-28';

      // Simpan pertama kali
      await repository.saveTodayUsage(
        userId: userId,
        date: date,
        totalUsageMillis: 3600000,
        apps: [
          const AppUsageModel(
            packageName: 'com.whatsapp',
            appName: 'WhatsApp',
            usageMillis: 3600000,
          ),
        ],
      );

      var apps = await repository.getAppUsages(userId, date);
      expect(apps.length, 1);
      expect(apps.first.usageMillis.toInt(), 3600000);

      // Refresh / Simpan kedua kali dengan nilai terupdate
      await repository.saveTodayUsage(
        userId: userId,
        date: date,
        totalUsageMillis: 5400000,
        apps: [
          const AppUsageModel(
            packageName: 'com.whatsapp',
            appName: 'WhatsApp',
            usageMillis: 5400000,
          ),
        ],
      );

      // Pastikan tetap hanya ada 1 baris (UPSERT)
      apps = await repository.getAppUsages(userId, date);
      expect(apps.length, 1);
      expect(apps.first.usageMillis.toInt(), 5400000);

      final screenTime = await repository.getScreenTime(userId, date);
      expect(screenTime!.totalUsageMillis.toInt(), 5400000);
    });

    test('markScreenTimeSynced dan markAppUsageSynced memperbarui status dan menghapus queue',
        () async {
      const userId = 'user-test-uuid-3';
      const date = '2026-09-28';

      await repository.saveTodayUsage(
        userId: userId,
        date: date,
        totalUsageMillis: 1800000,
        apps: [
          const AppUsageModel(
            packageName: 'com.youtube',
            appName: 'YouTube',
            usageMillis: 1800000,
          ),
        ],
      );

      final screenTime = await repository.getScreenTime(userId, date);
      final apps = await repository.getAppUsages(userId, date);

      // Tandai berhasil sync
      await repository.markScreenTimeSynced(screenTime!.id);
      await repository.markAppUsageSynced(apps.first.id);

      // Cek status lokal
      final updatedScreenTime = await repository.getScreenTime(userId, date);
      final updatedApps = await repository.getAppUsages(userId, date);

      expect(updatedScreenTime!.syncStatus, SyncStatus.synced);
      expect(updatedApps.first.syncStatus, SyncStatus.synced);

      // Antrean harus kosong
      final pendingCount = await repository.getPendingSyncCount(userId);
      expect(pendingCount, 0);
    });

    test('markScreenTimeFailed dan markAppUsageFailed mencatat error dan increment attempt',
        () async {
      const userId = 'user-test-uuid-4';
      const date = '2026-09-28';

      await repository.saveTodayUsage(
        userId: userId,
        date: date,
        totalUsageMillis: 1000,
        apps: [
          const AppUsageModel(
            packageName: 'com.test',
            appName: 'Test',
            usageMillis: 1000,
          ),
        ],
      );

      final screenTime = await repository.getScreenTime(userId, date);
      final apps = await repository.getAppUsages(userId, date);

      await repository.markScreenTimeFailed(screenTime!.id, 'Timeout network error');
      await repository.markAppUsageFailed(apps.first.id, 'Supabase RLS error');

      final updatedST = await repository.getScreenTime(userId, date);
      final updatedApp = await repository.getAppUsages(userId, date);

      expect(updatedST!.syncStatus, SyncStatus.failed);
      expect(updatedST.syncAttempts, 1);
      expect(updatedST.lastSyncError, 'Timeout network error');

      expect(updatedApp.first.syncStatus, SyncStatus.failed);
      expect(updatedApp.first.syncAttempts, 1);
      expect(updatedApp.first.lastSyncError, 'Supabase RLS error');
    });
  });

  group('SyncManager Observable State Tests', () {
    test('SyncManager merefleksikan status pending dan offline secara reaktif',
        () async {
      final syncManager = SyncManager(
        localRepo: repository,
        autoStart: false,
      );

      expect(syncManager.isSyncing.value, isFalse);
      expect(syncManager.isOnline.value, isTrue);
      expect(syncManager.pendingCount.value, 0);
      expect(syncManager.syncStatus.value, SyncStatus.synced);

      // Simulasi trigger manual sync saat offline
      syncManager.isOnline.value = false;
      final result = await syncManager.triggerManualSync();
      expect(result, isFalse);
    });
  });
}
