import 'dart:convert';
import 'recommendation_model.dart';

/// Jenis intervensi yang dapat dieksekusi berdasarkan pilihan pengguna.
enum InterventionType {
  digitalBreak,
  focusMode,
  eyeRelaxation,
  nightReminder,
  pomodoro,
  custom;

  String get displayName {
    switch (this) {
      case InterventionType.digitalBreak:
        return 'Jeda Digital';
      case InterventionType.focusMode:
        return 'Mode Fokus';
      case InterventionType.eyeRelaxation:
        return 'Relaksasi Mata';
      case InterventionType.nightReminder:
        return 'Pengingat Malam';
      case InterventionType.pomodoro:
        return 'Pomodoro';
      case InterventionType.custom:
        return 'Kustom';
    }
  }

  static InterventionType fromString(String? val) {
    if (val == null) return InterventionType.digitalBreak;
    switch (val.toLowerCase()) {
      case 'digitalbreak':
      case 'digital_break':
        return InterventionType.digitalBreak;
      case 'focusmode':
      case 'focus_mode':
        return InterventionType.focusMode;
      case 'eyerelaxation':
      case 'eye_relaxation':
      case 'eyerest':
      case 'eye_rest':
        return InterventionType.eyeRelaxation;
      case 'nightreminder':
      case 'night_reminder':
        return InterventionType.nightReminder;
      case 'pomodoro':
        return InterventionType.pomodoro;
      case 'custom':
        return InterventionType.custom;
      default:
        return InterventionType.digitalBreak;
    }
  }
}

/// Status siklus hidup intervensi.
enum InterventionStatus {
  pending,
  active,
  completed,
  cancelled;

  static InterventionStatus fromString(String? val) {
    if (val == null) return InterventionStatus.pending;
    switch (val.toLowerCase()) {
      case 'pending':
        return InterventionStatus.pending;
      case 'active':
        return InterventionStatus.active;
      case 'completed':
        return InterventionStatus.completed;
      case 'cancelled':
      case 'canceled':
        return InterventionStatus.cancelled;
      default:
        return InterventionStatus.pending;
    }
  }
}

/// Model representasi data intervensi aktif maupun terselesaikan.
///
/// Dirancang transparan, berlandaskan pilihan pengguna (User Choice),
/// dan sama sekali tidak memuat skor diagnosis maupun klaim medis.
class InterventionModel {
  final String id;
  final String userId;
  final InterventionType type;
  final String title;
  final int durationMinutes;
  final DateTime startedAt;
  final DateTime endedAt;
  final InterventionStatus status;
  final RecommendationModel? sourceRecommendation;
  final String? sourceRecommendationId;
  final DateTime? cancelledAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const InterventionModel({
    required this.id,
    this.userId = 'local_user',
    required this.type,
    required this.title,
    required this.durationMinutes,
    required this.startedAt,
    required this.endedAt,
    required this.status,
    this.sourceRecommendation,
    this.sourceRecommendationId,
    this.cancelledAt,
    required this.createdAt,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? createdAt;

  /// Menghitung sisa detik intervensi secara deterministik berbasis timestamp mutlak.
  int get remainingSeconds {
    if (status != InterventionStatus.active) return 0;
    final now = DateTime.now();
    final diff = endedAt.difference(now).inSeconds;
    return diff > 0 ? diff : 0;
  }

  /// Menentukan apakah durasi intervensi telah habis.
  bool get isFinished {
    if (status == InterventionStatus.completed ||
        status == InterventionStatus.cancelled) {
      return true;
    }
    return DateTime.now().isAfter(endedAt);
  }

  /// Progres intervensi dari 0.0 sampai 1.0.
  double get progress {
    final totalSeconds = endedAt.difference(startedAt).inSeconds;
    if (totalSeconds <= 0) return 1.0;
    final elapsedSeconds = DateTime.now().difference(startedAt).inSeconds;
    if (elapsedSeconds <= 0) return 0.0;
    if (elapsedSeconds >= totalSeconds) return 1.0;
    return elapsedSeconds / totalSeconds;
  }

  InterventionModel copyWith({
    String? id,
    String? userId,
    InterventionType? type,
    String? title,
    int? durationMinutes,
    DateTime? startedAt,
    DateTime? endedAt,
    InterventionStatus? status,
    RecommendationModel? sourceRecommendation,
    String? sourceRecommendationId,
    DateTime? cancelledAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InterventionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      status: status ?? this.status,
      sourceRecommendation:
          sourceRecommendation ?? this.sourceRecommendation,
      sourceRecommendationId:
          sourceRecommendationId ?? this.sourceRecommendationId ?? this.sourceRecommendation?.id,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'title': title,
      'durationMinutes': durationMinutes,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt.toIso8601String(),
      'status': status.name,
      if (sourceRecommendation != null)
        'sourceRecommendation': sourceRecommendation!.toMap(),
      if (sourceRecommendationId != null || sourceRecommendation != null)
        'sourceRecommendationId':
            sourceRecommendationId ?? sourceRecommendation?.id,
      if (cancelledAt != null) 'cancelledAt': cancelledAt!.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory InterventionModel.fromMap(Map<String, dynamic> map) {
    final srcRec = map['sourceRecommendation'] != null
        ? RecommendationModel.fromMap(
            Map<String, dynamic>.from(map['sourceRecommendation'] as Map))
        : null;
    final created = DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
        DateTime.now();
    return InterventionModel(
      id: map['id']?.toString() ?? '',
      userId: map['userId']?.toString() ?? 'local_user',
      type: InterventionType.fromString(map['type']?.toString()),
      title: map['title']?.toString() ?? '',
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 15,
      startedAt: DateTime.tryParse(map['startedAt']?.toString() ?? '') ??
          DateTime.now(),
      endedAt: DateTime.tryParse(map['endedAt']?.toString() ?? '') ??
          DateTime.now(),
      status: InterventionStatus.fromString(map['status']?.toString()),
      sourceRecommendation: srcRec,
      sourceRecommendationId: map['sourceRecommendationId']?.toString() ??
          srcRec?.id,
      cancelledAt: map['cancelledAt'] != null
          ? DateTime.tryParse(map['cancelledAt']?.toString() ?? '')
          : null,
      createdAt: created,
      updatedAt: DateTime.tryParse(map['updatedAt']?.toString() ?? '') ??
          created,
    );
  }

  String toJson() => json.encode(toMap());

  factory InterventionModel.fromJson(String source) =>
      InterventionModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
