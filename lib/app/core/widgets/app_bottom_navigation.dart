import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';
import '../../routes/app_routes.dart';

/// Bottom Navigation Bar terpusat & konsisten untuk MIND DRIJI
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
        color: AppColors.card,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        backgroundColor: AppColors.card,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary.withValues(alpha: 0.7),
        selectedFontSize: 11,
        unselectedFontSize: 11,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.speed_rounded),
            label: 'Monitoring',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights_rounded),
            label: 'Insight',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.spa_rounded),
            label: 'Intervensi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
        onTap: (index) {
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
        },
      ),
    );
  }
}
