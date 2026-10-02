import '../../../core/utils/duration_formatter.dart';
import '../../models/behavioral_features.dart';
import '../../models/detection_result.dart';
import '../../models/monitoring_visualization_model.dart';
import 'detection_strategy.dart';
import 'detection_thresholds.dart';

/// Implementasi strategi deteksi berbasis aturan deterministik (Rule-Based).
///
/// Menggunakan sinyal perilaku terukur dari data nyata:
/// - Durasi sesi terpanjang
/// - Frekuensi dan pengulangan sesi
/// - Akumulasi jumlah swipe
/// - Rasio swipe ke bawah
/// - Distribusi waktu sesi (malam / dini hari)
/// - Konteks kelelahan mata (sebagai sinyal kontekstual)
class RuleBasedDetectionStrategy implements DetectionStrategy {
  @override
  DetectionResult detect(
    BehavioralFeatures features, {
    EyeMonitoringSummary? contextualEye,
    DetectionThresholds thresholds = const DetectionThresholds(),
  }) {
    // Jika tidak ada sesi atau data tidak mencukupi, kembalikan none
    if (!features.hasSessions) {
      return DetectionResult.none(
        date: features.date,
        features: features,
        note: 'Belum ada data sesi scrolling pada periode ini.',
      );
    }

    final evidences = <DetectionEvidence>[];

    // Sinyal A: Long Session
    final isLongSession =
        features.longestSessionDurationMillis >= thresholds.longSessionMillis;
    if (isLongSession) {
      evidences.add(DetectionEvidence.longSession);
    }

    // Sinyal B: High Scroll Activity
    final isHighSwipe =
        features.totalSwipeCount >= thresholds.highScrollActivitySwipes;
    if (isHighSwipe) {
      evidences.add(DetectionEvidence.highSwipeActivity);
    }

    // Sinyal C: Repeated Scrolling
    final isRepeated =
        features.repeatedSessionCount >= thresholds.repeatedSessionThreshold;
    if (isRepeated) {
      evidences.add(DetectionEvidence.repeatedScrolling);
    }

    // Sinyal D: Continuous Downward Scrolling (minimal 50 swipe agar tidak bias)
    final isDownward =
        features.totalSwipeCount >= 50 &&
        features.downwardSwipeRatio >= thresholds.downwardSwipeRatioThreshold;
    if (isDownward) {
      evidences.add(DetectionEvidence.downwardPattern);
    }

    // Sinyal E: Night Scrolling Pattern
    final isNightPattern =
        (features.nightSessionCount + features.diniHariSessionCount) >=
        thresholds.combinedNightSessionThreshold;
    if (isNightPattern) {
      evidences.add(DetectionEvidence.nightPattern);
    }

    // Sinyal Kontekstual F: Eye Monitoring (BUKAN bukti utama / diagnosis)
    String? contextualEyeNote;
    if (contextualEye != null && contextualEye.hasData) {
      final isHighClosures =
          contextualEye.eyeClosureEvents >= thresholds.contextualEyeClosureThreshold;
      final isLowEar =
          contextualEye.averageEar != null && contextualEye.averageEar! < 0.22;

      if (isHighClosures || isLowEar) {
        evidences.add(DetectionEvidence.contextualEyeFatigue);
        contextualEyeNote =
            'Pada periode penggunaan tersebut juga tercatat indikasi mata lelah '
            'berdasarkan parameter monitoring aplikasi (${contextualEye.eyeClosureEvents} kejadian penutupan mata).';
      }
    }

    // Evaluasi sinyal behavioral (tanpa contextualEye)
    final behavioralEvidenceCount = evidences
        .where((e) => e != DetectionEvidence.contextualEyeFatigue)
        .length;

    if (behavioralEvidenceCount == 0) {
      return DetectionResult.none(
        date: features.date,
        features: features,
        note: 'Pola penggunaan aplikasi berada dalam rentang wajar berdasarkan parameter pemantauan.',
      );
    }

    // Sinyal utama (Major behavioral signals)
    final majorEvidenceCount = [
      isLongSession,
      isHighSwipe,
      isRepeated,
      isNightPattern,
    ].where((b) => b).length;

    // Multi-signal: jika terdapat minimal 2 sinyal utama dan minimal ambang sesi
    if (majorEvidenceCount >= 2 &&
        features.totalScrollingSessions >= thresholds.multiSignalSessionThreshold) {
      return DetectionResult(
        detected: true,
        type: DetectionType.multiSignalScrollingPattern,
        features: features,
        evidences: evidences,
        detectedAt: DateTime.now(),
        relatedApps: features.involvedApps,
        title: 'Pola scrolling multi-sinyal terdeteksi',
        description:
            'Kombinasi sesi berulang, durasi panjang, dan intensitas navigasi tinggi '
            'tercatat secara bersamaan pada periode pemantauan.',
        suggestedIntervention: 'Mode Fokus',
        contextualEyeNote: contextualEyeNote,
      );
    }

    // Single-signal detection types
    if (isLongSession) {
      final formattedDuration =
          DurationFormatter.format(features.longestSessionDurationMillis);
      return DetectionResult(
        detected: true,
        type: DetectionType.longScrollSession,
        features: features,
        evidences: evidences,
        detectedAt: DateTime.now(),
        relatedApps: features.involvedApps,
        title: 'Sesi scrolling panjang terdeteksi',
        description:
            'Terdapat sesi penggunaan aplikasi yang berlangsung selama $formattedDuration '
            'secara berkelanjutan.',
        suggestedIntervention: 'Jeda Digital',
        contextualEyeNote: contextualEyeNote,
      );
    }

    if (isRepeated) {
      return DetectionResult(
        detected: true,
        type: DetectionType.repeatedScrolling,
        features: features,
        evidences: evidences,
        detectedAt: DateTime.now(),
        relatedApps: features.involvedApps,
        title: 'Sesi scrolling berulang terdeteksi',
        description:
            'Terdeteksi ${features.repeatedSessionCount} kali sesi scrolling '
            'yang dilakukan dalam jeda waktu relatif singkat.',
        suggestedIntervention: 'Jeda Digital',
        contextualEyeNote: contextualEyeNote,
      );
    }

    if (isHighSwipe) {
      return DetectionResult(
        detected: true,
        type: DetectionType.highScrollActivity,
        features: features,
        evidences: evidences,
        detectedAt: DateTime.now(),
        relatedApps: features.involvedApps,
        title: 'Aktivitas scrolling meningkat',
        description:
            'Frekuensi navigasi dan interaksi scrolling tercatat tinggi '
            '(${features.totalSwipeCount} swipe) pada periode pemantauan.',
        suggestedIntervention: 'Mode Fokus',
        contextualEyeNote: contextualEyeNote,
      );
    }

    if (isNightPattern) {
      return DetectionResult(
        detected: true,
        type: DetectionType.nightScrollingPattern,
        features: features,
        evidences: evidences,
        detectedAt: DateTime.now(),
        relatedApps: features.involvedApps,
        title: 'Kecenderungan pola scrolling malam hari',
        description:
            'Aktivitas scrolling terpusat pada rentang waktu malam hari '
            'berdasarkan catatan penggunaan.',
        suggestedIntervention: 'Pengingat Istirahat Malam',
        contextualEyeNote: contextualEyeNote,
      );
    }

    // Default fallback jika ada bukti seperti downward pattern tunggal
    return DetectionResult(
      detected: true,
      type: DetectionType.highScrollActivity,
      features: features,
      evidences: evidences,
      detectedAt: DateTime.now(),
      relatedApps: features.involvedApps,
      title: 'Pola scrolling terdeteksi',
      description:
          'Kecenderungan interaksi scrolling satu arah berkelanjutan tercatat '
          'pada periode pemantauan.',
      suggestedIntervention: 'Jeda Digital',
      contextualEyeNote: contextualEyeNote,
    );
  }
}
