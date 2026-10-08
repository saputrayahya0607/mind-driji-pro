import 'package:get/get.dart';

import '../modules/focus_mode/bindings/focus_mode_binding.dart';
import '../modules/focus_mode/views/focus_mode_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/insight/bindings/insight_binding.dart';
import '../modules/insight/views/insight_view.dart';
import '../modules/intervention/bindings/intervention_binding.dart';
import '../modules/intervention/views/eye_relaxation_view.dart';
import '../modules/intervention/views/intervention_view.dart';
import '../modules/intervention_history/bindings/intervention_history_binding.dart';
import '../modules/intervention_history/views/intervention_history_view.dart';
import '../modules/login/bindings/login_binding.dart';
import '../modules/login/views/login_view.dart';
import '../modules/monitoring/bindings/doomscroll_binding.dart';
import '../modules/monitoring/bindings/eye_monitoring_binding.dart';
import '../modules/monitoring/bindings/monitoring_binding.dart';
import '../modules/monitoring/bindings/screen_time_binding.dart';
import '../modules/monitoring/views/doomscroll_view.dart';
import '../modules/monitoring/views/eye_monitoring_view.dart';
import '../modules/monitoring/views/monitoring_view.dart';
import '../modules/monitoring/views/screen_time_view.dart';
import '../modules/permission_guide/bindings/permission_guide_binding.dart';
import '../modules/permission_guide/views/permission_guide_view.dart';
import '../modules/profile/bindings/edit_profile_binding.dart';
import '../modules/profile/bindings/profile_binding.dart';
import '../modules/profile/views/edit_profile_view.dart';
import '../modules/profile/views/profile_view.dart';
import '../modules/register/bindings/register_binding.dart';
import '../modules/register/views/register_view.dart';
import '../modules/splash/bindings/splash_binding.dart';
import '../modules/splash/views/splash_view.dart';
import '../modules/target_apps/bindings/target_apps_binding.dart';
import '../modules/target_apps/views/target_apps_view.dart';
import 'app_routes.dart';

class AppPages {
  AppPages._();

  static const initial = Routes.splash;

  static final routes = [
    GetPage(
      name: Routes.splash,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: Routes.login,
      page: () => const LoginView(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: Routes.register,
      page: () => const RegisterView(),
      binding: RegisterBinding(),
    ),
    GetPage(
      name: Routes.home,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: Routes.monitoring,
      page: () => const MonitoringView(),
      binding: MonitoringBinding(),
    ),
    GetPage(
      name: Routes.screenTime,
      page: () => const ScreenTimeView(),
      binding: ScreenTimeBinding(),
    ),
    GetPage(
      name: Routes.doomscrolling,
      page: () => const DoomscrollView(),
      binding: DoomscrollBinding(),
    ),
    GetPage(
      name: Routes.eyeMonitoring,
      page: () => const EyeMonitoringView(),
      binding: EyeMonitoringBinding(),
    ),
    GetPage(
      name: Routes.insight,
      page: () => const InsightView(),
      binding: InsightBinding(),
    ),
    GetPage(
      name: Routes.profile,
      page: () => const ProfileView(),
      binding: ProfileBinding(),
    ),
    GetPage(
      name: Routes.editProfile,
      page: () => const EditProfileView(),
      binding: EditProfileBinding(),
    ),
    GetPage(
      name: Routes.permissionGuide,
      page: () => const PermissionGuideView(),
      binding: PermissionGuideBinding(),
    ),
    GetPage(
      name: Routes.intervention,
      page: () => const InterventionView(),
      binding: InterventionBinding(),
    ),
    GetPage(
      name: Routes.eyeRelaxation,
      page: () => const EyeRelaxationView(),
      binding: InterventionBinding(),
    ),
    GetPage(
      name: Routes.focusMode,
      page: () => const FocusModeView(),
      binding: FocusModeBinding(),
    ),
    GetPage(
      name: Routes.interventionHistory,
      page: () => const InterventionHistoryView(),
      binding: InterventionHistoryBinding(),
    ),
    GetPage(
      name: Routes.targetApps,
      page: () => const TargetAppsView(),
      binding: TargetAppsBinding(),
    ),
  ];
}
