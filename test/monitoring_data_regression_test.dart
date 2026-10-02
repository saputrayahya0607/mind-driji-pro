import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:mind_drji/app/data/local/app_database.dart';
import 'package:mind_drji/app/data/local/repositories/doomscroll_local_repository.dart';
import 'package:mind_drji/app/data/local/repositories/eye_monitoring_local_repository.dart';
import 'package:mind_drji/app/data/local/repositories/local_usage_repository.dart';
import 'package:mind_drji/app/data/models/doomscroll_session_model.dart';
import 'package:mind_drji/app/data/models/monitoring_visualization_model.dart';
import 'package:mind_drji/app/data/repositories/doomscroll_repository.dart';
import 'package:mind_drji/app/data/repositories/eye_monitoring_repository.dart';
import 'package:mind_drji/app/data/repositories/usage_stats_repository.dart';
import 'package:mind_drji/app/data/services/monitoring_data_service.dart';
import 'package:mind_drji/app/modules/home/controllers/home_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late DoomscrollLocalRepository localRepo;
  late DoomscrollRepository doomRepo;
  late LocalUsageRepository localUsageRepo;
  late EyeMonitoringRepository eyeRepo;
  late UsageStatsRepository usageStatsRepo;
  late MonitoringDataService dataService;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    localRepo = DoomscrollLocalRepository(db: db);
    doomRepo = DoomscrollRepository(localRepository: localRepo);
    localUsageRepo = LocalUsageRepository(db: db);
    eyeRepo = EyeMonitoringRepository(
      localRepository: EyeMonitoringLocalRepository(db: db),
    );
    usageStatsRepo = UsageStatsRepository(localRepository: localUsageRepo);
    dataService = MonitoringDataService(
      doomscrollRepo: doomRepo,
      localUsageRepo: localUsageRepo,
      usageStatsRepo: usageStatsRepo,
      eyeRepo: eyeRepo,
    );
  });

  tearDown(() async {
    await db.close();
  });

  DoomscrollSessionModel createSession({
    required String id,
    String userId = 'test_user',
    required DateTime startedAt,
    DateTime? endedAt,
    int durationMillis = 60000,
    int swipeCount = 20,
    int downwardSwipeCount = 15,
    int upwardSwipeCount = 5,
    String packageName = 'com.ss.android.ugc.trill',
    String appName = 'TikTok',
  }) {
    return DoomscrollSessionModel(
      id: id,
      userId: userId,
      packageName: packageName,
      appName: appName,
      startedAt: startedAt,
      endedAt: endedAt ?? startedAt.add(Duration(milliseconds: durationMillis)),
      durationMillis: durationMillis,
      swipeCount: swipeCount,
      downwardSwipeCount: downwardSwipeCount,
      upwardSwipeCount: upwardSwipeCount,
      avgInterSwipeMillis: 3000,
      collectedAt: DateTime.now(),
    );
  }

  // 1. 13 session hari ini -> Daily tidak kosong
  test('1. 13 session hari ini -> Daily tidak kosong, sessionCount=13, totalScrolls>0, totalDuration>0', () async {
    final today = DateTime(2026, 10, 1);
    final sessions = List.generate(13, (i) {
      final start = DateTime(2026, 10, 1, 8 + (i ~/ 2), (i % 2) * 25, 0);
      return createSession(
        id: 'session_$i',
        startedAt: start,
        durationMillis: 45000 + (i * 5000),
        swipeCount: 10 + i * 2,
        downwardSwipeCount: 8 + i,
        upwardSwipeCount: 2 + i,
      );
    });

    await localRepo.insertSessions(sessions);

    final summary = await dataService.getDoomscrollSummary(
      period: MonitoringPeriod.daily,
      date: today,
      userId: 'test_user',
    );

    expect(summary.totalSessions, equals(13));
    expect(summary.totalSwipes, greaterThan(0));
    expect(summary.totalDurationMillis, greaterThan(0));
    expect(summary.downwardSwipes, greaterThan(0));
    expect(summary.upwardSwipes, greaterThan(0));
    expect(summary.hasData, isTrue);
  });

  // 2. session tepat 00:00 -> masuk hari tersebut
  test('2. session tepat 00:00:00 -> masuk hari tersebut (half-open interval start)', () async {
    final today = DateTime(2026, 10, 1);
    final session = createSession(
      id: 'session_midnight',
      startedAt: DateTime(2026, 10, 1, 0, 0, 0, 0),
      durationMillis: 30000,
      swipeCount: 15,
    );

    await localRepo.insertSessions([session]);

    final summary = await dataService.getDoomscrollSummary(
      period: MonitoringPeriod.daily,
      date: today,
      userId: 'test_user',
    );

    expect(summary.totalSessions, equals(1));
    expect(summary.totalSwipes, equals(15));
    expect(summary.hasData, isTrue);
  });

  // 3. session 23:59 -> masuk hari tersebut
  test('3. session 23:59:59 -> masuk hari tersebut', () async {
    final today = DateTime(2026, 10, 1);
    final session = createSession(
      id: 'session_late_night',
      startedAt: DateTime(2026, 10, 1, 23, 59, 30),
      durationMillis: 20000,
      swipeCount: 12,
    );

    await localRepo.insertSessions([session]);

    final summary = await dataService.getDoomscrollSummary(
      period: MonitoringPeriod.daily,
      date: today,
      userId: 'test_user',
    );

    expect(summary.totalSessions, equals(1));
    expect(summary.totalSwipes, equals(12));
    expect(summary.hasData, isTrue);
  });

  // 4. session kemarin -> tidak masuk hari ini
  test('4. session kemarin -> tidak masuk hari ini', () async {
    final today = DateTime(2026, 10, 1);
    final yesterdaySession = createSession(
      id: 'session_yesterday',
      startedAt: DateTime(2026, 9, 30, 23, 50, 0),
      endedAt: DateTime(2026, 9, 30, 23, 55, 0),
      durationMillis: 300000,
      swipeCount: 40,
    );

    await localRepo.insertSessions([yesterdaySession]);

    // Query hari ini
    final summaryToday = await dataService.getDoomscrollSummary(
      period: MonitoringPeriod.daily,
      date: today,
      userId: 'test_user',
    );
    expect(summaryToday.totalSessions, equals(0));
    expect(summaryToday.totalSwipes, equals(0));
    expect(summaryToday.hasData, isFalse);

    // Query kemarin
    final summaryYesterday = await dataService.getDoomscrollSummary(
      period: MonitoringPeriod.daily,
      date: DateTime(2026, 9, 30),
      userId: 'test_user',
    );
    expect(summaryYesterday.totalSessions, equals(1));
    expect(summaryYesterday.totalSwipes, equals(40));
    expect(summaryYesterday.hasData, isTrue);
  });

  // 5. weekly aggregation
  test('5. weekly aggregation -> agregasi sesi dalam satu minggu', () async {
    // 2026-09-28 adalah Senin, 2026-10-04 adalah Minggu
    final mondaySession = createSession(
      id: 's_monday',
      startedAt: DateTime(2026, 9, 28, 10, 0),
      swipeCount: 20,
    );
    final wednesdaySession = createSession(
      id: 's_wednesday',
      startedAt: DateTime(2026, 9, 30, 14, 0),
      swipeCount: 30,
    );
    final sundaySession = createSession(
      id: 's_sunday',
      startedAt: DateTime(2026, 10, 4, 20, 0),
      swipeCount: 25,
    );

    await localRepo.insertSessions([mondaySession, wednesdaySession, sundaySession]);

    final weeklySummary = await dataService.getDoomscrollSummary(
      period: MonitoringPeriod.weekly,
      date: DateTime(2026, 10, 1),
      userId: 'test_user',
    );

    expect(weeklySummary.totalSessions, equals(3));
    expect(weeklySummary.totalSwipes, equals(75));
    expect(weeklySummary.hasData, isTrue);

    final days = await dataService.getWeeklyDays(
      dateInWeek: DateTime(2026, 10, 1),
      userId: 'test_user',
    );
    expect(days.length, equals(7));
    // Senin
    expect(days[0].doomscrollSwipes, equals(20));
    // Rabu
    expect(days[2].doomscrollSwipes, equals(30));
    // Minggu
    expect(days[6].doomscrollSwipes, equals(25));
  });

  // 6. monthly aggregation
  test('6. monthly aggregation -> agregasi sesi bulanan terbagi per minggu', () async {
    final sWeek1 = createSession(
      id: 's_w1',
      startedAt: DateTime(2026, 10, 3, 10, 0),
      swipeCount: 15,
    );
    final sWeek2 = createSession(
      id: 's_w2',
      startedAt: DateTime(2026, 10, 10, 11, 0),
      swipeCount: 25,
    );
    final sWeek4 = createSession(
      id: 's_w4',
      startedAt: DateTime(2026, 10, 25, 12, 0),
      swipeCount: 35,
    );

    await localRepo.insertSessions([sWeek1, sWeek2, sWeek4]);

    final monthlySummary = await dataService.getDoomscrollSummary(
      period: MonitoringPeriod.monthly,
      date: DateTime(2026, 10, 15),
      userId: 'test_user',
    );

    expect(monthlySummary.totalSessions, equals(3));
    expect(monthlySummary.totalSwipes, equals(75));
    expect(monthlySummary.hasData, isTrue);

    final weeks = await dataService.getMonthlyWeeks(
      year: 2026,
      month: 10,
      userId: 'test_user',
    );
    expect(weeks.length, equals(5)); // Oktober 31 hari -> 5 minggu
    expect(weeks[0].doomscrollSwipes, equals(15)); // Week 1 (1-7)
    expect(weeks[1].doomscrollSwipes, equals(25)); // Week 2 (8-14)
    expect(weeks[3].doomscrollSwipes, equals(35)); // Week 4 (22-28)
  });

  // 7. user isolation
  test('7. user isolation -> data user A tidak tercampur dengan user B', () async {
    final today = DateTime(2026, 10, 1);
    final sessionUserA = createSession(
      id: 's_user_a',
      userId: 'user_A_uuid',
      startedAt: DateTime(2026, 10, 1, 9, 0),
      swipeCount: 50,
    );
    final sessionUserB = createSession(
      id: 's_user_b',
      userId: 'user_B_uuid',
      startedAt: DateTime(2026, 10, 1, 10, 0),
      swipeCount: 100,
    );

    await localRepo.insertSessions([sessionUserA, sessionUserB]);

    // Query untuk user A
    final summaryA = await dataService.getDoomscrollSummary(
      period: MonitoringPeriod.daily,
      date: today,
      userId: 'user_A_uuid',
    );
    expect(summaryA.totalSessions, equals(1));
    expect(summaryA.totalSwipes, equals(50));

    // Query untuk user B
    final summaryB = await dataService.getDoomscrollSummary(
      period: MonitoringPeriod.daily,
      date: today,
      userId: 'user_B_uuid',
    );
    expect(summaryB.totalSessions, equals(1));
    expect(summaryB.totalSwipes, equals(100));
  });

  // 8. completed session
  test('8. completed session -> startedAt <= now dan endedAt != null terhitung akurat', () async {
    final today = DateTime(2026, 10, 1);
    final session = createSession(
      id: 's_completed',
      startedAt: DateTime(2026, 10, 1, 11, 0, 0),
      endedAt: DateTime(2026, 10, 1, 11, 5, 0),
      durationMillis: 300000,
      swipeCount: 60,
      downwardSwipeCount: 50,
      upwardSwipeCount: 10,
    );

    await localRepo.insertSessions([session]);

    final summary = await dataService.getDoomscrollSummary(
      period: MonitoringPeriod.daily,
      date: today,
      userId: 'test_user',
    );

    expect(summary.totalSessions, equals(1));
    expect(summary.totalDurationMillis, equals(300000));
    expect(summary.totalSwipes, equals(60));
    expect(summary.downwardSwipes, equals(50));
    expect(summary.upwardSwipes, equals(10));
    expect(summary.hasData, isTrue);
  });

  // 9. active session
  test('9. active session -> endedAt == null tetap terhitung dalam agregasi live', () async {
    final today = DateTime(2026, 10, 1);
    final activeSession = createSession(
      id: 's_active',
      startedAt: DateTime(2026, 10, 1, 14, 0, 0),
      endedAt: null,
      durationMillis: 120000, // 2 menit berjalan
      swipeCount: 35,
    );

    await localRepo.insertSessions([activeSession]);

    final summary = await dataService.getDoomscrollSummary(
      period: MonitoringPeriod.daily,
      date: today,
      userId: 'test_user',
    );

    expect(summary.totalSessions, equals(1));
    expect(summary.totalSwipes, equals(35));
    expect(summary.totalDurationMillis, greaterThan(0));
    expect(summary.hasData, isTrue);
  });

  // 10. timezone/local date boundary (crossing midnight)
  test('10. timezone/local date boundary -> session crossing midnight terbagi proporsional', () async {
    // Sesi 30 menit: 23:50 sampai 00:20 (10 menit di hari 1, 20 menit di hari 2)
    final crossSession = createSession(
      id: 's_cross',
      startedAt: DateTime(2026, 10, 1, 23, 50, 0),
      endedAt: DateTime(2026, 10, 2, 0, 20, 0),
      durationMillis: 1800000, // 30 menit
      swipeCount: 90,
      downwardSwipeCount: 60,
      upwardSwipeCount: 30,
    );

    await localRepo.insertSessions([crossSession]);

    // Hari 1: 10 menit overlap (1/3 durasi & swipes)
    final summaryDay1 = await dataService.getDoomscrollSummary(
      period: MonitoringPeriod.daily,
      date: DateTime(2026, 10, 1),
      userId: 'test_user',
    );
    expect(summaryDay1.totalSessions, equals(1));
    expect(summaryDay1.totalDurationMillis, equals(600000)); // 10 menit
    expect(summaryDay1.totalSwipes, equals(30)); // 1/3 dari 90

    // Hari 2: 20 menit overlap (2/3 durasi & swipes)
    // Query getSessionsBetween dengan half-open interval mencakup sesi yang dimulai sebelum midnight jika overlap
    final sessionsDay2 = await localRepo.getSessionsBetween(
      start: DateTime(2026, 10, 1, 23, 50, 0),
      end: DateTime(2026, 10, 3, 0, 0, 0),
      userId: 'test_user',
    );
    expect(sessionsDay2.length, equals(1));
  });

  // 11. empty period tetap menampilkan empty state
  test('11. empty period tetap menghasilkan hasData == false', () async {
    final emptyDate = DateTime(2026, 11, 15);
    final summary = await dataService.getDoomscrollSummary(
      period: MonitoringPeriod.daily,
      date: emptyDate,
      userId: 'test_user',
    );

    expect(summary.totalSessions, equals(0));
    expect(summary.totalDurationMillis, equals(0));
    expect(summary.totalSwipes, equals(0));
    expect(summary.hasData, isFalse);
  });

  // 12. Home summary membaca data yang sama
  test('12. Home summary membaca data yang sama dari MonitoringDataService', () async {
    final today = DateTime.now();
    final todaySession = createSession(
      id: 'home_test_session',
      userId: 'local_user',
      startedAt: DateTime(today.year, today.month, today.day, 10, 0, 0),
      durationMillis: 150000, // 2m 30s
      swipeCount: 45,
      downwardSwipeCount: 35,
      upwardSwipeCount: 10,
    );

    await localRepo.insertSessions([todaySession]);

    final homeController = HomeController(
      doomscrollRepository: doomRepo,
      monitoringDataService: dataService,
    );

    await homeController.loadDoomscrollSummary();

    expect(homeController.hasDoomscrollData, isTrue);
    expect(homeController.doomscrollSessionCount, equals(1));
    expect(homeController.doomscrollSwipes, equals(45));
    expect(homeController.doomscrollDurationFormatted, equals('2m'));
  });
}
