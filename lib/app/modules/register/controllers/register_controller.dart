import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../supabase_config.dart';
import '../../../routes/app_routes.dart';

class RegisterController extends GetxController {
  final SupabaseClient? _supabaseClient;

  RegisterController({SupabaseClient? supabaseClient})
      : _supabaseClient = supabaseClient;

  SupabaseClient get _client => _supabaseClient ?? Supabase.instance.client;

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
    if (isLoading.value) return;

    if (formKey.currentState != null) {
      if (!formKey.currentState!.validate()) {
        return;
      }
    } else {
      if (validateName(nameController.text) != null ||
          validateEmail(emailController.text) != null ||
          validatePassword(passwordController.text) != null ||
          validateConfirmPassword(confirmPasswordController.text) != null) {
        return;
      }
    }

    final nama = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;

    isLoading.value = true;

    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: SupabaseConfig.authCallbackUrl,
        data: {
          'nama_lengkap': nama,
        },
      );

      isLoading.value = false;

      if (response.session == null) {
        _showSnackbar(
          'Registrasi Berhasil',
          'Registrasi berhasil. Silakan periksa email untuk melakukan verifikasi sebelum login.',
          backgroundColor: const Color(0xFF00BFA5),
          duration: const Duration(seconds: 5),
        );
      } else {
        _showSnackbar(
          'Registrasi Berhasil',
          'Akun berhasil dibuat. Selamat datang di MIND DRIJI!',
          backgroundColor: const Color(0xFF00BFA5),
          duration: const Duration(seconds: 4),
        );
      }

      // Beri jeda singkat agar user dapat membaca pesan feedback sebelum kembali ke login
      if (Get.overlayContext != null || Get.context != null) {
        await Future.delayed(const Duration(milliseconds: 1500));
        Get.offNamed(Routes.login);
      }
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

      _showSnackbar(
        'Gagal Mendaftar',
        errorMessage,
        backgroundColor: const Color(0xFFE53E3E),
        duration: const Duration(seconds: 4),
      );
    } catch (_) {
      isLoading.value = false;
      _showSnackbar(
        'Terjadi Kesalahan',
        'Tidak dapat terhubung ke layanan. Silakan periksa koneksi internet Anda dan coba lagi.',
        backgroundColor: const Color(0xFFE53E3E),
        duration: const Duration(seconds: 4),
      );
    }
  }

  void _showSnackbar(
    String title,
    String message, {
    Color? backgroundColor,
    Duration? duration,
  }) {
    if (Get.overlayContext != null || Get.context != null) {
      Get.snackbar(
        title,
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: backgroundColor ?? const Color(0xFF00BFA5),
        colorText: Colors.white,
        duration: duration ?? const Duration(seconds: 4),
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
