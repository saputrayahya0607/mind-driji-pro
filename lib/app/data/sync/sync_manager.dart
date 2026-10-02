import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../local/repositories/doomscroll_local_repository.dart';
import '../local/repositories/eye_monitoring_local_repository.dart';
import '../local/repositories/local_usage_repository.dart';
import '../local/tables/sync_queue.dart';
import '../services/device_service.dart';

/// SyncManager mengelola sinkronisasi data lokal ke Supabase secara otomatis dan manual.
/// Menggunakan arsitektur offline-first: data disimpan di SQLite lokal terlebih dahulu,
/// lalu disinkronkan saat koneksi internet tersedia.
class SyncManager extends GetxService {
  final LocalUsageRepository? _localRepo;
  final DoomscrollLocalRepository? _doomscrollRepoInstance;
  final EyeMonitoringLocalRepository? _eyeMonitoringRepoInstance;
  final DeviceService? _deviceServiceInstance;
  final SupabaseClient? _supabase;
  Connectivity? _connectivity;
  final bool autoStart;

  SyncManager({
    LocalUsageRepository? localRepo,
    DoomscrollLocalRepository? doomscrollRepo,
    EyeMonitoringLocalRepository? eyeMonitoringRepo,
    DeviceService? deviceService,
    SupabaseClient? supabase,
    Connectivity? connectivity,
    this.autoStart = true,
  })  : _localRepo = localRepo,
        _doomscrollRepoInstance = doomscrollRepo,
        _eyeMonitoringRepoInstance = eyeMonitoringRepo,
        _deviceServiceInstance = deviceService,
        _supabase = supabase ?? _safeGetSupabaseClient(),
        _connectivity = connectivity;

  LocalUsageRepository get _repo =>
      _localRepo ??
      (Get.isRegistered<LocalUsageRepository>()
          ? Get.find<LocalUsageRepository>()
          : LocalUsageRepository());

  DoomscrollLocalRepository get _doomscrollRepo =>
      _doomscrollRepoInstance ??
      (Get.isRegistered<DoomscrollLocalRepository>()
          ? Get.find<DoomscrollLocalRepository>()
          : DoomscrollLocalRepository());

  EyeMonitoringLocalRepository get _eyeMonitoringRepo =>
      _eyeMonitoringRepoInstance ??
      (Get.isRegistered<EyeMonitoringLocalRepository>()
          ? Get.find<EyeMonitoringLocalRepository>()
          : EyeMonitoringLocalRepository());

  DeviceService get _deviceService =>
      _deviceServiceInstance ??
      (Get.isRegistered<DeviceService>()
          ? Get.find<DeviceService>()
          : DeviceService());

  static SupabaseClient? _safeGetSupabaseClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  // Observable state
  final isSyncing = false.obs;
  final isOnline = true.obs;
  final pendingCount = 0.obs;
  final lastSyncTime = Rxn<DateTime>();
  final lastError = RxnString();
  final syncStatus = SyncStatus.synced.obs;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void onInit() {
    super.onInit();
    if (autoStart) {
      _initConnectivity();
      refreshPendingCount();
    }
  }

  @override
  void onClose() {
    _connectivitySubscription?.cancel();
    super.onClose();
  }

  Connectivity get _conn => _connectivity ??= Connectivity();

  /// Inisialisasi listener konektivitas jaringan
  void _initConnectivity() {
    _conn.checkConnectivity().then(_updateConnectionStatus);
    _connectivitySubscription =
        _conn.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  /// Menangani perubahan status konektivitas internet
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final connected = results.any((r) => r != ConnectivityResult.none);
    final wasOffline = !isOnline.value;
    isOnline.value = connected;

    // Jika internet kembali aktif dan ada antrean yang belum tersinkron, jalankan auto-sync
    if (connected && (wasOffline || pendingCount.value > 0) && !isSyncing.value) {
      syncPendingData();
    }
  }

  /// Memperbarui jumlah antrean pending untuk pengguna yang sedang aktif
  Future<void> refreshPendingCount() async {
    final userId = _supabase?.auth.currentUser?.id;
    if (userId != null) {
      final usageCount = await _repo.getPendingSyncCount(userId);
      final eyeCount = await _eyeMonitoringRepo.getPendingSyncCount(userId);
      final count = usageCount + eyeCount;
      pendingCount.value = count;
      if (count > 0 && syncStatus.value == SyncStatus.synced) {
        syncStatus.value = SyncStatus.pending;
      } else if (count == 0 && syncStatus.value != SyncStatus.failed) {
        syncStatus.value = SyncStatus.synced;
      }
    }
  }

  /// Sinkronisasi antrean data lokal (Screen Time, App Usage, Doomscroll & Eye Monitoring) ke Supabase
  Future<bool> syncPendingData() async {
    if (isSyncing.value) return false;

    final client = _supabase;
    final currentUser = client?.auth.currentUser;
    if (client == null || currentUser == null || currentUser.id == 'local_user' || currentUser.id.isEmpty) {
      // User belum login di cloud, data tetap tersimpan aman di SQLite lokal
      return false;
    }

    // Registrasikan device ke Supabase user_devices terlebih dahulu
    try {
      await _deviceService.ensureDeviceRegistered(currentUser.id);
    } catch (_) {
      // Abaikan jika network issue atau table belum dimigrasi, sync monitoring tetap berjalan
    }

    // Klaim sesi 'local_user' yang tersimpan di SQLite lokal untuk user yang sekarang login
    await _eyeMonitoringRepo.claimLocalSessions(currentUser.id);
    await _doomscrollRepo.claimLocalSessions(currentUser.id);
    await _repo.claimLocalUsage(currentUser.id);

    // Periksa status konektivitas sebelum mencoba kirim
    final connectivityResults = await _conn.checkConnectivity();
    final connected =
        connectivityResults.any((r) => r != ConnectivityResult.none);
    isOnline.value = connected;
    if (!connected) {
      if (pendingCount.value > 0) {
        syncStatus.value = SyncStatus.pending;
      }
      return false;
    }

    isSyncing.value = true;
    lastError.value = null;

    try {
      final queueItems = await _repo.getPendingQueue();
      if (queueItems.isEmpty) {
        pendingCount.value = 0;
        syncStatus.value = SyncStatus.synced;
        isSyncing.value = false;
        return true;
      }

      int failCount = 0;

      for (final item in queueItems) {
        try {
          if (item.entityType == SyncEntityType.screenTimeDaily) {
            final data = await _repo.getScreenTimeById(item.entityId);
            if (data != null) {
              if (data.userId == 'local_user') continue;
              final devId = data.deviceId.isNotEmpty ? data.deviceId : await _deviceService.getDeviceId();
              await client.from('screen_time_daily').upsert({
                'id': data.id,
                'user_id': currentUser.id,
                'device_id': devId,
                'date': data.date,
                'total_usage_millis': data.totalUsageMillis.toInt(),
                'collected_at': data.collectedAt.toUtc().toIso8601String(),
                'created_at': data.createdAt.toUtc().toIso8601String(),
                'updated_at': data.updatedAt.toUtc().toIso8601String(),
              }, onConflict: 'user_id, device_id, date');

              await _repo.markScreenTimeSynced(data.id);
            } else {
              // Data sudah tidak ditemukan di database lokal, hapus dari antrean
              await _repo.removeQueueItem(item.id);
            }
          } else if (item.entityType == SyncEntityType.appUsageDaily) {
            final data = await _repo.getAppUsageById(item.entityId);
            if (data != null) {
              if (data.userId == 'local_user') continue;
              final devId = data.deviceId.isNotEmpty ? data.deviceId : await _deviceService.getDeviceId();
              await client.from('app_usage_daily').upsert({
                'id': data.id,
                'user_id': currentUser.id,
                'device_id': devId,
                'date': data.date,
                'package_name': data.packageName,
                'app_name': data.appName,
                'usage_millis': data.usageMillis.toInt(),
                'collected_at': data.collectedAt.toUtc().toIso8601String(),
                'created_at': data.createdAt.toUtc().toIso8601String(),
                'updated_at': data.updatedAt.toUtc().toIso8601String(),
              }, onConflict: 'user_id, device_id, date, package_name');

              await _repo.markAppUsageSynced(data.id);
            } else {
              // Data sudah tidak ditemukan di database lokal, hapus dari antrean
              await _repo.removeQueueItem(item.id);
            }
          } else if (item.entityType == SyncEntityType.doomscrollSession) {
            final session = await _doomscrollRepo.getSessionById(item.entityId);
            if (session != null) {
              if (session.userId == 'local_user') {
                await _doomscrollRepo.claimLocalSessions(currentUser.id);
              }
              final devId = session.deviceId.isNotEmpty ? session.deviceId : await _deviceService.getDeviceId();
              await client.from('doomscroll_sessions').upsert({
                'id': session.id,
                'user_id': currentUser.id,
                'device_id': devId,
                'package_name': session.packageName,
                'app_name': session.appName,
                'started_at': session.startedAt.toUtc().toIso8601String(),
                'ended_at': session.endedAt?.toUtc().toIso8601String(),
                'duration_millis': session.durationMillis.toInt(),
                'swipe_count': session.swipeCount,
                'downward_swipe_count': session.downwardSwipeCount,
                'upward_swipe_count': session.upwardSwipeCount,
                'avg_inter_swipe_millis': session.avgInterSwipeMillis.toInt(),
                'collected_at': session.collectedAt.toUtc().toIso8601String(),
                'created_at': session.createdAt.toUtc().toIso8601String(),
                'updated_at': session.updatedAt.toUtc().toIso8601String(),
              }, onConflict: 'id');

              await _doomscrollRepo.markSessionSynced(session.id);
            } else {
              // Data sudah tidak ditemukan di database lokal, hapus dari antrean
              await _repo.removeQueueItem(item.id);
            }
          } else if (item.entityType == SyncEntityType.eyeMonitoringSession) {
            final session = await _eyeMonitoringRepo.getSessionById(item.entityId);
            if (session != null) {
              final authenticatedUserId = currentUser.id;
              // Pastikan record lokal terhubung ke ID authenticated user yang sah
              if (session.userId != authenticatedUserId) {
                await _eyeMonitoringRepo.updateSessionUserId(session.id, authenticatedUserId);
              }

              final durationMillis = session.durationMillis.toInt() < 0 ? 0 : session.durationMillis.toInt();
              // Jangan kirim sesi kosong 0 ms tanpa data monitoring ke cloud
              if (durationMillis <= 0 && session.blinkCount == 0 && session.eyeClosureEvents == 0) {
                await _eyeMonitoringRepo.markSessionSynced(session.id);
                continue;
              }

              final devId = session.deviceId.isNotEmpty ? session.deviceId : await _deviceService.getDeviceId();
              final validAvgEar = (session.averageEar.isNaN || session.averageEar.isInfinite)
                  ? 0.0
                  : session.averageEar;
              final validMinEar = (session.minEar.isNaN || session.minEar.isInfinite)
                  ? 0.0
                  : session.minEar;
              final endedAt = session.endedAt ??
                  session.startedAt.add(Duration(milliseconds: durationMillis));
              final nowUtc = DateTime.now().toUtc().toIso8601String();

              await client.from('eye_monitoring_sessions').upsert({
                'id': session.id,
                'user_id': authenticatedUserId,
                'device_id': devId,
                'started_at': session.startedAt.toUtc().toIso8601String(),
                'ended_at': endedAt.toUtc().toIso8601String(),
                'duration_millis': durationMillis,
                'average_ear': validAvgEar,
                'min_ear': validMinEar,
                'eye_closure_events': session.eyeClosureEvents,
                'blink_count': session.blinkCount,
                'collected_at': session.collectedAt.toUtc().toIso8601String(),
                'created_at': session.createdAt.toUtc().toIso8601String(),
                'updated_at': nowUtc,
              }, onConflict: 'id');

              await _eyeMonitoringRepo.markSessionSynced(session.id);
            } else {
              await _repo.removeQueueItem(item.id);
            }
          }
        } catch (e) {
          failCount++;
          final errorMsg = e.toString();
          lastError.value = errorMsg;
          await _repo.updateQueueRetry(item.id, errorMsg);

          if (item.entityType == SyncEntityType.screenTimeDaily) {
            await _repo.markScreenTimeFailed(item.entityId, errorMsg);
          } else if (item.entityType == SyncEntityType.appUsageDaily) {
            await _repo.markAppUsageFailed(item.entityId, errorMsg);
          } else if (item.entityType == SyncEntityType.doomscrollSession) {
            await _doomscrollRepo.markSessionFailed(item.entityId, errorMsg);
          } else if (item.entityType == SyncEntityType.eyeMonitoringSession) {
            await _eyeMonitoringRepo.markSessionFailed(item.entityId, errorMsg);
          }
        }
      }

      final remainingUsage = await _repo.getPendingSyncCount(currentUser.id);
      final remainingEye = await _eyeMonitoringRepo.getPendingSyncCount(currentUser.id);
      final remaining = remainingUsage + remainingEye;
      pendingCount.value = remaining;

      if (remaining == 0) {
        syncStatus.value = SyncStatus.synced;
        lastSyncTime.value = DateTime.now();
      } else if (failCount > 0) {
        syncStatus.value = SyncStatus.failed;
      } else {
        syncStatus.value = SyncStatus.pending;
      }

      return failCount == 0;
    } catch (e) {
      lastError.value = e.toString();
      syncStatus.value = SyncStatus.failed;
      return false;
    } finally {
      isSyncing.value = false;
    }
  }

  /// Pemicu sinkronisasi manual yang dipanggil oleh user dari UI
  Future<bool> triggerManualSync() async {
    return await syncPendingData();
  }
}
