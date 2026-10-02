import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../local/repositories/local_usage_repository.dart';
import '../models/detection_result.dart';
import '../models/monitoring_visualization_model.dart';
import '../repositories/doomscroll_repository.dart';
import '../repositories/eye_monitoring_repository.dart';
import '../repositories/usage_stats_repository.dart';
import 'detection/detection_engine.dart';
import 'detection/detection_thresholds.dart';

/// Service orkestrator deteksi perilaku scrolling MIND DRIJI
///
/// Mengambil data pemantauan nyata (offline Drift DB, native UsageStats, Accessibility),
/// mengekstraksi fitur perilaku, dan menghasilkan [DetectionResult] tanpa diagnosis medis.
class DetectionService extends GetxService {
  static DetectionService get to => Get.find<DetectionService>();

  final DetectionEngine _engine;
  final DoomscrollRepository _doomscrollRepo;
  final UsageStatsRepository _usageStatsRepo;
  final LocalUsageRepository _localUsageRepo;
  final EyeMonitoringRepository _eyeRepo;
  final SupabaseClient? _supabase;

  DetectionService({
    DetectionEngine? engine,
    DoomscrollRepository? doomscrollRepo,
    UsageStatsRepository? usageStatsRepo,
    LocalUsageRepository? localUsageRepo,
    EyeMonitoringRepository? eyeRepo,
    SupabaseClient? supabase,
  })  : _engine = engine ?? DetectionEngine(),
        _doomscrollRepo = doomscrollRepo ??
            (Get.isRegistered<DoomscrollRepository>()
                ? Get.find<DoomscrollRepository>()
                : DoomscrollRepository()),
        _usageStatsRepo = usageStatsRepo ??
            (Get.isRegistered<UsageStatsRepository>()
                ? Get.find<UsageStatsRepository>()
                : UsageStatsRepository()),
        _localUsageRepo = localUsageRepo ??
            (Get.isRegistered<LocalUsageRepository>()
                ? Get.find<LocalUsageRepository>()
                : LocalUsageRepository()),
        _eyeRepo = eyeRepo ??
            (Get.isRegistered<EyeMonitoringRepository>()
                ? Get.find<EyeMonitoringRepository>()
                : EyeMonitoringRepository()),
        _supabase = supabase ?? _safeGetSupabaseClient();

  static SupabaseClient? _safeGetSupabaseClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  String _resolveUserId(String? userId) {
    if (userId != null && userId.isNotEmpty) return userId;
    return _supabase?.auth.currentUser?.id ?? 'local_user';
  }

  DetectionEngine get engine => _engine;
  DetectionThresholds get thresholds => _engine.thresholds;

  /// Deteksi pola scrolling untuk hari ini (Today)
  /// Mengambil data realtime dari Accessibility dan UsageStats
  Future<DetectionResult> detectToday({String? userId}) async {
    final now = DateTime.now();
    return detectForDate(now, userId: userId);
  }

  /// Deteksi pola scrolling untuk tanggal spesifik
  Future<DetectionResult> detectForDate(DateTime date, {String? userId}) async {
    final effectiveUserId = _resolveUserId(userId);
    final dayStart = DateTime(date.year, date.month, date.day, 0, 0, 0);
    final dayEnd = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

    debugPrint(
      '[MIND_DRIJI_DETECTION] Starting detection for date: '
      '${date.toIso8601String().substring(0, 10)}, user: $effectiveUserId',
    );

    try {
      final now = DateTime.now();
      final isToday = date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;

      // Jika mendeteksi hari ini, flush antrean sesi native terlebih dahulu
      if (isToday) {
        try {
          await _doomscrollRepo.collectAndPersistPendingSessions();
        } catch (e) {
          debugPrint('[MIND_DRIJI_DETECTION] Error collecting pending native sessions: $e');
        }
      }

      // Ambil data sesi scrolling dari database lokal Drift
      final sessions = await _doomscrollRepo.getSessionsBetween(
        start: dayStart,
        end: dayEnd,
        userId: effectiveUserId,
      );

      // Ambil total waktu layar hari ini
      int totalScreenTimeMillis = 0;
      if (isToday) {
        try {
          final usage = await _usageStatsRepo.getTodayUsage();
          totalScreenTimeMillis = usage.totalUsageMillis;
        } catch (_) {}
      }

      if (totalScreenTimeMillis == 0) {
        final dateStr =
            '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final localUsage =
            await _localUsageRepo.getScreenTime(effectiveUserId, dateStr);
        totalScreenTimeMillis = localUsage?.totalUsageMillis.toInt() ?? 0;
      }

      // Ambil ringkasan pemantauan mata kontekstual
      final eyeSessions = await _eyeRepo.getSessionsBetween(
        start: dayStart,
        end: dayEnd,
        userId: effectiveUserId,
      );

      EyeMonitoringSummary? contextualEye;
      if (eyeSessions.isNotEmpty) {
        int totalEyeDur = 0;
        double earSum = 0;
        int earCount = 0;
        int closures = 0;
        int blinks = 0;

        for (final s in eyeSessions) {
          totalEyeDur += s.durationMillis.toInt();
          if (s.averageEar > 0) {
            earSum += s.averageEar;
            earCount++;
          }
          closures += s.eyeClosureEvents;
          blinks += s.blinkCount;
        }

        contextualEye = EyeMonitoringSummary(
          totalSessions: eyeSessions.length,
          totalDurationMillis: totalEyeDur,
          averageEar: earCount > 0 ? (earSum / earCount) : null,
          eyeClosureEvents: closures,
          blinkCount: blinks,
        );
      }

      // Ekstraksi fitur dan jalankan engine
      final features = _engine.extractFeatures(
        rawSessions: sessions,
        date: date,
        totalScreenTimeMillis: totalScreenTimeMillis,
      );

      return _engine.analyze(
        features,
        contextualEye: contextualEye,
      );
    } catch (e, stack) {
      debugPrint('[MIND_DRIJI_DETECTION] Error during detection: $e\n$stack');
      return DetectionResult.none(
        date: date,
        note: 'Gagal memproses data pemantauan.',
      );
    }
  }

  /// Deteksi pola scrolling untuk rentang tanggal (Range)
  Future<DetectionResult> detectForRange({
    required DateTime start,
    required DateTime end,
    String? userId,
  }) async {
    final effectiveUserId = _resolveUserId(userId);
    debugPrint(
      '[MIND_DRIJI_DETECTION] Starting range detection: '
      '${start.toIso8601String().substring(0, 10)} to ${end.toIso8601String().substring(0, 10)}',
    );

    try {
      final sessions = await _doomscrollRepo.getSessionsBetween(
        start: start,
        end: end,
        userId: effectiveUserId,
      );

      final startDateStr =
          '${start.year.toString().padLeft(4, '0')}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
      final endDateStr =
          '${end.year.toString().padLeft(4, '0')}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}';

      final screenTimes = await _localUsageRepo.getScreenTimesBetween(
        userId: effectiveUserId,
        startDate: startDateStr,
        endDate: endDateStr,
      );

      int totalScreenTime = 0;
      for (final st in screenTimes) {
        totalScreenTime += st.totalUsageMillis.toInt();
      }

      final eyeSessions = await _eyeRepo.getSessionsBetween(
        start: start,
        end: end,
        userId: effectiveUserId,
      );

      EyeMonitoringSummary? contextualEye;
      if (eyeSessions.isNotEmpty) {
        int closures = 0;
        int blinks = 0;
        double earSum = 0;
        int earCount = 0;
        for (final s in eyeSessions) {
          closures += s.eyeClosureEvents;
          blinks += s.blinkCount;
          if (s.averageEar > 0) {
            earSum += s.averageEar;
            earCount++;
          }
        }
        contextualEye = EyeMonitoringSummary(
          totalSessions: eyeSessions.length,
          eyeClosureEvents: closures,
          blinkCount: blinks,
          averageEar: earCount > 0 ? earSum / earCount : null,
        );
      }

      final features = _engine.extractFeatures(
        rawSessions: sessions,
        date: start,
        totalScreenTimeMillis: totalScreenTime,
      );

      return _engine.analyze(
        features,
        contextualEye: contextualEye,
      );
    } catch (e, stack) {
      debugPrint('[MIND_DRIJI_DETECTION] Error during range detection: $e\n$stack');
      return DetectionResult.none(
        date: start,
        note: 'Gagal memproses data pemantauan periode.',
      );
    }
  }

  /// Deteksi pola scrolling untuk periode Mingguan (Senin - Minggu)
  Future<DetectionResult> detectWeekly(DateTime date, {String? userId}) async {
    final monday = DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: date.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    final start = DateTime(monday.year, monday.month, monday.day, 0, 0, 0);
    final end = DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59, 999);

    return detectForRange(start: start, end: end, userId: userId);
  }

  /// Deteksi pola scrolling untuk periode Bulanan (Tgl 1 - Akhir Bulan)
  Future<DetectionResult> detectMonthly(DateTime date, {String? userId}) async {
    final daysInMonth = DateTime(date.year, date.month + 1, 0).day;
    final start = DateTime(date.year, date.month, 1, 0, 0, 0);
    final end = DateTime(date.year, date.month, daysInMonth, 23, 59, 59, 999);

    return detectForRange(start: start, end: end, userId: userId);
  }
}
