/// Model data fitur perilaku (Behavioral Features) yang diekstraksi dari data riil
/// sesi pemantauan scrolling dan screen time MIND DRIJI.
class BehavioralFeatures {
  final DateTime date;
  final int totalScrollingSessions;
  final int totalScrollingDurationMillis;
  final int totalSwipeCount;
  final int totalDownwardSwipeCount;
  final int totalUpwardSwipeCount;
  final double downwardSwipeRatio;
  final int averageInterSwipeMillis;
  final int longestSessionDurationMillis;
  final int averageSessionDurationMillis;
  final int repeatedSessionCount;
  final int nightSessionCount; // Malam (18:00–23:59)
  final int diniHariSessionCount; // Dini Hari (00:00–04:59)
  final int morningSessionCount; // Pagi (05:00–10:59)
  final int afternoonSessionCount; // Siang (11:00–14:59)
  final int eveningSessionCount; // Sore (15:00–17:59)
  final String? topScrollingApp;
  final int totalScreenTimeMillis;

  // Fitur perilaku tambahan
  final double sessionsPerHour;
  final double averageSwipesPerSession;
  final int averageSessionGapMillis;
  final int longestSessionGapMillis;
  final int consecutiveScrollingSessions;
  final List<String> involvedApps;

  const BehavioralFeatures({
    required this.date,
    this.totalScrollingSessions = 0,
    this.totalScrollingDurationMillis = 0,
    this.totalSwipeCount = 0,
    this.totalDownwardSwipeCount = 0,
    this.totalUpwardSwipeCount = 0,
    this.downwardSwipeRatio = 0.0,
    this.averageInterSwipeMillis = 0,
    this.longestSessionDurationMillis = 0,
    this.averageSessionDurationMillis = 0,
    this.repeatedSessionCount = 0,
    this.nightSessionCount = 0,
    this.diniHariSessionCount = 0,
    this.morningSessionCount = 0,
    this.afternoonSessionCount = 0,
    this.eveningSessionCount = 0,
    this.topScrollingApp,
    this.totalScreenTimeMillis = 0,
    this.sessionsPerHour = 0.0,
    this.averageSwipesPerSession = 0.0,
    this.averageSessionGapMillis = 0,
    this.longestSessionGapMillis = 0,
    this.consecutiveScrollingSessions = 0,
    this.involvedApps = const [],
  });

  /// Factory untuk kondisi kosong saat tidak ada data sesi sama sekali
  factory BehavioralFeatures.empty(DateTime date) {
    return BehavioralFeatures(date: date);
  }

  bool get hasSessions => totalScrollingSessions > 0;

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'totalScrollingSessions': totalScrollingSessions,
      'totalScrollingDurationMillis': totalScrollingDurationMillis,
      'totalSwipeCount': totalSwipeCount,
      'totalDownwardSwipeCount': totalDownwardSwipeCount,
      'totalUpwardSwipeCount': totalUpwardSwipeCount,
      'downwardSwipeRatio': downwardSwipeRatio,
      'averageInterSwipeMillis': averageInterSwipeMillis,
      'longestSessionDurationMillis': longestSessionDurationMillis,
      'averageSessionDurationMillis': averageSessionDurationMillis,
      'repeatedSessionCount': repeatedSessionCount,
      'nightSessionCount': nightSessionCount,
      'diniHariSessionCount': diniHariSessionCount,
      'morningSessionCount': morningSessionCount,
      'afternoonSessionCount': afternoonSessionCount,
      'eveningSessionCount': eveningSessionCount,
      'topScrollingApp': topScrollingApp,
      'totalScreenTimeMillis': totalScreenTimeMillis,
      'sessionsPerHour': sessionsPerHour,
      'averageSwipesPerSession': averageSwipesPerSession,
      'averageSessionGapMillis': averageSessionGapMillis,
      'longestSessionGapMillis': longestSessionGapMillis,
      'consecutiveScrollingSessions': consecutiveScrollingSessions,
      'involvedApps': involvedApps,
    };
  }

  factory BehavioralFeatures.fromJson(Map<String, dynamic> json) {
    return BehavioralFeatures(
      date: DateTime.parse(json['date'] as String),
      totalScrollingSessions: (json['totalScrollingSessions'] as num?)?.toInt() ?? 0,
      totalScrollingDurationMillis:
          (json['totalScrollingDurationMillis'] as num?)?.toInt() ?? 0,
      totalSwipeCount: (json['totalSwipeCount'] as num?)?.toInt() ?? 0,
      totalDownwardSwipeCount:
          (json['totalDownwardSwipeCount'] as num?)?.toInt() ?? 0,
      totalUpwardSwipeCount:
          (json['totalUpwardSwipeCount'] as num?)?.toInt() ?? 0,
      downwardSwipeRatio:
          (json['downwardSwipeRatio'] as num?)?.toDouble() ?? 0.0,
      averageInterSwipeMillis:
          (json['averageInterSwipeMillis'] as num?)?.toInt() ?? 0,
      longestSessionDurationMillis:
          (json['longestSessionDurationMillis'] as num?)?.toInt() ?? 0,
      averageSessionDurationMillis:
          (json['averageSessionDurationMillis'] as num?)?.toInt() ?? 0,
      repeatedSessionCount:
          (json['repeatedSessionCount'] as num?)?.toInt() ?? 0,
      nightSessionCount: (json['nightSessionCount'] as num?)?.toInt() ?? 0,
      diniHariSessionCount:
          (json['diniHariSessionCount'] as num?)?.toInt() ?? 0,
      morningSessionCount: (json['morningSessionCount'] as num?)?.toInt() ?? 0,
      afternoonSessionCount:
          (json['afternoonSessionCount'] as num?)?.toInt() ?? 0,
      eveningSessionCount: (json['eveningSessionCount'] as num?)?.toInt() ?? 0,
      topScrollingApp: json['topScrollingApp'] as String?,
      totalScreenTimeMillis:
          (json['totalScreenTimeMillis'] as num?)?.toInt() ?? 0,
      sessionsPerHour: (json['sessionsPerHour'] as num?)?.toDouble() ?? 0.0,
      averageSwipesPerSession:
          (json['averageSwipesPerSession'] as num?)?.toDouble() ?? 0.0,
      averageSessionGapMillis:
          (json['averageSessionGapMillis'] as num?)?.toInt() ?? 0,
      longestSessionGapMillis:
          (json['longestSessionGapMillis'] as num?)?.toInt() ?? 0,
      consecutiveScrollingSessions:
          (json['consecutiveScrollingSessions'] as num?)?.toInt() ?? 0,
      involvedApps: (json['involvedApps'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}
