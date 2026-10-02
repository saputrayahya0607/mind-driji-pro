import 'package:drift/drift.dart';
import 'package:get/get.dart' hide Value;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/uuid_generator.dart';
import '../../models/eye_monitoring_session_model.dart';
import '../../services/device_service.dart';
import '../app_database.dart';
import '../tables/sync_queue.dart';

/// Repository lokal untuk menyimpan dan mengelola Eye Monitoring Session di SQLite via Drift.
/// Menerapkan prinsip offline-first dan memastikan userId selalu diambil dari sesi autentikasi Supabase.
class EyeMonitoringLocalRepository {
  final AppDatabase _db;
  final SupabaseClient? _supabase;

  EyeMonitoringLocalRepository({AppDatabase? db, SupabaseClient? supabase})
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
  String get _currentUserId =>
      _supabase?.auth.currentUser?.id ?? 'local_user';

  String _resolveDeviceId([String? deviceId]) {
    if (deviceId != null && deviceId.isNotEmpty) return deviceId;
    try {
      if (Get.isRegistered<DeviceService>()) {
        return DeviceService.to.deviceId;
      }
    } catch (_) {}
    return 'legacy';
  }

  /// Menyimpan satu sesi eye monitoring ke SQLite lokal dan mendaftarkannya ke antrean sinkronisasi
  Future<void> insertSession(EyeMonitoringSessionModel session) async {
    final userId = (session.userId != null && session.userId!.isNotEmpty)
        ? session.userId!
        : _currentUserId;
    final now = DateTime.now();
    final sessionId = session.id.isNotEmpty ? session.id : UuidGenerator.v4();
    final devId = _resolveDeviceId(session.deviceId);

    await _db.transaction(() async {
      await _db.into(_db.eyeMonitoringSessions).insert(
            EyeMonitoringSessionsCompanion.insert(
              id: sessionId,
              userId: userId,
              deviceId: Value(devId),
              startedAt: session.startedAt,
              endedAt: Value(session.endedAt),
              durationMillis: BigInt.from(session.durationMillis),
              averageEar: session.averageEar,
              minEar: session.minEar,
              eyeClosureEvents: session.eyeClosureEvents,
              blinkCount: session.blinkCount,
              collectedAt: session.collectedAt,
              syncStatus: const Value(SyncStatus.pending),
              syncAttempts: const Value(0),
              createdAt: now,
              updatedAt: now,
            ),
          );

      await _enqueueSync(
        entityId: sessionId,
        entityType: SyncEntityType.eyeMonitoringSession,
        operation: SyncOperation.insert,
        now: now,
      );
    });
  }

  /// Mendaftarkan record baru ke antrean sinkronisasi
  Future<void> _enqueueSync({
    required String entityId,
    required String entityType,
    required String operation,
    required DateTime now,
  }) async {
    await _db.into(_db.syncQueue).insert(
          SyncQueueCompanion.insert(
            id: UuidGenerator.v4(),
            entityType: entityType,
            entityId: entityId,
            operation: Value(operation),
            createdAt: now,
            retryCount: const Value(0),
          ),
        );
  }

  /// Membaca daftar riwayat sesi eye monitoring yang tersimpan di SQLite lokal
  Future<List<EyeMonitoringSessionData>> getSessions({
    int limit = 50,
    String? deviceId,
    String? userId,
  }) async {
    final clientUser = _supabase?.auth.currentUser?.id ?? _safeGetSupabaseClient()?.auth.currentUser?.id;
    final effectiveUserId = userId ?? clientUser;
    final query = _db.select(_db.eyeMonitoringSessions);
    if (effectiveUserId != null && effectiveUserId.isNotEmpty) {
      if (deviceId != null) {
        final devId = _resolveDeviceId(deviceId);
        query.where((t) =>
            (t.userId.equals(effectiveUserId) | t.userId.equals('local_user')) &
            (t.deviceId.equals(devId) | t.deviceId.equals('legacy')));
      } else {
        query.where((t) =>
            t.userId.equals(effectiveUserId) |
            t.userId.equals('local_user'));
      }
    } else {
      if (deviceId != null) {
        final devId = _resolveDeviceId(deviceId);
        query.where((t) =>
            t.deviceId.equals(devId) | t.deviceId.equals('legacy'));
      }
    }
    query
      ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
      ..limit(limit);
    return query.get();
  }

  /// Membaca detail sesi berdasarkan ID
  Future<EyeMonitoringSessionData?> getSessionById(String id) async {
    final query = _db.select(_db.eyeMonitoringSessions)
      ..where((t) => t.id.equals(id));
    return query.getSingleOrNull();
  }

  /// Memperbarui userId pada sesi lokal (misalnya setelah sesi offline diklaim oleh user yang login)
  Future<void> updateSessionUserId(String sessionId, String newUserId) async {
    await (_db.update(_db.eyeMonitoringSessions)..where((t) => t.id.equals(sessionId)))
        .write(
      EyeMonitoringSessionsCompanion(
        userId: Value(newUserId),
      ),
    );
  }

  /// Mengaitkan seluruh sesi berlabel 'local_user' ke userId user yang sedang login
  Future<void> claimLocalSessions(String authenticatedUserId) async {
    await (_db.update(_db.eyeMonitoringSessions)
          ..where((t) => t.userId.equals('local_user')))
        .write(
      EyeMonitoringSessionsCompanion(
        userId: Value(authenticatedUserId),
      ),
    );
  }

  /// Memperbarui status sesi menjadi 'synced' setelah berhasil dikirim ke Supabase
  Future<void> markSessionSynced(String id) async {
    final now = DateTime.now();
    await _db.transaction(() async {
      await (_db.update(_db.eyeMonitoringSessions)..where((t) => t.id.equals(id)))
          .write(
        EyeMonitoringSessionsCompanion(
          syncStatus: const Value(SyncStatus.synced),
          lastSyncError: const Value(null),
          updatedAt: Value(now),
        ),
      );

      await (_db.delete(_db.syncQueue)
            ..where((t) =>
                t.entityType.equals(SyncEntityType.eyeMonitoringSession) &
                t.entityId.equals(id)))
          .go();
    });
  }

  /// Menandai sesi gagal sinkronisasi dan mencatat pesan error
  Future<void> markSessionFailed(String id, String error) async {
    final now = DateTime.now();
    final current = await getSessionById(id);
    final attempts = (current?.syncAttempts ?? 0) + 1;

    await (_db.update(_db.eyeMonitoringSessions)..where((t) => t.id.equals(id)))
        .write(
      EyeMonitoringSessionsCompanion(
        syncStatus: const Value(SyncStatus.failed),
        syncAttempts: Value(attempts),
        lastSyncError: Value(error),
        updatedAt: Value(now),
      ),
    );
  }

  /// Menghitung jumlah sesi eye monitoring yang masih pending atau failed sinkronisasi
  Future<int> getPendingSyncCount(String userId) async {
    final countExp = _db.eyeMonitoringSessions.id.count();
    final query = _db.selectOnly(_db.eyeMonitoringSessions)
      ..addColumns([countExp])
      ..where((_db.eyeMonitoringSessions.userId.equals(userId) |
              _db.eyeMonitoringSessions.userId.equals('local_user')) &
          _db.eyeMonitoringSessions.syncStatus.isNotValue(SyncStatus.synced));

    final result = await query.getSingle();
    return result.read(countExp) ?? 0;
  }

  /// Membaca daftar riwayat sesi eye monitoring dalam rentang waktu [start .. end]
  Future<List<EyeMonitoringSessionData>> getSessionsBetween({
    required DateTime start,
    required DateTime end,
    String? userId,
  }) async {
    final effectiveUserId = userId ?? _supabase?.auth.currentUser?.id ?? _safeGetSupabaseClient()?.auth.currentUser?.id;
    return (_db.select(_db.eyeMonitoringSessions)
          ..where((t) =>
              (effectiveUserId == null
                  ? const Constant(true)
                  : (t.userId.equals(effectiveUserId) |
                      t.userId.equals('local_user'))) &
              t.startedAt.isBiggerOrEqualValue(start) &
              t.startedAt.isSmallerThanValue(end))
          ..orderBy([(t) => OrderingTerm.asc(t.startedAt)]))
        .get();
  }
}
