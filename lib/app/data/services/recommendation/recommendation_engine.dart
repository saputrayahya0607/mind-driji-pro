import '../../models/behavioral_features.dart';
import '../../models/detection_result.dart';
import '../../models/insight_model.dart';
import '../../models/recommendation_model.dart';

/// Mesin penghasil rekomendasi tindakan cerdas (Recommendation Engine)
///
/// PENTING:
/// 1. Berfungsi murni menerjemahkan [DetectionResult], [InsightModel], dan [BehavioralFeatures]
///    menjadi opsi rekomendasi yang dapat dipilih oleh pengguna secara sadar (User Choice).
/// 2. TIDAK menjalankan intervensi secara sepihak.
/// 3. TIDAK mengandung diagnosa medis maupun skor kecanduan.
/// 4. Pure engine tanpa ketergantungan langsung ke database.
class RecommendationEngine {
  const RecommendationEngine();

  /// Menghasilkan daftar rekomendasi berdasarkan [DetectionResult] dan fitur perilaku
  List<RecommendationModel> generateFromDetection({
    required DetectionResult detection,
    BehavioralFeatures? features,
  }) {
    if (!detection.detected) {
      return const [];
    }

    final rawList = <RecommendationModel>[];
    final feat = features ?? detection.features;
    final now = DateTime.now();

    // 1. Cek Sinyal Sesi Panjang (Long Session)
    if (detection.type == DetectionType.longScrollSession ||
        detection.evidences.contains(DetectionEvidence.longSession)) {
      rawList.add(RecommendationModel(
        id: 'rec_break_long_${now.millisecondsSinceEpoch}',
        type: RecommendationType.digitalBreak,
        title: 'Jeda Digital',
        description:
            'Berikan jeda singkat dari aktivitas layar untuk menyegarkan fokus dan pikiranmu.',
        reason: 'Terdapat sesi scrolling yang berlangsung cukup lama.',
        actionLabel: 'Mulai Jeda',
        durationOptions:
            RecommendationDurations.forType(RecommendationType.digitalBreak),
        icon: 'spa_rounded',
        relatedDetection: detection.type,
        generatedAt: now,
      ));
    }

    // 2. Cek Sinyal Aktivitas Scrolling Tinggi (High Swipe)
    if (detection.type == DetectionType.highScrollActivity ||
        detection.evidences.contains(DetectionEvidence.highSwipeActivity)) {
      rawList.add(RecommendationModel(
        id: 'rec_break_swipe_${now.millisecondsSinceEpoch}',
        type: RecommendationType.digitalBreak,
        title: 'Jeda Digital',
        description:
            'Ambil jeda sejenak untuk menyeimbangkan frekuensi interaksi layarmu.',
        reason: 'Aktivitas swipe dan scrolling terpantau meningkat.',
        actionLabel: 'Mulai Jeda',
        durationOptions:
            RecommendationDurations.forType(RecommendationType.digitalBreak),
        icon: 'spa_rounded',
        relatedDetection: detection.type,
        generatedAt: now,
      ));
    }

    // 3. Cek Sinyal Sesi Berulang (Repeated Scrolling)
    if (detection.type == DetectionType.repeatedScrolling ||
        detection.evidences.contains(DetectionEvidence.repeatedScrolling)) {
      rawList.add(RecommendationModel(
        id: 'rec_focus_rep_${now.millisecondsSinceEpoch}',
        type: RecommendationType.focusMode,
        title: 'Mode Fokus',
        description:
            'Bantu pertahankan konsentrasi dengan mengurangi dorongan membuka kembali aplikasi secara berulang.',
        reason:
            'Beberapa sesi scrolling terjadi kembali dalam jeda waktu yang relatif singkat.',
        actionLabel: 'Aktifkan Fokus',
        durationOptions:
            RecommendationDurations.forType(RecommendationType.focusMode),
        icon: 'center_focus_strong_rounded',
        relatedDetection: detection.type,
        generatedAt: now,
      ));
    }

    // 4. Cek Sinyal Pola Malam (Night Scrolling Pattern)
    if (detection.type == DetectionType.nightScrollingPattern ||
        detection.evidences.contains(DetectionEvidence.nightPattern)) {
      rawList.add(RecommendationModel(
        id: 'rec_night_${now.millisecondsSinceEpoch}',
        type: RecommendationType.nightReminder,
        title: 'Pengingat Malam',
        description:
            'Kurangi paparan cahaya layar menjelang waktu istirahat malam demi kenyamanan tidurmu.',
        reason: 'Aktivitas scrolling terpantau terkonsentrasi pada malam hari.',
        actionLabel: 'Atur Pengingat',
        durationOptions:
            RecommendationDurations.forType(RecommendationType.nightReminder),
        icon: 'bedtime_rounded',
        relatedDetection: detection.type,
        generatedAt: now,
      ));
    }

    // 5. Cek Sinyal Pola Gulir Satu Arah (Downward Pattern)
    if (detection.evidences.contains(DetectionEvidence.downwardPattern) &&
        !detection.evidences.contains(DetectionEvidence.longSession) &&
        !detection.evidences.contains(DetectionEvidence.highSwipeActivity)) {
      rawList.add(RecommendationModel(
        id: 'rec_reflect_${now.millisecondsSinceEpoch}',
        type: RecommendationType.usageReflection,
        title: 'Refleksi Penggunaan',
        description:
            'Luangkan waktu sejenak untuk menyadari ritme dan tujuan penggunaan aplikasi secara bijak.',
        reason:
            'Pola scrolling satu arah secara kontinu teridentifikasi pada pemantauan.',
        actionLabel: 'Mulai Refleksi',
        durationOptions: RecommendationDurations.forType(
            RecommendationType.usageReflection),
        icon: 'psychology_rounded',
        relatedDetection: detection.type,
        generatedAt: now,
      ));
    }

    // 6. Cek Sinyal Konteks Mata (Contextual Eye Fatigue)
    if (detection.evidences.contains(DetectionEvidence.contextualEyeFatigue) ||
        (detection.contextualEyeNote != null &&
            detection.contextualEyeNote!.isNotEmpty)) {
      rawList.add(RecommendationModel(
        id: 'rec_eye_${now.millisecondsSinceEpoch}',
        type: RecommendationType.eyeRest,
        title: 'Istirahat Mata',
        description:
            'Istirahatkan pandangan dari layar dengan menerapkan aturan 20-20-20.',
        reason:
            'Parameter monitoring menunjukkan beberapa kejadian penutupan mata.',
        actionLabel: 'Istirahatkan Mata',
        durationOptions:
            RecommendationDurations.forType(RecommendationType.eyeRest),
        icon: 'visibility_off_rounded',
        relatedDetection: detection.type,
        generatedAt: now,
      ));
    }

    // 7. Cek Multi-Signal Scrolling Pattern
    if (detection.type == DetectionType.multiSignalScrollingPattern) {
      if (!rawList.any((r) => r.type == RecommendationType.digitalBreak)) {
        rawList.add(RecommendationModel(
          id: 'rec_break_multi_${now.millisecondsSinceEpoch}',
          type: RecommendationType.digitalBreak,
          title: 'Jeda Digital',
          description:
              'Ambil jeda singkat untuk menyegarkan fokus dan mengistirahatkan pandangan.',
          reason:
              'Beberapa pola penggunaan muncul bersamaan pada periode pemantauan.',
          actionLabel: 'Mulai Jeda',
          durationOptions:
              RecommendationDurations.forType(RecommendationType.digitalBreak),
          icon: 'spa_rounded',
          relatedDetection: detection.type,
          generatedAt: now,
        ));
      }
      if (!rawList.any((r) => r.type == RecommendationType.focusMode)) {
        rawList.add(RecommendationModel(
          id: 'rec_focus_multi_${now.millisecondsSinceEpoch}',
          type: RecommendationType.focusMode,
          title: 'Mode Fokus',
          description:
              'Batasi akses sementara ke aplikasi scrolling untuk mengembalikan produktivitas.',
          reason:
              'Sesi scrolling panjang dan interaksi berulang muncul secara simultan.',
          actionLabel: 'Aktifkan Fokus',
          durationOptions:
              RecommendationDurations.forType(RecommendationType.focusMode),
          icon: 'center_focus_strong_rounded',
          relatedDetection: detection.type,
          generatedAt: now,
        ));
      }
    }

    // Gabungkan duplikasi
    return mergeRecommendations(rawList, detection: detection, features: feat);
  }

  /// Menghasilkan rekomendasi berdasarkan [InsightModel]
  List<RecommendationModel> generateFromInsight({
    required InsightModel insight,
    BehavioralFeatures? features,
  }) {
    if (insight.suggestedAction == null || insight.suggestedAction!.isEmpty) {
      return const [];
    }

    final action = insight.suggestedAction!;
    final now = DateTime.now();

    if (action.contains('Fokus')) {
      return [
        RecommendationModel(
          id: 'rec_insight_focus_${now.millisecondsSinceEpoch}',
          type: RecommendationType.focusMode,
          title: 'Mode Fokus',
          description:
              'Batasi akses ke aplikasi tertentu selama waktu yang kamu pilih.',
          reason: insight.summary,
          actionLabel: 'Aktifkan Fokus',
          durationOptions:
              RecommendationDurations.forType(RecommendationType.focusMode),
          icon: 'center_focus_strong_rounded',
          generatedAt: now,
        ),
      ];
    }

    if (action.contains('Istirahat') || action.contains('Mata')) {
      return [
        RecommendationModel(
          id: 'rec_insight_eye_${now.millisecondsSinceEpoch}',
          type: RecommendationType.eyeRest,
          title: 'Istirahat Mata',
          description:
              'Pertimbangkan mengambil jeda dari layar dan rilekskan otot mata.',
          reason: insight.summary,
          actionLabel: 'Istirahatkan Mata',
          durationOptions:
              RecommendationDurations.forType(RecommendationType.eyeRest),
          icon: 'visibility_off_rounded',
          generatedAt: now,
        ),
      ];
    }

    // Default ke Jeda Digital
    return [
      RecommendationModel(
        id: 'rec_insight_break_${now.millisecondsSinceEpoch}',
        type: RecommendationType.digitalBreak,
        title: 'Jeda Digital',
        description: 'Berikan jeda singkat dari scrolling.',
        reason: insight.summary,
        actionLabel: 'Mulai Jeda',
        durationOptions:
            RecommendationDurations.forType(RecommendationType.digitalBreak),
        icon: 'spa_rounded',
        generatedAt: now,
      ),
    ];
  }

  /// Menghasilkan daftar rekomendasi terpadu untuk hari ini
  List<RecommendationModel> generateDailyRecommendations({
    required DetectionResult detection,
    List<InsightModel>? insights,
    BehavioralFeatures? features,
  }) {
    if (!detection.detected && (insights == null || insights.isEmpty)) {
      return const [];
    }

    final combinedList = <RecommendationModel>[];

    if (detection.detected) {
      combinedList.addAll(generateFromDetection(
        detection: detection,
        features: features,
      ));
    }

    if (insights != null) {
      for (final ins in insights) {
        if (ins.hasSuggestedAction) {
          final fromIns = generateFromInsight(insight: ins, features: features);
          combinedList.addAll(fromIns);
        }
      }
    }

    return mergeRecommendations(combinedList,
        detection: detection, features: features);
  }

  /// Menghapus duplikasi dan menggabungkan rekomendasi bertipe sama menjadi satu kartu kohesif
  List<RecommendationModel> mergeRecommendations(
    List<RecommendationModel> recommendations, {
    DetectionResult? detection,
    BehavioralFeatures? features,
  }) {
    if (recommendations.isEmpty) return const [];

    final Map<RecommendationType, List<RecommendationModel>> grouped = {};
    for (final rec in recommendations) {
      grouped.putIfAbsent(rec.type, () => []).add(rec);
    }

    final result = <RecommendationModel>[];

    for (final entry in grouped.entries) {
      final type = entry.key;
      final items = entry.value;

      if (items.length == 1) {
        result.add(items.first);
        continue;
      }

      // Gabungkan alasan jika lebih dari 1 item memiliki tipe yang sama
      String mergedReason = items.first.reason;
      if (type == RecommendationType.digitalBreak) {
        mergedReason =
            'Beberapa pola penggunaan menunjukkan sesi scrolling yang panjang dan berulang.';
      } else if (type == RecommendationType.focusMode) {
        mergedReason =
            'Aktivitas scrolling meningkat dengan frekuensi pembukaan aplikasi berulang.';
      }

      final representative = items.first;
      result.add(representative.copyWith(
        id: 'merged_${type.name}_${DateTime.now().millisecondsSinceEpoch}',
        reason: mergedReason,
      ));
    }

    // Urutkan prioritas tampilan rekomendasi
    result.sort((a, b) => _priorityOrder(a.type).compareTo(_priorityOrder(b.type)));

    return result;
  }

  int _priorityOrder(RecommendationType type) {
    switch (type) {
      case RecommendationType.digitalBreak:
        return 1;
      case RecommendationType.focusMode:
        return 2;
      case RecommendationType.eyeRest:
        return 3;
      case RecommendationType.nightReminder:
        return 4;
      case RecommendationType.usageReflection:
        return 5;
    }
  }
}
