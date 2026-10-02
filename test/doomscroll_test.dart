import 'dart:async';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mind_drji/app/data/local/app_database.dart';
import 'package:mind_drji/app/data/local/repositories/doomscroll_local_repository.dart';
import 'package:mind_drji/app/data/local/tables/sync_queue.dart';
import 'package:mind_drji/app/data/models/doomscroll_live_session.dart';
import 'package:mind_drji/app/data/models/doomscroll_session_model.dart';
import 'package:mind_drji/app/data/repositories/doomscroll_repository.dart';
import 'package:mind_drji/app/data/sync/sync_manager.dart';
import 'package:mind_drji/app/modules/monitoring/controllers/doomscroll_controller.dart';
import 'package:mind_drji/app/modules/monitoring/views/doomscroll_view.dart';

class FakeDoomscrollRepository implements DoomscrollRepository {
  bool isServiceActive = false;
  bool openSettingsResult = true;
  List<DoomscrollSessionModel> pendingNative = [];
  List<DoomscrollSessionData> storedInDb = [];
  final liveController = StreamController<DoomscrollLiveSession>.broadcast();

  @override
  Stream<DoomscrollLiveSession> liveSessionStream() => liveController.stream;

  @override
  Future<bool> checkAccessibilityService() async => isServiceActive;

  @override
  Future<bool> openAccessibilitySettings() async => openSettingsResult;

  @override
  Future<int> collectAndPersistPendingSessions() async {
    final count = pendingNative.length;
    for (final s in pendingNative) {
      storedInDb.add(
        DoomscrollSessionData(
          id: s.id,
          userId: s.userId ?? 'test-user',
          deviceId: s.deviceId,
          packageName: s.packageName,
          appName: s.appName,
          startedAt: s.startedAt,
          endedAt: s.endedAt,
          durationMillis: BigInt.from(s.durationMillis),
          swipeCount: s.swipeCount,
          downwardSwipeCount: s.downwardSwipeCount,
          upwardSwipeCount: s.upwardSwipeCount,
          avgInterSwipeMillis: BigInt.from(s.avgInterSwipeMillis),
          collectedAt: s.collectedAt,
          syncStatus: SyncStatus.pending,
          syncAttempts: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    }
    pendingNative.clear();
    return count;
  }

  @override
  Future<List<DoomscrollSessionData>> getStoredSessions({int limit = 50}) async {
    return List.from(storedInDb);
  }

  @override
  Future<List<DoomscrollSessionData>> getSessionsBetween({
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

  @override
  Future<int> claimLocalSessions(String authenticatedUserId) async => 0;
}

void main() {
  group('DoomscrollSessionModel Tests', () {
    test('fromMap mem-parse data native Android dengan kalkulasi behavioral yang tepat', () {
      final nowMillis = DateTime.now().millisecondsSinceEpoch;
      final endedMillis = nowMillis + 45000; // 45 detik durasi

      final rawMap = {
        'id': 'sess-uuid-1',
        'packageName': 'com.zhiliaoapp.musically',
        'appName': 'TikTok',
        'startedAt': nowMillis,
        'endedAt': endedMillis,
        'durationMillis': 45000,
        'swipeCount': 25,
        'downwardSwipeCount': 20,
        'upwardSwipeCount': 5,
        'avgInterSwipeMillis': 1875,
        'collectedAt': endedMillis,
      };

      final model = DoomscrollSessionModel.fromMap(rawMap, defaultUserId: 'usr-1');

      expect(model.id, 'sess-uuid-1');
      expect(model.userId, 'usr-1');
      expect(model.packageName, 'com.zhiliaoapp.musically');
      expect(model.appName, 'TikTok');
      expect(model.durationMillis, 45000);
      expect(model.swipeCount, 25);
      expect(model.downwardSwipeCount, 20);
      expect(model.upwardSwipeCount, 5);
      expect(model.downwardSwipeCount + model.upwardSwipeCount, equals(model.swipeCount));
      expect(model.avgInterSwipeMillis, 1875);

      final map = model.toMap();
      expect(map['package_name'], 'com.zhiliaoapp.musically');
      expect(map['swipe_count'], 25);
      expect(map['downward_swipe_count'], 20);
      expect(map['upward_swipe_count'], 5);
    });

    test('Durasi sesi dan rata-rata interval dihitung dengan konsisten', () {
      final start = DateTime(2026, 9, 28, 14, 0, 0);
      final end = DateTime(2026, 9, 28, 14, 2, 30); // 150 detik = 150.000 ms
      const swipes = 30;
      final duration = end.difference(start).inMilliseconds;
      final avgInterval = duration ~/ (swipes - 1);

      final session = DoomscrollSessionModel(
        id: 'sess-calc-1',
        userId: 'u1',
        packageName: 'com.instagram.android',
        appName: 'Instagram',
        startedAt: start,
        endedAt: end,
        durationMillis: duration,
        swipeCount: swipes,
        downwardSwipeCount: 26,
        upwardSwipeCount: 4,
        avgInterSwipeMillis: avgInterval,
        collectedAt: end,
      );

      expect(session.durationMillis, 150000);
      expect(session.avgInterSwipeMillis, 5172); // 150000 / 29
      expect(session.downwardSwipeCount, greaterThan(session.upwardSwipeCount));
    });
  });

  group('DoomscrollLocalRepository In-Memory SQLite Tests', () {
    late AppDatabase db;
    late DoomscrollLocalRepository localRepo;

    setUp(() {
      Get.reset();
      db = AppDatabase(NativeDatabase.memory());
      localRepo = DoomscrollLocalRepository(db: db);
    });

    tearDown(() async {
      await db.close();
      Get.reset();
    });

    test('insertSession menyimpan sesi ke Drift dan mendaftarkan sync_queue', () async {
      final session = DoomscrollSessionModel(
        id: 'sess-db-1',
        packageName: 'com.google.android.youtube',
        appName: 'YouTube',
        startedAt: DateTime.now().subtract(const Duration(minutes: 5)),
        endedAt: DateTime.now(),
        durationMillis: 300000,
        swipeCount: 40,
        downwardSwipeCount: 35,
        upwardSwipeCount: 5,
        avgInterSwipeMillis: 7500,
        collectedAt: DateTime.now(),
      );

      await localRepo.insertSession(session);

      final stored = await localRepo.getSessions();
      expect(stored.length, 1);
      expect(stored.first.id, 'sess-db-1');
      expect(stored.first.appName, 'YouTube');
      expect(stored.first.swipeCount, 40);
      expect(stored.first.syncStatus, SyncStatus.pending);

      // Verifikasi antrean sync
      final queue = await db.select(db.syncQueue).get();
      expect(queue.length, 1);
      expect(queue.first.entityType, SyncEntityType.doomscrollSession);
      expect(queue.first.entityId, 'sess-db-1');
    });

    test('markSessionSynced memperbarui status dan menghapus dari antrean', () async {
      final session = DoomscrollSessionModel(
        id: 'sess-db-2',
        packageName: 'com.snapchat.android',
        appName: 'Snapchat',
        startedAt: DateTime.now(),
        durationMillis: 20000,
        swipeCount: 10,
        downwardSwipeCount: 8,
        upwardSwipeCount: 2,
        avgInterSwipeMillis: 2000,
        collectedAt: DateTime.now(),
      );

      await localRepo.insertSession(session);
      await localRepo.markSessionSynced('sess-db-2');

      final updated = await localRepo.getSessionById('sess-db-2');
      expect(updated!.syncStatus, SyncStatus.synced);

      final queue = await db.select(db.syncQueue).get();
      expect(queue.isEmpty, isTrue);
    });

    test('markSessionFailed mencatat error dan menaikkan attempts', () async {
      final session = DoomscrollSessionModel(
        id: 'sess-db-3',
        packageName: 'com.zhiliaoapp.musically',
        appName: 'TikTok',
        startedAt: DateTime.now(),
        durationMillis: 15000,
        swipeCount: 8,
        downwardSwipeCount: 8,
        upwardSwipeCount: 0,
        avgInterSwipeMillis: 1800,
        collectedAt: DateTime.now(),
      );

      await localRepo.insertSession(session);
      await localRepo.markSessionFailed('sess-db-3', 'Connection closed');

      final updated = await localRepo.getSessionById('sess-db-3');
      expect(updated!.syncStatus, SyncStatus.failed);
      expect(updated.syncAttempts, 1);
      expect(updated.lastSyncError, 'Connection closed');
    });
  });

  group('DoomscrollController & DoomscrollView Widget Tests', () {
    late FakeDoomscrollRepository fakeRepo;
    late SyncManager fakeSyncManager;

    setUp(() {
      Get.reset();
      fakeRepo = FakeDoomscrollRepository();
      fakeSyncManager = SyncManager(autoStart: false);
      Get.put<SyncManager>(fakeSyncManager);
    });

    tearDown(() {
      Get.reset();
    });

    test('Controller mendeteksi status aksesibilitas non-aktif', () async {
      fakeRepo.isServiceActive = false;
      final controller = DoomscrollController(
        repository: fakeRepo,
        syncManager: fakeSyncManager,
      );
      await controller.initialCheckAndLoad();

      expect(controller.isAccessibilityActive.value, isFalse);
      expect(controller.sessions.isEmpty, isTrue);
    });

    test('Controller mengumpulkan sesi saat aksesibilitas aktif', () async {
      fakeRepo.isServiceActive = true;
      fakeRepo.pendingNative = [
        DoomscrollSessionModel(
          id: 's1',
          packageName: 'com.zhiliaoapp.musically',
          appName: 'TikTok',
          startedAt: DateTime.now().subtract(const Duration(minutes: 2)),
          endedAt: DateTime.now(),
          durationMillis: 120000,
          swipeCount: 50,
          downwardSwipeCount: 42,
          upwardSwipeCount: 8,
          avgInterSwipeMillis: 2400,
          collectedAt: DateTime.now(),
        ),
      ];

      final controller = DoomscrollController(
        repository: fakeRepo,
        syncManager: fakeSyncManager,
      );
      await controller.initialCheckAndLoad();

      expect(controller.isAccessibilityActive.value, isTrue);
      expect(controller.sessions.length, 1);
      expect(controller.totalSwipes.value, 50);
      expect(controller.totalDownwardSwipes.value, 42);
      expect(controller.totalUpwardSwipes.value, 8);
    });

    testWidgets('Tampilkan status belum aktif dan tombol aktifkan monitoring saat service off',
        (tester) async {
      fakeRepo.isServiceActive = false;
      final controller = Get.put(DoomscrollController(
        repository: fakeRepo,
        syncManager: fakeSyncManager,
      ));
      controller.isAccessibilityActive.value = false;
      controller.isLoading.value = false;

      await tester.pumpWidget(
        const GetMaterialApp(
          home: DoomscrollView(),
        ),
      );

      expect(find.text('Doomscroll Monitoring'), findsAtLeastNWidgets(1));
      expect(find.text('Monitoring Belum Aktif'), findsOneWidget);
      expect(find.text('Aktifkan Monitoring'), findsOneWidget);
      expect(find.textContaining('Monitoring menggunakan pola interaksi scrolling, bukan isi konten'),
          findsOneWidget);
      expect(find.text('Belum ada sesi scrolling terdeteksi.'), findsOneWidget);
    });

    testWidgets('Tampilkan status monitoring aktif dan daftar sesi terdeteksi',
        (tester) async {
      fakeRepo.isServiceActive = true;
      fakeRepo.storedInDb = [
        DoomscrollSessionData(
          id: 'test-view-1',
          userId: 'u1',
          deviceId: 'dev-1',
          packageName: 'com.instagram.android',
          appName: 'Instagram',
          startedAt: DateTime(2026, 9, 28, 14, 30),
          endedAt: DateTime(2026, 9, 28, 14, 31, 30),
          durationMillis: BigInt.from(90000),
          swipeCount: 32,
          downwardSwipeCount: 28,
          upwardSwipeCount: 4,
          avgInterSwipeMillis: BigInt.from(2800),
          collectedAt: DateTime.now(),
          syncStatus: 'synced',
          syncAttempts: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final controller = Get.put(DoomscrollController(
        repository: fakeRepo,
        syncManager: fakeSyncManager,
      ));
      await controller.initialCheckAndLoad();

      await tester.pumpWidget(
        const GetMaterialApp(
          home: DoomscrollView(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Monitoring Aktif'), findsOneWidget);
      expect(find.text('Instagram'), findsOneWidget);
      expect(find.text('32 scroll'), findsOneWidget);
      expect(find.text('28 bawah'), findsOneWidget);
      expect(find.text('4 atas'), findsOneWidget);
      expect(find.text('Synced'), findsOneWidget);
    });

    testWidgets('Tampilkan empty state jika tidak ada activeSession dan history kosong',
        (tester) async {
      fakeRepo.isServiceActive = true;
      fakeRepo.storedInDb = [];

      final controller = Get.put(DoomscrollController(
        repository: fakeRepo,
        syncManager: fakeSyncManager,
      ));
      await controller.initialCheckAndLoad();

      await tester.pumpWidget(
        const GetMaterialApp(
          home: DoomscrollView(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Belum ada sesi scrolling terdeteksi.'), findsOneWidget);
      expect(find.text('Sedang Memantau'), findsNothing);
    });

    testWidgets('Tampilkan card live session ketika activeSession tersedia',
        (tester) async {
      fakeRepo.isServiceActive = true;

      final controller = Get.put(DoomscrollController(
        repository: fakeRepo,
        syncManager: fakeSyncManager,
      ));
      await controller.initialCheckAndLoad();

      controller.activeSession.value = DoomscrollLiveSession(
        type: 'session_updated',
        id: 'live-test-1',
        packageName: 'com.ss.android.ugc.trill',
        appName: 'TikTok',
        startedAt: DateTime.now().subtract(const Duration(seconds: 155)), // 02:35
        durationMillis: 155000,
        swipeCount: 17,
        downwardSwipeCount: 15,
        upwardSwipeCount: 2,
        avgInterSwipeMillis: 9117,
        isActive: true,
      );

      await tester.pumpWidget(
        const GetMaterialApp(
          home: DoomscrollView(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sedang Memantau'), findsOneWidget);
      expect(find.text('Sesi scrolling aktif'), findsOneWidget);
      expect(find.text('TikTok'), findsOneWidget);
      expect(find.text('02:35'), findsOneWidget);
      expect(find.text('17 Scroll'), findsOneWidget);
      expect(find.text('↓ 15'), findsOneWidget);
      expect(find.text('↑ 2'), findsOneWidget);

      // Verifikasi TIDAK ADA skor adiksi atau diagnosis
      expect(find.textContaining('Doomscroll Score'), findsNothing);
      expect(find.textContaining('Addiction Score'), findsNothing);
      expect(find.textContaining('Diagnosis'), findsNothing);
      expect(find.textContaining('Kamu sedang doomscrolling'), findsNothing);
    });
  });

  group('DoomscrollLiveSession Model & Stream Tests', () {
    late FakeDoomscrollRepository fakeRepo;
    late SyncManager fakeSyncManager;

    setUp(() {
      Get.reset();
      fakeRepo = FakeDoomscrollRepository();
      fakeSyncManager = SyncManager(autoStart: false);
      Get.put<SyncManager>(fakeSyncManager);
    });

    tearDown(() {
      fakeRepo.liveController.close();
      Get.reset();
    });

    test('Parsing session_started event dari format Map native', () {
      final rawMap = {
        'type': 'session_started',
        'id': 'sess-live-101',
        'packageName': 'com.ss.android.ugc.trill',
        'appName': 'TikTok',
        'startedAt': 1727510400000,
        'durationMillis': 0,
        'swipeCount': 1,
        'downwardSwipeCount': 1,
        'upwardSwipeCount': 0,
        'avgInterSwipeMillis': 0,
        'isActive': true,
      };

      final liveSession = DoomscrollLiveSession.fromMap(rawMap);

      expect(liveSession.type, 'session_started');
      expect(liveSession.id, 'sess-live-101');
      expect(liveSession.packageName, 'com.ss.android.ugc.trill');
      expect(liveSession.appName, 'TikTok');
      expect(liveSession.swipeCount, 1);
      expect(liveSession.downwardSwipeCount, 1);
      expect(liveSession.upwardSwipeCount, 0);
      expect(liveSession.isActive, isTrue);
    });

    test('Parsing session_updated event dan format ISO string', () {
      final isoTime = DateTime.now().toIso8601String();
      final rawMap = {
        'type': 'session_updated',
        'id': 'sess-live-102',
        'packageName': 'com.instagram.android',
        'appName': 'Instagram',
        'startedAt': isoTime,
        'durationMillis': 65000,
        'swipeCount': 15,
        'downwardSwipeCount': 13,
        'upwardSwipeCount': 2,
        'avgInterSwipeMillis': 4333,
        'isActive': true,
      };

      final liveSession = DoomscrollLiveSession.fromMap(rawMap);

      expect(liveSession.type, 'session_updated');
      expect(liveSession.appName, 'Instagram');
      expect(liveSession.durationMillis, 65000);
      expect(liveSession.swipeCount, 15);
      expect(liveSession.downwardSwipeCount, 13);
      expect(liveSession.upwardSwipeCount, 2);
      expect(liveSession.isActive, isTrue);
    });

    test('Parsing session_finished event menandai isActive false', () {
      final rawMap = {
        'type': 'session_finished',
        'id': 'sess-live-103',
        'packageName': 'com.google.android.youtube',
        'appName': 'YouTube',
        'startedAt': 1727510400000,
        'durationMillis': 120000,
        'swipeCount': 30,
        'downwardSwipeCount': 25,
        'upwardSwipeCount': 5,
        'avgInterSwipeMillis': 4000,
        'isActive': false,
      };

      final liveSession = DoomscrollLiveSession.fromMap(rawMap);

      expect(liveSession.type, 'session_finished');
      expect(liveSession.isActive, isFalse);
      expect(liveSession.swipeCount, 30);
    });

    test('Controller bereaksi terhadap stream event session_started, session_updated, dan session_finished',
        () async {
      fakeRepo.isServiceActive = true;
      final controller = Get.put(DoomscrollController(
        repository: fakeRepo,
        syncManager: fakeSyncManager,
      ));
      await controller.initialCheckAndLoad();

      expect(controller.activeSession.value, isNull);

      final testStartTime = DateTime(2026, 9, 28, 14, 0, 0);

      // 1. Kirim event session_started
      fakeRepo.liveController.add(DoomscrollLiveSession(
        type: 'session_started',
        id: 's-start-1',
        packageName: 'com.ss.android.ugc.trill',
        appName: 'TikTok',
        startedAt: testStartTime,
        durationMillis: 0,
        swipeCount: 1,
        downwardSwipeCount: 1,
        upwardSwipeCount: 0,
        avgInterSwipeMillis: 0,
        isActive: true,
      ));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(controller.activeSession.value, isNotNull);
      expect(controller.activeSession.value!.appName, 'TikTok');
      expect(controller.activeSession.value!.swipeCount, 1);

      // 2. Kirim event session_updated
      fakeRepo.liveController.add(DoomscrollLiveSession(
        type: 'session_updated',
        id: 's-start-1',
        packageName: 'com.ss.android.ugc.trill',
        appName: 'TikTok',
        startedAt: testStartTime,
        durationMillis: 5000,
        swipeCount: 5,
        downwardSwipeCount: 4,
        upwardSwipeCount: 1,
        avgInterSwipeMillis: 1250,
        isActive: true,
      ));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(controller.activeSession.value!.swipeCount, 5);
      expect(controller.activeSession.value!.downwardSwipeCount, 4);

      // 3. Masukkan sesi ke antrean native sebelum session_finished dikirim
      fakeRepo.pendingNative = [
        DoomscrollSessionModel(
          id: 's-start-1',
          packageName: 'com.ss.android.ugc.trill',
          appName: 'TikTok',
          startedAt: testStartTime,
          endedAt: testStartTime.add(const Duration(seconds: 5)),
          durationMillis: 5000,
          swipeCount: 5,
          downwardSwipeCount: 4,
          upwardSwipeCount: 1,
          avgInterSwipeMillis: 1250,
          collectedAt: DateTime.now(),
        ),
      ];

      // 4. Kirim event session_finished
      fakeRepo.liveController.add(DoomscrollLiveSession(
        type: 'session_finished',
        id: 's-start-1',
        packageName: 'com.ss.android.ugc.trill',
        appName: 'TikTok',
        startedAt: testStartTime,
        durationMillis: 5000,
        swipeCount: 5,
        downwardSwipeCount: 4,
        upwardSwipeCount: 1,
        avgInterSwipeMillis: 1250,
        isActive: false,
      ));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // activeSession dibersihkan
      expect(controller.activeSession.value, isNull);
      // History dimuat ulang dan pending native berhasil dikumpulkan ke DB
      expect(controller.sessions.length, 1);
      expect(controller.sessions.first.id, 's-start-1');
      expect(controller.totalSwipes.value, 5);
    });

    test('Controller membatalkan stream subscription saat onClose tanpa memory leak',
        () async {
      final controller = Get.put(DoomscrollController(
        repository: fakeRepo,
        syncManager: fakeSyncManager,
      ));
      await controller.initialCheckAndLoad();

      expect(fakeRepo.liveController.hasListener, isTrue);

      controller.onClose();

      expect(fakeRepo.liveController.hasListener, isFalse);
    });
  });
}
