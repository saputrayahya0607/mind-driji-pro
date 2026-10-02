import '../../models/behavioral_features.dart';
import '../../models/detection_result.dart';
import '../../models/monitoring_visualization_model.dart';
import 'detection_thresholds.dart';

/// Kontrak strategi deteksi pola scrolling MIND DRIJI.
///
/// Memungkinkan arsitektur modular di mana strategi dapat berupa
/// Rule-Based deterministic (tahap saat ini) maupun Machine Learning
/// (seperti Random Forest di tahap berikutnya) tanpa mengubah arsitektur utama.
abstract class DetectionStrategy {
  DetectionResult detect(
    BehavioralFeatures features, {
    EyeMonitoringSummary? contextualEye,
    DetectionThresholds thresholds = const DetectionThresholds(),
  });
}
