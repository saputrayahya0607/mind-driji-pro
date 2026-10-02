import 'package:get/get.dart';
import '../../../data/local/repositories/intervention_history_local_repository.dart';
import '../controllers/intervention_history_controller.dart';

class InterventionHistoryBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<InterventionHistoryLocalRepository>()) {
      Get.lazyPut<InterventionHistoryLocalRepository>(
        () => InterventionHistoryLocalRepository(),
        fenix: true,
      );
    }
    Get.lazyPut<InterventionHistoryController>(
      () => InterventionHistoryController(
        repo: Get.find<InterventionHistoryLocalRepository>(),
      ),
    );
  }
}
