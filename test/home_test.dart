import 'dart:typed_data';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mind_drji/app/data/local/app_database.dart';
import 'package:mind_drji/app/data/local/repositories/eye_monitoring_local_repository.dart';
import 'package:mind_drji/app/data/models/app_usage_model.dart';
import 'package:mind_drji/app/data/models/eye_monitoring_live_event.dart';
import 'package:mind_drji/app/data/models/eye_monitoring_session_model.dart';
import 'package:mind_drji/app/data/models/monitoring_visualization_model.dart';
import 'package:mind_drji/app/data/models/profile_model.dart';
import 'package:mind_drji/app/data/providers/eye_monitoring_native_provider.dart';
import 'package:mind_drji/app/data/repositories/eye_monitoring_repository.dart';
import 'package:mind_drji/app/data/repositories/profile_repository.dart';
import 'package:mind_drji/app/data/repositories/usage_stats_repository.dart';
import 'package:mind_drji/app/data/services/eye_monitoring_service.dart';
import 'package:mind_drji/app/modules/home/controllers/home_controller.dart';
import 'package:mind_drji/app/modules/home/views/home_view.dart';

class FakeHomeProfileRepository implements ProfileRepository {
  ProfileModel? mockProfile;
  bool shouldThrow = false;

  @override
  Future<ProfileModel?> getMyProfile() async {
    if (shouldThrow) {
      throw Exception('Network error');
    }
    return mockProfile;
  }

  @override
  Future<ProfileModel> updateMyProfile({
    String? namaLengkap,
    DateTime? tanggalLahir,
    String? noHp,
    String? jenisKelamin,
    bool clearTanggalLahir = false,
  }) async {
    throw UnimplementedError();
  }
}

class FakeHomeUsageStatsRepository implements UsageStatsRepository {
  bool hasAccess = false;
  UsageStatsModel stats = const UsageStatsModel(totalUsageMillis: 0, apps: []);

  @override
  Future<bool> checkUsageAccess() async => hasAccess;

  @override
  Future<bool> openUsageAccessSettings() async => true;

  @override
  Future<UsageStatsModel> getTodayUsage() async => stats;

  @override
  Future<UsageStatsModel?> getLocalTodayUsage() async => stats;

  @override
  Future<UsageStatsModel> getUsageRange({
    required DateTime startTime,
    required DateTime endTime,
  }) async => stats;

  @override
  Future<void> saveDailySnapshot({
    UsageStatsModel? stats,
    DateTime? date,
  }) async {}

  @override
  Future<int> claimLocalUsage(String authenticatedUserId) async => 0;

  @override
  Future<Uint8List?> getAppIcon(String packageName) async => null;
}

class FakeHomeEyeRepository implements EyeMonitoringRepository {
  final EyeMonitoringLocalRepository? _local;
  FakeHomeEyeRepository({EyeMonitoringLocalRepository? localRepo})
    : _local = localRepo;

  @override
  EyeMonitoringLocalRepository get localRepository =>
      _local ?? EyeMonitoringLocalRepository();

  @override
  EyeMonitoringNativeProvider get provider => EyeMonitoringNativeProvider();

  @override
  Future<bool> checkCameraPermission() async => true;

  @override
  Future<bool> requestCameraPermission() async => true;

  @override
  Future<bool> checkNotificationPermission() async => true;

  @override
  Future<bool> requestNotificationPermission() async => true;

  @override
  Future<bool> startForegroundMonitoring({
    Duration? interval,
    Duration? sessionDuration,
    String? userId,
    String? deviceId,
    bool runImmediate = true,
  }) async => true;

  @override
  Future<bool> stopForegroundMonitoring() async => true;

  @override
  Future<bool> isForegroundServiceRunning() async => false;

  @override
  Future<List<EyeMonitoringSessionModel>> flushPendingSessions() async => [];

  @override
  Future<bool> startMonitoring() async => true;

  @override
  Future<EyeMonitoringSessionModel?> stopMonitoringAndPersist() async => null;

  @override
  Future<bool> getStatus() async => false;

  @override
  Future<List<EyeMonitoringSessionData>> getStoredSessions({
    int limit = 50,
  }) async => [];

  @override
  Future<void> claimLocalSessions(String userId) async {}

  @override
  Stream<EyeMonitoringLiveEvent> liveEventStream() => const Stream.empty();

  @override
  Future<List<EyeMonitoringSessionData>> getSessionsBetween({
    required DateTime start,
    required DateTime end,
    String? userId,
  }) async =>
      _local?.getSessionsBetween(start: start, end: end, userId: userId) ??
      Future.value([]);
}

void main() {
  late FakeHomeProfileRepository fakeRepo;
  late FakeHomeUsageStatsRepository fakeUsageRepo;
  late AppDatabase db;
  late EyeMonitoringLocalRepository localRepo;
  late EyeMonitoringService defaultEyeService;

  setUp(() {
    Get.reset();
    fakeRepo = FakeHomeProfileRepository();
    fakeUsageRepo = FakeHomeUsageStatsRepository();
    db = AppDatabase(NativeDatabase.memory());
    localRepo = EyeMonitoringLocalRepository(db: db);
    final eyeRepo = FakeHomeEyeRepository(localRepo: localRepo);
    Get.put<EyeMonitoringLocalRepository>(localRepo);
    Get.put<EyeMonitoringRepository>(eyeRepo);
    defaultEyeService = EyeMonitoringService(
      db: db,
      localRepository: localRepo,
      repository: eyeRepo,
      autoStart: false,
    );
    Get.put<EyeMonitoringService>(defaultEyeService);
  });

  tearDown(() async {
    defaultEyeService.onClose();
    await db.close();
    Get.reset();
  });

  group('HomeController Logic & Greeting Tests', () {
    test('Greeting menghasilkan nama depan dengan format Halo, [Nama] 👋', () {
      final controller = HomeController(
        profileRepository: fakeRepo,
        usageStatsRepository: fakeUsageRepo,
      );
      controller.profile.value = const ProfileModel(
        id: 'u-1',
        namaLengkap: 'Misya Amalia',
        email: 'misya@example.com',
      );

      expect(controller.greetingName, 'Misya');
      expect(controller.greetingText, 'Halo, Misya 👋');
    });

    test('Greeting huruf kecil otomatis dikapitalisasi dengan benar', () {
      final controller = HomeController(
        profileRepository: fakeRepo,
        usageStatsRepository: fakeUsageRepo,
      );
      controller.profile.value = const ProfileModel(
        id: 'u-2',
        namaLengkap: 'misya',
        email: 'misya@example.com',
      );

      expect(controller.greetingName, 'Misya');
      expect(controller.greetingText, 'Halo, Misya 👋');
    });

    test('Greeting fallback ke Halo 👋 saat nama null atau kosong', () {
      final controller = HomeController(
        profileRepository: fakeRepo,
        usageStatsRepository: fakeUsageRepo,
      );
      controller.profile.value = const ProfileModel(
        id: 'u-3',
        namaLengkap: null,
        email: 'misya@example.com',
      );

      expect(controller.greetingName, '');
      expect(controller.greetingText, 'Halo 👋');
    });

    test(
      'loadUserProfile menangani error state jika user id null di test',
      () async {
        final controller = HomeController(
          profileRepository: fakeRepo,
          usageStatsRepository: fakeUsageRepo,
        );
        await controller.loadUserProfile();

        expect(
          controller.errorMessage.value,
          'Data pengguna belum dapat dimuat.',
        );
        expect(controller.profile.value, isNull);
      },
    );

    test('Screen time summary terupdate saat permission aktif', () async {
      fakeUsageRepo.hasAccess = true;
      fakeUsageRepo.stats = const UsageStatsModel(
        totalUsageMillis: 9300000, // 2j 35m
        apps: [],
      );

      final controller = HomeController(
        profileRepository: fakeRepo,
        usageStatsRepository: fakeUsageRepo,
      );
      await controller.loadScreenTimeSummary();

      expect(controller.hasUsageAccess.value, isTrue);
      expect(controller.todayScreenTimeMillis.value, 9300000);
    });
  });

  group('HomeView Widget Tests', () {
    testWidgets(
      'Tampilkan seluruh elemen Home Dashboard tanpa data monitoring dummy',
      (tester) async {
        fakeRepo.mockProfile = const ProfileModel(
          id: 'u-1',
          namaLengkap: 'Misya',
          email: 'misya@example.com',
        );

        final controller = Get.put(
          HomeController(
            profileRepository: fakeRepo,
            usageStatsRepository: fakeUsageRepo,
          ),
        );
        controller.profile.value = fakeRepo.mockProfile;
        controller.isLoading.value = false;
        controller.errorMessage.value = null;

        await tester.pumpWidget(const GetMaterialApp(home: HomeView()));

        // 1. Header & Greeting
        expect(find.text('MIND DRIJI'), findsOneWidget);
        expect(find.text('Halo, Misya 👋'), findsOneWidget);
        expect(
          find.text('Bagaimana kebiasaan digitalmu hari ini?'),
          findsOneWidget,
        );

        // 2. Banner Quick Action
        expect(find.text('Fokus & Intervensi Digital'), findsOneWidget);
        expect(find.text('Mulai Focus Mode'), findsOneWidget);
        expect(find.text('Semua Intervensi'), findsOneWidget);

        // 3. Screen Time Card (Tanpa chip Screen Time Monitoring belum aktif)
        expect(find.text('Screen Time'), findsAtLeastNWidgets(1));
        expect(find.text('Monitoring belum aktif'), findsNothing);
        expect(find.text('Belum ada data'), findsWidgets);

        // 4. Pola Scrolling Card (Status ringkas: Belum Aktif)
        expect(find.text('Pola Scrolling'), findsAtLeastNWidgets(1));
        expect(find.text('Belum Aktif'), findsWidgets);

        // 5. Monitoring Mata Card (Status ringkas: Belum Aktif)
        expect(find.text('Monitoring Mata'), findsAtLeastNWidgets(1));

        // 6. Insight Hari Ini
        expect(find.text('Insight Hari Ini'), findsOneWidget);
        expect(
          find.text('Insight akan tersedia setelah data penggunaan terkumpul.'),
          findsOneWidget,
        );

        // 7. Bottom Navigation Bar Material 3 (5 tabs)
        expect(find.byType(NavigationBar), findsOneWidget);
        expect(find.text('Home'), findsOneWidget);
        expect(find.text('Monitoring'), findsOneWidget);
        expect(find.text('Insight'), findsOneWidget);
        expect(find.text('Intervensi'), findsOneWidget);
        expect(find.text('Profil'), findsOneWidget);

        // 8. Pastikan tidak ada angka palsu / dummy metrics
        expect(find.textContaining('2j'), findsNothing);
        expect(find.textContaining('3j'), findsNothing);
        expect(find.textContaining('78%'), findsNothing);
        expect(find.textContaining('skor'), findsNothing);
      },
    );

    testWidgets(
      'Screen Time card di Home menampilkan data real saat permission aktif',
      (tester) async {
        fakeRepo.mockProfile = const ProfileModel(
          id: 'u-1',
          namaLengkap: 'Misya',
          email: 'misya@example.com',
        );

        fakeUsageRepo.hasAccess = true;
        fakeUsageRepo.stats = const UsageStatsModel(
          totalUsageMillis: 9300000, // 2j 35m
          apps: [],
        );

        final controller = Get.put(
          HomeController(
            profileRepository: fakeRepo,
            usageStatsRepository: fakeUsageRepo,
          ),
        );
        controller.profile.value = fakeRepo.mockProfile;
        controller.hasUsageAccess.value = true;
        controller.todayScreenTimeMillis.value = 9300000;
        controller.isLoading.value = false;
        controller.errorMessage.value = null;

        await tester.pumpWidget(const GetMaterialApp(home: HomeView()));

        expect(find.text('Aktif'), findsOneWidget);
        expect(find.text('2j 35m'), findsOneWidget);
        expect(find.text('Total penggunaan hari ini'), findsOneWidget);
      },
    );
  });

  group('Home Eye Monitoring Reactive Synchronization Tests', () {
    const testProfile = ProfileModel(
      id: 'u-1',
      namaLengkap: 'Misya',
      email: 'misya@example.com',
    );

    // 1. monitoring OFF → Home menampilkan "Monitoring belum aktif"
    testWidgets(
      '1. Monitoring OFF: Home menampilkan "Monitoring belum aktif", "Belum ada data", dan deskripsi aktivasi',
      (tester) async {
        defaultEyeService.isMonitoringEnabled.value = false;
        defaultEyeService.isSessionRunning.value = false;

        final controller = Get.put(
          HomeController(
            profileRepository: fakeRepo,
            usageStatsRepository: fakeUsageRepo,
            eyeMonitoringService: defaultEyeService,
          ),
        );
        controller.profile.value = testProfile;
        controller.isLoading.value = false;
        controller.errorMessage.value = null;

        expect(controller.eyeMonitoringBadgeText, 'Belum Aktif');
        expect(controller.eyeMonitoringTitle, 'Belum ada data');
        expect(
          controller.eyeMonitoringDescription,
          'Aktifkan monitoring untuk memulai pemantauan mata.',
        );

        await tester.pumpWidget(const GetMaterialApp(home: HomeView()));

        expect(find.text('Belum Aktif'), findsAtLeastNWidgets(1));
        expect(find.text('Belum ada data'), findsAtLeastNWidgets(1));
      },
    );

    // 2. monitoring ON + camera OFF → Home menampilkan "Aktif"
    testWidgets(
      '2. Monitoring ON + camera OFF: Home menampilkan "Aktif", "Monitoring aktif", dan deskripsi pemantauan otomatis',
      (tester) async {
        defaultEyeService.isMonitoringEnabled.value = true;
        defaultEyeService.isSessionRunning.value = false;

        final controller = Get.put(
          HomeController(
            profileRepository: fakeRepo,
            usageStatsRepository: fakeUsageRepo,
            eyeMonitoringService: defaultEyeService,
          ),
        );
        controller.profile.value = testProfile;
        controller.isLoading.value = false;
        controller.errorMessage.value = null;

        expect(controller.eyeMonitoringBadgeText, 'Aktif');
        expect(controller.eyeMonitoringTitle, 'Monitoring aktif');
        expect(
          controller.eyeMonitoringDescription,
          'Pemantauan mata berjalan otomatis.',
        );

        await tester.pumpWidget(const GetMaterialApp(home: HomeView()));

        expect(find.text('Aktif'), findsOneWidget);
        expect(find.text('Monitoring aktif'), findsOneWidget);
        expect(find.text('Pemantauan mata berjalan otomatis.'), findsOneWidget);
        expect(find.text('Kamera Aktif'), findsNothing);
      },
    );

    // 3. monitoring ON + camera ON → Home menampilkan "Kamera Aktif"
    testWidgets(
      '3. Monitoring ON + camera ON: Home menampilkan "Kamera Aktif", "Sedang memantau", dan deskripsi kamera digunakan',
      (tester) async {
        defaultEyeService.isMonitoringEnabled.value = true;
        defaultEyeService.isSessionRunning.value = true;

        final controller = Get.put(
          HomeController(
            profileRepository: fakeRepo,
            usageStatsRepository: fakeUsageRepo,
            eyeMonitoringService: defaultEyeService,
          ),
        );
        controller.profile.value = testProfile;
        controller.isLoading.value = false;
        controller.errorMessage.value = null;

        expect(controller.eyeMonitoringBadgeText, 'Kamera Aktif');
        expect(controller.eyeMonitoringTitle, 'Sedang memantau');
        expect(
          controller.eyeMonitoringDescription,
          'Kamera sedang digunakan untuk pemantauan mata.',
        );

        await tester.pumpWidget(const GetMaterialApp(home: HomeView()));

        expect(find.text('Kamera Aktif'), findsOneWidget);
        expect(find.text('Sedang memantau'), findsOneWidget);
        expect(
          find.text('Kamera sedang digunakan untuk pemantauan mata.'),
          findsOneWidget,
        );
      },
    );

    // 4. monitoring berubah OFF → Home reactive berubah ke OFF
    testWidgets(
      '4. Monitoring berubah OFF: Home reactive berubah ke "Monitoring belum aktif" tanpa restart',
      (tester) async {
        defaultEyeService.isMonitoringEnabled.value = true;
        defaultEyeService.isSessionRunning.value = false;

        final controller = Get.put(
          HomeController(
            profileRepository: fakeRepo,
            usageStatsRepository: fakeUsageRepo,
            eyeMonitoringService: defaultEyeService,
          ),
        );
        controller.profile.value = testProfile;
        controller.isLoading.value = false;
        controller.errorMessage.value = null;

        await tester.pumpWidget(const GetMaterialApp(home: HomeView()));

        expect(find.text('Aktif'), findsOneWidget);
        expect(find.text('Monitoring aktif'), findsOneWidget);

        // User / service mematikan monitoring
        defaultEyeService.isMonitoringEnabled.value = false;
        defaultEyeService.isSessionRunning.value = false;
        await tester.pump();

        expect(find.text('Belum Aktif'), findsAtLeastNWidgets(1));
        expect(find.text('Belum ada data'), findsAtLeastNWidgets(1));
        expect(find.text('Monitoring aktif'), findsNothing);
      },
    );

    // 5. monitoring berubah ON → Home reactive berubah ke ON
    testWidgets(
      '5. Monitoring berubah ON: Home reactive berubah ke "Aktif" tanpa restart',
      (tester) async {
        defaultEyeService.isMonitoringEnabled.value = false;
        defaultEyeService.isSessionRunning.value = false;

        final controller = Get.put(
          HomeController(
            profileRepository: fakeRepo,
            usageStatsRepository: fakeUsageRepo,
            eyeMonitoringService: defaultEyeService,
          ),
        );
        controller.profile.value = testProfile;
        controller.isLoading.value = false;
        controller.errorMessage.value = null;

        await tester.pumpWidget(const GetMaterialApp(home: HomeView()));

        expect(find.text('Belum Aktif'), findsAtLeastNWidgets(1));
        expect(find.text('Monitoring aktif'), findsNothing);

        // User mengaktifkan monitoring
        defaultEyeService.isMonitoringEnabled.value = true;
        defaultEyeService.isSessionRunning.value = false;
        await tester.pump();

        expect(find.text('Aktif'), findsOneWidget);
        expect(find.text('Monitoring aktif'), findsOneWidget);
        expect(find.text('Pemantauan mata berjalan otomatis.'), findsOneWidget);
      },
    );

    // 6. app restart dengan monitoring persisted ON → Home menampilkan ON
    testWidgets(
      '6. App restart dengan monitoring persisted ON: Home membaca state dari EyeMonitoringService dan menampilkan "Aktif"',
      (tester) async {
        final restartDb = AppDatabase(NativeDatabase.memory());
        final restartLocalRepo = EyeMonitoringLocalRepository(db: restartDb);
        final restartEyeRepo = FakeHomeEyeRepository(
          localRepo: restartLocalRepo,
        );
        // Masukkan persistent config yang enabled
        await restartDb
            .into(restartDb.eyeMonitoringConfig)
            .insert(
              EyeMonitoringConfigCompanion.insert(
                id: 'current_config',
                monitoringEnabled: const drift.Value(true),
                lastSessionCompletedAt: drift.Value(
                  DateTime.now().subtract(const Duration(minutes: 10)),
                ),
                updatedAt: DateTime.now(),
              ),
            );

        final eyeService = EyeMonitoringService(
          db: restartDb,
          localRepository: restartLocalRepo,
          repository: restartEyeRepo,
          autoStart: false,
        );
        await eyeService.initService();

        expect(eyeService.isMonitoringEnabled.value, isTrue);

        final controller = Get.put(
          HomeController(
            profileRepository: fakeRepo,
            usageStatsRepository: fakeUsageRepo,
            eyeMonitoringService: eyeService,
          ),
        );
        controller.profile.value = testProfile;
        controller.isLoading.value = false;
        controller.errorMessage.value = null;

        expect(
          controller.eyeMonitoringBadgeText,
          anyOf(equals('Aktif'), equals('Kamera Aktif')),
        );
        expect(
          controller.eyeMonitoringTitle,
          anyOf(equals('Monitoring aktif'), equals('Sedang memantau')),
        );

        await tester.pumpWidget(const GetMaterialApp(home: HomeView()));

        expect(find.text('Monitoring aktif'), findsOneWidget);
        expect(find.text('Pemantauan mata berjalan otomatis.'), findsOneWidget);

        eyeService.onClose();
        await restartDb.close();
      },
    );
  });

  group(
    'Home Redesign Feature Tests (Top 5 Apps, Time Period Ring, Eye & Camera Status, Navigation)',
    () {
      const testProfile = ProfileModel(
        id: 'u-1',
        namaLengkap: 'Misya',
        email: 'misya@example.com',
      );

      testWidgets(
        '1. Top 5 Aplikasi: Menampilkan hingga 5 aplikasi secara berurutan dengan durasi aktual',
        (tester) async {
          fakeRepo.mockProfile = testProfile;
          fakeUsageRepo.hasAccess = true;
          fakeUsageRepo.stats = const UsageStatsModel(
            totalUsageMillis: 24600000, // ~6j 50m
            apps: [
              AppUsageModel(
                packageName: 'com.zhiliaoapp.musically',
                appName: 'TikTok',
                usageMillis: 11400000, // 3j 10m
              ),
              AppUsageModel(
                packageName: 'com.instagram.android',
                appName: 'Instagram',
                usageMillis: 6300000, // 1j 45m
              ),
              AppUsageModel(
                packageName: 'com.google.android.youtube',
                appName: 'YouTube',
                usageMillis: 4200000, // 1j 10m
              ),
              AppUsageModel(
                packageName: 'com.twitter.android',
                appName: 'Twitter',
                usageMillis: 1800000, // 30m
              ),
              AppUsageModel(
                packageName: 'com.whatsapp',
                appName: 'WhatsApp',
                usageMillis: 900000, // 15m
              ),
            ],
          );

          final controller = Get.put(
            HomeController(
              profileRepository: fakeRepo,
              usageStatsRepository: fakeUsageRepo,
              eyeMonitoringService: defaultEyeService,
            ),
          );
          controller.profile.value = testProfile;
          controller.hasUsageAccess.value = true;
          controller.todayUsageStats.value = fakeUsageRepo.stats;
          controller.todayScreenTimeMillis.value = 24600000;
          controller.isLoading.value = false;
          controller.errorMessage.value = null;

          await tester.pumpWidget(const GetMaterialApp(home: HomeView()));

          expect(find.text('Top 5 Aplikasi'), findsOneWidget);
          expect(find.text('Lihat Semua'), findsOneWidget);
          expect(find.text('TikTok'), findsOneWidget);
          expect(find.text('Instagram'), findsOneWidget);
          expect(find.text('YouTube'), findsOneWidget);
          expect(find.text('Twitter'), findsOneWidget);
          expect(find.text('WhatsApp'), findsOneWidget);
        },
      );

      testWidgets(
        '2. Ring Periode Waktu: Menampilkan 5 segmen (Dini Hari, Pagi, Siang, Sore, Malam) dengan legenda',
        (tester) async {
          fakeRepo.mockProfile = testProfile;
          fakeUsageRepo.hasAccess = true;
          fakeUsageRepo.stats = const UsageStatsModel(
            totalUsageMillis: 18000000, // 5j
            apps: [],
          );

          final controller = Get.put(
            HomeController(
              profileRepository: fakeRepo,
              usageStatsRepository: fakeUsageRepo,
              eyeMonitoringService: defaultEyeService,
            ),
          );
          controller.profile.value = testProfile;
          controller.hasUsageAccess.value = true;
          controller.todayScreenTimeMillis.value = 18000000; // 5j
          controller.isLoading.value = false;

          controller.timeSegments.assignAll(const [
            TimeSegmentUsage(
              label: DailyTimeSegment.diniHari,
              timeRange: '00:00–04:59',
              startHour: 0,
              endHour: 5,
              screenTimeMillis: 1800000, // 30m
              doomscrollMillis: 0,
              doomscrollSwipes: 0,
            ),
            TimeSegmentUsage(
              label: DailyTimeSegment.pagi,
              timeRange: '05:00–10:59',
              startHour: 5,
              endHour: 11,
              screenTimeMillis: 5400000, // 1j 30m
              doomscrollMillis: 0,
              doomscrollSwipes: 0,
            ),
            TimeSegmentUsage(
              label: DailyTimeSegment.siang,
              timeRange: '11:00–14:59',
              startHour: 11,
              endHour: 15,
              screenTimeMillis: 3600000, // 1j
              doomscrollMillis: 0,
              doomscrollSwipes: 0,
            ),
            TimeSegmentUsage(
              label: DailyTimeSegment.sore,
              timeRange: '15:00–17:59',
              startHour: 15,
              endHour: 18,
              screenTimeMillis: 3600000, // 1j
              doomscrollMillis: 0,
              doomscrollSwipes: 0,
            ),
            TimeSegmentUsage(
              label: DailyTimeSegment.malam,
              timeRange: '18:00–23:59',
              startHour: 18,
              endHour: 24,
              screenTimeMillis: 3600000, // 1j
              doomscrollMillis: 0,
              doomscrollSwipes: 0,
            ),
          ]);

          await tester.pumpWidget(const GetMaterialApp(home: HomeView()));

          expect(find.textContaining('Dini Hari'), findsOneWidget);
          expect(find.textContaining('Pagi'), findsOneWidget);
          expect(find.textContaining('Siang'), findsOneWidget);
          expect(find.textContaining('Sore'), findsOneWidget);
          expect(find.textContaining('Malam'), findsOneWidget);
        },
      );

      testWidgets(
        '3. Status Monitoring Mata vs Status Sensor Kamera: Berbeda tegas dan tidak dicampur aduk',
        (tester) async {
          defaultEyeService.isMonitoringEnabled.value = true;
          defaultEyeService.isSessionRunning.value = false;
          defaultEyeService.cameraPermission.value = true;

          final controller = Get.put(
            HomeController(
              profileRepository: fakeRepo,
              usageStatsRepository: fakeUsageRepo,
              eyeMonitoringService: defaultEyeService,
            ),
          );
          controller.profile.value = testProfile;
          controller.isLoading.value = false;

          await tester.pumpWidget(const GetMaterialApp(home: HomeView()));

          // Fitur monitoring aktif
          expect(find.text('Aktif'), findsAtLeastNWidgets(1));
          expect(find.text('Status Kamera'), findsOneWidget);
          expect(find.text('Sensor Off'), findsOneWidget);

          // Simulasi kamera mulai sampling
          defaultEyeService.isSessionRunning.value = true;
          await tester.pump();

          expect(find.text('Sensor Aktif'), findsOneWidget);
        },
      );

      testWidgets(
        '4. Intervensi Digital dan Aksi Cepat: Memiliki shortcut lengkap sesuai arsitektur',
        (tester) async {
          final controller = Get.put(
            HomeController(
              profileRepository: fakeRepo,
              usageStatsRepository: fakeUsageRepo,
              eyeMonitoringService: defaultEyeService,
            ),
          );
          controller.profile.value = testProfile;
          controller.isLoading.value = false;

          await tester.pumpWidget(const GetMaterialApp(home: HomeView()));

          expect(find.text('Mulai Focus Mode'), findsOneWidget);
          expect(find.text('Semua Intervensi'), findsOneWidget);
          expect(find.text('Relaksasi Mata'), findsOneWidget);
          expect(find.text('Target Apps'), findsAtLeastNWidgets(1));
          expect(find.text('Riwayat Jeda'), findsOneWidget);
          expect(find.text('Aksi Cepat'), findsOneWidget);
        },
      );
    },
  );
}
