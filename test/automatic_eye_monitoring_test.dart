import 'dart:async';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
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

class MockEyeMonitoringRepository implements EyeMonitoringRepository {
  final EyeMonitoringLocalRepository? localRepo;
  MockEyeMonitoringRepository({this.localRepo});

  bool hasPermission = true;
  bool isCameraRunning = false;
  int startCount = 0;
  int stopCount = 0;
  final liveStreamController = StreamController<EyeMonitoringLiveEvent>.broadcast();
  final List<EyeMonitoringSessionData> storedInDb = [];

  @override
  Future<bool> checkCameraPermission() async => hasPermission;

  @override
  Future<bool> requestCameraPermission() async => hasPermission;

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
      id: 'auto-sess-$stopCount',
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

    storedInDb.add(
      EyeMonitoringSessionData(
        id: session.id,
        userId: session.userId!,
        deviceId: session.deviceId,
        startedAt: session.startedAt,
        endedAt: session.endedAt,
        durationMillis: BigInt.from(session.durationMillis),
        averageEar: session.averageEar,
        minEar: session.minEar,
        eyeClosureEvents: session.eyeClosureEvents,
        blinkCount: session.blinkCount,
        collectedAt: session.collectedAt,
        syncStatus: SyncStatus.pending,
        syncAttempts: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    if (localRepo != null) {
      await localRepo!.insertSession(session);
    }

    return session;
  }

  @override
  Future<bool> getStatus() async => isCameraRunning;

  @override
  Future<List<EyeMonitoringSessionData>> getStoredSessions({int limit = 50}) async {
    return List.from(storedInDb);
  }

  @override
  Future<bool> checkNotificationPermission() async => true;

  @override
  Future<bool> requestNotificationPermission() async => true;

  @override
  Future<bool> startForegroundMonitoring({
    Duration? interval,
    Duration? sessionDuration,
    String? userId,
    String? deviceId,
    bool runImmediate = true,
  }) async {
    return true;
  }

  @override
  Future<bool> stopForegroundMonitoring() async {
    return true;
  }

  @override
  Future<bool> isForegroundServiceRunning() async => isCameraRunning;

  @override
  Future<List<EyeMonitoringSessionModel>> flushPendingSessions() async => [];

  @override
  EyeMonitoringNativeProvider get provider => EyeMonitoringNativeProvider();

  @override
  EyeMonitoringLocalRepository get localRepository =>
      localRepo ?? EyeMonitoringLocalRepository();

  @override
  Future<void> claimLocalSessions(String userId) async {}

  @override
  Stream<EyeMonitoringLiveEvent> liveEventStream() => liveStreamController.stream;

  @override
  Future<List<EyeMonitoringSessionData>> getSessionsBetween({
    required DateTime start,
    required DateTime end,
    String? userId,
  }) async {
    return storedInDb.where((s) {
      if (userId != null && s.userId != userId) return false;
      return s.startedAt.isAfter(start.subtract(const Duration(milliseconds: 1))) &&
          s.startedAt.isBefore(end);
    }).toList();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late EyeMonitoringLocalRepository localRepo;
  late MockEyeMonitoringRepository mockRepo;
  late SyncManager syncMgr;

  setUp(() {
    Get.reset();
    db = AppDatabase(NativeDatabase.memory());
    localRepo = EyeMonitoringLocalRepository(db: db);
    mockRepo = MockEyeMonitoringRepository(localRepo: localRepo);
    syncMgr = SyncManager(autoStart: false);
  });

  tearDown(() async {
    mockRepo.liveStreamController.close();
    await db.close();
    Get.reset();
  });

  group('Automatic Periodic Eye Monitoring Specification Tests', () {
    // 1. monitoring enabled persistence
    test('1. Monitoring enabled persistence: tersimpan persistent di Drift', () async {
      final service = EyeMonitoringService(
        repository: mockRepo,
        localRepository: localRepo,
        syncManager: syncMgr,
        db: db,
        autoStart: false,
      );

      final success = await service.enableMonitoring();
      expect(success, isTrue);
      expect(service.isMonitoringEnabled.value, isTrue);

      final config = await (db.select(db.eyeMonitoringConfig)..limit(1)).getSingleOrNull();
      expect(config, isNotNull);
      expect(config!.monitoringEnabled, isTrue);
    });

    // 2. monitoring disabled persistence
    test('2. Monitoring disabled persistence: tersimpan persistent di Drift saat dimatikan', () async {
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

      final config = await (db.select(db.eyeMonitoringConfig)..limit(1)).getSingleOrNull();
      expect(config, isNotNull);
      expect(config!.monitoringEnabled, isFalse);
    });

    // 3. scheduler initialization
    test('3. Scheduler initialization: scheduler aktif saat monitoring diaktifkan', () async {
      final service = EyeMonitoringService(
        repository: mockRepo,
        localRepository: localRepo,
        syncManager: syncMgr,
        db: db,
        autoStart: false,
      );

      expect(service.isSchedulerActive, isFalse);
      await service.enableMonitoring();
      expect(service.isSchedulerActive, isTrue);
    });

    // 4. scheduler tidak duplicate
    test('4. Scheduler tidak duplicate: pemanggilan enable berulang kali tidak membuat duplicate scheduler', () async {
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
      // startCount hanya dipanggil untuk 1 sesi awal
      expect(mockRepo.startCount, 1);
    });

    // 5. session tidak duplicate
    test('5. Session tidak duplicate: kamera tidak boleh dijalankan dua kali secara bersamaan', () async {
      final service = EyeMonitoringService(
        repository: mockRepo,
        localRepository: localRepo,
        syncManager: syncMgr,
        db: db,
        autoStart: false,
      );

      await service.enableMonitoring();
      expect(service.isSessionRunning.value, isTrue);

      // Coba trigger session lagi secara paksa saat masih berjalan
      await service.triggerImmediateSession();

      // Kamera tidak boleh di-start dua kali
      expect(mockRepo.startCount, 1);
    });

    // 6. interval calculation
    test('6. Interval calculation: default 30 menit dan deteksi jatuh tempo', () async {
      final service = EyeMonitoringService(
        repository: mockRepo,
        localRepository: localRepo,
        syncManager: syncMgr,
        db: db,
        autoStart: false,
      );

      expect(service.monitoringInterval, const Duration(minutes: 30));
      expect(service.sessionDuration, const Duration(minutes: 1));
    });

    // 7. session duration
    test('7. Session duration: dapat dikonfigurasi untuk pengujian', () async {
      final service = EyeMonitoringService(
        repository: mockRepo,
        localRepository: localRepo,
        syncManager: syncMgr,
        db: db,
        monitoringInterval: const Duration(seconds: 10),
        sessionDuration: const Duration(seconds: 2),
        autoStart: false,
      );

      expect(service.monitoringInterval, const Duration(seconds: 10));
      expect(service.sessionDuration, const Duration(seconds: 2));
    });

    // 8. stop monitoring
    test('8. Stop monitoring: mematikan kamera yang sedang aktif dan membatalkan jadwal berikutnya', () async {
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
      expect(mockRepo.stopCount, 1);
    });

    // 9. app resume
    test('9. App resume: jika sesi jatuh tempo, menjalankan SATU sesi', () async {
      final service = EyeMonitoringService(
        repository: mockRepo,
        localRepository: localRepo,
        syncManager: syncMgr,
        db: db,
        monitoringInterval: const Duration(minutes: 30),
        autoStart: false,
      );

      await service.enableMonitoring();
      // Selesaikan sesi pertama
      await service.disableMonitoring();

      // Buat state seolah-olah monitoring aktif tapi sesi terakhir sudah 2 jam yang lalu
      await db.into(db.eyeMonitoringConfig).insertOnConflictUpdate(
        EyeMonitoringConfigCompanion.insert(
          id: 'current_config',
          monitoringEnabled: const drift.Value(true),
          lastSessionCompletedAt: drift.Value(DateTime.now().subtract(const Duration(hours: 2))),
          updatedAt: DateTime.now(),
        ),
      );

      final resumedService = EyeMonitoringService(
        repository: mockRepo,
        localRepository: localRepo,
        syncManager: syncMgr,
        db: db,
        autoStart: false,
      );
      await resumedService.initService();

      // Simulasikan app resume
      resumedService.didChangeAppLifecycleState(AppLifecycleState.resumed);

      // Harus menjalankan SATU sesi (bukan mengejar 4 sesi beruntun)
      expect(resumedService.isSessionRunning.value, isTrue);
    });

    // 10. app background
    test('10. App background: melepaskan kamera seketika tetapi monitoringEnabled tetap TRUE', () async {
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

      // Masuk background
      service.didChangeAppLifecycleState(AppLifecycleState.paused);
      await Future.delayed(const Duration(milliseconds: 50));

      // Kamera harus langsung dilepas
      expect(service.isSessionRunning.value, isFalse);
      expect(mockRepo.isCameraRunning, isFalse);
      // Status monitoring TETAP aktif
      expect(service.isMonitoringEnabled.value, isTrue);
    });

    // 11. app restart state
    test('11. App restart state: membaca persistent state dari Drift saat service baru dibuat', () async {
      // Tulis konfigurasi enabled ke database
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

      // State harus tetap aktif
      expect(restartedService.isMonitoringEnabled.value, isTrue);
      expect(restartedService.isSchedulerActive, isTrue);
    });

    // 12. navigation/controller recreation
    test('12. Navigation/controller recreation: dispose controller TIDAK mematikan monitoring service', () async {
      final service = EyeMonitoringService(
        repository: mockRepo,
        localRepository: localRepo,
        syncManager: syncMgr,
        db: db,
        autoStart: false,
      );
      Get.put<EyeMonitoringService>(service, permanent: true);

      // Navigasi ke halaman: Controller dibuat
      var controller = EyeMonitoringController(
        repository: mockRepo,
        syncManager: syncMgr,
        service: service,
      );
      await controller.enableMonitoring();

      expect(service.isMonitoringEnabled.value, isTrue);
      expect(service.isSessionRunning.value, isTrue);

      // User berpindah halaman: controller di-dispose
      controller.onClose();

      // Service harus tetap aktif dan sesi tetap berjalan!
      expect(service.isMonitoringEnabled.value, isTrue);
      expect(service.isSessionRunning.value, isTrue);

      // User kembali ke halaman Eye Monitoring: controller baru dibuat
      final newController = EyeMonitoringController(
        repository: mockRepo,
        syncManager: syncMgr,
        service: service,
      );
      newController.onInit();

      expect(newController.isMonitoringEnabled.value, isTrue);
      expect(newController.isMonitoring.value, isTrue);
    });

    // 13. due session
    test('13. Due session: jika selisih waktu >= interval, sesi otomatis dieksekusi', () async {
      final service = EyeMonitoringService(
        repository: mockRepo,
        localRepository: localRepo,
        syncManager: syncMgr,
        db: db,
        monitoringInterval: const Duration(minutes: 30),
        autoStart: false,
      );

      service.lastSessionCompletedAt.value = DateTime.now().subtract(const Duration(minutes: 31));
      service.isMonitoringEnabled.value = true;

      // Resume harus menjalankan sesi karena due
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(service.isSessionRunning.value, isTrue);
    });

    // 14. non-due session
    test('14. Non-due session: jika selisih waktu < interval, tidak menjalankan kamera', () async {
      final service = EyeMonitoringService(
        repository: mockRepo,
        localRepository: localRepo,
        syncManager: syncMgr,
        db: db,
        monitoringInterval: const Duration(minutes: 30),
        autoStart: false,
      );

      service.lastSessionCompletedAt.value = DateTime.now().subtract(const Duration(minutes: 10));
      service.isMonitoringEnabled.value = true;

      // Resume tidak boleh langsung menyalakan kamera
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(service.isSessionRunning.value, isFalse);
      expect(service.nextScheduledAt.value, isNotNull);
    });

    // 15. pending sync
    test('15. Pending sync: hasil sesi otomatis masuk ke database lokal Drift dengan syncStatus pending', () async {
      final service = EyeMonitoringService(
        repository: mockRepo,
        localRepository: localRepo,
        syncManager: syncMgr,
        db: db,
        autoStart: false,
      );

      await service.enableMonitoring();
      await service.disableMonitoring();

      final list = await localRepo.getSessions();
      expect(list.isNotEmpty, isTrue);
      expect(list.first.syncStatus, SyncStatus.pending);
    });

    // 16. device_id tetap sama
    test('16. Device ID tetap konsisten pada sesi yang disimpan', () async {
      final service = EyeMonitoringService(
        repository: mockRepo,
        localRepository: localRepo,
        syncManager: syncMgr,
        db: db,
        autoStart: false,
      );

      await service.enableMonitoring();
      await service.disableMonitoring();

      final list = await localRepo.getSessions();
      expect(list.first.deviceId, 'persistent-device-uuid-abc');
    });

    // 17. user_id menggunakan authenticated user
    test('17. User ID menggunakan authenticated user yang valid', () async {
      final service = EyeMonitoringService(
        repository: mockRepo,
        localRepository: localRepo,
        syncManager: syncMgr,
        db: db,
        autoStart: false,
      );

      await service.enableMonitoring();
      await service.disableMonitoring();

      final list = await localRepo.getSessions();
      expect(list.first.userId, 'auth-user-uuid-123');
    });

    // 18. camera tidak start saat background
    test('18. Camera TIDAK BOLEH start saat app berada di background', () async {
      final service = EyeMonitoringService(
        repository: mockRepo,
        localRepository: localRepo,
        syncManager: syncMgr,
        db: db,
        autoStart: false,
      );

      // Simulasikan app berada di background
      service.didChangeAppLifecycleState(AppLifecycleState.paused);

      // Coba jalankan sesi
      await service.triggerImmediateSession();

      // Kamera tidak boleh aktif saat background!
      expect(service.isSessionRunning.value, isFalse);
      expect(mockRepo.isCameraRunning, isFalse);
    });

    // 19. manual stop mencegah next session
    test('19. Manual stop mencegah sesi berikutnya dari timer terjadwal', () async {
      final service = EyeMonitoringService(
        repository: mockRepo,
        localRepository: localRepo,
        syncManager: syncMgr,
        db: db,
        monitoringInterval: const Duration(milliseconds: 100),
        sessionDuration: const Duration(milliseconds: 50),
        autoStart: false,
      );

      await service.enableMonitoring();
      await service.disableMonitoring();

      // Tunggu interval berlalu
      await Future.delayed(const Duration(milliseconds: 150));

      // Sesi berikutnya TIDAK BOLEH berjalan
      expect(service.isSessionRunning.value, isFalse);
    });

    // 20. re-enable membuat scheduler aktif kembali
    test('20. Re-enable membuat scheduler aktif kembali setelah dimatikan', () async {
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
      expect(service.isSchedulerActive, isFalse);

      await service.enableMonitoring();
      expect(service.isMonitoringEnabled.value, isTrue);
      expect(service.isSchedulerActive, isTrue);
    });
  });
}
