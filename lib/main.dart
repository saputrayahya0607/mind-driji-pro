import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/bindings/initial_binding.dart';
import 'app/core/constants/app_strings.dart';
import 'app/core/theme/app_theme.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'supabase_config.dart';

/// Menentukan rute awal aplikasi berdasarkan status sesi Supabase Auth yang tersimpan.
/// Dengan menentukan rute awal langsung ke Home atau Login, aplikasi bertransisi
/// mulus langsung dari Native Launch Splash Screen tanpa menampilkan splash screen ganda di Flutter.
Future<String> determineInitialRoute([SupabaseClient? client]) async {
  try {
    final supabase = client ?? Supabase.instance.client;
    final session = supabase.auth.currentSession;

    if (session == null) {
      return Routes.login;
    }

    if (!session.isExpired) {
      return Routes.home;
    }

    // Jika token kedaluwarsa, coba segarkan sesi
    try {
      final response = await supabase.auth.refreshSession();
      if (response.session != null && !response.session!.isExpired) {
        return Routes.home;
      }
    } catch (_) {
      // Refresh gagal (misalnya token di-revoke atau offline dan expired)
    }

    return Routes.login;
  } catch (_) {
    return Routes.login;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    publishableKey: SupabaseConfig.supabasePublishableKey,
  );

  final initialRoute = await determineInitialRoute();

  runApp(MindDrjiApp(initialRoute: initialRoute));
}

class MindDrjiApp extends StatelessWidget {
  final String? initialRoute;

  const MindDrjiApp({super.key, this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialBinding: InitialBinding(),
      initialRoute: initialRoute ?? AppPages.initial,
      getPages: AppPages.routes,
    );
  }
}
