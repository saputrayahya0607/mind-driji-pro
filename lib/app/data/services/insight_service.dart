import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/insight_model.dart';
import '../models/monitoring_visualization_model.dart';
import 'detection_service.dart';
import 'insight/insight_engine.dart';
import 'monitoring_data_service.dart';

/// Global service GetX untuk mengorkestrasi pembentukan Insight di MIND DRIJI
class InsightService extends GetxService {
  static InsightService get to => Get.find<InsightService>();

  final DetectionService _detectionService;
  final MonitoringDataService _monitoringDataService;
  final InsightEngine _engine;
  final SupabaseClient? _supabase;

  InsightService({
    DetectionService? detectionService,
    MonitoringDataService? monitoringDataService,
    InsightEngine? engine,
    SupabaseClient? supabase,
  })  : _detectionService = detectionService ??
            (Get.isRegistered<DetectionService>()
                ? Get.find<DetectionService>()
                : DetectionService()),
        _monitoringDataService = monitoringDataService ??
            (Get.isRegistered<MonitoringDataService>()
                ? Get.find<MonitoringDataService>()
                : MonitoringDataService()),
        _engine = engine ?? const InsightEngine(),
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

  /// Menghasilkan insight untuk hari ini (Today)
  Future<List<InsightModel>> getTodayInsights({String? userId}) async {
    final now = DateTime.now();
    return getDailyInsights(now, userId: userId);
  }

  /// Menghasilkan insight untuk tanggal harian tertentu
  Future<List<InsightModel>> getDailyInsights(
    DateTime date, {
    String? userId,
  }) async {
    final effectiveUserId = _resolveUserId(userId);
    debugPrint(
      '[MIND_DRIJI_INSIGHT] Generating daily insights for date: '
      '${date.toIso8601String().substring(0, 10)}, user: $effectiveUserId',
    );

    try {
      // 1. Ambil hasil deteksi dari DetectionService
      final detection =
          await _detectionService.detectForDate(date, userId: effectiveUserId);

      // 2. Ambil segmen harian dan summary dari MonitoringDataService
      final segments = await _monitoringDataService.getDailySegments(
        date: date,
        userId: effectiveUserId,
      );

      final eyeSummary = await _monitoringDataService.getEyeMonitoringSummary(
        period: MonitoringPeriod.daily,
        date: date,
        userId: effectiveUserId,
      );

      final screenTimeSum = await _monitoringDataService.getScreenTimeSummary(
        period: MonitoringPeriod.daily,
        date: date,
        userId: effectiveUserId,
      );
      final totalScreenTime = (screenTimeSum['totalMillis'] as num?)?.toInt() ?? 0;

      final topApps = await _monitoringDataService.getTopApps(
        period: MonitoringPeriod.daily,
        date: date,
        userId: effectiveUserId,
      );
      final topApp = topApps.isNotEmpty ? topApps.first.appName : null;

      // 3. Olah menggunakan InsightEngine
      return _engine.generateInsights(
        detection: detection,
        features: detection.features,
        eyeSummary: eyeSummary,
        totalScreenTimeMillis: totalScreenTime,
        dailySegments: segments,
        topApp: topApp,
        period: 'daily',
        date: date,
      );
    } catch (e, stack) {
      debugPrint('[MIND_DRIJI_INSIGHT] Error generating daily insights: $e\n$stack');
      return [];
    }
  }

  /// Menghasilkan insight untuk periode mingguan (Senin - Minggu)
  Future<List<InsightModel>> getWeeklyInsights(
    DateTime date, {
    String? userId,
  }) async {
    final effectiveUserId = _resolveUserId(userId);
    debugPrint(
      '[MIND_DRIJI_INSIGHT] Generating weekly insights for date: '
      '${date.toIso8601String().substring(0, 10)}, user: $effectiveUserId',
    );

    try {
      final detection =
          await _detectionService.detectWeekly(date, userId: effectiveUserId);

      final weeklyDays = await _monitoringDataService.getWeeklyDays(
        dateInWeek: date,
        userId: effectiveUserId,
      );

      final eyeSummary = await _monitoringDataService.getEyeMonitoringSummary(
        period: MonitoringPeriod.weekly,
        date: date,
        userId: effectiveUserId,
      );

      final screenTimeSum = await _monitoringDataService.getScreenTimeSummary(
        period: MonitoringPeriod.weekly,
        date: date,
        userId: effectiveUserId,
      );
      final totalScreenTime = (screenTimeSum['totalMillis'] as num?)?.toInt() ?? 0;

      final topApps = await _monitoringDataService.getTopApps(
        period: MonitoringPeriod.weekly,
        date: date,
        userId: effectiveUserId,
      );
      final topApp = topApps.isNotEmpty ? topApps.first.appName : null;

      return _engine.generateInsights(
        detection: detection,
        features: detection.features,
        eyeSummary: eyeSummary,
        totalScreenTimeMillis: totalScreenTime,
        weeklyDays: weeklyDays,
        topApp: topApp,
        period: 'weekly',
        date: date,
      );
    } catch (e, stack) {
      debugPrint('[MIND_DRIJI_INSIGHT] Error generating weekly insights: $e\n$stack');
      return [];
    }
  }

  /// Menghasilkan insight untuk periode bulanan (Week 1 - Week 5)
  Future<List<InsightModel>> getMonthlyInsights(
    DateTime date, {
    String? userId,
  }) async {
    final effectiveUserId = _resolveUserId(userId);
    debugPrint(
      '[MIND_DRIJI_INSIGHT] Generating monthly insights for date: '
      '${date.toIso8601String().substring(0, 10)}, user: $effectiveUserId',
    );

    try {
      final detection =
          await _detectionService.detectMonthly(date, userId: effectiveUserId);

      final monthlyWeeks = await _monitoringDataService.getMonthlyWeeks(
        year: date.year,
        month: date.month,
        userId: effectiveUserId,
      );

      final eyeSummary = await _monitoringDataService.getEyeMonitoringSummary(
        period: MonitoringPeriod.monthly,
        date: date,
        userId: effectiveUserId,
      );

      final screenTimeSum = await _monitoringDataService.getScreenTimeSummary(
        period: MonitoringPeriod.monthly,
        date: date,
        userId: effectiveUserId,
      );
      final totalScreenTime = (screenTimeSum['totalMillis'] as num?)?.toInt() ?? 0;

      final topApps = await _monitoringDataService.getTopApps(
        period: MonitoringPeriod.monthly,
        date: date,
        userId: effectiveUserId,
      );
      final topApp = topApps.isNotEmpty ? topApps.first.appName : null;

      return _engine.generateInsights(
        detection: detection,
        features: detection.features,
        eyeSummary: eyeSummary,
        totalScreenTimeMillis: totalScreenTime,
        monthlyWeeks: monthlyWeeks,
        topApp: topApp,
        period: 'monthly',
        date: date,
      );
    } catch (e, stack) {
      debugPrint('[MIND_DRIJI_INSIGHT] Error generating monthly insights: $e\n$stack');
      return [];
    }
  }
}
