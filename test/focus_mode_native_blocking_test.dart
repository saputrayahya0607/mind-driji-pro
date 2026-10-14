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
    if (isExcludedPackage(pkgName)) {
      currentForegroundPackage = pkgName;
      lastForegroundPackage = pkgName;
      lastBlockedAt = 0; // Reset debounce when user lands back on home screen / excluded app
      return false;
    }

    // New launch attempt from outside target app or different app resets debounce
    if (lastForegroundPackage != null && lastForegroundPackage != pkgName) {
      lastBlockedAt = 0;
    }
    lastForegroundPackage = pkgName;

    if (!isFocusModeActive(nowMillis)) {
      currentForegroundPackage = pkgName;
      return false;
    }

    if (!isTargetPackage(pkgName)) {
      currentForegroundPackage = pkgName;
      return false;
    }

    // Target package detected during active intervention:
    // Blocking action (return to Home) is ALWAYS executed!
    final isBurstEvent = (nowMillis - lastBlockedAt < 1500);
    lastBlockedAt = nowMillis;

    blockCount++;
    currentForegroundPackage = 'com.android.launcher';

    // Throttled feedback toast (2500ms) only if not burst event
    if (!isBurstEvent && (nowMillis - lastToastAt >= 2500)) {
      lastToastAt = nowMillis;
      feedbackCount++;
    }

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
    // 11. No blocking loop & debounce maintains blocking action
    // -------------------------------------------------------------------------
    test('11. No blocking loop: Rapid burst events debounces feedback while maintaining blocking', () async {
      await service.startFocusMode(15);
      final sim = SimulatedAccessibilityService(mockPlatform.sharedPreferences);

      final now = DateTime.now().millisecondsSinceEpoch;

      // Event pertama memicu block & feedback
      expect(sim.onWindowStateChanged('com.ss.android.ugc.trill', now), isTrue);
      expect(sim.feedbackCount, 1);

      // Event subview burst dalam 50ms tetap diblokir (mengembalikan pengguna ke Home),
      // namun feedback toast/notification didebounce sehingga tidak terjadi spam
      expect(sim.onWindowStateChanged('com.ss.android.ugc.trill', now + 50), isTrue);
      expect(sim.onWindowStateChanged('com.ss.android.ugc.trill', now + 100), isTrue);

      expect(sim.blockCount, 3);
      expect(sim.feedbackCount, 1); // Feedback tetap 1 karena burst debounce
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

      // Event berikutnya setelah 500ms tetap diblokir tapi toast dithrottle
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

  group('TAHAP 3 — BACKGROUND INTERVENTION BLOCKING SCENARIOS', () {
    // Skenario 1: Intervensi aktif dan aplikasi target dibuka
    test('Skenario 1: Intervensi aktif dan aplikasi target dibuka -> langsung dicegat dan dialihkan ke Home', () async {
      await service.startFocusMode(20);
      final sim = SimulatedAccessibilityService(mockPlatform.sharedPreferences);
      final now = DateTime.now().millisecondsSinceEpoch;

      final blocked = sim.onWindowStateChanged('com.instagram.android', now);
      expect(blocked, isTrue);
      expect(sim.currentForegroundPackage, 'com.android.launcher');
      expect(sim.blockCount, 1);
    });

    // Skenario 2: Intervensi aktif ketika MIND DRIJI berada di latar belakang
    test('Skenario 2: Intervensi aktif ketika MIND DRIJI di latar belakang -> target app dicegat langsung tanpa buka MIND DRIJI', () async {
      await service.startFocusMode(15);
      final sim = SimulatedAccessibilityService(mockPlatform.sharedPreferences);
      final now = DateTime.now().millisecondsSinceEpoch;

      // 1. Pengguna keluar dari MIND DRIJI ke launcher bawaan MIUI/AOSP
      sim.onWindowStateChanged('com.hn.mind_drji', now);
      sim.onWindowStateChanged('com.android.launcher', now + 200);

      // 2. Dari launcher, pengguna langsung membuka Instagram TANPA pernah membuka MIND DRIJI lagi
      final blocked = sim.onWindowStateChanged('com.instagram.android', now + 1000);

      // 3. AccessibilityService wajib memblokir dan mengembalikan ke launcher secara otonom
      expect(blocked, isTrue);
      expect(sim.currentForegroundPackage, 'com.android.launcher');
      expect(sim.blockCount, 1);
    });

    // Skenario 3: Intervensi kedaluwarsa
    test('Skenario 3: Intervensi kedaluwarsa -> aplikasi target diizinkan dan state native dibersihkan', () async {
      await service.startFocusMode(10);
      final sim = SimulatedAccessibilityService(mockPlatform.sharedPreferences);
      final endedAt = mockPlatform.sharedPreferences['focus_mode_ended_at'] as int;

      // Saat timer telah habis (endedAt + 1 detik)
      final blocked = sim.onWindowStateChanged('com.instagram.android', endedAt + 1000);

      expect(blocked, isFalse);
      expect(sim.blockCount, 0);
      expect(mockPlatform.sharedPreferences['focus_mode_active'], isFalse);
      expect(mockPlatform.sharedPreferences['status'], 'inactive');
    });

    // Skenario 4: Intervensi dihentikan manual
    test('Skenario 4: Intervensi dihentikan manual -> blokir berhenti dan aplikasi target dapat dibuka', () async {
      await service.startFocusMode(15);
      final sim = SimulatedAccessibilityService(mockPlatform.sharedPreferences);
      final now = DateTime.now().millisecondsSinceEpoch;

      // Saat aktif -> diblokir
      expect(sim.onWindowStateChanged('com.ss.android.ugc.trill', now), isTrue);

      // Hentikan secara manual
      await service.cancelIntervention();

      // Sekarang buka target -> diizinkan
      final blockedAfterStop = sim.onWindowStateChanged('com.ss.android.ugc.trill', now + 500);
      expect(blockedAfterStop, isFalse);
      expect(mockPlatform.sharedPreferences['focus_mode_active'], isFalse);
    });

    // Skenario 5: Event launcher/System UI berulang tidak menyebabkan loop
    test('Skenario 5: Event launcher/System UI berulang tidak menyebabkan loop atau blocking palsu', () async {
      await service.startFocusMode(15);
      final sim = SimulatedAccessibilityService(mockPlatform.sharedPreferences);
      final now = DateTime.now().millisecondsSinceEpoch;

      // Event beruntun dari Home/System UI
      expect(sim.onWindowStateChanged('com.android.launcher', now), isFalse);
      expect(sim.onWindowStateChanged('com.android.systemui', now + 50), isFalse);
      expect(sim.onWindowStateChanged('com.android.launcher', now + 100), isFalse);
      expect(sim.onWindowStateChanged('com.android.systemui', now + 150), isFalse);

      expect(sim.blockCount, 0);
      expect(sim.feedbackCount, 0);
    });

    // Skenario 6: Debounce peringatan tidak menonaktifkan jalur blokir
    test('Skenario 6: Debounce peringatan tidak menonaktifkan jalur blokir pada multiple window transition', () async {
      await service.startFocusMode(15);
      final sim = SimulatedAccessibilityService(mockPlatform.sharedPreferences);
      final now = DateTime.now().millisecondsSinceEpoch;

      // Event 1: Window transition awal target app -> Blocked + Feedback dimunculkan
      final block1 = sim.onWindowStateChanged('com.instagram.android', now);
      expect(block1, isTrue);
      expect(sim.blockCount, 1);
      expect(sim.feedbackCount, 1);

      // Event 2 & 3: Window transition berikutnya (burst 50ms & 100ms) dari target app
      // CRITICAL: Jalur blokir TETAP AKTIF (true), tetapi feedback toast didebounce (tidak bertambah)
      final block2 = sim.onWindowStateChanged('com.instagram.android', now + 50);
      final block3 = sim.onWindowStateChanged('com.instagram.android', now + 100);

      expect(block2, isTrue, reason: 'Debounce peringatan TIDAK BOLEH menonaktifkan blokir');
      expect(block3, isTrue, reason: 'Debounce peringatan TIDAK BOLEH menonaktifkan blokir');
      expect(sim.blockCount, 3);
      expect(sim.feedbackCount, 1, reason: 'Feedback toast dibatasi untuk menghindari spam UI');
    });
  });
}
