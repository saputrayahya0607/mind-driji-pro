import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/recommendation_model.dart';
import 'detection_service.dart';
import 'insight_service.dart';
import 'recommendation/recommendation_engine.dart';

/// Service orkestrasi rekomendasi intervensi digital wellbeing MIND DRIJI
class RecommendationService extends GetxService {
  final DetectionService _detectionService;
  final InsightService _insightService;
  final RecommendationEngine _engine;
  final SupabaseClient? _supabase;

  RecommendationService({
    DetectionService? detectionService,
    InsightService? insightService,
    RecommendationEngine? engine,
    SupabaseClient? supabase,
  })  : _detectionService = detectionService ??
            (Get.isRegistered<DetectionService>()
                ? Get.find<DetectionService>()
                : DetectionService()),
        _insightService = insightService ??
            (Get.isRegistered<InsightService>()
                ? Get.find<InsightService>()
                : InsightService()),
        _engine = engine ?? const RecommendationEngine(),
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
    final current = _supabase?.auth.currentUser?.id;
    if (current != null && current.isNotEmpty) return current;
    return 'local_user';
  }

  /// Menghasilkan rekomendasi tindakan untuk hari ini
  Future<List<RecommendationModel>> getTodayRecommendations({
    String? userId,
  }) async {
    return getRecommendationsForDate(DateTime.now(), userId: userId);
  }

  /// Menghasilkan rekomendasi tindakan untuk tanggal tertentu
  Future<List<RecommendationModel>> getRecommendationsForDate(
    DateTime date, {
    String? userId,
  }) async {
    final activeUserId = _resolveUserId(userId);
    debugPrint(
        '[MIND_DRIJI_REC] Generating recommendations for date: ${date.toIso8601String().substring(0, 10)}, user: $activeUserId');

    try {
      // 1. Dapatkan hasil deteksi dari DetectionService
      final detection = await _detectionService.detectForDate(
        date,
        userId: activeUserId,
      );

      // 2. Dapatkan insight harian dari InsightService
      final insights = await _insightService.getDailyInsights(
        date,
        userId: activeUserId,
      );

      // 3. Olah rekomendasi melalui RecommendationEngine
      final recommendations = _engine.generateDailyRecommendations(
        detection: detection,
        insights: insights,
        features: detection.features,
      );

      debugPrint(
          '[MIND_DRIJI_REC] Generated ${recommendations.length} recommendations for $activeUserId');
      return recommendations;
    } catch (e) {
      debugPrint('[MIND_DRIJI_REC] Error generating recommendations: $e');
      return const [];
    }
  }
}
