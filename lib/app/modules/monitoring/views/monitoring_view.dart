import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../../core/widgets/app_bottom_navigation.dart';
import '../../../data/models/monitoring_visualization_model.dart';
import '../../../routes/app_routes.dart';
import '../controllers/monitoring_controller.dart';

class MonitoringView extends GetView<MonitoringController> {
  const MonitoringView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Monitoring'),
        centerTitle: true,
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.loadData,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const Text(
                  'Visualisasi Monitoring',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Pantau pola penggunaan layar, scrolling, dan kesehatan mata.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),

                // Periode Tabs: [ Hari ] [ Minggu ] [ Bulan ]
                _buildPeriodTabs(),
                const SizedBox(height: 14),

                // Date Navigation Bar: ‹ 29 Sep 2026 ›
                _buildDateNavigationBar(),
                const SizedBox(height: 18),

                // Loading Indicator Ringan
                Obx(() {
                  if (controller.isLoading.value) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }),

                // 1. Screen Time Summary Card & Chart
                _buildScreenTimeCard(),
                const SizedBox(height: 16),

                // 2. App Usage Card (Top 5 Apps)
                _buildAppUsageCard(),
                const SizedBox(height: 16),

                // 3. Doomscrolling Card ("Pola Scrolling")
                _buildDoomscrollCard(),
                const SizedBox(height: 16),

                // 4. Eye Monitoring Card ("Monitoring Mata")
                _buildEyeMonitoringCard(),
                const SizedBox(height: 20),

                // 5. Quick Links ke Modul Monitoring Detail
                _buildQuickLinksSection(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavigation(currentIndex: 1),
    );
  }

  // ===========================================================================
  // PERIOD TABS: [ Hari ] [ Minggu ] [ Bulan ]
  // ===========================================================================
  Widget _buildPeriodTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Obx(() {
        final current = controller.selectedPeriod.value;
        return Row(
          children: [
            _buildTabButton('Hari', MonitoringPeriod.daily, current),
            _buildTabButton('Minggu', MonitoringPeriod.weekly, current),
            _buildTabButton('Bulan', MonitoringPeriod.monthly, current),
          ],
        );
      }),
    );
  }

  Widget _buildTabButton(
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
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.card : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // DATE NAVIGATION: ‹ 29 Sep 2026 ›
  // ===========================================================================
  Widget _buildDateNavigationBar() {
    return Obx(() {
      final label = controller.dateRangeLabel;
      final isDaily = controller.selectedPeriod.value == MonitoringPeriod.daily;
      final subtitle = isDaily ? controller.dailySubtitle : null;
      final canNext = controller.canGoNext;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              key: const Key('btn_prev_date'),
              icon: const Icon(Icons.chevron_left_rounded, size: 26),
              color: AppColors.textPrimary,
              onPressed: controller.goToPreviousPeriod,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
            Column(
              children: [
                Text(
                  label,
                  key: const Key('text_date_label'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
            IconButton(
              key: const Key('btn_next_date'),
              icon: Icon(
                Icons.chevron_right_rounded,
                size: 26,
                color: canNext
                    ? AppColors.textPrimary
                    : AppColors.textSecondary.withValues(alpha: 0.3),
              ),
              onPressed: canNext ? controller.goToNextPeriod : null,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ],
        ),
      );
    });
  }

  // ===========================================================================
  // 1. SCREEN TIME CARD & CHARTS
  // ===========================================================================
  Widget _buildScreenTimeCard() {
    return Obx(() {
      final totalMillis = controller.totalScreenTimeMillis.value;
      final comparison = controller.screenTimeComparison.value;
      final hasData = controller.hasScreenTimeData;
      final period = controller.selectedPeriod.value;

      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondary.withValues(alpha: 0.02),
              blurRadius: 10,
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
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.timer_outlined,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Total Screen Time',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (!hasData) ...[
              _buildEmptyState(
                message: 'Belum ada data',
                subMessage: 'Mulai monitoring untuk melihat pola penggunaanmu.',
              ),
            ] else ...[
              Text(
                DurationFormatter.format(totalMillis),
                key: const Key('text_screen_time_total'),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              if (comparison.isNotEmpty) ...[
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Text(
                    comparison,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Visualisasi Chart sesuai periode
              if (period == MonitoringPeriod.daily)
                _buildDailySegmentationChart()
              else if (period == MonitoringPeriod.weekly)
                _buildWeeklyBarChart()
              else
                _buildMonthlyBarChart(),
            ],
          ],
        ),
      );
    });
  }

  // Daily Chart: Dini Hari, Pagi, Siang, Sore, Malam
  Widget _buildDailySegmentationChart() {
    final segments = controller.dailySegments;
    if (segments.isEmpty) return const SizedBox.shrink();

    final maxMillis = segments.fold<int>(
      1,
      (prev, s) => max(prev, s.screenTimeMillis),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Distribusi Waktu Layar',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...segments.map((seg) {
          final ratio = seg.screenTimeMillis / maxMillis;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      seg.label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      seg.screenTimeFormatted,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: seg.screenTimeMillis > 0
                            ? AppColors.primary
                            : AppColors.textSecondary.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ratio.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: AppColors.background,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      seg.screenTimeMillis > 0
                          ? AppColors.primary
                          : const Color(0xFFCBD5E1),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // Weekly Chart: Sen, Sel, Rab, Kam, Jum, Sab, Min
  Widget _buildWeeklyBarChart() {
    final days = controller.weeklyDays;
    if (days.isEmpty) return const SizedBox.shrink();

    final maxMillis = days.fold<int>(
      1,
      (prev, d) => max(prev, d.screenTimeMillis),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Waktu Layar Harian (Senin – Minggu)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 130,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: days.map((day) {
              final ratio = (day.screenTimeMillis / maxMillis).clamp(0.0, 1.0);
              final barHeight = (ratio * 90).clamp(4.0, 90.0);
              final hasVal = day.screenTimeMillis > 0;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (hasVal)
                        Text(
                          day.screenTimeFormatted,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      else
                        const SizedBox(height: 12),
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        height: barHeight,
                        decoration: BoxDecoration(
                          color: hasVal
                              ? AppColors.primary
                              : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        day.shortDayName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: hasVal ? FontWeight.w700 : FontWeight.w500,
                          color: hasVal
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // Monthly Chart: Week 1 .. Week 5
  Widget _buildMonthlyBarChart() {
    final weeks = controller.monthlyWeeks;
    if (weeks.isEmpty) return const SizedBox.shrink();

    final maxMillis = weeks.fold<int>(
      1,
      (prev, w) => max(prev, w.screenTimeMillis),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Waktu Layar Mingguan',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 130,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: weeks.map((w) {
              final ratio = (w.screenTimeMillis / maxMillis).clamp(0.0, 1.0);
              final barHeight = (ratio * 90).clamp(4.0, 90.0);
              final hasVal = w.screenTimeMillis > 0;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (hasVal)
                        Text(
                          w.screenTimeFormatted,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      else
                        const SizedBox(height: 12),
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        height: barHeight,
                        decoration: BoxDecoration(
                          color: hasVal
                              ? AppColors.primary
                              : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        w.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: hasVal ? FontWeight.w700 : FontWeight.w500,
                          color: hasVal
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 2. APP USAGE CARD (Top 5 Apps)
  // ===========================================================================
  Widget _buildAppUsageCard() {
    return Obx(() {
      final apps = controller.topApps;
      final hasApps = apps.isNotEmpty;

      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondary.withValues(alpha: 0.02),
              blurRadius: 10,
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
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.apps_rounded,
                    size: 20,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Penggunaan Aplikasi',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (!hasApps) ...[
              _buildEmptyState(
                message: 'Belum ada data penggunaan aplikasi.',
                subMessage: 'Aplikasi yang Anda gunakan akan tercatat otomatis.',
              ),
            ] else ...[
              ...apps.map((app) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border, width: 1),
                        ),
                        child: Center(
                          child: Text(
                            app.appName.isNotEmpty
                                ? app.appName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          app.appName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        DurationFormatter.format(app.usageMillis),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
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
  // 3. DOOMSCROLLING CARD ("Pola Scrolling")
  // ===========================================================================
  Widget _buildDoomscrollCard() {
    return Obx(() {
      final summary = controller.doomscrollSummary.value;
      final hasData = summary.hasData;
      final period = controller.selectedPeriod.value;

      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondary.withValues(alpha: 0.02),
              blurRadius: 10,
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
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.swipe_vertical_rounded,
                    size: 20,
                    color: Color(0xFFD97706),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Pola Scrolling',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (!hasData) ...[
              _buildEmptyState(
                message: 'Belum ada data scrolling pada periode ini.',
                subMessage:
                    'Deteksi pola scrolling otomatis aktif saat Anda membuka media sosial.',
              ),
            ] else ...[
              // Grid Metrik Perilaku Real
              Row(
                children: [
                  _buildMetricBox('Total Sesi', '${summary.totalSessions} sesi'),
                  const SizedBox(width: 10),
                  _buildMetricBox('Total Durasi', summary.durationFormatted),
                  const SizedBox(width: 10),
                  _buildMetricBox('Total Scroll', '${summary.totalSwipes} kali'),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildMetricBox(
                    'Scroll Bawah (Next)',
                    '${summary.downwardSwipes} kali',
                  ),
                  const SizedBox(width: 10),
                  _buildMetricBox(
                    'Scroll Atas (Back)',
                    '${summary.upwardSwipes} kali',
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Doomscrolling Chart
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

  Widget _buildDoomscrollDailyChart() {
    final segments = controller.dailySegments;
    final maxMillis = segments.fold<int>(
      1,
      (prev, s) => max(prev, s.doomscrollMillis),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Waktu Scrolling per Segmen',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        ...segments.map((seg) {
          final ratio = (seg.doomscrollMillis / maxMillis).clamp(0.0, 1.0);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 70,
                  child: Text(
                    seg.label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 6,
                      backgroundColor: AppColors.background,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFD97706),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 50,
                  child: Text(
                    seg.doomscrollFormatted,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFD97706),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDoomscrollWeeklyChart() {
    final days = controller.weeklyDays;
    final maxMillis = days.fold<int>(
      1,
      (prev, d) => max(prev, d.doomscrollMillis),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Durasi Scrolling per Hari',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 90,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: days.map((d) {
              final ratio = (d.doomscrollMillis / maxMillis).clamp(0.0, 1.0);
              final barHeight = (ratio * 60).clamp(4.0, 60.0);
              final hasVal = d.doomscrollMillis > 0;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: double.infinity,
                        height: barHeight,
                        decoration: BoxDecoration(
                          color: hasVal
                              ? const Color(0xFFD97706)
                              : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        d.shortDayName,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDoomscrollMonthlyChart() {
    final weeks = controller.monthlyWeeks;
    final maxMillis = weeks.fold<int>(
      1,
      (prev, w) => max(prev, w.doomscrollMillis),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Durasi Scrolling per Minggu',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 90,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: weeks.map((w) {
              final ratio = (w.doomscrollMillis / maxMillis).clamp(0.0, 1.0);
              final barHeight = (ratio * 60).clamp(4.0, 60.0);
              final hasVal = w.doomscrollMillis > 0;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: double.infinity,
                        height: barHeight,
                        decoration: BoxDecoration(
                          color: hasVal
                              ? const Color(0xFFD97706)
                              : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        w.label,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 4. EYE MONITORING CARD ("Monitoring Mata")
  // ===========================================================================
  Widget _buildEyeMonitoringCard() {
    return Obx(() {
      final summary = controller.eyeSummary.value;
      final hasData = summary.hasData;

      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondary.withValues(alpha: 0.02),
              blurRadius: 10,
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
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.visibility_outlined,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Monitoring Mata',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (!hasData) ...[
              _buildEmptyState(
                message: 'Belum ada data monitoring mata pada periode ini.',
                subMessage:
                    'Kamera akan memantau kedipan secara berkala saat monitoring diaktifkan.',
              ),
            ] else ...[
              // Grid Data Monitoring Mata
              Row(
                children: [
                  _buildMetricBox('Jumlah Sesi', '${summary.totalSessions} sesi'),
                  const SizedBox(width: 10),
                  _buildMetricBox('Total Durasi', summary.durationFormatted),
                  const SizedBox(width: 10),
                  _buildMetricBox(
                    'Rata-rata EAR',
                    summary.averageEar != null
                        ? summary.averageEar!.toStringAsFixed(2)
                        : '-',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildMetricBox(
                    'Indikasi Mata Terpejam',
                    '${summary.eyeClosureEvents} kali',
                  ),
                  const SizedBox(width: 10),
                  _buildMetricBox(
                    'Total Kedipan',
                    '${summary.blinkCount} kedipan',
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    });
  }

  // ===========================================================================
  // 5. QUICK LINKS KE MODUL DETAIL
  // ===========================================================================
  Widget _buildQuickLinksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detail Modul Monitoring',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        _buildQuickLinkTile(
          title: 'Screen Time & Penggunaan Aplikasi',
          subtitle: 'Lihat rincian lengkap seluruh aplikasi hari ini',
          icon: Icons.timer_outlined,
          onTap: () => Get.toNamed(Routes.screenTime),
        ),
        const SizedBox(height: 8),
        _buildQuickLinkTile(
          title: 'Pola Scrolling & Doomscrolling',
          subtitle: 'Lihat live session dan riwayat scrolling',
          icon: Icons.swipe_vertical_rounded,
          onTap: () => Get.toNamed(Routes.doomscrolling),
        ),
        const SizedBox(height: 8),
        _buildQuickLinkTile(
          title: 'Pemantauan Kondisi Mata',
          subtitle: 'Kontrol monitoring kamera dan analisis EAR',
          icon: Icons.visibility_outlined,
          onTap: () => Get.toNamed(Routes.eyeMonitoring),
        ),
      ],
    );
  }

  Widget _buildQuickLinkTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: ListTile(
        onTap: onTap,
        dense: true,
        leading: Icon(icon, color: AppColors.primary, size: 22),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  // ===========================================================================
  // REUSABLE HELPER WIDGETS
  // ===========================================================================
  Widget _buildMetricBox(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required String message,
    required String subMessage,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subMessage,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
