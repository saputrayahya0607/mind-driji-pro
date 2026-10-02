import '../../providers/intervention_native_provider.dart';

/// Kontrak antarmuka eksekusi Focus Mode.
///
/// PENTING:
/// Focus Mode pada MIND DRIJI dirancang sebagai intervensi soft-blocking
/// melalui Accessibility Service yang sadar privasi. Bukan Kiosk mode,
/// bukan Device Owner, dan tidak mengklaim hard blocking universal.
abstract class FocusModeExecutor {
  /// Memulai sesi Focus Mode dengan durasi tertentu.
  /// Mengembalikan true jika executor berhasil diinisialisasi.
  Future<bool> start({
    String? id,
    required Duration duration,
    List<String>? targetPackages,
  });

  /// Menghentikan sesi Focus Mode secara aman.
  Future<void> stop();

  /// Memeriksa apakah perangkat dan versi Android mendukung mekanisme ini.
  Future<bool> isSupported();

  /// Daftar package yang dikecualikan (whitelist), seperti aplikasi MIND DRIJI,
  /// dialer darurat, dan launcher sistem.
  List<String> get whitelistedPackages;

  /// Status apakah executor sedang berjalan aktif
  bool get isRunning;
}

/// Implementasi nyata Focus Mode berbasis Accessibility Soft-Blocking.
/// Menghubungkan InterventionService dengan platform Android via InterventionNativeProvider.
class AccessibilityFocusModeExecutor implements FocusModeExecutor {
  final InterventionNativeProvider _nativeProvider;
  bool _isRunning = false;

  AccessibilityFocusModeExecutor({
    InterventionNativeProvider? nativeProvider,
  }) : _nativeProvider = nativeProvider ?? InterventionNativeProvider();

  @override
  Future<bool> isSupported() async {
    // Accessibility Soft Blocking didukung pada Android melalui DoomscrollAccessibilityService
    return true;
  }

  @override
  Future<bool> start({
    String? id,
    required Duration duration,
    List<String>? targetPackages,
  }) async {
    final effectiveId = id ?? 'focus_${DateTime.now().millisecondsSinceEpoch}';
    final durationMinutes = duration.inMinutes > 0 ? duration.inMinutes : 1;
    final endMillis = DateTime.now().add(duration).millisecondsSinceEpoch;

    final success = await _nativeProvider.startFocusMode(
      id: effectiveId,
      durationMinutes: durationMinutes,
      endTimestampMillis: endMillis,
    );

    _isRunning = success;
    return success;
  }

  @override
  Future<void> stop() async {
    await _nativeProvider.stopFocusMode();
    _isRunning = false;
  }

  @override
  List<String> get whitelistedPackages => const [
        'com.hn.mind_drji',
        'com.android.systemui',
        'com.android.settings',
        'com.android.dialer',
        'com.google.android.dialer',
      ];

  @override
  bool get isRunning => _isRunning;
}

/// Implementasi stub ter-audit untuk tahap verifikasi audit dan fallback.
class AuditedFocusModeExecutor implements FocusModeExecutor {
  bool _isRunning = false;

  @override
  Future<bool> isSupported() async {
    return false;
  }

  @override
  Future<bool> start({
    String? id,
    required Duration duration,
    List<String>? targetPackages,
  }) async {
    _isRunning = false;
    return false;
  }

  @override
  Future<void> stop() async {
    _isRunning = false;
  }

  @override
  List<String> get whitelistedPackages => const [
        'com.hn.mind_drji',
        'com.android.systemui',
        'com.android.settings',
        'com.android.dialer',
        'com.google.android.dialer',
      ];

  @override
  bool get isRunning => _isRunning;
}
