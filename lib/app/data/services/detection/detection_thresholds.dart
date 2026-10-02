/// Konfigurasi ambang batas (Thresholds) untuk Detection Engine MIND DRIJI.
///
/// Seluruh nilai dapat dikonfigurasi secara terpusat untuk mempermudah kalibrasi
/// dan transisi ke model berbasis Machine Learning di tahap berikutnya.
class DetectionThresholds {
  /// Batas durasi satu sesi untuk dianggap sebagai sesi scrolling panjang.
  /// Default: 20 menit (1.200.000 ms)
  final int longSessionMillis;

  /// Batas total jumlah swipe dalam satu sesi atau akumulasi untuk aktivitas scrolling tinggi.
  /// Default: 300 swipe
  final int highScrollActivitySwipes;

  /// Batas jeda waktu maksimal (gap) antar sesi yang berdekatan untuk dianggap berulang.
  /// Default: 15 menit (900.000 ms)
  final int repeatedSessionGapMillis;

  /// Jumlah minimal pasangan sesi yang berulang dalam periode aktif.
  /// Default: 3 kali
  final int repeatedSessionThreshold;

  /// Rasio minimal scroll ke bawah (downward swipe) untuk mengindikasikan pola scrolling satu arah kontinu.
  /// Default: 0.75 (75%)
  final double downwardSwipeRatioThreshold;

  /// Jumlah minimal sesi pada rentang malam (18:00–23:59) untuk pola scrolling malam.
  /// Default: 3 sesi
  final int nightSessionThreshold;

  /// Jumlah minimal sesi malam + dini hari untuk sinyal waktu malam
  final int combinedNightSessionThreshold;

  /// Batas minimal total sesi untuk mempertimbangkan pola multi-signal.
  /// Default: 3 sesi
  final int multiSignalSessionThreshold;

  /// Batas minimal jumlah kedipan atau penutupan mata untuk konteks kelelahan mata
  final int contextualEyeClosureThreshold;

  const DetectionThresholds({
    this.longSessionMillis = 20 * 60 * 1000, // 20 menit
    this.highScrollActivitySwipes = 300,
    this.repeatedSessionGapMillis = 15 * 60 * 1000, // 15 menit
    this.repeatedSessionThreshold = 3,
    this.downwardSwipeRatioThreshold = 0.75,
    this.nightSessionThreshold = 3,
    this.combinedNightSessionThreshold = 3,
    this.multiSignalSessionThreshold = 3,
    this.contextualEyeClosureThreshold = 5,
  });

  /// Salinan dengan parameter yang diubah untuk keperluan pengujian / kalibrasi
  DetectionThresholds copyWith({
    int? longSessionMillis,
    int? highScrollActivitySwipes,
    int? repeatedSessionGapMillis,
    int? repeatedSessionThreshold,
    double? downwardSwipeRatioThreshold,
    int? nightSessionThreshold,
    int? combinedNightSessionThreshold,
    int? multiSignalSessionThreshold,
    int? contextualEyeClosureThreshold,
  }) {
    return DetectionThresholds(
      longSessionMillis: longSessionMillis ?? this.longSessionMillis,
      highScrollActivitySwipes:
          highScrollActivitySwipes ?? this.highScrollActivitySwipes,
      repeatedSessionGapMillis:
          repeatedSessionGapMillis ?? this.repeatedSessionGapMillis,
      repeatedSessionThreshold:
          repeatedSessionThreshold ?? this.repeatedSessionThreshold,
      downwardSwipeRatioThreshold:
          downwardSwipeRatioThreshold ?? this.downwardSwipeRatioThreshold,
      nightSessionThreshold:
          nightSessionThreshold ?? this.nightSessionThreshold,
      combinedNightSessionThreshold:
          combinedNightSessionThreshold ?? this.combinedNightSessionThreshold,
      multiSignalSessionThreshold:
          multiSignalSessionThreshold ?? this.multiSignalSessionThreshold,
      contextualEyeClosureThreshold:
          contextualEyeClosureThreshold ?? this.contextualEyeClosureThreshold,
    );
  }
}
