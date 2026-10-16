import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../../core/widgets/app_bottom_navigation.dart';
import '../../../core/widgets/mind_driji_loader.dart';
import '../../../data/models/intervention_model.dart';
import '../../../data/models/monitoring_visualization_model.dart';
import '../../../data/models/recommendation_model.dart';
import '../../../routes/app_routes.dart';
import '../controllers/insight_controller.dart';

class InsightView extends GetView<InsightController> {
  const InsightView({super.key});

  static const Color pageBgColor = Color(0xFFEAF2F7);
  static const Color navyColor = Color(0xFF0B2030);
  static const Color primaryTeal = Color(0xFF00BFA5);
  static const Color softMint = Color(0xFFDDF4F2);
  static const Color borderColor = Color(0xFFE2E8F0);
  static const Color textMuted = Color(0xFF64748B);

  // 5 Warna Periode Waktu MIND DRIJI (Dini Hari, Pagi, Siang, Sore, Malam)
  static const List<Color> periodColors = [
    Color(0xFF334E68), // Dini Hari (Navy Slate)
    Color(0xFF48CAE4), // Pagi (Soft Cyan)
    Color(0xFF00B4D8), // Siang (Vibrant Cyan)
    Color(0xFF00BFA5), // Sore (Primary Teal)
    Color(0xFF10B981), // Malam (Emerald Green)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBgColor,
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFEAF2F7), Color(0xFFF1F6FA)],
            ),
          ),
          child: RefreshIndicator(
            onRefresh: controller.loadInsights,
            color: primaryTeal,
            backgroundColor: Colors.white,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Judul & Subtitle Insight
                  _buildHeaderTitle(),
                  const SizedBox(height: 14),

                  // 2. Segmented Control Periode: [ Hari ] [ Minggu ] [ Bulan ]
                  _buildPeriodSegmentedControl(),
                  const SizedBox(height: 12),

                  // 3. Navigasi Tanggal Ringkas
                  _buildDateNavigator(),
                  const SizedBox(height: 16),

                  // Indikator Loading
                  Obx(() {
                    if (controller.isLoading.value) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: MindDrijiLoader.compact(
                            size: 32,
                            message: 'Menyusun insight...',
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }),

                  // 4. Card Insight Utama (dengan Bar Chart 5 Periode)
                  _buildMainInsightCard(),
                  const SizedBox(height: 16),

                  // 5. Card Pola Scrolling
                  _buildScrollingPatternCard(),
                  const SizedBox(height: 16),

                  // 6. Card Tren Penggunaan (Line Chart 5 Periode)
                  _buildUsageTrendCard(),
                  const SizedBox(height: 16),

                  // 7. Card Saran untukmu
                  _buildRecommendationsCard(),
                  const SizedBox(height: 16),

                  // 8. Riwayat Intervensi Terbaru (Jika Ada)
                  _buildLatestInterventionSection(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavigation(currentIndex: 2),
    );
  }

  // ===========================================================================
  // 1. APPBAR (Logo MIND DRIJI kiri & Notifikasi kanan)
  // ===========================================================================
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: pageBgColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      leadingWidth: 64,
      leading: Padding(
        padding: const EdgeInsets.only(left: 18),
        child: Center(
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: navyColor.withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              'assets/icons/app_icon.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Image.asset(
                'assets/icons/loader/full_mark.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 18),
          child: Center(
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: navyColor.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  size: 20,
                  color: navyColor,
                ),
                onPressed: () => _showNotificationSheet(context),
                tooltip: 'Notifikasi',
              ),
            ),
          ),
        ),
      ],
    );
  }

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
                      color: primaryTeal,
                      size: 22,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Pemberitahuan Insight',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: navyColor,
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
                    border: Border.all(color: borderColor),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: primaryTeal,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Sistem analisis berjalan normal dan memantau pola penggunaan digitalmu secara aman.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: navyColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // 2. HEADER TITLE & SUBTITLE
  // ===========================================================================
  Widget _buildHeaderTitle() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Insight',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: navyColor,
            letterSpacing: -0.3,
          ),
        ),
        SizedBox(height: 3),
        Text(
          'Kenali pola penggunaan digitalmu',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: textMuted,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 3. SEGMENTED CONTROL: [ Hari ] [ Minggu ] [ Bulan ]
  // ===========================================================================
  Widget _buildPeriodSegmentedControl() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: navyColor.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Obx(() {
        final current = controller.selectedPeriod.value;
        return Row(
          children: [
            _buildTabItem('Hari', MonitoringPeriod.daily, current),
            _buildTabItem('Minggu', MonitoringPeriod.weekly, current),
            _buildTabItem('Bulan', MonitoringPeriod.monthly, current),
          ],
        );
      }),
    );
  }

  Widget _buildTabItem(
    String label,
    MonitoringPeriod period,
    MonitoringPeriod selected,
  ) {
    final isSelected = period == selected;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => controller.setPeriod(period),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: isSelected ? softMint : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? navyColor : textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 4. DATE NAVIGATOR: ‹ Tanggal (Hari Ini) ›
  // ===========================================================================
  Widget _buildDateNavigator() {
    return Obx(() {
      final canGoNext = controller.canGoNext;
      final isToday = controller.isToday;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: navyColor.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded, size: 22),
              color: navyColor,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              onPressed: () => controller.previousPeriod(),
              tooltip: 'Periode Sebelumnya',
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    controller.dateRangeLabel,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: navyColor,
                    ),
                  ),
                  if (isToday) ...[
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: softMint,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Hari Ini',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: primaryTeal,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded, size: 22),
              color: canGoNext ? navyColor : textMuted.withValues(alpha: 0.3),
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              onPressed: canGoNext ? () => controller.nextPeriod() : null,
              tooltip: 'Periode Berikutnya',
            ),
          ],
        ),
      );
    });
  }

  // ===========================================================================
  // 5. CARD INSIGHT UTAMA (dengan Bar Chart 5 Periode Waktu)
  // ===========================================================================
  Widget _buildMainInsightCard() {
    return Obx(() {
      final featured = controller.featuredInsight;
      final isToday = controller.isToday;

      String badgeLabel;
      switch (controller.selectedPeriod.value) {
        case MonitoringPeriod.daily:
          badgeLabel = isToday ? 'Hari Ini' : 'Harian';
          break;
        case MonitoringPeriod.weekly:
          badgeLabel = 'Minggu Ini';
          break;
        case MonitoringPeriod.monthly:
          badgeLabel = 'Bulan Ini';
          break;
      }

      final title = featured?.title ?? 'Pola Penggunaan Terpantau';
      final desc =
          featured?.summary ??
          'Penggunaan perangkatmu terekam stabil. Terus pantau kebiasaan digital secara sadar.';

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: primaryTeal.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Baris: Ikon & Label "Insight Utama" + Badge Periode
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: softMint,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    size: 18,
                    color: primaryTeal,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Insight Utama',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: navyColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3.5,
                  ),
                  decoration: BoxDecoration(
                    color: softMint,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badgeLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: primaryTeal,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Judul Dinamis
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: navyColor,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 6),

            // Deskripsi Singkat
            Text(
              desc,
              style: const TextStyle(
                fontSize: 13,
                color: textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),

            // Grafik Batang Sederhana: Dini Hari, Pagi, Siang, Sore, Malam
            _buildFivePeriodBarChart(),
          ],
        ),
      );
    });
  }

  /// Grafik Batang Sederhana untuk 5 Periode Waktu
  Widget _buildFivePeriodBarChart() {
    return Obx(() {
      final segments = controller.timeSegments;

      // Temukan nilai maksimum durasi untuk normalisasi tinggi batang
      int maxMillis = 0;
      for (final s in segments) {
        if (s.screenTimeMillis > maxMillis) {
          maxMillis = s.screenTimeMillis;
        }
      }
      if (maxMillis == 0) maxMillis = 1;

      final labels = ['Dini Hari', 'Pagi', 'Siang', 'Sore', 'Malam'];

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(labels.length, (index) {
            final seg = segments.firstWhereOrNull(
              (s) => s.label == labels[index],
            );
            final millis = seg?.screenTimeMillis ?? 0;
            final ratio = (millis / maxMillis).clamp(0.06, 1.0);
            final color = periodColors[index % periodColors.length];
            final durationText = millis > 0
                ? DurationFormatter.format(millis)
                : '0m';

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        durationText,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: navyColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Track Batang
                    Container(
                      height: 70,
                      width: 16,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: 70 * ratio,
                        width: 16,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Label Periode
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        labels[index],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      );
    });
  }

  // ===========================================================================
  // 6. CARD POLA SCROLLING
  // ===========================================================================
  Widget _buildScrollingPatternCard() {
    return Obx(() {
      final hasLong = controller.hasLongScrollDetected;
      final hasNight = controller.hasNightScrollDetected;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: navyColor.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Judul & Tombol "Lihat Semua"
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Pola Scrolling',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: navyColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => Get.toNamed(Routes.doomscrolling),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      'Lihat Semua',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: primaryTeal,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Ringkasan 1: Sesi Scrolling Panjang
            if (hasLong) ...[
              _buildScrollingSummaryItem(
                icon: Icons.hourglass_top_rounded,
                iconBg: const Color(0xFFFFF7ED),
                iconColor: const Color(0xFFF59E0B),
                title: 'Sesi scrolling panjang',
                description: controller.longScrollDescription,
                onTap: () => Get.toNamed(Routes.doomscrolling),
              ),
              if (hasNight) const SizedBox(height: 10),
            ],

            // Ringkasan 2: Aktivitas Scrolling Malam
            if (hasNight) ...[
              _buildScrollingSummaryItem(
                icon: Icons.bedtime_rounded,
                iconBg: const Color(0xFFEEF2FF),
                iconColor: const Color(0xFF6366F1),
                title: 'Aktivitas scrolling malam',
                description: controller.nightScrollDescription,
                onTap: () => Get.toNamed(Routes.doomscrolling),
              ),
            ],

            // State Normal jika tidak ada pola berlebih
            if (!hasLong && !hasNight) ...[
              _buildScrollingSummaryItem(
                icon: Icons.check_circle_outline_rounded,
                iconBg: softMint,
                iconColor: primaryTeal,
                title: 'Pola scrolling terjaga',
                description:
                    'Tidak terdeteksi sesi scrolling panjang atau aktivitas malam berlebih pada periode ini.',
                onTap: () => Get.toNamed(Routes.doomscrolling),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildScrollingSummaryItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: iconColor),
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
                      color: navyColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: textMuted,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 7. CARD TREN PENGGUNAAN (Line Chart 5 Periode Waktu)
  // ===========================================================================
  Widget _buildUsageTrendCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: navyColor.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Judul & Tombol "Lihat Detail"
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Tren Penggunaan',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: navyColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () => Get.toNamed(Routes.monitoring),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    'Lihat Detail',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: primaryTeal,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Grafik Garis 5 Periode
          Obx(() {
            final segments = controller.timeSegments;
            return _buildUsageTrendLineChart(segments);
          }),
        ],
      ),
    );
  }

  Widget _buildUsageTrendLineChart(List<TimeSegmentUsage> segments) {
    final labels = ['Dini Hari', 'Pagi', 'Siang', 'Sore', 'Malam'];
    final values = labels.map((lbl) {
      final seg = segments.firstWhereOrNull((s) => s.label == lbl);
      return (seg?.screenTimeMillis ?? 0).toDouble();
    }).toList();

    return Column(
      children: [
        Container(
          height: 110,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: CustomPaint(
            painter: _UsageTrendPainter(
              values: values,
              lineColor: primaryTeal,
              fillColor: primaryTeal.withValues(alpha: 0.12),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(labels.length, (index) {
            final val = values[index].toInt();
            final durText = val > 0 ? DurationFormatter.format(val) : '0m';

            return Expanded(
              child: Column(
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      durText,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: navyColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      labels[index],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  // ===========================================================================
  // 8. CARD SARAN UNTUKMU
  // ===========================================================================
  Widget _buildRecommendationsCard() {
    return Obx(() {
      final recs = controller.recommendations;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: navyColor.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Ikon Lampu + Judul & Tombol "Lihat Semua"
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.lightbulb_rounded,
                    size: 18,
                    color: Color(0xFFD97706),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Saran untukmu',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: navyColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => Get.toNamed(Routes.intervention),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      'Lihat Semua',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: primaryTeal,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Daftar Rekomendasi Aktual
            if (recs.isNotEmpty) ...[
              ...recs
                  .take(2)
                  .map(
                    (rec) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildSingleRecommendationItem(rec),
                    ),
                  ),
            ] else ...[
              // Empty State yang Ramah
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.spa_rounded, size: 28, color: primaryTeal),
                    const SizedBox(height: 8),
                    const Text(
                      'Belum Ada Saran Khusus',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: navyColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Pola penggunaan digitalmu seimbang pada periode ini. Tetap jaga ritme digitalmu!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: textMuted,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => Get.toNamed(Routes.intervention),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryTeal,
                        side: const BorderSide(color: primaryTeal),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        minimumSize: const Size(110, 34),
                      ),
                      child: const Text(
                        'Eksplorasi Jeda',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildSingleRecommendationItem(RecommendationModel rec) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: softMint,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getRecommendationIcon(rec.type),
                  size: 16,
                  color: primaryTeal,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${_getRecommendationEmoji(rec.type)}${rec.title}',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: navyColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            rec.description,
            style: const TextStyle(fontSize: 12, color: textMuted, height: 1.4),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final duration = controller.getSelectedDuration(rec);
                controller.applyRecommendation(rec, duration);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryTeal,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Mulai Jeda',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 9. RIWAYAT INTERVENSI TERBARU
  // ===========================================================================
  Widget _buildLatestInterventionSection() {
    return Obx(() {
      final latest = controller.latestIntervention.value;
      if (latest == null) return const SizedBox.shrink();

      final isCompleted = latest.status == InterventionStatus.completed;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: navyColor.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isCompleted ? softMint : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isCompleted ? Icons.check_circle_rounded : Icons.spa_rounded,
                size: 20,
                color: isCompleted ? primaryTeal : const Color(0xFFD97706),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    latest.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: navyColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${latest.durationMinutes} menit • ${isCompleted ? 'Selesai' : 'Aktif'}',
                    style: const TextStyle(fontSize: 11.5, color: textMuted),
                  ),
                ],
              ),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () => Get.toNamed(Routes.interventionHistory),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  'Riwayat',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: primaryTeal,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================
  IconData _getRecommendationIcon(RecommendationType type) {
    switch (type) {
      case RecommendationType.digitalBreak:
        return Icons.spa_rounded;
      case RecommendationType.focusMode:
        return Icons.center_focus_strong_rounded;
      case RecommendationType.eyeRest:
        return Icons.visibility_off_rounded;
      case RecommendationType.nightReminder:
        return Icons.bedtime_rounded;
      case RecommendationType.usageReflection:
        return Icons.psychology_rounded;
    }
  }

  String _getRecommendationEmoji(RecommendationType type) {
    switch (type) {
      case RecommendationType.digitalBreak:
        return '🌿 ';
      case RecommendationType.focusMode:
        return '🎯 ';
      case RecommendationType.eyeRest:
        return '👁️ ';
      case RecommendationType.nightReminder:
        return '🌙 ';
      case RecommendationType.usageReflection:
        return '🧠 ';
    }
  }
}

// =============================================================================
// CUSTOM PAINTER: LINE CHART TREN PENGGUNAAN 5 PERIODE
// =============================================================================
class _UsageTrendPainter extends CustomPainter {
  final List<double> values;
  final Color lineColor;
  final Color fillColor;

  _UsageTrendPainter({
    required this.values,
    required this.lineColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final paintLine = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final paintFill = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final paintDotOuter = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final paintDotInner = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final paintGrid = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Gambar grid horisontal
    canvas.drawLine(
      Offset(0, size.height * 0.25),
      Offset(size.width, size.height * 0.25),
      paintGrid,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.5),
      Offset(size.width, size.height * 0.5),
      paintGrid,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.75),
      Offset(size.width, size.height * 0.75),
      paintGrid,
    );
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      paintGrid,
    );

    double maxVal = 0;
    for (final v in values) {
      if (v > maxVal) maxVal = v;
    }
    if (maxVal == 0) maxVal = 1;

    final stepX = size.width / (values.length - 1);
    final points = <Offset>[];

    for (int i = 0; i < values.length; i++) {
      final x = i * stepX;
      final normalized = (values[i] / maxVal).clamp(0.0, 1.0);
      final y = size.height - (normalized * (size.height - 18)) - 9;
      points.add(Offset(x, y));
    }

    // Path kurva halus
    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlX1 = p0.dx + (p1.dx - p0.dx) / 2;
      final controlY1 = p0.dy;
      final controlX2 = p0.dx + (p1.dx - p0.dx) / 2;
      final controlY2 = p1.dy;
      path.cubicTo(controlX1, controlY1, controlX2, controlY2, p1.dx, p1.dy);
    }

    // Path area terisi bawah
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, paintFill);
    canvas.drawPath(path, paintLine);

    // Titik data
    for (final p in points) {
      canvas.drawCircle(p, 4.5, paintDotOuter);
      canvas.drawCircle(p, 2.2, paintDotInner);
    }
  }

  @override
  bool shouldRepaint(covariant _UsageTrendPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.fillColor != fillColor;
  }
}
