import '../../core/utils/duration_formatter.dart';

enum MonitoringPeriod { daily, weekly, monthly }

/// Konstanta label segmen waktu harian (MIND DRIJI)
class DailyTimeSegment {
  static const String diniHari = 'Dini Hari';
  static const String pagi = 'Pagi';
  static const String siang = 'Siang';
  static const String sore = 'Sore';
  static const String malam = 'Malam';
}

/// Representasi segmen waktu harian (Dini Hari, Pagi, Siang, Sore, Malam)
class TimeSegmentUsage {
  final String label;
  final String timeRange;
  final int startHour;
  final int endHour;
  final int screenTimeMillis;
  final int doomscrollMillis;
  final int doomscrollSwipes;

  const TimeSegmentUsage({
    required this.label,
    required this.timeRange,
    required this.startHour,
    required this.endHour,
    required this.screenTimeMillis,
    required this.doomscrollMillis,
    required this.doomscrollSwipes,
  });

  String get screenTimeFormatted => DurationFormatter.format(screenTimeMillis);
  String get doomscrollFormatted => DurationFormatter.format(doomscrollMillis);
  bool get hasData => screenTimeMillis > 0 || doomscrollMillis > 0;
}

/// Representasi agregasi harian untuk tab Mingguan (Senin - Minggu)
class DayUsage {
  final DateTime date;
  final String dayName;
  final String shortDayName;
  final int screenTimeMillis;
  final int doomscrollMillis;
  final int doomscrollSwipes;

  const DayUsage({
    required this.date,
    required this.dayName,
    required this.shortDayName,
    required this.screenTimeMillis,
    required this.doomscrollMillis,
    required this.doomscrollSwipes,
  });

  String get screenTimeFormatted => DurationFormatter.format(screenTimeMillis);
  String get doomscrollFormatted => DurationFormatter.format(doomscrollMillis);
  bool get hasData => screenTimeMillis > 0 || doomscrollMillis > 0;
}

/// Representasi agregasi mingguan dalam satu bulan (Week 1 - Week 5)
class WeekUsage {
  final int weekNumber;
  final String label;
  final DateTime startDate;
  final DateTime endDate;
  final int screenTimeMillis;
  final int doomscrollMillis;
  final int doomscrollSwipes;

  const WeekUsage({
    required this.weekNumber,
    required this.label,
    required this.startDate,
    required this.endDate,
    required this.screenTimeMillis,
    required this.doomscrollMillis,
    required this.doomscrollSwipes,
  });

  String get screenTimeFormatted => DurationFormatter.format(screenTimeMillis);
  String get doomscrollFormatted => DurationFormatter.format(doomscrollMillis);
  bool get hasData => screenTimeMillis > 0 || doomscrollMillis > 0;
}

/// Ringkasan sesi doomscrolling untuk periode aktif
class DoomscrollSummary {
  final int totalSessions;
  final int totalDurationMillis;
  final int totalSwipes;
  final int downwardSwipes;
  final int upwardSwipes;

  const DoomscrollSummary({
    this.totalSessions = 0,
    this.totalDurationMillis = 0,
    this.totalSwipes = 0,
    this.downwardSwipes = 0,
    this.upwardSwipes = 0,
  });

  String get durationFormatted => DurationFormatter.format(totalDurationMillis);
  bool get hasData => totalSessions > 0 || totalDurationMillis > 0 || totalSwipes > 0;
}

/// Ringkasan sesi eye monitoring untuk periode aktif
class EyeMonitoringSummary {
  final int totalSessions;
  final int totalDurationMillis;
  final double? averageEar;
  final int eyeClosureEvents;
  final int blinkCount;

  const EyeMonitoringSummary({
    this.totalSessions = 0,
    this.totalDurationMillis = 0,
    this.averageEar,
    this.eyeClosureEvents = 0,
    this.blinkCount = 0,
  });

  String get durationFormatted => DurationFormatter.format(totalDurationMillis);
  bool get hasData => totalSessions > 0 || totalDurationMillis > 0;
}
