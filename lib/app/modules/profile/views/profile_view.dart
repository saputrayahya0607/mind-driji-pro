import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_bottom_navigation.dart';
import '../../../data/models/profile_model.dart';
import '../../../routes/app_routes.dart';
import '../controllers/profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profil'),
        centerTitle: true,
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.edit_outlined,
              color: AppColors.textPrimary,
            ),
            tooltip: 'Edit Profil',
            onPressed: () => _goToEditProfile(context),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return _buildLoadingState();
        }

        if (controller.errorMessage.value != null) {
          return _buildErrorState(context);
        }

        final profile = controller.profile.value;
        if (profile == null) {
          return _buildEmptyState(context);
        }

        return _buildProfileContent(context, profile);
      }),
      bottomNavigationBar: const AppBottomNavigation(currentIndex: 4),
    );
  }

  /// State saat data sedang dimuat dari server
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
            'Memuat profil...',
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

  /// State saat terjadi error pengambilan data
  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 38,
                color: Color(0xFFE53E3E),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Data profil belum dapat dimuat.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => controller.loadProfile(),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: () => controller.showLogoutConfirmation(context),
              icon: const Icon(Icons.logout_rounded, size: 16, color: Color(0xFFEF4444)),
              label: const Text(
                'Keluar dari Akun',
                style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// State saat data profil tidak ditemukan (null)
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_off_outlined,
                size: 38,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Profil belum tersedia',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => controller.loadProfile(),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Muat Ulang'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: () => controller.showLogoutConfirmation(context),
              icon: const Icon(Icons.logout_rounded, size: 16, color: Color(0xFFEF4444)),
              label: const Text(
                'Keluar dari Akun',
                style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tampilan utama profil saat data berhasil didapatkan
  Widget _buildProfileContent(BuildContext context, ProfileModel profile) {
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.card,
      onRefresh: () => controller.loadProfile(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildProfileCard(profile),
            const SizedBox(height: 14),
            _buildEditButton(context, profile),
            const SizedBox(height: 24),
            _buildSettingsSection(),
            const SizedBox(height: 24),
            _buildPersonalInfoSection(profile),
            const SizedBox(height: 24),
            _buildDeviceInfoSection(),
            const SizedBox(height: 28),
            _buildLogoutSection(context),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// Header dengan judul "Profil" dan subtitle yang relevan
  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profil',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Informasi akun dan data diri digital wellness Anda',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// Profile card dengan avatar, nama lengkap, dan email
  Widget _buildProfileCard(ProfileModel profile) {
    final nama = _formatText(profile.namaLengkap);
    final email = _formatText(profile.email);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                _getInitials(profile.namaLengkap),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nama,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Tombol Edit Profil
  Widget _buildEditButton(BuildContext context, ProfileModel profile) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _goToEditProfile(context, profile),
        icon: const Icon(Icons.edit_outlined, size: 18),
        label: const Text(
          'Edit Profil',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  /// Navigasi ke halaman Edit Profile dan refresh jika ada pembaruan
  Future<void> _goToEditProfile(BuildContext context, [ProfileModel? profile]) async {
    final result = await Get.toNamed(
      Routes.editProfile,
      arguments: profile ?? controller.profile.value,
    );
    if (result == true) {
      controller.loadProfile();
    }
  }

  /// Section informasi pribadi lengkap
  Widget _buildPersonalInfoSection(ProfileModel profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Informasi Pribadi',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondary.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildInfoTile(
                icon: Icons.person_outline_rounded,
                label: 'Nama Lengkap',
                value: _formatText(profile.namaLengkap),
                isFirst: true,
              ),
              const Divider(height: 1, thickness: 1, color: AppColors.border),
              _buildInfoTile(
                icon: Icons.mail_outline_rounded,
                label: 'Email',
                value: _formatText(profile.email),
              ),
              const Divider(height: 1, thickness: 1, color: AppColors.border),
              _buildInfoTile(
                icon: Icons.phone_outlined,
                label: 'Nomor HP',
                value: _formatText(profile.noHp),
              ),
              const Divider(height: 1, thickness: 1, color: AppColors.border),
              _buildInfoTile(
                icon: Icons.calendar_today_outlined,
                label: 'Tanggal Lahir',
                value: _formatTanggal(profile.tanggalLahir),
              ),
              const Divider(height: 1, thickness: 1, color: AppColors.border),
              _buildInfoTile(
                icon: Icons.wc_outlined,
                label: 'Jenis Kelamin',
                value: _formatGender(profile.jenisKelamin),
                isLast: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Section informasi perangkat saat ini (Device Management sederhana)
  Widget _buildDeviceInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text('📱', style: TextStyle(fontSize: 18)),
            SizedBox(width: 8),
            Text(
              'Perangkat Ini',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondary.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Obx(() {
            final info = controller.currentDeviceInfo.value;
            // Prioritaskan manufacturer (merek) yang diberikan langsung oleh Android
            final brand = info?.displayBrand ?? 'Android Device';
            final androidVer = 'Android ${info?.androidVersion ?? '-'}';
            final model = info?.model.trim();
            final hasModel = model != null &&
                model.isNotEmpty &&
                model.toLowerCase() != 'unknown' &&
                model.toLowerCase() != brand.toLowerCase();
            final rawId = info?.deviceId ?? 'legacy';
            final shortId = rawId.length > 12 ? '${rawId.substring(0, 8)}...' : rawId;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.smartphone_rounded,
                          color: AppColors.primary,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              brand,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              androidVer,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (hasModel) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Model: $model',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1, color: AppColors.border),
                _buildInfoTile(
                  icon: Icons.fingerprint_rounded,
                  label: 'Device ID',
                  value: shortId,
                  isLast: true,
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  /// Section Pengaturan & Preferensi Monitoring
  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pengaturan Monitoring',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondary.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildNavigationTile(
                key: const Key('tile_target_apps'),
                icon: Icons.sensors_rounded,
                title: 'Target Doomscrolling',
                subtitle: 'Kelola aplikasi yang dipantau pola scrolling-nya',
                onTap: () => Get.toNamed(Routes.targetApps),
                isFirst: true,
              ),
              const Divider(height: 1, thickness: 1, color: AppColors.border),
              _buildNavigationTile(
                key: const Key('tile_permission_guide'),
                icon: Icons.verified_user_outlined,
                title: 'Izin & Optimasi HP',
                subtitle: 'Panduan izin dan kestabilan latar belakang HP Anda',
                onTap: () => Get.toNamed(Routes.permissionGuide),
                isLast: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationTile({
    Key? key,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: key,
        onTap: onTap,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(20) : Radius.zero,
          bottom: isLast ? const Radius.circular(20) : Radius.zero,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Baris informasi satuan
  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final isUnset = value == 'Belum diisi';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: isUnset ? AppColors.textSecondary.withValues(alpha: 0.7) : AppColors.textPrimary,
                    fontWeight: isUnset ? FontWeight.w400 : FontWeight.w600,
                    fontStyle: isUnset ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Helper untuk mengambil inisial nama
  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  /// Helper format teks string (fallback 'Belum diisi')
  String _formatText(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Belum diisi';
    }
    return value.trim();
  }

  /// Helper format tanggal (Indonesian format)
  String _formatTanggal(DateTime? date) {
    if (date == null) return 'Belum diisi';
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  /// Helper format jenis kelamin
  String _formatGender(String? gender) {
    if (gender == null || gender.trim().isEmpty) return 'Belum diisi';
    final normalized = gender.trim().toLowerCase();
    if (normalized == 'l' || normalized == 'laki-laki' || normalized == 'male') {
      return 'Laki-laki';
    }
    if (normalized == 'p' || normalized == 'perempuan' || normalized == 'female') {
      return 'Perempuan';
    }
    return gender.trim();
  }

  /// Bagian tombol logout akun
  Widget _buildLogoutSection(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => controller.showLogoutConfirmation(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFEF4444),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Keluar dari Akun',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Akhiri sesi akun pada perangkat ini',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFEF4444),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
