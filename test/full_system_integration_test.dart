import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mind_drji/app/data/local/app_database.dart';
import 'package:mind_drji/app/data/local/repositories/doomscroll_local_repository.dart';
import 'package:mind_drji/app/data/local/repositories/eye_monitoring_local_repository.dart';
import 'package:mind_drji/app/data/local/repositories/intervention_history_local_repository.dart';
import 'package:mind_drji/app/data/local/repositories/local_usage_repository.dart';
import 'package:mind_drji/app/data/local/tables/sync_queue.dart';
import 'package:mind_drji/app/data/models/app_usage_model.dart';
import 'package:mind_drji/app/data/models/behavioral_features.dart';
import 'package:mind_drji/app/data/models/detection_result.dart';
import 'package:mind_drji/app/data/models/doomscroll_session_model.dart';
import 'package:mind_drji/app/data/models/eye_monitoring_session_model.dart';
import 'package:mind_drji/app/data/models/intervention_model.dart';
import 'package:mind_drji/app/data/models/recommendation_model.dart';
import 'package:mind_drji/app/data/services/detection/detection_engine.dart';
import 'package:mind_drji/app/data/services/insight/insight_engine.dart';
import 'package:mind_drji/app/data/services/recommendation/recommendation_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late EyeMonitoringLocalRepository eyeRepo;
  late DoomscrollLocalRepository doomRepo;
  late LocalUsageRepository usageRepo;
  late InterventionHistoryLocalRepository historyRepo;

  setUp(() {
    Get.reset();
    db = AppDatabase(NativeDatabase.memory());
    eyeRepo = EyeMonitoringLocalRepository(db: db);
    doomRepo = DoomscrollLocalRepository(db: db);
    usageRepo = LocalUsageRepository(db: db);
    historyRepo = InterventionHistoryLocalRepository(db: db);
  });

  tearDown(() async {
    await db.close();
    Get.reset();
  });

  group('Full System Integration Tests', () {
    test('1. User Isolation: Data User A tidak bocor ke User B di seluruh repositories', () async {
      final now = DateTime.now();

      // Eye Monitoring: User A & User B
      await eyeRepo.insertSession(EyeMonitoringSessionModel(
        id: 'eye-user-a',
        userId: 'user_a_uuid',
        startedAt: now.subtract(const Duration(minutes: 10)),
        endedAt: now.subtract(const Duration(minutes: 9)),
        durationMillis: 60000,
        averageEar: 0.28,
        minEar: 0.18,
        eyeClosureEvents: 2,
        blinkCount: 15,
        collectedAt: now,
      ));
      await eyeRepo.insertSession(EyeMonitoringSessionModel(
        id: 'eye-user-b',
        userId: 'user_b_uuid',
        startedAt: now.subtract(const Duration(minutes: 5)),
        endedAt: now.subtract(const Duration(minutes: 4)),
        durationMillis: 60000,
        averageEar: 0.29,
        minEar: 0.20,
        eyeClosureEvents: 1,
        blinkCount: 18,
        collectedAt: now,
      ));

      final eyeSessionsUserB = await eyeRepo.getSessions(userId: 'user_b_uuid');
      expect(eyeSessionsUserB.any((s) => s.userId == 'user_a_uuid'), isFalse);
      expect(eyeSessionsUserB.every((s) => s.userId == 'user_b_uuid' || s.userId == 'local_user'), isTrue);

      // Doomscroll: User A & User B
      await doomRepo.insertSession(DoomscrollSessionModel(
        id: 'doom-user-a',
        userId: 'user_a_uuid',
        packageName: 'com.zhiliaoapp.musically',
        appName: 'TikTok',
        startedAt: now.subtract(const Duration(minutes: 30)),
        endedAt: now.subtract(const Duration(minutes: 15)),
        durationMillis: 900000,
        swipeCount: 80,
        downwardSwipeCount: 75,
        upwardSwipeCount: 5,
        avgInterSwipeMillis: 11000,
        collectedAt: now,
      ));
      await doomRepo.insertSession(DoomscrollSessionModel(
        id: 'doom-user-b',
        userId: 'user_b_uuid',
        packageName: 'com.instagram.android',
        appName: 'Instagram',
        startedAt: now.subtract(const Duration(minutes: 20)),
        endedAt: now.subtract(const Duration(minutes: 5)),
        durationMillis: 900000,
        swipeCount: 60,
        downwardSwipeCount: 55,
        upwardSwipeCount: 5,
        avgInterSwipeMillis: 15000,
        collectedAt: now,
      ));

      final doomBetweenB = await doomRepo.getSessionsBetween(
        start: now.subtract(const Duration(hours: 1)),
        end: now.add(const Duration(hours: 1)),
        userId: 'user_b_uuid',
      );
      expect(doomBetweenB.any((s) => s.userId == 'user_a_uuid'), isFalse);

      // Intervention History: User A & User B
      await historyRepo.insert(
        InterventionModel(
          id: 'inter-user-a',
          userId: 'user_a_uuid',
          type: InterventionType.digitalBreak,
          title: 'Break A',
          durationMinutes: 10,
          startedAt: now,
          endedAt: now.add(const Duration(minutes: 10)),
          status: InterventionStatus.completed,
          createdAt: now,
        ),
        userId: 'user_a_uuid',
      );
      await historyRepo.insert(
        InterventionModel(
          id: 'inter-user-b',
          userId: 'user_b_uuid',
          type: InterventionType.focusMode,
          title: 'Focus B',
          durationMinutes: 25,
          startedAt: now,
          endedAt: now.add(const Duration(minutes: 25)),
          status: InterventionStatus.completed,
          createdAt: now,
        ),
        userId: 'user_b_uuid',
      );

      final historyUserB = await historyRepo.getRecent(userId: 'user_b_uuid');
      expect(historyUserB.any((h) => h.userId == 'user_a_uuid'), isFalse);
    });

    test('2. Claim Local Data: Sesi offline local_user berhasil dialihkan ke user terautentikasi', () async {
      final now = DateTime.now();

      // Insert data offline under 'local_user'
      await eyeRepo.insertSession(EyeMonitoringSessionModel(
        id: 'eye-local-1',
        userId: 'local_user',
        startedAt: now.subtract(const Duration(minutes: 5)),
        durationMillis: 60000,
        averageEar: 0.28,
        minEar: 0.18,
        eyeClosureEvents: 2,
        blinkCount: 15,
        collectedAt: now,
      ));
      await doomRepo.insertSession(DoomscrollSessionModel(
        id: 'doom-local-1',
        userId: 'local_user',
        packageName: 'com.zhiliaoapp.musically',
        appName: 'TikTok',
        startedAt: now.subtract(const Duration(minutes: 20)),
        durationMillis: 600000,
        swipeCount: 50,
        downwardSwipeCount: 45,
        upwardSwipeCount: 5,
        avgInterSwipeMillis: 12000,
        collectedAt: now,
      ));
      await usageRepo.saveTodayUsage(
        userId: 'local_user',
        date: '2026-10-01',
        totalUsageMillis: 3600000,
        apps: [
          const AppUsageModel(packageName: 'com.whatsapp', appName: 'WhatsApp', usageMillis: 3600000),
        ],
      );

      // Klaim seluruh sesi lokal oleh user yang baru login
      const authenticatedUserId = 'auth-uuid-test-999';
      await eyeRepo.claimLocalSessions(authenticatedUserId);
      final claimedDoom = await doomRepo.claimLocalSessions(authenticatedUserId);
      final claimedUsage = await usageRepo.claimLocalUsage(authenticatedUserId);

      expect(claimedDoom, greaterThanOrEqualTo(1));
      expect(claimedUsage, greaterThanOrEqualTo(1));

      // Verifikasi di DB bahwa sesi telah berpindah ke authenticated user
      final eyeSession = await eyeRepo.getSessionById('eye-local-1');
      expect(eyeSession?.userId, authenticatedUserId);

      final doomSession = await doomRepo.getSessionById('doom-local-1');
      expect(doomSession?.userId, authenticatedUserId);

      final stData = await usageRepo.getScreenTime(authenticatedUserId, '2026-10-01');
      expect(stData?.userId, authenticatedUserId);
    });

    test('3. Half-Open Interval [start, end) mencegah duplikasi boundary', () async {
      final boundary = DateTime(2026, 10, 1, 0, 0, 0); // 00:00:00
      final yesterdayStart = DateTime(2026, 9, 30, 0, 0, 0);
      final todayEnd = DateTime(2026, 10, 2, 0, 0, 0);

      // Session exactly at midnight boundary
      await eyeRepo.insertSession(EyeMonitoringSessionModel(
        id: 'eye-midnight',
        userId: 'user-boundary',
        startedAt: boundary,
        durationMillis: 60000,
        averageEar: 0.28,
        minEar: 0.18,
        eyeClosureEvents: 2,
        blinkCount: 15,
        collectedAt: boundary,
      ));

      // Yesterday range [yesterdayStart, boundary) -> should NOT include session at boundary
      final yesterdaySessions = await eyeRepo.getSessionsBetween(
        start: yesterdayStart,
        end: boundary,
        userId: 'user-boundary',
      );
      expect(yesterdaySessions.any((s) => s.id == 'eye-midnight'), isFalse);

      // Today range [boundary, todayEnd) -> MUST include session at boundary
      final todaySessions = await eyeRepo.getSessionsBetween(
        start: boundary,
        end: todayEnd,
        userId: 'user-boundary',
      );
      expect(todaySessions.any((s) => s.id == 'eye-midnight'), isTrue);
    });

    test('4. Single Source of Truth: Detection -> Insight -> Recommendation Engine', () {
      final engine = DetectionEngine();
      const insightEngine = InsightEngine();
      const recEngine = RecommendationEngine();

      final now = DateTime(2026, 10, 1, 14, 0);

      // Feature extraction input with long session & downward pattern
      final features = BehavioralFeatures(
        date: now,
        totalScrollingDurationMillis: 2400000, // 40 menit
        totalScrollingSessions: 1,
        totalSwipeCount: 280,
        totalDownwardSwipeCount: 260,
        totalUpwardSwipeCount: 20,
        averageInterSwipeMillis: 8500,
        topScrollingApp: 'TikTok',
        longestSessionDurationMillis: 2400000,
      );

      // 1. Detection Engine analyzes features
      final detection = engine.analyze(features);
      expect(detection.detected, isTrue);
      expect(detection.type, DetectionType.longScrollSession);

      // 2. Insight Engine generates insights directly from detection result
      final insights = insightEngine.generateInsights(
        detection: detection,
        features: features,
        totalScreenTimeMillis: 3600000,
      );
      expect(insights.isNotEmpty, isTrue);
      expect(insights.first.title.toLowerCase(), contains('sesi scrolling panjang terdeteksi'));

      // 3. Recommendation Engine generates recommendations without auto-starting intervention
      final recommendations = recEngine.generateFromDetection(
        detection: detection,
        features: features,
      );
      expect(recommendations.isNotEmpty, isTrue);
      expect(recommendations.first.type, RecommendationType.digitalBreak);
      expect(recommendations.first.durationOptions.isNotEmpty, isTrue);
    });

    test('5. Sync Queue consistency across entity types', () async {
      final now = DateTime.now();

      await usageRepo.saveTodayUsage(
        userId: 'user-sync-test',
        date: '2026-10-01',
        totalUsageMillis: 7200000,
        apps: [
          const AppUsageModel(packageName: 'com.whatsapp', appName: 'WhatsApp', usageMillis: 7200000),
        ],
      );

      await doomRepo.insertSession(DoomscrollSessionModel(
        id: 'doom-sync-1',
        userId: 'user-sync-test',
        packageName: 'com.zhiliaoapp.musically',
        appName: 'TikTok',
        startedAt: now,
        durationMillis: 300000,
        swipeCount: 30,
        downwardSwipeCount: 28,
        upwardSwipeCount: 2,
        avgInterSwipeMillis: 10000,
        collectedAt: now,
      ));

      await eyeRepo.insertSession(EyeMonitoringSessionModel(
        id: 'eye-sync-1',
        userId: 'user-sync-test',
        startedAt: now,
        durationMillis: 60000,
        averageEar: 0.28,
        minEar: 0.18,
        eyeClosureEvents: 2,
        blinkCount: 15,
        collectedAt: now,
      ));

      final queue = await usageRepo.getPendingQueue();
      // 1 screen_time + 1 app_usage + 1 doomscroll + 1 eye_monitoring = 4
      expect(queue.length, 4);

      final entityTypes = queue.map((q) => q.entityType).toSet();
      expect(entityTypes.contains(SyncEntityType.screenTimeDaily), isTrue);
      expect(entityTypes.contains(SyncEntityType.appUsageDaily), isTrue);
      expect(entityTypes.contains(SyncEntityType.doomscrollSession), isTrue);
      expect(entityTypes.contains(SyncEntityType.eyeMonitoringSession), isTrue);
    });
  });
}
