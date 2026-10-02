import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../routes/app_routes.dart';

class RegisterController extends GetxController {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final formKey = GlobalKey<FormState>();

  final isLoading = false.obs;
  final isPasswordHidden = true.obs;
  final isConfirmPasswordHidden = true.obs;

  void togglePasswordVisibility() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordHidden.value = !isConfirmPasswordHidden.value;
  }

  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nama lengkap tidak boleh kosong';
    }
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email tidak boleh kosong';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Format email tidak valid';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password tidak boleh kosong';
    }
    if (value.length < 8) {
      return 'Password minimal 8 karakter';
    }
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi password tidak boleh kosong';
    }
    if (value != passwordController.text) {
      return 'Konfirmasi password harus sama';
    }
    return null;
  }

  Future<void> register() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    final nama = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;

    isLoading.value = true;

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'nama_lengkap': nama,
        },
      );

      isLoading.value = false;

      if (response.session == null) {
        Get.snackbar(
          'Registrasi Berhasil',
          'Registrasi berhasil. Silakan periksa email untuk melakukan verifikasi sebelum login.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF00BFA5),
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
          margin: const EdgeInsets.all(16),
        );
      } else {
        Get.snackbar(
          'Registrasi Berhasil',
          'Akun berhasil dibuat. Selamat datang di MIND DRIJI!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF00BFA5),
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
          margin: const EdgeInsets.all(16),
        );
      }

      // Beri jeda singkat agar user dapat membaca pesan feedback sebelum kembali ke login
      await Future.delayed(const Duration(milliseconds: 1500));
      Get.offNamed(Routes.login);
    } on AuthException catch (e) {
      isLoading.value = false;
      String errorMessage;

      final messageLower = e.message.toLowerCase();
      if (messageLower.contains('already registered') ||
          messageLower.contains('already in use') ||
          messageLower.contains('user already exists')) {
        errorMessage =
            'Email sudah terdaftar. Silakan gunakan email lain atau langsung login.';
      } else if (messageLower.contains('password')) {
        errorMessage = 'Password terlalu lemah atau tidak memenuhi syarat.';
      } else {
        errorMessage = e.message;
      }

      Get.snackbar(
        'Gagal Mendaftar',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFE53E3E),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(16),
      );
    } catch (_) {
      isLoading.value = false;
      Get.snackbar(
        'Terjadi Kesalahan',
        'Tidak dapat terhubung ke layanan. Silakan periksa koneksi internet Anda dan coba lagi.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFE53E3E),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(16),
      );
    }
  }

  void navigateToLogin() {
    Get.offNamed(Routes.login);
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
