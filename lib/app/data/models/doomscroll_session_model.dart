/// Model data untuk satu sesi scrolling (Doomscroll Session)
class DoomscrollSessionModel {
  final String id;
  final String? userId;
  final String deviceId;
  final String packageName;
  final String appName;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int durationMillis;
  final int swipeCount;
  final int downwardSwipeCount;
  final int upwardSwipeCount;
  final int avgInterSwipeMillis;
  final DateTime collectedAt;

  const DoomscrollSessionModel({
    required this.id,
    this.userId,
    this.deviceId = 'legacy',
    required this.packageName,
    required this.appName,
    required this.startedAt,
    this.endedAt,
    required this.durationMillis,
    required this.swipeCount,
    required this.downwardSwipeCount,
    required this.upwardSwipeCount,
    required this.avgInterSwipeMillis,
    required this.collectedAt,
  });

  factory DoomscrollSessionModel.fromMap(
    Map<dynamic, dynamic> map, {
    String? defaultUserId,
    String? defaultDeviceId,
  }) {
    DateTime parseDateTime(dynamic value) {
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      } else if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return DoomscrollSessionModel(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? map['user_id'] as String? ?? defaultUserId,
      deviceId: map['deviceId'] as String? ?? map['device_id'] as String? ?? defaultDeviceId ?? 'legacy',
      packageName: map['packageName'] as String? ?? map['package_name'] as String? ?? '',
      appName: map['appName'] as String? ?? map['app_name'] as String? ?? '',
      startedAt: parseDateTime(map['startedAt'] ?? map['started_at']),
      endedAt: map['endedAt'] != null || map['ended_at'] != null
          ? parseDateTime(map['endedAt'] ?? map['ended_at'])
          : null,
      durationMillis: (map['durationMillis'] as num?)?.toInt() ??
          (map['duration_millis'] as num?)?.toInt() ??
          0,
      swipeCount: (map['swipeCount'] as num?)?.toInt() ??
          (map['swipe_count'] as num?)?.toInt() ??
          0,
      downwardSwipeCount: (map['downwardSwipeCount'] as num?)?.toInt() ??
          (map['downward_swipe_count'] as num?)?.toInt() ??
          0,
      upwardSwipeCount: (map['upwardSwipeCount'] as num?)?.toInt() ??
          (map['upward_swipe_count'] as num?)?.toInt() ??
          0,
      avgInterSwipeMillis: (map['avgInterSwipeMillis'] as num?)?.toInt() ??
          (map['avg_inter_swipe_millis'] as num?)?.toInt() ??
          0,
      collectedAt: parseDateTime(map['collectedAt'] ?? map['collected_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      if (userId != null) 'user_id': userId,
      'device_id': deviceId,
      'package_name': packageName,
      'app_name': appName,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'duration_millis': durationMillis,
      'swipe_count': swipeCount,
      'downward_swipe_count': downwardSwipeCount,
      'upward_swipe_count': upwardSwipeCount,
      'avg_inter_swipe_millis': avgInterSwipeMillis,
      'collected_at': collectedAt.toIso8601String(),
    };
  }

  DoomscrollSessionModel copyWith({
    String? id,
    String? userId,
    String? deviceId,
    String? packageName,
    String? appName,
    DateTime? startedAt,
    DateTime? endedAt,
    int? durationMillis,
    int? swipeCount,
    int? downwardSwipeCount,
    int? upwardSwipeCount,
    int? avgInterSwipeMillis,
    DateTime? collectedAt,
  }) {
    return DoomscrollSessionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      deviceId: deviceId ?? this.deviceId,
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      durationMillis: durationMillis ?? this.durationMillis,
      swipeCount: swipeCount ?? this.swipeCount,
      downwardSwipeCount: downwardSwipeCount ?? this.downwardSwipeCount,
      upwardSwipeCount: upwardSwipeCount ?? this.upwardSwipeCount,
      avgInterSwipeMillis: avgInterSwipeMillis ?? this.avgInterSwipeMillis,
      collectedAt: collectedAt ?? this.collectedAt,
    );
  }
}
