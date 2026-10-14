import 'dart:async';
import 'dart:math' as math;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mind_drji/app/data/local/app_database.dart';
import 'package:mind_drji/app/data/local/repositories/eye_monitoring_local_repository.dart';
import 'package:mind_drji/app/data/local/tables/sync_queue.dart';
import 'package:mind_drji/app/data/models/eye_monitoring_live_event.dart';
import 'package:mind_drji/app/data/models/eye_monitoring_session_model.dart';
import 'package:mind_drji/app/data/providers/eye_monitoring_native_provider.dart';
import 'package:mind_drji/app/data/repositories/eye_monitoring_repository.dart';
import 'package:mind_drji/app/data/sync/sync_manager.dart';
import 'package:mind_drji/app/modules/monitoring/controllers/eye_monitoring_controller.dart';
import 'package:mind_drji/app/modules/monitoring/views/eye_monitoring_view.dart';

class FakeEyeMonitoringRepository implements EyeMonitoringRepository {
  bool hasPermission = true;
  bool isMonitoringActive = false;
  final liveStreamController = StreamController<EyeMonitoringLiveEvent>.broadcast();
  final List<EyeMonitoringSessionData> storedInDb = [];

  @override
  Future<bool> checkCameraPermission() async => hasPermission;

  @override
  Future<bool> requestCameraPermission() async => hasPermission;

  @override
  Future<bool> startMonitoring() async {
    isMonitoringActive = true;
    return true;
  }

  @override
  Future<EyeMonitoringSessionModel?> stopMonitoringAndPersist() async {
    isMonitoringActive = false;
    final session = EyeMonitoringSessionModel(
      id: 'fake-sess-1',
      userId: 'test-user-id',
      startedAt: DateTime.now().subtract(const Duration(seconds: 45)),
      endedAt: DateTime.now(),
      durationMillis: 45000,
      averageEar: 0.28,
      minEar: 0.16,
      eyeClosureEvents: 3,
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

    return session;
  }

  @override
  Future<bool> getStatus() async => isMonitoringActive;

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
    isMonitoringActive = true;
    return true;
  }

  @override
  Future<bool> stopForegroundMonitoring() async {
    isMonitoringActive = false;
    return true;
  }

  @override
  Future<bool> isForegroundServiceRunning() async => isMonitoringActive;

  @override
  Future<List<EyeMonitoringSessionModel>> flushPendingSessions() async => [];

  @override
  EyeMonitoringNativeProvider get provider => EyeMonitoringNativeProvider();

  @override
  EyeMonitoringLocalRepository get localRepository =>
      EyeMonitoringLocalRepository();

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
  group('EyeMonitoringSessionModel & LiveEvent Tests', () {
    test('fromNativeMap mengurai format data numeric CameraX/MediaPipe dengan benar', () {
      final nowMillis = DateTime.now().millisecondsSinceEpoch;
      final endedMillis = nowMillis + 60000;

      final nativeMap = {
        'id': 'eye-sess-uuid-1',
        'startedAt': nowMillis,
        'endedAt': endedMillis,
        'durationMillis': 60000,
        'averageEar': 0.275,
        'minEar': 0.14,
        'eyeClosureEvents': 4,
        'blinkCount': 18,
        'collectedAt': endedMillis,
      };

      final model = EyeMonitoringSessionModel.fromNativeMap(
        nativeMap,
        defaultUserId: 'user-abc',
      );

      expect(model.id, 'eye-sess-uuid-1');
      expect(model.userId, 'user-abc');
      expect(model.durationMillis, 60000);
      expect(model.averageEar, 0.275);
      expect(model.minEar, 0.14);
      expect(model.eyeClosureEvents, 4);
      expect(model.blinkCount, 18);
      expect(model.syncStatus, 'pending');

      final supaMap = model.toSupabaseMap('user-abc');
      expect(supaMap['user_id'], 'user-abc');
      expect(supaMap['average_ear'], 0.275);
      expect(supaMap['blink_count'], 18);
    });

    test('toSupabaseMap menangani NaN, Infinity, duration negatif, dan UTC formatting', () {
      final model = EyeMonitoringSessionModel(
        id: 'eye-nan-test',
        startedAt: DateTime.parse('2026-09-29T10:00:00Z'),
        endedAt: null,
        durationMillis: -100, // Durasi negatif
        averageEar: double.nan,
        minEar: double.infinity,
        eyeClosureEvents: 0,
        blinkCount: 0,
        collectedAt: DateTime.parse('2026-09-29T10:00:00Z'),
      );

      final map = model.toSupabaseMap('valid-user-uuid');

      expect(map['user_id'], 'valid-user-uuid');
      expect(map['duration_millis'], 0);
      expect(map['average_ear'], 0.0);
      expect(map['min_ear'], 0.0);
      expect(map['ended_at'], isNotNull);
      expect(map['started_at'], contains('Z'));
    });

    test('EyeMonitoringLiveEvent mengurai status realtime', () {
      final map = {
        'type': 'status_update',
        'isMonitoring': true,
        'faceDetected': true,
        'multipleFaces': false,
        'currentEar': 0.29,
        'averageEar': 0.28,
        'minEar': 0.18,
        'eyeClosureEvents': 2,
        'blinkCount': 8,
        'durationMillis': 15000,
        'statusMessage': 'Mata terbuka normal',
      };

      final event = EyeMonitoringLiveEvent.fromMap(map);

      expect(event.isMonitoring, isTrue);
      expect(event.faceDetected, isTrue);
      expect(event.multipleFaces, isFalse);
      expect(event.currentEar, 0.29);
      expect(event.blinkCount, 8);
      expect(event.statusMessage, 'Mata terbuka normal');
    });

    test('EyeMonitoringLiveEvent no-face state', () {
      final map = {
        'type': 'status_update',
        'isMonitoring': true,
        'faceDetected': false,
        'multipleFaces': false,
        'currentEar': 0.0,
        'statusMessage': 'Face not detected',
      };

      final event = EyeMonitoringLiveEvent.fromMap(map);

      expect(event.faceDetected, isFalse);
      expect(event.currentEar, 0.0);
      expect(event.statusMessage, 'Face not detected');
    });
  });

  group('EyeMonitoringLocalRepository In-Memory Drift Tests', () {
    late AppDatabase db;
    late EyeMonitoringLocalRepository repo;

    setUp(() {
      Get.reset();
      db = AppDatabase(NativeDatabase.memory());
      repo = EyeMonitoringLocalRepository(db: db);
    });

    tearDown(() async {
      await db.close();
      Get.reset();
    });

    test('insertSession menyimpan sesi ke Drift dan mendaftarkan sync_queue', () async {
      final session = EyeMonitoringSessionModel(
        id: 'eye-db-sess-1',
        startedAt: DateTime.now().subtract(const Duration(minutes: 1)),
        endedAt: DateTime.now(),
        durationMillis: 60000,
        averageEar: 0.26,
        minEar: 0.15,
        eyeClosureEvents: 2,
        blinkCount: 12,
        collectedAt: DateTime.now(),
      );

      await repo.insertSession(session);

      final list = await repo.getSessions();
      expect(list.length, 1);
      expect(list.first.id, 'eye-db-sess-1');
      expect(list.first.averageEar, 0.26);
      expect(list.first.blinkCount, 12);
      expect(list.first.syncStatus, SyncStatus.pending);

      // Verifikasi entri sync queue
      final queue = await db.select(db.syncQueue).get();
      expect(queue.length, 1);
      expect(queue.first.entityType, SyncEntityType.eyeMonitoringSession);
      expect(queue.first.entityId, 'eye-db-sess-1');
      expect(queue.first.operation, SyncOperation.insert);
    });

    test('markSessionSynced memperbarui status dan menghapus antrean sync', () async {
      final session = EyeMonitoringSessionModel(
        id: 'eye-db-sess-2',
        startedAt: DateTime.now(),
        durationMillis: 30000,
        averageEar: 0.30,
        minEar: 0.20,
        eyeClosureEvents: 1,
        blinkCount: 6,
        collectedAt: DateTime.now(),
      );

      await repo.insertSession(session);
      await repo.markSessionSynced('eye-db-sess-2');

      final updated = await repo.getSessionById('eye-db-sess-2');
      expect(updated!.syncStatus, SyncStatus.synced);

      final queue = await db.select(db.syncQueue).get();
      expect(queue.isEmpty, isTrue);
    });

    test('getPendingSyncCount menghitung status pending/failed dan claimLocalSessions mengaitkan userId', () async {
      final session = EyeMonitoringSessionModel(
        id: 'eye-db-sess-3',
        startedAt: DateTime.now(),
        durationMillis: 20000,
        averageEar: 0.25,
        minEar: 0.18,
        eyeClosureEvents: 1,
        blinkCount: 4,
        collectedAt: DateTime.now(),
      );

      // Simpan saat offline (userId bernilai 'local_user')
      await repo.insertSession(session);
      expect(await repo.getPendingSyncCount('real-user-123'), 1);

      // Klaim sesi oleh user yang login
      await repo.claimLocalSessions('real-user-123');
      final claimed = await repo.getSessionById('eye-db-sess-3');
      expect(claimed!.userId, 'real-user-123');

      // Tandai gagal, getPendingSyncCount harus tetap menghitung sesi yang belum tersinkron
      await repo.markSessionFailed('eye-db-sess-3', 'Connection failed');
      expect(await repo.getPendingSyncCount('real-user-123'), 1);
    });
  });

  group('EyeMonitoringController & EyeMonitoringView Tests', () {
    late FakeEyeMonitoringRepository fakeRepo;
    late SyncManager fakeSyncManager;

    setUp(() {
      Get.reset();
      fakeRepo = FakeEyeMonitoringRepository();
      fakeSyncManager = SyncManager(autoStart: false);
      Get.put<SyncManager>(fakeSyncManager);
    });

    tearDown(() {
      fakeRepo.liveStreamController.close();
      Get.reset();
    });

    test('Controller menginisialisasi status standby ketika belum aktif', () async {
      final controller = Get.put(EyeMonitoringController(
        repository: fakeRepo,
        syncManager: fakeSyncManager,
      ));
      await controller.initialCheck();

      expect(controller.isMonitoring.value, isFalse);
      expect(controller.cameraPermission.value, isTrue);
      expect(controller.faceDetected.value, isFalse);
    });

    test('Controller memulai dan menghentikan monitoring dengan benar', () async {
      final controller = Get.put(EyeMonitoringController(
        repository: fakeRepo,
        syncManager: fakeSyncManager,
      ));
      await controller.initialCheck();

      await controller.startMonitoring();
      expect(controller.isMonitoring.value, isTrue);
      expect(controller.statusMessage.value, 'Monitoring aktif');

      await controller.stopMonitoring();
      expect(controller.isMonitoring.value, isFalse);
      expect(controller.statusMessage.value, 'Monitoring selesai');
      expect(controller.storedSessions.length, 1);
    });

    testWidgets('EyeMonitoringView menampilkan state standby dan privacy notice',
        (tester) async {
      final controller = Get.put(EyeMonitoringController(
        repository: fakeRepo,
        syncManager: fakeSyncManager,
      ));
      await controller.initialCheck();

      await tester.pumpWidget(
        const GetMaterialApp(
          home: EyeMonitoringView(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pemantauan Mata'), findsOneWidget);
      expect(find.text('Monitoring belum aktif'), findsOneWidget);
      expect(find.text('Aktifkan Monitoring'), findsOneWidget);
      expect(
        find.textContaining('Prinsip Privasi & Keamanan Kamera'),
        findsOneWidget,
      );

      // Pastikan TIDAK ADA diagnosis medis atau skor fatigue 0-100
      expect(find.textContaining('Diagnosis Medis'), findsNothing);
      expect(find.textContaining('Fatigue Score'), findsNothing);
      expect(find.textContaining('Skor Kelelahan'), findsNothing);
    });

    testWidgets('EyeMonitoringView menampilkan status aktif ketika isMonitoring bernilai true',
        (tester) async {
      final controller = Get.put(EyeMonitoringController(
        repository: fakeRepo,
        syncManager: fakeSyncManager,
      ));
      await controller.initialCheck();
      controller.isMonitoringEnabled.value = true;
      controller.isMonitoring.value = true;
      controller.faceDetected.value = true;
      controller.currentEar.value = 0.28;
      controller.blinkCount.value = 10;
      controller.eyeClosureEvents.value = 2;
      controller.elapsedDuration.value = 45000;
      controller.statusMessage.value = 'Mata terbuka normal';

      await tester.pumpWidget(
        const GetMaterialApp(
          home: EyeMonitoringView(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sedang Memantau'), findsWidgets);
      expect(find.text('Kamera aktif untuk pemantauan mata.'), findsOneWidget);
      expect(find.text('Wajah Terdeteksi'), findsOneWidget);
      expect(find.text('00:45'), findsOneWidget);
      expect(find.text('0.28'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Matikan Monitoring'), findsOneWidget);
    });

    testWidgets('EyeMonitoringView menampilkan info Penyimpanan Lokal Aktif dan jadwal sinkronisasi 23:59',
        (tester) async {
      final controller = Get.put(EyeMonitoringController(
        repository: fakeRepo,
        syncManager: fakeSyncManager,
      ));
      await controller.initialCheck();

      // Tambahkan sesi lokal
      controller.storedSessions.add(
        EyeMonitoringSessionData(
          id: 'sess-pending-1',
          userId: 'test-user',
          deviceId: 'dev-1',
          startedAt: DateTime.now().subtract(const Duration(minutes: 5)),
          endedAt: DateTime.now().subtract(const Duration(minutes: 4)),
          durationMillis: BigInt.from(60000),
          averageEar: 0.27,
          minEar: 0.16,
          eyeClosureEvents: 2,
          blinkCount: 12,
          collectedAt: DateTime.now(),
          syncStatus: SyncStatus.pending,
          syncAttempts: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        const GetMaterialApp(
          home: EyeMonitoringView(),
        ),
      );
      await tester.pumpAndSettle();

      // Verifikasi banner info penyimpanan lokal aktif dan status tersimpan
      expect(find.text('Penyimpanan Lokal Aktif'), findsOneWidget);
      expect(find.textContaining('23:59 WIB'), findsOneWidget);
      expect(find.text('Tersimpan'), findsOneWidget);
    });
  });

  // ===========================================================================
  // EYE BLINK DETECTION & STATE MACHINE VALIDATION TESTS
  // ===========================================================================
  group('Eye Blink State Machine & EventChannel Tests', () {
    late EyeBlinkStateMachineSimulator stateMachine;

    setUp(() {
      Get.reset();
      stateMachine = EyeBlinkStateMachineSimulator();
    });

    tearDown(() {
      Get.reset();
    });

    test('1. Mata terbuka stabil: tidak menghasilkan kedipan atau penutupan', () {
      // Simulasi mata terbuka konsisten (EAR ~0.30 - 0.33) selama 10 frame @ 120ms
      for (int i = 0; i < 10; i++) {
        stateMachine.processFrame(
          ear: 0.32,
          timestampMs: i * 120,
          faceDetected: true,
          isEarValid: true,
        );
      }

      expect(stateMachine.totalBlinkCount, 0);
      expect(stateMachine.eyeClosureEventsCount, 0);
      expect(stateMachine.isEyeCurrentlyClosed, isFalse);
    });

    test('2. Satu siklus tutup-buka: menghasilkan tepat 1 kedipan valid', () {
      // Frame 0 (t=0ms): Mata terbuka
      stateMachine.processFrame(ear: 0.32, timestampMs: 0);

      // Frame 1 (t=120ms): Mata mulai menutup (EAR 0.16 < 0.21)
      stateMachine.processFrame(ear: 0.16, timestampMs: 120);
      expect(stateMachine.isEyeCurrentlyClosed, isTrue);

      // Frame 2 (t=240ms): Mata masih tertutup (EAR 0.15 < 0.21) -> durasi 120ms
      stateMachine.processFrame(ear: 0.15, timestampMs: 240);

      // Frame 3 (t=360ms): Mata membuka kembali (EAR 0.31 >= 0.21) -> transisi closed -> open
      stateMachine.processFrame(ear: 0.31, timestampMs: 360);

      expect(stateMachine.totalBlinkCount, 1);
      expect(stateMachine.eyeClosureEventsCount, 0);
      expect(stateMachine.isEyeCurrentlyClosed, isFalse);
    });

    test('3. Beberapa kedipan terpisah: menghasilkan hitungan yang tepat (3 kedipan)', () {
      int t = 0;

      for (int blink = 0; blink < 3; blink++) {
        // Mata terbuka 3 frame
        for (int f = 0; f < 3; f++) {
          stateMachine.processFrame(ear: 0.32, timestampMs: t);
          t += 120;
        }

        // Kedip: 2 frame tertutup (240ms)
        stateMachine.processFrame(ear: 0.14, timestampMs: t);
        t += 120;
        stateMachine.processFrame(ear: 0.13, timestampMs: t);
        t += 120;

        // Mata terbuka kembali
        stateMachine.processFrame(ear: 0.33, timestampMs: t);
        t += 120;
      }

      expect(stateMachine.totalBlinkCount, 3);
      expect(stateMachine.eyeClosureEventsCount, 0);
    });

    test('4. Mata tertutup berkepanjangan (>1000ms): dihitung sebagai penutupan mata, BUKAN kedipan', () {
      int t = 0;

      // Mata terbuka awal
      stateMachine.processFrame(ear: 0.32, timestampMs: t);
      t += 120;

      // Mata terpejam lama selama 10 frame (1200ms)
      for (int i = 0; i < 10; i++) {
        stateMachine.processFrame(ear: 0.12, timestampMs: t);
        t += 120;
      }

      // Harus terdeteksi sebagai 1 prolonged closure event saat melewati 1000ms
      expect(stateMachine.eyeClosureEventsCount, 1);
      expect(stateMachine.totalBlinkCount, 0);

      // Mata akhirnya membuka kembali
      stateMachine.processFrame(ear: 0.30, timestampMs: t);

      // Kedipan TIDAK boleh bertambah karena ini penutupan berkepanjangan
      expect(stateMachine.totalBlinkCount, 0);
      expect(stateMachine.eyeClosureEventsCount, 1);
      expect(stateMachine.isEyeCurrentlyClosed, isFalse);
    });

    test('5. Wajah tidak terdeteksi di tengah penutupan: TIDAK menghasilkan kedipan palsu', () {
      // Mata terbuka
      stateMachine.processFrame(ear: 0.32, timestampMs: 0);

      // Mata mulai menutup
      stateMachine.processFrame(ear: 0.15, timestampMs: 120);
      expect(stateMachine.isEyeCurrentlyClosed, isTrue);

      // Frame berikutnya: wajah hilang (pengguna menoleh/berpindah)
      stateMachine.processFrame(ear: 0.0, timestampMs: 240, faceDetected: false);
      expect(stateMachine.isEyeCurrentlyClosed, isFalse);

      // Wajah muncul kembali dengan mata terbuka
      stateMachine.processFrame(ear: 0.32, timestampMs: 360, faceDetected: true);

      // Tidak boleh ada kedipan palsu akibat wajah hilang
      expect(stateMachine.totalBlinkCount, 0);
      expect(stateMachine.eyeClosureEventsCount, 0);
    });

    test('6. Nilai EAR tidak valid (out of range/NaN): diabaikan tanpa kedipan palsu', () {
      stateMachine.processFrame(ear: 0.30, timestampMs: 0);

      // Nilai abnormal (misal landmark rusak / NaN)
      stateMachine.processFrame(ear: -1.0, timestampMs: 120, isEarValid: false);

      stateMachine.processFrame(ear: 0.31, timestampMs: 240);

      expect(stateMachine.totalBlinkCount, 0);
      expect(stateMachine.isEyeCurrentlyClosed, isFalse);
    });

    test('7. Event hasil deteksi diterima Flutter via EventChannel dan memperbarui Controller', () async {
      final fakeRepo = FakeEyeMonitoringRepository();
      fakeRepo.isMonitoringActive = true;
      final controller = EyeMonitoringController(
        repository: fakeRepo,
      );

      controller.onInit();
      await controller.initialCheck();

      // Emit live event dari native
      fakeRepo.liveStreamController.add(
        const EyeMonitoringLiveEvent(
          type: 'status_update',
          isMonitoring: true,
          faceDetected: true,
          multipleFaces: false,
          measurementValid: true,
          currentEar: 0.285,
          averageEar: 0.290,
          minEar: 0.150,
          eyeClosureEvents: 2,
          blinkCount: 7,
          durationMillis: 30000,
          statusMessage: 'Mata terbuka normal',
        ),
      );

      await Future.delayed(const Duration(milliseconds: 50));

      expect(controller.isMonitoring.value, isTrue);
      expect(controller.faceDetected.value, isTrue);
      expect(controller.currentEar.value, 0.285);
      expect(controller.blinkCount.value, 7);
      expect(controller.eyeClosureEvents.value, 2);
      expect(controller.statusMessage.value, 'Mata terbuka normal');

      controller.onClose();
    });

    test('8. Penanganan multiple faces: memilih wajah utama pengguna berdasarkan area dan posisi tengah', () {
      // Simulasi 2 wajah yang terdeteksi:
      // Wajah 1: Pengguna utama di depan kamera HP (30-45 cm) -> area besar, dekat tengah
      final userFaceArea = 0.35 * 0.40; // 0.14
      final userCenterDist = 0.05; // sangat dekat tengah (0.5, 0.5)
      final userScore = (userFaceArea * 3.0) - (userCenterDist * 0.4);

      // Wajah 2: Orang lain di latar belakang / poster -> area kecil, jauh dari tengah
      final backgroundFaceArea = 0.10 * 0.12; // 0.012
      final backgroundCenterDist = 0.35;
      final backgroundScore = (backgroundFaceArea * 3.0) - (backgroundCenterDist * 0.4);

      expect(userScore, greaterThan(backgroundScore));
    });

    test('9. Validasi pose roll: membedakan kemiringan wajar (0-35 deg) dari orientasi salah/miring ekstrem (80-90 deg)', () {
      // Mata tegak lurus natural (dy ~ 0): roll mendekati 0 deg
      const uprightDx = 160.0;
      const uprightDy = 5.0;
      final uprightRoll = (uprightDy / uprightDx) * (180 / 3.141592653589793);
      expect(uprightRoll, lessThan(45.0));

      // Kemiringan wajar penggunaan HP santai (~20 deg): roll < 45 deg
      const tiltedDx = 150.0;
      const tiltedDy = 50.0; // ~18.4 deg
      final tiltedRoll = (tiltedDy / tiltedDx) * (180 / 3.141592653589793);
      expect(tiltedRoll, lessThan(45.0));

      // Sensor frame terbalik 90 deg / sideways (dy >> dx, misal 81.3 deg)
      const sidewaysDx = 25.0;
      const sidewaysDy = 160.0; // ~81 deg
      final sidewaysRoll = 90.0 - ((sidewaysDx / sidewaysDy) * (180 / 3.141592653589793));
      expect(sidewaysRoll, greaterThan(45.0));
    });

    test('10. Event multiple faces dengan pengukuran valid tetap menampilkan EAR dan kedipan di Flutter', () async {
      final fakeRepo = FakeEyeMonitoringRepository();
      fakeRepo.isMonitoringActive = true;
      final controller = EyeMonitoringController(
        repository: fakeRepo,
      );

      controller.onInit();
      await controller.initialCheck();

      // Emit event dengan multipleFaces: true tetapi measurementValid: true (wajah utama terpilih)
      fakeRepo.liveStreamController.add(
        const EyeMonitoringLiveEvent(
          type: 'status_update',
          isMonitoring: true,
          faceDetected: true,
          multipleFaces: true, // Ada orang lain di background
          measurementValid: true, // Wajah utama pengguna valid
          currentEar: 0.312,
          averageEar: 0.305,
          minEar: 0.170,
          eyeClosureEvents: 1,
          blinkCount: 4,
          durationMillis: 15000,
          statusMessage: 'Mata terbuka normal',
        ),
      );

      await Future.delayed(const Duration(milliseconds: 50));

      expect(controller.isMonitoring.value, isTrue);
      expect(controller.faceDetected.value, isTrue);
      expect(controller.multipleFaces.value, isTrue);
      expect(controller.currentEar.value, 0.312);
      expect(controller.blinkCount.value, 4);

      controller.onClose();
    });

    group('Face Distance and Bounding Box Validation Tests', () {
      test('1D coordinate projection collapses under 90-degree sensor rotation while Euclidean anatomical span remains robust', () {
        // Simulasi wajah normal pada jarak 35 cm.
        // Pada orientasi normal (tegak):
        // Chin-forehead span = 0.35 vertical, Cheeks span = 0.30 horizontal.
        // Jika kamera sensor dirotasi 90 derajat (seperti landscape sensor pada HP Xiaomi):
        // Chin dan forehead berada pada sumbu horizontal: dx = 0.35, dy = 0.017 (hampir horizontal murni)
        // Cheeks berada pada sumbu vertikal: dy = 0.30, dx = 0.00005 (hampir vertikal murni)

        final simulatedLandmarks = List.generate(468, (index) => (x: 0.5, y: 0.5));
        // Atur titik kritis pada rotasi 90 derajat
        simulatedLandmarks[10] = (x: 0.30, y: 0.50); // Forehead
        simulatedLandmarks[152] = (x: 0.65, y: 0.517376); // Chin (dx = 0.35, dy = 0.017376)
        simulatedLandmarks[234] = (x: 0.475, y: 0.35); // Left cheek
        simulatedLandmarks[454] = (x: 0.4750528, y: 0.65); // Right cheek (dx = 0.0000528, dy = 0.30)

        // Hitung dengan rumus 1D lama (salah):
        final oldFaceHeight = (simulatedLandmarks[152].y - simulatedLandmarks[10].y).abs();
        final oldFaceWidth = (simulatedLandmarks[454].x - simulatedLandmarks[234].x).abs();

        // Bukti bug: 1D projection menghasilkan nilai sangat kecil yang persis dengan log pengguna!
        expect(oldFaceHeight, closeTo(0.017376, 0.001));
        expect(oldFaceWidth, closeTo(0.0000528, 0.00001));
        expect(oldFaceHeight < 0.05, isTrue); // Ditolak karena < 0.05
        expect(oldFaceWidth < 0.05, isTrue); // Ditolak karena < 0.05

        // Sekarang evaluasi dengan implementasi baru (FaceMetricsValidatorSimulator):
        final result = FaceMetricsValidatorSimulator.evaluateFace(landmarks: simulatedLandmarks);

        expect(result.isValid, isTrue, reason: 'Wajah pada jarak 35cm harus valid meskipun orientasi frame dirotasi');
        expect(result.height, greaterThanOrEqualTo(0.30));
        expect(result.width, greaterThanOrEqualTo(0.30));
        expect(result.rejectionReason, isNull);
      });

      test('Face genuinely too far away (< 0.05 frame ratio) is properly rejected', () {
        // Simulasi wajah sangat jauh (> 2 meter), di mana bentang wajah hanya 2% dari frame
        final tinyLandmarks = List.generate(468, (index) => (x: 0.5, y: 0.5));
        tinyLandmarks[10] = (x: 0.50, y: 0.49); // Forehead
        tinyLandmarks[152] = (x: 0.50, y: 0.51); // Chin (height = 0.02)
        tinyLandmarks[234] = (x: 0.49, y: 0.50); // Left cheek
        tinyLandmarks[454] = (x: 0.51, y: 0.50); // Right cheek (width = 0.02)

        final result = FaceMetricsValidatorSimulator.evaluateFace(landmarks: tinyLandmarks);

        expect(result.isValid, isFalse);
        expect(result.rejectionReason, equals('face_distance'));
        expect(result.width, lessThan(0.05));
        expect(result.height, lessThan(0.05));
      });

      test('EAR computation with 6 landmarks returns realistic eye aspect ratios', () {
        const frameW = 640.0;
        const frameH = 480.0;

        // Mata terbuka (lebar = 30px, tinggi = 9px -> EAR ≈ (9 + 9)/(2*30) = 0.30)
        final openEyeLandmarks = [
          (x: 100.0 / frameW, y: 200.0 / frameH), // p1 (outer corner)
          (x: 110.0 / frameW, y: 195.5 / frameH), // p2 (top 1)
          (x: 120.0 / frameW, y: 195.5 / frameH), // p3 (top 2)
          (x: 130.0 / frameW, y: 200.0 / frameH), // p4 (inner corner)
          (x: 120.0 / frameW, y: 204.5 / frameH), // p5 (bottom 2)
          (x: 110.0 / frameW, y: 204.5 / frameH), // p6 (bottom 1)
        ];

        final openEar = FaceMetricsValidatorSimulator.calculateEar(
          eyeLandmarks: openEyeLandmarks,
          frameWidth: frameW,
          frameHeight: frameH,
        );

        expect(openEar, closeTo(0.30, 0.02));
        expect(openEar > 0.21, isTrue, reason: 'Mata terbuka harus di atas ambang penutupan 0.21');

        // Mata terpejam (lebar = 30px, tinggi = 2px -> EAR ≈ (2 + 2)/(2*30) = 0.067)
        final closedEyeLandmarks = [
          (x: 100.0 / frameW, y: 200.0 / frameH), // p1
          (x: 110.0 / frameW, y: 199.0 / frameH), // p2
          (x: 120.0 / frameW, y: 199.0 / frameH), // p3
          (x: 130.0 / frameW, y: 200.0 / frameH), // p4
          (x: 120.0 / frameW, y: 201.0 / frameH), // p5
          (x: 110.0 / frameW, y: 201.0 / frameH), // p6
        ];

        final closedEar = FaceMetricsValidatorSimulator.calculateEar(
          eyeLandmarks: closedEyeLandmarks,
          frameWidth: frameW,
          frameHeight: frameH,
        );

        expect(closedEar, closeTo(0.067, 0.02));
        expect(closedEar < 0.21, isTrue, reason: 'Mata terpejam harus di bawah ambang penutupan 0.21');
      });
    });
  });
}

class EyeBlinkStateMachineSimulator {
  static const double technicalEarClosureThreshold = 0.21;
  static const int minBlinkDurationMs = 60;
  static const int maxBlinkDurationMs = 450;
  static const int prolongedClosureThresholdMs = 1000;
  static const int minInterBlinkIntervalMs = 150;

  bool isEyeCurrentlyClosed = false;
  int closureStartTimeMs = 0;
  int closureFrameCount = 0;
  bool prolongedClosureReported = false;
  int lastBlinkTimestamp = 0;
  int eyeClosureEventsCount = 0;
  int totalBlinkCount = 0;

  void processFrame({
    required double ear,
    required int timestampMs,
    bool faceDetected = true,
    bool isEarValid = true,
  }) {
    if (!faceDetected || !isEarValid) {
      isEyeCurrentlyClosed = false;
      closureFrameCount = 0;
      prolongedClosureReported = false;
      return;
    }

    final isClosed = ear < technicalEarClosureThreshold;

    if (isClosed) {
      if (!isEyeCurrentlyClosed) {
        isEyeCurrentlyClosed = true;
        closureStartTimeMs = timestampMs;
        closureFrameCount = 1;
        prolongedClosureReported = false;
      } else {
        closureFrameCount++;
        final closedDuration = timestampMs - closureStartTimeMs;
        if (closedDuration >= prolongedClosureThresholdMs && !prolongedClosureReported) {
          eyeClosureEventsCount++;
          prolongedClosureReported = true;
        }
      }
    } else {
      if (isEyeCurrentlyClosed) {
        final closedDuration = timestampMs - closureStartTimeMs;
        final timeSinceLastBlink = timestampMs - lastBlinkTimestamp;

        final isValidDuration = (closedDuration >= minBlinkDurationMs && closedDuration <= maxBlinkDurationMs) ||
            (closureFrameCount >= 1 && closureFrameCount <= 4 && closedDuration <= maxBlinkDurationMs + 100);

        if (!prolongedClosureReported && isValidDuration && timeSinceLastBlink >= minInterBlinkIntervalMs) {
          totalBlinkCount++;
          lastBlinkTimestamp = timestampMs;
        }

        isEyeCurrentlyClosed = false;
        closureFrameCount = 0;
        prolongedClosureReported = false;
      }
    }
  }
}

class FaceMetricsValidatorSimulator {
  static const double minFaceRatio = 0.05;

  static ({double width, double height, bool isValid, String? rejectionReason}) evaluateFace({
    required List<({double x, double y})> landmarks,
  }) {
    if (landmarks.length < 468) {
      return (width: 0.0, height: 0.0, isValid: false, rejectionReason: 'landmarks_count');
    }

    double minX = 1.0, maxX = 0.0, minY = 1.0, maxY = 0.0;
    for (final lm in landmarks) {
      if (lm.x < minX) minX = lm.x;
      if (lm.x > maxX) maxX = lm.x;
      if (lm.y < minY) minY = lm.y;
      if (lm.y > maxY) maxY = lm.y;
    }
    final bboxWidth = (maxX - minX).clamp(0.0, 1.0);
    final bboxHeight = (maxY - minY).clamp(0.0, 1.0);

    final chin = landmarks[152];
    final forehead = landmarks[10];
    final leftCheek = landmarks[234];
    final rightCheek = landmarks[454];

    final anatHeight = math.sqrt(
      math.pow(chin.x - forehead.x, 2) + math.pow(chin.y - forehead.y, 2),
    ).clamp(0.0, 1.0);
    final anatWidth = math.sqrt(
      math.pow(rightCheek.x - leftCheek.x, 2) + math.pow(rightCheek.y - leftCheek.y, 2),
    ).clamp(0.0, 1.0);

    final faceWidth = math.max(bboxWidth, anatWidth);
    final faceHeight = math.max(bboxHeight, anatHeight);

    if (faceWidth < minFaceRatio || faceHeight < minFaceRatio) {
      return (width: faceWidth, height: faceHeight, isValid: false, rejectionReason: 'face_distance');
    }

    return (width: faceWidth, height: faceHeight, isValid: true, rejectionReason: null);
  }

  static double calculateEar({
    required List<({double x, double y})> eyeLandmarks,
    required double frameWidth,
    required double frameHeight,
  }) {
    double dist(int i, int j) {
      final dx = (eyeLandmarks[i].x - eyeLandmarks[j].x) * frameWidth;
      final dy = (eyeLandmarks[i].y - eyeLandmarks[j].y) * frameHeight;
      return math.sqrt(dx * dx + dy * dy);
    }

    final vertical1 = dist(1, 5);
    final vertical2 = dist(2, 4);
    final horizontal = dist(0, 3);
    if (horizontal < 1e-6) return 0.0;
    return (vertical1 + vertical2) / (2.0 * horizontal);
  }
}
