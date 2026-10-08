import 'package:flutter/services.dart';
import '../models/doomscroll_live_session.dart';
import '../models/doomscroll_session_model.dart';
import '../models/target_app_model.dart';

/// Provider native yang berinteraksi dengan Android via MethodChannel com.hn.minddriji/doomscroll
class DoomscrollNativeProvider {
  static const MethodChannel _channel =
      MethodChannel('com.hn.minddriji/doomscroll');
  static const EventChannel _eventChannel =
      EventChannel('com.hn.minddriji/doomscroll_events');

  /// Stream sesi doomscroll realtime langsung dari Android AccessibilityService
  Stream<DoomscrollLiveSession> liveSessionStream() {
    return _eventChannel
        .receiveBroadcastStream()
        .where((event) => event is Map)
        .map((event) =>
            DoomscrollLiveSession.fromMap(event as Map<dynamic, dynamic>))
        .handleError((error) {
      // Abaikan error koneksi event channel agar stream tetap stabil
    });
  }

  /// Memeriksa apakah Accessibility Service MIND DRIJI aktif di pengaturan Android
  Future<bool> checkAccessibilityService() async {
    try {
      final isEnabled =
          await _channel.invokeMethod<bool>('checkAccessibilityService');
      return isEnabled ?? false;
    } on PlatformException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Membuka halaman Android Accessibility Settings
  Future<bool> openAccessibilitySettings() async {
    try {
      final opened =
          await _channel.invokeMethod<bool>('openAccessibilitySettings');
      return opened ?? false;
    } on PlatformException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Mengambil antrean sesi doomscroll yang tersimpan di native queue (SharedPreferences)
  Future<List<DoomscrollSessionModel>> getPendingDoomscrollSessions(
      {String? defaultUserId}) async {
    try {
      final rawList = await _channel
          .invokeListMethod<dynamic>('getPendingDoomscrollSessions');
      if (rawList == null) return [];

      return rawList
          .whereType<Map<dynamic, dynamic>>()
          .map((map) => DoomscrollSessionModel.fromMap(map, defaultUserId: defaultUserId))
          .where((s) => s.swipeCount > 0)
          .toList();
    } on PlatformException catch (_) {
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Menghapus native queue setelah berhasil disimpan ke Drift
  Future<bool> clearPendingDoomscrollSessions() async {
    try {
      final cleared =
          await _channel.invokeMethod<bool>('clearPendingDoomscrollSessions');
      return cleared ?? false;
    } on PlatformException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Menyelesaikan sesi aktif jika ada dan mengembalikan daftar sesi yang siap disimpan
  Future<List<DoomscrollSessionModel>> flushCurrentDoomscrollSession(
      {String? defaultUserId}) async {
    try {
      final rawList = await _channel
          .invokeListMethod<dynamic>('flushCurrentDoomscrollSession');
      if (rawList == null) return [];

      return rawList
          .whereType<Map<dynamic, dynamic>>()
          .map((map) => DoomscrollSessionModel.fromMap(map, defaultUserId: defaultUserId))
          .where((s) => s.swipeCount > 0)
          .toList();
    } on PlatformException catch (_) {
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Mengambil daftar aplikasi yang terpasang pada perangkat beserta status pemantauannya
  Future<List<TargetAppModel>> getInstalledApps() async {
    try {
      final rawList =
          await _channel.invokeListMethod<dynamic>('getInstalledApps');
      if (rawList == null) return [];

      return rawList
          .whereType<Map<dynamic, dynamic>>()
          .map((map) => TargetAppModel.fromMap(map))
          .toList();
    } on PlatformException catch (_) {
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Mengambil daftar package aplikasi target yang sedang aktif dipantau
  Future<List<TargetAppModel>> getTargetPackages() async {
    try {
      final rawList =
          await _channel.invokeListMethod<dynamic>('getTargetPackages');
      if (rawList == null) return [];

      return rawList
          .whereType<Map<dynamic, dynamic>>()
          .map((map) => TargetAppModel.fromMap(map))
          .toList();
    } on PlatformException catch (_) {
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Menyimpan daftar aplikasi target yang dipilih oleh pengguna ke native SharedPreferences
  Future<bool> saveTargetPackages(List<TargetAppModel> targetApps) async {
    try {
      final payload = targetApps.map((e) => e.toMap()).toList();
      final success = await _channel.invokeMethod<bool>(
        'saveTargetPackages',
        {'targetApps': payload},
      );
      return success ?? false;
    } on PlatformException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Mereset daftar aplikasi target ke konfigurasi default (TikTok, IG, YT, Snapchat, X, FB)
  Future<List<TargetAppModel>> resetTargetPackagesToDefault() async {
    try {
      final rawList = await _channel
          .invokeListMethod<dynamic>('resetTargetPackagesToDefault');
      if (rawList == null) return [];

      return rawList
          .whereType<Map<dynamic, dynamic>>()
          .map((map) => TargetAppModel.fromMap(map))
          .toList();
    } on PlatformException catch (_) {
      return [];
    } catch (_) {
      return [];
    }
  }
}
