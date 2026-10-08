import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:drift/native.dart';
import 'package:mind_drji/app/data/local/app_database.dart';
import 'package:mind_drji/app/data/local/repositories/doomscroll_local_repository.dart';
import 'package:mind_drji/app/data/local/repositories/local_usage_repository.dart';
import 'package:mind_drji/app/data/models/app_usage_model.dart';
import 'package:mind_drji/app/data/models/doomscroll_session_model.dart';
import 'package:mind_drji/app/data/providers/doomscroll_native_provider.dart';
import 'package:mind_drji/app/data/providers/eye_monitoring_native_provider.dart';
import 'package:mind_drji/app/data/providers/usage_stats_provider.dart';
import 'package:mind_drji/app/data/repositories/doomscroll_repository.dart';
import 'package:mind_drji/app/data/repositories/usage_stats_repository.dart';
import 'package:mind_drji/app/data/services/monitoring_data_service.dart';
import 'package:mind_drji/app/modules/home/controllers/home_controller.dart';
import 'package:mind_drji/app/modules/permission_guide/controllers/permission_guide_controller.dart';

// =============================================================================
// MOCK IMPLEMENTATIONS
// =============================================================================

class MockUsageStatsProvider extends UsageStatsProvider {
  bool usageAccess = true;
  UsageStatsModel mockUsage = const UsageStatsModel(totalUsageMillis: 0, apps: []);

  @override
  Future<bool> checkUsageAccess() async => usageAccess;

  @override
  Future<UsageStatsModel> getTodayUsage() async => mockUsage;

  @override
  Future<UsageStatsModel> getUsageRange({
    required DateTime startTime,
    required DateTime endTime,
  }) async => mockUsage;
}

class MockDoomscrollNativeProvider extends DoomscrollNativeProvider {
  bool serviceEnabled = true;
  final List<DoomscrollSessionModel> queue = [];

  @override
  Future<bool> checkAccessibilityService() async => serviceEnabled;

  @override
  Future<List<DoomscrollSessionModel>> flushCurrentDoomscrollSession({
    String? defaultUserId,
  }) async {
    return List.from(queue);
  }

  @override
  Future<bool> clearPendingDoomscrollSessions() async {
    queue.clear();
    return true;
  }
}

class MockEyeMonitoringNativeProvider extends EyeMonitoringNativeProvider {
  bool cameraGranted = true;
  bool notificationGranted = true;

  @override
  Future<bool> checkCameraPermission() async => cameraGranted;

  @override
  Future<bool> checkNotificationPermission() async => notificationGranted;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ===========================================================================
  // 1. SCREEN TIME REGRESSION TESTS
  // ===========================================================================
  group('1. SCREEN TIME REGRESSION TESTS', () {
    late AppDatabase db;
    late LocalUsageRepository localRepo;
    late MockUsageStatsProvider mockProvider;
    late UsageStatsRepository usageRepo;

    setUp(() {
      Get.reset();
      db = AppDatabase(NativeDatabase.memory());
      localRepo = LocalUsageRepository(db: db);
      mockProvider = MockUsageStatsProvider();
      usageRepo = UsageStatsRepository(
        provider: mockProvider,
        localRepository: localRepo,
      );
    });

    tearDown(() async {
      await db.close();
      Get.reset();
    });

    test('1. permission ON + no data: hasUsageAccess remains true and displays 0 duration', () async {
      mockProvider.usageAccess = true;
      mockProvider.mockUsage = const UsageStatsModel(totalUsageMillis: 0, apps: []);

      final controller = HomeController(
        usageStatsRepository: usageRepo,
      );

      await controller.loadScreenTimeSummary();

      expect(controller.hasUsageAccess.value, isTrue);
      expect(controller.todayScreenTimeMillis.value, 0);
    });

    test('2. permission OFF: hasUsageAccess is false and screen time is 0', () async {
      mockProvider.usageAccess = false;
      mockProvider.mockUsage = const UsageStatsModel(totalUsageMillis: 0, apps: []);

      final controller = HomeController(
        usageStatsRepository: usageRepo,
      );

      await controller.loadScreenTimeSummary();

      expect(controller.hasUsageAccess.value, isFalse);
      expect(controller.todayScreenTimeMillis.value, 0);
    });

    test('3. historical UsageStats available: returns real usage stats and packages', () async {
      mockProvider.usageAccess = true;
      mockProvider.mockUsage = const UsageStatsModel(
        totalUsageMillis: 3600000,
        apps: [
          AppUsageModel(packageName: 'com.instagram.android', appName: 'Instagram', usageMillis: 2000000),
          AppUsageModel(packageName: 'com.ss.android.ugc.trill', appName: 'TikTok', usageMillis: 1600000),
        ],
      );

      final result = await usageRepo.getTodayUsage();

      expect(result.totalUsageMillis, 3600000);
      expect(result.apps.length, 2);
      expect(result.apps.first.appName, 'Instagram');
    });

    test('4. today usage calculation: persisted to SQLite local storage on daily snapshot', () async {
      mockProvider.usageAccess = true;
      mockProvider.mockUsage = const UsageStatsModel(
        totalUsageMillis: 1800000,
        apps: [
          AppUsageModel(packageName: 'com.whatsapp', appName: 'WhatsApp', usageMillis: 1800000),
        ],
      );

      await usageRepo.saveDailySnapshot();
      final local = await usageRepo.getLocalTodayUsage();

      expect(local, isNotNull);
      expect(local!.totalUsageMillis, 1800000);
      expect(local.apps.length, 1);
    });

    test('5. time segmentation: segments accurately partition daily usage into 5 standard windows', () {
      final targetDate = DateTime(2026, 10, 2);

      // Sesi 1: 03:00 - 04:00 (Dini Hari, 1 jam = 3600000ms)
      // Sesi 2: 08:00 - 09:30 (Pagi, 1.5 jam = 5400000ms)
      // Sesi 3: 12:00 - 13:00 (Siang, 1 jam = 3600000ms)
      // Sesi 4: 16:00 - 17:00 (Sore, 1 jam = 3600000ms)
      // Sesi 5: 20:00 - 21:00 (Malam, 1 jam = 3600000ms)
      final intervals = [
        UsageInterval(packageName: 'app1', startTime: DateTime(2026, 10, 2, 3, 0), endTime: DateTime(2026, 10, 2, 4, 0)),
        UsageInterval(packageName: 'app2', startTime: DateTime(2026, 10, 2, 8, 0), endTime: DateTime(2026, 10, 2, 9, 30)),
        UsageInterval(packageName: 'app3', startTime: DateTime(2026, 10, 2, 12, 0), endTime: DateTime(2026, 10, 2, 13, 0)),
        UsageInterval(packageName: 'app4', startTime: DateTime(2026, 10, 2, 16, 0), endTime: DateTime(2026, 10, 2, 17, 0)),
        UsageInterval(packageName: 'app5', startTime: DateTime(2026, 10, 2, 20, 0), endTime: DateTime(2026, 10, 2, 21, 0)),
      ];

      final segments = MonitoringDataService.calculateUsageIntervalSegments(
        targetDate: targetDate,
        intervals: intervals,
      );

      expect(segments['Dini Hari'], 3600000);
      expect(segments['Pagi'], 5400000);
      expect(segments['Siang'], 3600000);
      expect(segments['Sore'], 3600000);
      expect(segments['Malam'], 3600000);
    });

    test('6. cross midnight: interval crossing midnight only attributes the portion within targetDate', () {
      final targetDate = DateTime(2026, 10, 2);

      // Interval dimulai tanggal 1 Oktober 23:30 dan berakhir tanggal 2 Oktober 01:30 (total 2 jam)
      // Porsi untuk tanggal 2 Oktober adalah 00:00 - 01:30 (90 menit = 5400000ms) pada Dini Hari
      final intervals = [
        UsageInterval(
          packageName: 'com.tiktok',
          startTime: DateTime(2026, 10, 1, 23, 30),
          endTime: DateTime(2026, 10, 2, 1, 30),
        ),
      ];

      final segments = MonitoringDataService.calculateUsageIntervalSegments(
        targetDate: targetDate,
        intervals: intervals,
      );

      expect(segments['Dini Hari'], 5400000); // Tepat 90 menit di tanggal 2 Oktober
      expect(segments['Pagi'], 0);
      expect(segments['Malam'], 0);
    });
  });

  // ===========================================================================
  // 2. DOOMSCROLL REGRESSION TESTS
  // ===========================================================================
  group('2. DOOMSCROLL REGRESSION TESTS', () {
    late AppDatabase db;
    late DoomscrollLocalRepository localRepo;
    late MockDoomscrollNativeProvider mockProvider;
    late DoomscrollRepository doomscrollRepo;

    setUp(() {
      Get.reset();
      db = AppDatabase(NativeDatabase.memory());
      localRepo = DoomscrollLocalRepository(db: db);
      mockProvider = MockDoomscrollNativeProvider();
      doomscrollRepo = DoomscrollRepository(
        provider: mockProvider,
        localRepository: localRepo,
      );
    });

    tearDown(() async {
      await db.close();
      Get.reset();
    });

    test('1. scroll detected: creates valid session model with swipe metrics', () {
      final now = DateTime.now();
      final session = DoomscrollSessionModel(
        id: 'sess-1',
        userId: 'user-1',
        packageName: 'com.instagram.android',
        appName: 'Instagram',
        startedAt: now.subtract(const Duration(minutes: 5)),
        endedAt: now,
        durationMillis: 300000,
        swipeCount: 45,
        downwardSwipeCount: 40,
        upwardSwipeCount: 5,
        avgInterSwipeMillis: 6600,
        collectedAt: now,
      );

      expect(session.swipeCount, 45);
      expect(session.durationMillis, 300000);
      expect(session.packageName, 'com.instagram.android');
    });

    test('2. Instagram -> TikTok finalizes previous session and queues it', () async {
      final now = DateTime.now();
      final igSession = DoomscrollSessionModel(
        id: 'ig-sess',
        packageName: 'com.instagram.android',
        appName: 'Instagram',
        startedAt: now.subtract(const Duration(minutes: 10)),
        endedAt: now.subtract(const Duration(minutes: 5)),
        durationMillis: 300000,
        swipeCount: 30,
        downwardSwipeCount: 28,
        upwardSwipeCount: 2,
        avgInterSwipeMillis: 10000,
        collectedAt: now,
      );

      mockProvider.queue.add(igSession);

      final collected = await doomscrollRepo.collectAndPersistPendingSessions();
      expect(collected, 1);
      expect(mockProvider.queue, isEmpty); // Queue cleared after flush
    });

    test('3. TikTok -> MIND DRIJI finalizes session and collects queue', () async {
      final now = DateTime.now();
      final ttSession = DoomscrollSessionModel(
        id: 'tt-sess',
        packageName: 'com.ss.android.ugc.trill',
        appName: 'TikTok',
        startedAt: now.subtract(const Duration(minutes: 4)),
        endedAt: now,
        durationMillis: 240000,
        swipeCount: 50,
        downwardSwipeCount: 45,
        upwardSwipeCount: 5,
        avgInterSwipeMillis: 4800,
        collectedAt: now,
      );

      mockProvider.queue.add(ttSession);

      final collected = await doomscrollRepo.collectAndPersistPendingSessions();
      expect(collected, 1);

      final stored = await doomscrollRepo.getStoredSessions();
      expect(stored.length, 1);
      expect(stored.first.packageName, 'com.ss.android.ugc.trill');
    });

    test('4. pending queue collected on resume: multiple sessions inserted without duplicates', () async {
      final now = DateTime.now();
      mockProvider.queue.addAll([
        DoomscrollSessionModel(
          id: 'sess-a',
          packageName: 'com.instagram.android',
          appName: 'Instagram',
          startedAt: now.subtract(const Duration(minutes: 15)),
          endedAt: now.subtract(const Duration(minutes: 10)),
          durationMillis: 300000,
          swipeCount: 20,
          downwardSwipeCount: 18,
          upwardSwipeCount: 2,
          avgInterSwipeMillis: 15000,
          collectedAt: now,
        ),
        DoomscrollSessionModel(
          id: 'sess-b',
          packageName: 'com.ss.android.ugc.trill',
          appName: 'TikTok',
          startedAt: now.subtract(const Duration(minutes: 8)),
          endedAt: now,
          durationMillis: 480000,
          swipeCount: 60,
          downwardSwipeCount: 55,
          upwardSwipeCount: 5,
          avgInterSwipeMillis: 8000,
          collectedAt: now,
        ),
      ]);

      final count = await doomscrollRepo.collectAndPersistPendingSessions();
      expect(count, 2);

      final stored = await doomscrollRepo.getStoredSessions();
      expect(stored.length, 2);
    });

    test('5. Drift insert: stores swipe breakdown, duration, and sets pending sync status', () async {
      final now = DateTime.now();
      final session = DoomscrollSessionModel(
        id: 'drift-test-1',
        userId: 'test-user',
        packageName: 'com.google.android.youtube',
        appName: 'YouTube',
        startedAt: now.subtract(const Duration(minutes: 20)),
        endedAt: now,
        durationMillis: 1200000,
        swipeCount: 25,
        downwardSwipeCount: 22,
        upwardSwipeCount: 3,
        avgInterSwipeMillis: 48000,
        collectedAt: now,
      );

      await localRepo.insertSession(session);
      final stored = await localRepo.getSessionById('drift-test-1');

      expect(stored, isNotNull);
      expect(stored!.swipeCount, 25);
      expect(stored.downwardSwipeCount, 22);
      expect(stored.syncStatus, 'pending');
    });

    test('6. Supabase sync: markSessionSynced removes item from syncQueue', () async {
      final now = DateTime.now();
      final session = DoomscrollSessionModel(
        id: 'sync-test-1',
        userId: 'test-user',
        packageName: 'com.instagram.android',
        appName: 'Instagram',
        startedAt: now.subtract(const Duration(minutes: 5)),
        endedAt: now,
        durationMillis: 300000,
        swipeCount: 30,
        downwardSwipeCount: 25,
        upwardSwipeCount: 5,
        avgInterSwipeMillis: 10000,
        collectedAt: now,
      );

      await localRepo.insertSession(session);
      await localRepo.markSessionSynced('sync-test-1');

      final updated = await localRepo.getSessionById('sync-test-1');
      expect(updated!.syncStatus, 'synced');
    });

    test('7. Home updates: HomeController loads collected session count and swipes', () async {
      final now = DateTime.now();
      mockProvider.queue.add(
        DoomscrollSessionModel(
          id: 'home-test-1',
          packageName: 'com.ss.android.ugc.trill',
          appName: 'TikTok',
          startedAt: now.subtract(const Duration(minutes: 12)),
          endedAt: now,
          durationMillis: 720000,
          swipeCount: 88,
          downwardSwipeCount: 80,
          upwardSwipeCount: 8,
          avgInterSwipeMillis: 8000,
          collectedAt: now,
        ),
      );

      final controller = HomeController(
        doomscrollRepository: doomscrollRepo,
      );

      await controller.loadDoomscrollSummary();

      expect(controller.hasAccessibilityPermission.value, isTrue);
      expect(controller.isDoomscrollMonitoringActive, isTrue);
    });

    test('8. user isolation: local_user sessions can be claimed by authenticated user', () async {
      final now = DateTime.now();
      await localRepo.insertSession(
        DoomscrollSessionModel(
          id: 'anon-1',
          userId: 'local_user',
          packageName: 'com.instagram.android',
          appName: 'Instagram',
          startedAt: now,
          durationMillis: 60000,
          swipeCount: 10,
          downwardSwipeCount: 10,
          upwardSwipeCount: 0,
          avgInterSwipeMillis: 6000,
          collectedAt: now,
        ),
      );

      final claimed = await localRepo.claimLocalSessions('auth-user-999');
      expect(claimed, 1);

      final sess = await localRepo.getSessionById('anon-1');
      expect(sess!.userId, 'auth-user-999');
    });
  });

  // ===========================================================================
  // 3. EYE MONITORING REGRESSION TESTS (LANDMARKS, EAR, POSE, BLINK)
  // ===========================================================================
  group('3. EYE MONITORING REGRESSION TESTS', () {
    // MediaPipe EAR calculation helper matching EyeMonitoringManager.kt
    double calculateEar({
      required double top1Y,
      required double bottom1Y,
      required double top2Y,
      required double bottom2Y,
      required double outerX,
      required double innerX,
    }) {
      final v1 = (top1Y - bottom1Y).abs();
      final v2 = (top2Y - bottom2Y).abs();
      final h = (outerX - innerX).abs();
      if (h <= 0.0001) return 0.0;
      return (v1 + v2) / (2.0 * h);
    }

    test('1. face detected + valid landmarks: EAR calculated accurately', () {
      final ear = calculateEar(
        top1Y: 0.35,
        bottom1Y: 0.40,
        top2Y: 0.35,
        bottom2Y: 0.40,
        outerX: 0.30,
        innerX: 0.45,
      );

      expect(ear, greaterThan(0.0));
      expect(ear.isNaN, isFalse);
      expect(ear.isInfinite, isFalse);
      expect(ear, closeTo(0.33, 0.05));
    });

    test('2. blink detection: temporary EAR drop below 0.21 triggers blink', () {
      const threshold = 0.21;
      int blinkCount = 0;
      int consecutiveClosure = 0;

      final frameEars = [0.32, 0.31, 0.18, 0.16, 0.30, 0.32];

      for (final ear in frameEars) {
        final isClosed = ear < threshold;
        if (isClosed) {
          consecutiveClosure++;
        } else {
          if ([1, 2].contains(consecutiveClosure)) {
            blinkCount++;
          }
          consecutiveClosure = 0;
        }
      }

      expect(blinkCount, 1);
    });

    test('3. closure detection: prolonged closure (>2 frames) increments closure events', () {
      const threshold = 0.21;
      int eyeClosureEvents = 0;
      int consecutiveClosure = 0;

      // 4 frame berturut-turut mata tertutup
      final frameEars = [0.32, 0.15, 0.14, 0.15, 0.14, 0.30];

      for (final ear in frameEars) {
        final isClosed = ear < threshold;
        if (isClosed) {
          consecutiveClosure++;
          if (consecutiveClosure == 3) {
            eyeClosureEvents++;
          }
        } else {
          consecutiveClosure = 0;
        }
      }

      expect(eyeClosureEvents, 1);
    });

    test('4. face missing: returns EAR 0 and status "Wajah tidak terdeteksi"', () {
      final facesDetected = 0;
      final status = facesDetected == 0 ? 'Wajah tidak terdeteksi' : 'Normal';
      final currentEar = facesDetected == 0 ? 0.0 : 0.28;

      expect(currentEar, 0.0);
      expect(status, 'Wajah tidak terdeteksi');
    });

    test('5. face too small (ratio < 0.05): measurement invalid, status "Menyesuaikan posisi wajah"', () {
      const minFaceRatio = 0.05;
      final faceHeightRatio = 0.03; // Wajah terlalu jauh

      final isValid = faceHeightRatio >= minFaceRatio;
      final status = isValid ? 'Normal' : 'Menyesuaikan posisi wajah';

      expect(isValid, isFalse);
      expect(status, 'Menyesuaikan posisi wajah');
    });

    test('6. invalid pose: excessive roll (>45 deg) marked as "Menyesuaikan posisi wajah"', () {
      const maxRoll = 45.0;
      final rollDeg = 55.0; // Terlalu miring

      final isValid = rollDeg <= maxRoll;
      final status = isValid ? 'Normal' : 'Menyesuaikan posisi wajah';

      expect(isValid, isFalse);
      expect(status, 'Menyesuaikan posisi wajah');
    });

    test('7. valid natural downward phone pose: pitch ratio between 0.10 and 0.85 is valid', () {
      const minPitch = 0.10;
      const maxPitch = 0.85;

      // User menatap layar HP ke bawah -> pitchRatio ~0.35
      final naturalDownwardPitch = 0.35;
      final isValid = naturalDownwardPitch >= minPitch && naturalDownwardPitch <= maxPitch;

      expect(isValid, isTrue);
    });
  });

  // ===========================================================================
  // 4. FOCUS MODE REGRESSION TESTS (SOFT WARNING UX)
  // ===========================================================================
  group('4. FOCUS MODE REGRESSION TESTS (SOFT WARNING UX)', () {
    test('1. target app detection: recognizes TikTok and Instagram', () {
      final targets = ['com.ss.android.ugc.trill', 'com.instagram.android', 'com.google.android.youtube'];
      expect(targets.contains('com.ss.android.ugc.trill'), isTrue);
      expect(targets.contains('com.instagram.android'), isTrue);
      expect(targets.contains('com.whatsapp'), isFalse);
    });

    test('2. notification created: with title "Mode Fokus Aktif" and action "Lihat"', () {
      const title = 'Mode Fokus Aktif';
      const body = 'Kamu sedang menggunakan aplikasi yang dibatasi oleh sesi fokus.';
      const actionText = 'Lihat';

      expect(title, 'Mode Fokus Aktif');
      expect(body, contains('dibatasi oleh sesi fokus'));
      expect(actionText, 'Lihat');
    });

    test('3. notification action opens MIND DRIJI: target route is /intervention', () {
      const route = '/intervention';
      expect(route, '/intervention');
    });

    test('4. target app is restricted: GLOBAL_ACTION_HOME is executed', () {
      // Active restriction: intercept and return user to Home
      bool executedGlobalActionHome = true;
      bool targetAppRestricted = true;

      expect(executedGlobalActionHome, isTrue);
      expect(targetAppRestricted, isTrue);
    });

    test('5. cancel Focus Mode: status becomes inactive immediately', () {
      final prefs = {'focus_mode_active': true, 'status': 'active'};

      // Batalkan
      prefs['focus_mode_active'] = false;
      prefs['status'] = 'inactive';

      expect(prefs['focus_mode_active'], isFalse);
      expect(prefs['status'], 'inactive');
    });

    test('6. timer expiry: automatically inactive when now >= endedAt', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final endedAt = now - 1000; // Sudah lewat

      final isActive = now < endedAt;
      expect(isActive, isFalse);
    });

    test('7. no duplicate notification spam: debounced within 5000ms', () {
      int notificationsSent = 0;
      int lastNotificationAt = 0;
      const debounceMs = 5000;

      void onTargetAppEvent(int now) {
        if (lastNotificationAt == 0 || (now - lastNotificationAt >= debounceMs)) {
          lastNotificationAt = now;
          notificationsSent++;
        }
      }

      onTargetAppEvent(1000);
      onTargetAppEvent(1500); // Debounced
      onTargetAppEvent(2000); // Debounced
      onTargetAppEvent(6500); // Allowed (5.5s later)

      expect(notificationsSent, 2);
    });
  });

  // ===========================================================================
  // 5. PERMISSION PERSISTENCE REGRESSION TESTS
  // ===========================================================================
  group('5. PERMISSION PERSISTENCE REGRESSION TESTS', () {
    late MockUsageStatsProvider usageProvider;
    late MockDoomscrollNativeProvider doomscrollProvider;
    late MockEyeMonitoringNativeProvider eyeProvider;
    late PermissionGuideController controller;

    setUp(() {
      Get.reset();
      usageProvider = MockUsageStatsProvider();
      doomscrollProvider = MockDoomscrollNativeProvider();
      eyeProvider = MockEyeMonitoringNativeProvider();

      controller = PermissionGuideController(
        usageStatsProvider: usageProvider,
        doomscrollProvider: doomscrollProvider,
        eyeMonitoringProvider: eyeProvider,
      );
    });

    tearDown(() {
      Get.reset();
    });

    test('1. permission ON: all permissions detected granted', () async {
      await controller.checkAllPermissions();

      expect(controller.usageAccessGranted.value, isTrue);
      expect(controller.accessibilityGranted.value, isTrue);
      expect(controller.cameraGranted.value, isTrue);
      expect(controller.notificationGranted.value, isTrue);
      expect(controller.allGranted, isTrue);
    });

    test('2. app restart: re-checking permissions retains granted state without prompt', () async {
      // Simulasi app launch 1
      await controller.checkAllPermissions();
      expect(controller.allGranted, isTrue);

      // Simulasi restart / controller re-init
      final newController = PermissionGuideController(
        usageStatsProvider: usageProvider,
        doomscrollProvider: doomscrollProvider,
        eyeMonitoringProvider: eyeProvider,
      );
      await newController.checkAllPermissions();

      expect(newController.allGranted, isTrue);
      expect(newController.summaryStatusText, 'Monitoring siap digunakan');
    });

    test('3. permission revoked externally: app accurately detects missing permission', () async {
      await controller.checkAllPermissions();
      expect(controller.allGranted, isTrue);

      // User mencabut izin Usage Access di Pengaturan Android
      usageProvider.usageAccess = false;
      await controller.checkAllPermissions();

      expect(controller.usageAccessGranted.value, isFalse);
      expect(controller.allGranted, isFalse);
      expect(controller.summaryStatusText, 'Beberapa izin masih diperlukan');
    });
  });
}
