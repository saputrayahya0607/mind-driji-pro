import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import '../../../data/providers/doomscroll_native_provider.dart';
import '../../../data/providers/eye_monitoring_native_provider.dart';
import '../../../data/providers/usage_stats_provider.dart';
import '../../../data/services/device_service.dart';
import '../../../routes/app_routes.dart';

class PermissionGuideController extends GetxController
    with WidgetsBindingObserver {
  final UsageStatsProvider _usageStatsProvider;
  final DoomscrollNativeProvider _doomscrollProvider;
  final EyeMonitoringNativeProvider _eyeMonitoringProvider;
  final DeviceService _deviceService;

  PermissionGuideController({
    UsageStatsProvider? usageStatsProvider,
    DoomscrollNativeProvider? doomscrollProvider,
    EyeMonitoringNativeProvider? eyeMonitoringProvider,
    DeviceService? deviceService,
  })  : _usageStatsProvider = usageStatsProvider ?? UsageStatsProvider(),
        _doomscrollProvider = doomscrollProvider ?? DoomscrollNativeProvider(),
        _eyeMonitoringProvider =
            eyeMonitoringProvider ?? EyeMonitoringNativeProvider(),
        _deviceService = deviceService ?? DeviceService();

  final usageAccessGranted = false.obs;
  final accessibilityGranted = false.obs;
  final cameraGranted = false.obs;
  final notificationGranted = false.obs;
  final batteryOptimizationIgnored = false.obs;
  final deviceManufacturer = ''.obs;
  final isLoading = false.obs;

  int get totalPermission => 4;

  int get activeCount => [
        usageAccessGranted.value,
        accessibilityGranted.value,
        cameraGranted.value,
        notificationGranted.value,
      ].where((granted) => granted).length;

  bool get allGranted => activeCount == totalPermission;

  String get summaryCountText => '$activeCount dari $totalPermission izin aktif';

  String get summaryStatusText =>
      allGranted ? 'Monitoring siap digunakan' : 'Beberapa izin masih diperlukan';

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    checkAllPermissions();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      checkAllPermissions();
    }
  }

  /// Memeriksa status ke-4 izin secara berurutan dengan penanganan error aman
  Future<void> checkAllPermissions() async {
    isLoading.value = true;
    try {
      // 1. Usage Access
      try {
        usageAccessGranted.value =
            await _usageStatsProvider.checkUsageAccess();
      } catch (_) {
        usageAccessGranted.value = false;
      }

      // 2. Accessibility
      try {
        accessibilityGranted.value =
            await _doomscrollProvider.checkAccessibilityService();
      } catch (_) {
        accessibilityGranted.value = false;
      }

      // 3. Camera
      try {
        cameraGranted.value =
            await _eyeMonitoringProvider.checkCameraPermission();
      } catch (_) {
        cameraGranted.value = false;
      }

      // 4. Notification
      try {
        notificationGranted.value =
            await _eyeMonitoringProvider.checkNotificationPermission();
      } catch (_) {
        notificationGranted.value = false;
      }

      // 5. Battery Optimization & Device Manufacturer
      try {
        batteryOptimizationIgnored.value =
            await _deviceService.checkBatteryOptimization();
      } catch (_) {
        batteryOptimizationIgnored.value = true;
      }

      try {
        final info = await _deviceService.getDeviceInfo();
        deviceManufacturer.value = info.manufacturer;
      } catch (_) {}
    } finally {
      isLoading.value = false;
    }
  }

  /// Membuka Pengaturan Akses Penggunaan (Usage Access) Android
  Future<void> requestUsageAccess() async {
    try {
      await _usageStatsProvider.openUsageAccessSettings();
    } catch (_) {}
    await checkAllPermissions();
  }

  /// Membuka Pengaturan Aksesibilitas (Accessibility Service) Android
  Future<void> requestAccessibility() async {
    try {
      await _doomscrollProvider.openAccessibilitySettings();
    } catch (_) {}
    await checkAllPermissions();
  }

  /// Meminta izin Kamera Android (CameraX / MediaPipe)
  Future<void> requestCamera() async {
    try {
      await _eyeMonitoringProvider.requestCameraPermission();
    } catch (_) {}
    await checkAllPermissions();
  }

  /// Meminta izin Notifikasi Android (POST_NOTIFICATIONS)
  Future<void> requestNotification() async {
    try {
      await _eyeMonitoringProvider.requestNotificationPermission();
    } catch (_) {}
    await checkAllPermissions();
  }

  /// Meminta pengguna untuk menonaktifkan pembatasan baterai (Unrestricted Battery)
  Future<void> requestBatteryOptimization() async {
    try {
      await _deviceService.requestIgnoreBatteryOptimization();
    } catch (_) {}
    await checkAllPermissions();
  }

  /// Membuka halaman pengaturan Auto-Start / Background Start khusus vendor HP
  Future<void> openOemAutoStart() async {
    try {
      await _deviceService.openOemAutoStartSettings();
    } catch (_) {}
  }

  /// Navigasi ke halaman Monitoring existing
  void navigateToMonitoring() {
    Get.toNamed(Routes.monitoring);
  }
}
