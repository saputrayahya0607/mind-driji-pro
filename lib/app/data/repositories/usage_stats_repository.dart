import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../local/repositories/local_usage_repository.dart';
import '../models/app_usage_model.dart';
import '../providers/usage_stats_provider.dart';

class UsageStatsRepository {
  final UsageStatsProvider _provider;
  final LocalUsageRepository _localRepository;
  final SupabaseClient? _supabase;

  UsageStatsRepository({
    UsageStatsProvider? provider,
    LocalUsageRepository? localRepository,
    SupabaseClient? supabase,
  })  : _provider = provider ?? UsageStatsProvider(),
        _localRepository = localRepository ??
            (Get.isRegistered<LocalUsageRepository>()
                ? Get.find<LocalUsageRepository>()
                : LocalUsageRepository()),
        _supabase = supabase ?? _safeGetSupabaseClient();

  static SupabaseClient? _safeGetSupabaseClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  Future<bool> checkUsageAccess() {
    return _provider.checkUsageAccess();
  }

  Future<bool> openUsageAccessSettings() {
    return _provider.openUsageAccessSettings();
  }

  String get _currentUserId =>
      _supabase?.auth.currentUser?.id ?? 'local_user';

  /// Mengambil data penggunaan hari ini langsung dari perangkat (Native UsageStats)
  /// Jika native gagal / tidak tersedia, fallback mengambil dari database lokal
  Future<UsageStatsModel> getTodayUsage() async {
    try {
      final realStats = await _provider.getTodayUsage();
      return realStats;
    } catch (e) {
      // Fallback offline: muat data yang tersimpan di database lokal jika ada
      final localStats = await getLocalTodayUsage();
      if (localStats != null) {
        return localStats;
      }
      rethrow;
    }
  }

  /// Menyimpan snapshot data penggunaan harian ke database lokal SQLite
  /// (Dijalankan pada akhir hari / pukul 23:59 WIB sebelum sinkronisasi cloud)
  Future<void> saveDailySnapshot({UsageStatsModel? stats, DateTime? date}) async {
    final actualUserId = _currentUserId;
    final targetDate = date ?? DateTime.now();
    final dateStr = _formatDate(targetDate);
    final usageToSave = stats ?? await _provider.getTodayUsage();

    await _localRepository.saveTodayUsage(
      userId: actualUserId,
      date: dateStr,
      totalUsageMillis: usageToSave.totalUsageMillis,
      apps: usageToSave.apps,
    );
  }

  /// Membaca data penggunaan hari ini langsung dari SQLite lokal
  Future<UsageStatsModel?> getLocalTodayUsage() async {
    final actualUserId = _currentUserId;
    final today = _formatDate(DateTime.now());

    final screenTime =
        await _localRepository.getScreenTime(actualUserId, today);
    if (screenTime == null) return null;

    final appUsages =
        await _localRepository.getAppUsages(actualUserId, today);

    return UsageStatsModel(
      totalUsageMillis: screenTime.totalUsageMillis.toInt(),
      apps: appUsages
          .map((a) => AppUsageModel(
                packageName: a.packageName,
                appName: a.appName,
                usageMillis: a.usageMillis.toInt(),
              ))
          .toList(),
    );
  }

  /// Mengambil data statistik penggunaan untuk rentang waktu spesifik
  Future<UsageStatsModel> getUsageRange({
    required DateTime startTime,
    required DateTime endTime,
  }) {
    return _provider.getUsageRange(startTime: startTime, endTime: endTime);
  }

  /// Mengklaim data screen time & app usage lokal untuk user yang baru login
  Future<int> claimLocalUsage(String authenticatedUserId) {
    return _localRepository.claimLocalUsage(authenticatedUserId);
  }
}
