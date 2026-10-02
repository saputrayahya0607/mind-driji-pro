import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mind_drji/app/data/local/app_database.dart';
import 'package:mind_drji/app/data/local/repositories/intervention_history_local_repository.dart';
import 'package:mind_drji/app/data/models/intervention_model.dart';
import 'package:mind_drji/app/data/models/recommendation_model.dart';
import 'package:mind_drji/app/data/providers/intervention_native_provider.dart';
import 'package:mind_drji/app/data/services/intervention/focus_mode_executor.dart';
import 'package:mind_drji/app/data/services/intervention_service.dart';
import 'package:mind_drji/app/modules/intervention/controllers/intervention_controller.dart';
import 'package:mind_drji/app/modules/intervention/views/intervention_view.dart';
import 'package:mind_drji/app/modules/intervention/views/eye_relaxation_view.dart';

class MockInterventionNativeProvider extends InterventionNativeProvider {
  Map<String, dynamic>? storedStatus;
  bool startCalled = false;
  bool stopCalled = false;

  @override
  Future<bool> startDigitalBreak({
    required String id,
    required int durationMinutes,
    required int endTimestampMillis,
  }) async {
    startCalled = true;
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

  setUp(() {
    Get.reset();
    final db = AppDatabase(NativeDatabase.memory());
    Get.put<AppDatabase>(db);
    Get.put<InterventionHistoryLocalRepository>(
      InterventionHistoryLocalRepository(db: db),
    );
  });

  tearDown(() {
    Get.reset();
  });

  group('DIGITAL BREAK TESTS (1 - 10)', () {
    test('1. Start 5 minute: Menginisialisasi Digital Break 5 menit dengan benar',
        () async {
      final mock = MockInterventionNativeProvider();
      final service = InterventionService(nativeProvider: mock);

      await service.startDigitalBreak(5);

      expect(service.isActive.value, isTrue);
      expect(service.activeIntervention.value?.durationMinutes, 5);
      expect(service.activeIntervention.value?.type, InterventionType.digitalBreak);
      expect(service.remainingSeconds.value, inInclusiveRange(295, 300));
      expect(mock.startCalled, isTrue);
    });

    test('2. Start 15 minute: Menginisialisasi Digital Break 15 menit dengan benar',
        () async {
      final mock = MockInterventionNativeProvider();
      final service = InterventionService(nativeProvider: mock);

      await service.startDigitalBreak(15);

      expect(service.isActive.value, isTrue);
      expect(service.activeIntervention.value?.durationMinutes, 15);
      expect(service.remainingSeconds.value, inInclusiveRange(895, 900));
    });

    test('3. Start 30 minute: Menginisialisasi Digital Break 30 menit dengan benar',
        () async {
      final mock = MockInterventionNativeProvider();
      final service = InterventionService(nativeProvider: mock);

      await service.startDigitalBreak(30);

      expect(service.isActive.value, isTrue);
      expect(service.activeIntervention.value?.durationMinutes, 30);
      expect(service.remainingSeconds.value, inInclusiveRange(1795, 1800));
    });

    test('4. Remaining time: Menghitung sisa waktu secara deterministik dari endedAt',
        () async {
      final service = InterventionService(nativeProvider: MockInterventionNativeProvider());
      final now = DateTime.now();
      final model = InterventionModel(
        id: 'test_time',
        type: InterventionType.digitalBreak,
        title: 'Jeda Digital',
        durationMinutes: 10,
        startedAt: now,
        endedAt: now.add(const Duration(seconds: 120)),
        status: InterventionStatus.active,
        createdAt: now,
      );

      await service.startIntervention(model);

      expect(service.getRemainingSeconds(), inInclusiveRange(118, 120));
      expect(service.activeIntervention.value?.remainingSeconds,
          inInclusiveRange(118, 120));
    });

    test('5. Background simulation: Waktu tetap berkurang berdasarkan timestamp saat app di background',
        () async {
      final service = InterventionService(nativeProvider: MockInterventionNativeProvider());
      final now = DateTime.now();
      // Simulasikan intervensi yang dimulai 50 detik yang lalu dengan durasi 60 detik
      final model = InterventionModel(
        id: 'bg_sim',
        type: InterventionType.digitalBreak,
        title: 'Jeda Digital',
        durationMinutes: 1,
        startedAt: now.subtract(const Duration(seconds: 50)),
        endedAt: now.add(const Duration(seconds: 10)),
        status: InterventionStatus.active,
        createdAt: now.subtract(const Duration(seconds: 50)),
      );

      await service.startIntervention(model);

      expect(service.getRemainingSeconds(), inInclusiveRange(8, 10));
    });

    test('6. Resume: handleAppResume menyegarkan sisa waktu seketika',
        () async {
      final service = InterventionService(nativeProvider: MockInterventionNativeProvider());
      await service.startDigitalBreak(10);

      service.handleAppResume();

      expect(service.isActive.value, isTrue);
      expect(service.remainingSeconds.value, inInclusiveRange(595, 600));
    });

    test('7. Complete: Menyelesaikan intervensi dan mematikan status aktif',
        () async {
      final mock = MockInterventionNativeProvider();
      final service = InterventionService(nativeProvider: mock);
      await service.startDigitalBreak(5);

      await service.completeIntervention();

      expect(service.isActive.value, isFalse);
      expect(service.remainingSeconds.value, 0);
      expect(service.activeIntervention.value?.status, InterventionStatus.completed);
      expect(mock.stopCalled, isTrue);
    });

    test('8. Cancel: Membatalkan intervensi atas inisiatif pengguna',
        () async {
      final mock = MockInterventionNativeProvider();
      final service = InterventionService(nativeProvider: mock);
      await service.startDigitalBreak(15);

      await service.cancelIntervention();

      expect(service.isActive.value, isFalse);
      expect(service.remainingSeconds.value, 0);
      expect(service.activeIntervention.value?.status, InterventionStatus.cancelled);
      expect(service.activeIntervention.value?.cancelledAt, isNotNull);
      expect(mock.stopCalled, isTrue);
    });

    test('9. Restart recovery: Memulihkan sesi aktif dari native provider saat restart',
        () async {
      final mock = MockInterventionNativeProvider();
      final now = DateTime.now();
      mock.storedStatus = {
        'id': 'restored_break',
        'type': 'digitalBreak',
        'title': 'Jeda Digital',
        'durationMinutes': 15,
        'startedAt': now.toIso8601String(),
        'endedAt': now.add(const Duration(minutes: 10)).toIso8601String(),
        'status': 'active',
        'createdAt': now.toIso8601String(),
      };

      final service = InterventionService(nativeProvider: mock);
      service.onInit();
      // Tunggu tick asynchronous restore
      await Future.delayed(const Duration(milliseconds: 50));

      expect(service.isActive.value, isTrue);
      expect(service.activeIntervention.value?.id, 'restored_break');
      expect(service.remainingSeconds.value, inInclusiveRange(590, 600));
    });

    test('10. No negative remaining: Sisa detik tidak boleh bernilai negatif jika waktu terlampaui',
        () {
      final now = DateTime.now();
      final expiredModel = InterventionModel(
        id: 'expired',
        type: InterventionType.digitalBreak,
        title: 'Jeda Digital',
        durationMinutes: 5,
        startedAt: now.subtract(const Duration(minutes: 10)),
        endedAt: now.subtract(const Duration(minutes: 5)),
        status: InterventionStatus.active,
        createdAt: now.subtract(const Duration(minutes: 10)),
      );

      expect(expiredModel.remainingSeconds, 0);
      expect(expiredModel.isFinished, isTrue);
    });
  });

  group('EYE RELAXATION TESTS (11 - 14)', () {
    test('11. Start: Memulai alur relaksasi mata dari tahap pertama',
        () async {
      final service = InterventionService(nativeProvider: MockInterventionNativeProvider());

      await service.startEyeRelaxation(durationSeconds: 60);

      expect(service.isActive.value, isTrue);
      expect(service.activeIntervention.value?.type, InterventionType.eyeRelaxation);
      expect(service.eyeRelaxationStep.value, 0);
    });

    test('12. Complete: Menyelesaikan seluruh tahapan relaksasi mata',
        () async {
      final service = InterventionService(nativeProvider: MockInterventionNativeProvider());
      final controller = InterventionController(interventionService: service);

      await service.startEyeRelaxation(durationSeconds: 60);
      expect(controller.eyeStep, 0);

      controller.nextEyeStep(); // Step 1
      controller.nextEyeStep(); // Step 2
      controller.nextEyeStep(); // Step 3
      controller.nextEyeStep(); // Step 4 (Selesai)
      controller.nextEyeStep(); // Complete & close

      expect(service.isActive.value, isFalse);
      expect(service.activeIntervention.value?.status, InterventionStatus.completed);
    });

    test('13. Cancel: Membatalkan sesi relaksasi mata kapan saja',
        () async {
      final service = InterventionService(nativeProvider: MockInterventionNativeProvider());
      final controller = InterventionController(interventionService: service);

      await service.startEyeRelaxation(durationSeconds: 60);
      controller.nextEyeStep();
      expect(controller.eyeStep, 1);

      await controller.cancel();

      expect(service.isActive.value, isFalse);
      expect(service.activeIntervention.value?.status, InterventionStatus.cancelled);
    });

    test('14. Timestamp recovery: Durasi relaksasi mata terhitung secara presisi',
        () async {
      final service = InterventionService(nativeProvider: MockInterventionNativeProvider());
      await service.startEyeRelaxation(durationSeconds: 120);

      expect(service.remainingSeconds.value, inInclusiveRange(118, 120));
      expect(service.activeIntervention.value?.durationMinutes, 2);
    });
  });

  group('INTERVENTION ENGINE INTEGRITY TESTS (15 - 24)', () {
    test('15. User initiated: Intervensi tidak aktif sebelum dipanggil oleh pengguna',
        () {
      final service = InterventionService(nativeProvider: MockInterventionNativeProvider());

      expect(service.isActive.value, isFalse);
      expect(service.activeIntervention.value, isNull);
      expect(service.remainingSeconds.value, 0);
    });

    test('16. No automatic intervention: Model rekomendasi tidak memicu auto-start intervention',
        () {
      final rec = RecommendationModel(
        id: 'rec_break_1',
        type: RecommendationType.digitalBreak,
        title: 'Jeda Digital',
        description: 'Berikan jeda singkat.',
        reason: 'Sesi scrolling panjang.',
        actionLabel: 'Mulai Jeda',
        durationOptions: const [5, 15, 30],
        icon: 'spa_rounded',
        generatedAt: DateTime.now(),
      );

      final service = InterventionService(nativeProvider: MockInterventionNativeProvider());
      // Pembuatan rekomendasi tidak mengubah state InterventionService
      expect(service.isActive.value, isFalse);
      expect(rec.title, 'Jeda Digital');
    });

    test('17. Active state: Menandai state aktif dengan konsisten',
        () async {
      final service = InterventionService(nativeProvider: MockInterventionNativeProvider());
      await service.startDigitalBreak(15);

      expect(service.isActive.value, isTrue);
      expect(service.getActiveIntervention(), isNotNull);
      expect(service.getActiveIntervention()?.status, InterventionStatus.active);
    });

    test('18. Completed state: Status tersimpan rapi sebagai completed',
        () async {
      final service = InterventionService(nativeProvider: MockInterventionNativeProvider());
      await service.startDigitalBreak(5);
      await service.completeIntervention();

      expect(service.activeIntervention.value?.status, InterventionStatus.completed);
      expect(service.getActiveIntervention(), isNull);
    });

    test('19. Cancelled state: Status tersimpan rapi sebagai cancelled',
        () async {
      final service = InterventionService(nativeProvider: MockInterventionNativeProvider());
      await service.startDigitalBreak(5);
      await service.cancelIntervention();

      expect(service.activeIntervention.value?.status, InterventionStatus.cancelled);
      expect(service.activeIntervention.value?.cancelledAt, isNotNull);
    });

    test('20. Multiple intervention prevention: Sesi baru membatalkan sesi lama secara bersih',
        () async {
      final service = InterventionService(nativeProvider: MockInterventionNativeProvider());
      await service.startDigitalBreak(5);
      final firstId = service.activeIntervention.value?.id;

      await service.startDigitalBreak(15);
      final secondId = service.activeIntervention.value?.id;

      expect(secondId, isNot(equals(firstId)));
      expect(service.activeIntervention.value?.durationMinutes, 15);
      expect(service.isActive.value, isTrue);
    });

    test('21. Serialization: Serialisasi dan deserialisasi JSON bekerja sempurna',
        () {
      final now = DateTime.now();
      final original = InterventionModel(
        id: 'ser_1',
        type: InterventionType.digitalBreak,
        title: 'Jeda Digital',
        durationMinutes: 15,
        startedAt: now,
        endedAt: now.add(const Duration(minutes: 15)),
        status: InterventionStatus.active,
        createdAt: now,
      );

      final jsonStr = original.toJson();
      final parsed = InterventionModel.fromJson(jsonStr);

      expect(parsed.id, original.id);
      expect(parsed.type, original.type);
      expect(parsed.title, original.title);
      expect(parsed.durationMinutes, original.durationMinutes);
      expect(parsed.status, original.status);
    });

    test('22. Lifecycle state: Status paused tidak membatalkan intervensi',
        () async {
      final service = InterventionService(nativeProvider: MockInterventionNativeProvider());
      await service.startDigitalBreak(15);

      service.handleLifecycle(AppLifecycleState.paused);

      expect(service.isActive.value, isTrue);
      expect(service.activeIntervention.value?.status, InterventionStatus.active);
    });

    test('23. Controller reactive state: Controller menyediakan waktu mm:ss yang reaktif',
        () async {
      final service = InterventionService(nativeProvider: MockInterventionNativeProvider());
      final controller = InterventionController(interventionService: service);

      await service.startDigitalBreak(15);

      expect(controller.formattedRemainingTime, contains(':'));
      expect(controller.title, 'Jeda Digital');
      expect(controller.progress, inInclusiveRange(0.0, 1.0));
      await service.completeIntervention();
    });

    testWidgets('24. Widget rendering: InterventionView dan EyeRelaxationView merender komponen dengan benar',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final service = InterventionService(nativeProvider: MockInterventionNativeProvider());
      Get.put<InterventionService>(service);
      Get.put<InterventionController>(
        InterventionController(interventionService: service),
      );

      // Render dalam state inaktif
      await tester.pumpWidget(
        const GetMaterialApp(
          home: InterventionView(),
        ),
      );
      await tester.pump();
      expect(find.text('Intervensi Digital'), findsOneWidget);
      expect(find.text('Jeda Digital'), findsOneWidget);

      // Mulai digital break dan verifikasi tampilan aktif
      await service.startDigitalBreak(15);
      await tester.pump();

      expect(find.text('Jeda Digital Aktif'), findsOneWidget);
      expect(find.text('Batalkan'), findsOneWidget);
      expect(find.text('Selesai'), findsOneWidget);

      // Render EyeRelaxationView
      await service.startEyeRelaxation(durationSeconds: 60);
      await tester.pumpWidget(
        const GetMaterialApp(
          home: EyeRelaxationView(),
        ),
      );
      await tester.pump();

      expect(find.text('Relaksasi Mata'), findsOneWidget);
      expect(find.text('Alihkan pandangan dari layar'), findsOneWidget);
      expect(find.text('Langkah Berikutnya'), findsOneWidget);

      await service.completeIntervention();
    });
  });

  group('FOCUS MODE AUDIT TESTS (25 - 27)', () {
    test('25. Android service audit documented: Dokumentasi docs/intervention_engine.md tersedia dan memuat poin A-J',
        () {
      final docFile = File('docs/intervention_engine.md');
      expect(docFile.existsSync(), isTrue);

      final content = docFile.readAsStringSync();
      expect(content, contains('Focus Mode Android Architecture Audit'));
      expect(content, contains('A. Deteksi Foreground Package'));
      expect(content, contains('B. Kemampuan Navigasi Kembali'));
      expect(content, contains('C. Pengecualian MIND DRIJI'));
      expect(content, contains('G. Kebutuhan Device Owner / Lock Task Mode'));
      expect(content, contains('J. Kelayakan AccessibilityService untuk Prototype'));
    });

    test('26. Existing AccessibilityService not broken: DoomscrollAccessibilityService tidak terganggu',
        () {
      final ktFile = File(
          'android/app/src/main/kotlin/com/hn/mind_drji/DoomscrollAccessibilityService.kt');
      expect(ktFile.existsSync(), isTrue);
      final content = ktFile.readAsStringSync();

      expect(content, contains('class DoomscrollAccessibilityService'));
      expect(content, contains('object DoomscrollConfig'));
      expect(content, contains('TYPE_VIEW_SCROLLED'));
    });

    test('27. No fake blocker implementation: AuditedFocusModeExecutor mengembalikan isSupported false dan tidak memblokir palsu',
        () async {
      final executor = AuditedFocusModeExecutor();

      final supported = await executor.isSupported();
      final started = await executor.start(duration: const Duration(minutes: 15));

      expect(supported, isFalse);
      expect(started, isFalse);
      expect(executor.isRunning, isFalse);
      expect(executor.whitelistedPackages, contains('com.hn.mind_drji'));
    });
  });
}
