import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../routes/app_routes.dart';

/// Service pusat untuk menangani siklus hidup autentikasi dan callback deep link
/// verifikasi email Supabase Auth.
class AuthService extends GetxService {
  final SupabaseClient? _supabase;

  StreamSubscription<AuthState>? _authSubscription;

  bool _isHandlingAuthCallback = false;
  bool get isHandlingAuthCallback => _isHandlingAuthCallback;

  AuthService({SupabaseClient? supabase}) : _supabase = supabase;

  static AuthService get to {
    if (Get.isRegistered<AuthService>()) {
      return Get.find<AuthService>();
    }
    final service = AuthService();
    Get.put<AuthService>(service, permanent: true);
    return service;
  }

  static SupabaseClient? _safeGetSupabaseClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  SupabaseClient? get _client => _supabase ?? _safeGetSupabaseClient();

  @override
  void onInit() {
    super.onInit();
    _listenToAuthChanges();
  }

  String? lastFeedbackTitle;
  String? lastFeedbackMessage;

  void _showSnackbar(String title, String message, {Color? backgroundColor}) {
    lastFeedbackTitle = title;
    lastFeedbackMessage = message;
    if (Get.overlayContext != null || Get.context != null) {
      Get.snackbar(
        title,
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: backgroundColor ?? const Color(0xFF00BFA5),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(16),
      );
    }
  }

  void _listenToAuthChanges() {
    final client = _client;
    if (client == null) return;

    try {
      _authSubscription = client.auth.onAuthStateChange.listen(
        _onAuthStateChange,
        onError: (error) {
          _isHandlingAuthCallback = false;
          String message =
              'Verifikasi email gagal atau tautan telah kedaluwarsa.';
          if (error is AuthException) {
            message = error.message;
          }
          _showSnackbar(
            'Verifikasi Gagal',
            message,
            backgroundColor: const Color(0xFFE53E3E),
          );
        },
      );
    } catch (_) {
      // Supabase auth stream error guard
    }
  }

  /// Memproses URI callback autentikasi dari Supabase (minddriji://auth-callback)
  Future<void> handleDeepLink(Uri uri) async {
    // Hanya proses skema dan host yang sesuai
    if (uri.scheme != 'minddriji' || uri.host != 'auth-callback') {
      return;
    }

    // Hindari pemrosesan callback ganda jika sedang berjalan
    if (_isHandlingAuthCallback) {
      return;
    }

    final fragmentParams = Uri.splitQueryString(uri.fragment);
    final error = uri.queryParameters['error'] ?? fragmentParams['error'];
    final errorDesc =
        uri.queryParameters['error_description'] ??
        fragmentParams['error_description'];

    // Jika Supabase menyertakan parameter error pada redirect URL
    if (error != null || errorDesc != null) {
      _isHandlingAuthCallback = false;
      final message =
          errorDesc ??
          error ??
          'Tautan verifikasi tidak valid atau telah kedaluwarsa.';
      _showSnackbar(
        'Verifikasi Gagal',
        message,
        backgroundColor: const Color(0xFFE53E3E),
      );
      return;
    }

    _isHandlingAuthCallback = true;

    // SDK supabase_flutter biasanya memproses getSessionFromUrl via internal deep link listener.
    // Jika sesi belum aktif, lakukan fallback pemanggilan getSessionFromUrl secara aman.
    final client = _client;
    if (client != null && client.auth.currentSession == null) {
      try {
        await client.auth.getSessionFromUrl(uri);
      } catch (e) {
        _isHandlingAuthCallback = false;
        String errorMessage =
            'Verifikasi email gagal atau tautan telah kedaluwarsa.';
        if (e is AuthException) {
          errorMessage = e.message;
        }
        _showSnackbar(
          'Verifikasi Gagal',
          errorMessage,
          backgroundColor: const Color(0xFFE53E3E),
        );
      }
    }
  }

  void _onAuthStateChange(AuthState state) {
    if (state.event == AuthChangeEvent.signedIn && state.session != null) {
      final wasAuthCallback = _isHandlingAuthCallback;
      _isHandlingAuthCallback = false;

      final currentRoute = Get.currentRoute;
      final shouldNavigate =
          wasAuthCallback ||
          currentRoute == Routes.login ||
          currentRoute == Routes.register ||
          currentRoute == Routes.splash;

      if (shouldNavigate && currentRoute != Routes.home) {
        Get.offAllNamed(Routes.home);

        _showSnackbar(
          'Verifikasi Berhasil',
          'Email berhasil diverifikasi! Selamat datang di MIND DRIJI.',
          backgroundColor: const Color(0xFF00BFA5),
        );
      }
    }
  }

  @override
  void onClose() {
    _authSubscription?.cancel();
    super.onClose();
  }
}
