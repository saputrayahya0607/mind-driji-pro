import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../data/models/intervention_model.dart';
import '../../../data/models/recommendation_model.dart';
import '../../../data/services/intervention_service.dart';

/// Controller untuk mengelola interaksi pengguna pada fitur Mode Fokus (Focus Mode).
///
/// Prinsip Utama:
/// 1. Calm Digital Wellness: Menenangkan, bebas bahasa medis atau skor kecanduan.
/// 2. Single Source of Truth: Menjadikan [InterventionService] sebagai satu-satunya
///    sumber data waktu, status, dan riwayat intervensi.
/// 3. Timestamp-based Countdown: Menghitung sisa waktu berdasarkan `endedAt - now`.
/// 4. Lifecycle-aware: Resilient terhadap app pause, resume, dan cold-start recovery.
/// 5. User Confirmation: Sesi hanya dimulai melalui inisiatif dan konfirmasi pengguna.
class FocusModeController extends GetxController with WidgetsBindingObserver {
  final InterventionService service;

  FocusModeController({InterventionService? interventionService})
      : service = interventionService ??
            (Get.isRegistered<InterventionService>()
                ? Get.find<InterventionService>()
                : InterventionService());

  static const List<int> availableDurations = [15, 30, 60];

  // State Reaktif
  final selectedDuration = 15.obs;
  final isStarting = false.obs;
  final hasCompletedSession = false.obs;
  final completedDurationMinutes = 15.obs;

  RecommendationModel? sourceRecommendation;

  /// Memeriksa apakah Focus Mode sedang aktif berjalan
  bool get isActive =>
      service.isActive.value &&
      service.activeIntervention.value?.type == InterventionType.focusMode;

  /// Sisa detik yang tersisa pada sesi Focus Mode aktif
  int get remainingSeconds {
    final current = service.activeIntervention.value;
    if (current == null || current.type != InterventionType.focusMode) {
      return 0;
    }
    return service.remainingSeconds.value;
  }

  /// Rasio progres intervensi dari 0.0 sampai 1.0
  double get progress {
    final current = service.activeIntervention.value;
    if (current == null || current.type != InterventionType.focusMode) {
      return 0.0;
    }
    return current.progress.clamp(0.0, 1.0);
  }

  /// Format sisa waktu menjadi `mm:ss` (contoh: 29:42)
  String get formattedRemainingTime {
    final secs = remainingSeconds;
    if (secs <= 0) return '00:00';
    final minutes = secs ~/ 60;
    final remainingSecs = secs % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSecs.toString().padLeft(2, '0')}';
  }

  @override
  void onInit() {
    super.onInit();
    try {
      WidgetsBinding.instance.addObserver(this);
    } catch (_) {}
    _initFromArguments();

    // Dengarkan perubahan activeIntervention untuk mendeteksi penyelesaian alami
    ever(service.activeIntervention, (InterventionModel? item) {
      if (item != null &&
          item.type == InterventionType.focusMode &&
          item.status == InterventionStatus.completed) {
        hasCompletedSession.value = true;
        completedDurationMinutes.value = item.durationMinutes;
      }
    });
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
      service.handleAppResume();
    }
  }

  /// Menginisialisasi durasi atau sumber rekomendasi dari argumen navigasi jika ada
  void _initFromArguments() {
    final args = Get.arguments;
    if (args is int) {
      selectDuration(args);
    } else if (args is Map) {
      if (args['duration'] is int) {
        selectDuration(args['duration'] as int);
      }
      if (args['source'] is RecommendationModel) {
        sourceRecommendation = args['source'] as RecommendationModel;
      }
    }
  }

  /// Memilih opsi durasi sesi fokus (15, 30, atau 60 menit)
  void selectDuration(int minutes) {
    if (minutes > 0) {
      selectedDuration.value = minutes;
    }
  }

  /// Memulai sesi Focus Mode dengan durasi terpilih
  Future<bool> startFocusMode() async {
    if (isStarting.value) return false;
    isStarting.value = true;
    try {
      final success = await service.startFocusMode(
        selectedDuration.value,
        source: sourceRecommendation,
      );
      if (success) {
        hasCompletedSession.value = false;
        completedDurationMinutes.value = selectedDuration.value;
      }
      return success;
    } finally {
      isStarting.value = false;
    }
  }

  /// Membatalkan sesi Focus Mode yang sedang aktif
  Future<void> cancelFocusMode() async {
    hasCompletedSession.value = false;
    await service.cancelIntervention();
  }

  /// Menyelesaikan sesi Focus Mode secara manual atau programatik
  Future<void> completeFocusMode() async {
    final current = service.activeIntervention.value;
    if (current != null && current.type == InterventionType.focusMode) {
      completedDurationMinutes.value = current.durationMinutes;
      hasCompletedSession.value = true;
    }
    await service.completeIntervention();
  }

  /// Memulihkan status Focus Mode dari native layer atau database lokal
  Future<void> restoreActiveFocusMode() async {
    if (isActive) return;
    await service.restoreActiveIntervention();
    if (isActive) {
      completedDurationMinutes.value =
          service.activeIntervention.value?.durationMinutes ?? selectedDuration.value;
    }
  }

  /// Me-reset state selesai untuk kembali ke tampilan awal (State A)
  void resetCompletedState() {
    hasCompletedSession.value = false;
  }
}
