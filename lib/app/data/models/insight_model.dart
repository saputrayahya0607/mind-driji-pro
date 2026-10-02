/// Tipe kategori insight
enum InsightType {
  scrolling,
  screenTime,
  eyeMonitoring,
  usagePattern,
  recommendation,
}

/// Prioritas urutan penampilan insight (BUKAN tingkat keparahan medis)
enum InsightPriority {
  high,
  medium,
  low,
}

/// Butir bukti kuantitatif objektif pendukung insight
class InsightEvidenceItem {
  final String label;
  final String value;
  final String? iconName;

  const InsightEvidenceItem({
    required this.label,
    required this.value,
    this.iconName,
  });

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'value': value,
      'iconName': iconName,
    };
  }

  factory InsightEvidenceItem.fromJson(Map<String, dynamic> json) {
    return InsightEvidenceItem(
      label: json['label'] as String? ?? '',
      value: json['value'] as String? ?? '',
      iconName: json['iconName'] as String?,
    );
  }
}

/// Model data representasi Insight MIND DRIJI
///
/// Dirancang transparan, faktual, bebas dari diagnosis medis dan skor kecanduan.
class InsightModel {
  final String id;
  final InsightType type;
  final String title;
  final String summary;
  final String details;
  final List<InsightEvidenceItem> evidences;
  final List<String> relatedApps;
  final String period; // 'daily', 'weekly', 'monthly'
  final DateTime generatedAt;
  final String? suggestedAction;
  final InsightPriority priority;

  const InsightModel({
    required this.id,
    required this.type,
    required this.title,
    required this.summary,
    required this.details,
    this.evidences = const [],
    this.relatedApps = const [],
    required this.period,
    required this.generatedAt,
    this.suggestedAction,
    this.priority = InsightPriority.medium,
  });

  bool get hasEvidences => evidences.isNotEmpty;
  bool get hasRelatedApps => relatedApps.isNotEmpty;
  bool get hasSuggestedAction => suggestedAction != null && suggestedAction!.isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'summary': summary,
      'details': details,
      'evidences': evidences.map((e) => e.toJson()).toList(),
      'relatedApps': relatedApps,
      'period': period,
      'generatedAt': generatedAt.toIso8601String(),
      'suggestedAction': suggestedAction,
      'priority': priority.name,
    };
  }

  factory InsightModel.fromJson(Map<String, dynamic> json) {
    return InsightModel(
      id: json['id'] as String? ?? '',
      type: InsightType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => InsightType.scrolling,
      ),
      title: json['title'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      details: json['details'] as String? ?? '',
      evidences: (json['evidences'] as List<dynamic>?)
              ?.map((e) =>
                  InsightEvidenceItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      relatedApps: (json['relatedApps'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      period: json['period'] as String? ?? 'daily',
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      suggestedAction: json['suggestedAction'] as String?,
      priority: InsightPriority.values.firstWhere(
        (p) => p.name == json['priority'],
        orElse: () => InsightPriority.medium,
      ),
    );
  }
}
