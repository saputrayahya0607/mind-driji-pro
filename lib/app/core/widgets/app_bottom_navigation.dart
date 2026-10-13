import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';
import '../../routes/app_routes.dart';

/// Bottom Navigation Bar Material 3 terpusat & konsisten untuk MIND DRIJI
/// Mendukung 5 pilar navigasi utama:
/// 0: Home (Ringkasan hari ini)
/// 1: Monitoring (Data & visualisasi)
/// 2: Insight (Interpretasi data)
/// 3: Intervensi (Aksi digital wellness: Jeda, Focus, Pomodoro, Custom)
/// 4: Profil (Akun, pengaturan, status izin)
class AppBottomNavigation extends StatelessWidget {
  final int currentIndex;

  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.navBackground,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: NavigationBar(
        selectedIndex: currentIndex.clamp(0, 4),
        onDestinationSelected: _onDestinationSelected,
        backgroundColor: AppColors.navBackground,
        elevation: 0,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            key: Key('nav_destination_home'),
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            key: Key('nav_destination_monitoring'),
            icon: Icon(Icons.speed_outlined),
            selectedIcon: Icon(Icons.speed_rounded),
            label: 'Monitoring',
          ),
          NavigationDestination(
            key: Key('nav_destination_insight'),
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights_rounded),
            label: 'Insight',
          ),
          NavigationDestination(
            key: Key('nav_destination_intervention'),
            icon: Icon(Icons.spa_outlined),
            selectedIcon: Icon(Icons.spa_rounded),
            label: 'Intervensi',
          ),
          NavigationDestination(
            key: Key('nav_destination_profile'),
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  void _onDestinationSelected(int index) {
    if (index == currentIndex) return;

    switch (index) {
      case 0:
        Get.offAllNamed(Routes.home);
        break;
      case 1:
        Get.offNamed(Routes.monitoring);
        break;
      case 2:
        Get.offNamed(Routes.insight);
        break;
      case 3:
        Get.offNamed(Routes.intervention);
        break;
      case 4:
        Get.offNamed(Routes.profile);
        break;
    }
  }
}
