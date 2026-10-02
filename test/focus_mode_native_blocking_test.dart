import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:drift/native.dart';
import 'package:mind_drji/app/data/local/app_database.dart';
import 'package:mind_drji/app/data/local/repositories/intervention_history_local_repository.dart';
import 'package:mind_drji/app/data/models/intervention_model.dart';
import 'package:mind_drji/app/data/providers/intervention_native_provider.dart';
import 'package:mind_drji/app/data/services/intervention_service.dart';

/// Mock platform provider simulating Android SharedPreferences and notification state.
class MockNativeInterventionPlatform extends InterventionNativeProvider {
  final Map<String, dynamic> sharedPreferences = {};
  int notificationCount = 0;
  int? activeNotificationId;

  bool startFocusModeCalled = false;
  bool stopFocusModeCalled = false;

  @override
  Future<bool> startFocusMode({
    required String id,
    required int durationMinutes,
    required int endTimestampMillis,
  }) async {
    startFocusModeCalled = true;
    final now = DateTime.now().millisecondsSinceEpoch;

    sharedPreferences['active_id'] = id;
    sharedPreferences['type'] = 'focusMode';
    sharedPreferences['title'] = 'Mode Fokus';
    sharedPreferences['duration_minutes'] = durationMinutes;
    sharedPreferences['started_at'] = now;
    sharedPreferences['ended_at'] = endTimestampMillis;
    sharedPreferences['status'] = 'active';
    sharedPreferences['focus_mode_active'] = true;
    sharedPreferences['focus_mode_ended_at'] = endTimestampMillis;
    sharedPreferences.remove('cancelled_at');

    notificationCount++;
    activeNotificationId = 3001;
    return true;
  }

  @override
  Future<bool> stopFocusMode() async {
    stopFocusModeCalled = true;
    sharedPreferences['status'] = 'inactive';
    sharedPreferences['focus_mode_active'] = false;
    sharedPreferences['focus_mode_ended_at'] = 0;
    sharedPreferences.remove('cancelled_at');

    activeNotificationId = null;
    return true;
  }

  @override
  Future<Map<String, dynamic>?> getInterventionStatus() async {
    final status = sharedPreferences['status'] as String?;
    final endedAt = (sharedPreferences['focus_mode_ended_at'] ??
            sharedPreferences['ended_at'] ??
            0) as int;
    final now = DateTime.now().millisecondsSinceEpoch;

    if (status == 'active' && endedAt > now) {
      return {
        'id': sharedPreferences['active_id'] ?? '',
        'type': sharedPreferences['type'] ?? 'focusMode',
        'title': sharedPreferences['title'] ?? 'Mode Fokus',
        'durationMinutes': sharedPreferences['duration_minutes'] ?? 15,
        'startedAt': DateTime.fromMillisecondsSinceEpoch(
                sharedPreferences['started_at'] as int? ?? now)
            .toIso8601String(),
        'endedAt': DateTime.fromMillisecondsSinceEpoch(endedAt).toIso8601String(),
        'status': 'active',
        'createdAt': DateTime.fromMillisecondsSinceEpoch(
                sharedPreferences['started_at'] as int? ?? now)
            .toIso8601String(),
      };
    } else {
      if (status == 'active' && endedAt <= now) {
        sharedPreferences['status'] = 'inactive';
        sharedPreferences['focus_mode_active'] = false;
        sharedPreferences['focus_mode_ended_at'] = 0;
        activeNotificationId = null;
      }
      return null;
    }
  }
}

/// Simulated Android AccessibilityService state evaluation matching Kotlin implementation.
class SimulatedAccessibilityService {
  final Map<String, dynamic> prefs;
  final List<String> targetPackages = [
    'com.ss.android.ugc.trill',
    'com.zhiliaoapp.musically',
    'com.zhiliaoapp.musically.go',
    'com.ss.android.ugc.aweme',
    'com.instagram.android',
    'com.instagram.lite',
    'com.google.android.youtube',
    'com.snapchat.android',
  ];

  final List<String> excludedPackages = [
    'com.hn.mind_drji',
    'com.android.systemui',
    'com.android.settings',
    'com.google.android.settings',
    'com.android.dialer',
    'com.google.android.dialer',
    'com.samsung.android.dialer',
    'com.google.android.apps.nexuslauncher',
  ];

  int lastBlockedAt = 0;
  int lastToastAt = 0;
  int blockCount = 0;
  int feedbackCount = 0;
  String? currentForegroundPackage;

  SimulatedAccessibilityService(this.prefs);

  bool isFocusModeActive(int nowMillis) {
    final boolActive = prefs['focus_mode_active'] as bool? ?? false;
    final status = prefs['status'] as String?;
    final type = prefs['type'] as String?;
    final endedAt = (prefs['focus_mode_ended_at'] ?? prefs['ended_at'] ?? 0) as int;

    final isActive = boolActive || (status == 'active' && type == 'focusMode');
    if (isActive) {
      if (nowMillis < endedAt) {
        return true;
      } else {
        deactivateNativeFocusMode();
        return false;
      }
    }
    return false;
  }

  void deactivateNativeFocusMode() {
    prefs['status'] = 'inactive';
    prefs['focus_mode_active'] = false;
    prefs['focus_mode_ended_at'] = 0;
  }

  bool isExcludedPackage(String pkgName) {
    if (pkgName.isEmpty) return true;
    if (excludedPackages.contains(pkgName)) return true;
    if (pkgName.contains('launcher')) return true;
    return false;
  }

  bool isTargetPackage(String? pkgName) {
    if (pkgName == null) return false;
    return targetPackages.contains(pkgName);
  }

  String? lastForegroundPackage;

  bool onWindowStateChanged(String pkgName, int nowMillis) {
    if (!isFocusModeActive(nowMillis)) {
      currentForegroundPackage = pkgName;
      lastForegroundPackage = pkgName;
      return false;
    }

    if (isExcludedPackage(pkgName)) {
      currentForegroundPackage = pkgName;
      lastForegroundPackage = pkgName;
      lastBlockedAt = 0; // Reset debounce when user lands back on home screen / excluded app
      return false;
    }

    if (!isTargetPackage(pkgName)) {
      currentForegroundPackage = pkgName;
      lastForegroundPackage = pkgName;
      return false;
    }

    // New launch attempt from outside target app resets debounce
    if (!isTargetPackage(lastForegroundPackage)) {
      lastBlockedAt = 0;
    }

    // Debounce check (1500ms) for rapid events within same app
    if (nowMillis - lastBlockedAt < 1500) {
      lastForegroundPackage = pkgName;
      return false;
    }

    lastBlockedAt = nowMillis;
    blockCount++;
    lastForegroundPackage = pkgName;

    // Throttled feedback toast (2500ms)
    if (nowMillis - lastToastAt >= 2500) {
      lastToastAt = nowMillis;
      feedbackCount++;
    }

    // Active restriction: returns to Home launcher
    currentForegroundPackage = 'com.android.launcher';
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late InterventionHistoryLocalRepository repo;
  late MockNativeInterventionPlatform mockPlatform;
  late InterventionService service;

  setUp(() {
    Get.reset();
    db = AppDatabase(NativeDatabase.memory());
    Get.put<AppDatabase>(db);
    repo = InterventionHistoryLocalRepository(db: db);
    Get.put<InterventionHistoryLocalRepository>(repo);
    mockPlatform = MockNativeInterventionPlatform();
    service = InterventionService(
      nativeProvider: mockPlatform,
      historyRepository: repo,
    );
  });

  tearDown(() async {
    await db.close();
    Get.reset();
  });

  group('STRENGTHEN FOCUS MODE NATIVE BLOCKING REGRESSION TESTS (1 - 14)', () {
    // -------------------------------------------------------------------------
    // 1. Focus Mode active + target package → block
    // -------------------------------------------------------------------------
    test('1. Focus Mode active + target package -> block: target diblokir saat sesi aktif', () async {
      await service.startFocusMode(15);
      final sim = SimulatedAccessibilityService(mockPlatform.sharedPreferences);

      final now = DateTime.now().millisecondsSinceEpoch;
      final blocked = sim.onWindowStateChanged('com.ss.android.ugc.trill', now);

      expect(blocked, isTrue);
      expect(sim.blockCount, 1);
      expect(sim.feedbackCount, 1);
    });

    // -------------------------------------------------------------------------
    // 2. Focus Mode inactive + target package → allow
    // -------------------------------------------------------------------------
    test('2. Focus Mode inactive + target package -> allow: target dapat dibuka jika Focus Mode tidak aktif', () async {
      final sim = SimulatedAccessibilityService(mockPlatform.sharedPreferences);

      final now = DateTime.now().millisecondsSinceEpoch;
      final blocked = sim.onWindowStateChanged('com.instagram.android', now);

      expect(blocked, isFalse);
      expect(sim.blockCount, 0);
    });

    // -------------------------------------------------------------------------
    // 3. MIND DRIJI package → never block
    // -------------------------------------------------------------------------
    test('3. MIND DRIJI package -> never block: aplikasi MIND DRIJI dikecualikan sepenuhnya', () async {
      await service.startFocusMode(30);
      final sim = SimulatedAccessibilityService(mockPlatform.sharedPreferences);

      final now = DateTime.now().millisecondsSinceEpoch;
      final blocked = sim.onWindowStateChanged('com.hn.mind_drji', now);

      expect(blocked, isFalse);
      expect(sim.blockCount, 0);
    });

    // -------------------------------------------------------------------------
    // 4. Non-target package → never block
    // -------------------------------------------------------------------------
    test('4. Non-target package -> never block: aplikasi umum & sistem tidak diblokir', () async {
      await service.startFocusMode(15);
      final sim = SimulatedAccessibilityService(mockPlatform.sharedPreferences);

      final now = DateTime.now().millisecondsSinceEpoch;
      expect(sim.onWindowStateChanged('com.android.settings', now), isFalse);
      expect(sim.onWindowStateChanged('com.android.dialer', now), isFalse);
      expect(sim.onWindowStateChanged('com.android.systemui', now), isFalse);
      expect(sim.onWindowStateChanged('com.whatsapp', now), isFalse);
      expect(sim.blockCount, 0);
    });

    test('5. Repeated target launch -> repeatedly blocked: percobaan buka berulang terus dicegat dan dikembalikan ke Home', () async {
      await service.startFocusMode(15);
      final sim = SimulatedAccessibilityService(mockPlatform.sharedPreferences);

      var now = DateTime.now().millisecondsSinceEpoch;

      // Percobaan 1: buka TikTok -> dicegat, dikembalikan ke launcher
      final block1 = sim.onWindowStateChanged('com.ss.android.ugc.trill', now);
      expect(block1, isTrue);

      // Launcher window state event saat user berada di Home
      sim.onWindowStateChanged('com.android.launcher', now + 100);

      // Percobaan 2 (500ms kemudian): user langsung buka TikTok lagi dari launcher -> tetap dicegat!
      now += 500;
      final block2 = sim.onWindowStateChanged('com.ss.android.ugc.trill', now);
      expect(block2, isTrue);

      // Launcher window state event saat user berada di Home
      sim.onWindowStateChanged('com.android.launcher', now + 100);

      // Percobaan 3 (500ms kemudian): user buka Instagram -> tetap dicegat!
      now += 500;
      final block3 = sim.onWindowStateChanged('com.instagram.android', now);
      expect(block3, isTrue);

      expect(sim.blockCount, 3);
    });

    // -------------------------------------------------------------------------
    // 6. Focus Mode cancel → block stops
    // -------------------------------------------------------------------------
    test('6. Focus Mode cancel -> block stops: pembatalan intervensi menghentikan blocking seketika', () async {
      await service.startFocusMode(15);
      final sim = SimulatedAccessibilityService(mockPlatform.sharedPreferences);

      final now = DateTime.now().millisecondsSinceEpoch;
      expect(sim.onWindowStateChanged('com.google.android.youtube', now), isTrue);

      // Batalkan Focus Mode
      await service.cancelIntervention();
      expect(mockPlatform.sharedPreferences['focus_mode_active'], isFalse);
      expect(mockPlatform.sharedPreferences['status'], 'inactive');

      // Buka YouTube lagi -> diizinkan
      expect(sim.onWindowStateChanged('com.google.android.youtube', now + 1000), isFalse);
    });

    // -------------------------------------------------------------------------
    // 7. Focus Mode expiry → block stops
    // -------------------------------------------------------------------------
    test('7. Focus Mode expiry -> block stops: timer berakhir menghentikan blocking otomatis', () async {
      await service.startFocusMode(15);
      final sim = SimulatedAccessibilityService(mockPlatform.sharedPreferences);

      final endedAt = mockPlatform.sharedPreferences['focus_mode_ended_at'] as int;

      // Sebelum expired (endedAt - 1000ms) -> diblokir
      expect(sim.onWindowStateChanged('com.snapchat.android', endedAt - 1000), isTrue);

      // Setelah expired (endedAt + 1000ms) -> otomatis allow & native state dibersihkan
      expect(sim.onWindowStateChanged('com.snapchat.android', endedAt + 1000), isFalse);
      expect(mockPlatform.sharedPreferences['focus_mode_active'], isFalse);
      expect(mockPlatform.sharedPreferences['status'], 'inactive');
    });

    // -------------------------------------------------------------------------
    // 8. Native state persistence
    // -------------------------------------------------------------------------
    test('8. Native state persistence: SharedPreferences menyimpan focus_mode_active dan ended_at', () async {
      await service.startFocusMode(30);

      expect(mockPlatform.sharedPreferences['focus_mode_active'], isTrue);
      expect(mockPlatform.sharedPreferences['status'], 'active');
      expect(mockPlatform.sharedPreferences['type'], 'focusMode');
      expect(mockPlatform.sharedPreferences['focus_mode_ended_at'], isNotNull);
      expect(mockPlatform.sharedPreferences['ended_at'], isNotNull);
    });

    // -------------------------------------------------------------------------
    // 9. AccessibilityService reconnect reads current state
    // -------------------------------------------------------------------------
    test('9. AccessibilityService reconnect reads current state: Reconnect membaca state dari SharedPreferences', () async {
      await service.startFocusMode(20);

      // Simulasi service baru terkoneksi (reconnect) membaca SharedPreferences yang ada
      final simReconnected = SimulatedAccessibilityService(mockPlatform.sharedPreferences);
      final now = DateTime.now().millisecondsSinceEpoch;

      expect(simReconnected.isFocusModeActive(now), isTrue);
      expect(simReconnected.onWindowStateChanged('com.instagram.lite', now), isTrue);
    });

    // -------------------------------------------------------------------------
    // 10. endedAt passed → automatically inactive
    // -------------------------------------------------------------------------
    test('10. endedAt passed -> automatically inactive: Evaluasi otomatis menonaktifkan state dan bersihkan notifikasi', () async {
      await service.startFocusMode(15);
      expect(mockPlatform.activeNotificationId, 3001);

      final endedAt = mockPlatform.sharedPreferences['focus_mode_ended_at'] as int;

      // Simulasi app query status setelah endedAt lewat
      final sim = SimulatedAccessibilityService(mockPlatform.sharedPreferences);
      final active = sim.isFocusModeActive(endedAt + 5000);

      expect(active, isFalse);
      expect(mockPlatform.sharedPreferences['focus_mode_active'], isFalse);
      expect(mockPlatform.sharedPreferences['status'], 'inactive');
    });

    // -------------------------------------------------------------------------
    // 11. No blocking loop
    // -------------------------------------------------------------------------
    test('11. No blocking loop: Rapid burst events dalam jendela 1500ms didebounce untuk mencegah loop', () async {
      await service.startFocusMode(15);
      final sim = SimulatedAccessibilityService(mockPlatform.sharedPreferences);

      final now = DateTime.now().millisecondsSinceEpoch;

      // Event pertama memicu block
      expect(sim.onWindowStateChanged('com.ss.android.ugc.trill', now), isTrue);

      // Event subview burst dalam 50ms tidak memicu performGlobalAction ganda
      expect(sim.onWindowStateChanged('com.ss.android.ugc.trill', now + 50), isFalse);
      expect(sim.onWindowStateChanged('com.ss.android.ugc.trill', now + 100), isFalse);

      expect(sim.blockCount, 1);
    });

    // -------------------------------------------------------------------------
    // 12. Feedback does not create navigation loop
    // -------------------------------------------------------------------------
    test('12. Feedback does not create navigation loop: Toast feedback dithrottle dan tidak membuka Activity', () async {
      await service.startFocusMode(15);
      final sim = SimulatedAccessibilityService(mockPlatform.sharedPreferences);

      final now = DateTime.now().millisecondsSinceEpoch;

      // Block pertama menghasilkan feedback
      sim.onWindowStateChanged('com.ss.android.ugc.trill', now);
      expect(sim.feedbackCount, 1);

      // Event berikutnya setelah 500ms tetap dihitung tapi toast dithrottle
      sim.onWindowStateChanged('com.ss.android.ugc.trill', now + 500);
      expect(sim.feedbackCount, 1);

      // Setelah 3000ms (melewati TOAST_THROTTLE_MS 2500ms) toast baru dimunculkan kembali
      sim.onWindowStateChanged('com.ss.android.ugc.trill', now + 3000);
      expect(sim.feedbackCount, 2);
    });

    // -------------------------------------------------------------------------
    // 13. No duplicate notification
    // -------------------------------------------------------------------------
    test('13. No duplicate notification: Notifikasi Focus Mode menggunakan ID konstan 3001', () async {
      await service.startFocusMode(15);
      expect(mockPlatform.notificationCount, 1);
      expect(mockPlatform.activeNotificationId, 3001);

      // Stop membatalkan notifikasi ID 3001
      await service.cancelIntervention();
      expect(mockPlatform.activeNotificationId, isNull);
    });

    // -------------------------------------------------------------------------
    // 14. No duplicate history
    // -------------------------------------------------------------------------
    test('14. No duplicate history: Sesi hanya diinsert sekali pada awal startFocusMode', () async {
      await service.startFocusMode(15);

      final historyList = await repo.getByStatus(InterventionStatus.active);
      expect(historyList.length, 1);
      expect(historyList.first.type, InterventionType.focusMode);

      // Pastikan re-check/restore tidak menduplikasi record
      await service.restoreActiveIntervention();
      final allHistory = await repo.getRecent(limit: 10);
      expect(allHistory.length, 1);
    });

    // -------------------------------------------------------------------------
    // Native source code integrity audit tests
    // -------------------------------------------------------------------------
    test('Native source audit: DoomscrollAccessibilityService.kt implements active restriction with GLOBAL_ACTION_HOME', () {
      final file = File('android/app/src/main/kotlin/com/hn/mind_drji/DoomscrollAccessibilityService.kt');
      expect(file.existsSync(), isTrue);
      final content = file.readAsStringSync();

      expect(content, contains('isFocusModeActive'));
      expect(content, contains('focus_mode_active'));
      expect(content, contains('focus_mode_ended_at'));
      expect(content, contains('deactivateNativeFocusMode'));
      expect(content, contains('showBlockingFeedback'));
      expect(content, contains('Sesi Intervensi Aktif'));
      expect(content, contains('Toast.makeText'));
      expect(content, contains('showFocusWarningNotification'));
      expect(content, contains('checkFocusModeBlocking'));
      expect(content, contains('isExcludedPackage'));
      expect(content, contains('com.hn.mind_drji'));
      expect(content, contains('performGlobalAction(GLOBAL_ACTION_HOME)'));
    });

    test('Native source audit: MainActivity.kt persists Focus Mode state and handles cleanup on expiry', () {
      final file = File('android/app/src/main/kotlin/com/hn/mind_drji/MainActivity.kt');
      expect(file.existsSync(), isTrue);
      final content = file.readAsStringSync();

      expect(content, contains('"startFocusMode"'));
      expect(content, contains('"focus_mode_active", true'));
      expect(content, contains('"focus_mode_ended_at"'));
      expect(content, contains('"stopFocusMode"'));
      expect(content, contains('"focus_mode_active", false'));
      expect(content, contains('"getInterventionStatus"'));
    });
  });
}
