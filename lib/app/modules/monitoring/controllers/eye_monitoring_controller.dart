import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/eye_condition_analyzer.dart';
import '../../../data/local/app_database.dart';
import '../../../data/local/tables/sync_queue.dart';
import '../../../data/models/eye_monitoring_live_event.dart';
import '../../../data/models/eye_monitoring_session_model.dart';
import '../../../data/repositories/eye_monitoring_repository.dart';
import '../../../data/services/eye_monitoring_service.dart';
import '../../../data/sync/sync_manager.dart';

/// Controller GetX untuk Eye Monitoring (Pemantauan Mata).
///
/// Bertindak sebagai presenter/view-model yang membaca dan meneruskan state dari
/// [EyeMonitoringService] global ke UI.
///
/// Lifecycle page/controller ini dapat dibuat atau di-dispose kapan saja
/// saat user bernavigasi tanpa mengganggu scheduler atau sesi yang sedang berjalan.
class EyeMonitoringController extends GetxController with WidgetsBindingObserver {
  final EyeMonitoringRepository _repository;
  final SyncManager _syncManager;
  final EyeMonitoringService? _serviceInstance;

  EyeMonitoringController({
    EyeMonitoringRepository? repository,
    SyncManager? syncManager,
    EyeMonitoringService? service,
  })  : _repository = repository ?? _safeGetRepository(),
        _syncManager = syncManager ?? _safeGetSyncManager(),
        _serviceInstance = service;

  static EyeMonitoringRepository _safeGetRepository() {
    if (Get.isRegistered<EyeMonitoringRepository>()) {
      return Get.find<EyeMonitoringRepository>();
    }
    return EyeMonitoringRepository();
  }

  static SyncManager _safeGetSyncManager() {
    if (Get.isRegistered<SyncManager>()) {
      return Get.find<SyncManager>();
    }
    return SyncManager(autoStart: false);
  }

  EyeMonitoringService? get _service {
    if (_serviceInstance != null) return _serviceInstance;
    if (Get.isRegistered<EyeMonitoringService>()) {
      return Get.find<EyeMonitoringService>();
    }
    return null;
  }

  SyncManager get syncManager => _syncManager;
  EyeMonitoringService? get monitoringService => _service;

  // ===========================================================================
  // STATE REAKTIF (Terhubung ke EyeMonitoringService)
  // ===========================================================================
  final isLoading = false.obs;
  final isMonitoringEnabled = false.obs;
  final isMonitoring = false.obs; // true saat kamera fisik sedang aktif
  final cameraPermission = false.obs;

  final faceDetected = false.obs;
  final multipleFaces = false.obs;
  final currentEar = 0.0.obs;
  final averageEar = 0.0.obs;
  final minEar = 0.0.obs;
  final eyeClosureEvents = 0.obs;
  final blinkCount = 0.obs;
  final elapsedDuration = 0.obs;

  final nextScheduledAt = Rxn<DateTime>();
  final lastSessionCompletedAt = Rxn<DateTime>();

  final statusMessage = 'Monitoring mata belum aktif'.obs;
  final errorMessage = RxnString();

  final lastCompletedSession = Rxn<EyeMonitoringSessionModel>();
  final lastConditionResult = Rxn<EyeConditionResult>();
  final storedSessions = <EyeMonitoringSessionData>[].obs;

  final List<StreamSubscription> _serviceSubscriptions = [];
  StreamSubscription<EyeMonitoringLiveEvent>? _liveSubscription;

  @override
  void onInit() {
    super.onInit();
    try {
      WidgetsBinding.instance.addObserver(this);
    } catch (_) {}

    _bindToGlobalService();
    _subscribeToLiveEvents();
    _setupSyncListeners();
    initialCheck();
  }

  /// Menghubungkan observer controller ke service global
  void _bindToGlobalService() {
    final svc = _service;
    if (svc == null) return;

    // Inisialisasi nilai awal dari service
    isMonitoringEnabled.value = svc.isMonitoringEnabled.value;
    isMonitoring.value = svc.isSessionRunning.value;
    cameraPermission.value = svc.cameraPermission.value;
    faceDetected.value = svc.faceDetected.value;
    multipleFaces.value = svc.multipleFaces.value;
    currentEar.value = svc.currentEar.value;
    averageEar.value = svc.averageEar.value;
    minEar.value = svc.minEar.value;
    eyeClosureEvents.value = svc.eyeClosureEvents.value;
    blinkCount.value = svc.blinkCount.value;
    elapsedDuration.value = svc.elapsedDuration.value;
    statusMessage.value = svc.statusMessage.value;
    errorMessage.value = svc.errorMessage.value;
    nextScheduledAt.value = svc.nextScheduledAt.value;
    lastSessionCompletedAt.value = svc.lastSessionCompletedAt.value;
    if (svc.lastCompletedSession.value != null) {
      lastCompletedSession.value = svc.lastCompletedSession.value;
    }
    if (svc.lastConditionResult.value != null) {
      lastConditionResult.value = svc.lastConditionResult.value;
    }

    // Subscribe perubahan reaktif dari service
    _serviceSubscriptions.add(svc.isMonitoringEnabled.listen((v) {
      isMonitoringEnabled.value = v;
    }));
    _serviceSubscriptions.add(svc.isSessionRunning.listen((v) {
      isMonitoring.value = v;
    }));
    _serviceSubscriptions.add(svc.cameraPermission.listen((v) {
      cameraPermission.value = v;
    }));
    _serviceSubscriptions.add(svc.faceDetected.listen((v) {
      faceDetected.value = v;
    }));
    _serviceSubscriptions.add(svc.multipleFaces.listen((v) {
      multipleFaces.value = v;
    }));
    _serviceSubscriptions.add(svc.currentEar.listen((v) {
      currentEar.value = v;
    }));
    _serviceSubscriptions.add(svc.averageEar.listen((v) {
      averageEar.value = v;
    }));
    _serviceSubscriptions.add(svc.minEar.listen((v) {
      minEar.value = v;
    }));
    _serviceSubscriptions.add(svc.eyeClosureEvents.listen((v) {
      eyeClosureEvents.value = v;
    }));
    _serviceSubscriptions.add(svc.blinkCount.listen((v) {
      blinkCount.value = v;
    }));
    _serviceSubscriptions.add(svc.elapsedDuration.listen((v) {
      elapsedDuration.value = v;
    }));
    _serviceSubscriptions.add(svc.statusMessage.listen((v) {
      statusMessage.value = v;
    }));
    _serviceSubscriptions.add(svc.errorMessage.listen((v) {
      errorMessage.value = v;
    }));
    _serviceSubscriptions.add(svc.nextScheduledAt.listen((v) {
      nextScheduledAt.value = v;
    }));
    _serviceSubscriptions.add(svc.lastSessionCompletedAt.listen((v) {
      lastSessionCompletedAt.value = v;
    }));
    _serviceSubscriptions.add(svc.lastCompletedSession.listen((s) {
      if (s != null) {
        lastCompletedSession.value = s;
        loadStoredSessions();
      }
    }));
    _serviceSubscriptions.add(svc.lastConditionResult.listen((c) {
      lastConditionResult.value = c;
    }));
  }

  /// Memantau perubahan status sinkronisasi untuk memperbarui riwayat sesi secara otomatis
  void _setupSyncListeners() {
    ever(_syncManager.lastSyncTime, (_) => loadStoredSessions());
    ever(_syncManager.syncStatus, (status) {
      if (status == SyncStatus.synced || status == SyncStatus.failed) {
        loadStoredSessions();
      }
    });
  }

  @override
  void onClose() {
    for (final sub in _serviceSubscriptions) {
      sub.cancel();
    }
    _serviceSubscriptions.clear();

    _liveSubscription?.cancel();
    _liveSubscription = null;

    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (_) {}

    // PENTING: Jangan hentikan service monitoring di sini saat user berpindah halaman!
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (_service != null) {
        // Global EyeMonitoringService menangani lifecycle background secara terpusat
      } else {
        // Fallback untuk standalone controller / testing lingkungan terisolasi
        if (isMonitoring.value) {
          stopMonitoring();
        }
      }
    } else if (state == AppLifecycleState.resumed) {
      checkPermissionAndStatus();
      loadStoredSessions();
      _syncManager.refreshPendingCount();
    }
  }

  /// Inisialisasi awal saat halaman dibuka
  Future<void> initialCheck() async {
    isLoading.value = true;
    errorMessage.value = null;
    await checkPermissionAndStatus();
    await loadStoredSessions();
    await _syncManager.refreshPendingCount();
    isLoading.value = false;
  }

  /// Memeriksa status izin kamera dan status monitoring aktif
  Future<void> checkPermissionAndStatus() async {
    try {
      final svc = _service;
      if (svc != null) {
        final hasPerm = await svc.checkCameraPermission();
        cameraPermission.value = hasPerm;
        isMonitoringEnabled.value = svc.isMonitoringEnabled.value;
        isMonitoring.value = svc.isSessionRunning.value;
      } else {
        final hasPerm = await _repository.checkCameraPermission();
        cameraPermission.value = hasPerm;
        final isMon = await _repository.getStatus();
        isMonitoring.value = isMon;
      }
    } catch (_) {
      cameraPermission.value = false;
    }
  }

  /// Meminta izin kamera kepada pengguna
  Future<void> requestCameraPermission() async {
    try {
      final svc = _service;
      if (svc != null) {
        final granted = await svc.requestCameraPermission();
        cameraPermission.value = granted;
      } else {
        final granted = await _repository.requestCameraPermission();
        cameraPermission.value = granted;
      }
      if (!cameraPermission.value) {
        errorMessage.value =
            'Izin kamera diperlukan untuk mendeteksi indikator mata lelah.';
      } else {
        errorMessage.value = null;
      }
    } catch (_) {
      cameraPermission.value = false;
    }
  }

  /// Mengaktifkan Automatic Periodic Monitoring (User Action Utama)
  Future<void> enableMonitoring() async {
    final svc = _service;
    if (svc != null) {
      final success = await svc.enableMonitoring();
      if (success) {
        await loadStoredSessions();
      }
    } else {
      // Fallback jika dijalankan di isolated environment tanpa service
      await startMonitoring();
    }
  }

  /// Mematikan Monitoring secara permanen hingga user mengaktifkannya kembali
  Future<void> disableMonitoring() async {
    final svc = _service;
    if (svc != null) {
      await svc.disableMonitoring();
      await loadStoredSessions();
    } else {
      // Fallback jika dijalankan di isolated environment tanpa service
      await stopMonitoring();
    }
  }

  /// Menjalankan satu sesi kamera sekarang secara langsung (untuk testing/verifikasi manual)
  Future<void> startSessionNow() async {
    final svc = _service;
    if (svc != null) {
      await svc.triggerImmediateSession();
    } else {
      await startMonitoring();
    }
  }

  /// Memulai sesi pemantauan mata (mendukung pemanggilan legacy / testing)
  Future<void> startMonitoring() async {
    final svc = _service;
    if (svc != null) {
      await svc.enableMonitoring();
      return;
    }

    if (isMonitoring.value) return;

    if (!cameraPermission.value) {
      await requestCameraPermission();
      if (!cameraPermission.value) return;
    }

    isLoading.value = true;
    errorMessage.value = null;

    try {
      final started = await _repository.startMonitoring();
      if (started) {
        isMonitoring.value = true;
        faceDetected.value = false;
        multipleFaces.value = false;
        currentEar.value = 0.0;
        averageEar.value = 0.0;
        minEar.value = 0.0;
        eyeClosureEvents.value = 0;
        blinkCount.value = 0;
        elapsedDuration.value = 0;
        statusMessage.value = 'Monitoring aktif';
      } else {
        errorMessage.value = 'Gagal memulai monitoring kamera.';
      }
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('kamera depan') || msg.contains('kamera')) {
        errorMessage.value =
            'Perangkat tidak memiliki kamera depan yang kompatibel.';
      } else {
        errorMessage.value = 'Terjadi kesalahan saat memulai monitoring mata.';
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Menghentikan pemantauan mata (mendukung pemanggilan legacy / testing)
  Future<void> stopMonitoring() async {
    final svc = _service;
    if (svc != null) {
      await svc.disableMonitoring();
      return;
    }

    if (!isMonitoring.value) return;

    isLoading.value = true;
    try {
      final session = await _repository.stopMonitoringAndPersist();
      isMonitoring.value = false;
      faceDetected.value = false;
      multipleFaces.value = false;
      statusMessage.value = 'Monitoring selesai';

      if (session != null) {
        lastCompletedSession.value = session;
        await loadStoredSessions();

        // Picu sinkronisasi cloud ke Supabase
        if (_syncManager.isOnline.value) {
          await _syncManager.refreshPendingCount();
          await _syncManager.syncPendingData();
          await loadStoredSessions();
        }
      }
    } catch (e) {
      errorMessage.value = 'Gagal menyelesaikan sesi monitoring mata.';
    } finally {
      isLoading.value = false;
    }
  }

  /// Berlangganan event live dari CameraX & MediaPipe (untuk fallback direct mode)
  void _subscribeToLiveEvents() {
    if (_service != null) return; // Jika service aktif, service yang mendistribusikan event

    _liveSubscription = _repository.liveEventStream().listen(
      (event) {
        if (event.type == 'status_update') {
          isMonitoring.value = event.isMonitoring;
          faceDetected.value = event.faceDetected;
          multipleFaces.value = event.multipleFaces;
          currentEar.value = event.currentEar;
          averageEar.value = event.averageEar;
          minEar.value = event.minEar;
          eyeClosureEvents.value = event.eyeClosureEvents;
          blinkCount.value = event.blinkCount;
          elapsedDuration.value = event.durationMillis;
          statusMessage.value = event.statusMessage;
        } else if (event.type == 'session_finished') {
          isMonitoring.value = false;
          faceDetected.value = false;
          statusMessage.value = 'Monitoring selesai';
        }
      },
      onError: (_) {},
    );
  }

  /// Membaca riwayat sesi yang tersimpan di Drift
  Future<void> loadStoredSessions() async {
    final svc = _service;
    if (svc != null) {
      await svc.flushPendingSessions();
    }
    final list = await _repository.getStoredSessions();
    storedSessions.assignAll(list);
  }

  /// Sinkronisasi manual dari tombol UI
  Future<void> manualSync() async {
    if (_syncManager.isSyncing.value) return;

    final success = await _syncManager.triggerManualSync();
    await loadStoredSessions();
    if (success) {
      Get.snackbar(
        'Sinkronisasi Berhasil',
        'Data sesi pemantauan mata telah tersimpan di cloud.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF00BFA5),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      );
    } else {
      Get.snackbar(
        'Sinkronisasi Gagal',
        'Sebagian data belum berhasil dikirim ke server. Sesi tetap tersimpan aman di HP.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      );
    }
  }
}
