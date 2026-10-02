import 'dart:async';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../routes/app_routes.dart';

/// Controller untuk Splash Screen.
/// Mengelola pengecekan Supabase Auth session persistence saat startup aplikasi.
///
/// Flow:
/// Splash
///   ↓
/// Supabase currentSession
///   ↓
/// session != null && !isExpired → Home
/// session != null && isExpired  → Coba refresh → Sukses: Home, Gagal: Login
/// session == null               → Login
class SplashController extends GetxController {
  final SupabaseClient? _supabaseClient;
  final Duration delay;
  Timer? _navigationTimer;

  SplashController({
    SupabaseClient? supabaseClient,
    this.delay = const Duration(seconds: 2),
  }) : _supabaseClient = supabaseClient;

  SupabaseClient? get _client {
    if (_supabaseClient != null) return _supabaseClient;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  @override
  void onReady() {
    super.onReady();
    if (delay > Duration.zero) {
      _navigationTimer = Timer(delay, () {
        checkSessionAndNavigate();
      });
    } else {
      checkSessionAndNavigate();
    }
  }

  /// Memeriksa sesi Supabase Auth yang tersimpan secara lokal.
  Future<void> checkSessionAndNavigate() async {
    _navigationTimer?.cancel();
    final client = _client;

    if (client == null) {
      Get.offAllNamed(Routes.login);
      return;
    }

    final session = client.auth.currentSession;
    if (session == null) {
      Get.offAllNamed(Routes.login);
      return;
    }

    if (!session.isExpired) {
      Get.offAllNamed(Routes.home);
      return;
    }

    // Jika token kedaluwarsa, coba segarkan session
    try {
      final response = await client.auth.refreshSession();
      if (response.session != null && !response.session!.isExpired) {
        Get.offAllNamed(Routes.home);
      } else {
        Get.offAllNamed(Routes.login);
      }
    } catch (_) {
      // Refresh gagal (misalnya token di-revoke atau offline dan expired)
      Get.offAllNamed(Routes.login);
    }
  }

  /// Navigasi manual saat tombol di SplashView ditekan
  void navigateManually() {
    _navigationTimer?.cancel();
    checkSessionAndNavigate();
  }

  /// Kompatibilitas mundur
  void navigateToLogin() {
    _navigationTimer?.cancel();
    Get.offAllNamed(Routes.login);
  }

  @override
  void onClose() {
    _navigationTimer?.cancel();
    super.onClose();
  }
}
