import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../../core/widgets/app_bottom_navigation.dart';
import '../../../data/models/intervention_model.dart';
import '../../../routes/app_routes.dart';
import '../controllers/home_controller.dart';

/// Halaman Utama (Dashboard) MIND DRIJI - Stitch Design System
/// Prioritas Visual:
/// 1. Doomscrolling sebagai fitur utama MIND DRIJI
/// 2. Pusat Aksi Intervensi Cepat
/// 3. Screen Time & Eye Monitoring sebagai informasi pendukung
/// 4. Smart Insight ringkas & visual
class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value && controller.profile.value == null) {
            return _buildLoadingState();
          }

          if (controller.errorMessage.value != null &&
              controller.profile.value == null) {
            return _buildErrorState();
          }

          return _buildHomeContent();
        }),
      ),
      bottomNavigationBar: const AppBottomNavigation(currentIndex: 0),
    );
  }

  /// AppBar dengan branding MIND DRIJI & tombol aksi cepat
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.teal, AppColors.cyan],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.teal.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.spa_rounded,
              size: 22,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          const Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppStrings.appName,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                    letterSpacing: 0.4,
                  ),
                ),
                Text(
                  'Digital Wellbeing Companion',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      centerTitle: false,
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      actions: [
        IconButton(
          icon: const Icon(
            Icons.tune_rounded,
            color: AppColors.navy,
            size: 22,
          ),
          tooltip: 'Target Aplikasi',
          onPressed: () => Get.toNamed(Routes.targetApps),
        ),
        IconButton(
          icon: const Icon(
            Icons.refresh_rounded,
            color: AppColors.navy,
            size: 22,
          ),
          tooltip: 'Perbarui Data',
          onPressed: () => controller.loadHomeData(),
        ),
        const SizedBox(width: 6),
      ],
    );
  }

  /// State saat memuat data profil awal
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              color: AppColors.teal,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Memuat dashboard...',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// State jika data profil gagal dimuat
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.errorContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 32,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Data pengguna belum dapat dimuat.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => controller.loadHomeData(),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Konten utama Dashboard Home Digital Wellbeing
  Widget _buildHomeContent() {
    return RefreshIndicator(
      color: AppColors.teal,
      backgroundColor: Colors.white,
      onRefresh: () => controller.loadHomeData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Sapaan Ramah & Tanggal Hari Ini
            _buildUserGreeting(),
            const SizedBox(height: 16),

            // 2. Banner Intervensi Aktif (jika ada sesi berjalan)
            if (controller.isInterventionActive) ...[
              _buildActiveInterventionBanner(),
              const SizedBox(height: 16),
            ],

            // 3. FITUR UTAMA MIND DRIJI: Doomscrolling (Pola Scrolling) Hero Card
            _buildDoomscrollingHeroCard(),
            const SizedBox(height: 16),

            // 4. Pusat Aksi Intervensi Cepat (Fokus & Intervensi Digital)
            _buildInterventionShortcutBanner(),
            const SizedBox(height: 16),

            // 5. Informasi Pendukung: Screen Time & Monitoring Mata
            _buildScreenTimeCard(),
            const SizedBox(height: 14),
            _buildEyeMonitoringCard(),
            const SizedBox(height: 20),

            // 6. Section AI Behavioral Insight
            _buildInsightSection(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// Sapaan ramah kepada user dan indikator tanggal
  Widget _buildUserGreeting() {
    return Obx(() {
      final formattedDate = _getFormattedDate();

      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.greetingText,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Bagaimana penggunaan digitalmu hari ini?',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navy.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 13,
                  color: AppColors.teal,
                ),
                const SizedBox(width: 6),
                Text(
                  formattedDate,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  /// Format tanggal hari ini dalam Bahasa Indonesia
  String _getFormattedDate() {
    final now = DateTime.now();
    const days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final dayName = days[now.weekday % 7];
    final monthName = months[now.month - 1];
    return '$dayName, ${now.day} $monthName';
  }

  /// Banner Intervensi Aktif jika sedang berjalan
  Widget _buildActiveInterventionBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.successContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.successBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.1),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.spa_rounded,
              color: AppColors.success,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${controller.activeInterventionTitle} Aktif',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSuccessContainer,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Sisa waktu: ${controller.activeInterventionRemaining}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.onSuccessContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final activeType =
                  controller.interventionService?.activeIntervention.value?.type;
              if (activeType == InterventionType.focusMode) {
                Get.toNamed(Routes.focusMode);
              } else if (activeType == InterventionType.eyeRelaxation) {
                Get.toNamed(Routes.eyeRelaxation);
              } else {
                Get.toNamed(Routes.intervention);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: const Size(60, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Lihat',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  /// FITUR UTAMA MIND DRIJI: Pola Scrolling (Doomscrolling Hero Card)
  Widget _buildDoomscrollingHeroCard() {
    return Obx(() {
      final isMonitoringActive = controller.isDoomscrollMonitoringActive;
      final summary = controller.doomscrollSummary.value;

      final badgeText = isMonitoringActive ? 'Aktif' : 'Monitoring tidak aktif';
      final badgeColor = isMonitoringActive
          ? AppColors.softMint
          : const Color(0xFFF1F5F9);
      final badgeTextColor = isMonitoringActive
          ? AppColors.navy
          : AppColors.textSecondary;

      final mainStatus = controller.doomscrollDataStatusText;
      final description = isMonitoringActive
          ? (summary.totalSessions > 0
              ? 'Aktivitas scrolling terdeteksi pada aplikasi media sosial target.'
              : 'Monitoring aktif memantau aplikasi target.')
          : 'Aktifkan izin aksesibilitas untuk mendeteksi pola scrolling.';

      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isMonitoringActive
                ? AppColors.teal.withValues(alpha: 0.4)
                : const Color(0xFFE2E8F0),
            width: isMonitoringActive ? 1.6 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isMonitoringActive
                  ? AppColors.teal.withValues(alpha: 0.08)
                  : AppColors.navy.withValues(alpha: 0.04),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              await Get.toNamed(Routes.doomscrolling);
              controller.loadDoomscrollSummary();
            },
            borderRadius: BorderRadius.circular(22),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row Top: Icon, Judul & Badge
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isMonitoringActive
                                ? [AppColors.teal, AppColors.cyan]
                                : [const Color(0xFFE2E8F0), const Color(0xFFCBD5E1)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.swipe_vertical_rounded,
                          size: 24,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pola Scrolling',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.navy,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isMonitoringActive
                                  ? 'Fitur Utama MIND DRIJI'
                                  : 'Aksesibilitas Diperlukan',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: isMonitoringActive
                                    ? AppColors.teal
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isMonitoringActive
                                ? AppColors.teal.withValues(alpha: 0.25)
                                : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: badgeTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Main Status & Navigation Arrow
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          mainStatus,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: AppColors.navy,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Description
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),

                  // Live Quick Stats Snippet when active
                  if (isMonitoringActive && summary.totalSessions > 0) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildMiniStat(
                            label: 'Total Sesi',
                            value: '${summary.totalSessions}',
                          ),
                          Container(
                            width: 1,
                            height: 24,
                            color: const Color(0xFFE2E8F0),
                          ),
                          _buildMiniStat(
                            label: 'Total Swipe',
                            value: '${summary.totalSwipes}',
                          ),
                          Container(
                            width: 1,
                            height: 24,
                            color: const Color(0xFFE2E8F0),
                          ),
                          _buildMiniStat(
                            label: 'Arah Bawah',
                            value: '${summary.downwardSwipes}',
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildMiniStat({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),
      ],
    );
  }

  /// Banner Aksi Cepat / Shortcut Intervensi Utama (Digital Detox Tools)
  Widget _buildInterventionShortcutBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.softMint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  size: 22,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fokus & Intervensi Digital',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Kendalikan scrolling impulsif dan istirahatkan mata dengan intervensi mandiri terarah.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tombol Aksi Utama
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: () => Get.toNamed(Routes.focusMode),
                  icon: const Icon(Icons.play_arrow_rounded, size: 20),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Mulai Focus Mode'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 48),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: OutlinedButton(
                  onPressed: () => Get.toNamed(Routes.intervention),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.navy,
                    minimumSize: const Size(0, 48),
                    side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Semua Intervensi',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Shortcut Chips Alat Bantu Digital
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildToolChip(
                  icon: Icons.visibility_rounded,
                  label: 'Jeda Mata 20-20-20',
                  onTap: () => Get.toNamed(Routes.eyeRelaxation),
                ),
                const SizedBox(width: 8),
                _buildToolChip(
                  icon: Icons.app_blocking_rounded,
                  label: 'Target Apps',
                  onTap: () => Get.toNamed(Routes.targetApps),
                ),
                const SizedBox(width: 8),
                _buildToolChip(
                  icon: Icons.history_rounded,
                  label: 'Riwayat Jeda',
                  onTap: () => Get.toNamed(Routes.interventionHistory),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Chip alat bantu digital cepat
  Widget _buildToolChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: AppColors.teal),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Card 1: Screen Time (Terkoneksi data real jika permission aktif)
  Widget _buildScreenTimeCard() {
    return Obx(() {
      final hasAccess = controller.hasUsageAccess.value;
      final totalMillis = controller.todayScreenTimeMillis.value;

      final badgeText = hasAccess ? 'Aktif' : 'Monitoring belum aktif';
      final badgeColor = hasAccess
          ? AppColors.softMint
          : const Color(0xFFF1F5F9);
      final badgeTextColor =
          hasAccess ? AppColors.navy : AppColors.textSecondary;

      final mainStatus = hasAccess
          ? (totalMillis > 0
              ? DurationFormatter.format(totalMillis)
              : 'Belum ada data')
          : 'Belum ada data';
      final description = hasAccess
          ? (totalMillis > 0
              ? 'Total penggunaan hari ini'
              : 'Belum ada data penggunaan yang tersedia.')
          : 'Data penggunaan perangkat akan muncul setelah monitoring diaktifkan.';

      final progress = hasAccess && totalMillis > 0
          ? (totalMillis / (6 * 3600 * 1000)).clamp(0.05, 1.0)
          : null;

      return _buildWellnessCard(
        title: 'Screen Time',
        icon: Icons.smartphone_rounded,
        badgeText: badgeText,
        badgeColor: badgeColor,
        badgeTextColor: badgeTextColor,
        mainStatus: mainStatus,
        description: description,
        progress: progress,
        progressColor: AppColors.teal,
        onTap: () async {
          await Get.toNamed(Routes.screenTime);
          controller.loadScreenTimeSummary();
        },
      );
    });
  }

  /// Card 2: Monitoring Mata (Eye Monitoring)
  Widget _buildEyeMonitoringCard() {
    return Obx(() {
      return _buildWellnessCard(
        title: 'Monitoring Mata',
        icon: Icons.visibility_outlined,
        badgeText: controller.eyeMonitoringBadgeText,
        badgeColor: controller.eyeMonitoringBadgeColor,
        badgeTextColor: controller.eyeMonitoringBadgeTextColor,
        mainStatus: controller.eyeMonitoringTitle,
        description: controller.eyeMonitoringDescription,
        onTap: () => Get.toNamed(Routes.eyeMonitoring),
      );
    });
  }

  /// Template Kartu Wellness Digital Seragam, Elegan & Stitch Compliant
  Widget _buildWellnessCard({
    required String title,
    required IconData icon,
    required String badgeText,
    required Color badgeColor,
    required Color badgeTextColor,
    required String mainStatus,
    required String description,
    double? progress,
    Color? progressColor,
    VoidCallback? onTap,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        size: 20,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: badgeTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        mainStatus,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 22,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                if (progress != null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progressColor ?? AppColors.teal,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Section: Insight Hari Ini (Smart AI Behavioral Insight)
  Widget _buildInsightSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              size: 20,
              color: AppColors.teal,
            ),
            SizedBox(width: 8),
            Text(
              'Insight Hari Ini',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Obx(() {
          final isDetected = controller.todayDetection.value?.detected ?? false;
          final intervention =
              controller.todayDetection.value?.suggestedIntervention;

          return Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDetected
                    ? AppColors.teal.withValues(alpha: 0.45)
                    : const Color(0xFFE2E8F0),
                width: isDetected ? 1.6 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navy.withValues(alpha: 0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Get.toNamed(Routes.insight),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: AppColors.softMint,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.auto_awesome_rounded,
                              size: 18,
                              color: AppColors.navy,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              controller.detectionTitle,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.navy,
                              ),
                            ),
                          ),
                          if (isDetected && intervention != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.softMint,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                intervention,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.navy,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (isDetected &&
                          controller.recommendationSnippet.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        InkWell(
                          onTap: () {
                            if (intervention == 'Mode Fokus') {
                              Get.toNamed(Routes.focusMode);
                            } else {
                              Get.toNamed(Routes.insight);
                            }
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.softMint,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.lightbulb_outline_rounded,
                                  size: 16,
                                  color: AppColors.navy,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    controller.recommendationSnippet,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.navy,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 14,
                                  color: AppColors.navy,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Text(
                        controller.detectionDescription,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            isDetected ? 'Lihat Pilihan' : 'Lihat Insight',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: isDetected
                                  ? AppColors.teal
                                  : AppColors.navy,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: isDetected
                                ? AppColors.teal
                                : AppColors.navy,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
