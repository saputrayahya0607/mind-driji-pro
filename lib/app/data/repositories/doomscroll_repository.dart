import 'package:get/get.dart';
import '../local/app_database.dart';
import '../local/repositories/doomscroll_local_repository.dart';
import '../models/doomscroll_live_session.dart';
import '../providers/doomscroll_native_provider.dart';

/// Repository untuk Doomscroll Monitoring yang mengorkestrasi
/// Native Accessibility Provider dan Drift Local Database
class DoomscrollRepository {
  final DoomscrollNativeProvider _provider;
  final DoomscrollLocalRepository _localRepository;

  DoomscrollRepository({
    DoomscrollNativeProvider? provider,
    DoomscrollLocalRepository? localRepository,
  })  : _provider = provider ?? DoomscrollNativeProvider(),
        _localRepository = localRepository ??
            (Get.isRegistered<DoomscrollLocalRepository>()
                ? Get.find<DoomscrollLocalRepository>()
                : DoomscrollLocalRepository());

  /// Stream event sesi doomscroll realtime dari native Android
  Stream<DoomscrollLiveSession> liveSessionStream() {
    return _provider.liveSessionStream();
  }

  /// Memeriksa status izin Accessibility Service di sistem Android
  Future<bool> checkAccessibilityService() {
    return _provider.checkAccessibilityService();
  }

  /// Membuka pengaturan Accessibility Android
  Future<bool> openAccessibilitySettings() {
    return _provider.openAccessibilitySettings();
  }

  /// Mengambil antrean sesi dari native SharedPreferences,
  /// menyimpannya secara transactional ke SQLite lokal (Drift),
  /// dan mengosongkan antrean native jika penyimpanan berhasil.
  Future<int> collectAndPersistPendingSessions() async {
    try {
      final nativeSessions = await _provider.flushCurrentDoomscrollSession();
      if (nativeSessions.isEmpty) return 0;

      await _localRepository.insertSessions(nativeSessions);
      await _provider.clearPendingDoomscrollSessions();
      return nativeSessions.length;
    } catch (e) {
      // Jika insert ke Drift gagal, JANGAN hapus native queue
      return 0;
    }
  }

  /// Membaca daftar riwayat sesi doomscroll lokal dari database Drift
  Future<List<DoomscrollSessionData>> getStoredSessions({int limit = 50}) {
    return _localRepository.getSessions(limit: limit);
  }

  /// Membaca daftar sesi doomscroll dalam rentang waktu tertentu
  Future<List<DoomscrollSessionData>> getSessionsBetween({
    required DateTime start,
    required DateTime end,
    String? userId,
  }) {
    return _localRepository.getSessionsBetween(start: start, end: end, userId: userId);
  }

  /// Mengklaim sesi doomscroll lokal untuk user yang baru login
  Future<int> claimLocalSessions(String authenticatedUserId) {
    return _localRepository.claimLocalSessions(authenticatedUserId);
  }
}
