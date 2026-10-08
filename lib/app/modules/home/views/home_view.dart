import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../../core/widgets/app_bottom_navigation.dart';
import '../../../data/models/intervention_model.dart';
import '../../../routes/app_routes.dart';
import '../controllers/home_controller.dart';

/// Halaman Utama (Dashboard) MIND DRIJI
/// Didesain dengan tata letak & estetika aplikasi Digital Wellbeing modern:
/// - AppBar & Branding dengan akses cepat ke Target Apps dan Refresh
/// - Sapaan ramah personal & tanggal hari ini
/// - Banner Intervensi Aktif jika sedang berjalan
/// - Pusat Aksi Cepat: Fokus & Intervensi Digital (Digital Detox)
/// - Tiga Pilar Digital Wellbeing: Screen Time, Pola Scrolling, Monitoring Mata
/// - Smart AI Insight & Rekomendasi Perilaku Harian
class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Obx(() {
        if (controller.isLoading.value && controller.profile.value == null) {
          return _buildLoadingState();
        }

        if (controller.errorMessage.value != null &&
            controller.profile.value == null) {
          return _buildErrorState();
        }

        return _buildHomeContent();
      }),
      bottomNavigationBar: const AppBottomNavigation(currentIndex: 0),
    );
  }

  /// AppBar dengan branding MIND DRIJI & aksi cepat
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFF14B8A6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.spa_rounded,
              size: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.appName,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.secondary,
                  letterSpacing: 0.6,
                ),
              ),
              Text(
                'Digital Wellbeing Companion',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.2,
                ),
              ),
            ],
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
            color: AppColors.secondary,
            size: 22,
          ),
          tooltip: 'Target Aplikasi',
          onPressed: () => Get.toNamed(Routes.targetApps),
        ),
        IconButton(
          icon: const Icon(
            Icons.refresh_rounded,
            color: AppColors.secondary,
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
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 3,
          ),
          SizedBox(height: 16),
          Text(
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
              width: 68,
              height: 68,
              decoration: const BoxDecoration(
                color: Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 34,
                color: Color(0xFFE53E3E),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Data pengguna belum dapat dimuat.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => controller.loadHomeData(),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
      color: AppColors.primary,
      backgroundColor: AppColors.card,
      onRefresh: () => controller.loadHomeData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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

            // 3. Fokus & Intervensi Digital (Digital Detox Shortcut Center)
            _buildInterventionShortcutBanner(),
            const SizedBox(height: 20),

            // 4. Pilar Digital Wellbeing: Screen Time, Pola Scrolling, Monitoring Mata
            _buildScreenTimeCard(),
            const SizedBox(height: 14),
            _buildDoomscrollingCard(),
            const SizedBox(height: 14),
            _buildEyeMonitoringCard(),
            const SizedBox(height: 20),

            // 5. Section AI Insight Hari Ini
            _buildInsightSection(),
            const SizedBox(height: 28),
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
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 12,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 5),
                Text(
                  formattedDate,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
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
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBBF7D0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF16A34A).withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.spa_rounded,
              color: AppColors.primary,
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
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF14532D),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Sisa waktu: ${controller.activeInterventionRemaining}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF166534),
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
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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

  /// Banner Aksi Cepat / Shortcut Intervensi Utama (Digital Detox Tools)
  Widget _buildInterventionShortcutBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  size: 20,
                  color: AppColors.primary,
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
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
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
          const SizedBox(height: 14),

          // Tombol Aksi Utama
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Get.toNamed(Routes.focusMode),
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('Mulai Focus Mode'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: () => Get.toNamed(Routes.intervention),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.secondary,
                  side: const BorderSide(color: AppColors.border),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Semua Intervensi'),
              ),
            ],
          ),
          const SizedBox(height: 12),

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
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border, width: 0.8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
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
          ? const Color(0xFFDCFCE7)
          : AppColors.secondary.withValues(alpha: 0.08);
      final badgeTextColor =
          hasAccess ? const Color(0xFF15803D) : AppColors.textSecondary;

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

      // Progress bar proporsional jika data tersedia (target harian: 6 jam)
      final progress = hasAccess && totalMillis > 0
          ? (totalMillis / (6 * 3600 * 1000)).clamp(0.05, 1.0)
          : 0.0;

      return _buildWellnessCard(
        title: 'Screen Time',
        icon: Icons.smartphone_rounded,
        badgeText: badgeText,
        badgeColor: badgeColor,
        badgeTextColor: badgeTextColor,
        mainStatus: mainStatus,
        description: description,
        progress: hasAccess && totalMillis > 0 ? progress : null,
        progressColor: AppColors.primary,
        onTap: () async {
          await Get.toNamed(Routes.screenTime);
          controller.loadScreenTimeSummary();
        },
      );
    });
  }

  /// Card 2: Pola Scrolling (Doomscrolling, Menggunakan data nyata dari MonitoringDataService)
  Widget _buildDoomscrollingCard() {
    return Obx(() {
      final isMonitoringActive = controller.isDoomscrollMonitoringActive;
      final summary = controller.doomscrollSummary.value;

      final badgeText = isMonitoringActive ? 'Aktif' : 'Monitoring tidak aktif';
      final badgeColor = isMonitoringActive
          ? const Color(0xFFDCFCE7)
          : AppColors.secondary.withValues(alpha: 0.08);
      final badgeTextColor = isMonitoringActive
          ? const Color(0xFF15803D)
          : AppColors.textSecondary;

      final mainStatus = controller.doomscrollDataStatusText;
      final description = isMonitoringActive
          ? (summary.totalSessions > 0
              ? 'Aktivitas scrolling terdeteksi pada aplikasi media sosial target.'
              : 'Monitoring aktif memantau aplikasi target.')
          : 'Aktifkan izin aksesibilitas untuk mendeteksi pola scrolling.';

      return _buildWellnessCard(
        title: 'Pola Scrolling',
        icon: Icons.swipe_vertical_rounded,
        badgeText: badgeText,
        badgeColor: badgeColor,
        badgeTextColor: badgeTextColor,
        mainStatus: mainStatus,
        description: description,
        onTap: () async {
          await Get.toNamed(Routes.doomscrolling);
          controller.loadDoomscrollSummary();
        },
      );
    });
  }

  /// Card 3: Monitoring Mata (Eye Monitoring, Reactive terhadap EyeMonitoringService)
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

  /// Template Kartu Wellness Digital Seragam & Elegan
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
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.02),
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
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        icon,
                        size: 20,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
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
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
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
                      minHeight: 5,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progressColor ?? AppColors.primary,
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
              Icons.lightbulb_outline_rounded,
              size: 20,
              color: AppColors.secondary,
            ),
            SizedBox(width: 8),
            Text(
              'Insight Hari Ini',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
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
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDetected
                    ? AppColors.primary.withValues(alpha: 0.3)
                    : AppColors.border,
                width: isDetected ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondary.withValues(alpha: 0.02),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
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
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.auto_awesome_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              controller.detectionTitle,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (isDetected && intervention != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                intervention,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (isDetected &&
                          controller.recommendationSnippet.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () {
                            if (intervention == 'Mode Fokus') {
                              Get.toNamed(Routes.focusMode);
                            } else {
                              Get.toNamed(Routes.insight);
                            }
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6F8F5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.lightbulb_outline_rounded,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    controller.recommendationSnippet,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 14,
                                  color: AppColors.primary,
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
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDetected
                                  ? AppColors.primary
                                  : AppColors.secondary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: isDetected
                                ? AppColors.primary
                                : AppColors.secondary,
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
