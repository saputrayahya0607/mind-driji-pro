import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/stitch_widgets.dart';
import '../../../data/models/intervention_model.dart';
import '../controllers/intervention_history_controller.dart';

class InterventionHistoryView extends GetView<InterventionHistoryController> {
  const InterventionHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Riwayat Intervensi',
          style: TextStyle(
            color: AppColors.navy,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: false,
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(
                side: BorderSide(color: Color(0xFFE2E8F0)),
              ),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Get.back(),
                child: const SizedBox(
                  width: 38,
                  height: 38,
                  child: Icon(Icons.arrow_back_rounded, color: AppColors.navy, size: 20),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.historyList.isEmpty) {
          return const Center(
            child: MindDrijiLoader(
              size: 72,
              message: 'Memuat riwayat intervensi...',
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.teal,
          onRefresh: () => controller.loadHistory(),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // Summary Stats Card
              _buildStatsCard(),
              const SizedBox(height: 16),

              // Filter Type Chips
              _buildTypeFilterRow(),
              const SizedBox(height: 12),

              // Filter Date Range Chips
              _buildDateFilterRow(),
              const SizedBox(height: 18),

              // List of Interventions
              if (controller.historyList.isEmpty)
                _buildEmptyState()
              else ...[
                ...controller.historyList.map(_buildHistoryCard),
                const SizedBox(height: 12),
                if (controller.hasMore.value &&
                    controller.selectedDateFilter.value == HistoryDateFilter.all)
                  Center(
                    child: SizedBox(
                      height: 48,
                      child: TextButton.icon(
                        onPressed: () => controller.loadMore(),
                        icon: const Icon(Icons.expand_more, size: 20),
                        label: const Text('Lihat Lebih Banyak'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.teal,
                          textStyle: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStatsCard() {
    final stats = controller.statistics.value;
    if (stats == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.04),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.softMint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.bar_chart_rounded, color: AppColors.teal, size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Ringkasan Intervensi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _buildStatItem('Total', '${stats.totalCount}', AppColors.navy),
              _buildStatItem('Selesai', '${stats.completedCount}', AppColors.teal),
              _buildStatItem('Dibatalkan', '${stats.cancelledCount}', const Color(0xFFE65100)),
              _buildStatItem('Durasi', '${stats.totalDurationMinutes}m', AppColors.cyan),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, [Color valueColor = AppColors.teal]) {
    return Expanded(
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: valueColor,
                letterSpacing: -0.4,
              ),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
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

  Widget _buildTypeFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: HistoryTypeFilter.values.map((filter) {
          final isSelected = controller.selectedType.value == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter.label),
              selected: isSelected,
              onSelected: (_) => controller.setTypeFilter(filter),
              selectedColor: AppColors.softMint,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppColors.teal : AppColors.textSecondary,
              ),
              side: BorderSide(
                color: isSelected ? AppColors.teal : const Color(0xFFE2E8F0),
                width: isSelected ? 1.5 : 1.0,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDateFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: HistoryDateFilter.values.map((filter) {
          final isSelected = controller.selectedDateFilter.value == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter.label),
              selected: isSelected,
              onSelected: (_) => controller.setDateFilter(filter),
              selectedColor: AppColors.navy.withValues(alpha: 0.08),
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? AppColors.navy : AppColors.textSecondary,
              ),
              side: BorderSide(
                color: isSelected ? AppColors.navy : const Color(0xFFE2E8F0),
                width: isSelected ? 1.5 : 1.0,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHistoryCard(InterventionModel item) {
    final isCompleted = item.status == InterventionStatus.completed;
    final isCancelled = item.status == InterventionStatus.cancelled;

    final badgeBg = isCompleted
        ? AppColors.softMint
        : (isCancelled ? const Color(0xFFFFECE0) : const Color(0xFFF1F5F9));

    final badgeTextColor = isCompleted
        ? AppColors.teal
        : (isCancelled ? const Color(0xFFD9531E) : AppColors.textSecondary);

    final statusText = isCompleted
        ? 'Selesai'
        : (isCancelled ? 'Dibatalkan' : 'Sedang Aktif');

    final icon = item.type == InterventionType.eyeRelaxation
        ? Icons.remove_red_eye_outlined
        : (item.type == InterventionType.focusMode
            ? Icons.center_focus_strong_rounded
            : Icons.spa_outlined);

    final dateStr =
        '${item.startedAt.day} ${_monthName(item.startedAt.month)} ${item.startedAt.year} · ${item.startedAt.hour.toString().padLeft(2, '0')}:${item.startedAt.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.softMint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.teal, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.durationMinutes} menit · $dateStr',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: badgeTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.softMint.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.history_toggle_off_rounded,
              size: 38,
              color: AppColors.teal,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum Ada Riwayat Intervensi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Riwayat akan otomatis tercatat setiap kali kamu menyelesaikan atau membatalkan sesi jeda.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    if (month >= 1 && month <= 12) return names[month - 1];
    return '';
  }
}
