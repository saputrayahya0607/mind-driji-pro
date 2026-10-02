/// Konfigurasi dan konstanta untuk Automatic Periodic Eye Monitoring (MIND DRIJI).
class EyeMonitoringConstants {
  EyeMonitoringConstants._();

  /// Tag logging resmi untuk konsol/logcat
  static const String logTag = 'MIND_DRIJI_EYE';

  /// Interval default antar sesi pemantauan otomatis (30 menit)
  static const Duration defaultMonitoringInterval = Duration(minutes: 30);

  /// Durasi kamera aktif per sesi pemantauan (1 menit)
  static const Duration defaultSessionDuration = Duration(minutes: 1);

  /// Durasi minimum sesi untuk dianggap valid dan disimpan
  static const Duration minValidSessionDuration = Duration(seconds: 10);

  /// Interval pendek untuk keperluan testing / verifikasi cepat (10 detik)
  static const Duration testMonitoringInterval = Duration(seconds: 10);

  /// Durasi sesi pendek untuk keperluan testing / verifikasi cepat (10 detik)
  static const Duration testSessionDuration = Duration(seconds: 10);

  /// Cooldown notifikasi indikasi kelelahan mata agar tidak spam (15 menit)
  static const Duration fatigueNotificationCooldown = Duration(minutes: 15);

  /// Threshold jumlah event penutupan mata untuk potensi kelelahan
  static const int fatigueClosureEventsThreshold = 2;

  /// Threshold jumlah event penutupan mata untuk potensi kantuk
  static const int drowsinessClosureEventsThreshold = 4;

  /// Threshold rata-rata EAR untuk potensi kelelahan mata
  static const double fatigueAverageEarThreshold = 0.22;
}
