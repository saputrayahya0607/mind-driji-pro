/// Model data untuk sesi pemantauan mata (Eye Monitoring Session).
/// Menyimpan metrik numerik behavioral semata (EAR, penutupan mata, durasi).
/// PRIVASI: Tidak menyimpan gambar, video, frame, atau data biometrik visual wajah.
class EyeMonitoringSessionModel {
  final String id;
  final String? userId;
  final String deviceId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int durationMillis;
  final double averageEar;
  final double minEar;
  final int eyeClosureEvents;
  final int blinkCount;
  final DateTime collectedAt;
  final String syncStatus;

  const EyeMonitoringSessionModel({
    required this.id,
    this.userId,
    this.deviceId = 'legacy',
    required this.startedAt,
    this.endedAt,
    required this.durationMillis,
    required this.averageEar,
    required this.minEar,
    required this.eyeClosureEvents,
    required this.blinkCount,
    required this.collectedAt,
    this.syncStatus = 'pending',
  });

  factory EyeMonitoringSessionModel.fromNativeMap(
    Map<dynamic, dynamic> map, {
    String? defaultUserId,
    String? defaultDeviceId,
  }) {
    final rawStarted = map['startedAt'];
    final rawEnded = map['endedAt'];
    final rawCollected = map['collectedAt'];

    final started = rawStarted is num
        ? DateTime.fromMillisecondsSinceEpoch(rawStarted.toInt())
        : DateTime.now();

    final ended = rawEnded is num
        ? DateTime.fromMillisecondsSinceEpoch(rawEnded.toInt())
        : null;

    final collected = rawCollected is num
        ? DateTime.fromMillisecondsSinceEpoch(rawCollected.toInt())
        : (ended ?? DateTime.now());

    final dur = (map['durationMillis'] as num?)?.toInt() ??
        (ended != null ? ended.difference(started).inMilliseconds : 0);

    return EyeMonitoringSessionModel(
      id: map['id']?.toString() ?? '',
      userId: defaultUserId,
      deviceId: map['deviceId']?.toString() ??
          map['device_id']?.toString() ??
          defaultDeviceId ??
          'legacy',
      startedAt: started,
      endedAt: ended,
      durationMillis: dur,
      averageEar: (map['averageEar'] as num?)?.toDouble() ?? 0.0,
      minEar: (map['minEar'] as num?)?.toDouble() ?? 0.0,
      eyeClosureEvents: (map['eyeClosureEvents'] as num?)?.toInt() ?? 0,
      blinkCount: (map['blinkCount'] as num?)?.toInt() ?? 0,
      collectedAt: collected,
      syncStatus: 'pending',
    );
  }

  Map<String, dynamic> toSupabaseMap(
    String authenticatedUserId, {
    String? deviceIdOverride,
  }) {
    final validAverageEar =
        (averageEar.isNaN || averageEar.isInfinite) ? 0.0 : averageEar;
    final validMinEar = (minEar.isNaN || minEar.isInfinite) ? 0.0 : minEar;
    final validDuration = durationMillis < 0 ? 0 : durationMillis;
    final effectiveEndedAt =
        endedAt ?? startedAt.add(Duration(milliseconds: validDuration));
    final nowUtc = DateTime.now().toUtc().toIso8601String();

    return {
      'id': id,
      'user_id': authenticatedUserId,
      'device_id': deviceIdOverride ?? deviceId,
      'started_at': startedAt.toUtc().toIso8601String(),
      'ended_at': effectiveEndedAt.toUtc().toIso8601String(),
      'duration_millis': validDuration,
      'average_ear': validAverageEar,
      'min_ear': validMinEar,
      'eye_closure_events': eyeClosureEvents,
      'blink_count': blinkCount,
      'collected_at': collectedAt.toUtc().toIso8601String(),
      'created_at': nowUtc,
      'updated_at': nowUtc,
    };
  }

  EyeMonitoringSessionModel copyWith({
    String? id,
    String? userId,
    String? deviceId,
    DateTime? startedAt,
    DateTime? endedAt,
    int? durationMillis,
    double? averageEar,
    double? minEar,
    int? eyeClosureEvents,
    int? blinkCount,
    DateTime? collectedAt,
    String? syncStatus,
  }) {
    return EyeMonitoringSessionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      deviceId: deviceId ?? this.deviceId,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      durationMillis: durationMillis ?? this.durationMillis,
      averageEar: averageEar ?? this.averageEar,
      minEar: minEar ?? this.minEar,
      eyeClosureEvents: eyeClosureEvents ?? this.eyeClosureEvents,
      blinkCount: blinkCount ?? this.blinkCount,
      collectedAt: collectedAt ?? this.collectedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
