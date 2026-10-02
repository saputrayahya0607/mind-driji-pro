import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../../data/models/app_usage_model.dart';
import '../controllers/screen_time_controller.dart';

class ScreenTimeView extends GetView<ScreenTimeController> {
  const ScreenTimeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Screen Time'),
        centerTitle: true,
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Get.back(),
          tooltip: 'Kembali',
        ),
        actions: [
          Obx(() {
            final isSyncing = controller.syncManager.isSyncing.value;
            return IconButton(
              icon: isSyncing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : const Icon(
                      Icons.sync_rounded,
                      color: AppColors.textPrimary,
                      size: 22,
                    ),
              tooltip: 'Sinkronisasi Cloud',
              onPressed: isSyncing ? null : () => controller.manualSync(),
            );
          }),
          const SizedBox(width: 8),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
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
                  'Memuat data penggunaan...',
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

        return RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.card,
          onRefresh: () => controller.refreshUsage(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 14),
                _buildSyncStatusBanner(),
                const SizedBox(height: 18),
                if (!controller.hasUsageAccess.value)
                  _buildPermissionRequiredCard()
                else ...[
                  _buildTotalScreenTimeSection(),
                  const SizedBox(height: 24),
                  _buildAppUsageListSection(),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      }),
    );
  }

  /// Banner indikator status sinkronisasi lokal ke Supabase
  Widget _buildSyncStatusBanner() {
    return Obx(() {
      final syncMgr = controller.syncManager;
      final isSyncing = syncMgr.isSyncing.value;
      final isOnline = syncMgr.isOnline.value;
      final pending = syncMgr.pendingCount.value;
      final status = syncMgr.syncStatus.value;

      Color badgeBg;
      Color badgeBorder;
      Color iconColor;
      IconData iconData;
      String statusTitle;
      String statusSubtitle;

      if (isSyncing) {
        badgeBg = const Color(0xFFE6FFFA);
        badgeBorder = const Color(0xFF81E6D9);
        iconColor = AppColors.primary;
        iconData = Icons.sync_rounded;
        statusTitle = 'Menyinkronkan data ke Cloud...';
        statusSubtitle = 'Menghubungkan ke Supabase';
      } else if (!isOnline) {
        badgeBg = const Color(0xFFF1F5F9);
        badgeBorder = const Color(0xFFCBD5E1);
        iconColor = const Color(0xFF64748B);
        iconData = Icons.cloud_off_rounded;
        statusTitle = 'Mode Offline (SQLite Aktif)';
        statusSubtitle = pending > 0
            ? '$pending data tersimpan lokal, siap sync saat online'
            : 'Data tersimpan aman di database lokal';
      } else if (status == 'failed' ||
          (syncMgr.lastError.value != null && pending > 0)) {
        badgeBg = const Color(0xFFFEF2F2);
        badgeBorder = const Color(0xFFFECACA);
        iconColor = const Color(0xFFEF4444);
        iconData = Icons.sync_problem_rounded;
        statusTitle = 'Sinkronisasi Tertunda';
        statusSubtitle = '$pending data tersimpan di SQLite lokal';
      } else if (pending > 0) {
        badgeBg = const Color(0xFFFFFBEB);
        badgeBorder = const Color(0xFFFDE68A);
        iconColor = const Color(0xFFD97706);
        iconData = Icons.cloud_queue_rounded;
        statusTitle = 'Menunggu Sinkronisasi';
        statusSubtitle = '$pending data baru di lokal siap disinkronkan';
      } else {
        badgeBg = const Color(0xFFF0FDF4);
        badgeBorder = const Color(0xFFBBF7D0);
        iconColor = const Color(0xFF16A34A);
        iconData = Icons.cloud_done_rounded;
        statusTitle = 'Tersinkronisasi Penuh';
        statusSubtitle = 'Data lokal & Supabase Cloud telah sinkron';
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: badgeBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: badgeBorder, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: iconColor.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: isSyncing
                  ? Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: iconColor,
                      ),
                    )
                  : Icon(iconData, size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusTitle,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    statusSubtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (!isSyncing && isOnline && pending > 0)
              InkWell(
                onTap: () => controller.manualSync(),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sync, size: 13, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Sync',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  /// Header halaman Screen Time
  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Waktu Layar',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Lihat bagaimana waktu digitalmu digunakan hari ini.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// Kartu permintaan aktivasi izin Usage Access jika belum diberikan
  Widget _buildPermissionRequiredCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_clock_outlined,
              size: 32,
              color: Color(0xFFD97706),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Monitoring penggunaan belum aktif',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'MIND DRIJI membutuhkan akses Usage Access untuk membaca durasi penggunaan aplikasi di perangkat.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => controller.requestUsageAccess(),
              icon: const Icon(Icons.settings_outlined, size: 18),
              label: const Text('Aktifkan Monitoring'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// SECTION 1: Total Screen Time Hari Ini
  Widget _buildTotalScreenTimeSection() {
    final formattedTotal =
        DurationFormatter.format(controller.totalUsageMillis.value);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.03),
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
                  Icons.timer_outlined,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Total Penggunaan',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Hari Ini',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF15803D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            formattedTotal,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Total penggunaan hari ini',
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

  /// SECTION 2 & 3: Daftar Aplikasi yang Digunakan atau Empty State
  Widget _buildAppUsageListSection() {
    final apps = controller.appUsages;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Aplikasi yang Digunakan',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            if (apps.isNotEmpty)
              Text(
                '${apps.length} aplikasi',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (apps.isEmpty)
          _buildEmptyUsageState()
        else
          Container(
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
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: apps.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                thickness: 1,
                color: AppColors.border,
              ),
              itemBuilder: (context, index) {
                final app = apps[index];
                final totalMillis = controller.totalUsageMillis.value;
                final percentage = totalMillis > 0
                    ? (app.usageMillis / totalMillis).clamp(0.0, 1.0)
                    : 0.0;

                return _buildAppUsageTile(app, percentage);
              },
            ),
          ),
      ],
    );
  }

  /// Item baris aplikasi
  Widget _buildAppUsageTile(AppUsageModel app, double percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Icon placeholder konsisten dengan inisial nama aplikasi
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: Text(
                _getAppInitial(app.appName),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Nama Aplikasi & Progress Bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app.appName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage,
                    minHeight: 5,
                    backgroundColor: AppColors.background,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Durasi
          Text(
            DurationFormatter.format(app.usageMillis),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  /// Empty state jika belum ada data penggunaan aplikasi
  Widget _buildEmptyUsageState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.hourglass_empty_rounded,
            size: 40,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 14),
          Text(
            'Belum ada data penggunaan yang tersedia.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Data penggunaan aplikasi akan muncul setelah perangkat mencatat aktivitas.',
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

  String _getAppInitial(String name) {
    if (name.trim().isEmpty) return '?';
    return name.trim()[0].toUpperCase();
  }
}
