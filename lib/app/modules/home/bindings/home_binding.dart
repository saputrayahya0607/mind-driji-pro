import 'package:get/get.dart';
import '../../../data/providers/usage_stats_provider.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../data/repositories/usage_stats_repository.dart';
import '../../../data/services/detection_service.dart';
import '../controllers/home_controller.dart';

import '../../../data/repositories/doomscroll_repository.dart';
import '../../../data/services/monitoring_data_service.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ProfileRepository>()) {
      Get.lazyPut<ProfileRepository>(() => ProfileRepository());
    }
    if (!Get.isRegistered<UsageStatsProvider>()) {
      Get.lazyPut<UsageStatsProvider>(() => UsageStatsProvider());
    }
    if (!Get.isRegistered<UsageStatsRepository>()) {
      Get.lazyPut<UsageStatsRepository>(
        () => UsageStatsRepository(provider: Get.find<UsageStatsProvider>()),
      );
    }
    if (!Get.isRegistered<DetectionService>()) {
      Get.lazyPut<DetectionService>(() => DetectionService());
    }
    if (!Get.isRegistered<DoomscrollRepository>()) {
      Get.lazyPut<DoomscrollRepository>(() => DoomscrollRepository());
    }
    if (!Get.isRegistered<MonitoringDataService>()) {
      Get.lazyPut<MonitoringDataService>(() => MonitoringDataService());
    }
    Get.lazyPut<HomeController>(
      () => HomeController(
        profileRepository: Get.find<ProfileRepository>(),
        usageStatsRepository: Get.find<UsageStatsRepository>(),
        detectionService: Get.find<DetectionService>(),
        doomscrollRepository: Get.find<DoomscrollRepository>(),
        monitoringDataService: Get.find<MonitoringDataService>(),
      ),
    );
  }
}
