import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/target_app_model.dart';
import '../../../data/providers/doomscroll_native_provider.dart';

enum TargetAppFilter { all, monitored, defaults }

class TargetAppsController extends GetxController {
  final DoomscrollNativeProvider _provider;

  TargetAppsController({DoomscrollNativeProvider? provider})
      : _provider = provider ?? DoomscrollNativeProvider();

  final isLoading = false.obs;
  final isSaving = false.obs;
  final searchQuery = ''.obs;
  final currentFilter = TargetAppFilter.all.obs;

  final installedApps = <TargetAppModel>[].obs;
  final searchController = TextEditingController();

  /// Default fallback list jika platform channel mengembalikan list kosong (misal di test/simulator)
  static final List<TargetAppModel> fallbackDefaultApps = [
    const TargetAppModel(
      packageName: 'com.ss.android.ugc.trill',
      appName: 'TikTok (Indonesia)',
      isMonitored: true,
      isDefault: true,
    ),
    const TargetAppModel(
      packageName: 'com.zhiliaoapp.musically',
      appName: 'TikTok (Global)',
      isMonitored: true,
      isDefault: true,
    ),
    const TargetAppModel(
      packageName: 'com.instagram.android',
      appName: 'Instagram',
      isMonitored: true,
      isDefault: true,
    ),
    const TargetAppModel(
      packageName: 'com.google.android.youtube',
      appName: 'YouTube',
      isMonitored: true,
      isDefault: true,
    ),
    const TargetAppModel(
      packageName: 'com.snapchat.android',
      appName: 'Snapchat',
      isMonitored: true,
      isDefault: true,
    ),
    const TargetAppModel(
      packageName: 'com.twitter.android',
      appName: 'X (Twitter)',
      isMonitored: true,
      isDefault: true,
    ),
    const TargetAppModel(
      packageName: 'com.facebook.katana',
      appName: 'Facebook',
      isMonitored: true,
      isDefault: true,
    ),
  ];

  @override
  void onInit() {
    super.onInit();
    loadApps();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  /// Memuat daftar seluruh aplikasi yang terpasang
  Future<void> loadApps() async {
    isLoading.value = true;
    try {
      final apps = await _provider.getInstalledApps();
      if (apps.isNotEmpty) {
        installedApps.assignAll(apps);
      } else {
        // Cek target packages yang aktif
        final monitored = await _provider.getTargetPackages();
        if (monitored.isNotEmpty) {
          installedApps.assignAll(monitored);
        } else {
          installedApps.assignAll(fallbackDefaultApps);
        }
      }
    } catch (_) {
      installedApps.assignAll(fallbackDefaultApps);
    } finally {
      isLoading.value = false;
    }
  }

  /// Toggle status pemantauan untuk satu aplikasi
  void toggleApp(TargetAppModel app, bool newValue) {
    final index = installedApps
        .indexWhere((element) => element.packageName == app.packageName);
    if (index != -1) {
      installedApps[index] = app.copyWith(isMonitored: newValue);
    }
  }

  /// Simpan perubahan target apps ke native layer
  Future<bool> saveTargetApps() async {
    isSaving.value = true;
    try {
      final monitoredApps =
          installedApps.where((app) => app.isMonitored).toList();
      final success = await _provider.saveTargetPackages(monitoredApps);
      if (success) {
        if (Get.context != null) {
          Get.snackbar(
            'Berhasil Disimpan',
            '${monitoredApps.length} aplikasi target pemantauan diperbarui.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFFDCFCE7),
            colorText: const Color(0xFF15803D),
            margin: const EdgeInsets.all(16),
            borderRadius: 12,
            duration: const Duration(seconds: 2),
          );
        }
      }
      return success;
    } catch (_) {
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  /// Reset target apps ke konfigurasi bawaan
  Future<void> resetToDefault() async {
    isLoading.value = true;
    try {
      await _provider.resetTargetPackagesToDefault();
      await loadApps();
      if (Get.context != null) {
        Get.snackbar(
          'Pengaturan Direset',
          'Daftar aplikasi target dikembalikan ke preset bawaan.',
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  /// Total aplikasi yang saat ini dipantau
  int get monitoredCount =>
      installedApps.where((app) => app.isMonitored).length;

  /// Daftar aplikasi yang sudah difilter berdasarkan pencarian dan tab filter
  List<TargetAppModel> get filteredApps {
    var list = installedApps.toList();

    // 1. Filter Tab
    switch (currentFilter.value) {
      case TargetAppFilter.monitored:
        list = list.where((app) => app.isMonitored).toList();
        break;
      case TargetAppFilter.defaults:
        list = list.where((app) => app.isDefault).toList();
        break;
      case TargetAppFilter.all:
        break;
    }

    // 2. Filter Search Query
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((app) {
        final nameMatch = app.appName.toLowerCase().contains(query);
        final pkgMatch = app.packageName.toLowerCase().contains(query);
        return nameMatch || pkgMatch;
      }).toList();
    }

    // Urutkan: aplikasi yang dipantau di atas, kemudian alfabetis
    list.sort((a, b) {
      if (a.isMonitored != b.isMonitored) {
        return a.isMonitored ? -1 : 1;
      }
      return a.appName.toLowerCase().compareTo(b.appName.toLowerCase());
    });

    return list;
  }
}
