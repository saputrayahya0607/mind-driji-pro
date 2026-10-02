import 'package:drift/drift.dart';
import 'package:get/get.dart' hide Value;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/uuid_generator.dart';
import '../../models/doomscroll_session_model.dart';
import '../../services/device_service.dart';
import '../app_database.dart';
import '../tables/sync_queue.dart';

/// Repository lokal untuk menyimpan dan mengelola Doomscroll Session di SQLite via Drift.
/// Menerapkan prinsip offline-first dan memastikan userId selalu diambil dari sesi autentikasi Supabase.
class DoomscrollLocalRepository {
  final AppDatabase _db;
  final SupabaseClient? _supabase;

  DoomscrollLocalRepository({AppDatabase? db, SupabaseClient? supabase})
      : _db = db ?? AppDatabase(),
        _supabase = supabase ?? _safeGetSupabaseClient();

  AppDatabase get db => _db;

  static SupabaseClient? _safeGetSupabaseClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Mendapatkan ID pengguna yang terautentikasi saat ini
  String get _currentUserId {
    final client = _supabase ?? _safeGetSupabaseClient();
    return client?.auth.currentUser?.id ?? 'local_user';
  }

  String _resolveDeviceId([String? deviceId]) {
    if (deviceId != null && deviceId.isNotEmpty) return deviceId;
    try {
      if (Get.isRegistered<DeviceService>()) {
        return DeviceService.to.deviceId;
      }
    } catch (_) {}
    return 'legacy';
  }

  /// Menyimpan satu sesi doomscroll ke SQLite lokal dan mendaftarkannya ke antrean sinkronisasi
  Future<void> insertSession(DoomscrollSessionModel session) async {
    final fallbackUserId = _currentUserId;
    final sessionUserId = (session.userId != null &&
            session.userId!.isNotEmpty &&
            session.userId != 'local_user')
        ? session.userId!
        : fallbackUserId;
    final now = DateTime.now();
    final sessionId = session.id.isNotEmpty ? session.id : UuidGenerator.v4();
    final devId = _resolveDeviceId(session.deviceId);

    await _db.transaction(() async {
      await _db.into(_db.doomscrollSessions).insert(
            DoomscrollSessionsCompanion.insert(
              id: sessionId,
              userId: sessionUserId,
              deviceId: Value(devId),
              packageName: session.packageName,
              appName: session.appName,
              startedAt: session.startedAt,
              endedAt: Value(session.endedAt),
              durationMillis: BigInt.from(session.durationMillis),
              swipeCount: session.swipeCount,
              downwardSwipeCount: session.downwardSwipeCount,
              upwardSwipeCount: session.upwardSwipeCount,
              avgInterSwipeMillis: BigInt.from(session.avgInterSwipeMillis),
              collectedAt: session.collectedAt,
              syncStatus: const Value(SyncStatus.pending),
              syncAttempts: const Value(0),
              createdAt: now,
              updatedAt: now,
            ),
          );

      await _enqueueSync(
        entityType: SyncEntityType.doomscrollSession,
        entityId: sessionId,
      );
    });
  }

  /// Menyimpan daftar sesi yang diambil dari native queue ke SQLite lokal secara batch dalam 1 transaksi
  Future<void> insertSessions(List<DoomscrollSessionModel> sessions) async {
    if (sessions.isEmpty) return;
    final fallbackUserId = _currentUserId;
    final now = DateTime.now();

    await _db.transaction(() async {
      for (final session in sessions) {
        final sessionId = session.id.isNotEmpty ? session.id : UuidGenerator.v4();

        // Hindari duplikasi jika id sesi sudah pernah disimpan
        final existing = await (_db.select(_db.doomscrollSessions)
              ..where((tbl) => tbl.id.equals(sessionId)))
            .getSingleOrNull();

        if (existing == null) {
          final devId = _resolveDeviceId(session.deviceId);
          final sessionUserId = (session.userId != null &&
                  session.userId!.isNotEmpty &&
                  session.userId != 'local_user')
              ? session.userId!
              : fallbackUserId;
          await _db.into(_db.doomscrollSessions).insert(
                DoomscrollSessionsCompanion.insert(
                  id: sessionId,
                  userId: sessionUserId,
                  deviceId: Value(devId),
                  packageName: session.packageName,
                  appName: session.appName,
                  startedAt: session.startedAt,
                  endedAt: Value(session.endedAt),
                  durationMillis: BigInt.from(session.durationMillis),
                  swipeCount: session.swipeCount,
                  downwardSwipeCount: session.downwardSwipeCount,
                  upwardSwipeCount: session.upwardSwipeCount,
                  avgInterSwipeMillis: BigInt.from(session.avgInterSwipeMillis),
                  collectedAt: session.collectedAt,
                  syncStatus: const Value(SyncStatus.pending),
                  syncAttempts: const Value(0),
                  createdAt: now,
                  updatedAt: now,
                ),
              );

          await _enqueueSync(
            entityType: SyncEntityType.doomscrollSession,
            entityId: sessionId,
          );
        }
      }
    });
  }

  /// Mendaftarkan ke sync_queue
  Future<void> _enqueueSync({
    required String entityType,
    required String entityId,
  }) async {
    final existingQueue = await (_db.select(_db.syncQueue)
          ..where((tbl) =>
              tbl.entityType.equals(entityType) &
              tbl.entityId.equals(entityId)))
        .getSingleOrNull();

    if (existingQueue == null) {
      await _db.into(_db.syncQueue).insert(
            SyncQueueCompanion.insert(
              id: UuidGenerator.v4(),
              entityType: entityType,
              entityId: entityId,
              operation: const Value(SyncOperation.insert),
              createdAt: DateTime.now(),
              retryCount: const Value(0),
            ),
          );
    }
  }

  /// Mengambil daftar riwayat sesi doomscroll pengguna saat ini (terbaru di atas)
  Future<List<DoomscrollSessionData>> getSessions({int limit = 50, String? deviceId}) {
    final userId = _currentUserId;
    final devId = _resolveDeviceId(deviceId);
    return (_db.select(_db.doomscrollSessions)
          ..where((tbl) =>
              (tbl.userId.equals(userId) | tbl.userId.equals('local_user')) &
              (tbl.deviceId.equals(devId) | tbl.deviceId.equals('legacy')))
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
          ..limit(limit))
        .get();
  }

  /// Mengambil satu sesi berdasarkan ID
  Future<DoomscrollSessionData?> getSessionById(String id) {
    return (_db.select(_db.doomscrollSessions)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  /// Menandai sesi berhasil disinkronkan ke Supabase
  Future<void> markSessionSynced(String id) async {
    await (_db.update(_db.doomscrollSessions)..where((tbl) => tbl.id.equals(id)))
        .write(
      const DoomscrollSessionsCompanion(
        syncStatus: Value(SyncStatus.synced),
        lastSyncError: Value(null),
      ),
    );
    await (_db.delete(_db.syncQueue)
          ..where((tbl) =>
              tbl.entityType.equals(SyncEntityType.doomscrollSession) &
              tbl.entityId.equals(id)))
        .go();
  }

  /// Menandai sesi gagal disinkronkan ke Supabase
  Future<void> markSessionFailed(String id, String error) async {
    final current = await getSessionById(id);
    final attempts = (current?.syncAttempts ?? 0) + 1;

    await (_db.update(_db.doomscrollSessions)..where((tbl) => tbl.id.equals(id)))
        .write(
      DoomscrollSessionsCompanion(
        syncStatus: const Value(SyncStatus.failed),
        syncAttempts: Value(attempts),
        lastSyncError: Value(error),
      ),
    );
  }

  /// Mengambil sesi doomscroll dalam rentang waktu [start .. end) dengan pola half-open interval
  Future<List<DoomscrollSessionData>> getSessionsBetween({
    required DateTime start,
    required DateTime end,
    String? userId,
  }) async {
    final currentUid = _currentUserId;
    final targetUserId =
        (userId != null && userId.isNotEmpty && userId != 'local_user')
            ? userId
            : currentUid;

    return (_db.select(_db.doomscrollSessions)
          ..where((t) =>
              (t.userId.equals(targetUserId) | t.userId.equals('local_user')) &
              t.startedAt.isBiggerOrEqualValue(start) &
              t.startedAt.isSmallerThanValue(end))
          ..orderBy([(t) => OrderingTerm.asc(t.startedAt)]))
        .get();
  }

  /// Mengaitkan seluruh sesi berlabel 'local_user' ke userId user yang sedang login
  Future<int> claimLocalSessions(String authenticatedUserId) async {
    if (authenticatedUserId.isEmpty || authenticatedUserId == 'local_user') return 0;
    return await (_db.update(_db.doomscrollSessions)
          ..where((t) => t.userId.equals('local_user')))
        .write(
      DoomscrollSessionsCompanion(
        userId: Value(authenticatedUserId),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
