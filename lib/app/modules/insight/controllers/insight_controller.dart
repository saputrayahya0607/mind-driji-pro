import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/local/repositories/intervention_history_local_repository.dart';
import '../../../data/models/detection_result.dart';
import '../../../data/models/insight_model.dart';
import '../../../data/models/intervention_model.dart';
import '../../../data/models/monitoring_visualization_model.dart';
import '../../../data/models/recommendation_model.dart';
import '../../../data/services/detection_service.dart';
import '../../../data/services/insight/insight_engine.dart';
import '../../../data/services/insight_service.dart';
import '../../../data/services/intervention_service.dart';
import '../../../data/services/monitoring_data_service.dart';
import '../../../data/services/recommendation/recommendation_engine.dart';
import '../../../data/services/recommendation_service.dart';
import '../../../routes/app_routes.dart';

/// Controller untuk modul Insight & Refleksi MIND DRIJI
class InsightController extends GetxController with WidgetsBindingObserver {
  final InsightService? _insightService;
  final DetectionService? _detectionService;
  final RecommendationService? _recommendationService;
  final RecommendationEngine _recommendationEngine;
  final InterventionService? _interventionService;
  final InterventionHistoryLocalRepository? _historyRepo;

  InsightController({
    InsightService? insightService,
    DetectionService? detectionService,
    RecommendationService? recommendationService,
    RecommendationEngine? recommendationEngine,
    InterventionService? interventionService,
    InterventionHistoryLocalRepository? historyRepo,
  })  : _insightService = insightService,
        _detectionService = detectionService,
        _recommendationService = recommendationService,
        _recommendationEngine =
            recommendationEngine ?? const RecommendationEngine(),
        _interventionService = interventionService,
        _historyRepo = historyRepo;

  InterventionHistoryLocalRepository get _historyRepository {
    if (_historyRepo != null) return _historyRepo;
    if (Get.isRegistered<InterventionHistoryLocalRepository>()) {
      return Get.find<InterventionHistoryLocalRepository>();
    }
    return InterventionHistoryLocalRepository();
  }

  InsightService get _service {
    if (_insightService != null) return _insightService;
    if (Get.isRegistered<InsightService>()) {
      return Get.find<InsightService>();
    }
    if (_detectionService != null) {
      final mon = Get.isRegistered<MonitoringDataService>()
          ? Get.find<MonitoringDataService>()
          : null;
      return InsightService(
        monitoringDataService: mon,
        detectionService: _detectionService,
      );
    }
    return InsightService();
  }

  RecommendationService get _recService {
    if (_recommendationService != null) return _recommendationService;
    if (Get.isRegistered<RecommendationService>()) {
      return Get.find<RecommendationService>();
    }
    return RecommendationService(
      detectionService: _detectionService,
      insightService: _insightService,
      engine: _recommendationEngine,
    );
  }

  InterventionService? get _interService {
    if (_interventionService != null) return _interventionService;
    if (Get.isRegistered<InterventionService>()) {
      return Get.find<InterventionService>();
    }
    return null;
  }

  // State Reaktif
  final selectedPeriod = MonitoringPeriod.daily.obs;
  final selectedDate = DateTime.now().obs;
  final isLoading = false.obs;
  final insights = <InsightModel>[].obs;
  final recommendations = <RecommendationModel>[].obs;
  final selectedDurations = <String, int>{}.obs;
  final selectedRecommendation = Rxn<RecommendationModel>();
  final userAppliedAction = RxnString();
  final selectedAction = RxnString();
  final detectionResult = Rxn<DetectionResult>();
  final latestIntervention = Rxn<InterventionModel>();

  // Getters
  InsightModel? get featuredInsight =>
      insights.isNotEmpty ? insights.first : null;

  List<InsightModel> get secondaryInsights =>
      insights.length > 1 ? insights.sublist(1) : const [];

  bool get hasInsights => insights.isNotEmpty;
  bool get hasRecommendations => recommendations.isNotEmpty;

  bool get hasDetection =>
      (detectionResult.value?.detected ?? false) ||
      (featuredInsight != null &&
          featuredInsight!.suggestedAction != null &&
          featuredInsight!.suggestedAction!.isNotEmpty);

  int getSelectedDuration(RecommendationModel rec) {
    return selectedDurations[rec.id] ??
        (rec.durationOptions.isNotEmpty ? rec.durationOptions[1] : 15);
  }

  void selectRecommendationDuration(String recId, int durationMinutes) {
    selectedDurations[recId] = durationMinutes;
  }

  /// Memilih dan mencatat rekomendasi yang diambil pengguna (User Choice)
  /// serta memulai intervensi ramah (Digital Break / Relaksasi Mata).
  Future<void> applyRecommendation(
      RecommendationModel rec, int durationMinutes) async {
    selectedRecommendation.value = rec;
    userAppliedAction.value = '${rec.title} ($durationMinutes menit)';
    selectAction(rec.title);

    final svc = _interService;
    if (rec.type == RecommendationType.focusMode) {
      Get.toNamed(
        Routes.focusMode,
        arguments: {
          'duration': durationMinutes,
          'source': rec,
        },
      );
    } else if (svc != null) {
      if (rec.type == RecommendationType.eyeRest) {
        await svc.startEyeRelaxation(
          durationSeconds: durationMinutes * 60,
          source: rec,
        );
        Get.toNamed(Routes.eyeRelaxation);
      } else {
        await svc.startDigitalBreak(
          durationMinutes,
          source: rec,
        );
        Get.toNamed(Routes.intervention);
      }
    }
  }

  Future<void> loadTodayInsight() async {
    if (_detectionService != null) {
      detectionResult.value = await _detectionService.detectToday();
    }
    await loadInsights();
    if (recommendations.isEmpty &&
        detectionResult.value != null &&
        detectionResult.value!.detected) {
      final recs = _recommendationEngine.generateDailyRecommendations(
        detection: detectionResult.value!,
        insights: insights,
        features: detectionResult.value!.features,
      );
      recommendations.assignAll(recs);
    }
  }

  void selectIntervention(String action) => selectAction(action);
  RxnString get selectedIntervention => selectedAction;

  /// Memeriksa apakah tombol navigasi ke masa depan diizinkan
  bool get canGoNext {
    final now = DateTime.now();
    final current = selectedDate.value;

    switch (selectedPeriod.value) {
      case MonitoringPeriod.daily:
        final todayMidnight = DateTime(now.year, now.month, now.day);
        final currentMidnight =
            DateTime(current.year, current.month, current.day);
        return currentMidnight.isBefore(todayMidnight);

      case MonitoringPeriod.weekly:
        final currentMonday =
            DateTime(current.year, current.month, current.day)
                .subtract(Duration(days: current.weekday - 1));
        final currentSunday = currentMonday.add(const Duration(days: 6));
        final nowMidnight = DateTime(now.year, now.month, now.day);
        return currentSunday.isBefore(nowMidnight);

      case MonitoringPeriod.monthly:
        return current.year < now.year ||
            (current.year == now.year && current.month < now.month);
    }
  }

  /// Label teks periode aktif untuk navigasi tanggal
  String get dateRangeLabel {
    final current = selectedDate.value;
    switch (selectedPeriod.value) {
      case MonitoringPeriod.daily:
        final dayName =
            MonitoringDataService.dayNames[current.weekday - 1];
        final monthName =
            MonitoringDataService.monthNames[current.month - 1];
        return '$dayName, ${current.day} $monthName ${current.year}';

      case MonitoringPeriod.weekly:
        final monday = DateTime(current.year, current.month, current.day)
            .subtract(Duration(days: current.weekday - 1));
        final sunday = monday.add(const Duration(days: 6));
        final sMonth =
            MonitoringDataService.shortMonthNames[monday.month - 1];
        final eMonth =
            MonitoringDataService.shortMonthNames[sunday.month - 1];

        if (monday.month == sunday.month) {
          return '${monday.day} – ${sunday.day} $sMonth ${monday.year}';
        } else {
          return '${monday.day} $sMonth – ${sunday.day} $eMonth ${sunday.year}';
        }

      case MonitoringPeriod.monthly:
        final mName =
            MonitoringDataService.monthNames[current.month - 1];
        return '$mName ${current.year}';
    }
  }

  @override
  void onInit() {
    super.onInit();
    try {
      WidgetsBinding.instance.addObserver(this);
    } catch (_) {}
    loadInsights();
  }

  @override
  void onClose() {
    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (_) {}
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      loadInsights();
    }
  }

  /// Mengubah periode pemantauan (Hari / Minggu / Bulan)
  void setPeriod(MonitoringPeriod period) {
    if (selectedPeriod.value != period) {
      selectedPeriod.value = period;
      loadInsights();
    }
  }

  /// Navigasi ke periode sebelumnya
  void previousPeriod() {
    final current = selectedDate.value;
    switch (selectedPeriod.value) {
      case MonitoringPeriod.daily:
        selectedDate.value = current.subtract(const Duration(days: 1));
        break;
      case MonitoringPeriod.weekly:
        selectedDate.value = current.subtract(const Duration(days: 7));
        break;
      case MonitoringPeriod.monthly:
        selectedDate.value = DateTime(current.year, current.month - 1, 1);
        break;
    }
    loadInsights();
  }

  /// Navigasi ke periode berikutnya (jika tidak melewati hari ini)
  void nextPeriod() {
    if (!canGoNext) return;
    final current = selectedDate.value;
    switch (selectedPeriod.value) {
      case MonitoringPeriod.daily:
        selectedDate.value = current.add(const Duration(days: 1));
        break;
      case MonitoringPeriod.weekly:
        selectedDate.value = current.add(const Duration(days: 7));
        break;
      case MonitoringPeriod.monthly:
        selectedDate.value = DateTime(current.year, current.month + 1, 1);
        break;
    }
    loadInsights();
  }

  /// Memuat daftar insight untuk periode aktif
  Future<void> loadInsights() async {
    try {
      isLoading.value = true;
      final date = selectedDate.value;
      List<InsightModel> result;

      if (_insightService != null ||
          Get.isRegistered<InsightService>() ||
          Get.isRegistered<MonitoringDataService>()) {
        switch (selectedPeriod.value) {
          case MonitoringPeriod.daily:
            result = await _service.getDailyInsights(date);
            break;
          case MonitoringPeriod.weekly:
            result = await _service.getWeeklyInsights(date);
            break;
          case MonitoringPeriod.monthly:
            result = await _service.getMonthlyInsights(date);
            break;
        }
      } else if (detectionResult.value != null) {
        final det = detectionResult.value!;
        final f = det.features;
        result = const InsightEngine().generateInsights(detection: det, features: f);
      } else {
        result = [];
      }

      insights.assignAll(result);

      // Muat rekomendasi untuk tanggal terpilih
      try {
        if (_recommendationService != null ||
            Get.isRegistered<RecommendationService>() ||
            Get.isRegistered<InsightService>() ||
            Get.isRegistered<MonitoringDataService>()) {
          final recs = await _recService.getRecommendationsForDate(date);
          recommendations.assignAll(recs);
        } else if (detectionResult.value != null &&
            detectionResult.value!.detected) {
          final recs = _recommendationEngine.generateDailyRecommendations(
            detection: detectionResult.value!,
            insights: result,
            features: detectionResult.value!.features,
          );
          recommendations.assignAll(recs);
        } else {
          recommendations.clear();
        }
      } catch (_) {
        recommendations.clear();
      }

      await loadLatestIntervention();
    } catch (_) {
      insights.clear();
      recommendations.clear();
    } finally {
      isLoading.value = false;
    }
  }

  /// Memuat riwayat intervensi terbaru yang telah dilakukan pengguna
  Future<void> loadLatestIntervention() async {
    try {
      final list = await _historyRepository.getRecent(limit: 1);
      if (list.isNotEmpty) {
        latestIntervention.value = list.first;
      } else {
        latestIntervention.value = null;
      }
    } catch (_) {
      latestIntervention.value = null;
    }
  }

  /// Memilih intervensi secara manual (User Choice)
  ///
  /// PENTING:
  /// Sistem tidak mengaktifkan Focus Mode secara sepihak.
  void selectAction(String action) {
    selectedAction.value = action;
  }
}
