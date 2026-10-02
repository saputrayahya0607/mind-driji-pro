import 'package:get/get.dart';
import '../../../data/local/repositories/local_usage_repository.dart';
import '../../../data/providers/usage_stats_provider.dart';
import '../../../data/repositories/usage_stats_repository.dart';
import '../../../data/sync/sync_manager.dart';
import '../controllers/screen_time_controller.dart';

class ScreenTimeBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<LocalUsageRepository>()) {
      Get.lazyPut<LocalUsageRepository>(() => LocalUsageRepository());
    }
    if (!Get.isRegistered<SyncManager>()) {
      Get.lazyPut<SyncManager>(() => SyncManager());
    }
    if (!Get.isRegistered<UsageStatsProvider>()) {
      Get.lazyPut<UsageStatsProvider>(() => UsageStatsProvider());
    }
    if (!Get.isRegistered<UsageStatsRepository>()) {
      Get.lazyPut<UsageStatsRepository>(
        () => UsageStatsRepository(
          provider: Get.find<UsageStatsProvider>(),
          localRepository: Get.find<LocalUsageRepository>(),
        ),
      );
    }
    Get.lazyPut<ScreenTimeController>(
      () => ScreenTimeController(
        repository: Get.find<UsageStatsRepository>(),
        syncManager: Get.find<SyncManager>(),
      ),
    );
  }
}
