import 'package:get/get.dart';
import '../controllers/permission_guide_controller.dart';

class PermissionGuideBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PermissionGuideController>(
      () => PermissionGuideController(),
    );
  }
}
