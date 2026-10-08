import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mind_drji/app/data/local/app_database.dart';
import 'package:mind_drji/app/data/local/repositories/intervention_history_local_repository.dart';
import 'package:mind_drji/app/data/models/intervention_model.dart';
import 'package:mind_drji/app/data/providers/intervention_native_provider.dart';
import 'package:mind_drji/app/data/services/intervention_service.dart';
import 'package:mind_drji/app/modules/intervention/controllers/intervention_controller.dart';
import 'package:mind_drji/app/modules/intervention/views/intervention_view.dart';

class MockInterventionNativeProvider extends InterventionNativeProvider {
  Map<String, dynamic>? storedStatus;
  bool startCalled = false;
  bool stopCalled = false;
  String? lastStartedId;
  int? lastStartedDuration;

  @override
  Future<bool> startDigitalBreak({
    required String id,
    required int durationMinutes,
    required int endTimestampMillis,
  }) async {
    startCalled = true;
    lastStartedId = id;
    lastStartedDuration = durationMinutes;
    final now = DateTime.now();
    storedStatus = {
      'id': id,
      'type': 'digitalBreak',
      'title': 'Jeda Digital',
      'durationMinutes': durationMinutes,
      'startedAt': now.toIso8601String(),
      'endedAt': DateTime.fromMillisecondsSinceEpoch(endTimestampMillis)
          .toIso8601String(),
      'status': 'active',
      'createdAt': now.toIso8601String(),
    };
    return true;
  }

  @override
  Future<bool> stopDigitalBreak() async {
    stopCalled = true;
    storedStatus = null;
    return true;
  }

  @override
  Future<Map<String, dynamic>?> getInterventionStatus() async {
    return storedStatus;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late InterventionHistoryLocalRepository historyRepo;
  late MockInterventionNativeProvider mockNative;
  late InterventionService service;
  late InterventionController controller;

  setUp(() {
    Get.reset();
    db = AppDatabase(NativeDatabase.memory());
    historyRepo = InterventionHistoryLocalRepository(db: db);
    Get.put<AppDatabase>(db);
    Get.put<InterventionHistoryLocalRepository>(historyRepo);

    mockNative = MockInterventionNativeProvider();
    service = InterventionService(
      nativeProvider: mockNative,
      historyRepository: historyRepo,
    );
    Get.put<InterventionService>(service);

    controller = InterventionController(interventionService: service);
    Get.put<InterventionController>(controller);
  });

  tearDown(() async {
    await db.close();
    Get.reset();
  });

  group('SUBFITUR 1: JEDA DIGITAL (UNIT & SERVICE TESTS)', () {
    test('1. Memulai Jeda Digital 5 menit: Model & Native payload tepat', () async {
      await controller.startDigitalBreak(5);

      expect(service.isActive.value, isTrue);
      expect(controller.isActive, isTrue);
      expect(service.activeIntervention.value?.type, InterventionType.digitalBreak);
      expect(service.activeIntervention.value?.title, 'Jeda Digital');
      expect(service.activeIntervention.value?.durationMinutes, 5);
      expect(service.remainingSeconds.value, inInclusiveRange(295, 300));
      expect(mockNative.startCalled, isTrue);
      expect(mockNative.lastStartedDuration, 5);

      // Verifikasi tersimpan di SQLite
      final list = await historyRepo.getRecent(userId: 'local_user');
      expect(list.length, 1);
      expect(list.first.status, InterventionStatus.active);
      expect(list.first.durationMinutes, 5);
    });

    test('2. Memulai Jeda Digital 15, 30, dan 60 menit', () async {
      // 15 Menit
      await controller.startDigitalBreak(15);
      expect(service.activeIntervention.value?.durationMinutes, 15);
      expect(service.remainingSeconds.value, inInclusiveRange(895, 900));

      // 30 Menit (Otomatis membatalkan sesi 15m sebelumnya)
      await controller.startDigitalBreak(30);
      expect(service.activeIntervention.value?.durationMinutes, 30);
      expect(service.remainingSeconds.value, inInclusiveRange(1795, 1800));

      // 60 Menit
      await controller.startDigitalBreak(60);
      expect(service.activeIntervention.value?.durationMinutes, 60);
      expect(service.remainingSeconds.value, inInclusiveRange(3595, 3600));

      // Database harus mencatat 3 sesi (2 dibatalkan, 1 aktif)
      final all = await historyRepo.getRecent(userId: 'local_user');
      expect(all.length, 3);
      expect(all.where((s) => s.status == InterventionStatus.cancelled).length, 2);
      expect(all.where((s) => s.status == InterventionStatus.active).length, 1);
    });

    test('3. Format waktu mundur mm:ss dan kalkulasi progres persentase', () async {
      final now = DateTime.now();
      final model = InterventionModel(
        id: 'test_progress',
        type: InterventionType.digitalBreak,
        title: 'Jeda Digital',
        durationMinutes: 10,
        startedAt: now.subtract(const Duration(minutes: 5)),
        endedAt: now.add(const Duration(minutes: 5)),
        status: InterventionStatus.active,
        createdAt: now.subtract(const Duration(minutes: 5)),
      );

      await service.startIntervention(model);

      // 5 menit tersisa = ~300 detik
      expect(controller.remainingSeconds, inInclusiveRange(298, 300));
      expect(controller.formattedRemainingTime, matches(RegExp(r'^0[45]:\d\d$')));
      expect(controller.progress, closeTo(0.5, 0.05));
    });

    test('4. Batalkan Jeda Digital: Status cancelled dan timestamp tercatat', () async {
      await controller.startDigitalBreak(15);
      expect(service.isActive.value, isTrue);

      await controller.cancel();

      expect(service.isActive.value, isFalse);
      expect(controller.isActive, isFalse);
      expect(service.remainingSeconds.value, 0);
      expect(service.activeIntervention.value?.status, InterventionStatus.cancelled);
      expect(service.activeIntervention.value?.cancelledAt, isNotNull);
      expect(mockNative.stopCalled, isTrue);

      final dbRecord = await historyRepo.getById(
        service.activeIntervention.value!.id,
        userId: 'local_user',
      );
      expect(dbRecord?.status, InterventionStatus.cancelled);
    });

    test('5. Selesaikan Jeda Digital: Status completed dan timestamp endedAt tersimpan', () async {
      await controller.startDigitalBreak(5);
      expect(service.isActive.value, isTrue);

      await controller.complete();

      expect(service.isActive.value, isFalse);
      expect(service.remainingSeconds.value, 0);
      expect(service.activeIntervention.value?.status, InterventionStatus.completed);
      expect(mockNative.stopCalled, isTrue);

      final dbRecord = await historyRepo.getById(
        service.activeIntervention.value!.id,
        userId: 'local_user',
      );
      expect(dbRecord?.status, InterventionStatus.completed);
    });

    test('6. Lifecycle resilient: Aplikasi minimize / background tidak mereset countdown', () async {
      await controller.startDigitalBreak(15);

      // Simulasi app masuk paused
      service.handleLifecycle(AppLifecycleState.paused);
      expect(service.isActive.value, isTrue);

      // Simulasi app kembali resumed
      service.handleLifecycle(AppLifecycleState.resumed);
      expect(service.isActive.value, isTrue);
      expect(service.remainingSeconds.value, inInclusiveRange(890, 900));
    });

    test('7. Cold restart recovery: Memulihkan sesi aktif dari storage native saat dibuka ulang', () async {
      final now = DateTime.now();
      mockNative.storedStatus = {
        'id': 'cold_restored_break',
        'type': 'digitalBreak',
        'title': 'Jeda Digital',
        'durationMinutes': 15,
        'startedAt': now.toIso8601String(),
        'endedAt': now.add(const Duration(minutes: 8)).toIso8601String(),
        'status': 'active',
        'createdAt': now.toIso8601String(),
      };

      await service.restoreActiveIntervention();

      expect(service.isActive.value, isTrue);
      expect(service.activeIntervention.value?.id, 'cold_restored_break');
      expect(service.remainingSeconds.value, inInclusiveRange(470, 480));
    });
  });

  group('SUBFITUR 1: JEDA DIGITAL (WIDGET & UI FLOW TESTS)', () {
    testWidgets('8. UI Hub: Memilih durasi 5m dan memulai Jeda Digital', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const GetMaterialApp(
          home: InterventionView(),
        ),
      );
      await tester.pumpAndSettle();

      // Pastikan bagian Jeda Digital tampil dengan 4 chip pilihan
      expect(find.text('Jeda Digital'), findsOneWidget);
      expect(find.text('5 mnt'), findsOneWidget);
      expect(find.text('15 mnt'), findsOneWidget);
      expect(find.text('30 mnt'), findsOneWidget);
      expect(find.text('60 mnt'), findsOneWidget);
      expect(find.text('Mulai Jeda Digital'), findsOneWidget);

      // Klik chip 5 mnt
      await tester.tap(find.text('5 mnt'));
      await tester.pump();

      // Klik Mulai Jeda Digital
      await tester.tap(find.text('Mulai Jeda Digital'));
      await tester.pumpAndSettle();

      // Layar beralih ke state aktif
      expect(find.text('Jeda Digital Aktif'), findsOneWidget);
      expect(find.text('Sisa Waktu'), findsOneWidget);
      expect(find.text('Saran Selama Intervensi'), findsOneWidget);
      expect(find.text('Minum segelas air putih.'), findsOneWidget);
      expect(find.text('Batalkan'), findsOneWidget);
      expect(find.text('Selesai'), findsOneWidget);
    });

    testWidgets('9. UI Active: Konfirmasi dialog batal dan kembali ke hub', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await service.startDigitalBreak(15);

      await tester.pumpWidget(
        const GetMaterialApp(
          home: InterventionView(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Jeda Digital Aktif'), findsOneWidget);

      // Klik tombol Batalkan
      await tester.tap(find.text('Batalkan'));
      await tester.pumpAndSettle();

      // Dialog konfirmasi muncul
      expect(find.text('Batalkan Intervensi?'), findsOneWidget);
      expect(find.text('Apakah kamu yakin ingin mengakhiri sesi lebih awal?'), findsOneWidget);
      expect(find.text('Lanjutkan Sesi'), findsOneWidget);

      // Klik konfirmasi batal
      final confirmCancelBtn = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Batalkan'),
      );
      await tester.tap(confirmCancelBtn);
      await tester.pumpAndSettle();

      // UI kembali ke hub
      expect(find.text('Jeda Digital Aktif'), findsNothing);
      expect(find.text('Atur Penggunaan Digital'), findsOneWidget);
      expect(service.isActive.value, isFalse);
    });

    testWidgets('10. UI Active: Klik Selesai menyelesaikan sesi langsung', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await service.startDigitalBreak(15);

      await tester.pumpWidget(
        const GetMaterialApp(
          home: InterventionView(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Jeda Digital Aktif'), findsOneWidget);

      // Klik tombol Selesai
      await tester.tap(find.text('Selesai'));
      await tester.pumpAndSettle();

      // UI kembali ke hub
      expect(find.text('Jeda Digital Aktif'), findsNothing);
      expect(find.text('Atur Penggunaan Digital'), findsOneWidget);
      expect(service.isActive.value, isFalse);
    });
  });
}
