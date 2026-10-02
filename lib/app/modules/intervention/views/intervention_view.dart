import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_bottom_navigation.dart';
import '../../../data/models/intervention_model.dart';
import '../../../routes/app_routes.dart';
import '../controllers/intervention_controller.dart';

/// Halaman Pusat Intervensi (MIND DRIJI).
///
/// Tempat terpusat untuk semua aksi digital wellness:
/// 1. Jeda Digital (5m, 15m, 30m)
/// 2. Mode Fokus (15m, 30m, 60m, custom)
/// 3. Pomodoro (25m fokus, 5m jeda)
/// 4. Intervensi Kustom (durasi fleksibel dengan validasi)
/// Serta shortcut ke Panduan Relaksasi Mata dan Riwayat Intervensi.
class InterventionView extends GetView<InterventionController> {
  const InterventionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Intervensi Digital',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.history_rounded,
              color: AppColors.textPrimary,
            ),
            tooltip: 'Riwayat Intervensi',
            onPressed: () => Get.toNamed(Routes.interventionHistory),
          ),
        ],
      ),
      body: Obx(() {
        final active = controller.activeIntervention;
        final isActive = controller.isActive;

        if (isActive && active != null && active.status == InterventionStatus.active) {
          if (active.type == InterventionType.eyeRelaxation) {
            return _buildEyeRelaxationShortcut(context);
          }
          return _buildActiveInterventionState(context, active);
        }

        return _buildInterventionHub(context);
      }),
      bottomNavigationBar: const AppBottomNavigation(currentIndex: 3),
    );
  }

  // ===========================================================================
  // 1. INACTIVE STATE: THE INTERVENTION HUB
  // ===========================================================================
  Widget _buildInterventionHub(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Pengantar
          _buildHubHeader(),
          const SizedBox(height: 20),

          // 1. Jeda Digital
          _buildDigitalBreakSection(context),
          const SizedBox(height: 18),

          // 2. Mode Fokus
          _buildFocusModeSection(context),
          const SizedBox(height: 18),

          // 3. Pomodoro Flow
          _buildPomodoroSection(context),
          const SizedBox(height: 20),

          // Shortcut ke Relaksasi Mata & Riwayat
          _buildAdditionalActions(context),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHubHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.spa_rounded,
              color: AppColors.primary,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Atur Penggunaan Digital',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Ambil jeda berkala atau batasi akses ke media sosial untuk menjaga fokus.',
                  style: TextStyle(
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
    );
  }

  // 1. JEDA DIGITAL (5, 15, 30 Menit)
  Widget _buildDigitalBreakSection(BuildContext context) {
    final selectedBreak = 15.obs;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.coffee_rounded, size: 20, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Jeda Digital',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Istirahat santai dari layar. Notifikasi jeda akan mengingatkanmu saat waktu habis.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          Obx(() {
            return Row(
              children: [15, 30, 60].map((mins) {
                final isSelected = selectedBreak.value == mins;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Center(
                        child: Text(
                          '$mins mnt',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.background,
                      onSelected: (_) => selectedBreak.value = mins,
                      showCheckmark: false,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: isSelected ? AppColors.primary : AppColors.border,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          }),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => controller.startDigitalBreak(selectedBreak.value),
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: const Text('Mulai Jeda Digital'),
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
      ),
    );
  }

  // 2. FOCUS MODE (15, 30, 45, 60 Menit, atau Kustom)
  Widget _buildFocusModeSection(BuildContext context) {
    final selectedFocus = 30.obs;
    final isCustom = false.obs;
    final customFocusController = TextEditingController(text: '20');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.do_not_disturb_on_total_silence_rounded,
                  size: 20, color: Color(0xFF2563EB)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Mode Fokus',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Active Restriction',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E40AF),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Membatasi aplikasi scrolling target (TikTok, IG, YouTube, Snapchat) selama timer. MIND DRIJI tetap bebas diakses.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          Obx(() {
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...[15, 30, 45, 60].map((mins) {
                  final isSelected = !isCustom.value && selectedFocus.value == mins;
                  return ChoiceChip(
                    label: Text(
                      '$mins mnt',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: const Color(0xFF2563EB),
                    backgroundColor: AppColors.background,
                    onSelected: (_) {
                      isCustom.value = false;
                      selectedFocus.value = mins;
                    },
                    showCheckmark: false,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFF2563EB) : AppColors.border,
                      ),
                    ),
                  );
                }),
                ChoiceChip(
                  label: Text(
                    'Kustom',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isCustom.value ? FontWeight.w700 : FontWeight.w500,
                      color: isCustom.value ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  selected: isCustom.value,
                  selectedColor: const Color(0xFF2563EB),
                  backgroundColor: AppColors.background,
                  onSelected: (_) {
                    isCustom.value = true;
                  },
                  showCheckmark: false,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: isCustom.value ? const Color(0xFF2563EB) : AppColors.border,
                    ),
                  ),
                ),
              ],
            );
          }),
          Obx(() {
            if (!isCustom.value) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 14),
              child: TextField(
                controller: customFocusController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Durasi Kustom (1 - 180 menit)',
                  hintText: 'Contoh: 20',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            );
          }),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                final duration = isCustom.value
                    ? (int.tryParse(customFocusController.text.trim()) ?? 0)
                    : selectedFocus.value;
                if (duration <= 0 || duration > 180) {
                  Get.snackbar(
                    'Durasi Tidak Valid',
                    'Durasi harus antara 1 sampai 180 menit.',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                  return;
                }
                controller.startFocusMode(duration);
              },
              icon: const Icon(Icons.shield_outlined, size: 18),
              label: const Text('Mulai Mode Fokus'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
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
      ),
    );
  }

  // 3. POMODORO (25m Fokus + 5m Jeda)
  Widget _buildPomodoroSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timer_outlined, size: 20, color: Color(0xFFEA580C)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Pomodoro Timer',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEDD5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '25m + 5m',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFC2410C),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Siklus produktivitas: 25 menit sesi fokus intensif dengan blocking, dilanjutkan 5 menit jeda penyegaran.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => controller.startPomodoro(),
              icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
              label: const Text('Mulai Siklus Pomodoro'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEA580C),
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
      ),
    );
  }

  Widget _buildAdditionalActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => Get.toNamed(Routes.eyeRelaxation),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.remove_red_eye_outlined,
                      size: 22, color: AppColors.primary),
                  SizedBox(height: 8),
                  Text(
                    'Relaksasi Mata',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Panduan rileks',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            onTap: () => Get.toNamed(Routes.interventionHistory),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.history_rounded,
                      size: 22, color: AppColors.secondary),
                  SizedBox(height: 8),
                  Text(
                    'Riwayat Sesi',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Daftar catatan',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 2. ACTIVE INTERVENTION STATE (Timer Ring, Countdown, Actions)
  // ===========================================================================
  Widget _buildActiveInterventionState(BuildContext context, InterventionModel active) {
    final isFocus = active.type == InterventionType.focusMode ||
        active.type == InterventionType.pomodoro;
    final primaryColor = isFocus ? const Color(0xFF2563EB) : AppColors.primary;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          // Timer Ring Visualization
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 220,
                  height: 220,
                  child: CircularProgressIndicator(
                    value: 1.0 - controller.progress,
                    strokeWidth: 10,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isFocus ? Icons.shield_outlined : Icons.spa_outlined,
                      size: 32,
                      color: primaryColor,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      controller.formattedRemainingTime,
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sisa Waktu',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),

          // Title & Subtext
          Text(
            '${active.title} Aktif',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isFocus
                ? 'Aplikasi media sosial sedang dibatasi. MIND DRIJI tetap bebas dibuka.'
                : 'Luangkan waktu sejenak untuk mengistirahatkan mata dan pikiran dari layar.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),

          // Tips Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline, size: 20, color: primaryColor),
                    const SizedBox(width: 8),
                    const Text(
                      'Saran Selama Intervensi',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildTipItem(Icons.water_drop_outlined, 'Minum segelas air putih.'),
                const SizedBox(height: 10),
                _buildTipItem(
                    Icons.nature_people_outlined, 'Tatap pemandangan hijau atau luar ruangan.'),
                const SizedBox(height: 10),
                _buildTipItem(
                    Icons.accessibility_new_outlined, 'Lakukan peregangan leher dan bahu.'),
              ],
            ),
          ),
          const SizedBox(height: 36),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _confirmCancel(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Batalkan',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => controller.complete(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Selesai',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTipItem(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEyeRelaxationShortcut(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.remove_red_eye_outlined, size: 64, color: AppColors.primary),
            const SizedBox(height: 16),
            const Text(
              'Panduan Relaksasi Mata',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Istirahat sejenak dari layar dengan mengikuti panduan rileks langkah demi langkah.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Get.toNamed(Routes.eyeRelaxation),
              child: const Text('Buka Panduan Relaksasi'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmCancel(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan Intervensi?'),
        content: const Text('Apakah kamu yakin ingin mengakhiri sesi lebih awal?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Lanjutkan Sesi'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              controller.cancel();
            },
            child: const Text('Ya, Batalkan', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
