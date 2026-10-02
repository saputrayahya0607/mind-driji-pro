import 'behavioral_features.dart';

/// Jenis deteksi pola scrolling berdasarkan sinyal perilaku teramati
enum DetectionType {
  none,
  longScrollSession,
  repeatedScrolling,
  highScrollActivity,
  nightScrollingPattern,
  multiSignalScrollingPattern,
}

/// Bukti/sinyal perilaku spesifik yang memicu hasil deteksi
enum DetectionEvidence {
  longSession,
  highSwipeActivity,
  repeatedScrolling,
  downwardPattern,
  nightPattern,
  contextualEyeFatigue,
}

/// Model hasil deteksi pola scrolling (Behavioral Detection Result)
///
/// PENTING:
/// Model ini merefleksikan observasi metadata perilaku navigasi aplikasi.
/// BUKAN diagnosis medis dan TIDAK menggunakan skor kecanduan sembarangan.
class DetectionResult {
  final bool detected;
  final DetectionType type;
  final BehavioralFeatures features;
  final List<DetectionEvidence> evidences;
  final DateTime detectedAt;
  final List<String> relatedApps;
  final String title;
  final String description;
  final String? suggestedIntervention;
  final String? contextualEyeNote;

  const DetectionResult({
    required this.detected,
    required this.type,
    required this.features,
    required this.evidences,
    required this.detectedAt,
    required this.relatedApps,
    required this.title,
    required this.description,
    this.suggestedIntervention,
    this.contextualEyeNote,
  });

  /// Factory untuk kondisi normal saat tidak ada pola khusus yang terdeteksi
  factory DetectionResult.none({
    required DateTime date,
    BehavioralFeatures? features,
    String? note,
  }) {
    return DetectionResult(
      detected: false,
      type: DetectionType.none,
      features: features ?? BehavioralFeatures.empty(date),
      evidences: const [],
      detectedAt: DateTime.now(),
      relatedApps: features?.involvedApps ?? const [],
      title: 'Belum ada pola scrolling khusus yang terdeteksi',
      description: note ??
          'Pola penggunaan aplikasi berada dalam rentang normal berdasarkan data pemantauan.',
      suggestedIntervention: null,
      contextualEyeNote: null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'detected': detected,
      'type': type.name,
      'features': features.toJson(),
      'evidences': evidences.map((e) => e.name).toList(),
      'detectedAt': detectedAt.toIso8601String(),
      'relatedApps': relatedApps,
      'title': title,
      'description': description,
      'suggestedIntervention': suggestedIntervention,
      'contextualEyeNote': contextualEyeNote,
    };
  }

  factory DetectionResult.fromJson(Map<String, dynamic> json) {
    return DetectionResult(
      detected: json['detected'] as bool? ?? false,
      type: DetectionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => DetectionType.none,
      ),
      features: BehavioralFeatures.fromJson(
        json['features'] as Map<String, dynamic>,
      ),
      evidences: (json['evidences'] as List<dynamic>?)
              ?.map((e) => DetectionEvidence.values.firstWhere(
                    (ev) => ev.name == e.toString(),
                    orElse: () => DetectionEvidence.longSession,
                  ))
              .toList() ??
          const [],
      detectedAt: DateTime.parse(json['detectedAt'] as String),
      relatedApps: (json['relatedApps'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      suggestedIntervention: json['suggestedIntervention'] as String?,
      contextualEyeNote: json['contextualEyeNote'] as String?,
    );
  }
}
