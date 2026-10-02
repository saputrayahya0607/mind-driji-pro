import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_bottom_navigation.dart';
import '../../../data/models/insight_model.dart';
import '../../../data/models/intervention_model.dart';
import '../../../data/models/monitoring_visualization_model.dart';
import '../../../data/models/recommendation_model.dart';
import '../../../routes/app_routes.dart';
import '../controllers/insight_controller.dart';

class InsightView extends GetView<InsightController> {
  const InsightView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Insight & Refleksi',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: false,
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.card,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: const Icon(
                Icons.refresh_rounded,
                size: 18,
                color: AppColors.secondary,
              ),
            ),
            onPressed: () => controller.loadInsights(),
            tooltip: 'Segarkan',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildPeriodSelector(),
          _buildDateNavigator(),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return _buildLoadingState();
              }
              if (!controller.hasInsights && !controller.hasRecommendations) {
                return _buildEmptyState();
              }
              return _buildInsightContent();
            }),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavigation(currentIndex: 2),
    );
  }

  // ===========================================================================
  // 1. PERIOD SELECTOR TABS: [ Hari ] [ Minggu ] [ Bulan ]
  // ===========================================================================
  Widget _buildPeriodSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Obx(() {
        final current = controller.selectedPeriod.value;
        return Row(
          children: [
            _buildPeriodTab('Hari', MonitoringPeriod.daily, current),
            _buildPeriodTab('Minggu', MonitoringPeriod.weekly, current),
            _buildPeriodTab('Bulan', MonitoringPeriod.monthly, current),
          ],
        );
      }),
    );
  }

  Widget _buildPeriodTab(
    String label,
    MonitoringPeriod period,
    MonitoringPeriod selected,
  ) {
    final isSelected = period == selected;
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.setPeriod(period),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 2. DATE NAVIGATOR: ‹  Label  ›
  // ===========================================================================
  Widget _buildDateNavigator() {
    return Obx(() {
      final canGoNext = controller.canGoNext;
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded, size: 24),
              color: AppColors.secondary,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: () => controller.previousPeriod(),
              tooltip: 'Periode Sebelumnya',
            ),
            Expanded(
              child: Text(
                controller.dateRangeLabel,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded, size: 24),
              color: canGoNext
                  ? AppColors.secondary
                  : AppColors.textSecondary.withValues(alpha: 0.2),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: canGoNext ? () => controller.nextPeriod() : null,
              tooltip: 'Periode Berikutnya',
            ),
          ],
        ),
      );
    });
  }

  // ===========================================================================
  // 3. INSIGHT CONTENT
  // ===========================================================================
  Widget _buildInsightContent() {
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.card,
      onRefresh: () => controller.loadInsights(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          if (controller.featuredInsight != null) ...[
            _buildFeaturedInsightCard(controller.featuredInsight!),
            const SizedBox(height: 16),
          ],
          ...controller.secondaryInsights.map((insight) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _buildSecondaryInsightCard(insight),
            );
          }),
          if (controller.hasRecommendations) ...[
            const SizedBox(height: 12),
            _buildRecommendationsSection(controller.recommendations),
          ],
          Obx(() {
            final latest = controller.latestIntervention.value;
            if (latest == null) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildLatestInterventionCard(latest),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLatestInterventionCard(InterventionModel item) {
    final isCompleted = item.status == InterventionStatus.completed;
    final statusText = isCompleted
        ? 'Selesai'
        : (item.status == InterventionStatus.cancelled ? 'Dibatalkan' : 'Aktif');
    final statusBg = isCompleted
        ? const Color(0xFFDCFCE7)
        : const Color(0xFFF3F4F6);
    final statusColor = isCompleted
        ? const Color(0xFF15803D)
        : const Color(0xFF4B5563);

    IconData icon;
    Color iconColor;
    if (item.type == InterventionType.eyeRelaxation) {
      icon = Icons.visibility_rounded;
      iconColor = const Color(0xFF0EA5E9);
    } else if (item.type == InterventionType.focusMode) {
      icon = Icons.center_focus_strong_rounded;
      iconColor = const Color(0xFFF59E0B);
    } else {
      icon = Icons.spa_rounded;
      iconColor = const Color(0xFF10B981);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Intervensi Terbaru',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () => Get.toNamed(Routes.interventionHistory),
                child: const Text(
                  'Lihat Semua →',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.durationMinutes} menit',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 4. FEATURED INSIGHT CARD (Utama / Paling Relevan)
  // ===========================================================================
  Widget _buildFeaturedInsightCard(InsightModel insight) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 16,
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
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F8F5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _getTypeBadge(insight.type),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      insight.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            insight.summary,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            insight.details,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          if (insight.hasEvidences) ...[
            const SizedBox(height: 16),
            _buildEvidenceGrid(insight.evidences),
          ],
          if (insight.hasRelatedApps) ...[
            const SizedBox(height: 14),
            _buildRelatedAppsChips(insight.relatedApps),
          ],
          if (insight.hasSuggestedAction) ...[
            const SizedBox(height: 16),
            _buildSuggestedActionBanner(insight.suggestedAction!),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // 5. SECONDARY INSIGHT CARD (Kartu Tambahan)
  // ===========================================================================
  Widget _buildSecondaryInsightCard(InsightModel insight) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getTypeIcon(insight.type),
                size: 20,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  insight.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            insight.summary,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          if (insight.hasEvidences) ...[
            const SizedBox(height: 12),
            _buildEvidenceGrid(insight.evidences),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // 6. EVIDENCE GRID: KARTU NILAI BUKTI TERUKUR (Angka + Ikon)
  // ===========================================================================
  Widget _buildEvidenceGrid(List<InsightEvidenceItem> evidences) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: evidences.map((e) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 0.8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                e.label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                e.value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ===========================================================================
  // 7. RELATED APPS CHIPS
  // ===========================================================================
  Widget _buildRelatedAppsChips(List<String> apps) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'Aplikasi:',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Wrap(
            spacing: 6,
            children: apps.map((app) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  app,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondary,
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
  // 8. SUGGESTED ACTION BANNER (Intervensi Pilihan Pengguna)
  // ===========================================================================
  Widget _buildSuggestedActionBanner(String action) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F8F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lightbulb_rounded,
            size: 20,
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Saran Tindakan',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  action,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _showActionDialog(action),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Lihat Pilihan',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Dialog konfirmasi tindakan pengguna (User Choice - Tidak auto-start)
  void _showActionDialog(String action) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.self_improvement_rounded,
                color: AppColors.primary, size: 24),
            const SizedBox(width: 10),
            Text(
              action,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          'Pilihan intervensi $action dirancang untuk membantumu mengambil '
          'jeda sadar dan mengistirahatkan mata. Apakah kamu ingin mencatat '
          'pilihan ini sebagai pengingat pribadimu?',
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'Nanti Saja',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              controller.selectAction(action);
              Get.back();
              Get.snackbar(
                'Tindakan Dicatat',
                'Pilihan $action telah tersimpan.',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: AppColors.card,
                colorText: AppColors.textPrimary,
                margin: const EdgeInsets.all(16),
                borderRadius: 12,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Simpan Pilihan'),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 8B. RECOMMENDATIONS SECTION (Pilihan Untukmu)
  // ===========================================================================
  Widget _buildRecommendationsSection(List<RecommendationModel> recommendations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 16,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'PILIHAN UNTUKMU',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Pilihan intervensi yang dirancang untuk membantumu mengambil kendali secara mandiri.',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        ...recommendations.map((rec) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _buildRecommendationCard(rec),
            )),
      ],
    );
  }

  Widget _buildRecommendationCard(RecommendationModel rec) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getRecommendationIcon(rec.type),
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_getRecommendationEmoji(rec.type)}${rec.title}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rec.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 15,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    rec.reason,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Pilihan Durasi:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Obx(() {
            final activeDuration = controller.getSelectedDuration(rec);
            return Wrap(
              spacing: 8,
              runSpacing: 6,
              children: rec.durationOptions.map((dur) {
                final isSelected = dur == activeDuration;
                return ChoiceChip(
                  label: Text('$dur menit'),
                  labelStyle: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.card,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.border,
                      width: 1,
                    ),
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      controller.selectRecommendationDuration(rec.id, dur);
                    }
                  },
                );
              }).toList(),
            );
          }),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                final dur = controller.getSelectedDuration(rec);
                _showRecommendationDialog(rec, dur);
              },
              icon: const Icon(Icons.touch_app_rounded, size: 16),
              label: Text(
                rec.actionLabel,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRecommendationDialog(RecommendationModel rec, int duration) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              _getRecommendationIcon(rec.type),
              color: AppColors.primary,
              size: 24,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                rec.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kamu memilih opsi ${rec.title} dengan durasi $duration menit.',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              rec.description,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F8F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pilihan ini disimpan sebagai pengingat sadar pribadimu.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'Nanti Saja',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              controller.applyRecommendation(rec, duration);
              Get.back();
              Get.snackbar(
                'Pilihan Disimpan',
                '${rec.title} ($duration menit) berhasil dicatat.',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: AppColors.card,
                colorText: AppColors.textPrimary,
                margin: const EdgeInsets.all(16),
                borderRadius: 12,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Konfirmasi Pilihan'),
          ),
        ],
      ),
    );
  }

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

  // ===========================================================================
  // 9. LOADING & EMPTY STATES
  // ===========================================================================
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
            'Menyusun insight...',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.card,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: const Icon(
                Icons.lightbulb_outline_rounded,
                size: 30,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum ada data',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Mulai monitoring untuk melihat pola dan insight penggunaanmu.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helpers
  String _getTypeBadge(InsightType type) {
    switch (type) {
      case InsightType.scrolling:
        return 'POLA SCROLLING';
      case InsightType.screenTime:
        return 'WAKTU LAYAR';
      case InsightType.eyeMonitoring:
        return 'MONITORING MATA';
      case InsightType.usagePattern:
        return 'POLA PENGGUNAAN';
      case InsightType.recommendation:
        return 'SARAN TINDAKAN';
    }
  }

  IconData _getTypeIcon(InsightType type) {
    switch (type) {
      case InsightType.scrolling:
        return Icons.swipe_rounded;
      case InsightType.screenTime:
        return Icons.smartphone_rounded;
      case InsightType.eyeMonitoring:
        return Icons.visibility_rounded;
      case InsightType.usagePattern:
        return Icons.insights_rounded;
      case InsightType.recommendation:
        return Icons.tips_and_updates_rounded;
    }
  }
}
