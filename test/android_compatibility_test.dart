import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mind_drji/app/data/local/app_database.dart';
import 'package:mind_drji/app/data/local/repositories/doomscroll_local_repository.dart';
import 'package:mind_drji/app/data/local/repositories/eye_monitoring_local_repository.dart';
import 'package:mind_drji/app/data/local/repositories/local_usage_repository.dart';
import 'package:mind_drji/app/data/local/tables/sync_queue.dart';
import 'package:mind_drji/app/data/models/app_usage_model.dart';
import 'package:mind_drji/app/data/models/doomscroll_live_session.dart';
import 'package:mind_drji/app/data/models/doomscroll_session_model.dart';
import 'package:mind_drji/app/data/models/eye_monitoring_live_event.dart';
import 'package:mind_drji/app/data/models/eye_monitoring_session_model.dart';
import 'package:mind_drji/app/data/providers/doomscroll_native_provider.dart';
import 'package:mind_drji/app/data/providers/eye_monitoring_native_provider.dart';
import 'package:mind_drji/app/data/providers/usage_stats_provider.dart';
import 'package:mind_drji/app/data/repositories/doomscroll_repository.dart';
import 'package:mind_drji/app/data/repositories/eye_monitoring_repository.dart';
import 'package:mind_drji/app/data/repositories/usage_stats_repository.dart';
import 'package:mind_drji/app/data/sync/sync_manager.dart';
import 'package:mind_drji/app/modules/monitoring/controllers/doomscroll_controller.dart';
import 'package:mind_drji/app/modules/monitoring/controllers/eye_monitoring_controller.dart';
import 'package:mind_drji/app/modules/monitoring/controllers/screen_time_controller.dart';

// ==============================================================================
// FAKE PROVIDERS UNTUK AUDIT COMPATIBILITY
// ==============================================================================

class MockUsageStatsProvider implements UsageStatsProvider {
  bool hasAccessResult = false;
  UsageStatsModel mockUsage = const UsageStatsModel(totalUsageMillis: 0, apps: []);
  bool shouldThrow = false;

  @override
  Future<bool> checkUsageAccess() async {
    if (shouldThrow) throw Exception('AppOpsManager failure on modified ROM');
    return hasAccessResult;
  }

  @override
  Future<bool> openUsageAccessSettings() async => true;

  @override
  Future<UsageStatsModel> getTodayUsage() async {
    if (shouldThrow) throw Exception('Direct Boot storage locked');
    return mockUsage;
  }

  @override
  Future<UsageStatsModel> getUsageRange({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    if (shouldThrow) throw Exception('Direct Boot storage locked');
    return mockUsage;
  }
}

class MockDoomscrollProvider implements DoomscrollNativeProvider {
  bool isServiceActive = false;
  List<Map<String, dynamic>> pendingSessions = [];
  bool clearCalled = false;

  @override
  Future<bool> checkAccessibilityService() async => isServiceActive;

  @override
  Future<bool> openAccessibilitySettings() async => true;

  @override
  Future<List<DoomscrollSessionModel>> getPendingDoomscrollSessions({String? defaultUserId}) async {
    return pendingSessions
        .map((m) => DoomscrollSessionModel.fromMap(m, defaultUserId: defaultUserId))
        .toList();
  }

  @override
  Future<bool> clearPendingDoomscrollSessions() async {
    clearCalled = true;
    pendingSessions = [];
    return true;
  }

  @override
  Future<List<DoomscrollSessionModel>> flushCurrentDoomscrollSession({String? defaultUserId}) async {
    return pendingSessions
        .map((m) => DoomscrollSessionModel.fromMap(m, defaultUserId: defaultUserId))
        .toList();
  }

  @override
  Stream<DoomscrollLiveSession> liveSessionStream() =>
      const Stream<DoomscrollLiveSession>.empty();
}

class MockEyeMonitoringProvider implements EyeMonitoringNativeProvider {
  bool hasPermission = false;
  bool isMonitoringActive = false;
  bool cameraHardwareAvailable = true;
  Map<String, dynamic> summaryToReturn = {};

  @override
  Future<bool> checkCameraPermission() async => hasPermission;

  @override
  Future<bool> requestCameraPermission() async {
    hasPermission = true;
    return true;
  }

  @override
  Future<bool> startMonitoring() async {
    if (!cameraHardwareAvailable) {
      throw Exception('Perangkat tidak memiliki kamera depan yang kompatibel');
    }
    isMonitoringActive = true;
    return true;
  }

  @override
  Future<EyeMonitoringSessionModel?> stopMonitoring({String? defaultUserId}) async {
    isMonitoringActive = false;
    if (summaryToReturn.isEmpty) return null;
    return EyeMonitoringSessionModel.fromNativeMap(summaryToReturn, defaultUserId: defaultUserId);
  }

  @override
  Future<bool> getStatus() async => isMonitoringActive;

  @override
  Future<bool> checkNotificationPermission() async => true;

  @override
  Future<bool> requestNotificationPermission() async => true;

  @override
  Future<bool> startForegroundService({
    int? intervalMillis,
    int? sessionDurationMillis,
    String? userId,
    String? deviceId,
    bool runImmediate = true,
  }) async {
    isMonitoringActive = true;
    return true;
  }

  @override
  Future<bool> stopForegroundService() async {
    isMonitoringActive = false;
    return true;
  }

  @override
  Future<bool> isForegroundServiceRunning() async => isMonitoringActive;

  @override
  Future<List<EyeMonitoringSessionModel>> getPendingSessions({
    String? defaultUserId,
  }) async =>
      [];

  @override
  Future<bool> clearPendingSessions() async => true;

  @override
  Stream<EyeMonitoringLiveEvent> liveEventStream() =>
      const Stream<EyeMonitoringLiveEvent>.empty();
}

// ==============================================================================
// TEST SUITE: ANDROID-WIDE COMPATIBILITY
// ==============================================================================

void main() {
  late AppDatabase inMemoryDb;
  late LocalUsageRepository localUsageRepo;
  late DoomscrollLocalRepository localDoomscrollRepo;
  late EyeMonitoringLocalRepository localEyeRepo;

  setUp(() {
    Get.reset();
    inMemoryDb = AppDatabase(NativeDatabase.memory());
    localUsageRepo = LocalUsageRepository(db: inMemoryDb);
    localDoomscrollRepo = DoomscrollLocalRepository(db: inMemoryDb);
    localEyeRepo = EyeMonitoringLocalRepository(db: inMemoryDb);
  });

  tearDown(() async {
    await inMemoryDb.close();
    Get.reset();
  });

  group('1. Screen Time & UsageStats Android Compatibility Tests', () {
    testWidgets('Permission Denied flow: total screen time 0, apps list empty, no crash', (tester) async {
      final mockProvider = MockUsageStatsProvider()..hasAccessResult = false;
      final usageRepo = UsageStatsRepository(
        provider: mockProvider,
        localRepository: localUsageRepo,
      );
      final syncManager = SyncManager(
        localRepo: localUsageRepo,
        doomscrollRepo: localDoomscrollRepo,
        eyeMonitoringRepo: localEyeRepo,
        autoStart: false,
      );

      final controller = ScreenTimeController(
        repository: usageRepo,
        syncManager: syncManager,
      );

      await controller.initialCheckAndLoad();

      expect(controller.hasUsageAccess.value, isFalse);
      expect(controller.totalUsageMillis.value, 0);
      expect(controller.appUsages, isEmpty);
      expect(controller.errorMessage.value, isNull);
    });

    testWidgets('Permission Granted flow: populates real apps list and saves to Drift SQLite', (tester) async {
      final mockProvider = MockUsageStatsProvider()
        ..hasAccessResult = true
        ..mockUsage = const UsageStatsModel(
          totalUsageMillis: 7200000,
          apps: [
            AppUsageModel(
              packageName: 'com.ss.android.ugc.trill',
              appName: 'TikTok',
              usageMillis: 4500000,
            ),
            AppUsageModel(
              packageName: 'com.google.android.youtube',
              appName: 'YouTube',
              usageMillis: 2700000,
            ),
          ],
        );

      final usageRepo = UsageStatsRepository(
        provider: mockProvider,
        localRepository: localUsageRepo,
      );
      final syncManager = SyncManager(
        localRepo: localUsageRepo,
        doomscrollRepo: localDoomscrollRepo,
        eyeMonitoringRepo: localEyeRepo,
        autoStart: false,
      );

      final controller = ScreenTimeController(
        repository: usageRepo,
        syncManager: syncManager,
      );

      await controller.initialCheckAndLoad();

      expect(controller.hasUsageAccess.value, isTrue);
      expect(controller.totalUsageMillis.value, 7200000);
      expect(controller.appUsages.length, 2);
      expect(controller.appUsages.first.appName, 'TikTok');

      // Verifikasi tersimpan di Drift lokal
      final nowStr = DateTime.now().toIso8601String().substring(0, 10);
      final savedScreenTime = await localUsageRepo.getScreenTime('local_user', nowStr);
      expect(savedScreenTime, isNotNull);
      expect(savedScreenTime!.totalUsageMillis, BigInt.from(7200000));
    });

    testWidgets('Permission Revoked dynamically: resets state when app resumes', (tester) async {
      final mockProvider = MockUsageStatsProvider()..hasAccessResult = true;
      final usageRepo = UsageStatsRepository(
        provider: mockProvider,
        localRepository: localUsageRepo,
      );
      final syncManager = SyncManager(
        localRepo: localUsageRepo,
        doomscrollRepo: localDoomscrollRepo,
        eyeMonitoringRepo: localEyeRepo,
        autoStart: false,
      );

      final controller = ScreenTimeController(
        repository: usageRepo,
        syncManager: syncManager,
      );

      await controller.initialCheckAndLoad();
      expect(controller.hasUsageAccess.value, isTrue);

      // Simulasikan izin dicabut saat user di Android Settings
      mockProvider.hasAccessResult = false;
      controller.didChangeAppLifecycleState(AppLifecycleState.resumed);

      await tester.pump(const Duration(milliseconds: 50));

      expect(controller.hasUsageAccess.value, isFalse);
      expect(controller.totalUsageMillis.value, 0);
      expect(controller.appUsages, isEmpty);
    });

    testWidgets('Empty UsageStats handling: device restarted or fresh boot', (tester) async {
      final mockProvider = MockUsageStatsProvider()
        ..hasAccessResult = true
        ..mockUsage = const UsageStatsModel(totalUsageMillis: 0, apps: []);

      final usageRepo = UsageStatsRepository(
        provider: mockProvider,
        localRepository: localUsageRepo,
      );
      final syncManager = SyncManager(
        localRepo: localUsageRepo,
        doomscrollRepo: localDoomscrollRepo,
        eyeMonitoringRepo: localEyeRepo,
        autoStart: false,
      );

      final controller = ScreenTimeController(
        repository: usageRepo,
        syncManager: syncManager,
      );

      await controller.initialCheckAndLoad();

      expect(controller.hasUsageAccess.value, isTrue);
      expect(controller.totalUsageMillis.value, 0);
      expect(controller.appUsages, isEmpty);
    });

    test('Package Visibility Fallback: app info extraction fallback from package name', () {
      final rawMap = {
        'packageName': 'com.example.unlistedgame',
        'usageMillis': 120000,
      };

      final model = AppUsageModel.fromMap(rawMap);
      expect(model.packageName, 'com.example.unlistedgame');
      expect(model.appName, 'com.example.unlistedgame');
      expect(model.usageMillis, 120000);
    });
  });

  group('2. Doomscroll Accessibility Compatibility Tests', () {
    testWidgets('Accessibility Disabled flow: status false and clean prompts', (tester) async {
      final mockProvider = MockDoomscrollProvider()..isServiceActive = false;
      final doomRepo = DoomscrollRepository(
        provider: mockProvider,
        localRepository: localDoomscrollRepo,
      );
      final syncManager = SyncManager(
        localRepo: localUsageRepo,
        doomscrollRepo: localDoomscrollRepo,
        eyeMonitoringRepo: localEyeRepo,
        autoStart: false,
      );

      final controller = DoomscrollController(
        repository: doomRepo,
        syncManager: syncManager,
      );

      await controller.initialCheckAndLoad();

      expect(controller.isAccessibilityActive.value, isFalse);
      expect(controller.sessions, isEmpty);
      expect(controller.errorMessage.value, isNull);
    });

    testWidgets('Accessibility Enabled flow: collects pending sessions from native queue', (tester) async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final mockProvider = MockDoomscrollProvider()
        ..isServiceActive = true
        ..pendingSessions = [
          {
            'id': 'session-tiktok-1',
            'packageName': 'com.ss.android.ugc.trill',
            'appName': 'TikTok',
            'startedAt': now - 180000,
            'endedAt': now,
            'durationMillis': 180000,
            'swipeCount': 25,
            'downwardSwipeCount': 23,
            'upwardSwipeCount': 2,
            'avgInterSwipeMillis': 7500,
            'collectedAt': now,
          }
        ];

      final doomRepo = DoomscrollRepository(
        provider: mockProvider,
        localRepository: localDoomscrollRepo,
      );
      final syncManager = SyncManager(
        localRepo: localUsageRepo,
        doomscrollRepo: localDoomscrollRepo,
        eyeMonitoringRepo: localEyeRepo,
        autoStart: false,
      );

      final controller = DoomscrollController(
        repository: doomRepo,
        syncManager: syncManager,
      );

      await controller.initialCheckAndLoad();

      expect(controller.isAccessibilityActive.value, isTrue);
      expect(controller.sessions.length, 1);
      expect(controller.sessions.first.appName, 'TikTok');
      expect(controller.sessions.first.swipeCount, 25);
      expect(mockProvider.clearCalled, isTrue);

      // Verifikasi terdaftar di antrean sync SQLite
      final queueCount = await inMemoryDb.select(inMemoryDb.syncQueue).get();
      expect(queueCount.length, 1);
      expect(queueCount.first.entityType, SyncEntityType.doomscrollSession);
    });

    test('Target Package Matching across multiple regions and variants', () {
      final supportedPackages = [
        'com.ss.android.ugc.trill',     // TikTok SEA
        'com.zhiliaoapp.musically',     // TikTok Global
        'com.zhiliaoapp.musically.go',  // TikTok Lite
        'com.ss.android.ugc.aweme',     // Douyin / TikTok
        'com.instagram.android',        // Instagram
        'com.instagram.lite',          // Instagram Lite
        'com.google.android.youtube',   // YouTube
        'com.snapchat.android',         // Snapchat
      ];

      for (final pkg in supportedPackages) {
        final session = DoomscrollSessionModel.fromMap({
          'id': 'test-id-$pkg',
          'packageName': pkg,
          'appName': 'App $pkg',
          'startedAt': 100000,
          'endedAt': 160000,
          'durationMillis': 60000,
          'swipeCount': 10,
          'downwardSwipeCount': 8,
          'upwardSwipeCount': 2,
          'avgInterSwipeMillis': 6000,
          'collectedAt': 160000,
        });

        expect(session.packageName, pkg);
        expect(session.swipeCount, 10);
      }
    });

    testWidgets('App Switch / Lifecycle resumed triggers status and collection check', (tester) async {
      final mockProvider = MockDoomscrollProvider()..isServiceActive = true;
      final doomRepo = DoomscrollRepository(
        provider: mockProvider,
        localRepository: localDoomscrollRepo,
      );
      final syncManager = SyncManager(
        localRepo: localUsageRepo,
        doomscrollRepo: localDoomscrollRepo,
        eyeMonitoringRepo: localEyeRepo,
        autoStart: false,
      );

      final controller = DoomscrollController(
        repository: doomRepo,
        syncManager: syncManager,
      );

      await controller.initialCheckAndLoad();

      // Tambahkan sesi saat user berpindah aplikasi
      final now = DateTime.now().millisecondsSinceEpoch;
      mockProvider.pendingSessions = [
        {
          'id': 'session-switched-app',
          'packageName': 'com.instagram.android',
          'appName': 'Instagram',
          'startedAt': now - 60000,
          'endedAt': now,
          'durationMillis': 60000,
          'swipeCount': 12,
          'downwardSwipeCount': 10,
          'upwardSwipeCount': 2,
          'avgInterSwipeMillis': 5000,
          'collectedAt': now,
        }
      ];

      // Simulasi user kembali ke app (resumed)
      controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pump(const Duration(milliseconds: 50));

      expect(controller.sessions.length, 1);
      expect(controller.sessions.first.appName, 'Instagram');
    });
  });

  group('3. Eye Monitoring Capability & Lifecycle Tests', () {
    testWidgets('Camera hardware missing or front camera unavailable returns clean error', (tester) async {
      final mockProvider = MockEyeMonitoringProvider()
        ..hasPermission = true
        ..cameraHardwareAvailable = false;

      final eyeRepo = EyeMonitoringRepository(
        provider: mockProvider,
        localRepository: localEyeRepo,
      );
      final syncManager = SyncManager(
        localRepo: localUsageRepo,
        doomscrollRepo: localDoomscrollRepo,
        eyeMonitoringRepo: localEyeRepo,
        autoStart: false,
      );

      final controller = EyeMonitoringController(
        repository: eyeRepo,
        syncManager: syncManager,
      );

      await controller.initialCheck();
      await controller.startMonitoring();

      expect(controller.isMonitoring.value, isFalse);
      expect(controller.errorMessage.value, contains('tidak memiliki kamera depan'));
    });

    testWidgets('Camera permission denied flow', (tester) async {
      final mockProvider = MockEyeMonitoringProvider()..hasPermission = false;
      final eyeRepo = EyeMonitoringRepository(
        provider: mockProvider,
        localRepository: localEyeRepo,
      );
      final syncManager = SyncManager(
        localRepo: localUsageRepo,
        doomscrollRepo: localDoomscrollRepo,
        eyeMonitoringRepo: localEyeRepo,
        autoStart: false,
      );

      final controller = EyeMonitoringController(
        repository: eyeRepo,
        syncManager: syncManager,
      );

      await controller.initialCheck();
      expect(controller.cameraPermission.value, isFalse);
      expect(controller.isMonitoring.value, isFalse);
    });

    testWidgets('Lifecycle paused immediately stops monitoring and releases camera', (tester) async {
      final mockProvider = MockEyeMonitoringProvider()
        ..hasPermission = true
        ..cameraHardwareAvailable = true
        ..summaryToReturn = {
          'id': 'session-eye-paused',
          'startedAt': 1000000,
          'endedAt': 1060000,
          'durationMillis': 60000,
          'averageEar': 0.28,
          'minEar': 0.18,
          'eyeClosureEvents': 2,
          'blinkCount': 15,
          'collectedAt': 1060000,
        };

      final eyeRepo = EyeMonitoringRepository(
        provider: mockProvider,
        localRepository: localEyeRepo,
      );
      final syncManager = SyncManager(
        localRepo: localUsageRepo,
        doomscrollRepo: localDoomscrollRepo,
        eyeMonitoringRepo: localEyeRepo,
        autoStart: false,
      );

      final controller = EyeMonitoringController(
        repository: eyeRepo,
        syncManager: syncManager,
      );

      await controller.initialCheck();
      await controller.startMonitoring();
      expect(controller.isMonitoring.value, isTrue);

      // Simulasikan aplikasi masuk background (paused)
      controller.didChangeAppLifecycleState(AppLifecycleState.paused);
      await tester.pump(const Duration(milliseconds: 50));

      // Kamera harus langsung dilepas dan monitoring non-aktif
      expect(controller.isMonitoring.value, isFalse);
      expect(mockProvider.isMonitoringActive, isFalse);

      // Sesi tersimpan di Drift lokal
      final stored = await localEyeRepo.getSessions();
      expect(stored.length, 1);
      expect(stored.first.id, 'session-eye-paused');
    });
  });

  group('4. Offline-First & Sync Queue Retry Tests', () {
    test('Offline session preservation: session saved locally in Drift when offline', () async {
      final eyeSession = EyeMonitoringSessionModel(
        id: 'offline-eye-1',
        userId: 'offline_user',
        startedAt: DateTime.now().subtract(const Duration(minutes: 5)),
        endedAt: DateTime.now(),
        durationMillis: 300000,
        averageEar: 0.27,
        minEar: 0.16,
        eyeClosureEvents: 3,
        blinkCount: 42,
        collectedAt: DateTime.now(),
      );

      await localEyeRepo.insertSession(eyeSession);

      // Pastikan ada di SQLite lokal
      final localSessions = await localEyeRepo.getSessions();
      expect(localSessions.length, 1);
      expect(localSessions.first.syncStatus, 'pending');

      // Pastikan masuk ke antrean sync
      final queueItems = await inMemoryDb.select(inMemoryDb.syncQueue).get();
      expect(queueItems.length, 1);
      expect(queueItems.first.entityId, 'offline-eye-1');
      expect(queueItems.first.entityType, SyncEntityType.eyeMonitoringSession);
    });

    test('Sync retry: updateQueueRetry increments retry count without dropping session', () async {
      final eyeSession = EyeMonitoringSessionModel(
        id: 'retry-eye-1',
        userId: 'retry_user',
        startedAt: DateTime.now().subtract(const Duration(minutes: 2)),
        endedAt: DateTime.now(),
        durationMillis: 120000,
        averageEar: 0.29,
        minEar: 0.19,
        eyeClosureEvents: 1,
        blinkCount: 20,
        collectedAt: DateTime.now(),
      );

      await localEyeRepo.insertSession(eyeSession);

      final queueBefore = await inMemoryDb.select(inMemoryDb.syncQueue).get();
      final queueItem = queueBefore.first;
      expect(queueItem.retryCount, 0);

      // Simulasikan kegagalan jaringan
      await localUsageRepo.updateQueueRetry(queueItem.id, 'SocketException: Connection refused');

      final queueAfter = await inMemoryDb.select(inMemoryDb.syncQueue).get();
      expect(queueAfter.first.retryCount, 1);
      expect(queueAfter.first.lastError, contains('SocketException'));

      // Sesi lokal tetap aman dan tidak hilang
      final localSessions = await localEyeRepo.getSessions();
      expect(localSessions.length, 1);
    });
  });
}
