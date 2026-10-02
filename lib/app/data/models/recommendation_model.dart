import 'detection_result.dart';

/// Jenis/kategori rekomendasi intervensi digital wellbeing
enum RecommendationType {
  digitalBreak,
  focusMode,
  eyeRest,
  nightReminder,
  usageReflection,
}

/// Konfigurasi durasi terpusat untuk setiap jenis rekomendasi
class RecommendationDurations {
  static const List<int> digitalBreak = [5, 15, 30]; // menit
  static const List<int> focusMode = [15, 30, 60]; // menit
  static const List<int> eyeRest = [5, 10, 20]; // menit
  static const List<int> nightReminder = [15, 30, 45]; // menit
  static const List<int> usageReflection = [5, 10, 15]; // menit

  static List<int> forType(RecommendationType type) {
    switch (type) {
      case RecommendationType.digitalBreak:
        return digitalBreak;
      case RecommendationType.focusMode:
        return focusMode;
      case RecommendationType.eyeRest:
        return eyeRest;
      case RecommendationType.nightReminder:
        return nightReminder;
      case RecommendationType.usageReflection:
        return usageReflection;
    }
  }
}

/// Model data representasi rekomendasi tindakan MIND DRIJI
///
/// PENTING:
/// Rekomendasi hanya menyajikan opsi yang dapat dipilih oleh pengguna secara sadar (User Choice).
/// Engine TIDAK mengeksekusi intervensi secara sepihak dan TIDAK menyertakan skor keparahan medis.
class RecommendationModel {
  final String id;
  final RecommendationType type;
  final String title;
  final String description;
  final String reason;
  final String actionLabel;
  final List<int> durationOptions; // dalam menit
  final String icon;
  final DetectionType? relatedDetection;
  final DateTime generatedAt;

  const RecommendationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.reason,
    required this.actionLabel,
    required this.durationOptions,
    required this.icon,
    this.relatedDetection,
    required this.generatedAt,
  });

  /// Factory untuk menyalin rekomendasi dengan modifikasi tertentu
  RecommendationModel copyWith({
    String? id,
    RecommendationType? type,
    String? title,
    String? description,
    String? reason,
    String? actionLabel,
    List<int>? durationOptions,
    String? icon,
    DetectionType? relatedDetection,
    DateTime? generatedAt,
  }) {
    return RecommendationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      reason: reason ?? this.reason,
      actionLabel: actionLabel ?? this.actionLabel,
      durationOptions: durationOptions ?? this.durationOptions,
      icon: icon ?? this.icon,
      relatedDetection: relatedDetection ?? this.relatedDetection,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'description': description,
      'reason': reason,
      'actionLabel': actionLabel,
      'durationOptions': durationOptions,
      'icon': icon,
      'relatedDetection': relatedDetection?.name,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toMap() => toJson();

  factory RecommendationModel.fromMap(Map<String, dynamic> map) =>
      RecommendationModel.fromJson(map);

  factory RecommendationModel.fromJson(Map<String, dynamic> json) {
    return RecommendationModel(
      id: json['id'] as String? ?? '',
      type: RecommendationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => RecommendationType.digitalBreak,
      ),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      actionLabel: json['actionLabel'] as String? ?? 'Mulai Jeda',
      durationOptions: (json['durationOptions'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          RecommendationDurations.digitalBreak,
      icon: json['icon'] as String? ?? 'spa_rounded',
      relatedDetection: json['relatedDetection'] != null
          ? DetectionType.values.firstWhere(
              (e) => e.name == json['relatedDetection'],
              orElse: () => DetectionType.none,
            )
          : null,
      generatedAt: json['generatedAt'] != null
          ? DateTime.tryParse(json['generatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
