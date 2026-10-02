import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;

import 'package:mind_drji/app/data/local/app_database.dart';
import 'package:mind_drji/app/data/local/repositories/intervention_history_local_repository.dart';
import 'package:mind_drji/app/data/models/intervention_model.dart';
import 'package:mind_drji/app/data/models/profile_model.dart';
import 'package:mind_drji/app/data/repositories/profile_repository.dart';
import 'package:mind_drji/app/modules/login/controllers/login_controller.dart';
import 'package:mind_drji/app/modules/profile/controllers/profile_controller.dart';
import 'package:mind_drji/app/modules/profile/views/profile_view.dart';
import 'package:mind_drji/app/modules/splash/controllers/splash_controller.dart';
import 'package:mind_drji/app/routes/app_routes.dart';

Session createFakeSession({
  required String userId,
  required String email,
  bool isExpired = false,
}) {
  final nowSecs = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  final expiresAt = isExpired ? nowSecs - 3600 : nowSecs + 3600;
  return Session.fromJson({
    'access_token': 'fake_access_token_$userId',
    'token_type': 'bearer',
    'expires_in': isExpired ? -3600 : 3600,
    'expires_at': expiresAt,
    'refresh_token': 'fake_refresh_token_$userId',
    'user': {
      'id': userId,
      'aud': 'authenticated',
      'email': email,
      'email_confirmed_at': DateTime.now().toIso8601String(),
      'app_metadata': <String, dynamic>{},
      'user_metadata': <String, dynamic>{},
      'created_at': DateTime.now().toIso8601String(),
    },
  })!;
}

class FakeGoTrueClient implements GoTrueClient {
  Session? _session;
  bool signOutCalled = false;

  FakeGoTrueClient({Session? initialSession}) : _session = initialSession;

  @override
  Session? get currentSession => _session;

  @override
  User? get currentUser => _session?.user;

  @override
  Future<void> signOut({SignOutScope scope = SignOutScope.global}) async {
    signOutCalled = true;
    _session = null;
  }

  @override
  Future<AuthResponse> signInWithPassword({
    String? email,
    String? phone,
    required String password,
    String? captchaToken,
  }) async {
    if (email == null || email.isEmpty || password != 'validPassword123') {
      throw const AuthException('Invalid login credentials');
    }
    final session = createFakeSession(
      userId: 'user_${email.split('@').first}',
      email: email,
    );
    _session = session;
    return AuthResponse(session: session, user: session.user);
  }

  @override
  Future<AuthResponse> refreshSession([String? refreshToken]) async {
    if (_session == null) {
      throw const AuthException('No session to refresh');
    }
    final refreshed = createFakeSession(
      userId: _session!.user.id,
      email: _session!.user.email ?? 'user@test.com',
      isExpired: false,
    );
    _session = refreshed;
    return AuthResponse(session: refreshed, user: refreshed.user);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeSupabaseClient implements SupabaseClient {
  final FakeGoTrueClient _auth;

  FakeSupabaseClient({FakeGoTrueClient? auth})
      : _auth = auth ?? FakeGoTrueClient();

  @override
  FakeGoTrueClient get auth => _auth;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeProfileRepository implements ProfileRepository {
  ProfileModel? mockProfile;

  FakeProfileRepository({this.mockProfile});

  @override
  Future<ProfileModel?> getMyProfile() async => mockProfile;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  drift.driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  setUp(() {
    Get.reset();
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  group('AUTHENTICATION & SESSION PERSISTENCE TESTS (1 - 10)', () {
    // -------------------------------------------------------------------------
    // 1. No session → Login
    // -------------------------------------------------------------------------
    testWidgets('1. No session -> Login: Splash mengarahkan ke Login jika tidak ada sesi', (tester) async {
      final fakeClient = FakeSupabaseClient();
      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: Routes.splash,
          getPages: [
            GetPage(name: Routes.splash, page: () => const Scaffold(body: Text('Splash'))),
            GetPage(name: Routes.login, page: () => const Scaffold(body: Text('Login'))),
            GetPage(name: Routes.home, page: () => const Scaffold(body: Text('Home'))),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final splashController = SplashController(
        supabaseClient: fakeClient,
        delay: Duration.zero,
      );

      await splashController.checkSessionAndNavigate();
      await tester.pumpAndSettle();

      expect(Get.currentRoute, Routes.login);
    });

    // -------------------------------------------------------------------------
    // 2. Existing session → Home
    // -------------------------------------------------------------------------
    testWidgets('2. Existing session -> Home: Splash mengarahkan ke Home jika session valid', (tester) async {
      final validSession = createFakeSession(
        userId: 'user_active_123',
        email: 'active@minddrji.com',
        isExpired: false,
      );
      final fakeClient = FakeSupabaseClient(
        auth: FakeGoTrueClient(initialSession: validSession),
      );
      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: Routes.splash,
          getPages: [
            GetPage(name: Routes.splash, page: () => const Scaffold(body: Text('Splash'))),
            GetPage(name: Routes.login, page: () => const Scaffold(body: Text('Login'))),
            GetPage(name: Routes.home, page: () => const Scaffold(body: Text('Home'))),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final splashController = SplashController(
        supabaseClient: fakeClient,
        delay: Duration.zero,
      );

      await splashController.checkSessionAndNavigate();
      await tester.pumpAndSettle();

      expect(Get.currentRoute, Routes.home);
    });

    // -------------------------------------------------------------------------
    // 3. Login session persistence
    // -------------------------------------------------------------------------
    testWidgets('3. Login session persistence: Sesi login tersimpan dan dikenali saat app start berikutnya', (tester) async {
      final fakeClient = FakeSupabaseClient();
      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: Routes.login,
          getPages: [
            GetPage(name: Routes.splash, page: () => const Scaffold(body: Text('Splash'))),
            GetPage(name: Routes.login, page: () => const Scaffold(body: Text('Login'))),
            GetPage(name: Routes.home, page: () => const Scaffold(body: Text('Home'))),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final loginController = LoginController(supabaseClient: fakeClient);

      // Simulasi user login
      loginController.emailController.text = 'persist@minddrji.com';
      loginController.passwordController.text = 'validPassword123';
      await loginController.login();
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      // Pastikan session tersimpan di client dan rute berpindah ke Home
      expect(fakeClient.auth.currentSession, isNotNull);
      expect(fakeClient.auth.currentUser?.email, 'persist@minddrji.com');
      expect(Get.currentRoute, Routes.home);

      // Simulasi buka kembali aplikasi (app cold-start / reopen via Splash)
      final splashController = SplashController(
        supabaseClient: fakeClient,
        delay: Duration.zero,
      );
      await splashController.checkSessionAndNavigate();
      await tester.pumpAndSettle();

      // Pengguna langsung diarahkan ke Home tanpa perlu login lagi
      expect(Get.currentRoute, Routes.home);
    });

    // -------------------------------------------------------------------------
    // 4. Logout confirmation
    // -------------------------------------------------------------------------
    testWidgets('4. Logout confirmation: Dialog konfirmasi muncul dan tombol Batal mempertahankan sesi', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final activeSession = createFakeSession(
        userId: 'user_logout_test',
        email: 'logout@minddrji.com',
      );
      final fakeClient = FakeSupabaseClient(
        auth: FakeGoTrueClient(initialSession: activeSession),
      );
      final fakeRepo = FakeProfileRepository(
        mockProfile: const ProfileModel(
          id: 'user_logout_test',
          namaLengkap: 'User Logout',
          email: 'logout@minddrji.com',
        ),
      );

      final profileController = ProfileController(
        supabaseClient: fakeClient,
        profileRepository: fakeRepo,
      );
      Get.put<ProfileController>(profileController);

      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: Routes.profile,
          getPages: [
            GetPage(name: Routes.profile, page: () => const ProfileView()),
            GetPage(name: Routes.login, page: () => const SizedBox()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Cari tombol 'Keluar dari Akun' dan pastikan terlihat
      final logoutBtn = find.text('Keluar dari Akun');
      await tester.ensureVisible(logoutBtn);
      expect(logoutBtn, findsOneWidget);

      await tester.tap(logoutBtn);
      await tester.pumpAndSettle();

      // Verifikasi Dialog Konfirmasi sesuai spesifikasi wording
      expect(find.text('Keluar dari akun?'), findsOneWidget);
      expect(find.text('Anda harus login kembali untuk mengakses akun ini.'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
      expect(find.text('Logout'), findsOneWidget);

      // Tekan tombol Batal
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      // Tetap di halaman Profile dan sesi tidak di-logout
      expect(find.text('Keluar dari akun?'), findsNothing);
      expect(fakeClient.auth.signOutCalled, isFalse);
      expect(fakeClient.auth.currentSession, isNotNull);
    });

    // -------------------------------------------------------------------------
    // 5. Logout success
    // -------------------------------------------------------------------------
    testWidgets('5. Logout success: Menekan tombol Logout menjalankan signOut dan berpindah ke Login', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final activeSession = createFakeSession(
        userId: 'user_logout_test',
        email: 'logout@minddrji.com',
      );
      final fakeAuth = FakeGoTrueClient(initialSession: activeSession);
      final fakeClient = FakeSupabaseClient(auth: fakeAuth);
      final fakeRepo = FakeProfileRepository(
        mockProfile: const ProfileModel(
          id: 'user_logout_test',
          namaLengkap: 'User Logout',
          email: 'logout@minddrji.com',
        ),
      );

      final profileController = ProfileController(
        supabaseClient: fakeClient,
        profileRepository: fakeRepo,
      );
      Get.put<ProfileController>(profileController);

      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: Routes.profile,
          getPages: [
            GetPage(name: Routes.profile, page: () => const ProfileView()),
            GetPage(name: Routes.login, page: () => const Scaffold(body: Text('Login Screen'))),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Tap Keluar dari Akun
      final logoutBtn = find.text('Keluar dari Akun');
      await tester.ensureVisible(logoutBtn);
      await tester.tap(logoutBtn);
      await tester.pumpAndSettle();

      // Tap Logout pada dialog konfirmasi
      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      // Verifikasi signOut terpanggil dan rute berpindah ke Login
      expect(fakeAuth.signOutCalled, isTrue);
      expect(Get.currentRoute, Routes.login);
    });

    // -------------------------------------------------------------------------
    // 6. Logout clears session
    // -------------------------------------------------------------------------
    test('6. Logout clears session: Session Supabase bernilai null setelah logout', () async {
      final activeSession = createFakeSession(
        userId: 'user_clear_session',
        email: 'clear@minddrji.com',
      );
      final fakeAuth = FakeGoTrueClient(initialSession: activeSession);
      final fakeClient = FakeSupabaseClient(auth: fakeAuth);

      final controller = ProfileController(supabaseClient: fakeClient);
      await controller.logout();

      expect(fakeClient.auth.currentSession, isNull);
      expect(fakeClient.auth.currentUser, isNull);
    });

    // -------------------------------------------------------------------------
    // 7. Reopen after logout → Login
    // -------------------------------------------------------------------------
    testWidgets('7. Reopen after logout -> Login: Buka kembali app setelah logout tetap di halaman Login', (tester) async {
      final activeSession = createFakeSession(
        userId: 'user_reopen_test',
        email: 'reopen@minddrji.com',
      );
      final fakeAuth = FakeGoTrueClient(initialSession: activeSession);
      final fakeClient = FakeSupabaseClient(auth: fakeAuth);

      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: Routes.profile,
          getPages: [
            GetPage(name: Routes.splash, page: () => const Scaffold(body: Text('Splash'))),
            GetPage(name: Routes.login, page: () => const Scaffold(body: Text('Login'))),
            GetPage(name: Routes.profile, page: () => const Scaffold(body: Text('Profile'))),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Lakukan logout
      final profileController = ProfileController(supabaseClient: fakeClient);
      await profileController.logout();
      await tester.pumpAndSettle();
      expect(fakeClient.auth.currentSession, isNull);
      expect(Get.currentRoute, Routes.login);

      // Buka kembali aplikasi (reopen via Splash)
      final splashController = SplashController(
        supabaseClient: fakeClient,
        delay: Duration.zero,
      );
      await splashController.checkSessionAndNavigate();
      await tester.pumpAndSettle();

      // Rute harus ke Login karena session sudah null
      expect(Get.currentRoute, Routes.login);
    });

    // -------------------------------------------------------------------------
    // 8. Back navigation after logout tidak kembali Home
    // -------------------------------------------------------------------------
    testWidgets('8. Back navigation after logout tidak kembali Home: Backstack dibersihkan', (tester) async {
      final activeSession = createFakeSession(
        userId: 'user_back_test',
        email: 'back@minddrji.com',
      );
      final fakeAuth = FakeGoTrueClient(initialSession: activeSession);
      final fakeClient = FakeSupabaseClient(auth: fakeAuth);

      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: Routes.home,
          getPages: [
            GetPage(name: Routes.home, page: () => const Scaffold(body: Text('Home Screen'))),
            GetPage(name: Routes.profile, page: () => const Scaffold(body: Text('Profile Screen'))),
            GetPage(name: Routes.login, page: () => const Scaffold(body: Text('Login Screen'))),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Navigasi ke Profile
      Get.toNamed(Routes.profile);
      await tester.pumpAndSettle();
      expect(Get.currentRoute, Routes.profile);

      // Jalankan logout (memanggil Get.offAllNamed(Routes.login))
      final controller = ProfileController(supabaseClient: fakeClient);
      await controller.logout();
      await tester.pumpAndSettle();

      expect(Get.currentRoute, Routes.login);

      // Coba lakukan back navigation
      final canPop = Navigator.of(Get.key.currentContext!).canPop();
      expect(canPop, isFalse);
    });

    // -------------------------------------------------------------------------
    // 9. User state cleared after logout
    // -------------------------------------------------------------------------
    test('9. User state cleared after logout: In-memory state dibersihkan', () async {
      final activeSession = createFakeSession(
        userId: 'user_state_test',
        email: 'state@minddrji.com',
      );
      final fakeAuth = FakeGoTrueClient(initialSession: activeSession);
      final fakeClient = FakeSupabaseClient(auth: fakeAuth);

      final profileController = ProfileController(supabaseClient: fakeClient);
      profileController.profile.value = const ProfileModel(
        id: 'user_state_test',
        namaLengkap: 'User State',
        email: 'state@minddrji.com',
      );

      expect(profileController.profile.value, isNotNull);

      await profileController.logout();

      expect(profileController.profile.value, isNull);
      expect(profileController.currentDeviceInfo.value, isNull);
    });

    // -------------------------------------------------------------------------
    // 10. User isolation
    // -------------------------------------------------------------------------
    test('10. User isolation: Data User A tidak muncul untuk User B pada Drift SQLite', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final repo = InterventionHistoryLocalRepository(db: db);

      final now = DateTime.now();

      // 1. Simpan data milik User A
      final itemA = InterventionModel(
        id: 'session-user-a-1',
        userId: 'uuid_user_a',
        type: InterventionType.digitalBreak,
        title: 'Jeda Digital User A',
        durationMinutes: 15,
        startedAt: now,
        endedAt: now.add(const Duration(minutes: 15)),
        status: InterventionStatus.completed,
        createdAt: now,
      );
      await repo.insert(itemA, userId: 'uuid_user_a');

      // 2. Simpan data milik User B
      final itemB = InterventionModel(
        id: 'session-user-b-1',
        userId: 'uuid_user_b',
        type: InterventionType.focusMode,
        title: 'Mode Fokus User B',
        durationMinutes: 30,
        startedAt: now,
        endedAt: now.add(const Duration(minutes: 30)),
        status: InterventionStatus.active,
        createdAt: now,
      );
      await repo.insert(itemB, userId: 'uuid_user_b');

      // 3. Query data untuk User B
      final historyUserB = await repo.getRecent(limit: 10, userId: 'uuid_user_b');

      // Verifikasi User B HANYA melihat datanya sendiri
      expect(historyUserB.length, 1);
      expect(historyUserB.first.id, 'session-user-b-1');
      expect(historyUserB.first.userId, 'uuid_user_b');
      expect(historyUserB.first.title, 'Mode Fokus User B');

      // Verifikasi data User A tidak bocor ke User B
      final leakedData = historyUserB.where((item) => item.userId == 'uuid_user_a');
      expect(leakedData, isEmpty);

      await db.close();
    });
  });
}
