import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/intervention_model.dart';
import '../controllers/intervention_history_controller.dart';

class InterventionHistoryView extends GetView<InterventionHistoryController> {
  const InterventionHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Riwayat Intervensi'),
        centerTitle: false,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Kembali',
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.historyList.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
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
                          foregroundColor: AppColors.primary,
                          textStyle: const TextStyle(fontWeight: FontWeight.w600),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Intervensi',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatItem('Total', '${stats.totalCount}'),
              _buildStatItem('Selesai', '${stats.completedCount}'),
              _buildStatItem('Dibatalkan', '${stats.cancelledCount}'),
              _buildStatItem('Durasi', '${stats.totalDurationMinutes}m'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
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
              selectedColor: AppColors.primary.withValues(alpha: 0.14),
              backgroundColor: AppColors.surface,
              labelStyle: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 1.4 : 1.0,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
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
              selectedColor: AppColors.secondary.withValues(alpha: 0.12),
              backgroundColor: AppColors.surface,
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.secondary : AppColors.textSecondary,
              ),
              side: BorderSide(
                color: isSelected ? AppColors.secondary : AppColors.border,
                width: isSelected ? 1.4 : 1.0,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
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

    final badgeColor = isCompleted
        ? AppColors.successContainer
        : (isCancelled ? AppColors.warningContainer : AppColors.border);

    final badgeTextColor = isCompleted
        ? AppColors.onSuccessContainer
        : (isCancelled ? AppColors.onWarningContainer : AppColors.textSecondary);

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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
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
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.durationMinutes} menit · $dateStr',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
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
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.history_toggle_off_outlined,
              size: 40,
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum Ada Riwayat Intervensi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Riwayat akan otomatis tercatat setiap kali kamu menyelesaikan atau membatalkan sesi jeda.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
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
