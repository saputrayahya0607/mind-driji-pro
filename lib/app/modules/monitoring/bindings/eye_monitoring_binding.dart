import 'package:get/get.dart';
import '../../../data/local/repositories/eye_monitoring_local_repository.dart';
import '../../../data/providers/eye_monitoring_native_provider.dart';
import '../../../data/repositories/eye_monitoring_repository.dart';
import '../../../data/sync/sync_manager.dart';
import '../controllers/eye_monitoring_controller.dart';

class EyeMonitoringBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<EyeMonitoringNativeProvider>()) {
      Get.lazyPut<EyeMonitoringNativeProvider>(() => EyeMonitoringNativeProvider());
    }
    if (!Get.isRegistered<EyeMonitoringLocalRepository>()) {
      Get.lazyPut<EyeMonitoringLocalRepository>(() => EyeMonitoringLocalRepository());
    }
    if (!Get.isRegistered<EyeMonitoringRepository>()) {
      Get.lazyPut<EyeMonitoringRepository>(
        () => EyeMonitoringRepository(
          provider: Get.find<EyeMonitoringNativeProvider>(),
          localRepository: Get.find<EyeMonitoringLocalRepository>(),
        ),
      );
    }
    if (!Get.isRegistered<SyncManager>()) {
      Get.lazyPut<SyncManager>(() => SyncManager());
    }
    Get.lazyPut<EyeMonitoringController>(
      () => EyeMonitoringController(
        repository: Get.find<EyeMonitoringRepository>(),
        syncManager: Get.find<SyncManager>(),
      ),
    );
  }
}
