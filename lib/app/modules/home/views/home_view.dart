import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../../core/widgets/app_bottom_navigation.dart';
import '../../../core/widgets/stitch_widgets.dart';
import '../../../data/models/app_usage_model.dart';
import '../../../data/models/intervention_model.dart';
import '../../../data/models/monitoring_visualization_model.dart';
import '../../../routes/app_routes.dart';
import '../controllers/home_controller.dart';

/// Halaman Utama (Dashboard) MIND DRIJI - Modern Digital Wellness Redesign
///
/// Mengikuti prinsip desain: "Calm, Intelligent, Personal Digital Wellness"
///
/// Hierarki Visual:
/// 1. Header ringkas: Logo resmi MIND DRIJI, teks nama aplikasi & companion, sapaan personal dinamis,
///    tanggal hari ini, dan aksi notifikasi/status sistem tunggal.
/// 2. Ringkasan Layar Hari Ini (Hero Focal Card): Total waktu pemakaian, circular segmented ring
///    berdasarkan sesi waktu (Dini Hari, Pagi, Siang, Sore, Malam), perbandingan kemarin, dan Top 5 Aplikasi.
/// 3. Pola Scrolling & Monitoring Mata: Dua kartu seimbang, informatif, dan responsif (side-by-side).
///    - Pola Scrolling: status izin, sesi, swipes, dan subbagian "Aplikasi Terbanyak Di-scroll".
///    - Monitoring Mata: status fitur vs status sensor kamera terpisah, sesi pemeriksaan, kedipan.
/// 4. Intervensi Digital: Pusat aksi relaksasi, Focus Mode, dan alat bantu digital mandiri.
/// 5. Aksi Cepat (Quick Shortcuts): 4 akses instan (Screen Time, Pola Scrolling, Monitoring Mata, Target Apps).
/// 6. Insight Hari Ini: Ringkasan cerdas pola digital berbasis data aktual dari DetectionService.
/// 7. Bottom Navigation M3 tetap dipertahankan.
class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  static const Color homeBgColor = Color(0xFFEAF2F7);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: homeBgColor,
      appBar: _buildAppBar(context),
      body: Container(
        decoration: const BoxDecoration(
          color: homeBgColor,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEAF2F7), Color(0xFFE4F0F4), Color(0xFFEAF2F7)],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          child: Obx(() {
            if (controller.isLoading.value &&
                controller.profile.value == null) {
              return _buildLoadingState();
            }

            if (controller.errorMessage.value != null &&
                controller.profile.value == null) {
              return _buildErrorState();
            }

            return _buildHomeContent(context);
          }),
        ),
      ),
      bottomNavigationBar: const AppBottomNavigation(currentIndex: 0),
    );
  }

  /// AppBar Ringkas dengan Logo Resmi MIND DRIJI & Aksi Notifikasi Tunggal
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo resmi MIND DRIJI dari asset proyek
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: AppColors.navy.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              'assets/icons/app_icon.png',
              width: 36,
              height: 36,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Image.asset(
                'assets/icons/loader/full_mark.png',
                width: 36,
                height: 36,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppStrings.appName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  'Digital Wellness Companion',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
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
      backgroundColor: homeBgColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      actions: [
        // Sesuai ketentuan: Di sebelah kanan cukup satu ikon notifikasi yang berfungsi
        IconButton(
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: AppColors.navy,
            size: 24,
          ),
          tooltip: 'Pemberitahuan Sistem & Intervensi',
          onPressed: () => _showNotificationSheet(context),
        ),
        const SizedBox(width: 6),
      ],
    );
  }

  /// Menampilkan modal bottom sheet status sistem & notifikasi intervensi
  void _showNotificationSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Icon(
                      Icons.notifications_active_rounded,
                      color: AppColors.teal,
                      size: 22,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Pemberitahuan & Status Sistem',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (controller.isInterventionActive)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.successContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.spa_rounded,
                          color: AppColors.success,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${controller.activeInterventionTitle} sedang berlangsung (${controller.activeInterventionRemaining})',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSuccessContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                _buildNotificationItem(
                  icon: Icons.timer_outlined,
                  color: AppColors.teal,
                  title: 'Monitoring Screen Time',
                  subtitle: controller.hasUsageAccess.value
                      ? 'Izin penggunaan aktif & terhubung.'
                      : 'Izin penggunaan belum diaktifkan.',
                ),
                const SizedBox(height: 10),
                _buildNotificationItem(
                  icon: Icons.swap_vert_rounded,
                  color: AppColors.cyan,
                  title: 'Monitoring Scrolling',
                  subtitle: controller.hasAccessibilityPermission.value
                      ? 'Aksesibilitas aktif mendeteksi pola scrolling.'
                      : 'Izin aksesibilitas belum aktif.',
                ),
                const SizedBox(height: 10),
                _buildNotificationItem(
                  icon: Icons.visibility_outlined,
                  color: AppColors.teal,
                  title: 'Monitoring Mata',
                  subtitle: controller.isEyeMonitoringEnabled.value
                      ? 'Monitoring aktif (${controller.cameraSensorStatusText}).'
                      : 'Monitoring mata belum diaktifkan.',
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Get.toNamed(Routes.interventionHistory);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: const Text(
                      'Lihat Riwayat Intervensi',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// State saat memuat data profil awal (menggunakan MindDrijiLoader native)
  Widget _buildLoadingState() {
    return const Center(
      child: MindDrijiLoader(size: 72, message: 'Memuat dashboard wellness...'),
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
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: AppColors.errorContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 30,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Data pengguna belum dapat dimuat.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 16),
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

  /// Konten utama Dashboard Home Digital Wellness
  Widget _buildHomeContent(BuildContext context) {
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
            // A. Sapaan Personal Dinamis & Tanggal Lokal
            _buildUserGreeting(),
            const SizedBox(height: 16),

            // Banner Intervensi Aktif (jika ada sesi berjalan)
            if (controller.isInterventionActive) ...[
              _buildActiveInterventionBanner(),
              const SizedBox(height: 16),
            ],

            // B. Fokus Utama: Kartu Utama Layar Hari Ini (Hero Card)
            _buildScreenTimeHeroCard(),
            const SizedBox(height: 16),

            // C. Dua Kartu Seimbang: Pola Scrolling & Monitoring Mata (Side-by-side)
            _buildDualMonitoringRow(),
            const SizedBox(height: 16),

            // D. Kartu Intervensi Digital
            _buildInterventionCard(),
            const SizedBox(height: 16),

            // E. Aksi Cepat (Quick Shortcuts)
            _buildQuickActionsRow(),
            const SizedBox(height: 16),

            // F. Insight Hari Ini
            _buildInsightSection(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// A. Sapaan Ramah Pengguna & Tanggal Hari Ini
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
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Bagaimana kebiasaan digitalmu hari ini?',
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
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
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
                    fontSize: 11.5,
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
    const days = [
      'Minggu',
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
    ];
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    final dayName = days[now.weekday % 7];
    final monthName = months[now.month - 1];
    return '$dayName, ${now.day} $monthName ${now.year}';
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
              final activeType = controller
                  .interventionService
                  ?.activeIntervention
                  .value
                  ?.type;
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

  /// B. KARTU UTAMA: LAYAR HARI INI (HERO CARD)
  ///
  /// Fokus visual pertama dashboard:
  /// - Bagian Atas: Ikon Screen Time, Judul `Layar Hari Ini`, Subtitle `Total penggunaan perangkat`,
  ///   badge status, dan indikator perbandingan hari kemarin.
  /// - Bagian Tengah: Circular Segmented Ring (Dini Hari, Pagi, Siang, Sore, Malam) berdasarkan
  ///   agregasi durasi penggunaan real hari ini, dengan total waktu di tengah ring dan legenda segmen.
  /// - Bagian Bawah: Separator dan Top 5 Aplikasi berdasarkan durasi penggunaan hari ini.
  Widget _buildScreenTimeHeroCard() {
    return Obx(() {
      final hasAccess = controller.hasUsageAccess.value;
      final totalMillis = controller.todayScreenTimeMillis.value;
      final topApps = controller.topApps;
      final segments = controller.displayTimeSegments;
      final yesterdayComp = controller.yesterdayComparisonText;

      final mainStatus = hasAccess
          ? (totalMillis > 0
                ? DurationFormatter.format(totalMillis)
                : 'Belum ada data')
          : 'Belum ada data';

      final description = hasAccess
          ? (totalMillis > 0
                ? 'Total penggunaan hari ini'
                : 'Belum ada data penggunaan yang tersedia.')
          : 'Belum ada data';

      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: hasAccess
                ? AppColors.teal.withValues(alpha: 0.3)
                : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              await Get.toNamed(Routes.screenTime);
              controller.loadScreenTimeSummary();
            },
            borderRadius: BorderRadius.circular(22),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Header Bagian Atas
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.softMint,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.smartphone_rounded,
                          size: 20,
                          color: AppColors.navy,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Layar Hari Ini',
                                  style: TextStyle(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.navy,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Screen Time',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Total penggunaan perangkat',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (hasAccess) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.softMint,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.teal.withValues(alpha: 0.25),
                              width: 1,
                            ),
                          ),
                          child: const Text(
                            'Aktif',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.navy,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 22,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),

                  // Indikator Perbandingan Kemarin (Hanya jika data valid tersedia)
                  if (hasAccess && yesterdayComp != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            yesterdayComp.startsWith('+')
                                ? Icons.trending_up_rounded
                                : Icons.trending_down_rounded,
                            size: 14,
                            color: yesterdayComp.startsWith('+')
                                ? AppColors.warning
                                : AppColors.teal,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            yesterdayComp,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.navy,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // 2. Bagian Tengah: Visualisasi Circular Segmented Ring & Legenda Sesi Waktu
                  if (!hasAccess || totalMillis == 0) ...[
                    // Empty state terpadu
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                mainStatus,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.navy,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                description,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.textSecondary,
                                  height: 1.35,
                                ),
                              ),
                              if (!hasAccess) ...[
                                const SizedBox(height: 10),
                                OutlinedButton.icon(
                                  onPressed: () =>
                                      controller.openUsageAccessSettings(),
                                  icon: const Icon(
                                    Icons.lock_open_rounded,
                                    size: 15,
                                  ),
                                  label: const Text('Aktifkan Izin'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.teal,
                                    side: const BorderSide(
                                      color: AppColors.teal,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    minimumSize: const Size(0, 32),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: CustomPaint(
                            painter: _SegmentedScreenTimeGaugePainter(
                              segments: const [],
                              totalMillis: 0,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.hourglass_top_rounded,
                                size: 24,
                                color: Color(0xFFCBD5E1),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // Data real tersedia: Circular Segmented Ring di sebelah kiri & Legenda periode di sebelah kanan
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final maxWidth = constraints.maxWidth;

                        // Ukuran ring responsif proporsional terhadap lebar kartu
                        final ringSize = (maxWidth * 0.44).clamp(108.0, 132.0);
                        final spacing = (maxWidth * 0.05).clamp(10.0, 20.0);
                        final dotSize = ringSize >= 120 ? 9.0 : 8.0;
                        final legendFontSize = ringSize >= 120 ? 12.0 : 11.0;
                        final legendPadding = ringSize >= 120 ? 3.5 : 2.5;

                        final gaugeWidget = SizedBox(
                          width: ringSize,
                          height: ringSize,
                          child: CustomPaint(
                            painter: _SegmentedScreenTimeGaugePainter(
                              segments: segments,
                              totalMillis: totalMillis,
                            ),
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        DurationFormatter.format(totalMillis),
                                        style: TextStyle(
                                          fontSize: ringSize >= 120 ? 23 : 20,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.navy,
                                          letterSpacing: -0.6,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        'Total penggunaan hari ini',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: ringSize >= 120 ? 9.5 : 8.5,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );

                        final legendWidget = _buildSegmentLegend(
                          segments: segments,
                          dotSize: dotSize,
                          fontSize: legendFontSize,
                          verticalPadding: legendPadding,
                        );

                        // Prioritaskan posisi kiri-kanan (Row) selama masih muat (maxWidth >= 210)
                        if (maxWidth < 210) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Center(child: gaugeWidget),
                              const SizedBox(height: 14),
                              legendWidget,
                            ],
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // 1. Lingkaran segmented Screen Time di sebelah kiri
                            gaugeWidget,
                            SizedBox(width: spacing),
                            // 2. Legenda periode penggunaan di sebelah kanan lingkaran, tersusun vertikal
                            Expanded(child: legendWidget),
                          ],
                        );
                      },
                    ),
                  ],

                  // 3. Bagian Bawah: Separator dan Top 5 Aplikasi
                  const SizedBox(height: 18),
                  const Divider(color: Color(0xFFF1F5F9), height: 1),
                  const SizedBox(height: 14),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Top 5 Aplikasi',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                        ),
                      ),
                      InkWell(
                        onTap: () => Get.toNamed(Routes.screenTime),
                        borderRadius: BorderRadius.circular(6),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          child: Row(
                            children: [
                              Text(
                                'Lihat Semua',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.teal,
                                ),
                              ),
                              SizedBox(width: 2),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 16,
                                color: AppColors.teal,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _buildTopAppsSection(topApps),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  /// Legenda 5 periode waktu: Dini Hari, Pagi, Siang, Sore, Malam (hanya warna & nama periode)
  Widget _buildSegmentLegend({
    required List<TimeSegmentUsage> segments,
    double dotSize = 9.0,
    double fontSize = 12.0,
    double verticalPadding = 3.5,
  }) {
    const segmentColors = _SegmentedScreenTimeGaugePainter.segmentColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(segments.length, (index) {
        final seg = segments[index];
        final color = index < segmentColors.length
            ? segmentColors[index]
            : AppColors.teal;

        return Padding(
          padding: EdgeInsets.symmetric(vertical: verticalPadding),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: dotSize,
                height: dotSize,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  seg.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  /// Top 5 Aplikasi: Berderet horizontal dengan ikon aplikasi asli dan nama aplikasi di bawahnya
  Widget _buildTopAppsSection(List<AppUsageModel> apps) {
    if (apps.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Belum ada data aplikasi hari ini.',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: apps.take(5).map((app) {
          return Container(
            width: 64,
            margin: const EdgeInsets.only(right: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildAppIconWidget(
                  packageName: app.packageName,
                  appName: app.appName,
                  size: 38,
                ),
                const SizedBox(height: 6),
                Text(
                  app.appName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Widget Ikon Aplikasi Cerdas: Menggunakan Android PackageManager native via MethodChannel
  /// dengan fallback berakurasi tinggi ke brand color & icon populer (TikTok, IG, YT, dll.)
  Widget _buildAppIconWidget({
    required String packageName,
    required String appName,
    double size = 38,
  }) {
    return FutureBuilder<Uint8List?>(
      future: controller.getAppIconBytes(packageName),
      builder: (context, snapshot) {
        if (snapshot.hasData &&
            snapshot.data != null &&
            snapshot.data!.isNotEmpty) {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size * 0.28),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navy.withValues(alpha: 0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(size * 0.28),
              child: Image.memory(
                snapshot.data!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _buildFallbackAppIcon(packageName, appName, size),
              ),
            ),
          );
        }
        return _buildFallbackAppIcon(packageName, appName, size);
      },
    );
  }

  /// Fallback ikon aplikasi teridentifikasi brand atau generik konsisten
  Widget _buildFallbackAppIcon(
    String packageName,
    String appName,
    double size,
  ) {
    final pkg = packageName.toLowerCase();
    final name = appName.toLowerCase();

    IconData iconData = Icons.apps_rounded;
    Color bgColor = const Color(0xFF00BFA5);
    Color iconColor = Colors.white;

    if (pkg.contains('musically') ||
        pkg.contains('tiktok') ||
        name.contains('tiktok')) {
      iconData = Icons.music_note_rounded;
      bgColor = const Color(0xFF000000);
    } else if (pkg.contains('instagram') || name.contains('instagram')) {
      iconData = Icons.camera_alt_rounded;
      bgColor = const Color(0xFFE1306C);
    } else if (pkg.contains('youtube') || name.contains('youtube')) {
      iconData = Icons.play_arrow_rounded;
      bgColor = const Color(0xFFFF0000);
    } else if (pkg.contains('whatsapp') || name.contains('whatsapp')) {
      iconData = Icons.chat_rounded;
      bgColor = const Color(0xFF25D366);
    } else if (pkg.contains('chrome') || name.contains('chrome')) {
      iconData = Icons.language_rounded;
      bgColor = const Color(0xFF4285F4);
    } else if (pkg.contains('twitter') ||
        pkg.contains('.x.') ||
        name.contains('twitter') ||
        name == 'x') {
      iconData = Icons.alternate_email_rounded;
      bgColor = const Color(0xFF1DA1F2);
    } else if (pkg.contains('facebook') || name.contains('facebook')) {
      iconData = Icons.facebook_rounded;
      bgColor = const Color(0xFF1877F2);
    } else if (pkg.contains('telegram') || name.contains('telegram')) {
      iconData = Icons.send_rounded;
      bgColor = const Color(0xFF0088CC);
    } else if (pkg.contains('snapchat') || name.contains('snapchat')) {
      iconData = Icons.chat_bubble_rounded;
      bgColor = const Color(0xFFFFFC00);
      iconColor = Colors.black87;
    } else {
      iconData = Icons.smartphone_rounded;
      bgColor = const Color(0xFFDDF4F2);
      iconColor = const Color(0xFF0B2030);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(iconData, size: size * 0.54, color: iconColor),
    );
  }

  /// C. DUA KARTU SEIMBANG: Pola Scrolling dan Monitoring Mata (Side-by-side)
  Widget _buildDualMonitoringRow() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Kartu Pola Scrolling
          Expanded(child: _buildScrollingCard()),
          const SizedBox(width: 14),
          // 2. Kartu Monitoring Mata
          Expanded(child: _buildEyeCard()),
        ],
      ),
    );
  }

  /// Kartu Pola Scrolling (Kiri)
  Widget _buildScrollingCard() {
    return Obx(() {
      final isMonitoringActive = controller.isDoomscrollMonitoringActive;
      final summary = controller.doomscrollSummary.value;
      final mostScrolled = controller.mostScrolledApp.value;

      final badgeText = isMonitoringActive ? 'Aktif' : 'Belum Aktif';
      final badgeColor = isMonitoringActive
          ? AppColors.softMint
          : const Color(0xFFF1F5F9);
      final badgeTextColor = isMonitoringActive
          ? AppColors.navy
          : AppColors.textSecondary;

      final mainStatus = isMonitoringActive
          ? (summary.totalSessions > 0
                ? '${summary.totalSessions} sesi • ${summary.durationFormatted}'
                : 'Belum ada data')
          : 'Belum Aktif';

      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isMonitoringActive
                ? AppColors.teal.withValues(alpha: 0.3)
                : const Color(0xFFE2E8F0),
            width: 1,
          ),
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
            onTap: () async {
              await Get.toNamed(Routes.doomscrolling);
              controller.loadDoomscrollSummary();
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Header
                  Column(
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
                              Icons.swipe_vertical_rounded,
                              size: 18,
                              color: AppColors.navy,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: badgeColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              badgeText,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: badgeTextColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Pola Scrolling',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mainStatus,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),

                  // Subbagian Khusus: Aplikasi Terbanyak Di-scroll
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 0.8,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Aplikasi Terbanyak Di-scroll',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (mostScrolled != null) ...[
                            Row(
                              children: [
                                _buildAppIconWidget(
                                  packageName: mostScrolled.packageName,
                                  appName: mostScrolled.appName,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    mostScrolled.appName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.navy,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  size: 16,
                                  color: AppColors.teal,
                                ),
                              ],
                            ),
                          ] else ...[
                            const Text(
                              'Belum ada data',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontStyle: FontStyle.italic,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  /// Kartu Monitoring Mata (Kanan)
  Widget _buildEyeCard() {
    return Obx(() {
      final isEnabled = controller.isEyeMonitoringEnabled.value;
      final badgeText = controller.eyeMonitoringBadgeText;
      final badgeColor = controller.eyeMonitoringBadgeColor;
      final badgeTextColor = controller.eyeMonitoringBadgeTextColor;
      final sessionCount = controller.todayEyeSessionCount.value;
      final blinkCount = controller.todayBlinkCount.value;

      final mainStatus = isEnabled
          ? (controller.isEyeSessionRunning.value
                ? 'Sedang memantau'
                : (sessionCount > 0
                      ? '$sessionCount sesi • $blinkCount kedipan'
                      : 'Monitoring aktif'))
          : 'Belum Aktif';

      final description = isEnabled
          ? (controller.isEyeSessionRunning.value
                ? 'Kamera sedang digunakan untuk pemantauan mata.'
                : 'Pemantauan mata berjalan otomatis.')
          : '';

      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isEnabled
                ? AppColors.teal.withValues(alpha: 0.3)
                : const Color(0xFFE2E8F0),
            width: 1,
          ),
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
            onTap: () => Get.toNamed(Routes.eyeMonitoring),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Header
                  Column(
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
                              Icons.visibility_outlined,
                              size: 18,
                              color: AppColors.navy,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: badgeColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              badgeText,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: badgeTextColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Monitoring Mata',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mainStatus,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Panel Terpisah: Status Kamera / Sensor
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 0.8,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Status Kamera',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: controller.cameraSensorStatusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  controller.cameraSensorStatusText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: controller.cameraSensorStatusColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  /// D. KARTU INTERVENSI DIGITAL: Mode Fokus & Jeda Terarah
  Widget _buildInterventionCard() {
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
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.softMint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  size: 20,
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

          // Tombol Aksi Utama: Mulai Focus Mode & Semua Intervensi
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
                    minimumSize: const Size(0, 46),
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
                    minimumSize: const Size(0, 46),
                    side: const BorderSide(
                      color: Color(0xFFE2E8F0),
                      width: 1.4,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
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

          // Shortcut Chips Intervensi Terarah
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildToolChip(
                  icon: Icons.visibility_rounded,
                  label: 'Relaksasi Mata',
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

  /// E. AKSI CEPAT: Baris Shortcut Ikonik Ringkas & Konsisten
  Widget _buildQuickActionsRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Aksi Cepat',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildQuickActionButton(
                icon: Icons.smartphone_rounded,
                label: 'Screen Time',
                onTap: () => Get.toNamed(Routes.screenTime),
              ),
              _buildQuickActionButton(
                icon: Icons.swipe_vertical_rounded,
                label: 'Pola Scrolling',
                onTap: () => Get.toNamed(Routes.doomscrolling),
              ),
              _buildQuickActionButton(
                icon: Icons.visibility_outlined,
                label: 'Monitoring Mata',
                onTap: () => Get.toNamed(Routes.eyeMonitoring),
              ),
              _buildQuickActionButton(
                icon: Icons.tune_rounded,
                label: 'Target Apps',
                onTap: () => Get.toNamed(Routes.targetApps),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 0.8,
                  ),
                ),
                child: Icon(icon, size: 20, color: AppColors.navy),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10.5,
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

  /// F. SECTION: Insight Hari Ini (Smart AI Behavioral Insight)
  Widget _buildInsightSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.auto_awesome_rounded, size: 20, color: AppColors.teal),
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
                                horizontal: 10,
                                vertical: 4,
                              ),
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
                              horizontal: 12,
                              vertical: 8,
                            ),
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
                            color: isDetected ? AppColors.teal : AppColors.navy,
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

/// Circular Segmented Time Visualization Painter untuk Layar Hari Ini
///
/// Membagi lingkaran ke dalam 5 periode penggunaan harian (MIND DRIJI):
/// - Dini Hari (00:00–04:59): #334E68 (Deep Slate Navy)
/// - Pagi (05:00–10:59):      #48CAE4 (Soft Mint Cyan)
/// - Siang (11:00–14:59):     #00B4D8 (Vibrant Cyan)
/// - Sore (15:00–17:59):      #00BFA5 (Primary Teal)
/// - Malam (18:00–23:59):     #10B981 (Bright Emerald Lime)
class _SegmentedScreenTimeGaugePainter extends CustomPainter {
  final List<TimeSegmentUsage> segments;
  final int totalMillis;

  static const List<Color> segmentColors = [
    Color(0xFF334E68), // Dini Hari
    Color(0xFF48CAE4), // Pagi
    Color(0xFF00B4D8), // Siang
    Color(0xFF00BFA5), // Sore
    Color(0xFF10B981), // Malam
  ];

  _SegmentedScreenTimeGaugePainter({
    required this.segments,
    required this.totalMillis,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const strokeWidth = 10.0;
    final radius = (size.width - strokeWidth) / 2;

    // Lingkaran latar belakang
    final bgPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    if (totalMillis <= 0 || segments.isEmpty) {
      return;
    }

    // Segmen aktif yang memiliki durasi penggunaan > 0
    final activeSegments = <Map<String, dynamic>>[];
    for (int i = 0; i < segments.length && i < segmentColors.length; i++) {
      final seg = segments[i];
      if (seg.screenTimeMillis > 0) {
        activeSegments.add({
          'segment': seg,
          'color': segmentColors[i],
          'ratio': seg.screenTimeMillis / totalMillis,
        });
      }
    }

    if (activeSegments.isEmpty) {
      return;
    }

    // Posisi awal: -pi / 2 (posisi jam 12 atas)
    double currentAngle = -math.pi / 2;
    final gapAngle = activeSegments.length > 1 ? 0.08 : 0.0;
    final totalGap = gapAngle * activeSegments.length;
    final availableAngle = (2 * math.pi) - totalGap;

    for (final item in activeSegments) {
      final ratio = item['ratio'] as double;
      final color = item['color'] as Color;
      final sweepAngle = (availableAngle * ratio).clamp(0.02, 2 * math.pi);

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        currentAngle + (gapAngle / 2),
        sweepAngle,
        false,
        paint,
      );

      currentAngle += sweepAngle + gapAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _SegmentedScreenTimeGaugePainter oldDelegate) {
    return oldDelegate.totalMillis != totalMillis ||
        oldDelegate.segments != segments;
  }
}
