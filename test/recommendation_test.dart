import 'dart:ui';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mind_drji/app/data/local/app_database.dart';
import 'package:mind_drji/app/data/local/repositories/doomscroll_local_repository.dart';
import 'package:mind_drji/app/data/local/repositories/eye_monitoring_local_repository.dart';
import 'package:mind_drji/app/data/local/repositories/local_usage_repository.dart';
import 'package:mind_drji/app/data/models/app_usage_model.dart';
import 'package:mind_drji/app/data/models/behavioral_features.dart';
import 'package:mind_drji/app/data/models/detection_result.dart';
import 'package:mind_drji/app/data/models/insight_model.dart';
import 'package:mind_drji/app/data/models/recommendation_model.dart';
import 'package:mind_drji/app/data/repositories/doomscroll_repository.dart';
import 'package:mind_drji/app/data/repositories/eye_monitoring_repository.dart';
import 'package:mind_drji/app/data/repositories/usage_stats_repository.dart';
import 'package:mind_drji/app/data/services/detection/detection_engine.dart';
import 'package:mind_drji/app/data/services/detection_service.dart';
import 'package:mind_drji/app/data/services/insight/insight_engine.dart';
import 'package:mind_drji/app/data/services/insight_service.dart';
import 'package:mind_drji/app/data/services/monitoring_data_service.dart';
import 'package:mind_drji/app/data/services/recommendation/recommendation_engine.dart';
import 'package:mind_drji/app/data/services/recommendation_service.dart';
import 'package:mind_drji/app/modules/insight/controllers/insight_controller.dart';
import 'package:mind_drji/app/modules/insight/views/insight_view.dart';

// =============================================================================
// TEST FAKES & DATA HELPERS
// =============================================================================

late AppDatabase _testDb;

class FakeRecUsageStatsRepo extends UsageStatsRepository {
  UsageStatsModel mockUsage =
      const UsageStatsModel(totalUsageMillis: 0, apps: []);

  FakeRecUsageStatsRepo()
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

class FakeRecLocalUsageRepo extends LocalUsageRepository {
  FakeRecLocalUsageRepo() : super(db: _testDb);

  final List<ScreenTimeDailyData> screenTimes = [];
  final List<AppUsageDailyData> appUsages = [];

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

  @override
  Future<List<AppUsageDailyData>> getAppUsages(
    String userId,
    String date, {
    String? deviceId,
  }) async {
    return appUsages
        .where((a) => a.userId == userId && a.date == date)
        .toList();
  }

  @override
  Future<List<AppUsageDailyData>> getAppUsagesBetween({
    required String userId,
    required String startDate,
    required String endDate,
  }) async {
    return appUsages
        .where((a) =>
            a.userId == userId &&
            a.date.compareTo(startDate) >= 0 &&
            a.date.compareTo(endDate) <= 0)
        .toList();
  }
}

class FakeRecDoomscrollRepo extends DoomscrollRepository {
  final List<DoomscrollSessionData> storedSessions = [];

  FakeRecDoomscrollRepo()
      : super(localRepository: DoomscrollLocalRepository(db: _testDb));

  @override
  Future<int> collectAndPersistPendingSessions() async => 0;

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
      return s.startedAt
              .isAfter(start.subtract(const Duration(milliseconds: 1))) &&
          s.startedAt.isBefore(end.add(const Duration(milliseconds: 1)));
    }).toList();
  }
}

class FakeRecEyeRepo extends EyeMonitoringRepository {
  final List<EyeMonitoringSessionData> storedEyeSessions = [];

  FakeRecEyeRepo()
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
      return s.startedAt
              .isAfter(start.subtract(const Duration(milliseconds: 1))) &&
          s.startedAt.isBefore(end.add(const Duration(milliseconds: 1)));
    }).toList();
  }
}

DoomscrollSessionData createSession({
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
  final down = downwardSwipeCount ?? (swipeCount * 0.5).round();
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

  late RecommendationEngine engine;
  late FakeRecUsageStatsRepo fakeUsage;
  late FakeRecLocalUsageRepo fakeLocalUsage;
  late FakeRecDoomscrollRepo fakeDoomscroll;
  late FakeRecEyeRepo fakeEye;

  late MonitoringDataService monitoringDataService;
  late DetectionService detectionService;
  late InsightService insightService;
  late RecommendationService recommendationService;

  const testUser = 'user_uuid_rec_123';
  final testDate = DateTime(2026, 9, 30);

  setUpAll(() {
    _testDb = AppDatabase(NativeDatabase.memory());
  });

  tearDownAll(() async {
    await _testDb.close();
  });

  setUp(() {
    Get.reset();
    engine = const RecommendationEngine();

    fakeUsage = FakeRecUsageStatsRepo();
    fakeLocalUsage = FakeRecLocalUsageRepo();
    fakeDoomscroll = FakeRecDoomscrollRepo();
    fakeEye = FakeRecEyeRepo();

    monitoringDataService = MonitoringDataService(
      usageStatsRepo: fakeUsage,
      localUsageRepo: fakeLocalUsage,
      doomscrollRepo: fakeDoomscroll,
      eyeRepo: fakeEye,
    );

    detectionService = DetectionService(
      engine: DetectionEngine(),
      doomscrollRepo: fakeDoomscroll,
      usageStatsRepo: fakeUsage,
      localUsageRepo: fakeLocalUsage,
      eyeRepo: fakeEye,
    );

    insightService = InsightService(
      detectionService: detectionService,
      monitoringDataService: monitoringDataService,
      engine: const InsightEngine(),
    );

    recommendationService = RecommendationService(
      detectionService: detectionService,
      insightService: insightService,
      engine: engine,
    );
  });

  group('Recommendation Engine Unit & Integration Tests', () {
    // -------------------------------------------------------------------------
    // 1. Long session → Digital Break
    // -------------------------------------------------------------------------
    test('1. Long session → Digital Break: Menghasilkan rekomendasi Jeda Digital', () {
      final features = BehavioralFeatures(
        date: testDate,
        totalScrollingSessions: 1,
        longestSessionDurationMillis: 25 * 60 * 1000,
        totalSwipeCount: 150,
      );

      final detection = DetectionResult(
        detected: true,
        type: DetectionType.longScrollSession,
        features: features,
        evidences: const [DetectionEvidence.longSession],
        detectedAt: DateTime.now(),
        relatedApps: const ['TikTok'],
        title: 'Sesi scrolling panjang terdeteksi',
        description: 'Durasi sesi cukup lama.',
        suggestedIntervention: 'Jeda Digital',
      );

      final recs = engine.generateFromDetection(
        detection: detection,
        features: features,
      );

      expect(recs, isNotEmpty);
      expect(recs.first.type, equals(RecommendationType.digitalBreak));
      expect(recs.first.title, equals('Jeda Digital'));
      expect(recs.first.actionLabel, equals('Mulai Jeda'));
      expect(recs.first.durationOptions, equals(RecommendationDurations.digitalBreak));
    });

    // -------------------------------------------------------------------------
    // 2. High swipe → Digital Break
    // -------------------------------------------------------------------------
    test('2. High swipe → Digital Break: Menyarankan jeda untuk menyeimbangkan frekuensi navigasi', () {
      final features = BehavioralFeatures(
        date: testDate,
        totalScrollingSessions: 2,
        totalSwipeCount: 450,
      );

      final detection = DetectionResult(
        detected: true,
        type: DetectionType.highScrollActivity,
        features: features,
        evidences: const [DetectionEvidence.highSwipeActivity],
        detectedAt: DateTime.now(),
        relatedApps: const ['Instagram'],
        title: 'Aktivitas scrolling meningkat',
        description: 'Frekuensi interaksi tinggi.',
        suggestedIntervention: 'Jeda Digital',
      );

      final recs = engine.generateFromDetection(
        detection: detection,
        features: features,
      );

      expect(recs, isNotEmpty);
      expect(recs.first.type, equals(RecommendationType.digitalBreak));
      expect(recs.first.reason, contains('swipe dan scrolling terpantau meningkat'));
    });

    // -------------------------------------------------------------------------
    // 3. Repeated session → Focus Mode
    // -------------------------------------------------------------------------
    test('3. Repeated session → Focus Mode: Menghasilkan rekomendasi Mode Fokus', () {
      final features = BehavioralFeatures(
        date: testDate,
        totalScrollingSessions: 4,
        repeatedSessionCount: 3,
        averageSessionGapMillis: 5 * 60 * 1000,
      );

      final detection = DetectionResult(
        detected: true,
        type: DetectionType.repeatedScrolling,
        features: features,
        evidences: const [DetectionEvidence.repeatedScrolling],
        detectedAt: DateTime.now(),
        relatedApps: const ['TikTok'],
        title: 'Sesi scrolling berulang',
        description: 'Sesi dibuka kembali dalam jeda singkat.',
        suggestedIntervention: 'Mode Fokus',
      );

      final recs = engine.generateFromDetection(
        detection: detection,
        features: features,
      );

      expect(recs, isNotEmpty);
      final focusRec = recs.firstWhere((r) => r.type == RecommendationType.focusMode);
      expect(focusRec.title, equals('Mode Fokus'));
      expect(focusRec.actionLabel, equals('Aktifkan Fokus'));
      expect(focusRec.durationOptions, equals([15, 30, 60]));
    });

    // -------------------------------------------------------------------------
    // 4. Night pattern → Night Reminder
    // -------------------------------------------------------------------------
    test('4. Night pattern → Night Reminder: Menghasilkan rekomendasi Pengingat Malam', () {
      final features = BehavioralFeatures(
        date: testDate,
        totalScrollingSessions: 3,
        nightSessionCount: 3,
      );

      final detection = DetectionResult(
        detected: true,
        type: DetectionType.nightScrollingPattern,
        features: features,
        evidences: const [DetectionEvidence.nightPattern],
        detectedAt: DateTime.now(),
        relatedApps: const ['YouTube'],
        title: 'Aktivitas scrolling pada malam hari',
        description: 'Terkonsentrasi di malam hari.',
        suggestedIntervention: 'Pengingat Istirahat',
      );

      final recs = engine.generateFromDetection(
        detection: detection,
        features: features,
      );

      expect(recs, isNotEmpty);
      expect(recs.first.type, equals(RecommendationType.nightReminder));
      expect(recs.first.title, equals('Pengingat Malam'));
      expect(recs.first.actionLabel, equals('Atur Pengingat'));
    });

    // -------------------------------------------------------------------------
    // 5. Eye context → Eye Rest
    // -------------------------------------------------------------------------
    test('5. Eye context → Eye Rest: Parameter monitoring mata memicu Istirahat Mata', () {
      final features = BehavioralFeatures(
        date: testDate,
        totalScrollingSessions: 1,
        longestSessionDurationMillis: 22 * 60 * 1000,
      );

      final detection = DetectionResult(
        detected: true,
        type: DetectionType.longScrollSession,
        features: features,
        evidences: const [
          DetectionEvidence.longSession,
          DetectionEvidence.contextualEyeFatigue,
        ],
        detectedAt: DateTime.now(),
        relatedApps: const ['TikTok'],
        title: 'Sesi scrolling panjang terdeteksi',
        description: 'Durasi sesi cukup lama.',
        contextualEyeNote: 'Parameter monitoring menunjukkan beberapa penutupan mata.',
      );

      final recs = engine.generateFromDetection(
        detection: detection,
        features: features,
      );

      expect(recs.any((r) => r.type == RecommendationType.eyeRest), isTrue);
      final eyeRec = recs.firstWhere((r) => r.type == RecommendationType.eyeRest);
      expect(eyeRec.title, equals('Istirahat Mata'));
      expect(eyeRec.actionLabel, equals('Istirahatkan Mata'));
      expect(eyeRec.durationOptions, equals([5, 10, 20]));
    });

    // -------------------------------------------------------------------------
    // 6. Multi signal → Combined recommendation
    // -------------------------------------------------------------------------
    test('6. Multi signal → combined recommendation: Menghasilkan Jeda Digital dan Mode Fokus terpadu', () {
      final features = BehavioralFeatures(
        date: testDate,
        totalScrollingSessions: 3,
        longestSessionDurationMillis: 25 * 60 * 1000,
        totalSwipeCount: 400,
        repeatedSessionCount: 2,
      );

      final detection = DetectionResult(
        detected: true,
        type: DetectionType.multiSignalScrollingPattern,
        features: features,
        evidences: const [
          DetectionEvidence.longSession,
          DetectionEvidence.highSwipeActivity,
          DetectionEvidence.repeatedScrolling,
        ],
        detectedAt: DateTime.now(),
        relatedApps: const ['TikTok', 'Instagram'],
        title: 'Beberapa pola scrolling terdeteksi',
        description: 'Multi-sinyal simultan.',
      );

      final recs = engine.generateFromDetection(
        detection: detection,
        features: features,
      );

      expect(recs.length, greaterThanOrEqualTo(2));
      expect(recs.any((r) => r.type == RecommendationType.digitalBreak), isTrue);
      expect(recs.any((r) => r.type == RecommendationType.focusMode), isTrue);
    });

    // -------------------------------------------------------------------------
    // 7. No detection → Empty recommendation
    // -------------------------------------------------------------------------
    test('7. No detection → empty recommendation: Tidak memaksa rekomendasi jika tidak ada pola khusus', () {
      final detection = DetectionResult.none(date: testDate);
      final recs = engine.generateFromDetection(detection: detection);
      expect(recs, isEmpty);
    });

    // -------------------------------------------------------------------------
    // 8. Duplicate recommendation removed
    // -------------------------------------------------------------------------
    test('8. Duplicate recommendation removed: Dua sinyal bertipe sama tidak menghasilkan kartu dobel', () {
      final features = BehavioralFeatures(
        date: testDate,
        totalScrollingSessions: 2,
        longestSessionDurationMillis: 22 * 60 * 1000,
        totalSwipeCount: 400,
      );

      // Memiliki longSession dan highSwipeActivity (keduanya menghasilkan digitalBreak)
      final detection = DetectionResult(
        detected: true,
        type: DetectionType.longScrollSession,
        features: features,
        evidences: const [
          DetectionEvidence.longSession,
          DetectionEvidence.highSwipeActivity,
        ],
        detectedAt: DateTime.now(),
        relatedApps: const ['TikTok'],
        title: 'Sesi scrolling panjang',
        description: 'Durasi cukup lama.',
      );

      final recs = engine.generateFromDetection(
        detection: detection,
        features: features,
      );

      final breakRecs =
          recs.where((r) => r.type == RecommendationType.digitalBreak).toList();
      expect(breakRecs.length, equals(1));
    });

    // -------------------------------------------------------------------------
    // 9. Multiple evidence merged
    // -------------------------------------------------------------------------
    test('9. Multiple evidence merged: Alasan digabungkan menjadi kalimat komprehensif', () {
      final features = BehavioralFeatures(
        date: testDate,
        totalScrollingSessions: 3,
        longestSessionDurationMillis: 25 * 60 * 1000,
        totalSwipeCount: 500,
      );

      final detection = DetectionResult(
        detected: true,
        type: DetectionType.longScrollSession,
        features: features,
        evidences: const [
          DetectionEvidence.longSession,
          DetectionEvidence.highSwipeActivity,
        ],
        detectedAt: DateTime.now(),
        relatedApps: const ['TikTok'],
        title: 'Sesi scrolling panjang',
        description: 'Sesi panjang dan swipe tinggi.',
      );

      final recs = engine.generateFromDetection(
        detection: detection,
        features: features,
      );

      expect(recs.first.type, equals(RecommendationType.digitalBreak));
      expect(recs.first.reason,
          contains('sesi scrolling yang panjang dan berulang'));
    });

    // -------------------------------------------------------------------------
    // 10. Duration options
    // -------------------------------------------------------------------------
    test('10. Duration options: Nilai durasi terpusat dan konsisten sesuai konfigurasi', () {
      expect(RecommendationDurations.digitalBreak, equals([5, 15, 30]));
      expect(RecommendationDurations.focusMode, equals([15, 30, 60]));
      expect(RecommendationDurations.eyeRest, equals([5, 10, 20]));
      expect(RecommendationDurations.nightReminder, equals([15, 30, 45]));
      expect(RecommendationDurations.usageReflection, equals([5, 10, 15]));
    });

    // -------------------------------------------------------------------------
    // 11. Recommendation serialization
    // -------------------------------------------------------------------------
    test('11. Recommendation serialization: toJson dan fromJson round-trip secara presisi', () {
      final original = RecommendationModel(
        id: 'rec_test_1',
        type: RecommendationType.digitalBreak,
        title: 'Jeda Digital',
        description: 'Berikan jeda singkat.',
        reason: 'Sesi cukup lama.',
        actionLabel: 'Mulai Jeda',
        durationOptions: const [5, 15, 30],
        icon: 'spa_rounded',
        relatedDetection: DetectionType.longScrollSession,
        generatedAt: DateTime(2026, 9, 30, 10, 0),
      );

      final json = original.toJson();
      final parsed = RecommendationModel.fromJson(json);

      expect(parsed.id, equals(original.id));
      expect(parsed.type, equals(original.type));
      expect(parsed.title, equals(original.title));
      expect(parsed.durationOptions, equals(original.durationOptions));
      expect(parsed.relatedDetection, equals(original.relatedDetection));
    });

    // -------------------------------------------------------------------------
    // 12. Daily recommendation
    // -------------------------------------------------------------------------
    test('12. Daily recommendation: Menghasilkan rekomendasi terintegrasi dari deteksi & insight', () {
      final features = BehavioralFeatures(
        date: testDate,
        totalScrollingSessions: 1,
        longestSessionDurationMillis: 25 * 60 * 1000,
        totalSwipeCount: 200,
      );

      final detection = DetectionResult(
        detected: true,
        type: DetectionType.longScrollSession,
        features: features,
        evidences: const [DetectionEvidence.longSession],
        detectedAt: DateTime.now(),
        relatedApps: const ['TikTok'],
        title: 'Sesi scrolling panjang',
        description: 'Durasi cukup lama.',
      );

      final ins = InsightModel(
        id: 'ins_1',
        type: InsightType.scrolling,
        title: 'Sesi panjang',
        summary: 'Terdapat sesi lama.',
        details: '25 menit',
        evidences: const [],
        relatedApps: const ['TikTok'],
        period: 'daily',
        generatedAt: DateTime.now(),
        suggestedAction: 'Jeda Digital',
      );

      final dailyRecs = engine.generateDailyRecommendations(
        detection: detection,
        insights: [ins],
        features: features,
      );

      expect(dailyRecs, isNotEmpty);
      expect(dailyRecs.first.type, equals(RecommendationType.digitalBreak));
    });

    // -------------------------------------------------------------------------
    // 13. Weekly context
    // -------------------------------------------------------------------------
    test('13. Weekly context: Rekomendasi tetap koheren pada konteks minggu aktif', () async {
      fakeDoomscroll.storedSessions.add(
        createSession(
          id: 'w_sess_1',
          userId: testUser,
          startedAt: DateTime(2026, 9, 28, 14, 0), // Senin
          durationMillis: 25 * 60 * 1000,
          swipeCount: 300,
        ),
      );

      final recs = await recommendationService.getRecommendationsForDate(
        DateTime(2026, 9, 28),
        userId: testUser,
      );

      expect(recs, isNotEmpty);
      expect(recs.first.type, equals(RecommendationType.digitalBreak));
    });

    // -------------------------------------------------------------------------
    // 14. Monthly context
    // -------------------------------------------------------------------------
    test('14. Monthly context: Rekomendasi tertangani akurat pada konteks bulan aktif', () async {
      fakeDoomscroll.storedSessions.add(
        createSession(
          id: 'm_sess_1',
          userId: testUser,
          startedAt: DateTime(2026, 9, 15, 20, 0),
          durationMillis: 30 * 60 * 1000,
          swipeCount: 350,
        ),
      );

      final recs = await recommendationService.getRecommendationsForDate(
        DateTime(2026, 9, 15),
        userId: testUser,
      );

      expect(recs, isNotEmpty);
      expect(recs.any((r) => r.type == RecommendationType.digitalBreak), isTrue);
    });

    // -------------------------------------------------------------------------
    // 15. User isolation
    // -------------------------------------------------------------------------
    test('15. User isolation: Sesi pengguna lain tidak menghasilkan rekomendasi untuk akun aktif', () async {
      fakeDoomscroll.storedSessions.add(
        createSession(
          id: 'foreign_sess',
          userId: 'other_user_999',
          startedAt: DateTime(2026, 9, 30, 10, 0),
          durationMillis: 40 * 60 * 1000,
          swipeCount: 500,
        ),
      );

      final recs = await recommendationService.getRecommendationsForDate(
        testDate,
        userId: testUser,
      );

      expect(recs, isEmpty);
    });

    // -------------------------------------------------------------------------
    // 16. Empty data
    // -------------------------------------------------------------------------
    test('16. Empty data: Mengembalikan list kosong tanpa exception saat data nir-aktivitas', () async {
      final recs = await recommendationService.getRecommendationsForDate(
        DateTime(2026, 8, 1),
        userId: testUser,
      );
      expect(recs, isEmpty);
    });

    // -------------------------------------------------------------------------
    // 17. Date boundary
    // -------------------------------------------------------------------------
    test('17. Date boundary: Sesi di tanggal kemarin tidak mempengaruhi rekomendasi hari ini', () async {
      fakeDoomscroll.storedSessions.add(
        createSession(
          id: 'yesterday_sess',
          userId: testUser,
          startedAt: DateTime(2026, 9, 29, 15, 0),
          durationMillis: 30 * 60 * 1000,
          swipeCount: 300,
        ),
      );

      final todayRecs = await recommendationService.getRecommendationsForDate(
        DateTime(2026, 9, 30),
        userId: testUser,
      );
      expect(todayRecs, isEmpty);

      final yesterdayRecs = await recommendationService.getRecommendationsForDate(
        DateTime(2026, 9, 29),
        userId: testUser,
      );
      expect(yesterdayRecs, isNotEmpty);
    });

    // -------------------------------------------------------------------------
    // 18. Midnight boundary
    // -------------------------------------------------------------------------
    test('18. Midnight boundary: Sesi melintasi pergantian hari tertangani secara terstruktur', () async {
      fakeDoomscroll.storedSessions.add(
        createSession(
          id: 'mid_sess',
          userId: testUser,
          startedAt: DateTime(2026, 9, 30, 23, 45),
          durationMillis: 25 * 60 * 1000, // Berakhir 00:10
          swipeCount: 200,
        ),
      );

      final recs = await recommendationService.getRecommendationsForDate(
        DateTime(2026, 9, 30),
        userId: testUser,
      );

      expect(recs, isNotEmpty);
      expect(recs.first.type, equals(RecommendationType.digitalBreak));
    });

    // -------------------------------------------------------------------------
    // 19. No auto intervention
    // -------------------------------------------------------------------------
    test('19. No auto intervention: applyRecommendation mencatat pilihan tanpa auto-start blocking', () {
      final controller = InsightController(
        recommendationService: recommendationService,
      );

      final rec = RecommendationModel(
        id: 'rec_manual_1',
        type: RecommendationType.digitalBreak,
        title: 'Jeda Digital',
        description: 'Jeda 15 menit',
        reason: 'Sesi panjang',
        actionLabel: 'Mulai Jeda',
        durationOptions: const [5, 15, 30],
        icon: 'spa_rounded',
        generatedAt: DateTime.now(),
      );

      expect(controller.selectedRecommendation.value, isNull);
      expect(controller.userAppliedAction.value, isNull);

      // Pengguna mengonfirmasi pilihan secara mandiri
      controller.applyRecommendation(rec, 15);

      expect(controller.selectedRecommendation.value?.title, equals('Jeda Digital'));
      expect(controller.userAppliedAction.value, equals('Jeda Digital (15 menit)'));
    });

    // -------------------------------------------------------------------------
    // 20. Insight integration
    // -------------------------------------------------------------------------
    test('20. Insight integration: generateFromInsight memetakan suggestedAction ke RecommendationModel', () {
      final ins = InsightModel(
        id: 'ins_focus',
        type: InsightType.scrolling,
        title: 'Sesi scrolling berulang',
        summary: 'Beberapa sesi dibuka kembali.',
        details: '3 sesi berulang.',
        evidences: const [],
        relatedApps: const ['Instagram'],
        period: 'daily',
        generatedAt: DateTime.now(),
        suggestedAction: 'Mode Fokus',
      );

      final recs = engine.generateFromInsight(insight: ins);
      expect(recs, isNotEmpty);
      expect(recs.first.type, equals(RecommendationType.focusMode));
      expect(recs.first.actionLabel, equals('Aktifkan Fokus'));
    });

    // -------------------------------------------------------------------------
    // 21. Controller reactive state
    // -------------------------------------------------------------------------
    test('21. Controller reactive state: InsightController memperbarui durasi dan rekomendasi secara reaktif', () {
      final controller = InsightController(
        recommendationService: recommendationService,
      );

      final rec = RecommendationModel(
        id: 'rec_rx_1',
        type: RecommendationType.focusMode,
        title: 'Mode Fokus',
        description: 'Fokus',
        reason: 'Sesi berulang',
        actionLabel: 'Aktifkan Fokus',
        durationOptions: const [15, 30, 60],
        icon: 'center_focus_strong_rounded',
        generatedAt: DateTime.now(),
      );

      controller.recommendations.assignAll([rec]);
      expect(controller.hasRecommendations, isTrue);

      // Default duration adalah pilihan tengah (30m)
      expect(controller.getSelectedDuration(rec), equals(30));

      // Pengguna memilih 60 menit
      controller.selectRecommendationDuration(rec.id, 60);
      expect(controller.getSelectedDuration(rec), equals(60));
    });

    // -------------------------------------------------------------------------
    // 22. Widget rendering
    // -------------------------------------------------------------------------
    testWidgets('22. Widget rendering: InsightView merender section PILIHAN UNTUKMU dan chip durasi', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final now = DateTime.now();
      fakeDoomscroll.storedSessions.add(
        createSession(
          id: 'widget_sess_1',
          userId: 'local_user',
          startedAt: DateTime(now.year, now.month, now.day, 0, 1),
          durationMillis: 25 * 60 * 1000,
          swipeCount: 200,
        ),
      );

      final controller = InsightController(
        insightService: insightService,
        recommendationService: recommendationService,
      );
      Get.put<InsightController>(controller);

      await tester.pumpWidget(
        const GetMaterialApp(
          home: InsightView(),
        ),
      );

      await tester.pumpAndSettle();

      // Memeriksa tampilan bagian PILIHAN UNTUKMU
      expect(find.text('PILIHAN UNTUKMU'), findsOneWidget);
      expect(find.text('🌿 Jeda Digital'), findsOneWidget);
      expect(find.text('5 menit'), findsOneWidget);
      expect(find.text('15 menit'), findsOneWidget);
      expect(find.text('30 menit'), findsOneWidget);
      expect(find.text('Mulai Jeda'), findsOneWidget);
    });
  });
}
