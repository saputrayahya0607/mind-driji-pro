import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mind_drji/app/data/local/app_database.dart';
import 'package:mind_drji/app/data/local/repositories/intervention_history_local_repository.dart';
import 'package:mind_drji/app/data/models/intervention_model.dart';
import 'package:mind_drji/app/data/providers/intervention_native_provider.dart';
import 'package:mind_drji/app/data/services/intervention/focus_mode_executor.dart';
import 'package:mind_drji/app/data/services/intervention_service.dart';

class MockFocusModeNativeProvider extends InterventionNativeProvider {
  Map<String, dynamic>? storedStatus;
  bool startFocusModeCalled = false;
  bool stopFocusModeCalled = false;
  String? lastId;
  int? lastDurationMinutes;
  int? lastEndTimestampMillis;
  bool startReturnSuccess = true;

  @override
  Future<bool> startFocusMode({
    required String id,
    required int durationMinutes,
    required int endTimestampMillis,
  }) async {
    startFocusModeCalled = true;
    lastId = id;
    lastDurationMinutes = durationMinutes;
    lastEndTimestampMillis = endTimestampMillis;

    if (!startReturnSuccess) return false;

    final now = DateTime.now();
    storedStatus = {
      'id': id,
      'type': 'focusMode',
      'title': 'Mode Fokus',
      'durationMinutes': durationMinutes,
      'startedAt': now.toIso8601String(),
      'endedAt': DateTime.fromMillisecondsSinceEpoch(endTimestampMillis)
          .toIso8601String(),
      'status': 'active',
      'createdAt': now.toIso8601String(),
    };
    return true;
  }

  @override
  Future<bool> stopFocusMode() async {
    stopFocusModeCalled = true;
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
    Get.put<AppDatabase>(db);
    repo = InterventionHistoryLocalRepository(db: db);
    Get.put<InterventionHistoryLocalRepository>(repo);
  });

  tearDown(() async {
    await db.close();
    Get.reset();
  });

  group('PHASE 2 & PHASE 3 — FOCUS MODE TESTS', () {
    test('1. FocusModeExecutor interface & AccessibilityFocusModeExecutor implementation', () async {
      final mock = MockFocusModeNativeProvider();
      final executor = AccessibilityFocusModeExecutor(nativeProvider: mock);

      expect(executor, isA<FocusModeExecutor>());
      expect(await executor.isSupported(), isTrue);
      expect(executor.isRunning, isFalse);
      expect(executor.whitelistedPackages, contains('com.hn.mind_drji'));
      expect(executor.whitelistedPackages, contains('com.android.systemui'));
    });

    test('2. startFocusMode: Menginisialisasi Focus Mode dengan durasi valid dan mencatat ke history', () async {
      final mock = MockFocusModeNativeProvider();
      final service = InterventionService(
        nativeProvider: mock,
        historyRepository: repo,
      );

      final started = await service.startFocusMode(30);

      expect(started, isTrue);
      expect(service.isActive.value, isTrue);
      expect(service.activeIntervention.value?.type, InterventionType.focusMode);
      expect(service.activeIntervention.value?.title, 'Mode Fokus');
      expect(service.activeIntervention.value?.durationMinutes, 30);
      expect(service.remainingSeconds.value, inInclusiveRange(1790, 1800));
      expect(mock.startFocusModeCalled, isTrue);
      expect(mock.lastDurationMinutes, 30);

      // Verifikasi tersimpan di SQLite
      final list = await repo.getByStatus(InterventionStatus.active);
      expect(list.length, 1);
      expect(list.first.type, InterventionType.focusMode);
      expect(list.first.durationMinutes, 30);
    });

    test('3. Invalid duration: Durasi Focus Mode <= 0 melempar ArgumentError', () async {
      final mock = MockFocusModeNativeProvider();
      final service = InterventionService(
        nativeProvider: mock,
        historyRepository: repo,
      );

      expect(() => service.startFocusMode(0), throwsArgumentError);
      expect(() => service.startFocusMode(-10), throwsArgumentError);
      expect(service.isActive.value, isFalse);
      expect(mock.startFocusModeCalled, isFalse);
    });

    test('4. Active state: Reactive state mencerminkan Focus Mode aktif dan sisa waktu', () async {
      final mock = MockFocusModeNativeProvider();
      final service = InterventionService(
        nativeProvider: mock,
        historyRepository: repo,
      );

      await service.startFocusMode(15);

      expect(service.isActive.value, isTrue);
      expect(service.getActiveIntervention(), isNotNull);
      expect(service.getActiveIntervention()?.status, InterventionStatus.active);
      expect(service.getRemainingSeconds(), inInclusiveRange(890, 900));
    });

    test('5. Native start call: Mengirim parameter id, duration, dan endTimestampMillis ke native layer', () async {
      final mock = MockFocusModeNativeProvider();
      final service = InterventionService(
        nativeProvider: mock,
        historyRepository: repo,
      );

      final before = DateTime.now().millisecondsSinceEpoch;
      await service.startFocusMode(60);
      final after = DateTime.now().millisecondsSinceEpoch;

      expect(mock.startFocusModeCalled, isTrue);
      expect(mock.lastId, startsWith('focus_'));
      expect(mock.lastDurationMinutes, 60);
      expect(
        mock.lastEndTimestampMillis,
        inInclusiveRange(before + 3600000, after + 3600000),
      );
    });

    test('6. Native start failure: Rollback history saat native layer gagal menginisialisasi', () async {
      final mock = MockFocusModeNativeProvider();
      mock.startReturnSuccess = false; // Simulasikan native failure
      final service = InterventionService(
        nativeProvider: mock,
        historyRepository: repo,
      );

      final success = await service.startFocusMode(15);

      expect(success, isFalse);
      expect(service.isActive.value, isFalse);

      // Verifikasi history di-rollback menjadi cancelled
      final list = await repo.getByStatus(InterventionStatus.active);
      expect(list, isEmpty);
      final cancelledList = await repo.getByStatus(InterventionStatus.cancelled);
      expect(cancelledList.length, 1);
    });

    test('7. Complete Focus Mode: Memperbarui history menjadi completed dan menghentikan native state', () async {
      final mock = MockFocusModeNativeProvider();
      final service = InterventionService(
        nativeProvider: mock,
        historyRepository: repo,
      );

      await service.startFocusMode(15);
      expect(service.isActive.value, isTrue);

      await service.completeIntervention();

      expect(service.isActive.value, isFalse);
      expect(service.remainingSeconds.value, 0);
      expect(mock.stopFocusModeCalled, isTrue);

      final completedList = await repo.getByStatus(InterventionStatus.completed);
      expect(completedList.length, 1);
      expect(completedList.first.type, InterventionType.focusMode);
      expect(completedList.first.status, InterventionStatus.completed);
      expect(completedList.first.cancelledAt, isNull);
    });

    test('8. Cancel Focus Mode: Memperbarui history menjadi cancelled dan menghentikan native state', () async {
      final mock = MockFocusModeNativeProvider();
      final service = InterventionService(
        nativeProvider: mock,
        historyRepository: repo,
      );

      await service.startFocusMode(30);
      await service.cancelIntervention();

      expect(service.isActive.value, isFalse);
      expect(service.remainingSeconds.value, 0);
      expect(mock.stopFocusModeCalled, isTrue);

      final cancelledList = await repo.getByStatus(InterventionStatus.cancelled);
      expect(cancelledList.length, 1);
      expect(cancelledList.first.type, InterventionType.focusMode);
      expect(cancelledList.first.status, InterventionStatus.cancelled);
      expect(cancelledList.first.cancelledAt, isNotNull);
    });

    test('9. Recovery active: Memulihkan Focus Mode yang masih aktif saat cold-start tanpa membuat duplikat', () async {
      final mock = MockFocusModeNativeProvider();
      final now = DateTime.now();
      final ended = now.add(const Duration(minutes: 20));

      mock.storedStatus = {
        'id': 'focus_test_recovery_1',
        'type': 'focusMode',
        'title': 'Mode Fokus',
        'durationMinutes': 30,
        'startedAt': now.subtract(const Duration(minutes: 10)).toIso8601String(),
        'endedAt': ended.toIso8601String(),
        'status': 'active',
        'createdAt': now.subtract(const Duration(minutes: 10)).toIso8601String(),
      };

      // Buat record existing di database
      await repo.insert(InterventionModel(
        id: 'focus_test_recovery_1',
        type: InterventionType.focusMode,
        title: 'Mode Fokus',
        durationMinutes: 30,
        startedAt: now.subtract(const Duration(minutes: 10)),
        endedAt: ended,
        status: InterventionStatus.active,
        createdAt: now.subtract(const Duration(minutes: 10)),
      ));

      final service = InterventionService(
        nativeProvider: mock,
        historyRepository: repo,
      );

      await service.restoreActiveIntervention();

      expect(service.isActive.value, isTrue);
      expect(service.activeIntervention.value?.id, 'focus_test_recovery_1');
      expect(service.remainingSeconds.value, inInclusiveRange(1190, 1205));

      // Verifikasi tidak ada baris duplikat
      final allRows = await repo.getRecent(limit: 10);
      expect(allRows.length, 1);
    });

    test('10. Recovery expired: Focus Mode yang kedaluwarsa saat app ditutup ditandai completed dan native dibersihkan', () async {
      final mock = MockFocusModeNativeProvider();
      final now = DateTime.now();
      final ended = now.subtract(const Duration(minutes: 5));

      mock.storedStatus = {
        'id': 'focus_test_expired_1',
        'type': 'focusMode',
        'title': 'Mode Fokus',
        'durationMinutes': 15,
        'startedAt': now.subtract(const Duration(minutes: 20)).toIso8601String(),
        'endedAt': ended.toIso8601String(),
        'status': 'active',
        'createdAt': now.subtract(const Duration(minutes: 20)).toIso8601String(),
      };

      await repo.insert(InterventionModel(
        id: 'focus_test_expired_1',
        type: InterventionType.focusMode,
        title: 'Mode Fokus',
        durationMinutes: 15,
        startedAt: now.subtract(const Duration(minutes: 20)),
        endedAt: ended,
        status: InterventionStatus.active,
        createdAt: now.subtract(const Duration(minutes: 20)),
      ));

      final service = InterventionService(
        nativeProvider: mock,
        historyRepository: repo,
      );

      await service.restoreActiveIntervention();

      expect(service.isActive.value, isFalse);
      expect(mock.stopFocusModeCalled, isTrue);

      final row = await repo.getById('focus_test_expired_1');
      expect(row?.status, InterventionStatus.completed);
    });

    test('11. No duplicate history: Memulai Focus Mode berturut-turut membatalkan yang lama dan tidak menduplikasi ID', () async {
      final mock = MockFocusModeNativeProvider();
      final service = InterventionService(
        nativeProvider: mock,
        historyRepository: repo,
      );

      await service.startFocusMode(15);
      final firstId = service.activeIntervention.value!.id;

      await service.startFocusMode(30);
      final secondId = service.activeIntervention.value!.id;

      expect(firstId, isNot(equals(secondId)));

      final firstRow = await repo.getById(firstId);
      final secondRow = await repo.getById(secondId);

      expect(firstRow?.status, InterventionStatus.cancelled);
      expect(secondRow?.status, InterventionStatus.active);
    });

    test('12. User isolation: Record Focus Mode terisolasi berdasarkan userId yang benar', () async {
      final now = DateTime.now();
      final modelUserA = InterventionModel(
        id: 'focus_user_a',
        userId: 'user_A_uuid',
        type: InterventionType.focusMode,
        title: 'Mode Fokus',
        durationMinutes: 30,
        startedAt: now,
        endedAt: now.add(const Duration(minutes: 30)),
        status: InterventionStatus.completed,
        createdAt: now,
      );
      final modelUserB = InterventionModel(
        id: 'focus_user_b',
        userId: 'user_B_uuid',
        type: InterventionType.focusMode,
        title: 'Mode Fokus',
        durationMinutes: 60,
        startedAt: now,
        endedAt: now.add(const Duration(minutes: 60)),
        status: InterventionStatus.completed,
        createdAt: now,
      );

      await repo.insert(modelUserA, userId: 'user_A_uuid');
      await repo.insert(modelUserB, userId: 'user_B_uuid');

      final statsA = await repo.getStatistics(userId: 'user_A_uuid');
      final statsB = await repo.getStatistics(userId: 'user_B_uuid');

      expect(statsA.focusModeCount, 1);
      expect(statsA.totalDurationMinutes, 30);
      expect(statsB.focusModeCount, 1);
      expect(statsB.totalDurationMinutes, 60);

      final rowAFromB = await repo.getById('focus_user_a', userId: 'user_B_uuid');
      expect(rowAFromB, isNull);
    });

    test('13. Target package detection: Centralized DoomscrollConfig memetakan seluruh package target terdaftar', () {
      final file = File('android/app/src/main/kotlin/com/hn/mind_drji/DoomscrollAccessibilityService.kt');
      expect(file.existsSync(), isTrue);
      final content = file.readAsStringSync();

      expect(content, contains('com.ss.android.ugc.trill'));
      expect(content, contains('com.zhiliaoapp.musically'));
      expect(content, contains('com.instagram.android'));
      expect(content, contains('com.google.android.youtube'));
      expect(content, contains('com.snapchat.android'));
    });

    test('14. Excluded package: Helper isExcludedPackage mengecualikan MIND DRIJI, System UI, Settings, dan Dialer', () {
      final file = File('android/app/src/main/kotlin/com/hn/mind_drji/DoomscrollAccessibilityService.kt');
      final content = file.readAsStringSync();

      expect(content, contains('fun isExcludedPackage'));
      expect(content, contains('applicationContext.packageName'));
      expect(content, contains('com.android.systemui'));
      expect(content, contains('com.android.settings'));
      expect(content, contains('com.android.dialer'));
      expect(content, contains('isLauncherPackage'));
    });

    test('15. Inactive Focus Mode does nothing: Service tidak memicu soft-blocking saat status inactive', () {
      final file = File('android/app/src/main/kotlin/com/hn/mind_drji/DoomscrollAccessibilityService.kt');
      final content = file.readAsStringSync();

      expect(content, contains('if (!isFocusModeActive(applicationContext))'));
      expect(content, contains('return false'));
    });

    test('16. Active Focus Mode triggers active restriction with GLOBAL_ACTION_HOME', () {
      final file = File('android/app/src/main/kotlin/com/hn/mind_drji/DoomscrollAccessibilityService.kt');
      final content = file.readAsStringSync();

      expect(content, contains('checkFocusModeBlocking'));
      expect(content, contains('showFocusWarningNotification'));
      expect(content, contains('performGlobalAction(GLOBAL_ACTION_HOME)'));
    });

    test('17. Debounce interval: Soft blocking dibatasi oleh cooldown minimal 1500ms untuk mencegah navigation loop', () {
      final file = File('android/app/src/main/kotlin/com/hn/mind_drji/DoomscrollAccessibilityService.kt');
      final content = file.readAsStringSync();

      expect(content, contains('BLOCK_DEBOUNCE_MS = 1500L'));
      expect(content, contains('now - lastBlockedAt < BLOCK_DEBOUNCE_MS'));
    });

    test('18. Timestamp expiration: isFocusModeActive memeriksa apakah now < endedAt', () {
      final file = File('android/app/src/main/kotlin/com/hn/mind_drji/DoomscrollAccessibilityService.kt');
      final content = file.readAsStringSync();

      expect(content, contains('now < endedAt'));
      expect(content, contains('status == "active"'));
      expect(content, contains('type == "focusMode"'));
    });

    test('19. Content privacy: canRetrieveWindowContent tetap false pada config XML', () {
      final xmlFile = File('android/app/src/main/res/xml/accessibility_service_config.xml');
      expect(xmlFile.existsSync(), isTrue);
      final xmlContent = xmlFile.readAsStringSync();

      expect(xmlContent, contains('android:canRetrieveWindowContent="false"'));
      expect(xmlContent, contains('typeWindowStateChanged'));
    });

    test('20. Statistics verification: Focus Mode statistics tercatat secara presisi pada InterventionStatistics', () async {
      final now = DateTime.now();
      await repo.insert(InterventionModel(
        id: 'f_stat_1',
        type: InterventionType.focusMode,
        title: 'Mode Fokus',
        durationMinutes: 30,
        startedAt: now,
        endedAt: now.add(const Duration(minutes: 30)),
        status: InterventionStatus.completed,
        createdAt: now,
      ));

      await repo.insert(InterventionModel(
        id: 'f_stat_2',
        type: InterventionType.focusMode,
        title: 'Mode Fokus',
        durationMinutes: 15,
        startedAt: now,
        endedAt: now.add(const Duration(minutes: 15)),
        status: InterventionStatus.cancelled,
        cancelledAt: now.add(const Duration(minutes: 5)),
        createdAt: now,
      ));

      final stats = await repo.getStatistics();
      expect(stats.totalCount, 2);
      expect(stats.focusModeCount, 2);
      expect(stats.completedCount, 1);
      expect(stats.cancelledCount, 1);
      expect(stats.totalDurationMinutes, 30);
    });

    test('21. Separation of concerns: Native stopFocusMode sets inactive and removes cancelled_at; Flutter handles history', () {
      final mainActivityFile = File('android/app/src/main/kotlin/com/hn/mind_drji/MainActivity.kt');
      expect(mainActivityFile.existsSync(), isTrue);
      final content = mainActivityFile.readAsStringSync();

      expect(content, contains('"stopFocusMode"'));
      expect(content, contains('.putString("status", "inactive")'));
      expect(content, contains('.remove("cancelled_at")'));
    });
  });
}
