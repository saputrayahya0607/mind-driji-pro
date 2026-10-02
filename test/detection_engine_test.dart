import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mind_drji/app/data/local/app_database.dart';
import 'package:mind_drji/app/data/local/repositories/doomscroll_local_repository.dart';
import 'package:mind_drji/app/data/local/repositories/eye_monitoring_local_repository.dart';
import 'package:mind_drji/app/data/local/repositories/local_usage_repository.dart';
import 'package:mind_drji/app/data/models/app_usage_model.dart';
import 'package:mind_drji/app/data/models/detection_result.dart';
import 'package:mind_drji/app/data/repositories/doomscroll_repository.dart';
import 'package:mind_drji/app/data/repositories/eye_monitoring_repository.dart';
import 'package:mind_drji/app/data/repositories/usage_stats_repository.dart';
import 'package:mind_drji/app/data/services/detection/detection_engine.dart';
import 'package:mind_drji/app/data/services/detection/detection_feature_extractor.dart';
import 'package:mind_drji/app/data/services/detection/detection_thresholds.dart';
import 'package:mind_drji/app/data/services/detection/rule_based_detection_strategy.dart';
import 'package:mind_drji/app/data/services/detection_service.dart';
import 'package:mind_drji/app/modules/insight/controllers/insight_controller.dart';

// =============================================================================
// TEST HELPERS & FAKES
// =============================================================================

final _testDb = AppDatabase(NativeDatabase.memory());

class FakeDetectionUsageStatsRepo extends UsageStatsRepository {
  UsageStatsModel mockUsage =
      const UsageStatsModel(totalUsageMillis: 0, apps: []);

  FakeDetectionUsageStatsRepo()
      : super(localRepository: LocalUsageRepository(db: _testDb));

  @override
  Future<UsageStatsModel> getTodayUsage() async => mockUsage;

  @override
  Future<UsageStatsModel> getUsageRange({
    required DateTime startTime,
    required DateTime endTime,
  }) async =>
      mockUsage;

  @override
  Future<bool> checkUsageAccess() async => true;
}

class FakeDetectionLocalUsageRepo extends LocalUsageRepository {
  FakeDetectionLocalUsageRepo() : super(db: _testDb);

  final List<ScreenTimeDailyData> screenTimes = [];

  @override
  Future<ScreenTimeDailyData?> getScreenTime(
    String userId,
    String date, {
    String? deviceId,
  }) async {
    try {
      return screenTimes.firstWhere(
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
    return screenTimes
        .where((st) =>
            st.userId == userId &&
            st.date.compareTo(startDate) >= 0 &&
            st.date.compareTo(endDate) <= 0)
        .toList();
  }
}

class FakeDetectionDoomscrollRepo extends DoomscrollRepository {
  final List<DoomscrollSessionData> storedSessions = [];
  bool collectCalled = false;

  FakeDetectionDoomscrollRepo()
      : super(localRepository: DoomscrollLocalRepository(db: _testDb));

  @override
  Future<int> collectAndPersistPendingSessions() async {
    collectCalled = true;
    return 0;
  }

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
      return s.startedAt.isAfter(start.subtract(const Duration(milliseconds: 1))) &&
          s.startedAt.isBefore(end.add(const Duration(milliseconds: 1)));
    }).toList();
  }
}

class FakeDetectionEyeRepo extends EyeMonitoringRepository {
  final List<EyeMonitoringSessionData> storedEyeSessions = [];

  FakeDetectionEyeRepo()
      : super(localRepository: EyeMonitoringLocalRepository(db: _testDb));

  @override
  Future<List<EyeMonitoringSessionData>> getSessionsBetween({
    required DateTime start,
    required DateTime end,
    String? userId,
  }) async {
    return storedEyeSessions.where((s) {
      if (userId != null && s.userId != userId && s.userId != 'local_user') {
        return false;
      }
      return s.startedAt.isAfter(start.subtract(const Duration(milliseconds: 1))) &&
          s.startedAt.isBefore(end.add(const Duration(milliseconds: 1)));
    }).toList();
  }
}

DoomscrollSessionData makeSessionData({
  required String id,
  required String userId,
  required DateTime startedAt,
  required int durationMillis,
  required int swipeCount,
  int? downwardSwipeCount,
  int? upwardSwipeCount,
  String appName = 'TikTok',
  String packageName = 'com.zhiliaoapp.musically',
  int avgInterSwipeMillis = 1500,
}) {
  final down = downwardSwipeCount ?? (swipeCount * 0.8).round();
  final up = upwardSwipeCount ?? (swipeCount - down);
  return DoomscrollSessionData(
    id: id,
    userId: userId,
    deviceId: 'test-device',
    packageName: packageName,
    appName: appName,
    startedAt: startedAt,
    endedAt: startedAt.add(Duration(milliseconds: durationMillis)),
    durationMillis: BigInt.from(durationMillis),
    swipeCount: swipeCount,
    downwardSwipeCount: down,
    upwardSwipeCount: up,
    avgInterSwipeMillis: BigInt.from(avgInterSwipeMillis),
    collectedAt: startedAt.add(Duration(milliseconds: durationMillis)),
    syncStatus: 'pending',
    syncAttempts: 0,
    createdAt: startedAt,
    updatedAt: startedAt,
  );
}

// =============================================================================
// MAIN TEST SUITE
// =============================================================================

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeDetectionUsageStatsRepo fakeUsage;
  late FakeDetectionLocalUsageRepo fakeLocalUsage;
  late FakeDetectionDoomscrollRepo fakeDoomscroll;
  late FakeDetectionEyeRepo fakeEye;
  late DetectionEngine engine;
  late DetectionService service;

  setUp(() {
    Get.reset();
    fakeUsage = FakeDetectionUsageStatsRepo();
    fakeLocalUsage = FakeDetectionLocalUsageRepo();
    fakeDoomscroll = FakeDetectionDoomscrollRepo();
    fakeEye = FakeDetectionEyeRepo();

    engine = DetectionEngine();
    service = DetectionService(
      engine: engine,
      doomscrollRepo: fakeDoomscroll,
      usageStatsRepo: fakeUsage,
      localUsageRepo: fakeLocalUsage,
      eyeRepo: fakeEye,
    );
  });

  tearDown(() {
    Get.reset();
  });

  group('Behavioral Detection Engine Unit Tests', () {
    const testUser = 'user_uuid_001';
    final testDate = DateTime(2026, 9, 30);

    test('1. Empty data: Mengembalikan detected=false dengan pesan ramah', () async {
      final result = await service.detectForDate(testDate, userId: testUser);

      expect(result.detected, isFalse);
      expect(result.type, DetectionType.none);
      expect(result.features.totalScrollingSessions, 0);
      expect(result.features.totalScrollingDurationMillis, 0);
      expect(result.evidences, isEmpty);
      expect(result.title, contains('Belum ada pola scrolling'));
    });

    test('2. Zero sessions: Ekstraksi fitur menghasilkan nilai 0 yang aman', () {
      final extractor = const DetectionFeatureExtractor();
      final features = extractor.extract(
        rawSessions: [],
        date: testDate,
        totalScreenTimeMillis: 3600000,
      );

      expect(features.hasSessions, isFalse);
      expect(features.totalScrollingSessions, 0);
      expect(features.totalScreenTimeMillis, 3600000);
      expect(features.downwardSwipeRatio, 0.0);
      expect(features.averageSessionDurationMillis, 0);
    });

    test('3. Zero swipe: Tidak terjadi error division by zero saat swipeCount=0', () {
      final session = makeSessionData(
        id: 's1',
        userId: testUser,
        startedAt: DateTime(2026, 9, 30, 10, 0),
        durationMillis: 60000,
        swipeCount: 0,
        downwardSwipeCount: 0,
        upwardSwipeCount: 0,
      );

      final extractor = const DetectionFeatureExtractor();
      final features = extractor.extract(
        rawSessions: [session],
        date: testDate,
      );

      expect(features.totalSwipeCount, 0);
      expect(features.downwardSwipeRatio, 0.0);
      expect(features.averageSwipesPerSession, 0.0);
    });

    test('4. Single short session: Sesi normal 5 menit tidak memicu deteksi', () async {
      fakeDoomscroll.storedSessions.add(
        makeSessionData(
          id: 's1',
          userId: testUser,
          startedAt: DateTime(2026, 9, 30, 10, 0),
          durationMillis: 5 * 60 * 1000, // 5 menit
          swipeCount: 40,
        ),
      );

      final result = await service.detectForDate(testDate, userId: testUser);

      expect(result.detected, isFalse);
      expect(result.type, DetectionType.none);
      expect(result.evidences, isEmpty);
    });

    test('5. Long session: Sesi >= 20 menit memicu longScrollSession', () async {
      fakeDoomscroll.storedSessions.add(
        makeSessionData(
          id: 's_long',
          userId: testUser,
          startedAt: DateTime(2026, 9, 30, 14, 0),
          durationMillis: 25 * 60 * 1000, // 25 menit (melebihi threshold 20 menit)
          swipeCount: 150,
        ),
      );

      final result = await service.detectForDate(testDate, userId: testUser);

      expect(result.detected, isTrue);
      expect(result.type, DetectionType.longScrollSession);
      expect(result.evidences.contains(DetectionEvidence.longSession), isTrue);
      expect(result.suggestedIntervention, 'Jeda Digital');
      expect(result.title, contains('panjang'));
    });

    test('6. High swipe activity: Swipe >= 300 memicu highScrollActivity', () async {
      fakeDoomscroll.storedSessions.add(
        makeSessionData(
          id: 's_high_swipe',
          userId: testUser,
          startedAt: DateTime(2026, 9, 30, 15, 0),
          durationMillis: 10 * 60 * 1000, // 10 menit
          swipeCount: 350, // Melebihi ambang batas 300
          downwardSwipeCount: 200,
          upwardSwipeCount: 150,
        ),
      );

      final result = await service.detectForDate(testDate, userId: testUser);

      expect(result.detected, isTrue);
      expect(result.evidences.contains(DetectionEvidence.highSwipeActivity), isTrue);
      expect(result.title, contains('Aktivitas scrolling meningkat'));
      expect(result.suggestedIntervention, 'Mode Fokus');
    });

    test('7. Repeated sessions: Minimal 3 sesi berurutan dengan jeda singkat memicu repeatedScrolling', () async {
      final base = DateTime(2026, 9, 30, 13, 0);

      // Sesi 1: 13:00 - 13:05
      fakeDoomscroll.storedSessions.add(
        makeSessionData(
          id: 'rep1',
          userId: testUser,
          startedAt: base,
          durationMillis: 5 * 60 * 1000,
          swipeCount: 30,
        ),
      );

      // Sesi 2: 13:10 - 13:15 (jeda 5 menit)
      fakeDoomscroll.storedSessions.add(
        makeSessionData(
          id: 'rep2',
          userId: testUser,
          startedAt: base.add(const Duration(minutes: 10)),
          durationMillis: 5 * 60 * 1000,
          swipeCount: 30,
        ),
      );

      // Sesi 3: 13:20 - 13:25 (jeda 5 menit)
      fakeDoomscroll.storedSessions.add(
        makeSessionData(
          id: 'rep3',
          userId: testUser,
          startedAt: base.add(const Duration(minutes: 20)),
          durationMillis: 5 * 60 * 1000,
          swipeCount: 30,
        ),
      );

      // Sesi 4: 13:30 - 13:35 (jeda 5 menit) -> 3 pengulangan berdekatan
      fakeDoomscroll.storedSessions.add(
        makeSessionData(
          id: 'rep4',
          userId: testUser,
          startedAt: base.add(const Duration(minutes: 30)),
          durationMillis: 5 * 60 * 1000,
          swipeCount: 30,
        ),
      );

      final result = await service.detectForDate(testDate, userId: testUser);

      expect(result.detected, isTrue);
      expect(result.features.repeatedSessionCount, greaterThanOrEqualTo(3));
      expect(result.evidences.contains(DetectionEvidence.repeatedScrolling), isTrue);
      expect(result.title, contains('berulang'));
      expect(result.suggestedIntervention, 'Jeda Digital');
    });

    test('8. Downward ratio: Rasio swipe ke bawah >= 75% teridentifikasi sebagai downwardPattern', () {
      final session = makeSessionData(
        id: 's_down',
        userId: testUser,
        startedAt: DateTime(2026, 9, 30, 11, 0),
        durationMillis: 10 * 60 * 1000,
        swipeCount: 100,
        downwardSwipeCount: 90, // 90%
        upwardSwipeCount: 10,
      );

      final extractor = const DetectionFeatureExtractor();
      final features = extractor.extract(rawSessions: [session], date: testDate);

      expect(features.downwardSwipeRatio, 0.9);

      final strategy = RuleBasedDetectionStrategy();
      final result = strategy.detect(features);

      expect(result.evidences.contains(DetectionEvidence.downwardPattern), isTrue);
    });

    test('9. Night pattern: Sesi terkonsentrasi di malam hari memicu nightScrollingPattern', () async {
      // 3 sesi di rentang malam (20:00, 21:00, 22:00)
      fakeDoomscroll.storedSessions.addAll([
        makeSessionData(
          id: 'n1',
          userId: testUser,
          startedAt: DateTime(2026, 9, 30, 20, 0),
          durationMillis: 5 * 60 * 1000,
          swipeCount: 30,
        ),
        makeSessionData(
          id: 'n2',
          userId: testUser,
          startedAt: DateTime(2026, 9, 30, 21, 30),
          durationMillis: 5 * 60 * 1000,
          swipeCount: 30,
        ),
        makeSessionData(
          id: 'n3',
          userId: testUser,
          startedAt: DateTime(2026, 9, 30, 23, 0),
          durationMillis: 5 * 60 * 1000,
          swipeCount: 30,
        ),
      ]);

      final result = await service.detectForDate(testDate, userId: testUser);

      expect(result.detected, isTrue);
      expect(result.evidences.contains(DetectionEvidence.nightPattern), isTrue);
      expect(result.title, contains('malam hari'));
      expect(result.suggestedIntervention, 'Pengingat Istirahat Malam');
    });

    test('10. Multi-signal pattern: Kombinasi sesi panjang, swipe tinggi, dan berulang memicu multiSignalScrollingPattern', () async {
      final base = DateTime(2026, 9, 30, 16, 0);

      // Sesi 1: Panjang (22 menit) + 200 swipe
      fakeDoomscroll.storedSessions.add(
        makeSessionData(
          id: 'multi1',
          userId: testUser,
          startedAt: base,
          durationMillis: 22 * 60 * 1000,
          swipeCount: 200,
        ),
      );

      // Sesi 2: Jeda 5 menit (16:27), durasi 10 menit, 150 swipe
      fakeDoomscroll.storedSessions.add(
        makeSessionData(
          id: 'multi2',
          userId: testUser,
          startedAt: base.add(const Duration(minutes: 27)),
          durationMillis: 10 * 60 * 1000,
          swipeCount: 150,
        ),
      );

      // Sesi 3: Jeda 5 menit (16:42), durasi 10 menit, 100 swipe (Total swipe = 450 > 300)
      fakeDoomscroll.storedSessions.add(
        makeSessionData(
          id: 'multi3',
          userId: testUser,
          startedAt: base.add(const Duration(minutes: 42)),
          durationMillis: 10 * 60 * 1000,
          swipeCount: 100,
        ),
      );

      final result = await service.detectForDate(testDate, userId: testUser);

      expect(result.detected, isTrue);
      expect(result.type, DetectionType.multiSignalScrollingPattern);
      expect(result.evidences.contains(DetectionEvidence.longSession), isTrue);
      expect(result.evidences.contains(DetectionEvidence.highSwipeActivity), isTrue);
      expect(result.title, contains('multi-sinyal'));
    });

    test('11. Multiple apps: Mendeteksi aplikasi-aplikasi terkait dan menentukan topScrollingApp', () {
      final sessions = [
        makeSessionData(
          id: 'app1',
          userId: testUser,
          startedAt: DateTime(2026, 9, 30, 10, 0),
          durationMillis: 500000,
          swipeCount: 50,
          appName: 'TikTok',
        ),
        makeSessionData(
          id: 'app2',
          userId: testUser,
          startedAt: DateTime(2026, 9, 30, 11, 0),
          durationMillis: 900000,
          swipeCount: 80,
          appName: 'Instagram',
        ),
        makeSessionData(
          id: 'app3',
          userId: testUser,
          startedAt: DateTime(2026, 9, 30, 12, 0),
          durationMillis: 300000,
          swipeCount: 30,
          appName: 'YouTube',
        ),
      ];

      final extractor = const DetectionFeatureExtractor();
      final features = extractor.extract(rawSessions: sessions, date: testDate);

      expect(features.involvedApps.length, 3);
      expect(features.involvedApps, containsAll(['TikTok', 'Instagram', 'YouTube']));
      expect(features.topScrollingApp, 'Instagram'); // Durasi terpanjang 900.000 ms
    });

    test('12. Date boundary: Sesi di luar tanggal tidak memengaruhi tanggal target', () async {
      // Sesi hari kemarin
      fakeDoomscroll.storedSessions.add(
        makeSessionData(
          id: 'yesterday_sess',
          userId: testUser,
          startedAt: DateTime(2026, 9, 29, 14, 0),
          durationMillis: 30 * 60 * 1000,
          swipeCount: 400,
        ),
      );

      // Hari ini tidak ada sesi
      final resultToday = await service.detectForDate(DateTime(2026, 9, 30), userId: testUser);
      expect(resultToday.detected, isFalse);
      expect(resultToday.features.totalScrollingSessions, 0);

      // Hari kemarin terdeteksi
      final resultYesterday = await service.detectForDate(DateTime(2026, 9, 29), userId: testUser);
      expect(resultYesterday.detected, isTrue);
    });

    test('13. Midnight boundary: Sesi yang melintasi pergantian hari/tengah malam tertangani', () {
      final session = makeSessionData(
        id: 'midnight_sess',
        userId: testUser,
        startedAt: DateTime(2026, 9, 30, 23, 45), // 23:45
        durationMillis: 30 * 60 * 1000, // 30 menit (berakhir 00:15 tgl 1 Okt)
        swipeCount: 150,
      );

      final extractor = const DetectionFeatureExtractor();
      final features = extractor.extract(
        rawSessions: [session],
        date: testDate,
      );

      expect(features.nightSessionCount, 1);
      expect(features.longestSessionDurationMillis, 30 * 60 * 1000);
    });

    test('14. User isolation: Sesi pengguna lain tidak pernah bocor', () async {
      fakeDoomscroll.storedSessions.add(
        makeSessionData(
          id: 'user_b_sess',
          userId: 'other_user_uuid_999',
          startedAt: DateTime(2026, 9, 30, 15, 0),
          durationMillis: 40 * 60 * 1000,
          swipeCount: 600,
        ),
      );

      final result = await service.detectForDate(testDate, userId: testUser);

      expect(result.detected, isFalse);
      expect(result.features.totalScrollingSessions, 0);
    });

    test('15. Current-day data: Deteksi hari ini memanggil flush antrean native', () async {
      expect(fakeDoomscroll.collectCalled, isFalse);

      await service.detectToday(userId: testUser);

      expect(fakeDoomscroll.collectCalled, isTrue);
    });

    test('16. Weekly detection: Mengagregasi seluruh hari dalam minggu kalender', () async {
      // Senin (28 Sep)
      fakeDoomscroll.storedSessions.add(
        makeSessionData(
          id: 'mon_sess',
          userId: testUser,
          startedAt: DateTime(2026, 9, 28, 10, 0),
          durationMillis: 15 * 60 * 1000,
          swipeCount: 200,
        ),
      );

      // Rabu (30 Sep)
      fakeDoomscroll.storedSessions.add(
        makeSessionData(
          id: 'wed_sess',
          userId: testUser,
          startedAt: DateTime(2026, 9, 30, 14, 0),
          durationMillis: 25 * 60 * 1000, // Long session
          swipeCount: 200,
        ),
      );

      final resultWeekly = await service.detectWeekly(DateTime(2026, 9, 30), userId: testUser);

      expect(resultWeekly.detected, isTrue);
      expect(resultWeekly.features.totalScrollingSessions, 2);
      expect(resultWeekly.features.totalSwipeCount, 400);
    });

    test('17. Monthly detection: Mengagregasi data dari tanggal 1 sampai akhir bulan', () async {
      fakeDoomscroll.storedSessions.add(
        makeSessionData(
          id: 'sep_1',
          userId: testUser,
          startedAt: DateTime(2026, 9, 1, 10, 0),
          durationMillis: 10 * 60 * 1000,
          swipeCount: 150,
        ),
      );
      fakeDoomscroll.storedSessions.add(
        makeSessionData(
          id: 'sep_25',
          userId: testUser,
          startedAt: DateTime(2026, 9, 25, 20, 0),
          durationMillis: 25 * 60 * 1000,
          swipeCount: 200,
        ),
      );

      final resultMonthly = await service.detectMonthly(DateTime(2026, 9, 15), userId: testUser);

      expect(resultMonthly.detected, isTrue);
      expect(resultMonthly.features.totalScrollingSessions, 2);
    });

    test('18. Eye monitoring contextual data: Penutupan mata menambahkan catatan kontekstual tanpa diagnosis', () async {
      fakeDoomscroll.storedSessions.add(
        makeSessionData(
          id: 's_eye_context',
          userId: testUser,
          startedAt: DateTime(2026, 9, 30, 21, 0),
          durationMillis: 22 * 60 * 1000,
          swipeCount: 150,
        ),
      );

      fakeEye.storedEyeSessions.add(
        EyeMonitoringSessionData(
          id: 'eye_sess_1',
          userId: testUser,
          deviceId: 'device-1',
          startedAt: DateTime(2026, 9, 30, 21, 0),
          endedAt: DateTime(2026, 9, 30, 21, 20),
          durationMillis: BigInt.from(20 * 60 * 1000),
          averageEar: 0.20,
          minEar: 0.15,
          eyeClosureEvents: 8, // Melebihi threshold penutupan mata
          blinkCount: 24,
          collectedAt: DateTime.now(),
          syncStatus: 'pending',
          syncAttempts: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final result = await service.detectForDate(testDate, userId: testUser);

      expect(result.detected, isTrue);
      expect(result.evidences.contains(DetectionEvidence.contextualEyeFatigue), isTrue);
      expect(result.contextualEyeNote, contains('indikasi mata lelah'));
      expect(result.contextualEyeNote, isNot(contains('diagnosis')));
      expect(result.contextualEyeNote, isNot(contains('karena doomscrolling')));
    });

    test('19. No false detection when insufficient data: Sesi sedikit tidak memicu alarm palsu', () async {
      fakeDoomscroll.storedSessions.add(
        makeSessionData(
          id: 's_short_1',
          userId: testUser,
          startedAt: DateTime(2026, 9, 30, 9, 0),
          durationMillis: 2 * 60 * 1000, // 2 menit
          swipeCount: 15,
        ),
      );

      final result = await service.detectForDate(testDate, userId: testUser);

      expect(result.detected, isFalse);
      expect(result.type, DetectionType.none);
    });

    test('20. Detection result serialization: toJson dan fromJson round-trip secara presisi', () {
      final session = makeSessionData(
        id: 's_ser',
        userId: testUser,
        startedAt: DateTime(2026, 9, 30, 14, 0),
        durationMillis: 25 * 60 * 1000,
        swipeCount: 200,
      );

      final extractor = const DetectionFeatureExtractor();
      final features = extractor.extract(rawSessions: [session], date: testDate);

      final originalResult = DetectionResult(
        detected: true,
        type: DetectionType.longScrollSession,
        features: features,
        evidences: const [DetectionEvidence.longSession],
        detectedAt: DateTime(2026, 9, 30, 14, 30),
        relatedApps: const ['TikTok'],
        title: 'Sesi scrolling panjang terdeteksi',
        description: 'Terdapat sesi penggunaan berkelanjutan.',
        suggestedIntervention: 'Jeda Digital',
        contextualEyeNote: 'Indikasi mata lelah tercatat.',
      );

      final json = originalResult.toJson();
      final parsed = DetectionResult.fromJson(json);

      expect(parsed.detected, originalResult.detected);
      expect(parsed.type, originalResult.type);
      expect(parsed.evidences, originalResult.evidences);
      expect(parsed.title, originalResult.title);
      expect(parsed.description, originalResult.description);
      expect(parsed.suggestedIntervention, originalResult.suggestedIntervention);
      expect(parsed.contextualEyeNote, originalResult.contextualEyeNote);
      expect(parsed.features.totalScrollingDurationMillis,
          originalResult.features.totalScrollingDurationMillis);
    });

    test('21. Configurable thresholds: Ambang batas custom mengubah titik picu deteksi', () {
      final session = makeSessionData(
        id: 's_custom',
        userId: testUser,
        startedAt: DateTime(2026, 9, 30, 10, 0),
        durationMillis: 12 * 60 * 1000, // 12 menit
        swipeCount: 100,
        downwardSwipeCount: 50, // Rasio 50% sehingga downwardPattern bernilai false
        upwardSwipeCount: 50,
      );

      final extractor = const DetectionFeatureExtractor();
      final features = extractor.extract(rawSessions: [session], date: testDate);

      // Default threshold: 20 menit -> NOT detected
      final defaultStrategy = RuleBasedDetectionStrategy();
      final resDefault = defaultStrategy.detect(features);
      expect(resDefault.detected, isFalse);

      // Custom threshold: 10 menit -> DETECTED
      final customThresholds = const DetectionThresholds(
        longSessionMillis: 10 * 60 * 1000,
      );
      final resCustom = defaultStrategy.detect(features, thresholds: customThresholds);
      expect(resCustom.detected, isTrue);
      expect(resCustom.evidences.contains(DetectionEvidence.longSession), isTrue);
    });

    test('22. InsightController integration: Memuat deteksi & menyimpan pilihan pengguna tanpa auto-aktif', () async {
      final now = DateTime.now();
      fakeDoomscroll.storedSessions.add(
        makeSessionData(
          id: 's_insight',
          userId: 'local_user',
          startedAt: DateTime(now.year, now.month, now.day, 0, 1),
          durationMillis: 25 * 60 * 1000,
          swipeCount: 150,
        ),
      );

      final controller = InsightController(detectionService: service);
      expect(controller.hasDetection, isFalse);

      await controller.loadTodayInsight();

      expect(controller.hasDetection, isTrue);
      expect(controller.detectionResult.value?.suggestedIntervention, 'Jeda Digital');

      // Pengguna memilih intervensi secara manual (User Choice)
      controller.selectIntervention('Jeda Digital');
      expect(controller.selectedIntervention.value, 'Jeda Digital');
    });
  });
}
