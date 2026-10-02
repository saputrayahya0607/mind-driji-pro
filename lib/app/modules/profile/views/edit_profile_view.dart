import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../controllers/edit_profile_controller.dart';

class EditProfileView extends GetView<EditProfileController> {
  const EditProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Profil'),
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
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),
          );
        }

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Form(
              key: controller.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(),
                  const SizedBox(height: 20),
                  _buildFormCard(context),
                  const SizedBox(height: 32),
                  _buildSaveButton(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  /// Header pembuka formulir
  Widget _buildSectionHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Perbarui Data Diri',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Pastikan informasi profil Anda selalu akurat dan terkini.',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// Kartu utama berisikan field-field formulir
  Widget _buildFormCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
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
          // 1. Email (Read-Only)
          _buildFieldLabel('Email (Informasi Akun)'),
          const SizedBox(height: 6),
          _buildReadOnlyEmailField(),
          const SizedBox(height: 20),

          // 2. Nama Lengkap (Required)
          _buildFieldLabel('Nama Lengkap *'),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller.namaLengkapController,
            validator: controller.validateNamaLengkap,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            decoration: _inputDecoration(
              hintText: 'Masukkan nama lengkap',
              prefixIcon: Icons.person_outline_rounded,
            ),
          ),
          const SizedBox(height: 20),

          // 3. Nomor HP (Optional)
          _buildFieldLabel('Nomor HP'),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller.noHpController,
            validator: controller.validateNoHp,
            keyboardType: TextInputType.phone,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            decoration: _inputDecoration(
              hintText: 'Contoh: 081234567890',
              prefixIcon: Icons.phone_outlined,
            ),
          ),
          const SizedBox(height: 20),

          // 4. Tanggal Lahir (Optional Date Picker)
          _buildFieldLabel('Tanggal Lahir'),
          const SizedBox(height: 6),
          _buildDatePickerField(context),
          const SizedBox(height: 20),

          // 5. Jenis Kelamin (Optional Dropdown)
          _buildFieldLabel('Jenis Kelamin'),
          const SizedBox(height: 6),
          _buildGenderDropdown(context),
        ],
      ),
    );
  }

  /// Field read-only untuk email
  Widget _buildReadOnlyEmailField() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.mail_outline_rounded,
            size: 20,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              controller.emailController.text.isNotEmpty
                  ? controller.emailController.text
                  : 'Email akun terdaftar',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Tetap',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Date picker field interaktif
  Widget _buildDatePickerField(BuildContext context) {
    return Obx(() {
      final selectedDate = controller.tanggalLahir.value;
      final hasDate = selectedDate != null;

      return InkWell(
        onTap: () => _pickDate(context),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 20,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  hasDate ? _formatDate(selectedDate) : 'Pilih tanggal',
                  style: TextStyle(
                    fontSize: 14,
                    color: hasDate
                        ? AppColors.textPrimary
                        : AppColors.textSecondary.withValues(alpha: 0.7),
                    fontWeight: hasDate ? FontWeight.w600 : FontWeight.w400,
                    fontStyle: hasDate ? FontStyle.normal : FontStyle.italic,
                  ),
                ),
              ),
              if (hasDate)
                IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () => controller.setTanggalLahir(null),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Hapus tanggal',
                )
              else
                const Icon(
                  Icons.arrow_drop_down_rounded,
                  color: AppColors.textSecondary,
                ),
            ],
          ),
        ),
      );
    });
  }

  /// Dropdown pilihan jenis kelamin
  Widget _buildGenderDropdown(BuildContext context) {
    return Obx(() {
      final selected = controller.jenisKelamin.value;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            value: (selected != null &&
                    (selected == 'Laki-laki' || selected == 'Perempuan'))
                ? selected
                : null,
            hint: Row(
              children: [
                const Icon(
                  Icons.wc_outlined,
                  size: 20,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Pilih jenis kelamin',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            icon: const Icon(
              Icons.arrow_drop_down_rounded,
              color: AppColors.textSecondary,
            ),
            items: const [
              DropdownMenuItem(
                value: 'Laki-laki',
                child: Row(
                  children: [
                    Icon(
                      Icons.male_rounded,
                      size: 20,
                      color: AppColors.secondary,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Laki-laki',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: 'Perempuan',
                child: Row(
                  children: [
                    Icon(
                      Icons.female_rounded,
                      size: 20,
                      color: AppColors.secondary,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Perempuan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            onChanged: (value) {
              controller.setJenisKelamin(value);
            },
          ),
        ),
      );
    });
  }

  /// Tombol simpan perubahan dengan state loading terproteksi
  Widget _buildSaveButton() {
    return Obx(() {
      final isSaving = controller.isSaving.value;

      return SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: isSaving ? null : () => controller.saveProfile(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: isSaving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : const Text(
                  'Simpan Perubahan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
        ),
      );
    });
  }

  /// Label teks setiap input field
  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  /// Dekorasi input form yang seragam
  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        fontSize: 14,
        color: AppColors.textSecondary.withValues(alpha: 0.6),
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: Icon(
        prefixIcon,
        size: 20,
        color: AppColors.secondary,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      filled: true,
      fillColor: AppColors.card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE53E3E)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE53E3E), width: 1.5),
      ),
    );
  }

  /// Menampilkan Flutter date picker
  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final initialDate = controller.tanggalLahir.value ?? DateTime(2000, 1, 1);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(now) ? now : initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      controller.setTanggalLahir(picked);
    }
  }

  /// Helper format tanggal (dd MMMM yyyy)
  String _formatDate(DateTime date) {
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
}
