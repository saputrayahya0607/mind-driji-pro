import 'package:get/get.dart';
import '../data/local/app_database.dart';
import '../data/local/repositories/doomscroll_local_repository.dart';
import '../data/local/repositories/eye_monitoring_local_repository.dart';
import '../data/local/repositories/intervention_history_local_repository.dart';
import '../data/local/repositories/local_usage_repository.dart';
import '../data/providers/intervention_native_provider.dart';
import '../data/repositories/eye_monitoring_repository.dart';
import '../data/services/device_service.dart';
import '../data/services/eye_monitoring_service.dart';
import '../data/services/intervention_service.dart';
import '../data/sync/sync_manager.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Database and device identity services (lazy)
    if (!Get.isRegistered<AppDatabase>()) {
      Get.lazyPut<AppDatabase>(() => AppDatabase(), fenix: true);
    }
    if (!Get.isRegistered<DeviceService>()) {
      Get.lazyPut<DeviceService>(() => DeviceService(), fenix: true);
    }

    // Core local database and sync manager
    if (!Get.isRegistered<LocalUsageRepository>()) {
      Get.lazyPut<LocalUsageRepository>(() => LocalUsageRepository(), fenix: true);
    }
    if (!Get.isRegistered<DoomscrollLocalRepository>()) {
      Get.lazyPut<DoomscrollLocalRepository>(() => DoomscrollLocalRepository(), fenix: true);
    }
    if (!Get.isRegistered<EyeMonitoringLocalRepository>()) {
      Get.lazyPut<EyeMonitoringLocalRepository>(() => EyeMonitoringLocalRepository(), fenix: true);
    }
    if (!Get.isRegistered<InterventionHistoryLocalRepository>()) {
      Get.lazyPut<InterventionHistoryLocalRepository>(
          () => InterventionHistoryLocalRepository(),
          fenix: true);
    }
    if (!Get.isRegistered<EyeMonitoringRepository>()) {
      Get.lazyPut<EyeMonitoringRepository>(() => EyeMonitoringRepository(), fenix: true);
    }
    if (!Get.isRegistered<EyeMonitoringService>()) {
      Get.lazyPut<EyeMonitoringService>(() => EyeMonitoringService(), fenix: true);
    }
    if (!Get.isRegistered<SyncManager>()) {
      Get.lazyPut<SyncManager>(() => SyncManager(), fenix: true);
    }
    if (!Get.isRegistered<InterventionNativeProvider>()) {
      Get.lazyPut<InterventionNativeProvider>(() => InterventionNativeProvider(), fenix: true);
    }
    if (!Get.isRegistered<InterventionService>()) {
      Get.lazyPut<InterventionService>(
          () => InterventionService(
                historyRepository:
                    Get.find<InterventionHistoryLocalRepository>(),
              ),
          fenix: true);
    }
  }
}
