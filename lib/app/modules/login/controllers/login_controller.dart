import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../routes/app_routes.dart';

class LoginController extends GetxController {
  final SupabaseClient? _supabaseClient;

  LoginController({SupabaseClient? supabaseClient})
      : _supabaseClient = supabaseClient;

  SupabaseClient get _client => _supabaseClient ?? Supabase.instance.client;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final formKey = GlobalKey<FormState>();

  final isLoading = false.obs;
  final isPasswordHidden = true.obs;

  void togglePasswordVisibility() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email wajib diisi';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Format email tidak valid';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password wajib diisi';
    }
    if (value.length < 8) {
      return 'Password minimal 8 karakter';
    }
    return null;
  }

  Future<void> login() async {
    if (formKey.currentState != null) {
      if (!formKey.currentState!.validate()) {
        return;
      }
    } else {
      if (validateEmail(emailController.text) != null ||
          validatePassword(passwordController.text) != null) {
        return;
      }
    }

    final email = emailController.text.trim();
    final password = passwordController.text;

    isLoading.value = true;

    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // Verifikasi status konfirmasi email
      final isEmailConfirmed = response.user?.emailConfirmedAt != null;

      if (!isEmailConfirmed) {
        // Sign out segera jika email belum terkonfirmasi
        await _client.auth.signOut();
        isLoading.value = false;

        Get.snackbar(
          'Verifikasi Diperlukan',
          'Email belum diverifikasi. Silakan cek email Anda terlebih dahulu.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFE53E3E),
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
          margin: const EdgeInsets.all(16),
        );
        return;
      }

      isLoading.value = false;

      Get.snackbar(
        'Login Berhasil',
        'Selamat datang kembali di MIND DRIJI!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF00BFA5),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
      );

      // Navigasi ke halaman Home setelah login sukses
      Get.offAllNamed(Routes.home);
    } on AuthException catch (e) {
      isLoading.value = false;
      String errorMessage;

      final messageLower = e.message.toLowerCase();
      if (messageLower.contains('invalid login credentials') ||
          messageLower.contains('invalid_credentials') ||
          messageLower.contains('invalid email or password')) {
        errorMessage = 'Email atau password salah.';
      } else if (messageLower.contains('email not confirmed') ||
          messageLower.contains('not confirmed')) {
        errorMessage =
            'Email belum diverifikasi. Silakan cek email Anda terlebih dahulu.';
      } else {
        errorMessage = e.message;
      }

      Get.snackbar(
        'Gagal Masuk',
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
        'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFE53E3E),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(16),
      );
    }
  }

  void onForgotPassword() {
    Get.snackbar(
      'Lupa Password',
      'Fitur reset password akan segera hadir pada tahap berikutnya.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF102A43),
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
    );
  }

  void goToRegister() {
    Get.toNamed(Routes.register);
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
