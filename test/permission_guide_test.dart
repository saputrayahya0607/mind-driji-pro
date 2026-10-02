import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mind_drji/app/data/providers/doomscroll_native_provider.dart';
import 'package:mind_drji/app/data/providers/eye_monitoring_native_provider.dart';
import 'package:mind_drji/app/data/providers/usage_stats_provider.dart';
import 'package:mind_drji/app/modules/permission_guide/controllers/permission_guide_controller.dart';
import 'package:mind_drji/app/modules/permission_guide/views/permission_guide_view.dart';

class FakeUsageStatsProvider extends UsageStatsProvider {
  bool hasAccess = false;
  bool openSettingsCalled = false;
  bool shouldThrow = false;

  @override
  Future<bool> checkUsageAccess() async {
    if (shouldThrow) throw Exception('Platform error');
    return hasAccess;
  }

  @override
  Future<bool> openUsageAccessSettings() async {
    openSettingsCalled = true;
    if (shouldThrow) throw Exception('Platform error');
    return true;
  }
}

class FakeDoomscrollNativeProvider extends DoomscrollNativeProvider {
  bool isEnabled = false;
  bool openSettingsCalled = false;
  bool shouldThrow = false;

  @override
  Future<bool> checkAccessibilityService() async {
    if (shouldThrow) throw Exception('Platform error');
    return isEnabled;
  }

  @override
  Future<bool> openAccessibilitySettings() async {
    openSettingsCalled = true;
    if (shouldThrow) throw Exception('Platform error');
    return true;
  }
}

class FakeEyeMonitoringNativeProvider extends EyeMonitoringNativeProvider {
  bool cameraGranted = false;
  bool notificationGranted = false;
  bool requestCameraCalled = false;
  bool requestNotificationCalled = false;
  bool shouldThrowCamera = false;
  bool shouldThrowNotification = false;

  @override
  Future<bool> checkCameraPermission() async {
    if (shouldThrowCamera) throw Exception('Platform error');
    return cameraGranted;
  }

  @override
  Future<bool> requestCameraPermission() async {
    requestCameraCalled = true;
    if (shouldThrowCamera) throw Exception('Platform error');
    return cameraGranted;
  }

  @override
  Future<bool> checkNotificationPermission() async {
    if (shouldThrowNotification) throw Exception('Platform error');
    return notificationGranted;
  }

  @override
  Future<bool> requestNotificationPermission() async {
    requestNotificationCalled = true;
    if (shouldThrowNotification) throw Exception('Platform error');
    return notificationGranted;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeUsageStatsProvider fakeUsage;
  late FakeDoomscrollNativeProvider fakeDoomscroll;
  late FakeEyeMonitoringNativeProvider fakeEye;
  late PermissionGuideController controller;

  setUp(() {
    Get.reset();
    fakeUsage = FakeUsageStatsProvider();
    fakeDoomscroll = FakeDoomscrollNativeProvider();
    fakeEye = FakeEyeMonitoringNativeProvider();
  });

  tearDown(() {
    Get.reset();
  });

  PermissionGuideController createController() {
    controller = PermissionGuideController(
      usageStatsProvider: fakeUsage,
      doomscrollProvider: fakeDoomscroll,
      eyeMonitoringProvider: fakeEye,
    );
    Get.put<PermissionGuideController>(controller);
    return controller;
  }

  group('PermissionGuideController Unit Tests', () {
    test('1. Initial state: 0/4 izin aktif saat semua provider false', () async {
      fakeUsage.hasAccess = false;
      fakeDoomscroll.isEnabled = false;
      fakeEye.cameraGranted = false;
      fakeEye.notificationGranted = false;

      final ctrl = createController();
      await ctrl.checkAllPermissions();

      expect(ctrl.activeCount, 0);
      expect(ctrl.allGranted, isFalse);
      expect(ctrl.summaryCountText, '0 dari 4 izin aktif');
      expect(ctrl.summaryStatusText, 'Beberapa izin masih diperlukan');
    });

    test('2. Usage Access aktif terdeteksi dengan benar', () async {
      fakeUsage.hasAccess = true;
      final ctrl = createController();
      await ctrl.checkAllPermissions();

      expect(ctrl.usageAccessGranted.value, isTrue);
      expect(ctrl.accessibilityGranted.value, isFalse);
      expect(ctrl.cameraGranted.value, isFalse);
      expect(ctrl.notificationGranted.value, isFalse);
      expect(ctrl.activeCount, 1);
    });

    test('3. Accessibility aktif terdeteksi dengan benar', () async {
      fakeDoomscroll.isEnabled = true;
      final ctrl = createController();
      await ctrl.checkAllPermissions();

      expect(ctrl.accessibilityGranted.value, isTrue);
      expect(ctrl.usageAccessGranted.value, isFalse);
      expect(ctrl.activeCount, 1);
    });

    test('4. Camera aktif terdeteksi dengan benar', () async {
      fakeEye.cameraGranted = true;
      final ctrl = createController();
      await ctrl.checkAllPermissions();

      expect(ctrl.cameraGranted.value, isTrue);
      expect(ctrl.activeCount, 1);
    });

    test('5. Notification aktif terdeteksi dengan benar', () async {
      fakeEye.notificationGranted = true;
      final ctrl = createController();
      await ctrl.checkAllPermissions();

      expect(ctrl.notificationGranted.value, isTrue);
      expect(ctrl.activeCount, 1);
    });

    test('6. Semua aktif: activeCount == 4 dan allGranted == true', () async {
      fakeUsage.hasAccess = true;
      fakeDoomscroll.isEnabled = true;
      fakeEye.cameraGranted = true;
      fakeEye.notificationGranted = true;

      final ctrl = createController();
      await ctrl.checkAllPermissions();

      expect(ctrl.activeCount, 4);
      expect(ctrl.allGranted, isTrue);
      expect(ctrl.summaryCountText, '4 dari 4 izin aktif');
      expect(ctrl.summaryStatusText, 'Monitoring siap digunakan');
    });

    test('7. Sebagian aktif: activeCount < 4 dan allGranted == false', () async {
      fakeUsage.hasAccess = true;
      fakeDoomscroll.isEnabled = true;
      fakeEye.cameraGranted = false;
      fakeEye.notificationGranted = false;

      final ctrl = createController();
      await ctrl.checkAllPermissions();

      expect(ctrl.activeCount, 2);
      expect(ctrl.allGranted, isFalse);
      expect(ctrl.summaryCountText, '2 dari 4 izin aktif');
      expect(ctrl.summaryStatusText, 'Beberapa izin masih diperlukan');
    });

    test('8. Lifecycle resumed memicu checkAllPermissions() kembali', () async {
      fakeUsage.hasAccess = false;
      final ctrl = createController();
      await ctrl.checkAllPermissions();
      expect(ctrl.usageAccessGranted.value, isFalse);

      // Simulasikan user kembali dari settings setelah mengaktifkan izin
      fakeUsage.hasAccess = true;
      ctrl.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);

      expect(ctrl.usageAccessGranted.value, isTrue);
      expect(ctrl.activeCount, 1);
    });

    test('9. Action masing-masing memanggil native method yang tepat', () async {
      final ctrl = createController();

      await ctrl.requestUsageAccess();
      expect(fakeUsage.openSettingsCalled, isTrue);

      await ctrl.requestAccessibility();
      expect(fakeDoomscroll.openSettingsCalled, isTrue);

      await ctrl.requestCamera();
      expect(fakeEye.requestCameraCalled, isTrue);

      await ctrl.requestNotification();
      expect(fakeEye.requestNotificationCalled, isTrue);
    });

    test('10. Permission request gagal/exception ditangani dengan aman tanpa crash',
        () async {
      fakeUsage.shouldThrow = true;
      fakeDoomscroll.shouldThrow = true;
      fakeEye.shouldThrowCamera = true;
      fakeEye.shouldThrowNotification = true;

      final ctrl = createController();

      // Controller tidak boleh melempar unhandled exception
      await expectLater(ctrl.checkAllPermissions(), completes);
      expect(ctrl.usageAccessGranted.value, isFalse);
      expect(ctrl.accessibilityGranted.value, isFalse);
      expect(ctrl.cameraGranted.value, isFalse);
      expect(ctrl.notificationGranted.value, isFalse);
      expect(ctrl.activeCount, 0);

      // Action request juga tidak boleh crash
      await expectLater(ctrl.requestUsageAccess(), completes);
      await expectLater(ctrl.requestAccessibility(), completes);
      await expectLater(ctrl.requestCamera(), completes);
      await expectLater(ctrl.requestNotification(), completes);
    });
  });

  group('PermissionGuideView Widget Tests', () {
    testWidgets('11. Jika 4/4 izin aktif: CTA "Mulai Monitoring" muncul dan tidak ada tombol "Aktifkan"',
        (tester) async {
      fakeUsage.hasAccess = true;
      fakeDoomscroll.isEnabled = true;
      fakeEye.cameraGranted = true;
      fakeEye.notificationGranted = true;

      createController();

      await tester.pumpWidget(
        const GetMaterialApp(
          home: PermissionGuideView(),
        ),
      );
      await tester.pumpAndSettle();

      // CTA Mulai Monitoring muncul
      expect(find.byKey(const Key('btn_mulai_monitoring')), findsOneWidget);
      expect(find.text('Mulai Monitoring'), findsOneWidget);
      expect(find.text('4 dari 4 izin aktif'), findsOneWidget);
      expect(find.text('Monitoring siap digunakan'), findsOneWidget);

      // Tombol Aktifkan tidak muncul untuk permission yang sudah aktif
      expect(find.text('Aktifkan'), findsNothing);
      expect(find.text('Aktif'), findsNWidgets(4));
    });

    testWidgets('12. Jika belum lengkap: Tombol "Aktifkan" muncul untuk yang belum aktif, dan opsi kembali tersedia',
        (tester) async {
      fakeUsage.hasAccess = true;
      fakeDoomscroll.isEnabled = false;
      fakeEye.cameraGranted = false;
      fakeEye.notificationGranted = false;

      createController();

      await tester.pumpWidget(
        const GetMaterialApp(
          home: PermissionGuideView(),
        ),
      );
      await tester.pumpAndSettle();

      // Summary 1 dari 4 izin aktif
      expect(find.text('1 dari 4 izin aktif'), findsOneWidget);
      expect(find.text('Beberapa izin masih diperlukan'), findsOneWidget);

      // Status badge
      expect(find.text('Aktif'), findsOneWidget);
      expect(find.text('Belum aktif'), findsNWidgets(3));

      // 3 Tombol Aktifkan untuk yang belum aktif
      expect(find.text('Aktifkan'), findsNWidgets(3));

      // CTA Mulai Monitoring tidak muncul
      expect(find.byKey(const Key('btn_mulai_monitoring')), findsNothing);

      // Tombol navigasi non-blocking "Lanjutkan ke Aplikasi Nanti" tersedia
      expect(find.byKey(const Key('btn_kembali_aplikasi')), findsOneWidget);
    });
  });
}
