/// Model representasi aplikasi yang dipantau (Target App) untuk deteksi Doomscrolling.
class TargetAppModel {
  final String packageName;
  final String appName;
  final bool isMonitored;
  final bool isDefault;
  final String? category;

  const TargetAppModel({
    required this.packageName,
    required this.appName,
    this.isMonitored = false,
    this.isDefault = false,
    this.category,
  });

  /// Daftar package bawaan (default presets)
  static const Set<String> defaultTargetPackageNames = {
    'com.ss.android.ugc.trill',
    'com.zhiliaoapp.musically',
    'com.zhiliaoapp.musically.go',
    'com.ss.android.ugc.aweme',
    'com.instagram.android',
    'com.instagram.lite',
    'com.google.android.youtube',
    'com.snapchat.android',
    'com.twitter.android',
    'com.facebook.katana',
    'com.facebook.lite',
  };

  factory TargetAppModel.fromMap(Map<dynamic, dynamic> map) {
    final pkg = map['packageName'] as String? ?? '';
    return TargetAppModel(
      packageName: pkg,
      appName: map['appName'] as String? ?? pkg,
      isMonitored: map['isMonitored'] as bool? ?? false,
      isDefault: defaultTargetPackageNames.contains(pkg),
      category: map['category'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'packageName': packageName,
      'appName': appName,
      'isMonitored': isMonitored,
      'category': category,
    };
  }

  TargetAppModel copyWith({
    String? packageName,
    String? appName,
    bool? isMonitored,
    bool? isDefault,
    String? category,
  }) {
    return TargetAppModel(
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      isMonitored: isMonitored ?? this.isMonitored,
      isDefault: isDefault ?? this.isDefault,
      category: category ?? this.category,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TargetAppModel &&
          runtimeType == other.runtimeType &&
          packageName == other.packageName &&
          isMonitored == other.isMonitored;

  @override
  int get hashCode => packageName.hashCode ^ isMonitored.hashCode;

  @override
  String toString() =>
      'TargetAppModel(packageName: $packageName, appName: $appName, isMonitored: $isMonitored)';
}
