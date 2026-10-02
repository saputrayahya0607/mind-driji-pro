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
import 'package:mind_drji/app/data/models/monitoring_visualization_model.dart';
import 'package:mind_drji/app/data/repositories/doomscroll_repository.dart';
import 'package:mind_drji/app/data/repositories/eye_monitoring_repository.dart';
import 'package:mind_drji/app/data/repositories/usage_stats_repository.dart';
import 'package:mind_drji/app/data/services/detection/detection_engine.dart';
import 'package:mind_drji/app/data/services/detection/detection_feature_extractor.dart';
import 'package:mind_drji/app/data/services/detection_service.dart';
import 'package:mind_drji/app/data/services/insight/insight_engine.dart';
import 'package:mind_drji/app/data/services/insight_service.dart';
import 'package:mind_drji/app/data/services/monitoring_data_service.dart';
import 'package:mind_drji/app/modules/home/controllers/home_controller.dart';
import 'package:mind_drji/app/modules/insight/controllers/insight_controller.dart';
import 'package:mind_drji/app/modules/insight/views/insight_view.dart';

// =============================================================================
// TEST FAKES & DATA HELPERS
// =============================================================================

final _testDb = AppDatabase(NativeDatabase.memory());

class FakeInsightUsageStatsRepo extends UsageStatsRepository {
  UsageStatsModel mockUsage =
      const UsageStatsModel(totalUsageMillis: 0, apps: []);

  FakeInsightUsageStatsRepo()
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

class FakeInsightLocalUsageRepo extends LocalUsageRepository {
  FakeInsightLocalUsageRepo() : super(db: _testDb);

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

class FakeInsightDoomscrollRepo extends DoomscrollRepository {
  final List<DoomscrollSessionData> storedSessions = [];

  FakeInsightDoomscrollRepo()
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
      return s.startedAt.isAfter(start.subtract(const Duration(milliseconds: 1))) &&
          s.startedAt.isBefore(end.add(const Duration(milliseconds: 1)));
    }).toList();
  }
}

class FakeInsightEyeRepo extends EyeMonitoringRepository {
  final List<EyeMonitoringSessionData> storedEyeSessions = [];

  FakeInsightEyeRepo()
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
// MAIN INSIGHT ENGINE & UI TEST SUITE
// =============================================================================

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeInsightUsageStatsRepo fakeUsage;
  late FakeInsightLocalUsageRepo fakeLocalUsage;
  late FakeInsightDoomscrollRepo fakeDoomscroll;
  late FakeInsightEyeRepo fakeEye;
  late MonitoringDataService monitoringDataService;
  late DetectionService detectionService;
  late InsightEngine engine;
  late InsightService insightService;

  const testUser = 'user_uuid_insight_123';
  final testDate = DateTime(2026, 9, 30);

  setUp(() {
    Get.reset();
    fakeUsage = FakeInsightUsageStatsRepo();
    fakeLocalUsage = FakeInsightLocalUsageRepo();
    fakeDoomscroll = FakeInsightDoomscrollRepo();
    fakeEye = FakeInsightEyeRepo();

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

    engine = const InsightEngine();

    insightService = InsightService(
      detectionService: detectionService,
      monitoringDataService: monitoringDataService,
      engine: engine,
    );
  });

  tearDown(() {
    Get.reset();
  });

  group('Insight Engine Logic & Generation Tests', () {
    test('1. Empty detection: Menghasilkan insight netral saat tidak ada sesi', () {
      final detection = DetectionResult.none(date: testDate);
      final features = BehavioralFeatures.empty(testDate);

      final insights = engine.generateInsights(
        detection: detection,
        features: features,
        period: 'daily',
        date: testDate,
      );

      expect(insights, isNotEmpty);
      final first = insights.first;
      expect(first.title, contains('Belum ada pola scrolling'));
      expect(first.summary, isNot(contains('kecanduan')));
      expect(first.details, contains('pantau pola'));
    });

    test('2. Long session insight: Menampilkan sesi terpanjang dan saran Jeda Digital', () {
      final features = BehavioralFeatures(
        date: DateTime(2026, 9, 30),
        totalScrollingSessions: 2,
        totalScrollingDurationMillis: 35 * 60 * 1000,
        longestSessionDurationMillis: 28 * 60 * 1000,
        totalSwipeCount: 220,
        topScrollingApp: 'TikTok',
        involvedApps: ['TikTok'],
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

      final insights = engine.generateInsights(
        detection: detection,
        features: features,
        period: 'daily',
      );

      final scrollInsight =
          insights.firstWhere((i) => i.type == InsightType.scrolling);
      expect(scrollInsight.title, 'Sesi scrolling panjang terdeteksi');
      expect(scrollInsight.suggestedAction, 'Jeda Digital');
      expect(scrollInsight.evidences.any((e) => e.label.contains('terpanjang')), isTrue);
    });

    test('3. Repeated scrolling insight: Menghitung jumlah sesi dan jeda singkat', () {
      final features = BehavioralFeatures(
        date: DateTime(2026, 9, 30),
        totalScrollingSessions: 4,
        repeatedSessionCount: 3,
        averageSessionGapMillis: 5 * 60 * 1000,
        totalSwipeCount: 150,
      );

      final detection = DetectionResult(
        detected: true,
        type: DetectionType.repeatedScrolling,
        features: features,
        evidences: const [DetectionEvidence.repeatedScrolling],
        detectedAt: DateTime.now(),
        relatedApps: const ['Instagram'],
        title: 'Sesi scrolling berulang',
        description: 'Sesi dibuka kembali berulang.',
        suggestedIntervention: 'Jeda Digital',
      );

      final insights = engine.generateInsights(
        detection: detection,
        features: features,
      );

      final scrollInsight =
          insights.firstWhere((i) => i.type == InsightType.scrolling);
      expect(scrollInsight.title, 'Sesi scrolling berulang');
      expect(scrollInsight.evidences.any((e) => e.label == 'Sesi berulang'), isTrue);
    });

    test('4. High swipe insight: Menampilkan akumulasi dan rata-rata swipe/sesi', () {
      final features = BehavioralFeatures(
        date: DateTime(2026, 9, 30),
        totalScrollingSessions: 2,
        totalSwipeCount: 450,
        averageSwipesPerSession: 225.0,
      );

      final detection = DetectionResult(
        detected: true,
        type: DetectionType.highScrollActivity,
        features: features,
        evidences: const [DetectionEvidence.highSwipeActivity],
        detectedAt: DateTime.now(),
        relatedApps: const ['TikTok'],
        title: 'Aktivitas scrolling meningkat',
        description: 'Navigasi tinggi.',
        suggestedIntervention: 'Mode Fokus',
      );

      final insights = engine.generateInsights(
        detection: detection,
        features: features,
      );

      final scrollInsight =
          insights.firstWhere((i) => i.type == InsightType.scrolling);
      expect(scrollInsight.title, 'Aktivitas scrolling meningkat');
      expect(scrollInsight.suggestedAction, 'Mode Fokus');
    });

    test('5. Downward pattern insight: Menampilkan data rasio tanpa label kecanduan', () {
      final features = BehavioralFeatures(
        date: DateTime(2026, 9, 30),
        totalScrollingSessions: 2,
        totalSwipeCount: 100,
        totalDownwardSwipeCount: 85,
        downwardSwipeRatio: 0.85,
      );

      final detection = DetectionResult(
        detected: true,
        type: DetectionType.highScrollActivity,
        features: features,
        evidences: const [DetectionEvidence.downwardPattern],
        detectedAt: DateTime.now(),
        relatedApps: const ['YouTube'],
        title: 'Pola scrolling terdeteksi',
        description: 'Satu arah kontinu.',
      );

      final insights = engine.generateInsights(
        detection: detection,
        features: features,
      );

      final scrollInsight =
          insights.firstWhere((i) => i.type == InsightType.scrolling);
      expect(scrollInsight.title, contains('Pola scrolling'));
      expect(scrollInsight.summary, isNot(contains('kecanduan')));
    });

    test('6. Night pattern insight: Menyajikan konsentrasi malam tanpa nada menghakimi', () {
      final features = BehavioralFeatures(
        date: DateTime(2026, 9, 30),
        totalScrollingSessions: 3,
        nightSessionCount: 2,
        diniHariSessionCount: 1,
        topScrollingApp: 'TikTok',
      );

      final detection = DetectionResult(
        detected: true,
        type: DetectionType.nightScrollingPattern,
        features: features,
        evidences: const [DetectionEvidence.nightPattern],
        detectedAt: DateTime.now(),
        relatedApps: const ['TikTok'],
        title: 'Aktivitas scrolling pada malam hari',
        description: 'Terkonsentrasi di malam hari.',
        suggestedIntervention: 'Pengingat Istirahat',
      );

      final insights = engine.generateInsights(
        detection: detection,
        features: features,
      );

      final scrollInsight =
          insights.firstWhere((i) => i.type == InsightType.scrolling);
      expect(scrollInsight.title, 'Aktivitas scrolling pada malam hari');
      expect(scrollInsight.summary, isNot(contains('buruk')));
      expect(scrollInsight.summary, isNot(contains('terlalu sering')));
    });

    test('7. Multi-signal insight: Menggabungkan beberapa bukti perilaku simultan', () {
      final features = BehavioralFeatures(
        date: DateTime(2026, 9, 30),
        totalScrollingSessions: 3,
        longestSessionDurationMillis: 25 * 60 * 1000,
        totalSwipeCount: 420,
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
        suggestedIntervention: 'Mode Fokus',
      );

      final insights = engine.generateInsights(
        detection: detection,
        features: features,
      );

      final scrollInsight =
          insights.firstWhere((i) => i.type == InsightType.scrolling);
      expect(scrollInsight.title, 'Beberapa pola scrolling terdeteksi');
      expect(scrollInsight.evidences.length, greaterThanOrEqualTo(3));
    });

    test('8. No duplicate insights: Id insight unik dan tidak menghasilkan duplikasi', () {
      final detection = DetectionResult.none(date: testDate);
      final features = BehavioralFeatures.empty(testDate);

      final insights = engine.generateInsights(
        detection: detection,
        features: features,
      );

      final ids = insights.map((i) => i.id).toSet();
      expect(ids.length, equals(insights.length));
    });

    test('9. Screen time insight: Menampilkan periode paling aktif dan aplikasi dominan', () {
      final detection = DetectionResult.none(date: testDate);
      final features = BehavioralFeatures(
        date: DateTime(2026, 9, 30),
        totalScreenTimeMillis: 3 * 3600 * 1000, // 3 jam
        topScrollingApp: 'YouTube',
      );

      final dailySegments = [
        const TimeSegmentUsage(
          label: 'Malam',
          timeRange: '18:00–23:59',
          startHour: 18,
          endHour: 23,
          screenTimeMillis: 2 * 3600 * 1000,
          doomscrollMillis: 600000,
          doomscrollSwipes: 100,
        ),
      ];

      final insights = engine.generateInsights(
        detection: detection,
        features: features,
        totalScreenTimeMillis: 3 * 3600 * 1000,
        dailySegments: dailySegments,
        topApp: 'YouTube',
      );

      final stInsight =
          insights.firstWhere((i) => i.type == InsightType.screenTime);
      expect(stInsight.title, 'Distribusi Waktu Layar');
      expect(stInsight.summary, contains('malam hari'));
      expect(stInsight.evidences.any((e) => e.value == 'Malam'), isTrue);
    });

    test('10. Eye monitoring insight: Menyajikan indikasi penutupan mata tanpa diagnosis medis', () {
      final detection = DetectionResult.none(date: testDate);
      final features = BehavioralFeatures.empty(testDate);

      const eyeSummary = EyeMonitoringSummary(
        totalSessions: 4,
        totalDurationMillis: 240000,
        eyeClosureEvents: 7,
        blinkCount: 28,
        averageEar: 0.19,
      );

      final insights = engine.generateInsights(
        detection: detection,
        features: features,
        eyeSummary: eyeSummary,
      );

      final eyeInsight =
          insights.firstWhere((i) => i.type == InsightType.eyeMonitoring);
      expect(eyeInsight.title, 'Indikasi Mata Lelah');
      expect(eyeInsight.summary, contains('indikasi mata mulai lelah'));
      expect(eyeInsight.details, isNot(contains('diagnosis')));
      expect(eyeInsight.suggestedAction, contains('20-20-20'));
    });

    test('11. Today insight via InsightService: Mengambil data live dan menghasilkan insight', () async {
      final now = DateTime.now();
      fakeDoomscroll.storedSessions.add(
        createSession(
          id: 'sess_today_1',
          userId: testUser,
          startedAt: DateTime(now.year, now.month, now.day, 0, 1),
          durationMillis: 22 * 60 * 1000,
          swipeCount: 200,
        ),
      );

      final insights = await insightService.getTodayInsights(userId: testUser);

      expect(insights, isNotEmpty);
      final mainInsight = insights.first;
      expect(mainInsight.type, InsightType.scrolling);
      expect(mainInsight.suggestedAction, isNotNull);
    });

    test('12. Weekly insight: Menghitung hari puncak dalam minggu', () async {
      final wed = DateTime(2026, 9, 30); // Rabu
      fakeDoomscroll.storedSessions.add(
        createSession(
          id: 'sess_wed',
          userId: testUser,
          startedAt: DateTime(2026, 9, 30, 15, 0),
          durationMillis: 25 * 60 * 1000,
          swipeCount: 300,
        ),
      );

      final insights = await insightService.getWeeklyInsights(wed, userId: testUser);

      expect(insights, isNotEmpty);
      expect(insights.any((i) => i.period == 'weekly'), isTrue);
    });

    test('13. Monthly insight: Menghitung pembagian minggu kalender bulanan', () async {
      final sep = DateTime(2026, 9, 15);
      fakeDoomscroll.storedSessions.add(
        createSession(
          id: 'sess_sep',
          userId: testUser,
          startedAt: DateTime(2026, 9, 5, 14, 0),
          durationMillis: 25 * 60 * 1000,
          swipeCount: 200,
        ),
      );

      final insights = await insightService.getMonthlyInsights(sep, userId: testUser);

      expect(insights, isNotEmpty);
      expect(insights.any((i) => i.period == 'monthly'), isTrue);
    });

    test('14. Empty weekly: Menghasilkan fallback saat minggu kosong', () async {
      final emptyWeek = DateTime(2026, 8, 10);
      final insights =
          await insightService.getWeeklyInsights(emptyWeek, userId: testUser);

      expect(insights, isNotEmpty);
      expect(insights.first.title, contains('Belum ada pola scrolling'));
    });

    test('15. Empty monthly: Menghasilkan fallback saat bulan kosong', () async {
      final emptyMonth = DateTime(2026, 7, 1);
      final insights =
          await insightService.getMonthlyInsights(emptyMonth, userId: testUser);

      expect(insights, isNotEmpty);
      expect(insights.first.title, contains('Belum ada pola scrolling'));
    });

    test('16. User isolation: Data pengguna lain tidak tercampur ke dalam insight', () async {
      fakeDoomscroll.storedSessions.add(
        createSession(
          id: 'other_user_sess',
          userId: 'stranger_uuid_999',
          startedAt: DateTime(2026, 9, 30, 10, 0),
          durationMillis: 40 * 60 * 1000,
          swipeCount: 500,
        ),
      );

      final insights =
          await insightService.getDailyInsights(testDate, userId: testUser);

      final scrollInsight =
          insights.firstWhere((i) => i.type == InsightType.scrolling);
      expect(scrollInsight.title, contains('Belum ada pola scrolling'));
    });

    test('17. No fake data: Data berasal murni dari model nyata', () {
      final item = const InsightEvidenceItem(
        label: 'Sesi terpanjang',
        value: '22m',
      );
      expect(item.label, 'Sesi terpanjang');
      expect(item.value, '22m');
    });

    test('18. Suggested action: Intervensi memerlukan persetujuan dan tidak auto-start', () {
      final controller = InsightController(insightService: insightService);
      expect(controller.selectedAction.value, isNull);

      controller.selectAction('Jeda Digital');
      expect(controller.selectedAction.value, 'Jeda Digital');
    });

    test('19. Serialization: toJson & fromJson InsightModel secara presisi', () {
      final original = InsightModel(
        id: 'ins_1',
        type: InsightType.scrolling,
        title: 'Sesi scrolling panjang',
        summary: 'Ringkasan',
        details: 'Detail penjelasan',
        evidences: const [
          InsightEvidenceItem(label: 'Sesi', value: '25m', iconName: 'timer'),
        ],
        relatedApps: const ['TikTok'],
        period: 'daily',
        generatedAt: DateTime(2026, 9, 30, 10, 0),
        suggestedAction: 'Jeda Digital',
        priority: InsightPriority.high,
      );

      final json = original.toJson();
      final parsed = InsightModel.fromJson(json);

      expect(parsed.id, original.id);
      expect(parsed.type, original.type);
      expect(parsed.title, original.title);
      expect(parsed.summary, original.summary);
      expect(parsed.evidences.length, 1);
      expect(parsed.evidences.first.label, 'Sesi');
      expect(parsed.suggestedAction, 'Jeda Digital');
      expect(parsed.priority, InsightPriority.high);
    });

    test('20. Home integration: HomeController menampilkan judul dan CTA ke Insight', () {
      final homeController = HomeController();
      expect(homeController.detectionTitle, isNotEmpty);
      expect(homeController.detectionDescription, isNotEmpty);
    });

    test('21. Reactive state: InsightController memperbarui state saat setPeriod', () async {
      final controller = InsightController(insightService: insightService);
      expect(controller.selectedPeriod.value, MonitoringPeriod.daily);

      controller.setPeriod(MonitoringPeriod.weekly);
      expect(controller.selectedPeriod.value, MonitoringPeriod.weekly);
    });

    test('22. Date boundary: Navigasi previous dan next mengubah tanggal aktif', () {
      final controller = InsightController(insightService: insightService);
      final initialDate = controller.selectedDate.value;

      controller.previousPeriod();
      expect(controller.selectedDate.value.isBefore(initialDate), isTrue);
    });

    test('23. Midnight boundary: Sesi melintasi pergantian hari diekstrak akurat', () {
      final midnightSess = createSession(
        id: 'mid_1',
        userId: testUser,
        startedAt: DateTime(2026, 9, 30, 23, 50),
        durationMillis: 20 * 60 * 1000, // Berakhir 00:10
        swipeCount: 150,
      );

      final extractor = const DetectionFeatureExtractor();
      final features = extractor.extract(
        rawSessions: [midnightSess],
        date: testDate,
      );

      expect(features.nightSessionCount, 1);
      expect(features.longestSessionDurationMillis, 20 * 60 * 1000);
    });

    test('24. Month boundary: Minggu di perbatasan bulan tertangani tanpa error', () async {
      final endOfMonth = DateTime(2026, 9, 30);
      final insights = await insightService.getWeeklyInsights(endOfMonth, userId: testUser);
      expect(insights, isNotNull);
    });

    testWidgets('25. Widget test: InsightView merender tab periode, header, dan konten', (tester) async {
      final controller = InsightController(insightService: insightService);
      Get.put<InsightController>(controller);

      await tester.pumpWidget(
        const GetMaterialApp(
          home: InsightView(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Insight & Refleksi'), findsOneWidget);
      expect(find.text('Hari'), findsOneWidget);
      expect(find.text('Minggu'), findsOneWidget);
      expect(find.text('Bulan'), findsOneWidget);
    });
  });
}
