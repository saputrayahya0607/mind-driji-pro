import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/local/app_database.dart';
import '../../../data/local/tables/sync_queue.dart';
import '../controllers/eye_monitoring_controller.dart';

class EyeMonitoringView extends GetView<EyeMonitoringController> {
  const EyeMonitoringView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Eye Monitoring'),
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
        if (controller.isLoading.value && !controller.isMonitoring.value) {
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
                  'Menyiapkan pemantauan mata...',
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
          onRefresh: () async {
            await controller.checkPermissionAndStatus();
            await controller.loadStoredSessions();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 14),
                _buildSyncStatusBanner(),
                const SizedBox(height: 16),
                _buildMonitoringStatusCard(),
                const SizedBox(height: 16),
                _buildPrivacyNoticeCard(),
                const SizedBox(height: 24),
                _buildSessionsSection(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      }),
    );
  }

  /// Header halaman Eye Monitoring
  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pemantauan Mata',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Indikator eye fatigue berbasis behavioral kedipan dan keterbukaan mata (EAR).',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// Banner status sinkronisasi ke Supabase
  Widget _buildSyncStatusBanner() {
    return Obx(() {
      final syncMgr = controller.syncManager;
      final isSyncing = syncMgr.isSyncing.value;
      final isOnline = syncMgr.isOnline.value;
      final queuePending = syncMgr.pendingCount.value;

      final localSessions = controller.storedSessions;
      final localPendingCount =
          localSessions.where((s) => s.syncStatus == 'pending').length;
      final localFailedCount =
          localSessions.where((s) => s.syncStatus == 'failed').length;

      final hasFailed =
          localFailedCount > 0 || syncMgr.syncStatus.value == SyncStatus.failed;
      final hasPending = localPendingCount > 0 || queuePending > 0;
      final totalPending = math.max(queuePending, localPendingCount);

      Color badgeBg;
      Color badgeBorder;
      Color iconColor;
      IconData iconData;
      String statusTitle;
      String statusSubtitle;
      Widget? actionButton;

      if (isSyncing) {
        badgeBg = const Color(0xFFE6FFFA);
        badgeBorder = const Color(0xFF81E6D9);
        iconColor = AppColors.primary;
        iconData = Icons.sync_rounded;
        statusTitle = 'Menyinkronkan sesi ke Cloud...';
        statusSubtitle = 'Menghubungkan ke Supabase';
      } else if (!isOnline) {
        badgeBg = const Color(0xFFF1F5F9);
        badgeBorder = const Color(0xFFCBD5E1);
        iconColor = const Color(0xFF64748B);
        iconData = Icons.cloud_off_rounded;
        statusTitle = 'Mode Offline (SQLite Aktif)';
        statusSubtitle = (hasPending || hasFailed)
            ? '$totalPending sesi tersimpan lokal, siap sync saat online'
            : 'Data sesi tersimpan aman di database lokal';
      } else if (hasFailed) {
        badgeBg = const Color(0xFFFEF2F2);
        badgeBorder = const Color(0xFFFECACA);
        iconColor = const Color(0xFFDC2626);
        iconData = Icons.sync_problem_rounded;
        statusTitle = 'Sinkronisasi Bermasalah';
        statusSubtitle = localFailedCount > 0
            ? '$localFailedCount sesi gagal dikirim. Ketuk untuk coba lagi.'
            : 'Gagal mengirim sebagian data ke server.';
        actionButton = InkWell(
          onTap: () => controller.manualSync(),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFDC2626),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.refresh, size: 13, color: Colors.white),
                SizedBox(width: 4),
                Text(
                  'Retry',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (hasPending) {
        badgeBg = const Color(0xFFFFFBEB);
        badgeBorder = const Color(0xFFFDE68A);
        iconColor = const Color(0xFFD97706);
        iconData = Icons.cloud_queue_rounded;
        statusTitle = 'Menunggu Sinkronisasi';
        statusSubtitle = '$totalPending sesi lokal siap disinkronkan';
        actionButton = InkWell(
          onTap: () => controller.manualSync(),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
        );
      } else {
        badgeBg = const Color(0xFFF0FDF4);
        badgeBorder = const Color(0xFFBBF7D0);
        iconColor = const Color(0xFF16A34A);
        iconData = Icons.cloud_done_rounded;
        statusTitle = 'Tersinkronisasi Penuh';
        statusSubtitle = 'Data sesi lokal & Supabase Cloud telah sinkron';
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
            if (!isSyncing && isOnline && actionButton != null)
              actionButton,
          ],
        ),
      );
    });
  }

  /// Kartu utama pemantauan mata (Belum Aktif / Aktif Berjalan Otomatis / Sedang Memantau)
  Widget _buildMonitoringStatusCard() {
    return Obx(() {
      final isEnabled = controller.isMonitoringEnabled.value;
      final isSessionRunning = controller.isMonitoring.value;
      final faceDet = controller.faceDetected.value;
      final multiFace = controller.multipleFaces.value;
      final dur = controller.elapsedDuration.value;
      final durationText = _formatDuration(dur);
      final nextSchedule = controller.nextScheduledAt.value;
      final lastCompleted = controller.lastSessionCompletedAt.value;

      // Color scheme based on state
      final Color borderColor;
      final Color shadowColor;
      if (isSessionRunning) {
        borderColor = const Color(0xFF00BFA5);
        shadowColor = const Color(0xFF00BFA5).withValues(alpha: 0.12);
      } else if (isEnabled) {
        borderColor = const Color(0xFF10B981);
        shadowColor = const Color(0xFF10B981).withValues(alpha: 0.08);
      } else {
        borderColor = AppColors.border;
        shadowColor = AppColors.secondary.withValues(alpha: 0.04);
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: (isSessionRunning || isEnabled) ? 1.5 : 1.0),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Status Indicator + Title + Badge
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: isSessionRunning
                        ? const Color(0xFF00BFA5)
                        : (isEnabled ? const Color(0xFF10B981) : const Color(0xFF94A3B8)),
                    shape: BoxShape.circle,
                    boxShadow: (isSessionRunning || isEnabled)
                        ? [
                            BoxShadow(
                              color: (isSessionRunning ? const Color(0xFF00BFA5) : const Color(0xFF10B981))
                                  .withValues(alpha: 0.4),
                              blurRadius: 6,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isSessionRunning
                      ? 'Sedang Memantau'
                      : (isEnabled ? 'Monitoring Aktif' : 'Monitoring belum aktif'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isSessionRunning
                        ? const Color(0xFF00BFA5)
                        : (isEnabled ? const Color(0xFF047857) : AppColors.textSecondary),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSessionRunning
                        ? const Color(0xFFE6FFFA)
                        : (isEnabled ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isSessionRunning
                        ? 'Kamera Aktif'
                        : (isEnabled ? 'Otomatis' : 'Standby'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isSessionRunning
                          ? AppColors.primary
                          : (isEnabled ? const Color(0xFF059669) : AppColors.textSecondary),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // KONDISI 1: SESI KAMERA SEDANG BERJALAN
            if (isSessionRunning) ...[
              const Text(
                'Kamera aktif untuk pemantauan mata.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            faceDet
                                ? (multiFace ? Icons.group_outlined : Icons.face_rounded)
                                : Icons.face_outlined,
                            size: 18,
                            color: faceDet
                                ? (multiFace ? const Color(0xFFD97706) : AppColors.primary)
                                : const Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            faceDet
                                ? (multiFace ? 'Lebih dari 1 Wajah' : 'Wajah Terdeteksi')
                                : 'Mencari Wajah...',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: faceDet
                                  ? (multiFace ? const Color(0xFFD97706) : AppColors.textPrimary)
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        controller.statusMessage.value,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    durationText,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.secondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetricItem(
                      label: 'EAR Terkini',
                      value: controller.currentEar.value > 0
                          ? controller.currentEar.value.toStringAsFixed(2)
                          : '-',
                    ),
                    Container(width: 1, height: 28, color: const Color(0xFFE2E8F0)),
                    _buildMetricItem(
                      label: 'Kedipan',
                      value: '${controller.blinkCount.value}',
                    ),
                    Container(width: 1, height: 28, color: const Color(0xFFE2E8F0)),
                    _buildMetricItem(
                      label: 'Penutupan Mata',
                      value: '${controller.eyeClosureEvents.value}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => controller.disableMonitoring(),
                  icon: const Icon(Icons.stop_circle_outlined, size: 20),
                  label: const Text('Matikan Monitoring'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ]

            // KONDISI 2: MONITORING DIAKTIFKAN, SEDANG MENUNGGU JADWAL INTERVAL
            else if (isEnabled) ...[
              const Text(
                'Pemantauan berjalan otomatis di latar belakang.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Sistem akan melakukan pemantauan singkat secara berkala (±1 menit). Kamera akan aktif otomatis dan mati setelah selesai.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),

              // Status selesai jika baru saja selesai
              if (controller.statusMessage.value.contains('selesai') ||
                  controller.statusMessage.value.contains('Selesai')) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF059669)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Pemantauan selesai. Kamera telah dimatikan.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF065F46),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Jadwal berikutnya & Sesi terakhir
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Jadwal Berikutnya',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            nextSchedule != null
                                ? 'Pukul ${_formatTime(nextSchedule)}'
                                : 'Menunggu...',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 28, color: const Color(0xFFE2E8F0)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sesi Terakhir',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            lastCompleted != null
                                ? 'Pukul ${_formatTime(lastCompleted)}'
                                : '-',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => controller.disableMonitoring(),
                      icon: const Icon(Icons.power_settings_new_rounded, size: 18),
                      label: const Text('Matikan Monitoring'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        side: const BorderSide(color: Color(0xFFFCA5A5)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Internal testing trigger for manual inspection
                  IconButton(
                    onPressed: () => controller.startSessionNow(),
                    icon: const Icon(Icons.play_circle_outline_rounded),
                    color: AppColors.primary,
                    tooltip: 'Jalankan Sesi Sekarang (Tes)',
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFE6FFFA),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ]

            // KONDISI 3: MONITORING MATI / BELUM AKTIF
            else ...[
              const Text(
                'Sistem akan memantau kondisi mata secara berkala selama ±1 menit saat Anda menggunakan aplikasi. Kamera mati otomatis setelah sesi selesai.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => controller.enableMonitoring(),
                  icon: const Icon(Icons.remove_red_eye_rounded, size: 18),
                  label: const Text('Aktifkan Monitoring'),
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
            ],
          ],
        ),
      );
    });
  }

  Widget _buildMetricItem({required String label, required String value}) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// Banner informasi privasi penting sesuai ketentuan Section 13
  Widget _buildPrivacyNoticeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.privacy_tip_outlined,
            size: 20,
            color: Color(0xFF64748B),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prinsip Privasi & Keamanan Kamera',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  '• Kamera HANYA aktif selama sesi pemantauan (±1 menit) lalu otomatis OFF.\n'
                  '• Analisis EAR dan kedipan diproses lokal dari frame sementara di memori (RAM).\n'
                  '• TIDAK ADA foto, video, frame gambar, atau face embedding yang disimpan atau dikirim.\n'
                  '• Yang disimpan HANYA ringkasan numerik: rata-rata EAR, kedipan, eye closure, dan durasi.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF475569),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Bagian riwayat sesi pemantauan mata
  Widget _buildSessionsSection() {
    final list = controller.storedSessions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Riwayat Sesi Pemantauan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            if (list.isNotEmpty)
              Text(
                '${list.length} sesi',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (list.isEmpty)
          _buildEmptyState()
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              return _buildSessionCard(list[index]);
            },
          ),
      ],
    );
  }

  /// Empty state jika belum ada data sesi
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.visibility_off_outlined,
            size: 44,
            color: Color(0xFF94A3B8),
          ),
          SizedBox(height: 12),
          Text(
            'Belum ada riwayat sesi pemantauan mata.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Mulai pemantauan mata untuk mencatat rata-rata keterbukaan kelopak mata dan frekuensi kedipan.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF94A3B8),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  /// Card untuk setiap sesi yang tersimpan
  Widget _buildSessionCard(EyeMonitoringSessionData session) {
    final durationSeconds = (session.durationMillis.toInt() / 1000).round();
    final durationText = durationSeconds < 60
        ? '$durationSeconds dtk'
        : '${durationSeconds ~/ 60}m ${durationSeconds % 60}d';

    final isSynced = session.syncStatus == 'synced';
    final isFailed = session.syncStatus == 'failed';
    final Color badgeColor;
    final IconData badgeIcon;
    final String badgeText;

    if (isSynced) {
      badgeColor = const Color(0xFF16A34A);
      badgeIcon = Icons.cloud_done_rounded;
      badgeText = 'Synced';
    } else if (isFailed) {
      badgeColor = const Color(0xFFDC2626);
      badgeIcon = Icons.error_outline_rounded;
      badgeText = 'Failed';
    } else {
      badgeColor = const Color(0xFFD97706);
      badgeIcon = Icons.cloud_upload_outlined;
      badgeText = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(
                Icons.remove_red_eye_outlined,
                size: 22,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Sesi Pemantauan Mata',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      _formatTime(session.startedAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Durasi $durationText',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('•', style: TextStyle(color: Color(0xFFCBD5E1))),
                    const SizedBox(width: 8),
                    Text(
                      'Rata-rata EAR ${session.averageEar.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${session.blinkCount} kedipan',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${session.eyeClosureEvents} penutupan',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      badgeIcon,
                      size: 13,
                      color: badgeColor,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      badgeText,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: badgeColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int millis) {
    final totalSec = (millis / 1000).floor();
    final hours = totalSec ~/ 3600;
    final minutes = (totalSec % 3600) ~/ 60;
    final seconds = totalSec % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
