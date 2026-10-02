class AppUsageModel {
  final String packageName;
  final String appName;
  final int usageMillis;

  const AppUsageModel({
    required this.packageName,
    required this.appName,
    required this.usageMillis,
  });

  factory AppUsageModel.fromMap(Map<dynamic, dynamic> map) {
    return AppUsageModel(
      packageName: map['packageName'] as String? ?? '',
      appName: map['appName'] as String? ??
          (map['packageName'] as String? ?? 'Aplikasi'),
      usageMillis: (map['usageMillis'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'packageName': packageName,
      'appName': appName,
      'usageMillis': usageMillis,
    };
  }
}

class UsageInterval {
  final DateTime startTime;
  final DateTime endTime;
  final String? packageName;

  const UsageInterval({
    required this.startTime,
    required this.endTime,
    this.packageName,
  });

  int get durationMillis {
    if (!endTime.isAfter(startTime)) return 0;
    return endTime.difference(startTime).inMilliseconds;
  }

  Map<String, dynamic> toMap() {
    return {
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime.millisecondsSinceEpoch,
      if (packageName != null) 'packageName': packageName,
    };
  }

  factory UsageInterval.fromMap(Map<dynamic, dynamic> map) {
    final s = (map['startTime'] as num?)?.toInt() ?? 0;
    final e = (map['endTime'] as num?)?.toInt() ?? 0;
    return UsageInterval(
      startTime: DateTime.fromMillisecondsSinceEpoch(s),
      endTime: DateTime.fromMillisecondsSinceEpoch(e),
      packageName: map['packageName'] as String?,
    );
  }
}

class UsageStatsModel {
  final int totalUsageMillis;
  final List<AppUsageModel> apps;
  final List<UsageInterval> intervals;
  final int? startTime;
  final int? endTime;

  const UsageStatsModel({
    required this.totalUsageMillis,
    required this.apps,
    this.intervals = const [],
    this.startTime,
    this.endTime,
  });

  factory UsageStatsModel.fromMap(Map<dynamic, dynamic> map) {
    final rawApps = map['apps'] as List<dynamic>? ?? [];
    final apps = rawApps
        .whereType<Map<dynamic, dynamic>>()
        .map((appMap) => AppUsageModel.fromMap(appMap))
        .where((app) => app.usageMillis > 0)
        .toList();

    final rawIntervals = map['intervals'] as List<dynamic>? ?? [];
    final intervals = rawIntervals
        .whereType<Map<dynamic, dynamic>>()
        .map((intMap) => UsageInterval.fromMap(intMap))
        .where((interval) => interval.durationMillis > 0)
        .toList();

    return UsageStatsModel(
      totalUsageMillis: (map['totalUsageMillis'] as num?)?.toInt() ?? 0,
      apps: apps,
      intervals: intervals,
      startTime: (map['startTime'] as num?)?.toInt(),
      endTime: (map['endTime'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalUsageMillis': totalUsageMillis,
      'apps': apps.map((a) => a.toMap()).toList(),
      'intervals': intervals.map((i) => i.toMap()).toList(),
      'startTime': startTime,
      'endTime': endTime,
    };
  }
}

