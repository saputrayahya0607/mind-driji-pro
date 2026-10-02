import 'package:get/get.dart';
import '../controllers/focus_mode_controller.dart';

class FocusModeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FocusModeController>(
      () => FocusModeController(),
    );
  }
}
