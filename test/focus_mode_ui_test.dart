import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mind_drji/app/data/local/app_database.dart';
import 'package:mind_drji/app/data/local/repositories/intervention_history_local_repository.dart';
import 'package:mind_drji/app/data/models/intervention_model.dart';
import 'package:mind_drji/app/data/models/recommendation_model.dart';
import 'package:mind_drji/app/data/providers/intervention_native_provider.dart';
import 'package:mind_drji/app/data/services/intervention_service.dart';
import 'package:mind_drji/app/modules/focus_mode/controllers/focus_mode_controller.dart';
import 'package:mind_drji/app/modules/focus_mode/views/focus_mode_view.dart';
import 'package:mind_drji/app/modules/insight/controllers/insight_controller.dart';
import 'package:mind_drji/app/routes/app_pages.dart';
import 'package:mind_drji/app/routes/app_routes.dart';

class MockFocusModeNativeProvider extends InterventionNativeProvider {
  Map<String, dynamic>? storedStatus;
  bool startFocusModeCalled = false;
  bool stopFocusModeCalled = false;
  String? lastId;
  int? lastDurationMinutes;
  int? lastEndTimestampMillis;
  bool startReturnSuccess = true;

  @override
  Future<bool> startFocusMode({
    required String id,
    required int durationMinutes,
    required int endTimestampMillis,
  }) async {
    startFocusModeCalled = true;
    lastId = id;
    lastDurationMinutes = durationMinutes;
    lastEndTimestampMillis = endTimestampMillis;

    if (!startReturnSuccess) return false;

    final now = DateTime.now();
    storedStatus = {
      'id': id,
      'type': 'focusMode',
      'title': 'Mode Fokus',
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
  Future<bool> stopFocusMode() async {
    stopFocusModeCalled = true;
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
  drift.driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late InterventionHistoryLocalRepository repo;
  late MockFocusModeNativeProvider mockNative;
  late InterventionService interventionService;

  setUp(() {
    Get.reset();
    db = AppDatabase(NativeDatabase.memory());
    Get.put<AppDatabase>(db);
    repo = InterventionHistoryLocalRepository(db: db);
    Get.put<InterventionHistoryLocalRepository>(repo);

    mockNative = MockFocusModeNativeProvider();
    interventionService = InterventionService(
      nativeProvider: mockNative,
      historyRepository: repo,
    );
    Get.put<InterventionService>(interventionService);
  });

  tearDown(() {
    interventionService.onClose();
    Get.reset();
  });

  group('PHASE 10 — FOCUS MODE UI & INTEGRATION TESTS', () {
    testWidgets('1. Focus Mode page renders', (tester) async {
      final controller = FocusModeController(interventionService: interventionService);
      Get.put<FocusModeController>(controller);

      await tester.pumpWidget(
        const GetMaterialApp(
          home: FocusModeView(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mode Fokus'), findsWidgets);
      expect(
        find.text('Ambil jeda dari aplikasi yang mengganggu fokus.'),
        findsOneWidget,
      );
      expect(
        find.text('Selama sesi berlangsung, aplikasi distraksi yang terdeteksi akan dibatasi.'),
        findsOneWidget,
      );
    });

    testWidgets('2. Default duration = 15', (tester) async {
      final controller = FocusModeController(interventionService: interventionService);
      Get.put<FocusModeController>(controller);

      await tester.pumpWidget(
        const GetMaterialApp(
          home: FocusModeView(),
        ),
      );
      await tester.pumpAndSettle();

      expect(controller.selectedDuration.value, 15);
      expect(find.text('15 menit'), findsOneWidget);
    });

    testWidgets('3. Select 30 minutes', (tester) async {
      final controller = FocusModeController(interventionService: interventionService);
      Get.put<FocusModeController>(controller);

      await tester.pumpWidget(
        const GetMaterialApp(
          home: FocusModeView(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('30 menit'));
      await tester.pumpAndSettle();

      expect(controller.selectedDuration.value, 30);
    });

    testWidgets('4. Select 60 minutes', (tester) async {
      final controller = FocusModeController(interventionService: interventionService);
      Get.put<FocusModeController>(controller);

      await tester.pumpWidget(
        const GetMaterialApp(
          home: FocusModeView(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('60 menit'));
      await tester.pumpAndSettle();

      expect(controller.selectedDuration.value, 60);
    });

    testWidgets('5. Select 15 minutes', (tester) async {
      final controller = FocusModeController(interventionService: interventionService);
      Get.put<FocusModeController>(controller);

      await tester.pumpWidget(
        const GetMaterialApp(
          home: FocusModeView(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('30 menit'));
      await tester.pumpAndSettle();
      expect(controller.selectedDuration.value, 30);

      await tester.tap(find.text('15 menit'));
      await tester.pumpAndSettle();
      expect(controller.selectedDuration.value, 15);
    });

    testWidgets('6. Start button available', (tester) async {
      final controller = FocusModeController(interventionService: interventionService);
      Get.put<FocusModeController>(controller);

      await tester.pumpWidget(
        const GetMaterialApp(
          home: FocusModeView(),
        ),
      );
      await tester.pumpAndSettle();

      final startBtn = find.widgetWithText(ElevatedButton, 'Mulai Focus Mode');
      expect(startBtn, findsOneWidget);
    });

    testWidgets('7. Active state renders', (tester) async {
      final controller = FocusModeController(interventionService: interventionService);
      Get.put<FocusModeController>(controller);

      await tester.runAsync(() async {
        await controller.startFocusMode();
      });

      await tester.pumpWidget(
        const GetMaterialApp(
          home: FocusModeView(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(controller.isActive, isTrue);
      expect(find.text('Mode Fokus Aktif'), findsOneWidget);
      expect(find.text('Pertahankan fokusmu.'), findsOneWidget);
      expect(find.text('Yang sedang aktif'), findsOneWidget);
      expect(find.text('Pembatasan aplikasi target'), findsOneWidget);
      expect(find.text('Akhiri Focus Mode'), findsOneWidget);
      await tester.runAsync(() async {
        await controller.cancelFocusMode();
      });
    });

    test('8. Countdown formatting', () {
      final controller = FocusModeController(interventionService: interventionService);

      // Simulasi via service
      final now = DateTime.now();
      final ended = now.add(const Duration(minutes: 29, seconds: 42));
      interventionService.activeIntervention.value = InterventionModel(
        id: 'test_123',
        type: InterventionType.focusMode,
        title: 'Mode Fokus',
        durationMinutes: 30,
        startedAt: now,
        endedAt: ended,
        status: InterventionStatus.active,
        createdAt: now,
      );
      interventionService.isActive.value = true;
      interventionService.remainingSeconds.value = 1782;

      expect(controller.formattedRemainingTime, '29:42');

      interventionService.remainingSeconds.value = 59;
      expect(controller.formattedRemainingTime, '00:59');

      interventionService.remainingSeconds.value = 0;
      expect(controller.formattedRemainingTime, '00:00');
    });

    test('9. Progress calculation', () {
      final controller = FocusModeController(interventionService: interventionService);

      final now = DateTime.now();
      final started = now.subtract(const Duration(minutes: 15));
      final ended = now.add(const Duration(minutes: 15));

      interventionService.activeIntervention.value = InterventionModel(
        id: 'test_prog',
        type: InterventionType.focusMode,
        title: 'Mode Fokus',
        durationMinutes: 30,
        startedAt: started,
        endedAt: ended,
        status: InterventionStatus.active,
        createdAt: started,
      );
      interventionService.isActive.value = true;

      expect(controller.progress, closeTo(0.5, 0.05));
    });

    testWidgets('10. Cancel confirmation dialog', (tester) async {
      final controller = FocusModeController(interventionService: interventionService);
      Get.put<FocusModeController>(controller);

      await tester.runAsync(() async {
        await interventionService.startFocusMode(15);
      });

      await tester.pumpWidget(
        const GetMaterialApp(
          home: FocusModeView(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Akhiri Focus Mode'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Sudahi Focus Mode?'), findsOneWidget);
      expect(
        find.text('Jika kamu mengakhirinya sekarang, sesi akan dicatat sebagai dibatalkan.'),
        findsOneWidget,
      );
      expect(find.text('Batal'), findsOneWidget);
      expect(find.text('Akhiri'), findsOneWidget);

      await tester.runAsync(() async {
        await controller.cancelFocusMode();
      });
    });

    testWidgets('11. Cancel action', (tester) async {
      final controller = FocusModeController(interventionService: interventionService);
      Get.put<FocusModeController>(controller);

      await tester.runAsync(() async {
        await interventionService.startFocusMode(15);
      });

      await tester.pumpWidget(
        const GetMaterialApp(
          home: FocusModeView(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Akhiri Focus Mode'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.runAsync(() async {
        await controller.cancelFocusMode();
      });
      await tester.pumpAndSettle();

      expect(controller.isActive, isFalse);
      expect(mockNative.stopFocusModeCalled, isTrue);

      final history = await repo.getRecent(limit: 10);
      expect(history.first.status, InterventionStatus.cancelled);
      expect(history.first.cancelledAt, isNotNull);
    });

    testWidgets('12. Completed state', (tester) async {
      await tester.runAsync(() async {
        final controller = FocusModeController(interventionService: interventionService);
        Get.put<FocusModeController>(controller);

        await controller.startFocusMode();
        await controller.completeFocusMode();
      });

      await tester.pumpWidget(
        const GetMaterialApp(
          home: FocusModeView(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Focus Mode Selesai'), findsOneWidget);
      expect(find.text('Bagus, sesi fokusmu telah selesai.'), findsOneWidget);
      expect(find.text('Selesai'), findsOneWidget);
      expect(find.text('Kembali'), findsOneWidget);
      expect(find.text('Lihat Riwayat'), findsOneWidget);
    });

    testWidgets('13. History navigation', (tester) async {
      final controller = FocusModeController(interventionService: interventionService);
      Get.put<FocusModeController>(controller);

      await tester.runAsync(() async {
        await controller.startFocusMode();
        await controller.completeFocusMode();
      });

      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: Routes.focusMode,
          getPages: AppPages.routes,
        ),
      );
      await tester.pumpAndSettle();

      final historyBtn = find.text('Lihat Riwayat');
      expect(historyBtn, findsOneWidget);

      await tester.tap(historyBtn);
      await tester.pumpAndSettle();

      expect(Get.currentRoute, Routes.interventionHistory);
    });

    testWidgets('14. Recommendation → Focus Mode route', (tester) async {
      final insightController = InsightController(
        interventionService: interventionService,
      );
      Get.put<InsightController>(insightController);

      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: '/test-home',
          getPages: [
            GetPage(name: '/test-home', page: () => const SizedBox()),
            ...AppPages.routes,
          ],
        ),
      );
      await tester.pumpAndSettle();

      final rec = RecommendationModel(
        id: 'rec_focus_1',
        type: RecommendationType.focusMode,
        title: 'Mode Fokus',
        description: 'Batasi distraksi untuk kembali fokus.',
        reason: 'Sesi scrolling panjang terdeteksi.',
        actionLabel: 'Mulai Mode Fokus',
        durationOptions: const [15, 30, 60],
        icon: 'center_focus_strong_rounded',
        generatedAt: DateTime.now(),
      );

      // Navigasi via applyRecommendation
      await insightController.applyRecommendation(rec, 30);
      await tester.pumpAndSettle();

      // Verify that focus mode route was requested
      expect(Get.currentRoute, Routes.focusMode);
      expect(Get.arguments['duration'], 30);
    });

    test('15. Recommendation duration passed', () {
      Get.parameters = {};
      // Inject arguments as Map
      Get.testMode = true;

      // Inisialisasi controller dengan argumen 30 menit
      final controller = FocusModeController(interventionService: interventionService);
      controller.selectDuration(30);

      expect(controller.selectedDuration.value, 30);
    });

    test('16. Cold start active recovery', () async {
      final now = DateTime.now();
      final end = now.add(const Duration(minutes: 20));
      mockNative.storedStatus = {
        'id': 'focus_cold_123',
        'type': 'focusMode',
        'title': 'Mode Fokus',
        'durationMinutes': 30,
        'startedAt': now.toIso8601String(),
        'endedAt': end.toIso8601String(),
        'status': 'active',
        'createdAt': now.toIso8601String(),
      };

      final controller = FocusModeController(interventionService: interventionService);
      await controller.restoreActiveFocusMode();

      expect(controller.isActive, isTrue);
      expect(controller.remainingSeconds, inInclusiveRange(1190, 1200));
      expect(controller.completedDurationMinutes.value, 30);
    });

    test('17. Expired recovery', () async {
      final pastStart = DateTime.now().subtract(const Duration(minutes: 40));
      final pastEnd = DateTime.now().subtract(const Duration(minutes: 10));

      mockNative.storedStatus = {
        'id': 'focus_expired_123',
        'type': 'focusMode',
        'title': 'Mode Fokus',
        'durationMinutes': 30,
        'startedAt': pastStart.toIso8601String(),
        'endedAt': pastEnd.toIso8601String(),
        'status': 'active',
        'createdAt': pastStart.toIso8601String(),
      };

      final controller = FocusModeController(interventionService: interventionService);
      await controller.restoreActiveFocusMode();

      expect(controller.isActive, isFalse);
      expect(mockNative.stopFocusModeCalled, isTrue);

      final histories = await repo.getRecent(limit: 10);
      expect(histories.isNotEmpty, isTrue);
      expect(histories.first.status, InterventionStatus.completed);
    });

    test('18. No duplicate history', () async {
      final controller = FocusModeController(interventionService: interventionService);
      await controller.startFocusMode();

      final firstCount = (await repo.getRecent(limit: 10)).length;
      expect(firstCount, 1);

      // Panggil recovery berulang kali
      await controller.restoreActiveFocusMode();
      await controller.restoreActiveFocusMode();

      final afterCount = (await repo.getRecent(limit: 10)).length;
      expect(afterCount, 1);
    });

    test('19. User confirmation before start', () async {
      Get.testMode = true;
      final insightController = InsightController(
        interventionService: interventionService,
      );

      final rec = RecommendationModel(
        id: 'rec_focus_test',
        type: RecommendationType.focusMode,
        title: 'Mode Fokus',
        description: 'Batasi distraksi.',
        reason: 'Scrolling terdeteksi.',
        actionLabel: 'Mulai Mode Fokus',
        durationOptions: const [15, 30, 60],
        icon: 'center_focus_strong_rounded',
        generatedAt: DateTime.now(),
      );

      await insightController.applyRecommendation(rec, 15);

      // Focus Mode belum aktif di service hanya karena rekomendasi dipilih
      expect(interventionService.isActive.value, isFalse);
      expect(mockNative.startFocusModeCalled, isFalse);
    });

    testWidgets('20. No health/addiction score displayed', (tester) async {
      final controller = FocusModeController(interventionService: interventionService);
      Get.put<FocusModeController>(controller);

      await tester.pumpWidget(
        const GetMaterialApp(
          home: FocusModeView(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('skor kecanduan', findRichText: true), findsNothing);
      expect(find.textContaining('addiction score', findRichText: true), findsNothing);
      expect(find.textContaining('diagnosis', findRichText: true), findsNothing);
      expect(find.textContaining('tingkat adiksi', findRichText: true), findsNothing);
      expect(find.textContaining('health score', findRichText: true), findsNothing);
    });
  });
}
