import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/app_usage_model.dart';
import '../../../data/repositories/usage_stats_repository.dart';
import '../../../data/sync/sync_manager.dart';

class ScreenTimeController extends GetxController with WidgetsBindingObserver {
  final UsageStatsRepository _repository;
  final SyncManager _syncManager;

  ScreenTimeController({
    UsageStatsRepository? repository,
    SyncManager? syncManager,
  })  : _repository = repository ??
            (Get.isRegistered<UsageStatsRepository>()
                ? Get.find<UsageStatsRepository>()
                : UsageStatsRepository()),
        _syncManager = syncManager ??
            (Get.isRegistered<SyncManager>()
                ? Get.find<SyncManager>()
                : SyncManager(autoStart: false));

  SyncManager get syncManager => _syncManager;

  final isLoading = false.obs;
  final hasUsageAccess = false.obs;
  final totalUsageMillis = 0.obs;
  final appUsages = <AppUsageModel>[].obs;
  final errorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    initialCheckAndLoad();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Selalu periksa ulang status izin saat aplikasi kembali ke foreground
      checkPermissionAndLoad();
    }
  }

  /// Alur inisialisasi awal saat halaman dibuka
  Future<void> initialCheckAndLoad() async {
    isLoading.value = true;
    errorMessage.value = null;
    await checkPermissionAndLoad();
    isLoading.value = false;
  }

  /// Memeriksa status izin; jika aktif, muat data penggunaan hari ini
  Future<void> checkPermissionAndLoad() async {
    try {
      final granted = await _repository.checkUsageAccess();
      hasUsageAccess.value = granted;

      if (granted) {
        await loadUsage();
      } else {
        totalUsageMillis.value = 0;
        appUsages.clear();
      }
    } catch (_) {
      errorMessage.value = 'Gagal memeriksa izin akses penggunaan.';
    }
  }

  /// Meminta pengguna membuka Pengaturan Android untuk mengaktifkan Usage Access
  Future<void> requestUsageAccess() async {
    final opened = await _repository.openUsageAccessSettings();
    if (!opened) {
      errorMessage.value =
          'Tidak dapat membuka pengaturan perangkat secara otomatis.';
    }
  }

  /// Mengambil data statistik penggunaan hari ini:
  /// Menyimpan ke SQLite lokal, lalu memicu sinkronisasi latar belakang jika online
  Future<void> loadUsage() async {
    try {
      errorMessage.value = null;
      final usageStats = await _repository.getTodayUsage();
      totalUsageMillis.value = usageStats.totalUsageMillis;
      appUsages.assignAll(usageStats.apps);

      // Perbarui status antrean sinkronisasi
      await _syncManager.refreshPendingCount();

      // Jika ada internet, lakukan sinkronisasi otomatis di latar belakang
      if (_syncManager.isOnline.value) {
        _syncManager.syncPendingData();
      }
    } catch (e) {
      // Fallback offline: coba baca dari database lokal
      try {
        final localStats = await _repository.getLocalTodayUsage();
        if (localStats != null) {
          totalUsageMillis.value = localStats.totalUsageMillis;
          appUsages.assignAll(localStats.apps);
          return;
        }
      } catch (_) {}
      errorMessage.value = 'Gagal memuat data penggunaan aplikasi.';
    }
  }

  /// Melakukan pembaruan ulang data penggunaan saat pull-to-refresh
  Future<void> refreshUsage() async {
    await checkPermissionAndLoad();
  }

  /// Melakukan sinkronisasi manual ke Supabase dengan umpan balik UI
  Future<void> manualSync() async {
    if (_syncManager.isSyncing.value) return;

    final success = await _syncManager.triggerManualSync();

    if (success) {
      Get.snackbar(
        'Sinkronisasi Berhasil',
        'Data waktu layar telah tersimpan di cloud.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF00BFA5),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      );
    } else {
      if (!_syncManager.isOnline.value) {
        Get.snackbar(
          'Mode Offline',
          'Data tersimpan aman di database lokal. Akan disinkronkan saat terhubung internet.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF627D98),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        );
      } else if (_syncManager.lastError.value != null) {
        Get.snackbar(
          'Sinkronisasi Tertunda',
          'Akan dicoba kembali secara otomatis saat jaringan stabil.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFE53E3E),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        );
      }
    }
  }
}
