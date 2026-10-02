import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mind_drji/app/data/local/app_database.dart';
import 'package:mind_drji/app/data/local/repositories/intervention_history_local_repository.dart';
import 'package:mind_drji/app/data/models/intervention_model.dart';
import 'package:mind_drji/app/data/models/recommendation_model.dart';
import 'package:mind_drji/app/data/providers/intervention_native_provider.dart';
import 'package:mind_drji/app/data/services/intervention_service.dart';
import 'package:mind_drji/app/modules/intervention_history/controllers/intervention_history_controller.dart';
import 'package:mind_drji/app/modules/intervention_history/views/intervention_history_view.dart';

class MockInterventionNativeProvider extends InterventionNativeProvider {
  Map<String, dynamic>? storedStatus;

  @override
  Future<bool> startDigitalBreak({
    required String id,
    required int durationMinutes,
    required int endTimestampMillis,
  }) async {
    storedStatus = {
      'id': id,
      'type': 'digitalBreak',
      'title': 'Jeda Digital',
      'durationMinutes': durationMinutes,
      'startedAt': DateTime.now().toIso8601String(),
      'endedAt': DateTime.fromMillisecondsSinceEpoch(endTimestampMillis)
          .toIso8601String(),
      'status': 'active',
      'createdAt': DateTime.now().toIso8601String(),
    };
    return true;
  }

  @override
  Future<bool> stopDigitalBreak() async {
    storedStatus = null;
    return true;
  }

  @override
  Future<Map<String, dynamic>?> getInterventionStatus() async {
    return storedStatus;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late InterventionHistoryLocalRepository repo;

  setUp(() {
    Get.reset();
    db = AppDatabase(NativeDatabase.memory());
    repo = InterventionHistoryLocalRepository(db: db);
    Get.put<AppDatabase>(db);
    Get.put<InterventionHistoryLocalRepository>(repo);
  });

  tearDown(() async {
    await db.close();
    Get.reset();
  });

  group('INTERVENTION HISTORY REPOSITORY TESTS (1 - 15)', () {
    test('1. Insert history: Menyimpan sesi intervensi active ke SQLite via Drift',
        () async {
      final now = DateTime.now();
      final item = InterventionModel(
        id: 'hist-item-1',
        userId: 'user_test_1',
        type: InterventionType.digitalBreak,
        title: 'Jeda Digital',
        durationMinutes: 15,
        startedAt: now,
        endedAt: now.add(const Duration(minutes: 15)),
        status: InterventionStatus.active,
        createdAt: now,
        updatedAt: now,
      );

      await repo.insert(item);

      final retrieved = await repo.getById('hist-item-1', userId: 'user_test_1');
      expect(retrieved, isNotNull);
      expect(retrieved!.id, 'hist-item-1');
      expect(retrieved.status, InterventionStatus.active);
      expect(retrieved.durationMinutes, 15);
      expect(retrieved.type, InterventionType.digitalBreak);
    });

    test('2. Update active -> completed: Mengubah status dan mencatat endedAt',
        () async {
      final now = DateTime.now();
      final item = InterventionModel(
        id: 'hist-item-2',
        userId: 'user_test_1',
        type: InterventionType.digitalBreak,
        title: 'Jeda Digital',
        durationMinutes: 15,
        startedAt: now.subtract(const Duration(minutes: 15)),
        endedAt: now,
        status: InterventionStatus.active,
        createdAt: now.subtract(const Duration(minutes: 15)),
        updatedAt: now.subtract(const Duration(minutes: 15)),
      );

      await repo.insert(item);

      final updated = item.copyWith(
        status: InterventionStatus.completed,
        endedAt: now,
        updatedAt: now,
      );
      await repo.update(updated);

      final result = await repo.getById('hist-item-2', userId: 'user_test_1');
      expect(result!.status, InterventionStatus.completed);
      expect(result.endedAt, isNotNull);
      expect(result.cancelledAt, isNull);
    });

    test('3. Update active -> cancelled: Mengubah status dan mencatat cancelledAt',
        () async {
      final now = DateTime.now();
      final item = InterventionModel(
        id: 'hist-item-3',
        userId: 'user_test_1',
        type: InterventionType.eyeRelaxation,
        title: 'Istirahat Mata',
        durationMinutes: 5,
        startedAt: now.subtract(const Duration(minutes: 2)),
        endedAt: now.add(const Duration(minutes: 3)),
        status: InterventionStatus.active,
        createdAt: now.subtract(const Duration(minutes: 2)),
        updatedAt: now.subtract(const Duration(minutes: 2)),
      );

      await repo.insert(item);

      final updated = item.copyWith(
        status: InterventionStatus.cancelled,
        cancelledAt: now,
        endedAt: now,
        updatedAt: now,
      );
      await repo.update(updated);

      final result = await repo.getById('hist-item-3', userId: 'user_test_1');
      expect(result!.status, InterventionStatus.cancelled);
      expect(result.cancelledAt, isNotNull);
      expect(result.endedAt, isNotNull);
    });

    test('4. Get by ID: Mengambil riwayat spesifik dengan ID dan userId yang tepat',
        () async {
      final now = DateTime.now();
      final item = InterventionModel(
        id: 'find-by-id-1',
        userId: 'user_target',
        type: InterventionType.digitalBreak,
        title: 'Jeda Digital 10m',
        durationMinutes: 10,
        startedAt: now,
        endedAt: now.add(const Duration(minutes: 10)),
        status: InterventionStatus.completed,
        createdAt: now,
        updatedAt: now,
      );

      await repo.insert(item);

      final found = await repo.getById('find-by-id-1', userId: 'user_target');
      expect(found, isNotNull);
      expect(found!.title, 'Jeda Digital 10m');

      final notFound = await repo.getById('non-existent-id', userId: 'user_target');
      expect(notFound, isNull);
    });

    test('5. Get recent: Mengambil daftar riwayat terbaru dengan sorting descending',
        () async {
      final t1 = DateTime(2026, 9, 30, 10, 0);
      final t2 = DateTime(2026, 9, 30, 12, 0);
      final t3 = DateTime(2026, 9, 30, 14, 0);

      await repo.insert(InterventionModel(
        id: 'item-1',
        userId: 'user_recent',
        type: InterventionType.digitalBreak,
        title: 'Pertama',
        durationMinutes: 5,
        startedAt: t1,
        endedAt: t1.add(const Duration(minutes: 5)),
        status: InterventionStatus.completed,
        createdAt: t1,
        updatedAt: t1,
      ));
      await repo.insert(InterventionModel(
        id: 'item-2',
        userId: 'user_recent',
        type: InterventionType.digitalBreak,
        title: 'Kedua',
        durationMinutes: 15,
        startedAt: t2,
        endedAt: t2.add(const Duration(minutes: 15)),
        status: InterventionStatus.completed,
        createdAt: t2,
        updatedAt: t2,
      ));
      await repo.insert(InterventionModel(
        id: 'item-3',
        userId: 'user_recent',
        type: InterventionType.eyeRelaxation,
        title: 'Ketiga',
        durationMinutes: 5,
        startedAt: t3,
        endedAt: t3.add(const Duration(minutes: 5)),
        status: InterventionStatus.completed,
        createdAt: t3,
        updatedAt: t3,
      ));

      final list = await repo.getRecent(userId: 'user_recent');
      expect(list.length, 3);
      expect(list[0].id, 'item-3'); // Paling baru
      expect(list[1].id, 'item-2');
      expect(list[2].id, 'item-1');
    });

    test('6. Get between: Mengambil riwayat dalam rentang kalender tertentu',
        () async {
      final d1 = DateTime(2026, 9, 28, 10, 0);
      final d2 = DateTime(2026, 9, 29, 15, 0);
      final d3 = DateTime(2026, 9, 30, 20, 0);

      for (var (idx, d) in [d1, d2, d3].indexed) {
        await repo.insert(InterventionModel(
          id: 'range-$idx',
          userId: 'user_range',
          type: InterventionType.digitalBreak,
          title: 'Sesi $idx',
          durationMinutes: 15,
          startedAt: d,
          endedAt: d.add(const Duration(minutes: 15)),
          status: InterventionStatus.completed,
          createdAt: d,
          updatedAt: d,
        ));
      }

      final results = await repo.getBetween(
        DateTime(2026, 9, 29, 0, 0),
        DateTime(2026, 9, 29, 23, 59, 59),
        userId: 'user_range',
      );
      expect(results.length, 1);
      expect(results.first.id, 'range-1');
    });

    test('7. User isolation: Query hanya mengembalikan data milik user yang bersangkutan',
        () async {
      final now = DateTime.now();
      await repo.insert(InterventionModel(
        id: 'user-a-sess',
        userId: 'user_A',
        type: InterventionType.digitalBreak,
        title: 'Jeda User A',
        durationMinutes: 15,
        startedAt: now,
        endedAt: now.add(const Duration(minutes: 15)),
        status: InterventionStatus.completed,
        createdAt: now,
        updatedAt: now,
      ));

      await repo.insert(InterventionModel(
        id: 'user-b-sess',
        userId: 'user_B',
        type: InterventionType.digitalBreak,
        title: 'Jeda User B',
        durationMinutes: 15,
        startedAt: now,
        endedAt: now.add(const Duration(minutes: 15)),
        status: InterventionStatus.completed,
        createdAt: now,
        updatedAt: now,
      ));

      final userAList = await repo.getRecent(userId: 'user_A');
      expect(userAList.length, 1);
      expect(userAList.first.id, 'user-a-sess');

      final userBList = await repo.getRecent(userId: 'user_B');
      expect(userBList.length, 1);
      expect(userBList.first.id, 'user-b-sess');

      final crossAccess = await repo.getById('user-a-sess', userId: 'user_B');
      expect(crossAccess, isNull);
    });

    test('8. Multiple users: Database menyimpan banyak user secara independen',
        () async {
      final now = DateTime.now();
      for (int i = 0; i < 3; i++) {
        await repo.insert(InterventionModel(
          id: 'multi-a-$i',
          userId: 'user_multi_1',
          type: InterventionType.digitalBreak,
          title: 'Sesi A $i',
          durationMinutes: 15,
          startedAt: now.subtract(Duration(minutes: i * 20)),
          endedAt: now.subtract(Duration(minutes: i * 20 - 15)),
          status: InterventionStatus.completed,
          createdAt: now,
          updatedAt: now,
        ));
      }
      for (int i = 0; i < 2; i++) {
        await repo.insert(InterventionModel(
          id: 'multi-b-$i',
          userId: 'user_multi_2',
          type: InterventionType.eyeRelaxation,
          title: 'Sesi B $i',
          durationMinutes: 5,
          startedAt: now.subtract(Duration(minutes: i * 10)),
          endedAt: now.subtract(Duration(minutes: i * 10 - 5)),
          status: InterventionStatus.completed,
          createdAt: now,
          updatedAt: now,
        ));
      }

      final statsA = await repo.getStatistics(userId: 'user_multi_1');
      final statsB = await repo.getStatistics(userId: 'user_multi_2');

      expect(statsA.totalCount, 3);
      expect(statsA.digitalBreakCount, 3);
      expect(statsA.eyeRelaxationCount, 0);

      expect(statsB.totalCount, 2);
      expect(statsB.digitalBreakCount, 0);
      expect(statsB.eyeRelaxationCount, 2);
    });

    test('9. Empty history: Mengembalikan list kosong tanpa error saat belum ada data',
        () async {
      final list = await repo.getRecent(userId: 'user_empty');
      expect(list, isEmpty);

      final stats = await repo.getStatistics(userId: 'user_empty');
      expect(stats.totalCount, 0);
      expect(stats.completedCount, 0);
      expect(stats.cancelledCount, 0);
      expect(stats.totalDurationMinutes, 0);
    });

    test('10. Pagination / limit: Mengembalikan data bertahap dengan limit dan offset',
        () async {
      final base = DateTime(2026, 9, 30, 8, 0);
      for (int i = 0; i < 15; i++) {
        await repo.insert(InterventionModel(
          id: 'page-$i',
          userId: 'user_page',
          type: InterventionType.digitalBreak,
          title: 'Sesi $i',
          durationMinutes: 15,
          startedAt: base.add(Duration(minutes: i * 30)),
          endedAt: base.add(Duration(minutes: i * 30 + 15)),
          status: InterventionStatus.completed,
          createdAt: base,
          updatedAt: base,
        ));
      }

      final page1 = await repo.getRecent(userId: 'user_page', limit: 10, offset: 0);
      expect(page1.length, 10);
      expect(page1.first.id, 'page-14'); // Descending

      final page2 = await repo.getRecent(userId: 'user_page', limit: 10, offset: 10);
      expect(page2.length, 5);
      expect(page2.first.id, 'page-4');
    });

    test('11. Today filter: Menyaring riwayat yang berlangsung hari ini saja',
        () async {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));

      await repo.insert(InterventionModel(
        id: 'yesterday-sess',
        userId: 'user_date_filter',
        type: InterventionType.digitalBreak,
        title: 'Kemarin',
        durationMinutes: 15,
        startedAt: yesterday,
        endedAt: yesterday.add(const Duration(minutes: 15)),
        status: InterventionStatus.completed,
        createdAt: yesterday,
        updatedAt: yesterday,
      ));

      await repo.insert(InterventionModel(
        id: 'today-sess',
        userId: 'user_date_filter',
        type: InterventionType.digitalBreak,
        title: 'Hari Ini',
        durationMinutes: 15,
        startedAt: today,
        endedAt: today.add(const Duration(minutes: 15)),
        status: InterventionStatus.completed,
        createdAt: today,
        updatedAt: today,
      ));

      final startToday = DateTime(today.year, today.month, today.day);
      final endToday = DateTime(today.year, today.month, today.day, 23, 59, 59);

      final todayList = await repo.getRecent(
        userId: 'user_date_filter',
        startDate: startToday,
        endDate: endToday,
      );

      expect(todayList.length, 1);
      expect(todayList.first.id, 'today-sess');
    });

    test('12. Weekly filter: Menyaring riwayat dalam rentang 7 hari minggu berjalan',
        () async {
      final now = DateTime(2026, 9, 30); // Rabu
      final monday = DateTime(2026, 9, 28);
      final lastWeek = DateTime(2026, 9, 20);

      await repo.insert(InterventionModel(
        id: 'in-week',
        userId: 'user_week_filter',
        type: InterventionType.digitalBreak,
        title: 'Minggu Ini',
        durationMinutes: 15,
        startedAt: now,
        endedAt: now.add(const Duration(minutes: 15)),
        status: InterventionStatus.completed,
        createdAt: now,
        updatedAt: now,
      ));

      await repo.insert(InterventionModel(
        id: 'out-week',
        userId: 'user_week_filter',
        type: InterventionType.digitalBreak,
        title: 'Minggu Lalu',
        durationMinutes: 15,
        startedAt: lastWeek,
        endedAt: lastWeek.add(const Duration(minutes: 15)),
        status: InterventionStatus.completed,
        createdAt: lastWeek,
        updatedAt: lastWeek,
      ));

      final weekList = await repo.getRecent(
        userId: 'user_week_filter',
        startDate: monday,
        endDate: monday.add(const Duration(days: 6, hours: 23, minutes: 59)),
      );

      expect(weekList.length, 1);
      expect(weekList.first.id, 'in-week');
    });

    test('13. Monthly filter: Menyaring riwayat dalam rentang 1 bulan penuh',
        () async {
      final sepDate = DateTime(2026, 9, 15);
      final augDate = DateTime(2026, 8, 25);

      await repo.insert(InterventionModel(
        id: 'sep-item',
        userId: 'user_month_filter',
        type: InterventionType.digitalBreak,
        title: 'September',
        durationMinutes: 15,
        startedAt: sepDate,
        endedAt: sepDate.add(const Duration(minutes: 15)),
        status: InterventionStatus.completed,
        createdAt: sepDate,
        updatedAt: sepDate,
      ));

      await repo.insert(InterventionModel(
        id: 'aug-item',
        userId: 'user_month_filter',
        type: InterventionType.digitalBreak,
        title: 'Agustus',
        durationMinutes: 15,
        startedAt: augDate,
        endedAt: augDate.add(const Duration(minutes: 15)),
        status: InterventionStatus.completed,
        createdAt: augDate,
        updatedAt: augDate,
      ));

      final monthList = await repo.getRecent(
        userId: 'user_month_filter',
        startDate: DateTime(2026, 9, 1),
        endDate: DateTime(2026, 9, 30, 23, 59, 59),
      );

      expect(monthList.length, 1);
      expect(monthList.first.id, 'sep-item');
    });

    test('14. Digital Break history: Menyaring riwayat khusus Jeda Digital',
        () async {
      final now = DateTime.now();
      await repo.insert(InterventionModel(
        id: 'db-item',
        userId: 'user_type_filter',
        type: InterventionType.digitalBreak,
        title: 'Jeda Digital',
        durationMinutes: 15,
        startedAt: now,
        endedAt: now.add(const Duration(minutes: 15)),
        status: InterventionStatus.completed,
        createdAt: now,
        updatedAt: now,
      ));

      await repo.insert(InterventionModel(
        id: 'eye-item',
        userId: 'user_type_filter',
        type: InterventionType.eyeRelaxation,
        title: 'Istirahat Mata',
        durationMinutes: 5,
        startedAt: now,
        endedAt: now.add(const Duration(minutes: 5)),
        status: InterventionStatus.completed,
        createdAt: now,
        updatedAt: now,
      ));

      final dbOnly = await repo.getRecent(
        userId: 'user_type_filter',
        type: InterventionType.digitalBreak,
      );
      expect(dbOnly.length, 1);
      expect(dbOnly.first.type, InterventionType.digitalBreak);
    });

    test('15. Eye Relaxation history: Menyaring riwayat khusus Istirahat Mata',
        () async {
      final now = DateTime.now();
      await repo.insert(InterventionModel(
        id: 'db-item-2',
        userId: 'user_type_filter_2',
        type: InterventionType.digitalBreak,
        title: 'Jeda Digital',
        durationMinutes: 15,
        startedAt: now,
        endedAt: now.add(const Duration(minutes: 15)),
        status: InterventionStatus.completed,
        createdAt: now,
        updatedAt: now,
      ));

      await repo.insert(InterventionModel(
        id: 'eye-item-2',
        userId: 'user_type_filter_2',
        type: InterventionType.eyeRelaxation,
        title: 'Istirahat Mata',
        durationMinutes: 5,
        startedAt: now,
        endedAt: now.add(const Duration(minutes: 5)),
        status: InterventionStatus.completed,
        createdAt: now,
        updatedAt: now,
      ));

      final eyeOnly = await repo.getRecent(
        userId: 'user_type_filter_2',
        type: InterventionType.eyeRelaxation,
      );
      expect(eyeOnly.length, 1);
      expect(eyeOnly.first.type, InterventionType.eyeRelaxation);
    });
  });

  group('LIFECYCLE & INTEGRATION TESTS (16 - 20)', () {
    test('16. No history for recommendation only: Rekomendasi tanpa klik tidak membuat riwayat',
        () async {
      final mock = MockInterventionNativeProvider();
      final service = InterventionService(
        nativeProvider: mock,
        historyRepository: repo,
      );

      // Simulasi rekomendasi yang hanya dibuat tanpa dimulai oleh user
      final rec = RecommendationModel(
        id: 'rec_idle',
        type: RecommendationType.digitalBreak,
        title: 'Jeda Digital',
        description: 'Saran jeda sejenak',
        reason: 'Sesi scroll panjang terdeteksi',
        actionLabel: 'Mulai',
        durationOptions: const [5, 15, 30],
        icon: 'spa',
        generatedAt: DateTime.now(),
      );
      expect(rec.id, 'rec_idle');

      // Pastikan belum ada intervensi aktif atau tersimpan di database
      expect(service.isActive.value, isFalse);
      final history = await repo.getRecent(userId: 'local_user');
      expect(history, isEmpty);
    });

    test('17. No duplicate record after restart: Melanjutkan sesi aktif tanpa membuat record baru',
        () async {
      final mock = MockInterventionNativeProvider();
      final service = InterventionService(
        nativeProvider: mock,
        historyRepository: repo,
      );

      // Mulai intervensi pertama
      await service.startDigitalBreak(15);
      final active = service.activeIntervention.value!;
      expect(active.status, InterventionStatus.active);

      // Simulasikan app restart dengan status tersimpan di native
      final restoredService = InterventionService(
        nativeProvider: mock,
        historyRepository: repo,
      );

      // Trigger recovery
      await restoredService.restoreActiveIntervention();

      final records = await repo.getRecent(userId: 'local_user');
      // Tidak boleh ada 2 baris rekaman baru yang duplikat
      expect(records.length, 1);
      expect(records.first.id, active.id);
    });

    test('18. Lifecycle recovery: Sesi aktif yang kadaluarsa ditandai completed saat restart',
        () async {
      final now = DateTime.now();
      final expiredStart = now.subtract(const Duration(minutes: 20));
      final expiredEnd = now.subtract(const Duration(minutes: 5));

      final expiredModel = InterventionModel(
        id: 'expired-session-1',
        userId: 'local_user',
        type: InterventionType.digitalBreak,
        title: 'Jeda Digital',
        durationMinutes: 15,
        startedAt: expiredStart,
        endedAt: expiredEnd,
        status: InterventionStatus.active,
        createdAt: expiredStart,
        updatedAt: expiredStart,
      );

      await repo.insert(expiredModel);

      final mock = MockInterventionNativeProvider();
      mock.storedStatus = {
        'id': 'expired-session-1',
        'type': 'digitalBreak',
        'title': 'Jeda Digital',
        'durationMinutes': 15,
        'startedAt': expiredStart.toIso8601String(),
        'endedAt': expiredEnd.toIso8601String(),
        'status': 'active',
        'createdAt': expiredStart.toIso8601String(),
      };

      final service = InterventionService(
        nativeProvider: mock,
        historyRepository: repo,
      );

      await service.restoreActiveIntervention();

      // Karena waktu telah berakhir, status otomatis menjadi completed
      expect(service.isActive.value, isFalse);
      final updatedRecord = await repo.getById('expired-session-1', userId: 'local_user');
      expect(updatedRecord!.status, InterventionStatus.completed);
    });

    test('19. Serialization: toMap dan fromMap InterventionModel akurat dan konsisten',
        () {
      final now = DateTime(2026, 9, 30, 12, 0);
      final model = InterventionModel(
        id: 'ser-1',
        userId: 'user_ser',
        type: InterventionType.eyeRelaxation,
        title: 'Istirahat Mata',
        durationMinutes: 5,
        startedAt: now,
        endedAt: now.add(const Duration(minutes: 5)),
        status: InterventionStatus.completed,
        cancelledAt: null,
        sourceRecommendationId: 'rec_source_1',
        createdAt: now,
        updatedAt: now,
      );

      final map = model.toMap();
      expect(map['id'], 'ser-1');
      expect(map['type'], 'eyeRelaxation');
      expect(map['status'], 'completed');
      expect(map['sourceRecommendationId'], 'rec_source_1');

      final reconstructed = InterventionModel.fromMap(map);
      expect(reconstructed.id, model.id);
      expect(reconstructed.type, model.type);
      expect(reconstructed.status, model.status);
      expect(reconstructed.durationMinutes, model.durationMinutes);
      expect(reconstructed.sourceRecommendationId, model.sourceRecommendationId);
    });

    test('20. Controller state: InterventionHistoryController mengelola filter dan pagination',
        () async {
      final now = DateTime.now();
      await repo.insert(InterventionModel(
        id: 'ctrl-1',
        userId: 'local_user',
        type: InterventionType.digitalBreak,
        title: 'Jeda Digital',
        durationMinutes: 15,
        startedAt: now,
        endedAt: now.add(const Duration(minutes: 15)),
        status: InterventionStatus.completed,
        createdAt: now,
        updatedAt: now,
      ));

      final controller = InterventionHistoryController(repo: repo);
      await controller.loadHistory();

      expect(controller.historyList.length, 1);
      expect(controller.statistics.value?.completedCount, 1);
      expect(controller.statistics.value?.totalDurationMinutes, 15);

      // Ubah filter ke eyeRelaxation -> harus kosong
      controller.setTypeFilter(HistoryTypeFilter.eyeRelaxation);
      await controller.loadHistory();
      expect(controller.historyList, isEmpty);

      // Kembalikan filter ke all
      controller.setTypeFilter(HistoryTypeFilter.all);
      await controller.loadHistory();
      expect(controller.historyList.length, 1);
    });
  });

  group('WIDGET, BOUNDARY & STATISTICS TESTS (21 - 25)', () {
    testWidgets('21. History screen rendering: Menampilkan filter chips dan card riwayat',
        (tester) async {
      final now = DateTime.now();
      await repo.insert(InterventionModel(
        id: 'widget-sess-1',
        userId: 'local_user',
        type: InterventionType.digitalBreak,
        title: 'Jeda Digital',
        durationMinutes: 15,
        startedAt: now,
        endedAt: now.add(const Duration(minutes: 15)),
        status: InterventionStatus.completed,
        createdAt: now,
        updatedAt: now,
      ));

      final controller = InterventionHistoryController(repo: repo);
      Get.put(controller);

      await tester.pumpWidget(
        const GetMaterialApp(
          home: InterventionHistoryView(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Riwayat Intervensi'), findsOneWidget);
      expect(find.text('Ringkasan Intervensi'), findsOneWidget);
      expect(find.text('Jeda Digital'), findsAtLeastNWidgets(1));
      expect(find.text('Selesai'), findsAtLeastNWidgets(1));
    });

    testWidgets('22. Filter rendering: Mengklik chip filter memperbarui UI',
        (tester) async {
      final controller = InterventionHistoryController(repo: repo);
      Get.put(controller);

      await tester.pumpWidget(
        const GetMaterialApp(
          home: InterventionHistoryView(),
        ),
      );
      await tester.pumpAndSettle();

      // Temukan chip 'Istirahat Mata' dan tap
      final eyeChip = find.text('Istirahat Mata');
      expect(eyeChip, findsOneWidget);
      await tester.tap(eyeChip);
      await tester.pumpAndSettle();

      expect(controller.selectedType.value, HistoryTypeFilter.eyeRelaxation);
    });

    test('23. Statistics aggregation: Agregasi total durasi, selesai, dan dibatalkan',
        () async {
      final now = DateTime.now();
      // 1. Digital break 15m completed
      await repo.insert(InterventionModel(
        id: 'stat-1',
        userId: 'user_stats',
        type: InterventionType.digitalBreak,
        title: 'Jeda 1',
        durationMinutes: 15,
        startedAt: now,
        endedAt: now.add(const Duration(minutes: 15)),
        status: InterventionStatus.completed,
        createdAt: now,
        updatedAt: now,
      ));

      // 2. Eye rest 5m completed
      await repo.insert(InterventionModel(
        id: 'stat-2',
        userId: 'user_stats',
        type: InterventionType.eyeRelaxation,
        title: 'Mata 1',
        durationMinutes: 5,
        startedAt: now,
        endedAt: now.add(const Duration(minutes: 5)),
        status: InterventionStatus.completed,
        createdAt: now,
        updatedAt: now,
      ));

      // 3. Digital break 30m cancelled
      await repo.insert(InterventionModel(
        id: 'stat-3',
        userId: 'user_stats',
        type: InterventionType.digitalBreak,
        title: 'Jeda 2',
        durationMinutes: 30,
        startedAt: now,
        endedAt: now.add(const Duration(minutes: 30)),
        status: InterventionStatus.cancelled,
        createdAt: now,
        updatedAt: now,
      ));

      final stats = await repo.getStatistics(userId: 'user_stats');
      expect(stats.totalCount, 3);
      expect(stats.completedCount, 2);
      expect(stats.cancelledCount, 1);
      expect(stats.totalDurationMinutes, 20); // 15 + 5 (hanya completed yang dihitung durasinya)
      expect(stats.digitalBreakCount, 2);
      expect(stats.eyeRelaxationCount, 1);
      expect(stats.focusModeCount, 0); // No fake focus mode
    });

    test('24. Date boundary: Riwayat tepat pada batas awal dan akhir tanggal tertangani',
        () async {
      final startBoundary = DateTime(2026, 9, 30, 0, 0, 0);
      final endBoundary = DateTime(2026, 9, 30, 23, 59, 59);

      await repo.insert(InterventionModel(
        id: 'bound-start',
        userId: 'user_bound',
        type: InterventionType.digitalBreak,
        title: 'Awal Hari',
        durationMinutes: 15,
        startedAt: startBoundary,
        endedAt: startBoundary.add(const Duration(minutes: 15)),
        status: InterventionStatus.completed,
        createdAt: startBoundary,
        updatedAt: startBoundary,
      ));

      await repo.insert(InterventionModel(
        id: 'bound-end',
        userId: 'user_bound',
        type: InterventionType.digitalBreak,
        title: 'Akhir Hari',
        durationMinutes: 15,
        startedAt: endBoundary,
        endedAt: endBoundary.add(const Duration(minutes: 15)),
        status: InterventionStatus.completed,
        createdAt: endBoundary,
        updatedAt: endBoundary,
      ));

      final list = await repo.getBetween(startBoundary, endBoundary, userId: 'user_bound');
      expect(list.length, 2);
    });

    test('25. Midnight boundary: Sesi yang melintasi tengah malam dicatat secara valid',
        () async {
      final startMidnight = DateTime(2026, 9, 30, 23, 55, 0);
      final endMidnight = DateTime(2026, 10, 1, 0, 10, 0);

      await repo.insert(InterventionModel(
        id: 'midnight-session',
        userId: 'user_midnight',
        type: InterventionType.digitalBreak,
        title: 'Jeda Tengah Malam',
        durationMinutes: 15,
        startedAt: startMidnight,
        endedAt: endMidnight,
        status: InterventionStatus.completed,
        createdAt: startMidnight,
        updatedAt: endMidnight,
      ));

      final retrieved = await repo.getById('midnight-session', userId: 'user_midnight');
      expect(retrieved, isNotNull);
      expect(retrieved!.startedAt.day, 30);
      expect(retrieved.endedAt.day, 1);
      expect(retrieved.status, InterventionStatus.completed);
    });
  });
}
