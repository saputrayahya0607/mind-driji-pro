import 'package:flutter/foundation.dart';
import '../../models/behavioral_features.dart';
import '../../models/detection_result.dart';
import '../../models/monitoring_visualization_model.dart';
import 'detection_feature_extractor.dart';
import 'detection_strategy.dart';
import 'detection_thresholds.dart';
import 'rule_based_detection_strategy.dart';

/// Detection Engine MIND DRIJI
///
/// Mengorkestrasi ekstraksi fitur perilaku dan evaluasi strategi deteksi.
/// Arsitektur ini dirancang decoupled (loosely coupled) agar strategi
/// rule-based dapat dengan mudah digantikan / dikombinasikan dengan model
/// Machine Learning (seperti Random Forest) di masa mendatang.
class DetectionEngine {
  final DetectionStrategy _strategy;
  final DetectionThresholds _thresholds;
  final DetectionFeatureExtractor _extractor;

  DetectionEngine({
    DetectionStrategy? strategy,
    DetectionThresholds? thresholds,
    DetectionFeatureExtractor? extractor,
  })  : _strategy = strategy ?? RuleBasedDetectionStrategy(),
        _thresholds = thresholds ?? const DetectionThresholds(),
        _extractor = extractor ??
            DetectionFeatureExtractor(
              thresholds: thresholds ?? const DetectionThresholds(),
            );

  DetectionStrategy get strategy => _strategy;
  DetectionThresholds get thresholds => _thresholds;
  DetectionFeatureExtractor get extractor => _extractor;

  /// Mengekstraksi fitur perilaku dari sekumpulan data sesi mentah
  BehavioralFeatures extractFeatures({
    required List<dynamic> rawSessions,
    required DateTime date,
    int totalScreenTimeMillis = 0,
  }) {
    return _extractor.extract(
      rawSessions: rawSessions,
      date: date,
      totalScreenTimeMillis: totalScreenTimeMillis,
    );
  }

  /// Menganalisis fitur perilaku dan mengembalikan [DetectionResult]
  DetectionResult analyze(
    BehavioralFeatures features, {
    EyeMonitoringSummary? contextualEye,
  }) {
    debugPrint(
      '[MIND_DRIJI_DETECTION] Analyzing features for date: ${features.date.toIso8601String().substring(0, 10)}, '
      'sessions: ${features.totalScrollingSessions}, duration: ${features.totalScrollingDurationMillis}ms, '
      'swipes: ${features.totalSwipeCount}',
    );

    final result = _strategy.detect(
      features,
      contextualEye: contextualEye,
      thresholds: _thresholds,
    );

    debugPrint(
      '[MIND_DRIJI_DETECTION] Detection result: detected=${result.detected}, type=${result.type.name}, '
      'evidences=${result.evidences.map((e) => e.name).toList()}',
    );

    return result;
  }

  /// Memproses data mentah langsung menjadi [DetectionResult]
  DetectionResult processRaw({
    required List<dynamic> rawSessions,
    required DateTime date,
    int totalScreenTimeMillis = 0,
    EyeMonitoringSummary? contextualEye,
  }) {
    final features = extractFeatures(
      rawSessions: rawSessions,
      date: date,
      totalScreenTimeMillis: totalScreenTimeMillis,
    );

    return analyze(
      features,
      contextualEye: contextualEye,
    );
  }
}
