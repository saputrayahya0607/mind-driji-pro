/// Model representasi sesi scrolling realtime langsung dari Android AccessibilityService
class DoomscrollLiveSession {
  final String type; // 'session_started', 'session_updated', 'session_finished'
  final String id;
  final String packageName;
  final String appName;
  final DateTime startedAt;
  final int durationMillis;
  final int swipeCount;
  final int downwardSwipeCount;
  final int upwardSwipeCount;
  final int avgInterSwipeMillis;
  final bool isActive;

  const DoomscrollLiveSession({
    required this.type,
    required this.id,
    required this.packageName,
    required this.appName,
    required this.startedAt,
    required this.durationMillis,
    required this.swipeCount,
    required this.downwardSwipeCount,
    required this.upwardSwipeCount,
    required this.avgInterSwipeMillis,
    required this.isActive,
  });

  factory DoomscrollLiveSession.fromMap(Map<dynamic, dynamic> map) {
    final rawStartedAt = map['startedAt'];
    DateTime started;
    if (rawStartedAt is num) {
      started = DateTime.fromMillisecondsSinceEpoch(rawStartedAt.toInt());
    } else if (rawStartedAt is String) {
      started = DateTime.tryParse(rawStartedAt) ?? DateTime.now();
    } else {
      started = DateTime.now();
    }

    final rawType = map['type'] as String? ?? 'session_updated';
    final rawIsActive = map['isActive'] as bool? ?? (rawType != 'session_finished');

    return DoomscrollLiveSession(
      type: rawType,
      id: map['id']?.toString() ?? '',
      packageName: map['packageName']?.toString() ?? '',
      appName: map['appName']?.toString() ?? 'Aplikasi',
      startedAt: started,
      durationMillis: (map['durationMillis'] as num?)?.toInt() ?? 0,
      swipeCount: (map['swipeCount'] as num?)?.toInt() ?? 0,
      downwardSwipeCount: (map['downwardSwipeCount'] as num?)?.toInt() ?? 0,
      upwardSwipeCount: (map['upwardSwipeCount'] as num?)?.toInt() ?? 0,
      avgInterSwipeMillis: (map['avgInterSwipeMillis'] as num?)?.toInt() ?? 0,
      isActive: rawIsActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'id': id,
      'packageName': packageName,
      'appName': appName,
      'startedAt': startedAt.millisecondsSinceEpoch,
      'durationMillis': durationMillis,
      'swipeCount': swipeCount,
      'downwardSwipeCount': downwardSwipeCount,
      'upwardSwipeCount': upwardSwipeCount,
      'avgInterSwipeMillis': avgInterSwipeMillis,
      'isActive': isActive,
    };
  }

  @override
  String toString() {
    return 'DoomscrollLiveSession(type: $type, id: $id, app: $appName, swipes: $swipeCount, down: $downwardSwipeCount, up: $upwardSwipeCount, duration: ${durationMillis}ms, active: $isActive)';
  }
}
