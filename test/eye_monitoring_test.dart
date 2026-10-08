import 'dart:async';
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
}
