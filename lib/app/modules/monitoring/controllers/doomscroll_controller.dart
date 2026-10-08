import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/local/app_database.dart';
import '../../../data/models/doomscroll_live_session.dart';
import '../../../data/repositories/doomscroll_repository.dart';
import '../../../data/sync/sync_manager.dart';

class DoomscrollController extends GetxController with WidgetsBindingObserver {
  final DoomscrollRepository _repository;
  final SyncManager _syncManager;

  DoomscrollController({
    DoomscrollRepository? repository,
    SyncManager? syncManager,
  })  : _repository = repository ??
            (Get.isRegistered<DoomscrollRepository>()
                ? Get.find<DoomscrollRepository>()
                : DoomscrollRepository()),
        _syncManager = syncManager ??
            (Get.isRegistered<SyncManager>()
                ? Get.find<SyncManager>()
                : SyncManager(autoStart: false));

  SyncManager get syncManager => _syncManager;

  final isLoading = false.obs;
  final isAccessibilityActive = false.obs;
  final sessions = <DoomscrollSessionData>[].obs;
  final totalSwipes = 0.obs;
  final totalDownwardSwipes = 0.obs;
  final totalUpwardSwipes = 0.obs;
  final errorMessage = RxnString();

  /// Sesi scrolling realtime yang sedang aktif di target aplikasi
  final activeSession = Rxn<DoomscrollLiveSession>();
  StreamSubscription<DoomscrollLiveSession>? _liveSessionSubscription;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _subscribeToLiveSessions();
    initialCheckAndLoad();
  }

  @override
  void onClose() {
    _liveSessionSubscription?.cancel();
    _liveSessionSubscription = null;
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  /// Berlangganan event sesi realtime langsung dari native AccessibilityService
  void _subscribeToLiveSessions() {
    _liveSessionSubscription = _repository.liveSessionStream().listen(
      (event) {
        if (event.type == 'session_started' || event.type == 'session_updated') {
          activeSession.value = event;
        } else if (event.type == 'session_finished') {
          activeSession.value = null;
          // Sesi berakhir: kumpulkan dari antrean native, simpan ke Drift, dan sinkronkan
          checkStatusAndCollect();
        }
      },
      onError: (_) {
        // Abaikan error stream agar tidak mengganggu stabilitas controller
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Periksa status dan kumpulkan sesi pending saat aplikasi dibuka kembali (dari target app maupun settings)
      checkStatusAndCollect();
    }
  }

  /// Alur awal saat halaman monitoring dibuka
  Future<void> initialCheckAndLoad() async {
    isLoading.value = true;
    errorMessage.value = null;
    await checkStatusAndCollect();
    isLoading.value = false;
  }

  /// Memeriksa status izin accessibility dan mengumpulkan sesi dari native queue
  Future<void> checkStatusAndCollect() async {
    try {
      final active = await _repository.checkAccessibilityService();
      isAccessibilityActive.value = active;

      // Ambil sesi baru dari antrean native SharedPreferences jika ada
      try {
        await _repository.collectAndPersistPendingSessions();
      } catch (_) {}

      // Selalu muat sesi yang sudah tersimpan di database lokal Drift
      await loadStoredSessions();
      await _syncManager.refreshPendingCount();
    } catch (e) {
      errorMessage.value = 'Gagal memuat status monitoring doomscrolling.';
    }
  }

  /// Membaca sesi dari Drift dan mengagregasi statistik sederhana
  Future<void> loadStoredSessions() async {
    final stored = await _repository.getStoredSessions();
    sessions.assignAll(stored);

    int swipes = 0;
    int downward = 0;
    int upward = 0;

    for (final s in stored) {
      swipes += s.swipeCount;
      downward += s.downwardSwipeCount;
      upward += s.upwardSwipeCount;
    }

    totalSwipes.value = swipes;
    totalDownwardSwipes.value = downward;
    totalUpwardSwipes.value = upward;
  }

  /// Meminta pengguna membuka pengaturan Accessibility Service di sistem Android
  Future<void> requestAccessibilityPermission() async {
    final opened = await _repository.openAccessibilitySettings();
    if (!opened) {
      errorMessage.value =
          'Tidak dapat membuka Pengaturan Aksesibilitas secara otomatis.';
    }
  }

  /// Refresh saat pull-to-refresh
  Future<void> refreshSessions() async {
    await checkStatusAndCollect();
  }

  /// Sinkronisasi manual dari tombol UI
  Future<void> manualSync() async {
    if (_syncManager.isSyncing.value) return;

    // Kumpulkan sesi yang baru saja selesai dari antrean native sebelum sync
    await checkStatusAndCollect();

    final success = await _syncManager.triggerManualSync();

    if (success) {
      await loadStoredSessions();
      Get.snackbar(
        'Sinkronisasi Berhasil',
        'Data sesi scrolling telah tersimpan di cloud.',
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
          'Data tersimpan aman di SQLite lokal. Akan disinkronkan saat terhubung internet.',
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
