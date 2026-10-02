import 'package:get/get.dart';
import '../../../data/repositories/profile_repository.dart';
import '../controllers/edit_profile_controller.dart';

class EditProfileBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ProfileRepository>()) {
      Get.lazyPut<ProfileRepository>(() => ProfileRepository());
    }
    Get.lazyPut<EditProfileController>(
      () => EditProfileController(
        profileRepository: Get.find<ProfileRepository>(),
      ),
    );
  }
}
