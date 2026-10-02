import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:get/get.dart' hide Value;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/uuid_generator.dart';
import '../../models/intervention_model.dart';
import '../app_database.dart';

/// Ringkasan statistik riwayat intervensi pengguna
class InterventionStatistics {
  final int totalCount;
  final int completedCount;
  final int cancelledCount;
  final int totalDurationMinutes;
  final int digitalBreakCount;
  final int eyeRelaxationCount;
  final int focusModeCount;

  const InterventionStatistics({
    required this.totalCount,
    required this.completedCount,
    required this.cancelledCount,
    required this.totalDurationMinutes,
    required this.digitalBreakCount,
    required this.eyeRelaxationCount,
    required this.focusModeCount,
  });

  factory InterventionStatistics.empty() {
    return const InterventionStatistics(
      totalCount: 0,
      completedCount: 0,
      cancelledCount: 0,
      totalDurationMinutes: 0,
      digitalBreakCount: 0,
      eyeRelaxationCount: 0,
      focusModeCount: 0,
    );
  }
}

/// Repository lokal untuk menyimpan dan mengelola riwayat intervensi pengguna di SQLite via Drift.
/// Menerapkan prinsip offline-first dan mengisolasi data per userId.
class InterventionHistoryLocalRepository {
  final AppDatabase _db;
  final SupabaseClient? _supabase;

  InterventionHistoryLocalRepository({
    AppDatabase? db,
    SupabaseClient? supabase,
  })  : _db = db ?? _resolveDatabase(),
        _supabase = supabase ?? _safeGetSupabaseClient();

  static AppDatabase? _testDbInstance;

  static AppDatabase _resolveDatabase() {
    if (Get.isRegistered<AppDatabase>()) {
      return Get.find<AppDatabase>();
    }
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return _testDbInstance ??= AppDatabase(NativeDatabase.memory());
    }
    return AppDatabase();
  }

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

  /// Menyimpan riwayat intervensi baru ke Drift SQLite
  Future<void> insert(InterventionModel model, {String? userId}) async {
    final effectiveUserId =
        userId ?? (model.userId.isNotEmpty ? model.userId : _currentUserId);
    final id = model.id.isNotEmpty ? model.id : UuidGenerator.v4();

    await _db.into(_db.interventionHistories).insert(
          InterventionHistoriesCompanion.insert(
            id: id,
            userId: effectiveUserId,
            type: model.type.name,
            title: model.title,
            durationMinutes: model.durationMinutes,
            startedAt: model.startedAt,
            endedAt: model.endedAt,
            status: model.status.name,
            cancelledAt: Value(model.cancelledAt),
            sourceRecommendationId: Value(
              model.sourceRecommendationId ?? model.sourceRecommendation?.id,
            ),
            createdAt: model.createdAt,
            updatedAt: model.updatedAt,
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  /// Memperbarui riwayat intervensi yang ada
  Future<void> update(InterventionModel model, {String? userId}) async {
    final effectiveUserId = userId ?? (model.userId.isNotEmpty ? model.userId : _currentUserId);
    final now = DateTime.now();

    await (_db.update(_db.interventionHistories)
          ..where((t) => t.id.equals(model.id) & t.userId.equals(effectiveUserId)))
        .write(
      InterventionHistoriesCompanion(
        status: Value(model.status.name),
        endedAt: Value(model.endedAt),
        cancelledAt: Value(model.cancelledAt),
        updatedAt: Value(now),
      ),
    );
  }

  /// Mengambil satu riwayat intervensi berdasarkan ID dan userId
  Future<InterventionModel?> getById(String id, {String? userId}) async {
    final effectiveUserId = userId ?? _currentUserId;
    final row = await (_db.select(_db.interventionHistories)
          ..where((t) => t.id.equals(id) & t.userId.equals(effectiveUserId)))
        .getSingleOrNull();

    if (row == null) return null;
    return _mapRowToModel(row);
  }

  /// Mengambil daftar riwayat intervensi terbaru dengan pagination
  Future<List<InterventionModel>> getRecent({
    int limit = 10,
    int offset = 0,
    InterventionType? type,
    DateTime? startDate,
    DateTime? endDate,
    String? userId,
  }) async {
    final effectiveUserId = userId ?? _currentUserId;
    var query = _db.select(_db.interventionHistories)
      ..where((t) => t.userId.equals(effectiveUserId));

    if (type != null) {
      query = query..where((t) => t.type.equals(type.name));
    }

    if (startDate != null) {
      query = query..where((t) => t.startedAt.isBiggerOrEqualValue(startDate));
    }

    if (endDate != null) {
      query = query..where((t) => t.startedAt.isSmallerOrEqualValue(endDate));
    }

    query = query
      ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
      ..limit(limit, offset: offset);

    final rows = await query.get();
    return rows.map(_mapRowToModel).toList();
  }

  /// Mengambil riwayat intervensi dalam rentang waktu tertentu
  Future<List<InterventionModel>> getBetween(
    DateTime start,
    DateTime end, {
    InterventionType? type,
    String? userId,
  }) async {
    final effectiveUserId = userId ?? _currentUserId;
    var query = _db.select(_db.interventionHistories)
      ..where((t) =>
          t.userId.equals(effectiveUserId) &
          t.startedAt.isBiggerOrEqualValue(start) &
          t.startedAt.isSmallerOrEqualValue(end));

    if (type != null) {
      query = query..where((t) => t.type.equals(type.name));
    }

    query = query..orderBy([(t) => OrderingTerm.desc(t.startedAt)]);
    final rows = await query.get();
    return rows.map(_mapRowToModel).toList();
  }

  /// Mengambil riwayat intervensi berdasarkan status tertentu
  Future<List<InterventionModel>> getByStatus(
    InterventionStatus status, {
    String? userId,
  }) async {
    final effectiveUserId = userId ?? _currentUserId;
    final query = _db.select(_db.interventionHistories)
      ..where(
          (t) => t.userId.equals(effectiveUserId) & t.status.equals(status.name))
      ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]);

    final rows = await query.get();
    return rows.map(_mapRowToModel).toList();
  }

  /// Menghitung statistik riwayat intervensi pengguna
  Future<InterventionStatistics> getStatistics({
    DateTime? start,
    DateTime? end,
    String? userId,
  }) async {
    final effectiveUserId = userId ?? _currentUserId;
    var query = _db.select(_db.interventionHistories)
      ..where((t) => t.userId.equals(effectiveUserId));

    if (start != null && end != null) {
      query = query
        ..where((t) =>
            t.startedAt.isBiggerOrEqualValue(start) &
            t.startedAt.isSmallerOrEqualValue(end));
    }

    final rows = await query.get();
    if (rows.isEmpty) return InterventionStatistics.empty();

    int completed = 0;
    int cancelled = 0;
    int totalMinutes = 0;
    int digitalBreak = 0;
    int eyeRelax = 0;
    int focusMode = 0;

    for (final r in rows) {
      if (r.status == InterventionStatus.completed.name) {
        completed++;
        totalMinutes += r.durationMinutes;
      } else if (r.status == InterventionStatus.cancelled.name) {
        cancelled++;
      }

      if (r.type == InterventionType.digitalBreak.name) {
        digitalBreak++;
      } else if (r.type == InterventionType.eyeRelaxation.name) {
        eyeRelax++;
      } else if (r.type == InterventionType.focusMode.name) {
        focusMode++;
      }
    }

    return InterventionStatistics(
      totalCount: rows.length,
      completedCount: completed,
      cancelledCount: cancelled,
      totalDurationMinutes: totalMinutes,
      digitalBreakCount: digitalBreak,
      eyeRelaxationCount: eyeRelax,
      focusModeCount: focusMode,
    );
  }

  InterventionModel _mapRowToModel(InterventionHistoryData row) {
    return InterventionModel(
      id: row.id,
      userId: row.userId,
      type: InterventionType.fromString(row.type),
      title: row.title,
      durationMinutes: row.durationMinutes,
      startedAt: row.startedAt,
      endedAt: row.endedAt,
      status: InterventionStatus.fromString(row.status),
      sourceRecommendationId: row.sourceRecommendationId,
      cancelledAt: row.cancelledAt,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
