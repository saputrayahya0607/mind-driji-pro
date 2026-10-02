/// Model data untuk informasi perangkat non-sensitif (Device Info)
class DeviceInfoModel {
  final String deviceId;
  final String deviceName;
  final String manufacturer;
  final String model;
  final String androidVersion;
  final String appVersion;
  final DateTime firstSeenAt;
  final DateTime lastSeenAt;

  const DeviceInfoModel({
    required this.deviceId,
    required this.deviceName,
    required this.manufacturer,
    required this.model,
    required this.androidVersion,
    required this.appVersion,
    required this.firstSeenAt,
    required this.lastSeenAt,
  });

  /// Nama tampilan merek/produsen perangkat untuk UI.
  /// Memprioritaskan manufacturer (Build.MANUFACTURER) yang diberikan langsung oleh sistem Android.
  /// Jika manufacturer kosong atau bernilai null/Unknown, gunakan model (Build.MODEL) sebagai fallback.
  String get displayBrand {
    final m = manufacturer.trim();
    if (m.isNotEmpty && m.toLowerCase() != 'unknown' && m.toLowerCase() != 'android') {
      return m;
    }
    if (m.isNotEmpty && m.toLowerCase() != 'unknown') {
      return m;
    }
    final mod = model.trim();
    if (mod.isNotEmpty && mod.toLowerCase() != 'unknown') {
      return mod;
    }
    return 'Android Device';
  }

  Map<String, dynamic> toSupabaseMap(String userId) {
    return {
      'user_id': userId,
      'device_id': deviceId,
      'device_name': deviceName,
      'manufacturer': manufacturer,
      'model': model,
      'android_version': androidVersion,
      'app_version': appVersion,
      'first_seen_at': firstSeenAt.toUtc().toIso8601String(),
      'last_seen_at': lastSeenAt.toUtc().toIso8601String(),
      'created_at': firstSeenAt.toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  DeviceInfoModel copyWith({
    String? deviceId,
    String? deviceName,
    String? manufacturer,
    String? model,
    String? androidVersion,
    String? appVersion,
    DateTime? firstSeenAt,
    DateTime? lastSeenAt,
  }) {
    return DeviceInfoModel(
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      manufacturer: manufacturer ?? this.manufacturer,
      model: model ?? this.model,
      androidVersion: androidVersion ?? this.androidVersion,
      appVersion: appVersion ?? this.appVersion,
      firstSeenAt: firstSeenAt ?? this.firstSeenAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    );
  }
}
