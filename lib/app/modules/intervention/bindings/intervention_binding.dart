import 'package:get/get.dart';
import '../../../data/services/intervention_service.dart';
import '../controllers/intervention_controller.dart';

class InterventionBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<InterventionService>()) {
      Get.lazyPut<InterventionService>(() => InterventionService(), fenix: true);
    }
    Get.lazyPut<InterventionController>(
      () => InterventionController(
        interventionService: Get.find<InterventionService>(),
      ),
    );
  }
}
