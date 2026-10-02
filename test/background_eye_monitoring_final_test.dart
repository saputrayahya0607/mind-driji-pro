import 'dart:async';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mind_drji/app/core/constants/eye_monitoring_constants.dart';
import 'package:mind_drji/app/core/utils/eye_condition_analyzer.dart';
import 'package:mind_drji/app/data/local/app_database.dart';
import 'package:mind_drji/app/data/local/repositories/eye_monitoring_local_repository.dart';
import 'package:mind_drji/app/data/local/tables/sync_queue.dart';
import 'package:mind_drji/app/data/models/eye_monitoring_live_event.dart';
import 'package:mind_drji/app/data/models/eye_monitoring_session_model.dart';
import 'package:mind_drji/app/data/providers/eye_monitoring_native_provider.dart';
import 'package:mind_drji/app/data/repositories/eye_monitoring_repository.dart';
import 'package:mind_drji/app/data/services/eye_monitoring_service.dart';
import 'package:mind_drji/app/data/sync/sync_manager.dart';
import 'package:mind_drji/app/modules/monitoring/controllers/eye_monitoring_controller.dart';

class MockEyeRepositoryFinal implements EyeMonitoringRepository {
  final EyeMonitoringLocalRepository? localRepo;
  MockEyeRepositoryFinal({this.localRepo});

  bool hasCameraPermission = true;
  bool hasNotificationPermission = true;
  bool isCameraRunning = false;
  bool isForegroundRunning = false;
  int startCount = 0;
  int stopCount = 0;
  int foregroundStartCount = 0;
  int foregroundStopCount = 0;

  final liveStreamController =
      StreamController<EyeMonitoringLiveEvent>.broadcast();
  final List<EyeMonitoringSessionData> storedInDb = [];
  final List<EyeMonitoringSessionModel> pendingQueue = [];

  @override
  Future<bool> checkCameraPermission() async => hasCameraPermission;

  @override
  Future<bool> requestCameraPermission() async => hasCameraPermission;

  @override
  Future<bool> checkNotificationPermission() async =>
      hasNotificationPermission;

  @override
  Future<bool> requestNotificationPermission() async =>
      hasNotificationPermission;

  @override
  Future<bool> startMonitoring() async {
    startCount++;
    isCameraRunning = true;
    return true;
  }

  @override
  Future<EyeMonitoringSessionModel?> stopMonitoringAndPersist() async {
    stopCount++;
    isCameraRunning = false;
    final session = EyeMonitoringSessionModel(
      id: 'final-sess-$stopCount',
      userId: 'auth-user-uuid-123',
      deviceId: 'persistent-device-uuid-abc',
      startedAt: DateTime.now().subtract(const Duration(seconds: 60)),
      endedAt: DateTime.now(),
      durationMillis: 60000,
      averageEar: 0.28,
      minEar: 0.16,
      eyeClosureEvents: 2,
      blinkCount: 14,
      collectedAt: DateTime.now(),
    );

    if (localRepo != null) {
      await localRepo!.insertSession(session);
    }
    return session;
  }

  @override
  Future<bool> startForegroundMonitoring({
    Duration? interval,
    Duration? sessionDuration,
    String? userId,
    String? deviceId,
    bool runImmediate = true,
  }) async {
    foregroundStartCount++;
    isForegroundRunning = true;
    return true;
  }

  @override
  Future<bool> stopForegroundMonitoring() async {
    foregroundStopCount++;
    isForegroundRunning = false;
    return true;
  }

  @override
  Future<bool> isForegroundServiceRunning() async => isForegroundRunning;

  @override
  Future<List<EyeMonitoringSessionModel>> flushPendingSessions() async {
    final list = List<EyeMonitoringSessionModel>.from(pendingQueue);
    pendingQueue.clear();
    for (final s in list) {
      if (localRepo != null) {
        await localRepo!.insertSession(s);
      }
    }
    return list;
  }

  @override
  Future<bool> getStatus() async => isCameraRunning;

  @override
  Future<List<EyeMonitoringSessionData>> getStoredSessions({int limit = 50}) async {
    return localRepo?.getSessions(limit: limit) ?? [];
  }

  @override
  Future<void> claimLocalSessions(String userId) async {}

  @override
  Stream<EyeMonitoringLiveEvent> liveEventStream() =>
      liveStreamController.stream;

  @override
  EyeMonitoringNativeProvider get provider => EyeMonitoringNativeProvider();

  @override
  EyeMonitoringLocalRepository get localRepository =>
      localRepo ?? EyeMonitoringLocalRepository();

  @override
  Future<List<EyeMonitoringSessionData>> getSessionsBetween({
    required DateTime start,
    required DateTime end,
    String? userId,
  }) async {
    return localRepo?.getSessionsBetween(start: start, end: end, userId: userId) ?? [];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late EyeMonitoringLocalRepository localRepo;
  late MockEyeRepositoryFinal mockRepo;
  late SyncManager syncMgr;

  setUp(() {
    Get.reset();
    db = AppDatabase(NativeDatabase.memory());
    localRepo = EyeMonitoringLocalRepository(db: db);
    mockRepo = MockEyeRepositoryFinal(localRepo: localRepo);
    syncMgr = SyncManager(autoStart: false);
  });

  tearDown(() async {
    mockRepo.liveStreamController.close();
    await db.close();
    Get.reset();
  });

  group('24 Specification Tests: Background Eye Monitoring Mind Driji', () {
    // 1. monitoring enable
    test('1. Monitoring enable: user consent mengaktifkan service dan status', () async {
      final service = EyeMonitoringService(
        repository: mockRepo,
        localRepository: localRepo,
        syncManager: syncMgr,
        db: db,
        autoStart: false,
      );

      final result = await service.enableMonitoring();
      expect(result, isTrue);
      expect(service.isMonitoringEnabled.value, isTrue);
      expect(service.statusMessage.value, anyOf(contains('Monitoring Aktif'), contains('Sedang Memantau')));
      expect(mockRepo.isForegroundRunning, isTrue);
    });

    // 2. monitoring disable
    test('2. Monitoring disable: mematikan service dan status menjadi belum aktif', () async {
      final service = EyeMonitoringService(
        repository: mockRepo,
        localRepository: localRepo,
        syncManager: syncMgr,
        db: db,
        autoStart: false,
      );

      await service.enableMonitoring();
      await service.disableMonitoring();

      expect(service.isMonitoringEnabled.value, isFalse);
      expect(service.statusMessage.value, 'Monitoring belum aktif');
      expect(mockRepo.isForegroundRunning, isFalse);
    });

    // 3. persistent state
    test('3. Persistent state: monitoringEnabled tersimpan di Drift SQLite', () async {
      final service = EyeMonitoringService(
        repository: mockRepo,
        localRepository: localRepo,
        syncManager: syncMgr,
        db: db,
        autoStart: false,
      );

      await service.enableMonitoring();
      final config = await (db.select(db.eyeMonitoringConfig)..limit(1)).getSingleOrNull();
      expect(config, isNotNull);
      expect(config!.monitoringEnabled, isTrue);

      await service.disableMonitoring();
      final updated = await (db.select(db.eyeMonitoringConfig)..limit(1)).getSingleOrNull();
      expect(updated!.monitoringEnabled, isFalse);
    });

    // 4. scheduler
    test('4. Scheduler: scheduler berjalan dan menghitung jadwal berikutnya', () async {
      final service = EyeMonitoringService(
        repository: mockRepo,
        localRepository: localRepo,
        syncManager: syncMgr,
        db: db,
        autoStart: false,
      );

      await service.enableMonitoring();
      expect(service.isSchedulerActive, isTrue);
      expect(service.nextScheduledAt.value, isNotNull);
    });

    // 5. duplicate scheduler
    test('5. Duplicate scheduler: pemanggilan enable berulang kali tidak membuat duplicate scheduler', () async {
      final service = EyeMonitoringService(
        repository: mockRepo,
        localRepository: localRepo,
        syncManager: syncMgr,
        db: db,
        autoStart: false,
      );

      await service.enableMonitoring();
      await service.enableMonitoring();
      await service.enableMonitoring();

      expect(service.isSchedulerActive, isTrue);
      expect(mockRepo.startCount, 1);
    });

    // 6. duplicate session
    test('6. Duplicate session: tidak memicu kamera dua kali bersamaan', () async {
      final service = EyeMonitoringService(
        repository: mockRepo,
        localRepository: localRepo,
        syncManager: syncMgr,
        db: db,
        autoStart: false,
      );

      await service.enableMonitoring();
      expect(service.isSessionRunning.value, isTrue);

      await service.triggerImmediateSession();
      expect(mockRepo.startCount, 1);
    });

    // 7. interval
    test('7. Interval: default 30 menit dan dapat disesuaikan untuk testing', () async {
      final service = EyeMonitoringService(
        repository: mockRepo,
        localRepository: localRepo,
        syncManager: syncMgr,
        db: db,
        autoStart: false,
      );

      expect(service.monitoringInterval, EyeMonitoringConstants.defaultMonitoringInterval);
      expect(service.monitoringInterval, const Duration(minutes: 30));

      service.setTestingIntervals(monitoringInterval: EyeMonitoringConstants.testMonitoringInterval);
      expect(service.monitoringInterval, const Duration(seconds: 10));
    });

    // 8. session duration
    test('8. Session duration: default 1 menit dan dapat disesuaikan untuk testing', () async {
      final service = EyeMonitoringService(
        repository: mockRepo,
        localRepository: localRepo,
        syncManager: syncMgr,
        db: db,
        autoStart: false,
      );

      expect(service.sessionDuration, EyeMonitoringConstants.defaultSessionDuration);
      expect(service.sessionDuration, const Duration(minutes: 1));

      service.setTestingIntervals(sessionDuration: EyeMonitoringConstants.testSessionDuration);
      expect(service.sessionDuration, const Duration(seconds: 10));
    });

    // 9. stop total
    test('9. Stop total: user matikan monitoring menghentikan kamera dan scheduler', () async {
      final service = EyeMonitoringService(
        repository: mockRepo,
        localRepository: localRepo,
        syncManager: syncMgr,
        db: db,
        autoStart: false,
      );

      await service.enableMonitoring();
      expect(service.isSessionRunning.value, isTrue);

      await service.disableMonitoring();
      expect(service.isSessionRunning.value, isFalse);
      expect(service.isMonitoringEnabled.value, isFalse);
      expect(service.isSchedulerActive, isFalse);
      expect(mockRepo.isCameraRunning, isFalse);
      expect(mockRepo.isForegroundRunning, isFalse);
    });

    // 10. app restart
    test('10. App restart: jika sebelumnya enabled, pulihkan state; jika disabled, tetap OFF', () async {
      await db.into(db.eyeMonitoringConfig).insertOnConflictUpdate(
        EyeMonitoringConfigCompanion.insert(
          id: 'current_config',
          monitoringEnabled: const drift.Value(true),
          lastSessionCompletedAt: drift.Value(DateTime.now().subtract(const Duration(minutes: 10))),
          updatedAt: DateTime.now(),
        ),
      );

      final restartedService = EyeMonitoringService(
        repository: mockRepo,
        localRepository: localRepo,
        syncManager: syncMgr,
        db: db,
        autoStart: false,
      );

      await restartedService.initService();
      expect(restartedService.isMonitoringEnabled.value, isTrue);
      expect(restartedService.isSchedulerActive, isTrue);
    });

    // 11. navigation
    test('11. Navigation: dispose controller tidak menghentikan background service', () async {
      final service = EyeMonitoringService(
        repository: mockRepo,
        localRepository: localRepo,
        syncManager: syncMgr,
        db: db,
        autoStart: false,
      );
      Get.put<EyeMonitoringService>(service, permanent: true);

      await service.enableMonitoring();

      final controller = EyeMonitoringController(
        repository: mockRepo,
        syncManager: syncMgr,
        service: service,
      );
      controller.onInit();
      expect(controller.isMonitoringEnabled.value, isTrue);

      // Navigasi ke halaman lain: Controller di-dispose
      controller.onClose();

      // Service harus TETAP HIDUP
      expect(service.isMonitoringEnabled.value, isTrue);
      expect(service.isSchedulerActive, isTrue);
    });

    // 12. user ID
    test('12. User ID: sesi disimpan dengan authenticated userId', () async {
      final service = EyeMonitoringService(
        repository: mockRepo,
        localRepository: localRepo,
        syncManager: syncMgr,
        db: db,
        autoStart: false,
      );

      await service.enableMonitoring();
      await service.disableMonitoring();

      final sessions = await localRepo.getSessions();
      expect(sessions.isNotEmpty, isTrue);
      expect(sessions.first.userId, 'auth-user-uuid-123');
    });

    // 13. device ID
    test('13. Device ID: sesi mencatat deviceId yang valid', () async {
      final service = EyeMonitoringService(
        repository: mockRepo,
        localRepository: localRepo,
        syncManager: syncMgr,
        db: db,
        autoStart: false,
      );

      await service.enableMonitoring();
      await service.disableMonitoring();

      final sessions = await localRepo.getSessions();
      expect(sessions.isNotEmpty, isTrue);
      expect(sessions.first.deviceId, isNotNull);
    });

    // 14. offline sync
    test('14. Offline sync: sesi tersimpan di SQLite Drift dan terdaftar di sync_queue', () async {
      final service = EyeMonitoringService(
        repository: mockRepo,
        localRepository: localRepo,
        syncManager: syncMgr,
        db: db,
        autoStart: false,
      );

      await service.enableMonitoring();
      await service.disableMonitoring();

      final sessions = await localRepo.getSessions();
      expect(sessions.isNotEmpty, isTrue);
      expect(sessions.first.syncStatus, SyncStatus.pending);

      final queue = await (db.select(db.syncQueue)..limit(1)).get();
      expect(queue.isNotEmpty, isTrue);
      expect(queue.first.entityType, SyncEntityType.eyeMonitoringSession);
    });

    // 15. service state
    test('15. Service state: observables statusMessage dan isSessionRunning akurat', () async {
      final service = EyeMonitoringService(
        repository: mockRepo,
        localRepository: localRepo,
        syncManager: syncMgr,
        db: db,
        autoStart: false,
      );

      expect(service.statusMessage.value, 'Monitoring mata belum aktif');

      await service.enableMonitoring();
      expect(service.statusMessage.value, anyOf('Sedang Memantau', 'Monitoring Aktif'));

      await service.disableMonitoring();
      expect(service.statusMessage.value, 'Monitoring belum aktif');
    });

    // 16. notification state
    test('16. Notification state: request dan check permission notifikasi (Android 13+)', () async {
      final service = EyeMonitoringService(
        repository: mockRepo,
        localRepository: localRepo,
        syncManager: syncMgr,
        db: db,
        autoStart: false,
      );

      final hasNotification = await service.checkNotificationPermission();
      expect(hasNotification, isTrue);
      expect(service.notificationPermission.value, isTrue);
    });

    // 17. background state
    test('17. Background state: saat pause, kamera in-process dilepas tapi monitoringEnabled tetap TRUE', () async {
      final service = EyeMonitoringService(
        repository: mockRepo,
        localRepository: localRepo,
        syncManager: syncMgr,
        db: db,
        autoStart: false,
      );

      await service.enableMonitoring();
      expect(service.isSessionRunning.value, isTrue);
      expect(service.isMonitoringEnabled.value, isTrue);

      service.didChangeAppLifecycleState(AppLifecycleState.paused);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(service.isSessionRunning.value, isFalse);
      expect(service.isMonitoringEnabled.value, isTrue);
    });

    // 18. permission denied
    test('18. Permission denied: jika kamera ditolak, monitoring TIDAK AKTIF', () async {
      mockRepo.hasCameraPermission = false;
      final service = EyeMonitoringService(
        repository: mockRepo,
        localRepository: localRepo,
        syncManager: syncMgr,
        db: db,
        autoStart: false,
      );

      final success = await service.enableMonitoring();
      expect(success, isFalse);
      expect(service.isMonitoringEnabled.value, isFalse);
      expect(service.errorMessage.value, contains('Izin kamera diperlukan'));
    });

    // 19. logout
    test('19. Logout: service dimatikan total saat user logout', () async {
      final service = EyeMonitoringService(
        repository: mockRepo,
        localRepository: localRepo,
        syncManager: syncMgr,
        db: db,
        autoStart: false,
      );

      await service.enableMonitoring();
      expect(service.isMonitoringEnabled.value, isTrue);

      // Simulasikan aksi disable monitoring via logout flow
      await service.disableMonitoring();
      expect(service.isMonitoringEnabled.value, isFalse);
      expect(service.isSchedulerActive, isFalse);
      expect(mockRepo.isForegroundRunning, isFalse);
    });

    // 20. re-enable
    test('20. Re-enable: monitoring dapat diaktifkan kembali setelah dimatikan', () async {
      final service = EyeMonitoringService(
        repository: mockRepo,
        localRepository: localRepo,
        syncManager: syncMgr,
        db: db,
        autoStart: false,
      );

      await service.enableMonitoring();
      expect(service.isMonitoringEnabled.value, isTrue);

      await service.disableMonitoring();
      expect(service.isMonitoringEnabled.value, isFalse);

      await service.enableMonitoring();
      expect(service.isMonitoringEnabled.value, isTrue);
      expect(service.isSchedulerActive, isTrue);
    });

    // 21. missed session
    test('21. Missed session: tidak mengejar banyak sesi terlewat secara beruntun', () async {
      // Simulasikan sesi terakhir terjadi 3 jam yang lalu (interval 30 menit)
      await db.into(db.eyeMonitoringConfig).insertOnConflictUpdate(
        EyeMonitoringConfigCompanion.insert(
          id: 'current_config',
          monitoringEnabled: const drift.Value(true),
          lastSessionCompletedAt: drift.Value(DateTime.now().subtract(const Duration(hours: 3))),
          updatedAt: DateTime.now(),
        ),
      );

      final service = EyeMonitoringService(
        repository: mockRepo,
        localRepository: localRepo,
        syncManager: syncMgr,
        db: db,
        autoStart: false,
      );

      await service.initService();

      // Hanya mengeksekusi 1 sesi awal
      expect(mockRepo.startCount, 1);
      // Next session dijadwalkan ke depan
      expect(service.nextScheduledAt.value!.isAfter(DateTime.now()), isTrue);
    });

    // 22. notification cooldown
    test('22. Notification cooldown: membatasi frekuensi notifikasi indikasi kelelahan', () {
      final analyzer = EyeConditionAnalyzer(
        cooldownDuration: const Duration(minutes: 15),
      );

      final now = DateTime.now();
      const fatiguedResult = EyeConditionResult(
        level: EyeConditionLevel.potentialFatigue,
        title: 'Indikasi Kondisi Mata',
        message: 'Terlihat indikasi mata mulai lelah.',
        disclaimer: 'Non-medis',
        indicatesFatigueOrDrowsiness: true,
      );

      // Notifikasi pertama diizinkan
      expect(analyzer.canSendNotification(fatiguedResult, now: now), isTrue);

      // Catat bahwa notifikasi sudah dikirim
      analyzer.recordNotificationSent(now);

      // Dalam periode 5 menit (belum 15 menit), dilarang kirim (cooldown aktif)
      final fiveMinLater = now.add(const Duration(minutes: 5));
      expect(analyzer.canSendNotification(fatiguedResult, now: fiveMinLater), isFalse);

      // Setelah 16 menit, diizinkan kembali
      final sixteenMinLater = now.add(const Duration(minutes: 16));
      expect(analyzer.canSendNotification(fatiguedResult, now: sixteenMinLater), isTrue);
    });

    // 23. fatigue indication logic
    test('23. Fatigue indication logic: evaluasi pola normal vs potential fatigue vs potential drowsiness', () {
      final analyzer = EyeConditionAnalyzer();

      // Normal session
      final normalSession = EyeMonitoringSessionModel(
        id: 'sess-norm',
        userId: 'u1',
        startedAt: DateTime.now().subtract(const Duration(minutes: 1)),
        endedAt: DateTime.now(),
        durationMillis: 60000,
        averageEar: 0.28,
        minEar: 0.18,
        eyeClosureEvents: 0,
        blinkCount: 15,
        collectedAt: DateTime.now(),
      );
      final resNormal = analyzer.analyzeSession(normalSession);
      expect(resNormal.level, EyeConditionLevel.normal);
      expect(resNormal.indicatesFatigueOrDrowsiness, isFalse);

      // Potential fatigue session (closures >= 2)
      final fatigueSession = EyeMonitoringSessionModel(
        id: 'sess-fatigue',
        userId: 'u1',
        startedAt: DateTime.now().subtract(const Duration(minutes: 1)),
        endedAt: DateTime.now(),
        durationMillis: 60000,
        averageEar: 0.24,
        minEar: 0.15,
        eyeClosureEvents: 2,
        blinkCount: 12,
        collectedAt: DateTime.now(),
      );
      final resFatigue = analyzer.analyzeSession(fatigueSession);
      expect(resFatigue.level, EyeConditionLevel.potentialFatigue);
      expect(resFatigue.message, contains('indikasi mata mulai lelah'));
      expect(resFatigue.indicatesFatigueOrDrowsiness, isTrue);

      // Potential drowsiness session (closures >= 4)
      final drowsinessSession = EyeMonitoringSessionModel(
        id: 'sess-drowsy',
        userId: 'u1',
        startedAt: DateTime.now().subtract(const Duration(minutes: 1)),
        endedAt: DateTime.now(),
        durationMillis: 60000,
        averageEar: 0.19,
        minEar: 0.10,
        eyeClosureEvents: 5,
        blinkCount: 8,
        collectedAt: DateTime.now(),
      );
      final resDrowsy = analyzer.analyzeSession(drowsinessSession);
      expect(resDrowsy.level, EyeConditionLevel.potentialDrowsiness);
      expect(resDrowsy.message, contains('mungkin mulai mengantuk'));
      expect(resDrowsy.indicatesFatigueOrDrowsiness, isTrue);
    });

    // 24. no camera when monitoring OFF
    test('24. No camera when monitoring OFF: saat monitoring dimatikan, kamera tidak aktif dan tidak ada sesi yang dicatat', () async {
      final service = EyeMonitoringService(
        repository: mockRepo,
        localRepository: localRepo,
        syncManager: syncMgr,
        db: db,
        autoStart: false,
      );

      expect(service.isMonitoringEnabled.value, isFalse);
      expect(mockRepo.isCameraRunning, isFalse);
      expect(mockRepo.startCount, 0);

      final sessions = await localRepo.getSessions();
      expect(sessions.isEmpty, isTrue);
    });
  });
}
