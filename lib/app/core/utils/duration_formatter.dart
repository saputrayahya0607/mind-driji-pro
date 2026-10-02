class DurationFormatter {
  DurationFormatter._();

  /// Memformat durasi dalam milidetik menjadi representasi waktu ramah pengguna:
  /// - < 1 menit: "< 1m" (atau "0m" jika 0)
  /// - < 1 jam: "35m"
  /// - >= 1 jam: "2j 35m"
  static String format(int millis) {
    if (millis <= 0) return '0m';

    final totalMinutes = millis ~/ 60000;
    if (totalMinutes < 1) {
      return '< 1m';
    }

    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours < 1) {
      return '${minutes}m';
    }

    if (minutes == 0) {
      return '${hours}j';
    }

    return '${hours}j ${minutes}m';
  }
}
