import 'package:flutter/services.dart';

/// Provider native bridge untuk berkomunikasi dengan platform Android
/// melalui MethodChannel dan EventChannel intervensi.
class InterventionNativeProvider {
  static const MethodChannel _channel =
      MethodChannel('com.hn.minddriji/intervention');
  static const EventChannel _eventChannel =
      EventChannel('com.hn.minddriji/intervention_events');

  /// Memulai Digital Break pada native layer (persisten SharedPreferences & notifikasi).
  Future<bool> startDigitalBreak({
    required String id,
    required int durationMinutes,
    required int endTimestampMillis,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>('startDigitalBreak', {
        'id': id,
        'durationMinutes': durationMinutes,
        'endTimestampMillis': endTimestampMillis,
      });
      return result ?? true;
    } catch (_) {
      // Fallback aman untuk platform selain Android atau saat test environment
      return true;
    }
  }

  /// Menghentikan Digital Break pada native layer.
  Future<bool> stopDigitalBreak() async {
    try {
      final result = await _channel.invokeMethod<bool>('stopDigitalBreak');
      return result ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Memulai Focus Mode pada native layer (persisten SharedPreferences & notifikasi).
  Future<bool> startFocusMode({
    required String id,
    required int durationMinutes,
    required int endTimestampMillis,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>('startFocusMode', {
        'id': id,
        'durationMinutes': durationMinutes,
        'endTimestampMillis': endTimestampMillis,
      });
      return result ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Menghentikan Focus Mode pada native layer.
  Future<bool> stopFocusMode() async {
    try {
      final result = await _channel.invokeMethod<bool>('stopFocusMode');
      return result ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Mengambil status intervensi yang tersimpan pada Android SharedPreferences.
  Future<Map<String, dynamic>?> getInterventionStatus() async {
    try {
      final result =
          await _channel.invokeMethod<Map<dynamic, dynamic>>('getInterventionStatus');
      if (result == null) return null;
      return Map<String, dynamic>.from(result);
    } catch (_) {
      return null;
    }
  }

  /// Event stream dari native layer jika ada pembaruan status intervensi.
  Stream<dynamic>? get eventStream {
    try {
      return _eventChannel.receiveBroadcastStream();
    } catch (_) {
      return null;
    }
  }
}
