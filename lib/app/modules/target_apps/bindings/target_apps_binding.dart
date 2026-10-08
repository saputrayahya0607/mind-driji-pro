import 'package:get/get.dart';
import '../controllers/target_apps_controller.dart';

class TargetAppsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TargetAppsController>(
      () => TargetAppsController(),
    );
  }
}
