import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/profile_model.dart';
import '../../../data/repositories/profile_repository.dart';

class EditProfileController extends GetxController {
  final ProfileRepository? _profileRepository;
  final SupabaseClient? _supabaseClient;

  EditProfileController({
    ProfileRepository? profileRepository,
    SupabaseClient? supabaseClient,
  })  : _profileRepository = profileRepository,
        _supabaseClient = supabaseClient;

  ProfileRepository get _repository {
    if (_profileRepository != null) return _profileRepository;
    if (Get.isRegistered<ProfileRepository>()) {
      return Get.find<ProfileRepository>();
    }
    return ProfileRepository();
  }

  final formKey = GlobalKey<FormState>();

  final namaLengkapController = TextEditingController();
  final noHpController = TextEditingController();
  final emailController = TextEditingController();

  final tanggalLahir = Rxn<DateTime>();
  final jenisKelamin = RxnString();

  final isLoading = false.obs;
  final isSaving = false.obs;
  final errorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    _initData();
  }

  void _initData() {
    if (Get.arguments is ProfileModel) {
      final initialProfile = Get.arguments as ProfileModel;
      _populateFromProfile(initialProfile);
    } else {
      loadInitialProfile();
    }
  }

  void _populateFromProfile(ProfileModel p) {
    namaLengkapController.text = p.namaLengkap ?? '';
    noHpController.text = p.noHp ?? '';

    String? userEmail = p.email;
    if (userEmail == null || userEmail.isEmpty) {
      try {
        final client = _supabaseClient ?? Supabase.instance.client;
        userEmail = client.auth.currentUser?.email;
      } catch (_) {
        userEmail = null;
      }
    }
    emailController.text = userEmail ?? '';

    tanggalLahir.value = p.tanggalLahir;

    if (p.jenisKelamin != null && p.jenisKelamin!.trim().isNotEmpty) {
      final norm = p.jenisKelamin!.trim().toLowerCase();
      if (norm == 'l' || norm == 'laki-laki' || norm == 'male') {
        jenisKelamin.value = 'Laki-laki';
      } else if (norm == 'p' || norm == 'perempuan' || norm == 'female') {
        jenisKelamin.value = 'Perempuan';
      } else {
        jenisKelamin.value = p.jenisKelamin!.trim();
      }
    } else {
      jenisKelamin.value = null;
    }
  }

  Future<void> loadInitialProfile() async {
    try {
      isLoading.value = true;
      errorMessage.value = null;

      final p = await _repository.getMyProfile();
      if (p != null) {
        _populateFromProfile(p);
      } else {
        try {
          final client = _supabaseClient ?? Supabase.instance.client;
          emailController.text = client.auth.currentUser?.email ?? '';
        } catch (_) {
          emailController.text = '';
        }
      }
    } catch (_) {
      errorMessage.value = 'Gagal memuat data profil awal.';
    } finally {
      isLoading.value = false;
    }
  }

  String? validateNamaLengkap(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nama lengkap wajib diisi';
    }
    if (value.trim().length < 2) {
      return 'Nama lengkap minimal 2 karakter';
    }
    return null;
  }

  String? validateNoHp(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final trimmed = value.trim();
    final phoneRegex = RegExp(r'^[0-9+\-\s()]{7,20}$');
    if (!phoneRegex.hasMatch(trimmed)) {
      return 'Format nomor HP tidak valid';
    }
    return null;
  }

  void setTanggalLahir(DateTime? date) {
    tanggalLahir.value = date;
  }

  void setJenisKelamin(String? value) {
    jenisKelamin.value = value;
  }

  Future<void> saveProfile() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    String? userId;
    try {
      final client = _supabaseClient ?? Supabase.instance.client;
      userId = client.auth.currentUser?.id;
    } catch (_) {
      userId = null;
    }

    if (userId == null) {
      Get.snackbar(
        'Gagal',
        'Sesi telah berakhir. Silakan login kembali.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFE53E3E),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    try {
      isSaving.value = true;
      errorMessage.value = null;

      await _repository.updateMyProfile(
        namaLengkap: namaLengkapController.text.trim(),
        noHp: noHpController.text.trim(),
        tanggalLahir: tanggalLahir.value,
        jenisKelamin: jenisKelamin.value,
        clearTanggalLahir: tanggalLahir.value == null,
      );

      Get.snackbar(
        'Berhasil',
        'Profil berhasil diperbarui.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.primary,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
      );

      Get.back(result: true);
    } catch (_) {
      errorMessage.value = 'Profil gagal diperbarui. Silakan coba lagi.';
      Get.snackbar(
        'Gagal',
        'Profil gagal diperbarui. Silakan coba lagi.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFE53E3E),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(16),
      );
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    namaLengkapController.dispose();
    noHpController.dispose();
    emailController.dispose();
    super.onClose();
  }
}
