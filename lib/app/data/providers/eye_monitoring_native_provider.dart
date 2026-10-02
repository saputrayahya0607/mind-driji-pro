import 'package:flutter/services.dart';
import '../models/eye_monitoring_live_event.dart';
import '../models/eye_monitoring_session_model.dart';

/// Provider native yang berinteraksi dengan Android CameraX, MediaPipe,
/// dan Android Foreground Service melalui MethodChannel dan EventChannel.
class EyeMonitoringNativeProvider {
  static const MethodChannel _channel =
      MethodChannel('com.hn.minddriji/eye_monitoring');
  static const EventChannel _eventChannel =
      EventChannel('com.hn.minddriji/eye_monitoring_events');

  /// Memeriksa apakah izin kamera sudah diberikan
  Future<bool> checkCameraPermission() async {
    try {
      final hasPermission =
          await _channel.invokeMethod<bool>('checkCameraPermission');
      return hasPermission ?? false;
    } on PlatformException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Meminta izin kamera kepada pengguna
  Future<bool> requestCameraPermission() async {
    try {
      final granted =
          await _channel.invokeMethod<bool>('requestCameraPermission');
      return granted ?? false;
    } on PlatformException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Memeriksa izin notifikasi (Android 13+ / API 33+)
  Future<bool> checkNotificationPermission() async {
    try {
      final granted =
          await _channel.invokeMethod<bool>('checkNotificationPermission');
      return granted ?? true;
    } on PlatformException catch (_) {
      return true;
    } catch (_) {
      return true;
    }
  }

  /// Meminta izin notifikasi (Android 13+ / API 33+)
  Future<bool> requestNotificationPermission() async {
    try {
      final granted =
          await _channel.invokeMethod<bool>('requestNotificationPermission');
      return granted ?? true;
    } on PlatformException catch (_) {
      return true;
    } catch (_) {
      return true;
    }
  }

  /// Memulai Android Foreground Service untuk periodic camera sampling
  Future<bool> startForegroundService({
    int? intervalMillis,
    int? sessionDurationMillis,
    String? userId,
    String? deviceId,
    bool runImmediate = true,
  }) async {
    try {
      final started = await _channel.invokeMethod<bool>(
        'startForegroundService',
        {
          if (intervalMillis != null) 'intervalMillis': intervalMillis,
          if (sessionDurationMillis != null)
            'sessionDurationMillis': sessionDurationMillis,
          if (userId != null) 'userId': userId,
          if (deviceId != null) 'deviceId': deviceId,
          'runImmediate': runImmediate,
        },
      );
      return started ?? false;
    } on PlatformException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Menghentikan Android Foreground Service dan mematikan monitoring total
  Future<bool> stopForegroundService() async {
    try {
      final stopped =
          await _channel.invokeMethod<bool>('stopForegroundService');
      return stopped ?? true;
    } on PlatformException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Memeriksa apakah Foreground Service sedang aktif
  Future<bool> isForegroundServiceRunning() async {
    try {
      final isRunning =
          await _channel.invokeMethod<bool>('isForegroundServiceRunning');
      return isRunning ?? false;
    } on PlatformException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Mengambil antrean sesi yang selesai dijalankan di background oleh Foreground Service
  Future<List<EyeMonitoringSessionModel>> getPendingSessions({
    String? defaultUserId,
  }) async {
    try {
      final rawList =
          await _channel.invokeListMethod<dynamic>('getPendingSessions');
      if (rawList == null || rawList.isEmpty) return [];

      final sessions = <EyeMonitoringSessionModel>[];
      for (final item in rawList) {
        if (item is Map) {
          final model = EyeMonitoringSessionModel.fromNativeMap(
            item,
            defaultUserId: defaultUserId,
          );
          sessions.add(model);
        }
      }
      return sessions;
    } on PlatformException catch (_) {
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Menghapus antrean sesi native setelah berhasil disimpan ke SQLite Drift
  Future<bool> clearPendingSessions() async {
    try {
      final cleared =
          await _channel.invokeMethod<bool>('clearPendingSessions');
      return cleared ?? false;
    } on PlatformException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Memulai pemantauan mata direct / in-process (CameraX front camera + MediaPipe)
  Future<bool> startMonitoring() async {
    try {
      final started = await _channel.invokeMethod<bool>('startMonitoring');
      return started ?? false;
    } on PlatformException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Menghentikan pemantauan mata, melepaskan kamera, dan mengembalikan summary sesi
  Future<EyeMonitoringSessionModel?> stopMonitoring(
      {String? defaultUserId}) async {
    try {
      final rawMap =
          await _channel.invokeMapMethod<dynamic, dynamic>('stopMonitoring');
      if (rawMap == null) return null;
      return EyeMonitoringSessionModel.fromNativeMap(
        rawMap,
        defaultUserId: defaultUserId,
      );
    } on PlatformException catch (_) {
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Memeriksa apakah monitoring mata saat ini sedang aktif di native
  Future<bool> getStatus() async {
    try {
      final statusMap =
          await _channel.invokeMapMethod<dynamic, dynamic>('getStatus');
      return statusMap?['isMonitoring'] as bool? ?? false;
    } on PlatformException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Stream event status realtime dari native Android (EAR, kedipan, deteksi wajah)
  Stream<EyeMonitoringLiveEvent> liveEventStream() {
    return _eventChannel
        .receiveBroadcastStream()
        .where((event) => event is Map)
        .map((event) =>
            EyeMonitoringLiveEvent.fromMap(event as Map<dynamic, dynamic>))
        .handleError((_) {
      // Abaikan error koneksi event channel agar stream tetap stabil
    });
  }
}
