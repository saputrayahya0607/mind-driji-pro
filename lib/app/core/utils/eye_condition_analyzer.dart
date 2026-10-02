import '../constants/eye_monitoring_constants.dart';
import '../../data/models/eye_monitoring_session_model.dart';

/// Level indikasi kondisi kelelahan/kebugaran mata (non-medis, behavioral).
enum EyeConditionLevel {
  normal,
  potentialFatigue,
  potentialDrowsiness,
}

/// Hasil analisis kondisi mata per sesi pemantauan.
class EyeConditionResult {
  final EyeConditionLevel level;
  final String title;
  final String message;
  final String disclaimer;
  final bool indicatesFatigueOrDrowsiness;

  const EyeConditionResult({
    required this.level,
    required this.title,
    required this.message,
    required this.disclaimer,
    required this.indicatesFatigueOrDrowsiness,
  });

  @override
  String toString() =>
      'EyeConditionResult(level: $level, title: "$title", message: "$message")';
}

/// Analyzer terpisah untuk mengevaluasi pola kedipan dan keterbukaan mata (EAR).
///
/// PERNYATAAN INTEGRITAS & PRIVASI:
/// 1. Logika ini BUKAN diagnosis medis dan TIDAK mengklaim standar klinis.
/// 2. Hasil evaluasi disajikan sebagai "indikasi" atau "kemungkinan" kebiasaan digital wellness.
/// 3. Dilengkapi sistem cooldown untuk mencegah spam notifikasi ke pengguna.
class EyeConditionAnalyzer {
  final int fatigueClosureEventsThreshold;
  final int drowsinessClosureEventsThreshold;
  final double fatigueAverageEarThreshold;
  final Duration cooldownDuration;

  DateTime? _lastNotificationTime;

  EyeConditionAnalyzer({
    int? fatigueClosureEventsThreshold,
    int? drowsinessClosureEventsThreshold,
    double? fatigueAverageEarThreshold,
    Duration? cooldownDuration,
  })  : fatigueClosureEventsThreshold = fatigueClosureEventsThreshold ??
            EyeMonitoringConstants.fatigueClosureEventsThreshold,
        drowsinessClosureEventsThreshold = drowsinessClosureEventsThreshold ??
            EyeMonitoringConstants.drowsinessClosureEventsThreshold,
        fatigueAverageEarThreshold = fatigueAverageEarThreshold ??
            EyeMonitoringConstants.fatigueAverageEarThreshold,
        cooldownDuration = cooldownDuration ??
            EyeMonitoringConstants.fatigueNotificationCooldown;

  DateTime? get lastNotificationTime => _lastNotificationTime;

  /// Menganalisis metrik sesi dan menentukan indikasi kondisi mata
  EyeConditionResult analyzeSession(EyeMonitoringSessionModel session) {
    const disclaimer =
        'Indikator kebiasaan digital wellness, bukan diagnosa ataupun standar medis.';

    // Sesi terlalu singkat (<10 detik) dianggap tidak mencukupi untuk evaluasi
    if (session.durationMillis < EyeMonitoringConstants.minValidSessionDuration.inMilliseconds) {
      return const EyeConditionResult(
        level: EyeConditionLevel.normal,
        title: 'Kondisi Normal',
        message: 'Durasi pemantauan belum mencukupi untuk analisis.',
        disclaimer: disclaimer,
        indicatesFatigueOrDrowsiness: false,
      );
    }

    final closures = session.eyeClosureEvents;
    final avgEar = session.averageEar;

    // 1. Potensi Mengantuk (Penutupan mata berulang / berkepanjangan)
    if (closures >= drowsinessClosureEventsThreshold) {
      return const EyeConditionResult(
        level: EyeConditionLevel.potentialDrowsiness,
        title: 'Indikasi Kondisi Mata',
        message:
            'Kamu mungkin mulai mengantuk. Coba istirahat sejenak untuk menyegarkan mata.',
        disclaimer: disclaimer,
        indicatesFatigueOrDrowsiness: true,
      );
    }

    // 2. Potensi Kelelahan Mata (Prolonged closure meningkat atau EAR rendah)
    if (closures >= fatigueClosureEventsThreshold ||
        (avgEar < fatigueAverageEarThreshold && avgEar > 0.0)) {
      return const EyeConditionResult(
        level: EyeConditionLevel.potentialFatigue,
        title: 'Indikasi Kondisi Mata',
        message:
            'Terlihat indikasi mata mulai lelah. Disarankan mengistirahatkan pandangan sejenak.',
        disclaimer: disclaimer,
        indicatesFatigueOrDrowsiness: true,
      );
    }

    // 3. Normal
    return const EyeConditionResult(
      level: EyeConditionLevel.normal,
      title: 'Kondisi Normal',
      message: 'Pola keterbukaan dan kedipan mata berada dalam rentang wajar.',
      disclaimer: disclaimer,
      indicatesFatigueOrDrowsiness: false,
    );
  }

  /// Memeriksa apakah notifikasi diizinkan dikirim berdasarkan cooldown
  bool canSendNotification(EyeConditionResult result, {DateTime? now}) {
    if (!result.indicatesFatigueOrDrowsiness) return false;

    final currentTime = now ?? DateTime.now();
    if (_lastNotificationTime == null) return true;

    final elapsed = currentTime.difference(_lastNotificationTime!);
    return elapsed >= cooldownDuration;
  }

  /// Mencatat waktu notifikasi terkirim untuk mengaktifkan cooldown
  void recordNotificationSent(DateTime sentAt) {
    _lastNotificationTime = sentAt;
  }

  /// Mengatur ulang cooldown (misal untuk testing / service re-enable)
  void resetCooldown() {
    _lastNotificationTime = null;
  }
}
