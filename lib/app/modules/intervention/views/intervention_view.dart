import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/app_bottom_navigation.dart';
import '../../../data/models/intervention_model.dart';
import '../../../routes/app_routes.dart';
import '../controllers/intervention_controller.dart';

/// Redesign Modern, Bersih & Minimalis Halaman Intervensi Digital MIND DRIJI
///
/// Fitur & Desain:
/// - Background soft blue-gray `#EAF2F7`
/// - Header Global MIND DRIJI konsisten dengan Home, Monitoring, & Insight (Logo, Teks, Subtitle, Notifikasi)
/// - Sub-header: Judul `Intervensi Digital`, Subtitle `Ambil jeda, kembali lebih sadar.`, & Ikon Riwayat Sesi
/// - Card Atur Penggunaan Digital (Ringkas, minimalis, ikon tanaman mint, chevron)
/// - Card Jeda Digital (Visual cangkir mint, chip 5m, 15m, 30m, 60m tanpa deskripsi panjang, tombol teal full-width)
/// - Card Mode Fokus (Ikon shield cyan, chip 15m, 30m, 45m, 60m, Kustom dalam grid rapi, tombol cyan full-width)
/// - Card Pomodoro Timer (Ikon timer oranye, badge 25m + 5m, tombol oranye full-width)
/// - Dua Card Berdampingan: Panduan Relaksasi Mata & Riwayat Sesi (Expanded proporsional, tanpa deskripsi panjang)
/// - State Intervensi Aktif: Countdown Timer Ring, Tips Selama Sesi, & Tombol Batalkan / Selesai
/// - Responsif di semua ukuran layar Android tanpa RenderFlex overflow
class InterventionView extends GetView<InterventionController> {
  const InterventionView({super.key});

  static const Color pageBgColor = Color(0xFFEAF2F7);
  static const Color cardBorderColor = Color(0xFFDCE5EE);
  static const Color tealAccent = Color(0xFF00BFA5);
  static const Color tealBg = Color(0xFFDDF4F2);
  static const Color cyanAccent = Color(0xFF00D9EC);
  static const Color cyanBg = Color(0xFFE0F7FA);
  static const Color orangeAccent = Color(0xFFD97706);
  static const Color orangeBg = Color(0xFFFEF3C7);
  static const Color navyColor = Color(0xFF0B2030);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBgColor,
      appBar: _buildAppBar(context),
      body: SafeArea(
        top: false,
        child: Obx(() {
          final active = controller.activeIntervention;
          final isActive = controller.isActive;

          if (isActive &&
              active != null &&
              active.status == InterventionStatus.active) {
            if (active.type == InterventionType.eyeRelaxation) {
              return _buildEyeRelaxationShortcut(context);
            }
            return _buildActiveInterventionState(context, active);
          }

          return _buildInterventionHub(context);
        }),
      ),
      bottomNavigationBar: const AppBottomNavigation(currentIndex: 3),
    );
  }

  // ===========================================================================
  // 1. HEADER GLOBAL MIND DRIJI (IDENTIK DENGAN HOME, MONITORING, & INSIGHT)
  // ===========================================================================
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: AppColors.navy.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              'assets/icons/app_icon.png',
              width: 36,
              height: 36,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Image.asset(
                'assets/icons/loader/full_mark.png',
                width: 36,
                height: 36,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppStrings.appName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  'Digital Wellness Companion',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      centerTitle: false,
      backgroundColor: pageBgColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      actions: [
        IconButton(
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: AppColors.navy,
            size: 24,
          ),
          tooltip: 'Pemberitahuan Sistem & Intervensi',
          onPressed: () => _showNotificationSheet(context),
        ),
        const SizedBox(width: 6),
      ],
    );
  }

  /// Modal Bottom Sheet Status Sistem & Notifikasi Intervensi
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
                      color: tealAccent,
                      size: 22,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Pemberitahuan & Status Intervensi',
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
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
                    border: Border.all(color: cardBorderColor),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.shield_outlined, color: tealAccent, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Fitur intervensi siap digunakan untuk menjaga keseimbangan digital dan produktivitasmu.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.navy,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tealAccent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                    child: const Text(
                      'Tutup',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // 2. THE INTERVENTION HUB (STATE INAKTIF)
  // ===========================================================================
  Widget _buildInterventionHub(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sub-Header: Judul Intervensi Digital, Subtitle, & Tombol Riwayat
          _buildPageTitleRow(context),
          const SizedBox(height: 12),

          // 1. Card Atur Penggunaan Digital (Pendek & Minimalis)
          _buildManageDigitalUsageCard(context),
          const SizedBox(height: 12),

          // 2. Card Jeda Digital (Fokus Visual & Kompak)
          _buildDigitalBreakSection(context),
          const SizedBox(height: 12),

          // 3. Card Mode Fokus (Grid Pilihan Durasi & Cyan Button)
          _buildFocusModeSection(context),
          const SizedBox(height: 12),

          // 4. Card Pomodoro Timer (Pendek & Sederhana)
          _buildPomodoroSection(context),
          const SizedBox(height: 12),

          // 5. Dua Card Berdampingan: Panduan Relaksasi Mata & Riwayat Sesi
          _buildBottomActionCards(context),
          const SizedBox(height: 14),
        ],
      ),
    );
  }

  // ===========================================================================
  // SUB-HEADER AREA: JUDUL & SUBTITLE
  // ===========================================================================
  Widget _buildPageTitleRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      color: tealAccent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Intervensi Digital',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: navyColor,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              const Text(
                'Ambil jeda, kembali lebih sadar.',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: () => Get.toNamed(Routes.interventionHistory),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cardBorderColor),
              boxShadow: [
                BoxShadow(
                  color: navyColor.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.history_rounded,
              size: 20,
              color: navyColor,
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // CARD 1: ATUR PENGGUNAAN DIGITAL (PENDEK & MINIMALIS)
  // ===========================================================================
  Widget _buildManageDigitalUsageCard(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Get.toNamed(Routes.targetApps),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cardBorderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: navyColor.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: tealBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.spa_rounded,
                  color: tealAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Atur Penggunaan Digital',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: navyColor,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 1),
                    Text(
                      'Atur batas aplikasi',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // CARD 2: JEDA DIGITAL (5m, 15m, 30m, 60m) - FOKUS VISUAL & KOMPAK
  // ===========================================================================
  Widget _buildDigitalBreakSection(BuildContext context) {
    final selectedBreak = 15.obs;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: navyColor.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: tealBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.coffee_rounded,
                  size: 20,
                  color: tealAccent,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Jeda Digital',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: navyColor,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Pilihan Durasi Jeda Digital: 5 mnt, 15 mnt, 30 mnt, 60 mnt
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 280;

              if (isWide) {
                return Obx(() {
                  return Row(
                    children: [5, 15, 30, 60].map((mins) {
                      final isSelected = selectedBreak.value == mins;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: mins == 60 ? 0 : 8),
                          child: _buildDurationOption(
                            label: '$mins mnt',
                            isSelected: isSelected,
                            accentColor: tealAccent,
                            activeBg: tealBg,
                            onTap: () => selectedBreak.value = mins,
                          ),
                        ),
                      );
                    }).toList(),
                  );
                });
              }

              // Layar sangat sempit: 2 x 2
              return Obx(() {
                return Column(
                  children: [
                    Row(
                      children: [5, 15].map((mins) {
                        final isSelected = selectedBreak.value == mins;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: mins == 15 ? 0 : 8),
                            child: _buildDurationOption(
                              label: '$mins mnt',
                              isSelected: isSelected,
                              accentColor: tealAccent,
                              activeBg: tealBg,
                              onTap: () => selectedBreak.value = mins,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [30, 60].map((mins) {
                        final isSelected = selectedBreak.value == mins;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: mins == 60 ? 0 : 8),
                            child: _buildDurationOption(
                              label: '$mins mnt',
                              isSelected: isSelected,
                              accentColor: tealAccent,
                              activeBg: tealBg,
                              onTap: () => selectedBreak.value = mins,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                );
              });
            },
          ),
          const SizedBox(height: 14),

          // Tombol Mulai Jeda Digital (Full-width Teal)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () =>
                  controller.startDigitalBreak(selectedBreak.value),
              icon: const Icon(Icons.play_arrow_rounded, size: 20),
              label: const Text(
                'Mulai Jeda Digital',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: tealAccent,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(46),
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

  // ===========================================================================
  // CARD 3: MODE FOKUS (15m, 30m, 45m, 60m, KUSTOM) - GRID RAPI & CYAN BUTTON
  // ===========================================================================
  Widget _buildFocusModeSection(BuildContext context) {
    final selectedFocus = 30.obs;
    final isCustom = false.obs;
    final customFocusController = TextEditingController(text: '20');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: navyColor.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: cyanBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  size: 20,
                  color: Color(0xFF0097A7),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Mode Fokus',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: navyColor,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Pilihan Durasi Grid Rapi: [15, 30, 45] di baris 1, [60, Kustom] di baris 2
          Obx(() {
            return Column(
              children: [
                Row(
                  children: [15, 30, 45].map((mins) {
                    final isSelected =
                        !isCustom.value && selectedFocus.value == mins;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: mins == 45 ? 0 : 8),
                        child: _buildDurationOption(
                          label: '$mins mnt',
                          isSelected: isSelected,
                          accentColor: tealAccent,
                          activeBg: tealBg,
                          onTap: () {
                            isCustom.value = false;
                            selectedFocus.value = mins;
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildDurationOption(
                          label: '60 mnt',
                          isSelected:
                              !isCustom.value && selectedFocus.value == 60,
                          accentColor: tealAccent,
                          activeBg: tealBg,
                          onTap: () {
                            isCustom.value = false;
                            selectedFocus.value = 60;
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      child: _buildDurationOption(
                        label: 'Kustom',
                        isSelected: isCustom.value,
                        accentColor: tealAccent,
                        activeBg: tealBg,
                        onTap: () {
                          isCustom.value = true;
                        },
                      ),
                    ),
                  ],
                ),
              ],
            );
          }),

          // Input Kustom Jika Dipilih
          Obx(() {
            if (!isCustom.value) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: TextField(
                controller: customFocusController,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: navyColor,
                ),
                decoration: InputDecoration(
                  labelText: 'Durasi Kustom (1 - 180 menit)',
                  labelStyle: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF64748B),
                  ),
                  hintText: 'Contoh: 20',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: cardBorderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: tealAccent, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 14),

          // Tombol Mulai Mode Fokus (Cyan #00D9EC Full-width)
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
                    backgroundColor: Colors.white,
                    colorText: navyColor,
                  );
                  return;
                }
                controller.startFocusMode(duration);
              },
              icon: const Icon(Icons.shield_outlined, size: 20),
              label: const Text(
                'Mulai Mode Fokus',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: cyanAccent,
                foregroundColor: navyColor,
                minimumSize: const Size.fromHeight(46),
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

  // ===========================================================================
  // CARD 4: POMODORO TIMER (25m + 5m) - PENDEK & SEDERHANA
  // ===========================================================================
  Widget _buildPomodoroSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: navyColor.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card dengan Badge Durasi
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: orangeBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.timer_outlined,
                  size: 20,
                  color: orangeAccent,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Pomodoro Timer',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: navyColor,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: orangeBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '25m + 5m',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF92400E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Tombol Mulai Siklus Pomodoro (Aksen Oranye Full-width)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => controller.startPomodoro(),
              icon: const Icon(Icons.play_circle_outline_rounded, size: 20),
              label: const Text(
                'Mulai Siklus Pomodoro',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: orangeAccent,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(46),
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

  // ===========================================================================
  // DUA CARD BERDAMPINGAN: RELAKSASI MATA & RIWAYAT SESI
  // ===========================================================================
  Widget _buildBottomActionCards(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isStacked =
            constraints.maxWidth < 260 ||
            MediaQuery.textScalerOf(context).scale(1.0) > 1.35;

        final cardRelaksasi = _buildCompactActionCard(
          icon: Icons.remove_red_eye_outlined,
          iconColor: const Color(0xFF0284C7),
          iconBgColor: const Color(0xFFE0F2FE),
          title: 'Relaksasi Mata',
          onTap: () => Get.toNamed(Routes.eyeRelaxation),
        );

        final cardRiwayat = _buildCompactActionCard(
          icon: Icons.history_rounded,
          iconColor: navyColor,
          iconBgColor: const Color(0xFFEDE9FE),
          title: 'Riwayat Sesi',
          onTap: () => Get.toNamed(Routes.interventionHistory),
        );

        if (isStacked) {
          return Column(
            children: [cardRelaksasi, const SizedBox(height: 10), cardRiwayat],
          );
        }

        return Row(
          children: [
            Expanded(child: cardRelaksasi),
            const SizedBox(width: 10),
            Expanded(child: cardRiwayat),
          ],
        );
      },
    );
  }

  Widget _buildCompactActionCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: cardBorderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: navyColor.withValues(alpha: 0.03),
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
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: navyColor,
                    height: 1.2,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // HELPER DURATION OPTION BUTTON
  // ===========================================================================
  Widget _buildDurationOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color accentColor = tealAccent,
    Color activeBg = tealBg,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? activeBg : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? accentColor : cardBorderColor,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? navyColor : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 3. STATE INTERVENSI AKTIF (COUNTDOWN, TIMER RING, & KONTROL SESI)
  // ===========================================================================
  Widget _buildActiveInterventionState(
    BuildContext context,
    InterventionModel active,
  ) {
    final isFocus =
        active.type == InterventionType.focusMode ||
        active.type == InterventionType.pomodoro;
    final primaryColor = isFocus ? tealAccent : tealAccent;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 10),

          // Timer Ring Visualization
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 210,
                  height: 210,
                  child: CircularProgressIndicator(
                    value: (1.0 - controller.progress).clamp(0.0, 1.0),
                    strokeWidth: 9,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isFocus ? Icons.shield_outlined : Icons.spa_outlined,
                      size: 30,
                      color: primaryColor,
                    ),
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        controller.formattedRemainingTime,
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          color: AppColors.navy,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Sisa Waktu',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Title & Subtext
          Text(
            '${active.title} Aktif',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isFocus
                ? 'Aplikasi media sosial sedang dibatasi. MIND DRIJI tetap bebas dibuka.'
                : 'Luangkan waktu sejenak untuk mengistirahatkan mata dan pikiran dari layar.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // Tips Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: cardBorderColor, width: 1),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navy.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 18,
                      color: primaryColor,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Saran Selama Intervensi',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildTipItem(
                  Icons.water_drop_outlined,
                  'Minum segelas air putih.',
                ),
                const SizedBox(height: 8),
                _buildTipItem(
                  Icons.nature_people_outlined,
                  'Tatap pemandangan hijau atau luar ruangan.',
                ),
                const SizedBox(height: 8),
                _buildTipItem(
                  Icons.accessibility_new_outlined,
                  'Lakukan peregangan leher dan bahu.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action Buttons: Batalkan & Selesai
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _confirmCancel(context),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    side: const BorderSide(color: cardBorderColor, width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Batalkan',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => controller.complete(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Selesai',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
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
            const Icon(
              Icons.remove_red_eye_outlined,
              size: 56,
              color: tealAccent,
            ),
            const SizedBox(height: 14),
            const Text(
              'Panduan Relaksasi Mata',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Istirahat sejenak dari layar dengan mengikuti panduan rileks langkah demi langkah.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Get.toNamed(Routes.eyeRelaxation),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(180, 48),
                backgroundColor: tealAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Buka Panduan Relaksasi',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Batalkan Intervensi?',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),
        content: const Text(
          'Apakah kamu yakin ingin mengakhiri sesi lebih awal?',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Lanjutkan Sesi',
              style: TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              controller.cancel();
            },
            child: const Text(
              'Ya, Batalkan',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
