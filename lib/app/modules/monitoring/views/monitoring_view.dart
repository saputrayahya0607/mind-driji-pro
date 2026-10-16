import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../../core/widgets/app_bottom_navigation.dart';
import '../../../core/widgets/mind_driji_loader.dart';
import '../../../data/models/monitoring_visualization_model.dart';
import '../../../routes/app_routes.dart';
import '../controllers/monitoring_controller.dart';

/// Redesign Modern & Minimalis Halaman Monitoring MIND DRIJI
///
/// Fitur & Desain:
/// - Background soft blue-gray `#EAF2F7`
/// - Header Global MIND DRIJI konsisten dengan Home & Insight (Logo, Teks, Subtitle, Notifikasi)
/// - Card putih `#FFFFFF`, radius 20dp, border halus `#DCE5EE`
/// - Typography ringkas, hierarki jelas, tanpa teks berulang
/// - Pemilih periode segmented satu baris: Hari | Minggu | Bulan
/// - Navigasi tanggal ringkas dengan batas tanggal masa depan
/// - Card Pola Scrolling beraksen orange (#F59E0B) dengan 3 metrik utama & grafik minimalis
/// - Card Total Screen Time beraksen teal (#00BFA5) dengan durasi besar & grafik horizontal 5 waktu
/// - Card Penggunaan Aplikasi (Top 5) dengan ikon native Android, nama aplikasi, & durasi
/// - Card Monitoring Mata beraksen cyan/teal dengan 5 statistik adaptif & status sensor kamera ringkas
class MonitoringView extends GetView<MonitoringController> {
  const MonitoringView({super.key});

  static const Color pageBgColor = Color(0xFFEAF2F7);
  static const Color cardBorderColor = Color(0xFFDCE5EE);
  static const Color orangeAccent = Color(0xFFF59E0B);
  static const Color orangeBg = Color(0xFFFEF3C7);
  static const Color tealAccent = Color(0xFF00BFA5);
  static const Color tealBg = Color(0xFFDDF4F2);
  static const Color cyanAccent = Color(0xFF00D9EC);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBgColor,
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.loadData,
          color: tealAccent,
          backgroundColor: Colors.white,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Pemilih Periode Segmented: Hari | Minggu | Bulan
                _buildPeriodSegmentedControl(),
                const SizedBox(height: 10),

                // 2. Navigasi Tanggal Ringkas
                _buildDateNavigationBar(),
                const SizedBox(height: 14),

                // Loading Indicator Ringkas
                Obx(() {
                  if (controller.isLoading.value) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Center(child: MindDrijiLoader.compact(size: 28)),
                    );
                  }
                  return const SizedBox.shrink();
                }),

                // 3. Card Pola Scrolling
                _buildDoomscrollCard(),
                const SizedBox(height: 14),

                // 4. Card Total Screen Time
                _buildScreenTimeCard(),
                const SizedBox(height: 14),

                // 5. Card Penggunaan Aplikasi (Top 5)
                _buildAppUsageCard(),
                const SizedBox(height: 14),

                // 6. Card Monitoring Mata
                _buildEyeMonitoringCard(),
                const SizedBox(height: 16),

                // 7. Modul Monitoring (Akses Cepat Ringkas)
                _buildQuickLinksSection(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavigation(currentIndex: 1),
    );
  }

  // ===========================================================================
  // 1. HEADER GLOBAL MIND DRIJI (SAMA PERSIS DENGAN HOME & INSIGHT)
  // ===========================================================================
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
      backgroundColor: pageBgColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      actions: [
        IconButton(
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: AppColors.navy,
            size: 24,
          ),
          tooltip: 'Pemberitahuan Sistem & Monitoring',
          onPressed: () => _showNotificationSheet(context),
        ),
        const SizedBox(width: 6),
      ],
    );
  }

  /// Menampilkan modal bottom sheet status sistem & notifikasi monitoring
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
                      color: tealAccent,
                      size: 22,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Pemberitahuan Sistem & Monitoring',
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cardBorderColor),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        color: tealAccent,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Sistem monitoring aktif mengumpulkan metrik digital wellness secara lokal & aman.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.navy,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tealAccent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                    child: const Text(
                      'Tutup',
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

  // ===========================================================================
  // 2. PEMILIH PERIODE: HARI | MINGGU | BULAN
  // ===========================================================================
  Widget _buildPeriodSegmentedControl() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Obx(() {
        final current = controller.selectedPeriod.value;
        return Row(
          children: [
            _buildSegmentTab('Hari', MonitoringPeriod.daily, current),
            _buildSegmentTab('Minggu', MonitoringPeriod.weekly, current),
            _buildSegmentTab('Bulan', MonitoringPeriod.monthly, current),
          ],
        );
      }),
    );
  }

  Widget _buildSegmentTab(
    String label,
    MonitoringPeriod period,
    MonitoringPeriod current,
  ) {
    final isSelected = current == period;
    return Expanded(
      child: GestureDetector(
        key: Key('tab_${period.name}'),
        onTap: () => controller.setPeriod(period),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? tealBg : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: tealAccent.withValues(alpha: 0.3), width: 1)
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppColors.navy : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 3. NAVIGASI TANGGAL RINGKAS
  // ===========================================================================
  Widget _buildDateNavigationBar() {
    return Obx(() {
      final label = controller.dateRangeLabel;
      final canNext = controller.canGoNext;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              key: const Key('btn_prev_date'),
              icon: const Icon(Icons.chevron_left_rounded, size: 24),
              color: AppColors.navy,
              onPressed: controller.goToPreviousPeriod,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              tooltip: 'Periode Sebelumnya',
            ),
            Expanded(
              child: Text(
                label,
                key: const Key('text_date_label'),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
            ),
            IconButton(
              key: const Key('btn_next_date'),
              icon: Icon(
                Icons.chevron_right_rounded,
                size: 24,
                color: canNext ? AppColors.navy : const Color(0xFFCBD5E1),
              ),
              onPressed: canNext ? controller.goToNextPeriod : null,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              tooltip: 'Periode Berikutnya',
            ),
          ],
        ),
      );
    });
  }

  // ===========================================================================
  // 4. CARD POLA SCROLLING (AKSEN ORANGE)
  // ===========================================================================
  Widget _buildDoomscrollCard() {
    return Obx(() {
      final summary = controller.doomscrollSummary.value;
      final hasData = summary.hasData;
      final period = controller.selectedPeriod.value;

      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cardBorderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Kotak orange muda, judul "Pola Scrolling", badge status singkat
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: orangeBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.swap_vert_rounded,
                    size: 20,
                    color: orangeAccent,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Pola Scrolling',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                _buildBadge(
                  text: hasData ? 'Aktif' : 'Belum Aktif',
                  bgColor: hasData ? orangeBg : const Color(0xFFF1F5F9),
                  textColor: hasData
                      ? const Color(0xFFB45309)
                      : AppColors.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (!hasData) ...[
              _buildCleanEmptyState(
                message: 'Belum ada data',
                icon: Icons.swap_vert_rounded,
              ),
            ] else ...[
              // 3 Metrik Utama: Sesi, Durasi, Total Scroll
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      label: 'Sesi',
                      value: '${summary.totalSessions}',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricTile(
                      label: 'Durasi',
                      value: summary.durationFormatted,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricTile(
                      label: 'Total Scroll',
                      value: '${summary.totalSwipes}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 2 Metrik Tambahan Kecil: Scroll Bawah & Scroll Atas
              Row(
                children: [
                  Expanded(
                    child: _buildSubMetricTile(
                      label: 'Scroll Bawah',
                      value: '${summary.downwardSwipes}',
                      icon: Icons.arrow_downward_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSubMetricTile(
                      label: 'Scroll Atas',
                      value: '${summary.upwardSwipes}',
                      icon: Icons.arrow_upward_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Divider Halus
              const Divider(color: Color(0xFFF1F5F9), height: 1),
              const SizedBox(height: 12),

              // Grafik Scrolling Minimalis Warna Orange
              if (period == MonitoringPeriod.daily)
                _buildDoomscrollDailyChart()
              else if (period == MonitoringPeriod.weekly)
                _buildDoomscrollWeeklyChart()
              else
                _buildDoomscrollMonthlyChart(),
            ],
          ],
        ),
      );
    });
  }

  /// Grafik Scrolling Harian: Distribusi per waktu (Dini Hari, Pagi, Siang, Sore, Malam)
  Widget _buildDoomscrollDailyChart() {
    final segments = controller.dailySegments;
    if (segments.isEmpty) return const SizedBox.shrink();

    final maxMillis = segments.fold<int>(
      1,
      (prev, s) => max(prev, s.doomscrollMillis),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(segments.length, (index) {
        final seg = segments[index];
        final hasVal = seg.doomscrollMillis > 0;
        final ratio = (seg.doomscrollMillis / maxMillis).clamp(0.0, 1.0);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              SizedBox(
                width: 68,
                child: Text(
                  seg.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: hasVal ? FontWeight.w700 : FontWeight.w500,
                    color: hasVal ? AppColors.navy : AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: hasVal
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 6,
                          backgroundColor: const Color(0xFFF1F5F9),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            orangeAccent,
                          ),
                        ),
                      )
                    : Container(
                        height: 2,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 44,
                child: Text(
                  hasVal ? seg.doomscrollFormatted : '—',
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: hasVal ? FontWeight.w700 : FontWeight.w500,
                    color: hasVal ? AppColors.navy : const Color(0xFF94A3B8),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  /// Grafik Scrolling Mingguan: Sen – Min (Bar Vertikal Orange Minimalis)
  Widget _buildDoomscrollWeeklyChart() {
    final days = controller.weeklyDays;
    if (days.isEmpty) return const SizedBox.shrink();

    final maxMillis = days.fold<int>(
      1,
      (prev, d) => max(prev, d.doomscrollMillis),
    );

    return SizedBox(
      height: 74,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: days.map((d) {
          final hasVal = d.doomscrollMillis > 0;
          final ratio = (d.doomscrollMillis / maxMillis).clamp(0.0, 1.0);
          final barHeight = (ratio * 46).clamp(3.0, 46.0);

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (hasVal)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        d.doomscrollFormatted,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: orangeAccent,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 11),
                  const SizedBox(height: 2),
                  Container(
                    width: double.infinity,
                    height: hasVal ? barHeight : 2.5,
                    decoration: BoxDecoration(
                      color: hasVal ? orangeAccent : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      d.shortDayName,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: hasVal ? FontWeight.w700 : FontWeight.w500,
                        color: hasVal
                            ? AppColors.navy
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Grafik Scrolling Bulanan: Minggu 1 .. 5 (Bar Vertikal Orange Minimalis)
  Widget _buildDoomscrollMonthlyChart() {
    final weeks = controller.monthlyWeeks;
    if (weeks.isEmpty) return const SizedBox.shrink();

    final maxMillis = weeks.fold<int>(
      1,
      (prev, w) => max(prev, w.doomscrollMillis),
    );

    return SizedBox(
      height: 74,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: weeks.map((w) {
          final hasVal = w.doomscrollMillis > 0;
          final ratio = (w.doomscrollMillis / maxMillis).clamp(0.0, 1.0);
          final barHeight = (ratio * 46).clamp(3.0, 46.0);

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (hasVal)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        w.doomscrollFormatted,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: orangeAccent,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 11),
                  const SizedBox(height: 2),
                  Container(
                    width: double.infinity,
                    height: hasVal ? barHeight : 2.5,
                    decoration: BoxDecoration(
                      color: hasVal ? orangeAccent : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      w.label,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: hasVal ? FontWeight.w700 : FontWeight.w500,
                        color: hasVal
                            ? AppColors.navy
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ===========================================================================
  // 5. CARD TOTAL SCREEN TIME (AKSEN MINT / TEAL)
  // ===========================================================================
  Widget _buildScreenTimeCard() {
    return Obx(() {
      final totalMillis = controller.totalScreenTimeMillis.value;
      final comparison = controller.screenTimeComparison.value;
      final hasData = controller.hasScreenTimeData;
      final segments = controller.dailySegments;

      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cardBorderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card: Ikon stopwatch dalam kotak mint, judul "Total Screen Time"
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: tealBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.timer_outlined,
                    size: 20,
                    color: tealAccent,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Total Screen Time',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (!hasData) ...[
              _buildCleanEmptyState(
                message: 'Belum ada data',
                icon: Icons.timer_outlined,
              ),
            ] else ...[
              // Durasi Total Besar & Chip Perbandingan Ringkas
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      DurationFormatter.format(totalMillis),
                      key: const Key('text_screen_time_total'),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppColors.navy,
                        letterSpacing: -0.6,
                      ),
                    ),
                  ),
                  if (comparison.isNotEmpty &&
                      comparison != 'Data sama dengan kemarin') ...[
                    const SizedBox(width: 10),
                    Flexible(child: _buildComparisonChip(comparison)),
                  ],
                ],
              ),
              const SizedBox(height: 14),

              // Divider Halus
              const Divider(color: Color(0xFFF1F5F9), height: 1),
              const SizedBox(height: 12),

              // Distribusi Waktu Penggunaan: Bar Horizontal Minimalis (Dini Hari, Pagi, Siang, Sore, Malam)
              if (segments.isNotEmpty)
                _buildScreenTimeHorizontalDistribution(segments)
              else
                const SizedBox.shrink(),
            ],
          ],
        ),
      );
    });
  }

  /// Distribusi Screen Time: Bar Horizontal Minimalis (Dini Hari, Pagi, Siang, Sore, Malam)
  Widget _buildScreenTimeHorizontalDistribution(
    List<TimeSegmentUsage> segments,
  ) {
    final maxMillis = segments.fold<int>(
      1,
      (prev, s) => max(prev, s.screenTimeMillis),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(segments.length, (index) {
        final seg = segments[index];
        final hasVal = seg.screenTimeMillis > 0;
        final ratio = (seg.screenTimeMillis / maxMillis).clamp(0.0, 1.0);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              SizedBox(
                width: 68,
                child: Text(
                  seg.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: hasVal ? FontWeight.w700 : FontWeight.w500,
                    color: hasVal ? AppColors.navy : AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: hasVal
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 6,
                          backgroundColor: const Color(0xFFF1F5F9),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            tealAccent,
                          ),
                        ),
                      )
                    : Container(
                        height: 2,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 44,
                child: Text(
                  hasVal ? seg.screenTimeFormatted : '—',
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: hasVal ? FontWeight.w700 : FontWeight.w500,
                    color: hasVal ? AppColors.navy : const Color(0xFF94A3B8),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  /// Chip Perbandingan Singkat: "Naik 23m" atau "Turun 12m"
  Widget _buildComparisonChip(String comparison) {
    final isIncrease =
        comparison.contains('Naik') || comparison.startsWith('+');
    final isDecrease =
        comparison.contains('Turun') || comparison.startsWith('-');

    String shortText = comparison;
    if (comparison.contains('dibanding')) {
      shortText = comparison.split('dibanding').first.trim();
    }

    final chipColor = isIncrease
        ? const Color(0xFFFEF2F2)
        : (isDecrease ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9));
    final textColor = isIncrease
        ? const Color(0xFFDC2626)
        : (isDecrease ? const Color(0xFF059669) : AppColors.textSecondary);
    final iconData = isIncrease
        ? Icons.trending_up_rounded
        : (isDecrease ? Icons.trending_down_rounded : Icons.remove_rounded);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, size: 12, color: textColor),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              shortText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 6. CARD PENGGUNAAN APLIKASI (TOP 5)
  // ===========================================================================
  Widget _buildAppUsageCard() {
    return Obx(() {
      final apps = controller.topApps.take(5).toList();
      final hasApps = apps.isNotEmpty;

      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cardBorderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE9FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.apps_rounded,
                    size: 20,
                    color: Color(0xFF7C3AED),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Penggunaan Aplikasi',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (!hasApps) ...[
              _buildCleanEmptyState(
                message: 'Belum ada data',
                icon: Icons.apps_rounded,
              ),
            ] else ...[
              // Setiap baris: Ikon native, nama aplikasi, & durasi ringkas
              ...apps.map((app) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      _buildNativeAppIcon(
                        packageName: app.packageName,
                        appName: app.appName,
                        size: 32,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          app.appName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navy,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        DurationFormatter.format(app.usageMillis),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      );
    });
  }

  // ===========================================================================
  // 7. CARD MONITORING MATA
  // ===========================================================================
  Widget _buildEyeMonitoringCard() {
    return Obx(() {
      final summary = controller.eyeSummary.value;
      final hasData = summary.hasData;
      final sensorStatus = controller.cameraSensorStatusText;

      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cardBorderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Ikon mata, judul "Monitoring Mata", badge "Aktif" / "Belum Aktif"
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.visibility_rounded,
                    size: 20,
                    color: Color(0xFF0284C7),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Monitoring Mata',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                _buildBadge(
                  text: hasData ? 'Aktif' : 'Belum Aktif',
                  bgColor: hasData
                      ? const Color(0xFFE0F2FE)
                      : const Color(0xFFF1F5F9),
                  textColor: hasData
                      ? const Color(0xFF0369A1)
                      : AppColors.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (!hasData) ...[
              _buildCleanEmptyState(
                message: 'Belum ada data',
                icon: Icons.visibility_outlined,
              ),
            ] else ...[
              // Grid Responsif 5 Statistik: Sesi, Durasi, Rata-rata EAR, Kedipan, Terpejam
              LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 320;

                  final statSesi = _buildMetricTile(
                    label: 'Sesi',
                    value: '${summary.totalSessions}',
                  );
                  final statDurasi = _buildMetricTile(
                    label: 'Durasi',
                    value: summary.durationFormatted,
                  );
                  final statEar = _buildMetricTile(
                    label: 'Rata-rata EAR',
                    value: summary.averageEar != null
                        ? summary.averageEar!.toStringAsFixed(2)
                        : '-',
                  );
                  final statKedipan = _buildMetricTile(
                    label: 'Kedipan',
                    value: '${summary.blinkCount}',
                  );
                  final statTerpejam = _buildMetricTile(
                    label: 'Terpejam',
                    value: '${summary.eyeClosureEvents}',
                  );

                  if (isCompact) {
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: statSesi),
                            const SizedBox(width: 8),
                            Expanded(child: statDurasi),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: statEar),
                            const SizedBox(width: 8),
                            Expanded(child: statKedipan),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(children: [Expanded(child: statTerpejam)]),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: statSesi),
                          const SizedBox(width: 8),
                          Expanded(child: statDurasi),
                          const SizedBox(width: 8),
                          Expanded(child: statEar),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: statKedipan),
                          const SizedBox(width: 8),
                          Expanded(child: statTerpejam),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
            const SizedBox(height: 12),

            // Status Sensor Kamera Terpisah & Ringkas
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: cardBorderColor, width: 1),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.videocam_outlined,
                    size: 15,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: 'Status Sensor: ',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                        children: [
                          TextSpan(
                            text: sensorStatus,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: sensorStatus == 'Sensor Aktif'
                                  ? const Color(0xFF059669)
                                  : (sensorStatus == 'Sensor Standby'
                                        ? tealAccent
                                        : AppColors.navy),
                            ),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  // ===========================================================================
  // 8. MODUL MONITORING (AKSES CEPAT RINGKAS)
  // ===========================================================================
  Widget _buildQuickLinksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Modul Monitoring',
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 8),
        _buildQuickLinkItem(
          title: 'Screen Time & Aplikasi',
          icon: Icons.timer_outlined,
          route: Routes.screenTime,
        ),
        const SizedBox(height: 6),
        _buildQuickLinkItem(
          title: 'Pola Scrolling & Doomscrolling',
          icon: Icons.swap_vert_rounded,
          route: Routes.doomscrolling,
        ),
        const SizedBox(height: 6),
        _buildQuickLinkItem(
          title: 'Monitoring Mata & EAR',
          icon: Icons.visibility_outlined,
          route: Routes.eyeMonitoring,
        ),
      ],
    );
  }

  Widget _buildQuickLinkItem({
    required String title,
    required IconData icon,
    required String route,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorderColor, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Get.toNamed(route),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: tealBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppColors.navy, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // REUSABLE HELPER WIDGETS
  // ===========================================================================

  Widget _buildMetricTile({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cardBorderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubMetricTile({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cardBorderColor, width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge({
    required String text,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildCleanEmptyState({
    required String message,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorderColor, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: const Color(0xFFCBD5E1)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNativeAppIcon({
    required String packageName,
    required String appName,
    double size = 32,
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
                  color: AppColors.navy.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
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
                    _buildFallbackAppIcon(appName, size),
              ),
            ),
          );
        }
        return _buildFallbackAppIcon(appName, size);
      },
    );
  }

  Widget _buildFallbackAppIcon(String appName, double size) {
    final lower = appName.toLowerCase();
    Color bgColor;
    Color iconColor;
    IconData iconData;

    if (lower.contains('tiktok')) {
      bgColor = const Color(0xFF000000);
      iconColor = const Color(0xFF00D9EC);
      iconData = Icons.play_arrow_rounded;
    } else if (lower.contains('instagram')) {
      bgColor = const Color(0xFFE1306C);
      iconColor = Colors.white;
      iconData = Icons.camera_alt_rounded;
    } else if (lower.contains('youtube')) {
      bgColor = const Color(0xFFFF0000);
      iconColor = Colors.white;
      iconData = Icons.play_circle_filled_rounded;
    } else if (lower.contains('whatsapp')) {
      bgColor = const Color(0xFF25D366);
      iconColor = Colors.white;
      iconData = Icons.chat_rounded;
    } else if (lower.contains('chrome') || lower.contains('browser')) {
      bgColor = const Color(0xFF4285F4);
      iconColor = Colors.white;
      iconData = Icons.language_rounded;
    } else {
      bgColor = tealBg;
      iconColor = AppColors.navy;
      iconData = Icons.smartphone_rounded;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      alignment: Alignment.center,
      child: Icon(iconData, size: size * 0.52, color: iconColor),
    );
  }
}
