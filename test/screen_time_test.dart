import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mind_drji/app/core/utils/duration_formatter.dart';
import 'package:mind_drji/app/data/models/app_usage_model.dart';
import 'package:mind_drji/app/data/models/monitoring_visualization_model.dart';
import 'package:mind_drji/app/data/repositories/usage_stats_repository.dart';
import 'package:mind_drji/app/data/services/monitoring_data_service.dart';
import 'package:mind_drji/app/modules/monitoring/controllers/screen_time_controller.dart';
import 'package:mind_drji/app/modules/monitoring/views/screen_time_view.dart';

class FakeScreenTimeRepository implements UsageStatsRepository {
  bool hasAccess = false;
  bool openSettingsResult = true;
  bool shouldThrow = false;
  UsageStatsModel stats = const UsageStatsModel(totalUsageMillis: 0, apps: []);

  @override
  Future<bool> checkUsageAccess() async {
    if (shouldThrow) throw Exception('Permission check failed');
    return hasAccess;
  }

  @override
  Future<bool> openUsageAccessSettings() async {
    return openSettingsResult;
  }

  @override
  Future<UsageStatsModel> getTodayUsage() async {
    if (shouldThrow) throw Exception('Usage query failed');
    return stats;
  }

  @override
  Future<UsageStatsModel?> getLocalTodayUsage() async {
    if (shouldThrow) throw Exception('Usage query failed');
    return stats;
  }

  @override
  Future<UsageStatsModel> getUsageRange({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    if (shouldThrow) throw Exception('Usage query failed');
    return stats;
  }

  @override
  Future<int> claimLocalUsage(String authenticatedUserId) async => 0;
}

void main() {
  late FakeScreenTimeRepository fakeRepo;

  setUp(() {
    Get.reset();
    fakeRepo = FakeScreenTimeRepository();
  });

  tearDown(() {
    Get.reset();
  });

  group('DurationFormatter Tests', () {
    test('Format berbagai durasi waktu dengan benar', () {
      expect(DurationFormatter.format(0), '0m');
      expect(DurationFormatter.format(-100), '0m');
      expect(DurationFormatter.format(30000), '< 1m'); // 30 detik
      expect(DurationFormatter.format(60000), '1m'); // 1 menit
      expect(DurationFormatter.format(2100000), '35m'); // 35 menit
      expect(DurationFormatter.format(3600000), '1j'); // 1 jam pas
      expect(DurationFormatter.format(9300000), '2j 35m'); // 2 jam 35 menit
      expect(DurationFormatter.format(7200000), '2j'); // 2 jam pas
    });
  });

  group('AppUsageModel & UsageStatsModel Tests', () {
    test('fromMap mem-parse data dan memfilter usageMillis <= 0', () {
      final rawData = {
        'totalUsageMillis': 7200000,
        'apps': [
          {
            'packageName': 'com.whatsapp',
            'appName': 'WhatsApp',
            'usageMillis': 3600000,
          },
          {
            'packageName': 'com.instagram.android',
            'appName': 'Instagram',
            'usageMillis': 3600000,
          },
          {
            'packageName': 'com.unused.app',
            'appName': 'Unused App',
            'usageMillis': 0,
          },
        ],
      };

      final stats = UsageStatsModel.fromMap(rawData);
      expect(stats.totalUsageMillis, 7200000);
      expect(stats.apps.length, 2);
      expect(stats.apps[0].appName, 'WhatsApp');
      expect(stats.apps[1].appName, 'Instagram');
    });
  });

  group('ScreenTimeController Logic Tests', () {
    test('State permission false menampilkan card aktivasi', () async {
      fakeRepo.hasAccess = false;
      final controller = ScreenTimeController(repository: fakeRepo);
      await controller.checkPermissionAndLoad();

      expect(controller.hasUsageAccess.value, isFalse);
      expect(controller.totalUsageMillis.value, 0);
      expect(controller.appUsages, isEmpty);
    });

    test('State permission true memuat data penggunaan aplikasi', () async {
      fakeRepo.hasAccess = true;
      fakeRepo.stats = const UsageStatsModel(
        totalUsageMillis: 7200000,
        apps: [
          AppUsageModel(
            packageName: 'com.whatsapp',
            appName: 'WhatsApp',
            usageMillis: 4800000,
          ),
          AppUsageModel(
            packageName: 'com.youtube',
            appName: 'YouTube',
            usageMillis: 2400000,
          ),
        ],
      );

      final controller = ScreenTimeController(repository: fakeRepo);
      await controller.checkPermissionAndLoad();

      expect(controller.hasUsageAccess.value, isTrue);
      expect(controller.totalUsageMillis.value, 7200000);
      expect(controller.appUsages.length, 2);
      expect(controller.appUsages.first.appName, 'WhatsApp');
    });
  });

  group('ScreenTimeView Widget Tests', () {
    testWidgets('Tampilkan kartu permintaan aktivasi saat permission belum diberikan',
        (tester) async {
      fakeRepo.hasAccess = false;
      final controller =
          Get.put(ScreenTimeController(repository: fakeRepo));
      controller.hasUsageAccess.value = false;
      controller.isLoading.value = false;

      await tester.pumpWidget(
        const GetMaterialApp(
          home: ScreenTimeView(),
        ),
      );

      expect(find.text('Screen Time'), findsOneWidget);
      expect(find.text('Monitoring penggunaan belum aktif'), findsOneWidget);
      expect(find.text('Aktifkan Monitoring'), findsOneWidget);
    });

    testWidgets('Tampilkan total durasi dan daftar aplikasi saat permission aktif',
        (tester) async {
      fakeRepo.hasAccess = true;
      fakeRepo.stats = const UsageStatsModel(
        totalUsageMillis: 9300000, // 2j 35m
        apps: [
          AppUsageModel(
            packageName: 'com.whatsapp',
            appName: 'WhatsApp',
            usageMillis: 5700000, // 1j 35m
          ),
          AppUsageModel(
            packageName: 'com.google.android.youtube',
            appName: 'YouTube',
            usageMillis: 3600000, // 1j
          ),
        ],
      );
      final controller =
          Get.put(ScreenTimeController(repository: fakeRepo));
      await controller.initialCheckAndLoad();

      await tester.pumpWidget(
        const GetMaterialApp(
          home: ScreenTimeView(),
        ),
      );
      await tester.pumpAndSettle();

      // Total Screen Time
      expect(find.text('2j 35m'), findsOneWidget);
      expect(find.text('Total penggunaan hari ini'), findsOneWidget);

      // Section Aplikasi
      expect(find.text('Aplikasi yang Digunakan'), findsOneWidget);
      expect(find.text('WhatsApp'), findsOneWidget);
      expect(find.text('1j 35m'), findsOneWidget);
      expect(find.text('YouTube'), findsOneWidget);
      expect(find.text('1j'), findsOneWidget);
    });

    testWidgets('Tampilkan empty state jika permission aktif tapi belum ada data',
        (tester) async {
      fakeRepo.hasAccess = true;
      final controller =
          Get.put(ScreenTimeController(repository: fakeRepo));
      controller.hasUsageAccess.value = true;
      controller.totalUsageMillis.value = 0;
      controller.appUsages.clear();
      controller.isLoading.value = false;

      await tester.pumpWidget(
        const GetMaterialApp(
          home: ScreenTimeView(),
        ),
      );

      expect(
        find.text('Belum ada data penggunaan yang tersedia.'),
        findsOneWidget,
      );
      expect(
        find.text(
            'Data penggunaan aplikasi akan muncul setelah perangkat mencatat aktivitas.'),
        findsOneWidget,
      );
    });
  });

  group('Screen Time Time-Segment Overlap Tests (Phase 1)', () {
    final targetDate = DateTime(2026, 10, 2);

    test('1. Interval 10:50 - 11:20: split into 10m Pagi & 20m Siang', () {
      final intervals = [
        UsageInterval(
          packageName: 'com.whatsapp',
          startTime: DateTime(2026, 10, 2, 10, 50),
          endTime: DateTime(2026, 10, 2, 11, 20),
        ),
      ];

      final segments = MonitoringDataService.calculateUsageIntervalSegments(
        intervals: intervals,
        targetDate: targetDate,
      );

      // Pagi (10:50 - 11:00) = 10 menit = 600,000 ms
      // Siang (11:00 - 11:20) = 20 menit = 1,200,000 ms
      expect(segments[DailyTimeSegment.pagi], 600000);
      expect(segments[DailyTimeSegment.siang], 1200000);
      expect(segments[DailyTimeSegment.diniHari], 0);
      expect(segments[DailyTimeSegment.sore], 0);
      expect(segments[DailyTimeSegment.malam], 0);

      final total = segments.values.fold<int>(0, (sum, val) => sum + val);
      expect(total, 1800000); // 30 menit
    });

    test('2. Interval 04:50 - 05:20: split into 10m Dini Hari & 20m Pagi', () {
      final intervals = [
        UsageInterval(
          packageName: 'com.whatsapp',
          startTime: DateTime(2026, 10, 2, 4, 50),
          endTime: DateTime(2026, 10, 2, 5, 20),
        ),
      ];

      final segments = MonitoringDataService.calculateUsageIntervalSegments(
        intervals: intervals,
        targetDate: targetDate,
      );

      expect(segments[DailyTimeSegment.diniHari], 600000);
      expect(segments[DailyTimeSegment.pagi], 1200000);
      expect(segments[DailyTimeSegment.siang], 0);
      expect(segments[DailyTimeSegment.sore], 0);
      expect(segments[DailyTimeSegment.malam], 0);
    });

    test('3. Interval 14:50 - 15:20: split into 10m Siang & 20m Sore', () {
      final intervals = [
        UsageInterval(
          packageName: 'com.instagram.android',
          startTime: DateTime(2026, 10, 2, 14, 50),
          endTime: DateTime(2026, 10, 2, 15, 20),
        ),
      ];

      final segments = MonitoringDataService.calculateUsageIntervalSegments(
        intervals: intervals,
        targetDate: targetDate,
      );

      expect(segments[DailyTimeSegment.siang], 600000);
      expect(segments[DailyTimeSegment.sore], 1200000);
      expect(segments[DailyTimeSegment.diniHari], 0);
      expect(segments[DailyTimeSegment.pagi], 0);
      expect(segments[DailyTimeSegment.malam], 0);
    });

    test('4. Interval 17:50 - 18:20: split into 10m Sore & 20m Malam', () {
      final intervals = [
        UsageInterval(
          packageName: 'com.google.android.youtube',
          startTime: DateTime(2026, 10, 2, 17, 50),
          endTime: DateTime(2026, 10, 2, 18, 20),
        ),
      ];

      final segments = MonitoringDataService.calculateUsageIntervalSegments(
        intervals: intervals,
        targetDate: targetDate,
      );

      expect(segments[DailyTimeSegment.sore], 600000);
      expect(segments[DailyTimeSegment.malam], 1200000);
      expect(segments[DailyTimeSegment.diniHari], 0);
      expect(segments[DailyTimeSegment.pagi], 0);
      expect(segments[DailyTimeSegment.siang], 0);
    });

    test('5. Interval 23:50 - 00:20 (cross-day): clips correctly per day', () {
      final crossDayInterval = [
        UsageInterval(
          packageName: 'com.ss.android.ugc.trill',
          startTime: DateTime(2026, 10, 2, 23, 50),
          endTime: DateTime(2026, 10, 3, 0, 20),
        ),
      ];

      // On Day 1 (2026-10-02): 23:50 - 24:00 belongs to Malam (10m)
      final day1Segments = MonitoringDataService.calculateUsageIntervalSegments(
        intervals: crossDayInterval,
        targetDate: DateTime(2026, 10, 2),
      );
      expect(day1Segments[DailyTimeSegment.malam], 600000);
      expect(day1Segments[DailyTimeSegment.diniHari], 0);
      expect(day1Segments[DailyTimeSegment.pagi], 0);
      expect(day1Segments[DailyTimeSegment.siang], 0);
      expect(day1Segments[DailyTimeSegment.sore], 0);

      // On Day 2 (2026-10-03): 00:00 - 00:20 belongs to Dini Hari (20m)
      final day2Segments = MonitoringDataService.calculateUsageIntervalSegments(
        intervals: crossDayInterval,
        targetDate: DateTime(2026, 10, 3),
      );
      expect(day2Segments[DailyTimeSegment.diniHari], 1200000);
      expect(day2Segments[DailyTimeSegment.malam], 0);
    });

    test('6. Long interval spanning multi-segments (10:30 - 16:30)', () {
      final intervals = [
        UsageInterval(
          packageName: 'com.example.work',
          startTime: DateTime(2026, 10, 2, 10, 30),
          endTime: DateTime(2026, 10, 2, 16, 30),
        ),
      ];

      final segments = MonitoringDataService.calculateUsageIntervalSegments(
        intervals: intervals,
        targetDate: targetDate,
      );

      // Pagi: 10:30 - 11:00 = 30m = 1,800,000 ms
      // Siang: 11:00 - 15:00 = 4h = 14,400,000 ms
      // Sore: 15:00 - 16:30 = 90m = 5,400,000 ms
      expect(segments[DailyTimeSegment.pagi], 1800000);
      expect(segments[DailyTimeSegment.siang], 14400000);
      expect(segments[DailyTimeSegment.sore], 5400000);
      expect(segments[DailyTimeSegment.diniHari], 0);
      expect(segments[DailyTimeSegment.malam], 0);

      final total = segments.values.fold<int>(0, (sum, val) => sum + val);
      expect(total, 6 * 3600 * 1000); // 6 jam total
    });

    test('7. Interval entirely within single segment (08:15 - 09:45 in Pagi)', () {
      final intervals = [
        UsageInterval(
          packageName: 'com.example.reading',
          startTime: DateTime(2026, 10, 2, 8, 15),
          endTime: DateTime(2026, 10, 2, 9, 45),
        ),
      ];

      final segments = MonitoringDataService.calculateUsageIntervalSegments(
        intervals: intervals,
        targetDate: targetDate,
      );

      expect(segments[DailyTimeSegment.pagi], 90 * 60 * 1000);
      expect(segments[DailyTimeSegment.diniHari], 0);
      expect(segments[DailyTimeSegment.siang], 0);
      expect(segments[DailyTimeSegment.sore], 0);
      expect(segments[DailyTimeSegment.malam], 0);
    });

    test('8. Zero duration interval produces 0 in all segments', () {
      final intervals = [
        UsageInterval(
          packageName: 'com.example.zero',
          startTime: DateTime(2026, 10, 2, 12, 0),
          endTime: DateTime(2026, 10, 2, 12, 0),
        ),
      ];

      final segments = MonitoringDataService.calculateUsageIntervalSegments(
        intervals: intervals,
        targetDate: targetDate,
      );

      for (final val in segments.values) {
        expect(val, 0);
      }
    });

    test('9. Invalid interval (end <= start) produces 0 in all segments', () {
      final intervals = [
        UsageInterval(
          packageName: 'com.example.invalid',
          startTime: DateTime(2026, 10, 2, 14, 0),
          endTime: DateTime(2026, 10, 2, 13, 0),
        ),
      ];

      final segments = MonitoringDataService.calculateUsageIntervalSegments(
        intervals: intervals,
        targetDate: targetDate,
      );

      for (final val in segments.values) {
        expect(val, 0);
      }
    });
  });
}
