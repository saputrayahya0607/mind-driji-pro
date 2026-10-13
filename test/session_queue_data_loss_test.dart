import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:mind_drji/app/data/local/app_database.dart';
import 'package:mind_drji/app/data/local/repositories/doomscroll_local_repository.dart';
import 'package:mind_drji/app/data/local/repositories/eye_monitoring_local_repository.dart';
import 'package:mind_drji/app/data/models/doomscroll_session_model.dart';
import 'package:mind_drji/app/data/models/eye_monitoring_session_model.dart';
import 'package:mind_drji/app/data/providers/doomscroll_native_provider.dart';
import 'package:mind_drji/app/data/providers/eye_monitoring_native_provider.dart';
import 'package:mind_drji/app/data/repositories/doomscroll_repository.dart';
import 'package:mind_drji/app/data/repositories/eye_monitoring_repository.dart';

// =============================================================================
// TEST HELPERS
// =============================================================================

DoomscrollSessionModel createDoomSession({
  required String id,
  String packageName = 'com.ss.android.ugc.trill',
  String appName = 'TikTok',
  DateTime? startedAt,
  DateTime? endedAt,
  int durationMillis = 300000,
  int swipeCount = 30,
  int downwardSwipeCount = 25,
  int upwardSwipeCount = 5,
  int avgInterSwipeMillis = 10000,
  DateTime? collectedAt,
}) {
  final now = DateTime.now();
  return DoomscrollSessionModel(
    id: id,
    packageName: packageName,
    appName: appName,
    startedAt: startedAt ?? now.subtract(const Duration(minutes: 5)),
    endedAt: endedAt ?? now,
    durationMillis: durationMillis,
    swipeCount: swipeCount,
    downwardSwipeCount: downwardSwipeCount,
    upwardSwipeCount: upwardSwipeCount,
    avgInterSwipeMillis: avgInterSwipeMillis,
    collectedAt: collectedAt ?? now,
  );
}

EyeMonitoringSessionModel createEyeSession({
  required String id,
  DateTime? startedAt,
  DateTime? endedAt,
  int durationMillis = 300000,
  double averageEar = 0.28,
  double minEar = 0.15,
  int eyeClosureEvents = 2,
  int blinkCount = 15,
  DateTime? collectedAt,
}) {
  final now = DateTime.now();
  return EyeMonitoringSessionModel(
    id: id,
    startedAt: startedAt ?? now.subtract(const Duration(minutes: 5)),
    endedAt: endedAt ?? now,
    durationMillis: durationMillis,
    averageEar: averageEar,
    minEar: minEar,
    eyeClosureEvents: eyeClosureEvents,
    blinkCount: blinkCount,
    collectedAt: collectedAt ?? now,
  );
}

// =============================================================================
// FAKE PROVIDERS EMULATING NATIVE QUEUE WITH SELECTIVE ACKNOWLEDGMENT
// =============================================================================

class FakeDoomscrollNativeQueueProvider extends DoomscrollNativeProvider {
  final List<DoomscrollSessionModel> queue = [];

  void enqueue(DoomscrollSessionModel session) {
    queue.add(session);
  }

  @override
  Future<List<DoomscrollSessionModel>> flushCurrentDoomscrollSession({
    String? defaultUserId,
  }) async {
    return List.from(queue);
  }

  @override
  Future<bool> clearPendingDoomscrollSessions({List<String>? sessionIds}) async {
    if (sessionIds != null) {
      if (sessionIds.isEmpty) {
        return false; // Empty ack: queue untouched
      }
      queue.removeWhere((s) => sessionIds.contains(s.id));
      return true;
    }
    queue.clear();
    return true;
  }
}

class FakeEyeMonitoringNativeQueueProvider extends EyeMonitoringNativeProvider {
  final List<EyeMonitoringSessionModel> queue = [];

  void enqueue(EyeMonitoringSessionModel session) {
    queue.add(session);
  }

  @override
  Future<List<EyeMonitoringSessionModel>> getPendingSessions({
    String? defaultUserId,
  }) async {
    return List.from(queue);
  }

  @override
  Future<bool> clearPendingSessions({List<String>? sessionIds}) async {
    if (sessionIds != null) {
      if (sessionIds.isEmpty) {
        return false; // Empty ack: queue untouched
      }
      queue.removeWhere((s) => sessionIds.contains(s.id));
      return true;
    }
    queue.clear();
    return true;
  }
}

// Repositories injecting simulated database failures
class FailingDoomscrollLocalRepository extends DoomscrollLocalRepository {
  final Set<String> failingSessionIds = {};
  bool failAll = false;

  FailingDoomscrollLocalRepository({required super.db});

  @override
  Future<void> insertSession(DoomscrollSessionModel session) async {
    if (failAll || failingSessionIds.contains(session.id)) {
      throw Exception('Simulated SQLite write error for doomscroll session ${session.id}');
    }
    return super.insertSession(session);
  }
}

class FailingEyeMonitoringLocalRepository extends EyeMonitoringLocalRepository {
  final Set<String> failingSessionIds = {};
  bool failAll = false;

  FailingEyeMonitoringLocalRepository({required super.db});

  @override
  Future<void> insertSession(EyeMonitoringSessionModel session) async {
    if (failAll || failingSessionIds.contains(session.id)) {
      throw Exception('Simulated SQLite write error for eye monitoring session ${session.id}');
    }
    return super.insertSession(session);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SESSION QUEUE DATA LOSS & ACKNOWLEDGMENT REGRESSION TESTS', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    // -------------------------------------------------------------------------
    // 1. INTERLEAVED ENQUEUE
    // -------------------------------------------------------------------------
    test('1. Interleaved enqueue (Doomscroll): Session B enqueued before Session A ack remains in queue', () async {
      final fakeProvider = FakeDoomscrollNativeQueueProvider();
      final localRepo = DoomscrollLocalRepository(db: db);
      final repo = DoomscrollRepository(
        provider: fakeProvider,
        localRepository: localRepo,
      );

      final sessionA = createDoomSession(id: 'doom-session-A', packageName: 'com.ss.android.ugc.trill');
      final sessionB = createDoomSession(id: 'doom-session-B', packageName: 'com.instagram.android');

      // Step 1: Session A in native queue
      fakeProvider.enqueue(sessionA);

      // Trigger flush: processes Session A
      final count1 = await repo.collectAndPersistPendingSessions();
      expect(count1, 1);

      // Verify Session A is safely in DB
      final storedAfterA = await localRepo.getSessionById('doom-session-A');
      expect(storedAfterA, isNotNull);
      expect(storedAfterA!.packageName, 'com.ss.android.ugc.trill');

      // Simulate native enqueue of Session B after Session A was collected
      fakeProvider.enqueue(sessionB);
      expect(fakeProvider.queue.map((s) => s.id), contains('doom-session-B'));
      expect(fakeProvider.queue.map((s) => s.id), isNot(contains('doom-session-A')));

      // Second flush: Session B collected and acknowledged without dropping
      final count2 = await repo.collectAndPersistPendingSessions();
      expect(count2, 1);
      expect(fakeProvider.queue, isEmpty);

      final storedAfterB = await localRepo.getSessionById('doom-session-B');
      expect(storedAfterB, isNotNull);
      expect(storedAfterB!.packageName, 'com.instagram.android');
    });

    test('1b. Interleaved enqueue (Eye Monitoring): Session B enqueued before Session A ack remains in queue', () async {
      final fakeProvider = FakeEyeMonitoringNativeQueueProvider();
      final localRepo = EyeMonitoringLocalRepository(db: db);
      final repo = EyeMonitoringRepository(
        provider: fakeProvider,
        localRepository: localRepo,
      );

      final sessionA = createEyeSession(id: 'eye-session-A');
      final sessionB = createEyeSession(id: 'eye-session-B');

      fakeProvider.enqueue(sessionA);

      // Run flush for sessionA
      final flushed1 = await repo.flushPendingSessions();
      expect(flushed1.length, 1);
      expect(flushed1.first.id, 'eye-session-A');

      // Enqueue sessionB and verify queue state
      fakeProvider.enqueue(sessionB);
      expect(fakeProvider.queue.any((s) => s.id == 'eye-session-B'), isTrue);
      expect(fakeProvider.queue.any((s) => s.id == 'eye-session-A'), isFalse);

      final flushed2 = await repo.flushPendingSessions();
      expect(flushed2.length, 1);
      expect(flushed2.first.id, 'eye-session-B');
      expect(fakeProvider.queue, isEmpty);

      final storedA = await localRepo.getSessionById('eye-session-A');
      final storedB = await localRepo.getSessionById('eye-session-B');
      expect(storedA, isNotNull);
      expect(storedB, isNotNull);
    });

    // -------------------------------------------------------------------------
    // 2. DATABASE FAILURE
    // -------------------------------------------------------------------------
    test('2. Database failure: unpersisted session is NOT acknowledged and is retried successfully', () async {
      final fakeProvider = FakeDoomscrollNativeQueueProvider();
      final failingRepo = FailingDoomscrollLocalRepository(db: db);
      final repo = DoomscrollRepository(
        provider: fakeProvider,
        localRepository: failingRepo,
      );

      final sessionA = createDoomSession(id: 'fail-session-1');
      fakeProvider.enqueue(sessionA);

      // Force database failure for this session
      failingRepo.failingSessionIds.add('fail-session-1');

      // Flush should fail to persist and NOT acknowledge
      final result1 = await repo.collectAndPersistPendingSessions();
      expect(result1, 0);

      // Session must still be preserved in the native queue!
      expect(fakeProvider.queue.length, 1);
      expect(fakeProvider.queue.first.id, 'fail-session-1');

      // Now heal the database
      failingRepo.failingSessionIds.clear();

      // Flush again: should now succeed and acknowledge
      final result2 = await repo.collectAndPersistPendingSessions();
      expect(result2, 1);
      expect(fakeProvider.queue, isEmpty);

      final stored = await failingRepo.getSessionById('fail-session-1');
      expect(stored, isNotNull);
    });

    // -------------------------------------------------------------------------
    // 3. RETRY EYE MONITORING (IDEMPOTENCY)
    // -------------------------------------------------------------------------
    test('3. Retry Eye Monitoring: retransmitting same session ID is idempotent and does not throw', () async {
      final fakeProvider = FakeEyeMonitoringNativeQueueProvider();
      final localRepo = EyeMonitoringLocalRepository(db: db);
      final repo = EyeMonitoringRepository(
        provider: fakeProvider,
        localRepository: localRepo,
      );

      final session = createEyeSession(id: 'idempotent-eye-1');

      // First run: enqueue and flush
      fakeProvider.enqueue(session);
      final flushed1 = await repo.flushPendingSessions();
      expect(flushed1.length, 1);

      final stored1 = await localRepo.getSessionById('idempotent-eye-1');
      expect(stored1, isNotNull);

      // Second run: same session re-enqueued (retry/retransmit scenario)
      fakeProvider.enqueue(session);
      expect(fakeProvider.queue.length, 1);

      // Flush again: must NOT throw UNIQUE constraint failed and must succeed
      final flushed2 = await repo.flushPendingSessions();
      expect(flushed2.length, 1);
      expect(fakeProvider.queue, isEmpty);

      // Ensure no duplication in SQLite
      final allStored = await localRepo.getSessions();
      final matching = allStored.where((s) => s.id == 'idempotent-eye-1').toList();
      expect(matching.length, 1);
    });

    // -------------------------------------------------------------------------
    // 4. PARTIAL FAILURE
    // -------------------------------------------------------------------------
    test('4. Partial failure: only successfully persisted session is acknowledged', () async {
      final fakeProvider = FakeEyeMonitoringNativeQueueProvider();
      final failingRepo = FailingEyeMonitoringLocalRepository(db: db);
      final repo = EyeMonitoringRepository(
        provider: fakeProvider,
        localRepository: failingRepo,
      );

      final sessionSuccess = createEyeSession(id: 'partial-success-A');
      final sessionFail = createEyeSession(id: 'partial-fail-B');

      fakeProvider.enqueue(sessionSuccess);
      fakeProvider.enqueue(sessionFail);

      // Configure B to fail
      failingRepo.failingSessionIds.add('partial-fail-B');

      final flushed = await repo.flushPendingSessions();
      expect(flushed.length, 1);
      expect(flushed.first.id, 'partial-success-A');

      // Only A was acknowledged! B MUST remain in the queue
      expect(fakeProvider.queue.length, 1);
      expect(fakeProvider.queue.first.id, 'partial-fail-B');

      // SQLite has A, but not B
      final storedA = await failingRepo.getSessionById('partial-success-A');
      final storedB = await failingRepo.getSessionById('partial-fail-B');
      expect(storedA, isNotNull);
      expect(storedB, isNull);

      // Heal B and retry
      failingRepo.failingSessionIds.clear();
      final retryFlushed = await repo.flushPendingSessions();
      expect(retryFlushed.length, 1);
      expect(retryFlushed.first.id, 'partial-fail-B');
      expect(fakeProvider.queue, isEmpty);
    });

    // -------------------------------------------------------------------------
    // 5. CONCURRENT FLUSH
    // -------------------------------------------------------------------------
    test('5. Concurrent flush: simultaneous calls do not drop sessions or duplicate data', () async {
      final fakeProvider = FakeDoomscrollNativeQueueProvider();
      final localRepo = DoomscrollLocalRepository(db: db);
      final repo = DoomscrollRepository(
        provider: fakeProvider,
        localRepository: localRepo,
      );

      for (int i = 0; i < 5; i++) {
        fakeProvider.enqueue(
          createDoomSession(id: 'concurrent-sess-$i', swipeCount: 10 + i),
        );
      }

      // Launch two concurrent flushes at the exact same instant
      final results = await Future.wait([
        repo.collectAndPersistPendingSessions(),
        repo.collectAndPersistPendingSessions(),
      ]);

      // Total collected across both calls must equal 5 (first caller processes all, second sees empty or remaining)
      final totalProcessed = results[0] + results[1];
      expect(totalProcessed, 5);

      // Queue must be completely empty
      expect(fakeProvider.queue, isEmpty);

      // SQLite must contain exactly 5 unique sessions
      final stored = await localRepo.getSessions();
      expect(stored.length, 5);
      final uniqueIds = stored.map((s) => s.id).toSet();
      expect(uniqueIds.length, 5);
    });

    // -------------------------------------------------------------------------
    // 6. EMPTY ACKNOWLEDGMENT
    // -------------------------------------------------------------------------
    test('6. Empty acknowledgment: empty ID list does not clear the queue', () async {
      final fakeDoomProvider = FakeDoomscrollNativeQueueProvider();
      final fakeEyeProvider = FakeEyeMonitoringNativeQueueProvider();

      fakeDoomProvider.enqueue(createDoomSession(id: 'doom-keep-1'));
      fakeEyeProvider.enqueue(createEyeSession(id: 'eye-keep-1'));

      // Call clear with empty sessionIds
      final doomCleared = await fakeDoomProvider.clearPendingDoomscrollSessions(sessionIds: []);
      final eyeCleared = await fakeEyeProvider.clearPendingSessions(sessionIds: []);

      expect(doomCleared, isFalse);
      expect(eyeCleared, isFalse);

      // Both queues must still have their items intact
      expect(fakeDoomProvider.queue.length, 1);
      expect(fakeDoomProvider.queue.first.id, 'doom-keep-1');

      expect(fakeEyeProvider.queue.length, 1);
      expect(fakeEyeProvider.queue.first.id, 'eye-keep-1');
    });

    // -------------------------------------------------------------------------
    // 7. QUEUE PERSISTENCE
    // -------------------------------------------------------------------------
    test('7. Queue persistence: unacknowledged sessions remain available across reads', () async {
      final fakeProvider = FakeEyeMonitoringNativeQueueProvider();

      final sess = createEyeSession(id: 'persist-check-1');
      fakeProvider.enqueue(sess);

      // Reading pending sessions does NOT remove them
      final read1 = await fakeProvider.getPendingSessions();
      expect(read1.length, 1);
      expect(fakeProvider.queue.length, 1);

      final read2 = await fakeProvider.getPendingSessions();
      expect(read2.length, 1);
      expect(fakeProvider.queue.length, 1);

      // Only explicit acknowledgment removes them
      await fakeProvider.clearPendingSessions(sessionIds: ['persist-check-1']);
      expect(fakeProvider.queue, isEmpty);
    });
  });
}
