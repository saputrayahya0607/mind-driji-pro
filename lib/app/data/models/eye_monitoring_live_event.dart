/// Event realtime status Eye Monitoring langsung dari native CameraX + MediaPipe
class EyeMonitoringLiveEvent {
  final String type;
  final bool isMonitoring;
  final bool faceDetected;
  final bool multipleFaces;
  final bool measurementValid;
  final double currentEar;
  final double averageEar;
  final double minEar;
  final int eyeClosureEvents;
  final int blinkCount;
  final int durationMillis;
  final String statusMessage;

  const EyeMonitoringLiveEvent({
    required this.type,
    required this.isMonitoring,
    required this.faceDetected,
    required this.multipleFaces,
    this.measurementValid = false,
    required this.currentEar,
    required this.averageEar,
    required this.minEar,
    required this.eyeClosureEvents,
    required this.blinkCount,
    required this.durationMillis,
    required this.statusMessage,
  });

  factory EyeMonitoringLiveEvent.fromMap(Map<dynamic, dynamic> map) {
    return EyeMonitoringLiveEvent(
      type: map['type']?.toString() ?? 'status_update',
      isMonitoring: map['isMonitoring'] as bool? ?? false,
      faceDetected: map['faceDetected'] as bool? ?? false,
      multipleFaces: map['multipleFaces'] as bool? ?? false,
      measurementValid: map['measurementValid'] as bool? ?? (map['faceDetected'] as bool? ?? false),
      currentEar: (map['currentEar'] as num?)?.toDouble() ?? 0.0,
      averageEar: (map['averageEar'] as num?)?.toDouble() ?? 0.0,
      minEar: (map['minEar'] as num?)?.toDouble() ?? 0.0,
      eyeClosureEvents: (map['eyeClosureEvents'] as num?)?.toInt() ?? 0,
      blinkCount: (map['blinkCount'] as num?)?.toInt() ?? 0,
      durationMillis: (map['durationMillis'] as num?)?.toInt() ?? 0,
      statusMessage: map['statusMessage']?.toString() ?? '',
    );
  }

  factory EyeMonitoringLiveEvent.initial() {
    return const EyeMonitoringLiveEvent(
      type: 'initial',
      isMonitoring: false,
      faceDetected: false,
      multipleFaces: false,
      measurementValid: false,
      currentEar: 0.0,
      averageEar: 0.0,
      minEar: 0.0,
      eyeClosureEvents: 0,
      blinkCount: 0,
      durationMillis: 0,
      statusMessage: 'Monitoring belum aktif',
    );
  }
}
