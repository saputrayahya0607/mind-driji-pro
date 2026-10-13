import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/local/app_database.dart';
import '../controllers/doomscroll_controller.dart';

class DoomscrollView extends GetView<DoomscrollController> {
  const DoomscrollView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Doomscroll Monitoring'),
        centerTitle: true,
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            size: 22,
            color: AppColors.textPrimary,
          ),
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          onPressed: () => Get.back(),
          tooltip: 'Kembali',
        ),
      ),
      body: SafeArea(
        top: false,
        child: Obx(() {
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
                    'Memeriksa status monitoring...',
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
            onRefresh: () => controller.refreshSessions(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 14),
                  _buildSyncInfoCard(),
                  const SizedBox(height: 16),
                  _buildServiceStatusCard(),
                  const SizedBox(height: 16),
                  _buildPrivacyNoticeCard(),
                  const SizedBox(height: 20),
                  _buildLiveSessionSection(),
                  _buildSessionsSection(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  /// Header halaman Doomscroll Monitoring
  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Doomscroll Monitoring',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Deteksi sesi scrolling berulang pada aplikasi target secara privat.',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// Kartu informasi penyimpanan lokal & jadwal sinkronisasi otomatis
  Widget _buildSyncInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.successContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.card,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withValues(alpha: 0.12),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.schedule_rounded,
              size: 20,
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Penyimpanan Lokal Aktif',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Data sesi scrolling tersimpan aman di perangkat. Sinkronisasi otomatis ke cloud berjalan setiap pukul 23:59 WIB.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Kartu status Accessibility Service (Aktif / Belum Aktif)
  Widget _buildServiceStatusCard() {
    final isActive = controller.isAccessibilityActive.value;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.4)
              : AppColors.warning.withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.04),
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primaryContainer
                      : AppColors.warningContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isActive
                      ? Icons.check_circle_rounded
                      : Icons.warning_amber_rounded,
                  size: 24,
                  color: isActive ? AppColors.primary : AppColors.warning,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isActive ? 'Monitoring Aktif' : 'Monitoring Belum Aktif',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isActive
                          ? 'MIND DRIJI aktif mendeteksi sesi scrolling di latar belakang'
                          : 'Izin Accessibility Service diperlukan untuk mendeteksi scrolling',
                      style: const TextStyle(
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
          if (!isActive) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => controller.requestAccessibilityPermission(),
                icon: const Icon(Icons.settings_accessibility_rounded, size: 18),
                label: const Text('Aktifkan Monitoring'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Banner informasi privasi penting
  Widget _buildPrivacyNoticeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.privacy_tip_outlined,
            size: 20,
            color: AppColors.textSecondary,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Monitoring menggunakan pola interaksi scrolling, bukan isi konten. MIND DRIJI tidak membaca teks pribadi, caption, pesan, atau tangkapan layar.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Bagian daftar riwayat sesi doomscroll
  Widget _buildSessionsSection() {
    final list = controller.sessions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Sesi Scrolling Terdeteksi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            if (list.isNotEmpty)
              Text(
                '${list.length} sesi',
                style: const TextStyle(
                  fontSize: 12,
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
      padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.history_toggle_off_rounded,
            size: 42,
            color: AppColors.textTertiary,
          ),
          SizedBox(height: 12),
          Text(
            'Belum ada sesi scrolling terdeteksi.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Sesi akan otomatis terbentuk saat kamu melakukan scroll pada aplikasi TikTok, Instagram, YouTube, atau Snapchat.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textTertiary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// Card untuk setiap sesi doomscroll
  Widget _buildSessionCard(DoomscrollSessionData session) {
    final durationSeconds = (session.durationMillis.toInt() / 1000).round();
    final durationText = durationSeconds < 60
        ? '$durationSeconds dtk'
        : '${durationSeconds ~/ 60}m ${durationSeconds % 60}d';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
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
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: _buildAppIcon(session.packageName),
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
                    Expanded(
                      child: Text(
                        session.appName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      _formatTime(session.startedAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${session.swipeCount} scroll',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('•', style: TextStyle(color: AppColors.border)),
                    const SizedBox(width: 8),
                    Text(
                      'Durasi $durationText',
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
                    Icon(
                      Icons.arrow_downward_rounded,
                      size: 13,
                      color: session.downwardSwipeCount > 0
                          ? AppColors.primary
                          : AppColors.textTertiary,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${session.downwardSwipeCount} bawah',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_upward_rounded,
                      size: 13,
                      color: session.upwardSwipeCount > 0
                          ? AppColors.info
                          : AppColors.textTertiary,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${session.upwardSwipeCount} atas',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 13,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 3),
                    const Text(
                      'Tersimpan',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
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

  Widget _buildAppIcon(String packageName) {
    IconData icon;
    Color color;

    if (packageName.contains('musically') || packageName.contains('tiktok')) {
      icon = Icons.music_note_rounded;
      color = const Color(0xFF000000);
    } else if (packageName.contains('instagram')) {
      icon = Icons.camera_alt_rounded;
      color = const Color(0xFFE1306C);
    } else if (packageName.contains('youtube')) {
      icon = Icons.play_arrow_rounded;
      color = const Color(0xFFFF0000);
    } else if (packageName.contains('snapchat')) {
      icon = Icons.chat_bubble_rounded;
      color = const Color(0xFFD97706);
    } else {
      icon = Icons.phone_android_rounded;
      color = AppColors.primary;
    }

    return Icon(icon, size: 22, color: color);
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Format durasi dalam mm:ss atau hh:mm:ss
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

  /// Kartu Sesi Scrolling Aktif (Realtime UI)
  Widget _buildLiveSessionSection() {
    return Obx(() {
      final live = controller.activeSession.value;
      if (live == null || !live.isActive) {
        return const SizedBox.shrink();
      }

      final durationText = _formatDuration(live.durationMillis);

      return Container(
        margin: const EdgeInsets.only(bottom: 20),
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primary,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.12),
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
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 6,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Sesi scrolling aktif',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Sedang Memantau',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: _buildAppIcon(live.packageName),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      live.appName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    durationText,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.secondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Text(
                    '${live.swipeCount} Scroll',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(
                        Icons.arrow_downward_rounded,
                        size: 15,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '↓ ${live.downwardSwipeCount}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Row(
                    children: [
                      const Icon(
                        Icons.arrow_upward_rounded,
                        size: 15,
                        color: AppColors.info,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '↑ ${live.upwardSwipeCount}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
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
    });
  }
}
