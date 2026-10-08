import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:drift/native.dart';
import 'package:mind_drji/app/core/utils/duration_formatter.dart';
import 'package:mind_drji/app/data/local/app_database.dart';
import 'package:mind_drji/app/data/local/repositories/doomscroll_local_repository.dart';
import 'package:mind_drji/app/data/local/repositories/eye_monitoring_local_repository.dart';
import 'package:mind_drji/app/data/local/repositories/local_usage_repository.dart';
import 'package:mind_drji/app/data/models/app_usage_model.dart';
import 'package:mind_drji/app/data/models/monitoring_visualization_model.dart';
import 'package:mind_drji/app/data/repositories/doomscroll_repository.dart';
import 'package:mind_drji/app/data/repositories/eye_monitoring_repository.dart';
import 'package:mind_drji/app/data/repositories/usage_stats_repository.dart';
import 'package:mind_drji/app/data/services/monitoring_data_service.dart';
import 'package:mind_drji/app/modules/monitoring/controllers/monitoring_controller.dart';
import 'package:mind_drji/app/modules/monitoring/views/monitoring_view.dart';

// =============================================================================
// FAKE REPOSITORIES FOR HERMETIC UNIT TESTING
// =============================================================================

final _testDb = AppDatabase(NativeDatabase.memory());

class FakeUsageStatsRepository extends UsageStatsRepository {
  UsageStatsModel mockTodayUsage =
      const UsageStatsModel(totalUsageMillis: 0, apps: []);
  final Map<String, UsageStatsModel> rangeUsageMap = {};

  FakeUsageStatsRepository({LocalUsageRepository? localRepo})
      : super(localRepository: localRepo ?? LocalUsageRepository(db: _testDb));

  @override
  Future<UsageStatsModel> getTodayUsage() async => mockTodayUsage;

  @override
  Future<UsageStatsModel> getUsageRange({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final key = '${startTime.millisecondsSinceEpoch}_${endTime.millisecondsSinceEpoch}';
    return rangeUsageMap[key] ??
        const UsageStatsModel(totalUsageMillis: 0, apps: []);
  }

  @override
  Future<bool> checkUsageAccess() async => true;
}

class FakeLocalUsageRepository extends LocalUsageRepository {
  FakeLocalUsageRepository() : super(db: _testDb);

  final List<ScreenTimeDailyData> storedScreenTimes = [];
  final List<AppUsageDailyData> storedAppUsages = [];

  @override
  Future<ScreenTimeDailyData?> getScreenTime(
    String userId,
    String date, {
    String? deviceId,
  }) async {
    try {
      return storedScreenTimes.firstWhere(
        (st) => st.userId == userId && st.date == date,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<ScreenTimeDailyData>> getScreenTimesBetween({
    required String userId,
    required String startDate,
    required String endDate,
  }) async {
    return storedScreenTimes
        .where((st) =>
            st.userId == userId &&
            st.date.compareTo(startDate) >= 0 &&
            st.date.compareTo(endDate) <= 0)
        .toList();
  }

  @override
  Future<List<AppUsageDailyData>> getAppUsages(
    String userId,
    String date, {
    String? deviceId,
  }) async {
    final list = storedAppUsages
        .where((a) => a.userId == userId && a.date == date)
        .toList();
    list.sort((a, b) => b.usageMillis.compareTo(a.usageMillis));
    return list;
  }

  @override
  Future<List<AppUsageDailyData>> getAppUsagesBetween({
    required String userId,
    required String startDate,
    required String endDate,
  }) async {
    return storedAppUsages
        .where((a) =>
            a.userId == userId &&
            a.date.compareTo(startDate) >= 0 &&
            a.date.compareTo(endDate) <= 0)
        .toList();
  }

  @override
  Future<void> saveTodayUsage({
    required String userId,
    String? deviceId,
    required String date,
    required int totalUsageMillis,
    required List<AppUsageModel> apps,
  }) async {
    storedScreenTimes.removeWhere((st) => st.userId == userId && st.date == date);
    storedScreenTimes.add(createScreenTimeData(
      userId: userId,
      date: date,
      totalMillis: totalUsageMillis,
    ));

    storedAppUsages.removeWhere((a) => a.userId == userId && a.date == date);
    for (final app in apps) {
      storedAppUsages.add(createAppUsageData(
        userId: userId,
        date: date,
        pkg: app.packageName,
        appName: app.appName,
        millis: app.usageMillis,
      ));
    }
  }
}

class FakeDoomscrollRepository extends DoomscrollRepository {
  FakeDoomscrollRepository()
      : super(
          localRepository: DoomscrollLocalRepository(
            db: _testDb,
          ),
        );

  final List<DoomscrollSessionData> storedSessions = [];

  @override
  Future<List<DoomscrollSessionData>> getSessionsBetween({
    required DateTime start,
    required DateTime end,
    String? userId,
  }) async {
    return storedSessions.where((s) {
      if (userId != null && s.userId != userId && s.userId != 'local_user') {
        return false;
      }
      final sEnd = s.endedAt ??
          s.startedAt.add(Duration(milliseconds: s.durationMillis.toInt()));
      return s.startedAt.isBefore(end) && sEnd.isAfter(start);
    }).toList();
  }
}

class FakeEyeMonitoringRepository extends EyeMonitoringRepository {
  FakeEyeMonitoringRepository()
      : super(
          localRepository: EyeMonitoringLocalRepository(
            db: _testDb,
          ),
        );

  final List<EyeMonitoringSessionData> storedSessions = [];

  @override
  Future<List<EyeMonitoringSessionData>> getSessionsBetween({
    required DateTime start,
    required DateTime end,
    String? userId,
  }) async {
    return storedSessions.where((s) {
      if (userId != null && s.userId != userId && s.userId != 'local_user') {
        return false;
      }
      final sEnd = s.endedAt ??
          s.startedAt.add(Duration(milliseconds: s.durationMillis.toInt()));
      return s.startedAt.isBefore(end) && sEnd.isAfter(start);
    }).toList();
  }
}

// Helper factory functions
ScreenTimeDailyData createScreenTimeData({
  required String userId,
  required String date,
  required int totalMillis,
}) {
  return ScreenTimeDailyData(
    id: 'st_${date}_$userId',
    userId: userId,
    deviceId: 'dev_1',
    date: date,
    totalUsageMillis: BigInt.from(totalMillis),
    collectedAt: DateTime.now(),
    syncStatus: 'synced',
    syncAttempts: 0,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

AppUsageDailyData createAppUsageData({
  required String userId,
  required String date,
  required String pkg,
  required String appName,
  required int millis,
}) {
  return AppUsageDailyData(
    id: 'app_${pkg}_$date',
    userId: userId,
    deviceId: 'dev_1',
    date: date,
    packageName: pkg,
    appName: appName,
    usageMillis: BigInt.from(millis),
    collectedAt: DateTime.now(),
    syncStatus: 'synced',
    syncAttempts: 0,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

DoomscrollSessionData createDoomscrollSession({
  required String userId,
  required DateTime start,
  required int durationMillis,
  int swipeCount = 10,
  int downward = 8,
  int upward = 2,
}) {
  return DoomscrollSessionData(
    id: 'ds_${start.millisecondsSinceEpoch}',
    userId: userId,
    deviceId: 'dev_1',
    packageName: 'com.tiktok.app',
    appName: 'TikTok',
    startedAt: start,
    endedAt: start.add(Duration(milliseconds: durationMillis)),
    durationMillis: BigInt.from(durationMillis),
    swipeCount: swipeCount,
    downwardSwipeCount: downward,
    upwardSwipeCount: upward,
    avgInterSwipeMillis: BigInt.from(1200),
    collectedAt: start,
    syncStatus: 'synced',
    syncAttempts: 0,
    createdAt: start,
    updatedAt: start,
  );
}

EyeMonitoringSessionData createEyeSession({
  required String userId,
  required DateTime start,
  required int durationMillis,
  double avgEar = 0.28,
  int closures = 2,
  int blinks = 40,
}) {
  return EyeMonitoringSessionData(
    id: 'eye_${start.millisecondsSinceEpoch}',
    userId: userId,
    deviceId: 'dev_1',
    startedAt: start,
    endedAt: start.add(Duration(milliseconds: durationMillis)),
    durationMillis: BigInt.from(durationMillis),
    averageEar: avgEar,
    minEar: 0.18,
    eyeClosureEvents: closures,
    blinkCount: blinks,
    collectedAt: start,
    syncStatus: 'synced',
    syncAttempts: 0,
    createdAt: start,
    updatedAt: start,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeUsageStatsRepository fakeUsageStats;
  late FakeLocalUsageRepository fakeLocalUsage;
  late FakeDoomscrollRepository fakeDoomscroll;
  late FakeEyeMonitoringRepository fakeEye;
  late MonitoringDataService dataService;

  setUp(() {
    Get.reset();
    fakeUsageStats = FakeUsageStatsRepository();
    fakeLocalUsage = FakeLocalUsageRepository();
    fakeDoomscroll = FakeDoomscrollRepository();
    fakeEye = FakeEyeMonitoringRepository();
    dataService = MonitoringDataService(
      usageStatsRepo: fakeUsageStats,
      localUsageRepo: fakeLocalUsage,
      doomscrollRepo: fakeDoomscroll,
      eyeRepo: fakeEye,
    );
  });

  tearDown(() {
    Get.reset();
  });

  group('Monitoring Visualization Unit & Aggregation Tests', () {
    const testUser = 'user_uuid_123';

    test('1. Daily aggregation: Menghitung total dan perbandingan harian dengan benar',
        () async {
      final today = DateTime(2026, 9, 30);

      // Kemarin 1 jam (3600000 ms)
      fakeLocalUsage.storedScreenTimes.add(
        createScreenTimeData(
          userId: testUser,
          date: '2026-09-29',
          totalMillis: 3600000,
        ),
      );

      // Hari ini 1 jam 35 menit (5700000 ms) -> Naik 35m
      fakeLocalUsage.storedScreenTimes.add(
        createScreenTimeData(
          userId: testUser,
          date: '2026-09-30',
          totalMillis: 5700000,
        ),
      );

      final summary = await dataService.getScreenTimeSummary(
        period: MonitoringPeriod.daily,
        date: today,
        userId: testUser,
      );

      expect(summary['totalMillis'], 5700000);
      expect(summary['comparisonText'], 'Naik 35m dibanding kemarin');
    });

    test('2. Weekly aggregation: Menghitung screen time per hari (Senin - Minggu)',
        () async {
      // 2026-09-30 adalah hari Rabu
      final wednesday = DateTime(2026, 9, 30);

      fakeLocalUsage.storedScreenTimes.addAll([
        createScreenTimeData(
            userId: testUser, date: '2026-09-28', totalMillis: 1800000), // Sen 30m
        createScreenTimeData(
            userId: testUser, date: '2026-09-29', totalMillis: 3600000), // Sel 1j
        createScreenTimeData(
            userId: testUser, date: '2026-09-30', totalMillis: 5400000), // Rab 1j 30m
      ]);

      final weeklyDays = await dataService.getWeeklyDays(
        dateInWeek: wednesday,
        userId: testUser,
      );

      expect(weeklyDays.length, 7);
      expect(weeklyDays[0].dayName, 'Senin');
      expect(weeklyDays[0].screenTimeMillis, 1800000);
      expect(weeklyDays[1].dayName, 'Selasa');
      expect(weeklyDays[1].screenTimeMillis, 3600000);
      expect(weeklyDays[2].dayName, 'Rabu');
      expect(weeklyDays[2].screenTimeMillis, 5400000);
      expect(weeklyDays[3].dayName, 'Kamis');
      expect(weeklyDays[3].screenTimeMillis, 0); // belum ada data
    });

    test('3. Monthly aggregation: Membagi ke Week 1 - Week 5 secara proporsional',
        () async {
      // September 2026 (30 hari)
      fakeLocalUsage.storedScreenTimes.addAll([
        createScreenTimeData(
            userId: testUser, date: '2026-09-02', totalMillis: 3600000), // Week 1 (1-7)
        createScreenTimeData(
            userId: testUser, date: '2026-09-10', totalMillis: 7200000), // Week 2 (8-14)
        createScreenTimeData(
            userId: testUser, date: '2026-09-29', totalMillis: 1800000), // Week 5 (29-30)
      ]);

      final monthlyWeeks = await dataService.getMonthlyWeeks(
        year: 2026,
        month: 9,
        userId: testUser,
      );

      expect(monthlyWeeks.length, 5); // September 30 hari memiliki Week 5
      expect(monthlyWeeks[0].label, 'Week 1');
      expect(monthlyWeeks[0].screenTimeMillis, 3600000);
      expect(monthlyWeeks[1].label, 'Week 2');
      expect(monthlyWeeks[1].screenTimeMillis, 7200000);
      expect(monthlyWeeks[4].label, 'Week 5');
      expect(monthlyWeeks[4].screenTimeMillis, 1800000);
    });

    test('4. Time-of-day segmentation: Memetakan 5 segmen harian secara tepat',
        () async {
      final date = DateTime(2026, 9, 30);

      // Sesi 1: Dini Hari (02:00, 20m)
      fakeDoomscroll.storedSessions.add(
        createDoomscrollSession(
          userId: testUser,
          start: DateTime(2026, 9, 30, 2, 0),
          durationMillis: 20 * 60 * 1000,
          swipeCount: 150,
        ),
      );

      // Sesi 2: Pagi (08:30, 45m)
      fakeDoomscroll.storedSessions.add(
        createDoomscrollSession(
          userId: testUser,
          start: DateTime(2026, 9, 30, 8, 30),
          durationMillis: 45 * 60 * 1000,
          swipeCount: 300,
        ),
      );

      final segments = await dataService.getDailySegments(
        date: date,
        userId: testUser,
      );

      expect(segments.length, 5);
      expect(segments[0].label, 'Dini Hari');
      expect(segments[0].doomscrollMillis, 20 * 60 * 1000);
      expect(segments[0].doomscrollSwipes, 150);

      expect(segments[1].label, 'Pagi');
      expect(segments[1].doomscrollMillis, 45 * 60 * 1000);
      expect(segments[1].doomscrollSwipes, 300);

      expect(segments[2].label, 'Siang');
      expect(segments[2].doomscrollMillis, 0);
    });

    test('5. Empty data state: Menghasilkan summary 0 dan false hasData saat tidak ada data',
        () async {
      final date = DateTime(2026, 9, 30);

      final doomSummary = await dataService.getDoomscrollSummary(
        period: MonitoringPeriod.daily,
        date: date,
        userId: testUser,
      );
      final eyeSummary = await dataService.getEyeMonitoringSummary(
        period: MonitoringPeriod.daily,
        date: date,
        userId: testUser,
      );

      expect(doomSummary.hasData, isFalse);
      expect(doomSummary.totalSessions, 0);
      expect(doomSummary.durationFormatted, '0m');

      expect(eyeSummary.hasData, isFalse);
      expect(eyeSummary.totalSessions, 0);
      expect(eyeSummary.durationFormatted, '0m');
    });

    test('6. Screen time total: Format durasi waktu layar akurat', () {
      expect(DurationFormatter.format(0), '0m');
      expect(DurationFormatter.format(30000), '< 1m');
      expect(DurationFormatter.format(45 * 60 * 1000), '45m');
      expect(DurationFormatter.format((2 * 60 + 35) * 60 * 1000), '2j 35m');
      expect(DurationFormatter.format(5 * 60 * 60 * 1000 + 12 * 60 * 1000), '5j 12m');
    });

    test('7. Top 5 apps: Mengambil maksimal 5 aplikasi teratas dan mengurutkannya secara descending',
        () async {
      final date = DateTime(2026, 9, 30);
      final dStr = '2026-09-30';

      // 8 aplikasi dengan durasi bervariasi
      fakeLocalUsage.storedAppUsages.addAll([
        createAppUsageData(userId: testUser, date: dStr, pkg: 'app.a', appName: 'App A', millis: 10000),
        createAppUsageData(userId: testUser, date: dStr, pkg: 'app.b', appName: 'App B', millis: 50000),
        createAppUsageData(userId: testUser, date: dStr, pkg: 'app.c', appName: 'App C', millis: 20000),
        createAppUsageData(userId: testUser, date: dStr, pkg: 'app.d', appName: 'App D', millis: 80000),
        createAppUsageData(userId: testUser, date: dStr, pkg: 'app.e', appName: 'App E', millis: 60000),
        createAppUsageData(userId: testUser, date: dStr, pkg: 'app.f', appName: 'App F', millis: 90000),
        createAppUsageData(userId: testUser, date: dStr, pkg: 'app.g', appName: 'App G', millis: 30000),
        createAppUsageData(userId: testUser, date: dStr, pkg: 'app.h', appName: 'App H', millis: 70000),
      ]);

      final topApps = await dataService.getTopApps(
        period: MonitoringPeriod.daily,
        date: date,
        userId: testUser,
      );

      expect(topApps.length, 5);
      expect(topApps[0].appName, 'App F'); // 90000 ms
      expect(topApps[1].appName, 'App D'); // 80000 ms
      expect(topApps[2].appName, 'App H'); // 70000 ms
      expect(topApps[3].appName, 'App E'); // 60000 ms
      expect(topApps[4].appName, 'App B'); // 50000 ms
    });

    test('8. Doomscroll total duration & 9. session count & 10. swipe count',
        () async {
      final date = DateTime(2026, 9, 30);

      fakeDoomscroll.storedSessions.addAll([
        createDoomscrollSession(
          userId: testUser,
          start: DateTime(2026, 9, 30, 10, 0),
          durationMillis: 30 * 60 * 1000,
          swipeCount: 500,
          downward: 450,
          upward: 50,
        ),
        createDoomscrollSession(
          userId: testUser,
          start: DateTime(2026, 9, 30, 14, 0),
          durationMillis: 20 * 60 * 1000,
          swipeCount: 300,
          downward: 280,
          upward: 20,
        ),
      ]);

      final summary = await dataService.getDoomscrollSummary(
        period: MonitoringPeriod.daily,
        date: date,
        userId: testUser,
      );

      expect(summary.totalSessions, 2);
      expect(summary.totalDurationMillis, 50 * 60 * 1000);
      expect(summary.durationFormatted, '50m');
      expect(summary.totalSwipes, 800);
      expect(summary.downwardSwipes, 730);
      expect(summary.upwardSwipes, 70);
    });

    test('11. Eye monitoring session count & 12. Eye monitoring duration & average EAR',
        () async {
      final date = DateTime(2026, 9, 30);

      fakeEye.storedSessions.addAll([
        createEyeSession(
          userId: testUser,
          start: DateTime(2026, 9, 30, 9, 0),
          durationMillis: 60 * 1000, // 1m
          avgEar: 0.30,
          closures: 1,
          blinks: 25,
        ),
        createEyeSession(
          userId: testUser,
          start: DateTime(2026, 9, 30, 15, 0),
          durationMillis: 60 * 1000, // 1m
          avgEar: 0.20,
          closures: 3,
          blinks: 15,
        ),
      ]);

      final summary = await dataService.getEyeMonitoringSummary(
        period: MonitoringPeriod.daily,
        date: date,
        userId: testUser,
      );

      expect(summary.totalSessions, 2);
      expect(summary.totalDurationMillis, 120 * 1000);
      expect(summary.durationFormatted, '2m');
      expect(summary.averageEar, closeTo(0.25, 0.01));
      expect(summary.eyeClosureEvents, 4);
      expect(summary.blinkCount, 40);
    });

    test('13. Date navigation: Navigasi tanggal sebelumnya dan format label yang benar',
        () async {
      final ctrl = MonitoringController(dataService: dataService);
      ctrl.selectedDate.value = DateTime(2026, 9, 30);

      expect(ctrl.dateRangeLabel, '30 Sep 2026');

      ctrl.goToPreviousPeriod();
      expect(ctrl.selectedDate.value.day, 29);
      expect(ctrl.dateRangeLabel, '29 Sep 2026');
    });

    test('14. Future date handling: Tombol Next disable jika mencapai hari ini / masa depan',
        () {
      final ctrl = MonitoringController(dataService: dataService);
      // Set ke hari ini
      ctrl.selectedDate.value = DateTime.now();

      // Tidak boleh melangkah ke tanggal masa depan
      expect(ctrl.canGoNext, isFalse);

      // Pindah ke kemarin -> canGoNext harus true
      ctrl.selectedDate.value =
          DateTime.now().subtract(const Duration(days: 2));
      expect(ctrl.canGoNext, isTrue);
    });

    test('15. Loading state: Controller merefleksikan isLoading saat refresh',
        () async {
      final ctrl = MonitoringController(dataService: dataService);
      final loadFuture = ctrl.loadData();
      expect(ctrl.isLoading.value, isTrue);
      await loadFuture;
      expect(ctrl.isLoading.value, isFalse);
    });

    test('16. Real user UUID isolation: Data user lain tidak tercampur',
        () async {
      final date = DateTime(2026, 9, 30);

      // Data milik user A
      fakeLocalUsage.storedScreenTimes.add(
        createScreenTimeData(
          userId: 'user_A',
          date: '2026-09-30',
          totalMillis: 9999999,
        ),
      );

      // Data milik user B
      fakeLocalUsage.storedScreenTimes.add(
        createScreenTimeData(
          userId: 'user_B',
          date: '2026-09-30',
          totalMillis: 1000,
        ),
      );

      final summaryA = await dataService.getScreenTimeSummary(
        period: MonitoringPeriod.daily,
        date: date,
        userId: 'user_A',
      );

      final summaryB = await dataService.getScreenTimeSummary(
        period: MonitoringPeriod.daily,
        date: date,
        userId: 'user_B',
      );

      expect(summaryA['totalMillis'], 9999999);
      expect(summaryB['totalMillis'], 1000);
    });

    // =========================================================================
    // EDGE CASES
    // =========================================================================

    test('Edge case: Sesi melintasi batas waktu (Time boundary crossing)', () {
      // Sesi mulai 04:50 dan berakhir 05:20 (30 menit)
      final sessionStart = DateTime(2026, 9, 30, 4, 50);
      final sessionEnd = DateTime(2026, 9, 30, 5, 20);

      final diniHariStart = DateTime(2026, 9, 30, 0, 0);
      final diniHariEnd = DateTime(2026, 9, 30, 5, 0);

      final pagiStart = DateTime(2026, 9, 30, 5, 0);
      final pagiEnd = DateTime(2026, 9, 30, 11, 0);

      final overlapDini = MonitoringDataService.calculateOverlap(
        sessionStart,
        sessionEnd,
        diniHariStart,
        diniHariEnd,
      );
      final overlapPagi = MonitoringDataService.calculateOverlap(
        sessionStart,
        sessionEnd,
        pagiStart,
        pagiEnd,
      );

      // 10 menit di Dini Hari (04:50 - 05:00)
      expect(overlapDini, 10 * 60 * 1000);
      // 20 menit di Pagi (05:00 - 05:20)
      expect(overlapPagi, 20 * 60 * 1000);
      // Total tetap 30 menit
      expect(overlapDini + overlapPagi, 30 * 60 * 1000);
    });

    test('Edge case: Sesi melintasi tengah malam (Midnight boundary crossing)', () {
      // Sesi mulai 23:45 (hari 1) dan selesai 00:15 (hari 2)
      final sStart = DateTime(2026, 9, 29, 23, 45);
      final sEnd = DateTime(2026, 9, 30, 0, 15);

      final day1MalamStart = DateTime(2026, 9, 29, 18, 0);
      final day1MalamEnd = DateTime(2026, 9, 29, 23, 59, 59, 999);

      final day2DiniStart = DateTime(2026, 9, 30, 0, 0);
      final day2DiniEnd = DateTime(2026, 9, 30, 5, 0);

      final overlapDay1 = MonitoringDataService.calculateOverlap(
        sStart,
        sEnd,
        day1MalamStart,
        day1MalamEnd,
      );
      final overlapDay2 = MonitoringDataService.calculateOverlap(
        sStart,
        sEnd,
        day2DiniStart,
        day2DiniEnd,
      );

      // Hari 1: ~15 menit
      expect(overlapDay1, closeTo(15 * 60 * 1000, 1000));
      // Hari 2: 15 menit
      expect(overlapDay2, 15 * 60 * 1000);
    });

    test('Edge case: Bulan dengan 28 hari (Februari biasa) tidak memiliki Week 5',
        () async {
      final weeksFeb = await dataService.getMonthlyWeeks(
        year: 2025, // Bukan tahun kabisat (28 hari)
        month: 2,
        userId: testUser,
      );

      // Tepat 4 minggu
      expect(weeksFeb.length, 4);
      expect(weeksFeb.any((w) => w.label == 'Week 5'), isFalse);
    });

    test('Edge case: Minggu yang melintasi pergantian bulan (Week crossing month)',
        () {
      final ctrl = MonitoringController(dataService: dataService);
      ctrl.selectedPeriod.value = MonitoringPeriod.weekly;

      // 30 September 2026 berada dalam minggu 28 Sep – 4 Okt
      ctrl.selectedDate.value = DateTime(2026, 9, 30);
      expect(ctrl.dateRangeLabel, '28 Sep – 4 Okt');
    });

    test('Weekly Tab: Backfill hari lampau dari UsageStatsManager jika SQLite kosong', () async {
      final now = DateTime.now();
      // Misal hari ini adalah hari tertentu dalam minggu ini (Senin-Minggu)
      final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));

      // Jika sekarang bukan hari Senin, buat mock data getUsageRange untuk hari Senin lampau
      if (now.weekday > 1) {
        final pastMondayStart = DateTime(monday.year, monday.month, monday.day, 0, 0, 0);
        final pastMondayEnd = pastMondayStart.add(const Duration(days: 1));
        final key = '${pastMondayStart.millisecondsSinceEpoch}_${pastMondayEnd.millisecondsSinceEpoch}';

        fakeUsageStats.rangeUsageMap[key] = const UsageStatsModel(
          totalUsageMillis: 7200000, // 2 jam
          apps: [
            AppUsageModel(packageName: 'com.mobile.legends', appName: 'Mobile Legends', usageMillis: 3600000),
            AppUsageModel(packageName: 'com.tiktok.app', appName: 'TikTok', usageMillis: 3600000),
          ],
        );
      }

      final weeklyDays = await dataService.getWeeklyDays(
        dateInWeek: now,
        userId: testUser,
      );

      expect(weeklyDays.length, 7);
      if (now.weekday > 1) {
        // Senin lampau berhasil di-backfill ke 7200000 ms
        expect(weeklyDays[0].screenTimeMillis, 7200000);
      }
    });

    test('Weekly Tab: getTopApps menggabungkan SQLite lampau dan live apps hari ini', () async {
      final now = DateTime.now();
      final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));

      // 1. Simpan app hari lampau di SQLite jika ada
      if (now.weekday > 1) {
        final pastDateStr = dataService.formatDate(monday);
        fakeLocalUsage.storedAppUsages.add(
          createAppUsageData(
            userId: testUser,
            date: pastDateStr,
            pkg: 'com.game.magicchess',
            appName: 'Magic Chess',
            millis: 3600000, // 1 jam
          ),
        );
      }

      // 2. Set live apps hari ini
      fakeUsageStats.mockTodayUsage = const UsageStatsModel(
        totalUsageMillis: 1800000,
        apps: [
          AppUsageModel(packageName: 'com.game.magicchess', appName: 'Magic Chess', usageMillis: 1800000), // +30m
          AppUsageModel(packageName: 'com.zhiliaoapp.musically', appName: 'TikTok', usageMillis: 1800000), // 30m
        ],
      );

      final topApps = await dataService.getTopApps(
        period: MonitoringPeriod.weekly,
        date: now,
        userId: testUser,
      );

      expect(topApps.isNotEmpty, isTrue);
      final mc = topApps.firstWhere((a) => a.packageName == 'com.game.magicchess');
      if (now.weekday > 1) {
        // 1 jam (SQLite) + 30m (Live) = 5400000 ms
        expect(mc.usageMillis, 5400000);
      } else {
        expect(mc.usageMillis, 1800000);
      }
    });

    test('Weekly Tab: Screen time summary menghitung total dan comparison text', () async {
      final wednesday = DateTime(2026, 9, 30); // Rabu
      // Minggu ini: 3 hari ada data (30m + 1j + 1j 30m = 3j = 10800000 ms)
      fakeLocalUsage.storedScreenTimes.addAll([
        createScreenTimeData(userId: testUser, date: '2026-09-28', totalMillis: 1800000),
        createScreenTimeData(userId: testUser, date: '2026-09-29', totalMillis: 3600000),
        createScreenTimeData(userId: testUser, date: '2026-09-30', totalMillis: 5400000),
      ]);

      // Minggu lalu: total 2 jam (7200000 ms) -> Naik 1j dibanding minggu lalu
      fakeLocalUsage.storedScreenTimes.addAll([
        createScreenTimeData(userId: testUser, date: '2026-09-21', totalMillis: 3600000),
        createScreenTimeData(userId: testUser, date: '2026-09-22', totalMillis: 3600000),
      ]);

      final summary = await dataService.getScreenTimeSummary(
        period: MonitoringPeriod.weekly,
        date: wednesday,
        userId: testUser,
      );

      expect(summary['totalMillis'], 10800000);
      expect(summary['comparisonText'], 'Naik 1j dibanding minggu lalu');
    });
  });

  group('MonitoringView Widget Tests', () {
    testWidgets('Tampilkan seluruh card monitoring dan tab periode dengan benar',
        (tester) async {
      final ctrl = Get.put(MonitoringController(dataService: dataService));
      ctrl.isLoading.value = false;
      ctrl.errorMessage.value = null;

      await tester.pumpWidget(
        const GetMaterialApp(
          home: MonitoringView(),
        ),
      );

      // Tab periode
      expect(find.text('Hari'), findsOneWidget);
      expect(find.text('Minggu'), findsOneWidget);
      expect(find.text('Bulan'), findsOneWidget);

      // Card titles
      expect(find.text('Total Screen Time'), findsOneWidget);
      expect(find.text('Penggunaan Aplikasi'), findsOneWidget);
      expect(find.text('Pola Scrolling'), findsOneWidget);
      expect(find.text('Monitoring Mata'), findsOneWidget);

      // Navigasi tanggal
      expect(find.byKey(const Key('btn_prev_date')), findsOneWidget);
      expect(find.byKey(const Key('btn_next_date')), findsOneWidget);
    });
  });
}
