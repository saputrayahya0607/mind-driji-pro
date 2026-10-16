import 'package:drift/drift.dart' as drift;
import 'dart:typed_data';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mind_drji/app/data/local/app_database.dart';
import 'package:mind_drji/app/data/local/repositories/doomscroll_local_repository.dart';
import 'package:mind_drji/app/data/local/repositories/eye_monitoring_local_repository.dart';
import 'package:mind_drji/app/data/local/repositories/intervention_history_local_repository.dart';
import 'package:mind_drji/app/data/models/app_usage_model.dart';
import 'package:mind_drji/app/data/models/profile_model.dart';
import 'package:mind_drji/app/data/providers/doomscroll_native_provider.dart';
import 'package:mind_drji/app/data/providers/eye_monitoring_native_provider.dart';
import 'package:mind_drji/app/data/providers/intervention_native_provider.dart';
import 'package:mind_drji/app/data/repositories/doomscroll_repository.dart';
import 'package:mind_drji/app/data/repositories/eye_monitoring_repository.dart';
import 'package:mind_drji/app/data/repositories/profile_repository.dart';
import 'package:mind_drji/app/data/repositories/usage_stats_repository.dart';
import 'package:mind_drji/app/data/services/eye_monitoring_service.dart';
import 'package:mind_drji/app/data/services/intervention_service.dart';
import 'package:mind_drji/app/modules/focus_mode/controllers/focus_mode_controller.dart';
import 'package:mind_drji/app/modules/focus_mode/views/focus_mode_view.dart';
import 'package:mind_drji/app/modules/home/controllers/home_controller.dart';
import 'package:mind_drji/app/modules/home/views/home_view.dart';
import 'package:mind_drji/app/modules/insight/controllers/insight_controller.dart';
import 'package:mind_drji/app/modules/insight/views/insight_view.dart';
import 'package:mind_drji/app/modules/intervention/controllers/intervention_controller.dart';
import 'package:mind_drji/app/modules/intervention/views/eye_relaxation_view.dart';
import 'package:mind_drji/app/modules/intervention/views/intervention_view.dart';
import 'package:mind_drji/app/modules/intervention_history/controllers/intervention_history_controller.dart';
import 'package:mind_drji/app/modules/intervention_history/views/intervention_history_view.dart';
import 'package:mind_drji/app/modules/monitoring/controllers/doomscroll_controller.dart';
import 'package:mind_drji/app/modules/monitoring/controllers/eye_monitoring_controller.dart';
import 'package:mind_drji/app/modules/monitoring/controllers/monitoring_controller.dart';
import 'package:mind_drji/app/modules/monitoring/controllers/screen_time_controller.dart';
import 'package:mind_drji/app/modules/monitoring/views/doomscroll_view.dart';
import 'package:mind_drji/app/modules/monitoring/views/eye_monitoring_view.dart';
import 'package:mind_drji/app/modules/monitoring/views/monitoring_view.dart';
import 'package:mind_drji/app/modules/monitoring/views/screen_time_view.dart';

// Mocks
class FakeProfileRepo implements ProfileRepository {
  @override
  Future<ProfileModel?> getMyProfile() async => const ProfileModel(
        id: 'test_user',
        email: 'user@test.com',
        namaLengkap: 'Budi Santoso',
      );
  @override
  Future<ProfileModel> updateMyProfile({
    String? namaLengkap,
    DateTime? tanggalLahir,
    String? noHp,
    String? jenisKelamin,
    bool clearTanggalLahir = false,
  }) async =>
      throw UnimplementedError();
}

class FakeUsageStatsRepo implements UsageStatsRepository {
  @override
  Future<bool> checkUsageAccess() async => true;
  @override
  Future<bool> openUsageAccessSettings() async => true;
  @override
  Future<UsageStatsModel> getTodayUsage() async => const UsageStatsModel(
        totalUsageMillis: 7200000,
        apps: [],
      );
  @override
  Future<UsageStatsModel?> getLocalTodayUsage() async => getTodayUsage();
  @override
  Future<UsageStatsModel> getUsageRange({
    required DateTime startTime,
    required DateTime endTime,
  }) async =>
      getTodayUsage();
  @override
  Future<void> saveDailySnapshot({UsageStatsModel? stats, DateTime? date}) async {}
  @override
  Future<int> claimLocalUsage(String authenticatedUserId) async => 0;
  @override
  Future<Uint8List?> getAppIcon(String packageName) async => null;
}

class FakeDoomNative extends DoomscrollNativeProvider {
  @override
  Future<bool> checkAccessibilityService() async => true;
}

class FakeEyeNative extends EyeMonitoringNativeProvider {
  @override
  Future<bool> checkCameraPermission() async => true;
  @override
  Future<bool> checkNotificationPermission() async => true;
}

class FakeInterventionNative extends InterventionNativeProvider {
  @override
  Future<bool> startDigitalBreak({
    required String id,
    required int durationMinutes,
    required int endTimestampMillis,
  }) async =>
      true;
  @override
  Future<bool> stopDigitalBreak() async => true;
  @override
  Future<bool> startFocusMode({
    required String id,
    required int durationMinutes,
    required int endTimestampMillis,
  }) async =>
      true;
  @override
  Future<bool> stopFocusMode() async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  drift.driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late InterventionHistoryLocalRepository histRepo;
  late InterventionService interService;

  setUp(() {
    Get.reset();
    db = AppDatabase(NativeDatabase.memory());
    Get.put<AppDatabase>(db);
    histRepo = InterventionHistoryLocalRepository(db: db);
    Get.put<InterventionHistoryLocalRepository>(histRepo);
    interService = InterventionService(
      nativeProvider: FakeInterventionNative(),
      historyRepository: histRepo,
    );
    Get.put<InterventionService>(interService);
  });

  tearDown(() {
    Get.reset();
  });

  group('FINAL REGRESSION AUDIT: RESPONSIVENESS & SCALING TESTS', () {
    testWidgets('1. HomeView renders without overflow on 360dp with 1.5x font scale',
        (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final homeCtrl = HomeController(
        profileRepository: FakeProfileRepo(),
        usageStatsRepository: FakeUsageStatsRepo(),
        interventionService: interService,
      );
      homeCtrl.profile.value = const ProfileModel(
        id: 'test_user',
        email: 'user@test.com',
        namaLengkap: 'Budi Santoso',
      );
      Get.put<HomeController>(homeCtrl);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 640),
            textScaler: TextScaler.linear(1.5),
          ),
          child: const GetMaterialApp(
            home: HomeView(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(HomeView), findsOneWidget);
    });

    testWidgets(
        '2. MonitoringView renders without overflow on 360dp with 1.5x font scale',
        (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final monCtrl = MonitoringController();
      Get.put<MonitoringController>(monCtrl);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 640),
            textScaler: TextScaler.linear(1.5),
          ),
          child: const GetMaterialApp(
            home: MonitoringView(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(MonitoringView), findsOneWidget);
    });

    testWidgets(
        '3. ScreenTimeView renders without overflow on 360dp with 1.5x font scale',
        (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final stCtrl = ScreenTimeController(
        repository: FakeUsageStatsRepo(),
      );
      Get.put<ScreenTimeController>(stCtrl);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 640),
            textScaler: TextScaler.linear(1.5),
          ),
          child: const GetMaterialApp(
            home: ScreenTimeView(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ScreenTimeView), findsOneWidget);
    });

    testWidgets(
        '4. DoomscrollView renders without overflow on 360dp with 1.5x font scale',
        (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final dsCtrl = DoomscrollController(
        repository: DoomscrollRepository(
          provider: FakeDoomNative(),
          localRepository: DoomscrollLocalRepository(db: db),
        ),
      );
      Get.put<DoomscrollController>(dsCtrl);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 640),
            textScaler: TextScaler.linear(1.5),
          ),
          child: const GetMaterialApp(
            home: DoomscrollView(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(DoomscrollView), findsOneWidget);
    });

    testWidgets(
        '5. EyeMonitoringView renders without overflow on 360dp with 1.5x font scale',
        (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final eyeCtrl = EyeMonitoringController(
        service: EyeMonitoringService(
          db: db,
          localRepository: EyeMonitoringLocalRepository(db: db),
          repository: EyeMonitoringRepository(
            localRepository: EyeMonitoringLocalRepository(db: db),
          ),
          autoStart: false,
        ),
      );
      Get.put<EyeMonitoringController>(eyeCtrl);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 640),
            textScaler: TextScaler.linear(1.5),
          ),
          child: const GetMaterialApp(
            home: EyeMonitoringView(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(EyeMonitoringView), findsOneWidget);
    });

    testWidgets(
        '6. InsightView renders without overflow on 360dp with 1.5x font scale',
        (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final insCtrl = InsightController(
        interventionService: interService,
      );
      Get.put<InsightController>(insCtrl);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 640),
            textScaler: TextScaler.linear(1.5),
          ),
          child: const GetMaterialApp(
            home: InsightView(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(InsightView), findsOneWidget);
    });

    testWidgets(
        '7. InterventionView renders without overflow on 360dp with 1.5x font scale',
        (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final intCtrl = InterventionController(
        interventionService: interService,
      );
      Get.put<InterventionController>(intCtrl);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 640),
            textScaler: TextScaler.linear(1.5),
          ),
          child: const GetMaterialApp(
            home: InterventionView(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(InterventionView), findsOneWidget);
    });

    testWidgets(
        '8. EyeRelaxationView renders without overflow on 360dp with 1.5x font scale',
        (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final intCtrl = InterventionController(
        interventionService: interService,
      );
      Get.put<InterventionController>(intCtrl);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 640),
            textScaler: TextScaler.linear(1.5),
          ),
          child: const GetMaterialApp(
            home: EyeRelaxationView(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(EyeRelaxationView), findsOneWidget);
    });

    testWidgets(
        '9. FocusModeView renders without overflow on 360dp with 1.5x font scale',
        (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final focCtrl = FocusModeController(
        interventionService: interService,
      );
      Get.put<FocusModeController>(focCtrl);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 640),
            textScaler: TextScaler.linear(1.5),
          ),
          child: const GetMaterialApp(
            home: FocusModeView(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(FocusModeView), findsOneWidget);
    });

    testWidgets(
        '10. InterventionHistoryView renders without overflow on 360dp with 1.5x font scale',
        (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final histCtrl = InterventionHistoryController(
        repo: histRepo,
      );
      Get.put<InterventionHistoryController>(histCtrl);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 640),
            textScaler: TextScaler.linear(1.5),
          ),
          child: const GetMaterialApp(
            home: InterventionHistoryView(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(InterventionHistoryView), findsOneWidget);
    });
  });
}
