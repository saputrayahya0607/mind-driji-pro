import 'package:get/get.dart';
import '../../../data/local/repositories/doomscroll_local_repository.dart';
import '../../../data/providers/doomscroll_native_provider.dart';
import '../../../data/repositories/doomscroll_repository.dart';
import '../../../data/sync/sync_manager.dart';
import '../controllers/doomscroll_controller.dart';

class DoomscrollBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<DoomscrollNativeProvider>()) {
      Get.lazyPut<DoomscrollNativeProvider>(() => DoomscrollNativeProvider());
    }
    if (!Get.isRegistered<DoomscrollLocalRepository>()) {
      Get.lazyPut<DoomscrollLocalRepository>(() => DoomscrollLocalRepository());
    }
    if (!Get.isRegistered<DoomscrollRepository>()) {
      Get.lazyPut<DoomscrollRepository>(
        () => DoomscrollRepository(
          provider: Get.find<DoomscrollNativeProvider>(),
          localRepository: Get.find<DoomscrollLocalRepository>(),
        ),
      );
    }
    if (!Get.isRegistered<SyncManager>()) {
      Get.lazyPut<SyncManager>(() => SyncManager());
    }
    Get.lazyPut<DoomscrollController>(
      () => DoomscrollController(
        repository: Get.find<DoomscrollRepository>(),
        syncManager: Get.find<SyncManager>(),
      ),
    );
  }
}
