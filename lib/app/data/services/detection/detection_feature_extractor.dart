import 'dart:math';
import '../../local/app_database.dart';
import '../../models/behavioral_features.dart';
import '../../models/doomscroll_session_model.dart';
import 'detection_thresholds.dart';

/// Adapter internal untuk membaca data sesi doomscroll dari berbagai tipe (Drift / Model)
class _SessionRecord {
  final DateTime startedAt;
  final DateTime? endedAt;
  final int durationMillis;
  final int swipeCount;
  final int downwardSwipeCount;
  final int upwardSwipeCount;
  final int avgInterSwipeMillis;
  final String appName;
  final String packageName;

  const _SessionRecord({
    required this.startedAt,
    this.endedAt,
    required this.durationMillis,
    required this.swipeCount,
    required this.downwardSwipeCount,
    required this.upwardSwipeCount,
    required this.avgInterSwipeMillis,
    required this.appName,
    required this.packageName,
  });

  factory _SessionRecord.fromData(DoomscrollSessionData data) {
    return _SessionRecord(
      startedAt: data.startedAt,
      endedAt: data.endedAt,
      durationMillis: data.durationMillis.toInt(),
      swipeCount: data.swipeCount,
      downwardSwipeCount: data.downwardSwipeCount,
      upwardSwipeCount: data.upwardSwipeCount,
      avgInterSwipeMillis: data.avgInterSwipeMillis.toInt(),
      appName: data.appName,
      packageName: data.packageName,
    );
  }

  factory _SessionRecord.fromModel(DoomscrollSessionModel model) {
    return _SessionRecord(
      startedAt: model.startedAt,
      endedAt: model.endedAt,
      durationMillis: model.durationMillis,
      swipeCount: model.swipeCount,
      downwardSwipeCount: model.downwardSwipeCount,
      upwardSwipeCount: model.upwardSwipeCount,
      avgInterSwipeMillis: model.avgInterSwipeMillis,
      appName: model.appName,
      packageName: model.packageName,
    );
  }

  static _SessionRecord? tryParse(dynamic item) {
    if (item is DoomscrollSessionData) {
      return _SessionRecord.fromData(item);
    } else if (item is DoomscrollSessionModel) {
      return _SessionRecord.fromModel(item);
    }
    return null;
  }
}

/// Komponen ekstraksi fitur perilaku (Behavioral Feature Extractor)
///
/// Menghitung parameter kuantitatif perilaku dari data riil pemantauan
/// tanpa membuat asumsi atau klaim diagnosis medis.
class DetectionFeatureExtractor {
  final DetectionThresholds _thresholds;

  const DetectionFeatureExtractor({
    DetectionThresholds thresholds = const DetectionThresholds(),
  }) : _thresholds = thresholds;

  /// Mengekstraksi fitur perilaku dari koleksi sesi dan total waktu layar
  BehavioralFeatures extract({
    required List<dynamic> rawSessions,
    required DateTime date,
    int totalScreenTimeMillis = 0,
  }) {
    if (rawSessions.isEmpty) {
      return BehavioralFeatures(
        date: date,
        totalScreenTimeMillis: totalScreenTimeMillis,
      );
    }

    final parsed = <_SessionRecord>[];
    for (final item in rawSessions) {
      final record = _SessionRecord.tryParse(item);
      if (record != null) {
        parsed.add(record);
      }
    }

    if (parsed.isEmpty) {
      return BehavioralFeatures(
        date: date,
        totalScreenTimeMillis: totalScreenTimeMillis,
      );
    }

    // Urutkan secara kronologis berdasarkan waktu mulai (startedAt asc)
    parsed.sort((a, b) => a.startedAt.compareTo(b.startedAt));

    final totalSessions = parsed.length;
    int totalDuration = 0;
    int totalSwipes = 0;
    int totalDownward = 0;
    int totalUpward = 0;
    int longestDuration = 0;
    int interSwipeSum = 0;
    int interSwipeCount = 0;

    int diniHariCount = 0;
    int morningCount = 0;
    int afternoonCount = 0;
    int eveningCount = 0;
    int nightCount = 0;

    final appDurations = <String, int>{};
    final appNames = <String>{};

    for (final s in parsed) {
      totalDuration += s.durationMillis;
      totalSwipes += s.swipeCount;
      totalDownward += s.downwardSwipeCount;
      totalUpward += s.upwardSwipeCount;

      if (s.durationMillis > longestDuration) {
        longestDuration = s.durationMillis;
      }

      if (s.avgInterSwipeMillis > 0) {
        interSwipeSum += s.avgInterSwipeMillis;
        interSwipeCount++;
      }

      // Klasifikasi segmen waktu lokal berdasarkan jam mulai sesi
      final hour = s.startedAt.hour;
      if (hour >= 0 && hour < 5) {
        diniHariCount++;
      } else if (hour >= 5 && hour < 11) {
        morningCount++;
      } else if (hour >= 11 && hour < 15) {
        afternoonCount++;
      } else if (hour >= 15 && hour < 18) {
        eveningCount++;
      } else {
        nightCount++;
      }

      // Frekuensi & durasi per aplikasi
      final name = s.appName.isNotEmpty ? s.appName : s.packageName;
      if (name.isNotEmpty) {
        appNames.add(name);
        appDurations[name] = (appDurations[name] ?? 0) + s.durationMillis;
      }
    }

    // Hitung rata-rata dan rasio
    final downwardRatio =
        totalSwipes > 0 ? (totalDownward / totalSwipes) : 0.0;
    final avgSessionDuration =
        totalSessions > 0 ? (totalDuration ~/ totalSessions) : 0;
    final avgSwipesPerSession =
        totalSessions > 0 ? (totalSwipes / totalSessions) : 0.0;
    final avgInterSwipe =
        interSwipeCount > 0 ? (interSwipeSum ~/ interSwipeCount) : 0;

    // Analisis jeda antar-sesi & pengulangan (Repeated Sessions)
    int repeatedCount = 0;
    int totalGaps = 0;
    int gapCount = 0;
    int longestGap = 0;
    int currentConsecutive = 1;
    int maxConsecutive = 1;

    for (int i = 0; i < parsed.length - 1; i++) {
      final current = parsed[i];
      final next = parsed[i + 1];

      final currentEnd = current.endedAt ??
          current.startedAt.add(Duration(milliseconds: current.durationMillis));
      final gap = max(0, next.startedAt.difference(currentEnd).inMilliseconds);

      totalGaps += gap;
      gapCount++;
      if (gap > longestGap) {
        longestGap = gap;
      }

      if (gap <= _thresholds.repeatedSessionGapMillis) {
        repeatedCount++;
        currentConsecutive++;
        if (currentConsecutive > maxConsecutive) {
          maxConsecutive = currentConsecutive;
        }
      } else {
        currentConsecutive = 1;
      }
    }

    final avgGap = gapCount > 0 ? (totalGaps ~/ gapCount) : 0;

    // Menemukan aplikasi scrolling paling dominan
    String? topApp;
    int maxAppDuration = -1;
    appDurations.forEach((app, dur) {
      if (dur > maxAppDuration) {
        maxAppDuration = dur;
        topApp = app;
      }
    });

    final sessionsPerHour = totalSessions / 24.0;

    return BehavioralFeatures(
      date: date,
      totalScrollingSessions: totalSessions,
      totalScrollingDurationMillis: totalDuration,
      totalSwipeCount: totalSwipes,
      totalDownwardSwipeCount: totalDownward,
      totalUpwardSwipeCount: totalUpward,
      downwardSwipeRatio: downwardRatio,
      averageInterSwipeMillis: avgInterSwipe,
      longestSessionDurationMillis: longestDuration,
      averageSessionDurationMillis: avgSessionDuration,
      repeatedSessionCount: repeatedCount,
      nightSessionCount: nightCount,
      diniHariSessionCount: diniHariCount,
      morningSessionCount: morningCount,
      afternoonSessionCount: afternoonCount,
      eveningSessionCount: eveningCount,
      topScrollingApp: topApp,
      totalScreenTimeMillis: totalScreenTimeMillis,
      sessionsPerHour: sessionsPerHour,
      averageSwipesPerSession: avgSwipesPerSession,
      averageSessionGapMillis: avgGap,
      longestSessionGapMillis: longestGap,
      consecutiveScrollingSessions: maxConsecutive,
      involvedApps: appNames.toList(),
    );
  }
}
