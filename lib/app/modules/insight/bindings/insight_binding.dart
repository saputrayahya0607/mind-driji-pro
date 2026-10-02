import 'package:get/get.dart';
import '../../../data/services/detection_service.dart';
import '../../../data/services/insight_service.dart';
import '../../../data/services/intervention_service.dart';
import '../../../data/services/monitoring_data_service.dart';
import '../../../data/services/recommendation_service.dart';
import '../controllers/insight_controller.dart';

class InsightBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<MonitoringDataService>()) {
      Get.lazyPut<MonitoringDataService>(() => MonitoringDataService());
    }
    if (!Get.isRegistered<DetectionService>()) {
      Get.lazyPut<DetectionService>(() => DetectionService());
    }
    if (!Get.isRegistered<InsightService>()) {
      Get.lazyPut<InsightService>(() => InsightService());
    }
    if (!Get.isRegistered<RecommendationService>()) {
      Get.lazyPut<RecommendationService>(() => RecommendationService());
    }
    if (!Get.isRegistered<InterventionService>()) {
      Get.lazyPut<InterventionService>(() => InterventionService());
    }
    Get.lazyPut<InsightController>(
      () => InsightController(
        insightService: Get.find<InsightService>(),
        recommendationService: Get.find<RecommendationService>(),
        interventionService: Get.find<InterventionService>(),
      ),
    );
  }
}
