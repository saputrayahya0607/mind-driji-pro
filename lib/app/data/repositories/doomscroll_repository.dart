import 'dart:async';
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
  Future<void> _flushLock = Future.value();

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
  /// memvalidasi payload dan ID, menyimpannya ke Drift SQLite secara aman,
  /// dan hanya meng-acknowledge ID sesi yang berhasil disimpan ke native queue.
  /// Operasi serial aman dari pemanggilan konkruen.
  Future<int> collectAndPersistPendingSessions() async {
    final prevLock = _flushLock;
    final completer = Completer<void>();
    _flushLock = completer.future;

    try {
      await prevLock;
    } catch (_) {}

    try {
      return await _doCollectAndPersistPendingSessions();
    } finally {
      completer.complete();
    }
  }

  Future<int> _doCollectAndPersistPendingSessions() async {
    try {
      final nativeSessions = await _provider.flushCurrentDoomscrollSession();
      if (nativeSessions.isEmpty) return 0;

      final acknowledgedIds = <String>[];
      for (final session in nativeSessions) {
        // Validasi payload dan ID
        if (session.id.isEmpty ||
            session.packageName.isEmpty ||
            session.swipeCount <= 0) {
          continue;
        }

        try {
          await _localRepository.insertSession(session);
          acknowledgedIds.add(session.id);
        } catch (_) {
          // Gagal persist lokal: jangan acknowledge ID ini agar bisa dicoba ulang
        }
      }

      if (acknowledgedIds.isNotEmpty) {
        await _provider.clearPendingDoomscrollSessions(
          sessionIds: acknowledgedIds,
        );
      }

      return acknowledgedIds.length;
    } catch (e) {
      // Jika terjadi exception tak terduga, jangan hapus native queue
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
