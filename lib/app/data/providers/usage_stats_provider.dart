import 'package:flutter/services.dart';
import '../models/app_usage_model.dart';

class UsageStatsProvider {
  static const MethodChannel _channel =
      MethodChannel('com.hn.minddriji/usage_stats');

  /// Memeriksa status izin akses penggunaan aplikasi (PACKAGE_USAGE_STATS).
  Future<bool> checkUsageAccess() async {
    try {
      final result = await _channel.invokeMethod<bool>('checkUsageAccess');
      return result ?? false;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Membuka halaman Pengaturan Sistem Android untuk mengaktifkan Usage Access.
  Future<bool> openUsageAccessSettings() async {
    try {
      final result =
          await _channel.invokeMethod<bool>('openUsageAccessSettings');
      return result ?? false;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Mengambil data statistik penggunaan hari ini dari Android UsageStatsManager.
  Future<UsageStatsModel> getTodayUsage() async {
    try {
      final result =
          await _channel.invokeMethod<Map<dynamic, dynamic>>('getTodayUsage');
      if (result == null) {
        return const UsageStatsModel(totalUsageMillis: 0, apps: []);
      }
      return UsageStatsModel.fromMap(result);
    } on PlatformException catch (e) {
      throw Exception('Gagal mengambil data penggunaan: ${e.message}');
    } catch (e) {
      throw Exception('Gagal mengambil data penggunaan: $e');
    }
  }

  /// Mengambil data statistik penggunaan untuk rentang waktu spesifik
  Future<UsageStatsModel> getUsageRange({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'getTodayUsage',
        {
          'startTime': startTime.millisecondsSinceEpoch,
          'endTime': endTime.millisecondsSinceEpoch,
        },
      );
      if (result == null) {
        return const UsageStatsModel(totalUsageMillis: 0, apps: []);
      }
      return UsageStatsModel.fromMap(result);
    } on PlatformException catch (_) {
      return const UsageStatsModel(totalUsageMillis: 0, apps: []);
    } catch (_) {
      return const UsageStatsModel(totalUsageMillis: 0, apps: []);
    }
  }
}
