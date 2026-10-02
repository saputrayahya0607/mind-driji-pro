import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/device_info_model.dart';
import '../../../data/models/profile_model.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../data/services/device_service.dart';
import '../../../routes/app_routes.dart';
import '../../home/controllers/home_controller.dart';
import '../../insight/controllers/insight_controller.dart';
import '../../intervention/controllers/intervention_controller.dart';
import '../../monitoring/controllers/monitoring_controller.dart';
import '../../../data/services/eye_monitoring_service.dart';
import '../../../data/services/intervention_service.dart';

class ProfileController extends GetxController {
  final ProfileRepository? _profileRepository;
  final SupabaseClient? _supabaseClient;
  final DeviceService? _deviceService;

  ProfileController({
    ProfileRepository? profileRepository,
    SupabaseClient? supabaseClient,
    DeviceService? deviceService,
  })  : _profileRepository = profileRepository,
        _supabaseClient = supabaseClient,
        _deviceService = deviceService;

  ProfileRepository get _repository {
    if (_profileRepository != null) return _profileRepository;
    if (Get.isRegistered<ProfileRepository>()) {
      return Get.find<ProfileRepository>();
    }
    return ProfileRepository();
  }

  DeviceService? get _device {
    if (_deviceService != null) return _deviceService;
    if (Get.isRegistered<DeviceService>()) {
      return Get.find<DeviceService>();
    }
    return null;
  }

  final isLoading = false.obs;
  final profile = Rxn<ProfileModel>();
  final errorMessage = RxnString();
  final currentDeviceInfo = Rxn<DeviceInfoModel>();

  @override
  void onInit() {
    super.onInit();
    loadProfile();
    loadDeviceInfo();
  }

  /// Memuat info perangkat saat ini
  Future<void> loadDeviceInfo() async {
    try {
      final dev = _device;
      if (dev != null) {
        final info = await dev.getDeviceInfo();
        currentDeviceInfo.value = info;
      }
    } catch (_) {}
  }

  /// Mengambil data profil milik pengguna yang sedang login.
  /// User ID diambil langsung dari Supabase Auth Client, bukan dari UI.
  Future<void> loadProfile() async {
    try {
      isLoading.value = true;
      errorMessage.value = null;

      String? userId;
      try {
        final client = _supabaseClient ?? Supabase.instance.client;
        userId = client.auth.currentUser?.id;
      } catch (_) {
        userId = null;
      }

      if (userId == null) {
        errorMessage.value = 'Data profil belum dapat dimuat.';
        profile.value = null;
        return;
      }

      final data = await _repository.getMyProfile();
      profile.value = data;
    } catch (_) {
      errorMessage.value = 'Data profil belum dapat dimuat.';
    } finally {
      isLoading.value = false;
    }
  }

  /// Logout dari Supabase Auth, membersihkan user state in-memory,
  /// dan navigasi ke halaman Login tanpa dapat kembali ke Home via back button.
  Future<void> logout() async {
    try {
      final client = _supabaseClient ?? Supabase.instance.client;
      await client.auth.signOut();
    } catch (_) {}

    // Bersihkan user-specific in-memory state
    profile.value = null;
    currentDeviceInfo.value = null;
    errorMessage.value = null;

    // Hentikan pemantauan latar belakang & intervensi aktif milik user saat ini
    if (Get.isRegistered<EyeMonitoringService>()) {
      try {
        final eye = Get.find<EyeMonitoringService>();
        await eye.disableMonitoring();
      } catch (_) {}
    }
    if (Get.isRegistered<InterventionService>()) {
      try {
        final intervention = Get.find<InterventionService>();
        await intervention.cancelIntervention();
      } catch (_) {}
    }

    // Bersihkan stale controller state agar tidak terjadi kebocoran data user antar-sesi
    if (Get.isRegistered<HomeController>()) {
      try {
        final home = Get.find<HomeController>();
        home.profile.value = null;
        home.errorMessage.value = null;
      } catch (_) {}
      Get.delete<HomeController>(force: true);
    }
    if (Get.isRegistered<MonitoringController>()) {
      Get.delete<MonitoringController>(force: true);
    }
    if (Get.isRegistered<InsightController>()) {
      Get.delete<InsightController>(force: true);
    }
    if (Get.isRegistered<InterventionController>()) {
      Get.delete<InterventionController>(force: true);
    }

    // Navigasi ke Login dan hapus seluruh backstack
    Get.offAllNamed(Routes.login);
  }

  /// Menampilkan dialog konfirmasi logout sesuai spesifikasi.
  Future<void> showLogoutConfirmation(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Keluar dari akun?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: const Text(
          'Anda harus login kembali untuk mengakses akun ini.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Batal',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Logout',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await logout();
    }
  }
}
