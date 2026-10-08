import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../controllers/permission_guide_controller.dart';

class PermissionGuideView extends GetView<PermissionGuideController> {
  const PermissionGuideView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Persiapan Monitoring'),
        centerTitle: true,
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Persiapan Monitoring',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Aktifkan izin yang diperlukan agar MIND DRIJI dapat memantau penggunaan digitalmu.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // Summary Card
              _buildSummaryCard(),
              const SizedBox(height: 20),

              const Text(
                'Daftar Izin',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              // 1. Usage Access Card
              Obx(() => _buildPermissionCard(
                    title: 'Akses Penggunaan',
                    description: 'Screen Time & App Usage',
                    icon: Icons.data_usage_rounded,
                    isGranted: controller.usageAccessGranted.value,
                    onAction: controller.requestUsageAccess,
                  )),
              const SizedBox(height: 14),

              // 2. Accessibility Card
              Obx(() => _buildPermissionCard(
                    title: 'Aksesibilitas',
                    description:
                        'Deteksi pola scrolling pada aplikasi yang dipilih',
                    icon: Icons.swipe_vertical_rounded,
                    isGranted: controller.accessibilityGranted.value,
                    onAction: controller.requestAccessibility,
                  )),
              const SizedBox(height: 14),

              // 3. Camera Card
              Obx(() => _buildPermissionCard(
                    title: 'Kamera',
                    description: 'Pemantauan kondisi mata secara berkala',
                    icon: Icons.visibility_outlined,
                    isGranted: controller.cameraGranted.value,
                    onAction: controller.requestCamera,
                  )),
              const SizedBox(height: 14),

              // 4. Notification Card
              Obx(() => _buildPermissionCard(
                    title: 'Notifikasi',
                    description: 'Notifikasi monitoring dan insight',
                    icon: Icons.notifications_active_outlined,
                    isGranted: controller.notificationGranted.value,
                    onAction: controller.requestNotification,
                  )),
              const SizedBox(height: 18),

              // OEM Adaptive Guide Section
              Obx(() {
                final manufacturer =
                    controller.deviceManufacturer.value.trim();
                return _buildOemGuideSection(manufacturer);
              }),
              const SizedBox(height: 28),

              // Bottom CTA Section
              Obx(() {
                if (controller.allGranted) {
                  return SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      key: const Key('btn_mulai_monitoring'),
                      onPressed: controller.navigateToMonitoring,
                      icon: const Icon(Icons.arrow_forward_rounded,
                          color: Colors.white),
                      label: const Text(
                        'Mulai Monitoring',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                    ),
                  );
                } else {
                  return Center(
                    child: TextButton(
                      key: const Key('btn_kembali_aplikasi'),
                      onPressed: () => Get.back(),
                      child: const Text(
                        'Lanjutkan ke Aplikasi Nanti',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }
              }),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Obx(() {
      final activeCount = controller.activeCount;
      final isAll = controller.allGranted;
      final progress = activeCount / controller.totalPermission;

      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondary.withValues(alpha: 0.03),
              blurRadius: 10,
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
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isAll
                        ? const Color(0xFFDCFCE7)
                        : AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isAll
                        ? Icons.check_circle_outline_rounded
                        : Icons.shield_outlined,
                    color:
                        isAll ? const Color(0xFF15803D) : AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.summaryCountText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        controller.summaryStatusText,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isAll
                              ? const Color(0xFF15803D)
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: AppColors.background,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isAll ? const Color(0xFF15803D) : AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPermissionCard({
    required String title,
    required String description,
    required IconData icon,
    required bool isGranted,
    required VoidCallback onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGranted
              ? AppColors.primary.withValues(alpha: 0.25)
              : AppColors.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
                  color: isGranted
                      ? const Color(0xFFDCFCE7)
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isGranted
                      ? const Color(0xFF15803D)
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Badge Status
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isGranted
                      ? const Color(0xFFDCFCE7)
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isGranted
                        ? const Color(0xFFBBF7D0)
                        : AppColors.border,
                    width: 1,
                  ),
                ),
                child: Text(
                  isGranted ? 'Aktif' : 'Belum aktif',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isGranted
                        ? const Color(0xFF15803D)
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          if (!isGranted) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton(
                key: Key('btn_aktifkan_$title'),
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Aktifkan',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Banner panduan khusus latar belakang yang menyesuaikan dengan brand/vendor HP pengguna
  Widget _buildOemGuideSection(String manufacturer) {
    final brand =
        manufacturer.isEmpty ? 'Perangkat Anda' : manufacturer.toUpperCase();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB), // Warm yellow/amber
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  color: Color(0xFFD97706),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Panduan Latar Belakang ($brand)',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF92400E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Cegah sistem mematikan pemantauan saat layar mati',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildStepItem(
            '1',
            'Pilih opsi "Tidak Ada Pembatasan" (Unrestricted) pada Penghemat Baterai.',
          ),
          const SizedBox(height: 8),
          _buildStepItem(
            '2',
            'Aktifkan izin "Mulai Otomatis" (Auto-start / Background Start).',
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (!controller.batteryOptimizationIgnored.value) ...[
                Expanded(
                  child: OutlinedButton(
                    key: const Key('btn_matikan_hemat_baterai'),
                    onPressed: () => controller.requestBatteryOptimization(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF92400E),
                      side: const BorderSide(color: Color(0xFFD97706), width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      backgroundColor: Colors.white.withValues(alpha: 0.7),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text(
                      'Matikan Hemat Baterai',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: ElevatedButton.icon(
                  key: const Key('btn_buka_pengaturan_oem'),
                  onPressed: () => controller.openOemAutoStart(),
                  icon: const Icon(Icons.settings_suggest_rounded,
                      size: 16, color: Colors.white),
                  label: Text(
                    'Buka Pengaturan $brand',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD97706),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: const Color(0xFFD97706),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF78350F),
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
