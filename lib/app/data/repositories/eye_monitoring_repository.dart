import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../local/app_database.dart';
import '../local/repositories/eye_monitoring_local_repository.dart';
import '../models/eye_monitoring_live_event.dart';
import '../models/eye_monitoring_session_model.dart';
import '../providers/eye_monitoring_native_provider.dart';

/// Repository untuk Eye Monitoring yang mengorkestrasi
/// Native CameraX/MediaPipe Provider, Foreground Service, dan Drift Local Database.
class EyeMonitoringRepository {
  final EyeMonitoringNativeProvider _provider;
  final EyeMonitoringLocalRepository _localRepository;
  final SupabaseClient? _supabase;

  EyeMonitoringRepository({
    EyeMonitoringNativeProvider? provider,
    EyeMonitoringLocalRepository? localRepository,
    SupabaseClient? supabase,
  })  : _provider = provider ?? EyeMonitoringNativeProvider(),
        _localRepository = localRepository ??
            (Get.isRegistered<EyeMonitoringLocalRepository>()
                ? Get.find<EyeMonitoringLocalRepository>()
                : EyeMonitoringLocalRepository()),
        _supabase = supabase ?? _safeGetSupabaseClient();

  EyeMonitoringNativeProvider get provider => _provider;
  EyeMonitoringLocalRepository get localRepository => _localRepository;

  static SupabaseClient? _safeGetSupabaseClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  String get _currentUserId =>
      _supabase?.auth.currentUser?.id ?? 'local_user';

  /// Memeriksa status izin kamera
  Future<bool> checkCameraPermission() {
    return _provider.checkCameraPermission();
  }

  /// Meminta izin kamera kepada pengguna
  Future<bool> requestCameraPermission() {
    return _provider.requestCameraPermission();
  }

  /// Memeriksa status izin notifikasi (Android 13+)
  Future<bool> checkNotificationPermission() {
    return _provider.checkNotificationPermission();
  }

  /// Meminta izin notifikasi kepada pengguna (Android 13+)
  Future<bool> requestNotificationPermission() {
    return _provider.requestNotificationPermission();
  }

  /// Memulai background monitoring menggunakan Android Foreground Service
  Future<bool> startForegroundMonitoring({
    Duration? interval,
    Duration? sessionDuration,
    String? userId,
    String? deviceId,
    bool runImmediate = true,
  }) {
    return _provider.startForegroundService(
      intervalMillis: interval?.inMilliseconds,
      sessionDurationMillis: sessionDuration?.inMilliseconds,
      userId: userId ?? _currentUserId,
      deviceId: deviceId,
      runImmediate: runImmediate,
    );
  }

  /// Menghentikan background monitoring dan Foreground Service secara total
  Future<bool> stopForegroundMonitoring() {
    return _provider.stopForegroundService();
  }

  /// Memeriksa apakah Foreground Service sedang aktif
  Future<bool> isForegroundServiceRunning() {
    return _provider.isForegroundServiceRunning();
  }

  /// Mengambil antrean sesi dari native, menyimpannya ke Drift SQLite, dan membersihkan antrean native
  Future<List<EyeMonitoringSessionModel>> flushPendingSessions() async {
    final pending =
        await _provider.getPendingSessions(defaultUserId: _currentUserId);
    if (pending.isEmpty) return [];

    for (final session in pending) {
      if (session.durationMillis > 0) {
        await _localRepository.insertSession(session);
      }
    }

    await _provider.clearPendingSessions();
    return pending;
  }

  /// Memulai monitoring mata secara lokal di native (direct mode)
  Future<bool> startMonitoring() {
    return _provider.startMonitoring();
  }

  /// Menghentikan monitoring, menyimpan summary sesi ke Drift SQLite lokal,
  /// dan mendaftarkannya ke Sync Queue.
  Future<EyeMonitoringSessionModel?> stopMonitoringAndPersist() async {
    final session = await _provider.stopMonitoring(defaultUserId: _currentUserId);
    if (session != null && session.durationMillis > 0) {
      await _localRepository.insertSession(session);
    }
    return session;
  }

  /// Mengaitkan sesi 'local_user' ke ID user yang login
  Future<void> claimLocalSessions(String userId) {
    return _localRepository.claimLocalSessions(userId);
  }

  /// Memeriksa status monitoring
  Future<bool> getStatus() {
    return _provider.getStatus();
  }

  /// Membaca riwayat sesi eye monitoring dari SQLite lokal
  Future<List<EyeMonitoringSessionData>> getStoredSessions({int limit = 50}) {
    return _localRepository.getSessions(limit: limit);
  }

  /// Membaca riwayat sesi eye monitoring dalam rentang waktu tertentu
  Future<List<EyeMonitoringSessionData>> getSessionsBetween({
    required DateTime start,
    required DateTime end,
    String? userId,
  }) {
    return _localRepository.getSessionsBetween(
        start: start, end: end, userId: userId);
  }

  /// Stream event status realtime langsung dari native
  Stream<EyeMonitoringLiveEvent> liveEventStream() {
    return _provider.liveEventStream();
  }
}
