import 'package:get/get.dart';
import '../../../data/repositories/profile_repository.dart';
import '../controllers/profile_controller.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ProfileRepository>()) {
      Get.lazyPut<ProfileRepository>(() => ProfileRepository());
    }
    Get.lazyPut<ProfileController>(
      () => ProfileController(
        profileRepository: Get.find<ProfileRepository>(),
      ),
    );
  }
}
