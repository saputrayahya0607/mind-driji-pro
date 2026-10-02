import 'dart:async';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Value;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/eye_monitoring_constants.dart';
import '../../core/utils/eye_condition_analyzer.dart';
import '../local/app_database.dart';
import '../local/repositories/eye_monitoring_local_repository.dart';
import '../models/eye_monitoring_live_event.dart';
import '../models/eye_monitoring_session_model.dart';
import '../repositories/eye_monitoring_repository.dart';
import '../services/device_service.dart';
import '../sync/sync_manager.dart';

/// Service global untuk Automatic Periodic Eye Monitoring (MIND DRIJI).
///
/// PRINSIP ARSITEKTUR:
/// 1. Lifecycle global (GetxService) yang tidak terikat pada buka-tutup halaman UI.
/// 2. Terintegrasi dengan Android Foreground Service (camera type) untuk eksekusi background resmi.
/// 3. Status monitoring (monitoringEnabled) tersimpan persisten di SQLite (Drift).
/// 4. Kamera TIDAK MENYALA TERUS: hanya sampling berkala (default 1 menit tiap 30 menit).
/// 5. Kamera otomatis OFF dan dilepas setelah sesi 1 menit selesai.
/// 6. Tetap aktif di background saat pengguna membuka aplikasi lain (TikTok, Instagram, YouTube, dll).
/// 7. Berhenti total saat user menekan "Matikan Monitoring" atau saat user logout.
/// 8. Single Source of Truth: Controller dan UI hanya mengamati status dari service ini.
class EyeMonitoringService extends GetxService with WidgetsBindingObserver {
  final EyeMonitoringRepository _repository;
  final EyeMonitoringLocalRepository _localRepository;
  final SyncManager _syncManager;
  final AppDatabase? _db;
  final SupabaseClient? _supabaseClient;
  final EyeConditionAnalyzer _analyzer;

  Duration _monitoringInterval;
  Duration _sessionDuration;
  final bool _autoStart;

  EyeMonitoringService({
    EyeMonitoringRepository? repository,
    EyeMonitoringLocalRepository? localRepository,
    SyncManager? syncManager,
    AppDatabase? db,
    SupabaseClient? supabaseClient,
    EyeConditionAnalyzer? analyzer,
    Duration? monitoringInterval,
    Duration? sessionDuration,
    bool autoStart = true,
  })  : _repository = repository ?? _safeGetRepository(),
        _localRepository = localRepository ?? _safeGetLocalRepository(),
        _syncManager = syncManager ?? _safeGetSyncManager(),
        _db = db ?? _safeGetDatabase(),
        _supabaseClient = supabaseClient ?? _safeGetSupabaseClient(),
        _analyzer = analyzer ?? EyeConditionAnalyzer(),
        _monitoringInterval =
            monitoringInterval ?? EyeMonitoringConstants.defaultMonitoringInterval,
        _sessionDuration =
            sessionDuration ?? EyeMonitoringConstants.defaultSessionDuration,
        _autoStart = autoStart;

  static EyeMonitoringService get to {
    if (Get.isRegistered<EyeMonitoringService>()) {
      return Get.find<EyeMonitoringService>();
    }
    final service = EyeMonitoringService();
    Get.put<EyeMonitoringService>(service, permanent: true);
    return service;
  }

  static EyeMonitoringRepository _safeGetRepository() {
    if (Get.isRegistered<EyeMonitoringRepository>()) {
      return Get.find<EyeMonitoringRepository>();
    }
    return EyeMonitoringRepository();
  }

  static EyeMonitoringLocalRepository _safeGetLocalRepository() {
    if (Get.isRegistered<EyeMonitoringLocalRepository>()) {
      return Get.find<EyeMonitoringLocalRepository>();
    }
    return EyeMonitoringLocalRepository();
  }

  static SyncManager _safeGetSyncManager() {
    if (Get.isRegistered<SyncManager>()) {
      return Get.find<SyncManager>();
    }
    return SyncManager(autoStart: false);
  }

  static AppDatabase? _safeGetDatabase() {
    try {
      if (Get.isRegistered<AppDatabase>()) {
        return Get.find<AppDatabase>();
      }
    } catch (_) {}
    return null;
  }

  static SupabaseClient? _safeGetSupabaseClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  String _resolveDeviceId() {
    try {
      if (Get.isRegistered<DeviceService>()) {
        return DeviceService.to.deviceId;
      }
    } catch (_) {}
    return 'unknown_device';
  }

  // ===========================================================================
  // STATE OBSERVABLES (Untuk Konsumsi Controller & UI)
  // ===========================================================================
  final isMonitoringEnabled = false.obs;
  final isSessionRunning = false.obs;
  final isLoading = false.obs;
  final cameraPermission = false.obs;
  final notificationPermission = true.obs;

  final lastSessionCompletedAt = Rxn<DateTime>();
  final nextScheduledAt = Rxn<DateTime>();
  final elapsedDuration = 0.obs;

  final faceDetected = false.obs;
  final multipleFaces = false.obs;
  final currentEar = 0.0.obs;
  final averageEar = 0.0.obs;
  final minEar = 0.0.obs;
  final eyeClosureEvents = 0.obs;
  final blinkCount = 0.obs;

  final statusMessage = 'Monitoring mata belum aktif'.obs;
  final errorMessage = RxnString();
  final lastCompletedSession = Rxn<EyeMonitoringSessionModel>();
  final lastConditionResult = Rxn<EyeConditionResult>();

  // ===========================================================================
  // INTERNAL SCHEDULER & CONCURRENCY CONTROLS
  // ===========================================================================
  bool _isSchedulerActive = false;
  bool _isExecutingSession = false;
  Timer? _schedulerTimer;
  Timer? _sessionTimeoutTimer;
  StreamSubscription<EyeMonitoringLiveEvent>? _liveSubscription;
  StreamSubscription? _authSubscription;
  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;

  Duration get monitoringInterval => _monitoringInterval;
  Duration get sessionDuration => _sessionDuration;
  bool get isSchedulerActive => _isSchedulerActive;
  EyeMonitoringRepository get repository => _repository;
  EyeMonitoringLocalRepository get localRepository => _localRepository;
  EyeConditionAnalyzer get analyzer => _analyzer;

  /// Konfigurasi durasi untuk keperluan pengujian / debugging
  void setTestingIntervals({
    Duration? monitoringInterval,
    Duration? sessionDuration,
  }) {
    if (monitoringInterval != null) _monitoringInterval = monitoringInterval;
    if (sessionDuration != null) _sessionDuration = sessionDuration;
  }

  @override
  void onInit() {
    super.onInit();
    try {
      WidgetsBinding.instance.addObserver(this);
    } catch (_) {}
    _subscribeToLiveEvents();
    _subscribeToAuthChanges();
    if (_autoStart) {
      initService();
    }
  }

  @override
  void onClose() {
    _cancelTimers();
    _liveSubscription?.cancel();
    _liveSubscription = null;
    _authSubscription?.cancel();
    _authSubscription = null;
    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (_) {}
    super.onClose();
  }

  /// Memantau perubahan auth status: jika user logout, monitoring WAJIB dihentikan total
  void _subscribeToAuthChanges() {
    try {
      final client = _supabaseClient ?? _safeGetSupabaseClient();
      if (client != null) {
        _authSubscription = client.auth.onAuthStateChange.listen((data) {
          final event = data.event;
          final user = data.session?.user;
          if (event == AuthChangeEvent.signedOut || user == null) {
            _log('[EYE] User signed out -> STOP monitoring total');
            if (isMonitoringEnabled.value) {
              disableMonitoring();
            }
          }
        });
      }
    } catch (e) {
      _log('[EYE] Error subscribing to auth state changes: $e');
    }
  }

  /// Inisialisasi awal membaca persistent state dari database lokal Drift
  Future<void> initService() async {
    await checkCameraPermission();
    await checkNotificationPermission();
    await _loadConfigFromDb();

    // Ambil sesi background yang belum sempat diambil Flutter
    await flushPendingSessions();

    if (isMonitoringEnabled.value) {
      // Pastikan user masih login
      final client = _supabaseClient ?? _safeGetSupabaseClient();
      if (client != null && client.auth.currentUser == null) {
        _log('[EYE] No active authenticated session on startup. Disabling monitoring.');
        await disableMonitoring();
        return;
      }

      _log('[EYE] Persistent monitoring state is ENABLED on startup');
      statusMessage.value = 'Monitoring Aktif';

      final userId = client?.auth.currentUser?.id ?? 'local_user';
      final isDue = _isSessionDue();

      // Pulihkan Foreground Service di level native
      await _repository.startForegroundMonitoring(
        interval: _monitoringInterval,
        sessionDuration: _sessionDuration,
        userId: userId,
        deviceId: _resolveDeviceId(),
        runImmediate: isDue,
      );

      _startScheduler();
      if (isDue) {
        _log('[EYE] Previous session is due on startup. Triggering initial session.');
        await _runSessionIfDue();
      } else {
        _scheduleNextSession();
      }
    } else {
      _log('[EYE] Persistent monitoring state is DISABLED');
      statusMessage.value = 'Monitoring belum aktif';
    }
  }

  // ===========================================================================
  // LIFECYCLE OBSERVER (Background Resilience)
  // ===========================================================================
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleState = state;

    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _log('[EYE] App entered background / inactive ($state)');
      // Hentikan sesi in-process jika sedang berjalan untuk melepas kamera hardware bagi background service
      if (isSessionRunning.value) {
        _log('[EYE] Releasing in-process camera due to background transition');
        isSessionRunning.value = false;
        _completeSession(reason: 'app_backgrounded');
      }
    } else if (state == AppLifecycleState.resumed) {
      _log('[EYE] App resumed to foreground. Flushing pending sessions.');
      checkCameraPermission();
      checkNotificationPermission();
      flushPendingSessions();

      if (isMonitoringEnabled.value) {
        statusMessage.value = isSessionRunning.value ? 'Sedang Memantau' : 'Monitoring Aktif';
        if (_isSessionDue() && !isSessionRunning.value) {
          _runSessionIfDue();
        } else {
          _scheduleNextSession();
        }
      }
    }
  }

  // ===========================================================================
  // PUBLIC ACTIONS (User Controls & Consent)
  // ===========================================================================

  /// Memeriksa status izin kamera
  Future<bool> checkCameraPermission() async {
    try {
      final granted = await _repository.checkCameraPermission();
      cameraPermission.value = granted;
      return granted;
    } catch (_) {
      cameraPermission.value = false;
      return false;
    }
  }

  /// Meminta izin kamera kepada pengguna
  Future<bool> requestCameraPermission() async {
    try {
      final granted = await _repository.requestCameraPermission();
      cameraPermission.value = granted;
      if (!granted) {
        errorMessage.value =
            'Izin kamera diperlukan untuk mendeteksi indikator mata lelah.';
      } else {
        errorMessage.value = null;
      }
      return granted;
    } catch (_) {
      cameraPermission.value = false;
      return false;
    }
  }

  /// Memeriksa izin notifikasi (Android 13+)
  Future<bool> checkNotificationPermission() async {
    try {
      final granted = await _repository.checkNotificationPermission();
      notificationPermission.value = granted;
      return granted;
    } catch (_) {
      notificationPermission.value = true;
      return true;
    }
  }

  /// Meminta izin notifikasi (Android 13+)
  Future<bool> requestNotificationPermission() async {
    try {
      final granted = await _repository.requestNotificationPermission();
      notificationPermission.value = granted;
      return granted;
    } catch (_) {
      notificationPermission.value = true;
      return true;
    }
  }

  /// Mengaktifkan Automatic Periodic Monitoring (User Explicit Consent)
  Future<bool> enableMonitoring() async {
    if (isMonitoringEnabled.value) return true;

    isLoading.value = true;
    errorMessage.value = null;

    try {
      // 1. Consent Guard: User harus login (jika Supabase terkonfigurasi)
      final client = _supabaseClient ?? _safeGetSupabaseClient();
      if (client != null && client.auth.currentUser == null) {
        errorMessage.value =
            'Silakan login terlebih dahulu untuk mengaktifkan pemantauan mata.';
        isLoading.value = false;
        return false;
      }

      // 2. Consent Guard: Izin Kamera
      final hasPerm = await checkCameraPermission();
      if (!hasPerm) {
        final requested = await requestCameraPermission();
        if (!requested) {
          isLoading.value = false;
          return false;
        }
      }

      // 3. Izin Notifikasi (Android 13+)
      await requestNotificationPermission();

      isMonitoringEnabled.value = true;
      statusMessage.value = 'Monitoring Aktif';
      _log('[EYE] Monitoring enabled with explicit user consent');

      await _saveConfigToDb();

      // 4. Mulai Android Foreground Service
      final userId = client?.auth.currentUser?.id ?? 'local_user';
      final devId = _resolveDeviceId();
      final isDue = _isSessionDue();

      await _repository.startForegroundMonitoring(
        interval: _monitoringInterval,
        sessionDuration: _sessionDuration,
        userId: userId,
        deviceId: devId,
        runImmediate: isDue,
      );

      _startScheduler();

      // Jalankan sesi pertama jika sudah due dan app di foreground
      if (isDue && _lifecycleState == AppLifecycleState.resumed) {
        await _runSessionIfDue();
      } else {
        _scheduleNextSession();
      }

      return true;
    } catch (e) {
      errorMessage.value = 'Gagal mengaktifkan monitoring: ${e.toString()}';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Mematikan Monitoring secara permanen hingga diaktifkan kembali oleh pengguna
  Future<void> disableMonitoring() async {
    if (!isMonitoringEnabled.value) return;

    isLoading.value = true;
    try {
      isMonitoringEnabled.value = false;
      _log('[EYE] Monitoring disabled -> stopping native foreground service');

      // 1. Matikan Android Foreground Service di level native
      await _repository.stopForegroundMonitoring();

      // 2. Hentikan sesi kamera jika sedang aktif
      if (isSessionRunning.value) {
        await _completeSession(reason: 'user_disabled');
      }

      _cancelTimers();
      _isSchedulerActive = false;
      isSessionRunning.value = false;
      statusMessage.value = 'Monitoring belum aktif';

      await _saveConfigToDb();
    } catch (e) {
      errorMessage.value = 'Gagal mematikan monitoring: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  /// Mengambil dan memproses antrean sesi yang selesai dijalankan di background oleh native service
  Future<List<EyeMonitoringSessionModel>> flushPendingSessions() async {
    try {
      final flushed = await _repository.flushPendingSessions();
      if (flushed.isNotEmpty) {
        _log('[EYE] Successfully flushed ${flushed.length} sessions from native background queue');
        final latest = flushed.last;
        lastCompletedSession.value = latest;
        lastSessionCompletedAt.value = latest.endedAt;
        final end = latest.endedAt ?? DateTime.now();
        nextScheduledAt.value = end.add(_monitoringInterval);

        final condition = _analyzer.analyzeSession(latest);
        lastConditionResult.value = condition;
        _log('[EYE] Flushed session condition: ${condition.level} - ${condition.message}');

        await _saveConfigToDb();
        _triggerCloudSync();
      }
      return flushed;
    } catch (e) {
      _log('[EYE] Error flushing pending sessions: $e');
      return [];
    }
  }

  /// Manual test trigger untuk menjalankan satu sesi langsung (misal untuk testing / debugging)
  Future<void> triggerImmediateSession() async {
    if (!isMonitoringEnabled.value) {
      await enableMonitoring();
    }
    await _runSessionIfDue(force: true);
  }

  // ===========================================================================
  // SCHEDULER & SESSION EXECUTION
  // ===========================================================================

  void _startScheduler() {
    if (_isSchedulerActive) return;
    _isSchedulerActive = true;
    _log('[EYE] Scheduler started');
  }

  bool _isSessionDue() {
    final last = lastSessionCompletedAt.value;
    if (last == null) return true;

    final elapsed = DateTime.now().difference(last);
    return elapsed >= _monitoringInterval;
  }

  void _scheduleNextSession() {
    if (!isMonitoringEnabled.value) return;

    _schedulerTimer?.cancel();

    final now = DateTime.now();
    DateTime targetTime;

    if (lastSessionCompletedAt.value != null) {
      targetTime = lastSessionCompletedAt.value!.add(_monitoringInterval);
    } else {
      targetTime = now;
    }

    if (targetTime.isBefore(now)) {
      targetTime = now;
    }

    nextScheduledAt.value = targetTime;
    _saveConfigToDb();

    final delay = targetTime.difference(now);
    _log('[EYE] Next session scheduled at $targetTime (in ${delay.inSeconds} seconds)');

    _schedulerTimer = Timer(delay, () {
      if (isMonitoringEnabled.value) {
        _runSessionIfDue();
      }
    });
  }

  /// Menjalankan sesi kamera jika due (mencegah penumpukan sesi terlewat)
  Future<void> _runSessionIfDue({bool force = false}) async {
    if (!isMonitoringEnabled.value && !force) return;

    // Proteksi duplicate session
    if (_isExecutingSession || isSessionRunning.value) {
      _log('[EYE] Camera session already running, skipping duplicate invocation');
      return;
    }

    // Proteksi background: jangan start kamera in-process jika app tidak di foreground
    if (_lifecycleState != AppLifecycleState.resumed) {
      _log('[EYE] App is not in foreground ($_lifecycleState). Skipping in-process session execution.');
      return;
    }

    _isExecutingSession = true;
    isSessionRunning.value = true;
    nextScheduledAt.value = DateTime.now().add(_monitoringInterval);
    _resetLiveMetrics();

    _log('[EYE] Session due');
    _log('[EYE] Camera started');
    statusMessage.value = 'Sedang Memantau';

    try {
      final started = await _repository.startMonitoring();
      if (!started) {
        _log('[EYE] Failed to start native camera session');
        isSessionRunning.value = false;
        _isExecutingSession = false;
        statusMessage.value = 'Monitoring Aktif';
        _scheduleNextSession();
        return;
      }

      // Mulai timer durasi sesi (default ~1 menit)
      _sessionTimeoutTimer?.cancel();
      _sessionTimeoutTimer = Timer(_sessionDuration, () {
        _log('[EYE] Session duration elapsed ($_sessionDuration). Stopping camera.');
        _completeSession(reason: 'duration_completed');
      });
    } catch (e) {
      _log('[EYE] Error during session execution: $e');
      isSessionRunning.value = false;
      _isExecutingSession = false;
      _scheduleNextSession();
    }
  }

  /// Menyelesaikan sesi monitoring, mematikan kamera, menyimpan sesi ke Drift, dan memicu sync
  Future<void> _completeSession({String reason = 'normal'}) async {
    if (!_isExecutingSession && !isSessionRunning.value) return;

    _sessionTimeoutTimer?.cancel();
    _sessionTimeoutTimer = null;

    _log('[EYE] Camera stopped');
    statusMessage.value = 'Pemantauan selesai';

    try {
      final session = await _repository.stopMonitoringAndPersist();
      isSessionRunning.value = false;
      _isExecutingSession = false;

      final now = DateTime.now();
      lastSessionCompletedAt.value = now;
      nextScheduledAt.value = now.add(_monitoringInterval);

      if (session != null) {
        lastCompletedSession.value = session;
        final condition = _analyzer.analyzeSession(session);
        lastConditionResult.value = condition;
        _log('[EYE] Session saved (ID: ${session.id}, Duration: ${session.durationMillis}ms, EAR: ${session.averageEar}, Condition: ${condition.level})');
      }

      _log('[EYE] Session completed (reason: $reason)');
      await _saveConfigToDb();

      // Jalankan sinkronisasi cloud
      _triggerCloudSync();

      // Jadwalkan sesi berikutnya jika monitoring masih enabled
      if (isMonitoringEnabled.value) {
        statusMessage.value = 'Monitoring Aktif';
        _scheduleNextSession();
      }
    } catch (e) {
      _log('[EYE] Error stopping session: $e');
      isSessionRunning.value = false;
      _isExecutingSession = false;
      if (isMonitoringEnabled.value) {
        _scheduleNextSession();
      }
    }
  }

  void _triggerCloudSync() {
    _log('[EYE] Sync started');
    _syncManager.refreshPendingCount().then((_) {
      if (_syncManager.isOnline.value) {
        _syncManager.syncPendingData().then((success) {
          _log('[EYE] Sync completed (success: $success)');
        }).catchError((err) {
          _log('[EYE] Sync error: $err');
        });
      }
    });
  }

  // ===========================================================================
  // LIVE EVENTS & METRICS
  // ===========================================================================

  void _subscribeToLiveEvents() {
    _liveSubscription = _repository.liveEventStream().listen(
      (event) {
        if (event.type == 'status_update') {
          if (!faceDetected.value && event.faceDetected) {
            _log('[EYE] Face detected');
          }
          faceDetected.value = event.faceDetected;
          multipleFaces.value = event.multipleFaces;
          currentEar.value = event.currentEar;
          averageEar.value = event.averageEar;
          minEar.value = event.minEar;
          eyeClosureEvents.value = event.eyeClosureEvents;
          blinkCount.value = event.blinkCount;
          elapsedDuration.value = event.durationMillis;
          if (isSessionRunning.value) {
            statusMessage.value = event.statusMessage;
          }
        } else if (event.type == 'session_finished') {
          _log('[EYE] Received session_finished from native');
          isSessionRunning.value = false;
          _isExecutingSession = false;
          statusMessage.value = 'Pemantauan selesai';

          final now = DateTime.now();
          lastSessionCompletedAt.value = now;
          nextScheduledAt.value = now.add(_monitoringInterval);

          flushPendingSessions();

          if (isMonitoringEnabled.value) {
            statusMessage.value = 'Monitoring Aktif';
            _scheduleNextSession();
          }
        }
      },
      onError: (err) {
        _log('[EYE] Live stream error: $err');
      },
    );
  }

  void _resetLiveMetrics() {
    faceDetected.value = false;
    multipleFaces.value = false;
    currentEar.value = 0.0;
    averageEar.value = 0.0;
    minEar.value = 0.0;
    eyeClosureEvents.value = 0;
    blinkCount.value = 0;
    elapsedDuration.value = 0;
  }

  void _cancelTimers() {
    _schedulerTimer?.cancel();
    _schedulerTimer = null;
    _sessionTimeoutTimer?.cancel();
    _sessionTimeoutTimer = null;
  }

  // ===========================================================================
  // PERSISTENCE (Drift SQLite)
  // ===========================================================================

  Future<void> _loadConfigFromDb() async {
    final db = _db;
    if (db == null) return;

    try {
      final config = await (db.select(db.eyeMonitoringConfig)
            ..where((t) => t.id.equals('current_config')))
          .getSingleOrNull();

      if (config != null) {
        isMonitoringEnabled.value = config.monitoringEnabled;
        lastSessionCompletedAt.value = config.lastSessionCompletedAt;
        nextScheduledAt.value = config.nextScheduledAt;
      }
    } catch (e) {
      _log('[EYE] Failed to load config from database: $e');
    }
  }

  Future<void> _saveConfigToDb() async {
    final db = _db;
    if (db == null) return;

    try {
      final now = DateTime.now();
      await db.into(db.eyeMonitoringConfig).insertOnConflictUpdate(
            EyeMonitoringConfigCompanion.insert(
              id: 'current_config',
              monitoringEnabled: drift.Value(isMonitoringEnabled.value),
              lastSessionCompletedAt:
                  drift.Value(lastSessionCompletedAt.value),
              nextScheduledAt: drift.Value(nextScheduledAt.value),
              updatedAt: now,
            ),
          );
    } catch (e) {
      _log('[EYE] Failed to save config to database: $e');
    }
  }

  void _log(String message) {
    debugPrint('[${EyeMonitoringConstants.logTag}] $message');
  }

  AppLifecycleState get lifecycleState => _lifecycleState;

  @visibleForTesting
  void setLifecycleStateForTesting(AppLifecycleState state) {
    _lifecycleState = state;
  }
}
