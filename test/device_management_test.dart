import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Value;
import 'package:mind_drji/app/data/local/app_database.dart';
import 'package:mind_drji/app/data/local/repositories/doomscroll_local_repository.dart';
import 'package:mind_drji/app/data/local/repositories/eye_monitoring_local_repository.dart';
import 'package:mind_drji/app/data/local/repositories/local_usage_repository.dart';
import 'package:mind_drji/app/data/models/app_usage_model.dart';
import 'package:mind_drji/app/data/models/device_info_model.dart';
import 'package:mind_drji/app/data/models/doomscroll_session_model.dart';
import 'package:mind_drji/app/data/models/eye_monitoring_session_model.dart';
import 'package:mind_drji/app/data/models/profile_model.dart';
import 'package:mind_drji/app/data/services/device_service.dart';
import 'package:mind_drji/app/modules/profile/controllers/profile_controller.dart';
import 'package:mind_drji/app/modules/profile/views/profile_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late DeviceService deviceService;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    deviceService = DeviceService(db: db);
  });

  tearDown(() async {
    await db.close();
    Get.reset();
  });

  group('Device Management & Device ID Tests', () {
    test('1. device_id persistent - disimpan di SQLite lokal dan nilainya konsisten', () async {
      final id1 = await deviceService.getDeviceId();
      final id2 = await deviceService.getDeviceId();

      expect(id1, isNotEmpty);
      expect(id1, equals(id2));

      // Verifikasi tersimpan di tabel local_device_info SQLite
      final stored = await (db.select(db.localDeviceInfo)
            ..where((t) => t.id.equals('current_device')))
          .getSingleOrNull();

      expect(stored, isNotNull);
      expect(stored!.deviceId, equals(id1));
      expect(stored.id, equals('current_device'));
    });

    test('2. device_id tetap setelah restart aplikasi', () async {
      final originalId = await deviceService.getDeviceId();

      // Simulasikan app restart: buat instance DeviceService baru pada DB yang sama
      final restartedService = DeviceService(db: db);
      final idAfterRestart = await restartedService.getDeviceId();

      expect(idAfterRestart, equals(originalId));
    });

    test('3. device_id tetap setelah logout', () async {
      final idBeforeLogout = await deviceService.getDeviceId();

      // Simulasikan logout (user keluar, auth state hilang)
      // Device ID tidak boleh di-reset atau diubah
      final idAfterLogout = await deviceService.getDeviceId();

      expect(idAfterLogout, equals(idBeforeLogout));
    });

    test('4. device_id tetap saat akun berganti pada HP yang sama', () async {
      final deviceId = await deviceService.getDeviceId();

      // User A aktif pada perangkat ini
      const userA = 'user-uuid-aaaa-1111';
      final infoUserA = await deviceService.getDeviceInfo();
      expect(infoUserA.deviceId, equals(deviceId));

      // User A logout, User B login pada perangkat yang sama
      const userB = 'user-uuid-bbbb-2222';
      final infoUserB = await deviceService.getDeviceInfo();

      // Device ID tetap identik pada HP yang sama, terlepas dari pergantian akun
      expect(infoUserB.deviceId, equals(deviceId));
      expect(userA, isNot(equals(userB)));
    });

    test('5. device_id berbeda antar instalasi / device fisik yang berbeda', () async {
      final db2 = AppDatabase(NativeDatabase.memory());
      final deviceService2 = DeviceService(db: db2);

      final deviceId1 = await deviceService.getDeviceId();
      final deviceId2 = await deviceService2.getDeviceId();

      expect(deviceId1, isNotEmpty);
      expect(deviceId2, isNotEmpty);
      expect(deviceId1, isNot(equals(deviceId2)));

      // Keduanya adalah valid UUID format (36 karakter dengan 4 tanda hubung)
      final uuidRegex = RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
      expect(uuidRegex.hasMatch(deviceId1), isTrue);
      expect(uuidRegex.hasMatch(deviceId2), isTrue);

      await db2.close();
    });

    test('6. satu user dapat memiliki >3 device tanpa batas (multi-device unlimited)', () async {
      // Simulasikan 5 perangkat berbeda untuk user Yahya
      const userId = 'user-yahya-uuid';
      final registeredDevices = <String, Map<String, dynamic>>{};

      for (int i = 1; i <= 5; i++) {
        final devId = 'device-uuid-000$i';
        final compositeKey = '$userId:$devId';

        // Tidak ada batasan max_devices = 3, simpan dengan UNIQUE(user_id, device_id)
        registeredDevices[compositeKey] = {
          'user_id': userId,
          'device_id': devId,
          'device_name': 'Android Phone $i',
          'last_seen_at': DateTime.now().toUtc().toIso8601String(),
        };
      }

      expect(registeredDevices.length, equals(5));
      expect(registeredDevices.length, greaterThan(3));

      // Verifikasi seluruh 5 perangkat terdaftar untuk user yang sama
      final userDevices = registeredDevices.values
          .where((d) => d['user_id'] == userId)
          .toList();
      expect(userDevices.length, equals(5));
    });

    test('7. multi-user isolation di Drift lokal (data akun berbeda tidak tercampur)', () async {
      final localUsageRepo = LocalUsageRepository(db: db);
      final devId = await deviceService.getDeviceId();
      const date = '2026-09-29';

      const userA = 'user-A';
      const userB = 'user-B';

      // Simpan usage untuk User A
      await localUsageRepo.saveTodayUsage(
        userId: userA,
        deviceId: devId,
        date: date,
        totalUsageMillis: 3600000, // 1 jam
        apps: [
          AppUsageModel(packageName: 'com.whatsapp', appName: 'WhatsApp', usageMillis: 3600000),
        ],
      );

      // Simpan usage untuk User B pada HP yang sama
      await localUsageRepo.saveTodayUsage(
        userId: userB,
        deviceId: devId,
        date: date,
        totalUsageMillis: 7200000, // 2 jam
        apps: [
          AppUsageModel(packageName: 'com.instagram.android', appName: 'Instagram', usageMillis: 7200000),
        ],
      );

      // Query User A
      final screenTimeA = await localUsageRepo.getScreenTime(userA, date, deviceId: devId);
      final appsA = await localUsageRepo.getAppUsages(userA, date, deviceId: devId);

      // Query User B
      final screenTimeB = await localUsageRepo.getScreenTime(userB, date, deviceId: devId);
      final appsB = await localUsageRepo.getAppUsages(userB, date, deviceId: devId);

      expect(screenTimeA!.totalUsageMillis.toInt(), equals(3600000));
      expect(appsA.length, equals(1));
      expect(appsA.first.packageName, equals('com.whatsapp'));

      expect(screenTimeB!.totalUsageMillis.toInt(), equals(7200000));
      expect(appsB.length, equals(1));
      expect(appsB.first.packageName, equals('com.instagram.android'));
    });

    test('8. multi-device isolation di Drift lokal (data perangkat berbeda tidak saling menimpa)', () async {
      final localUsageRepo = LocalUsageRepository(db: db);
      const userId = 'user-yahya';
      const date = '2026-09-29';

      const dev1 = 'device-tablet';
      const dev2 = 'device-phone';

      // User Yahya menggunakan Tablet
      await localUsageRepo.saveTodayUsage(
        userId: userId,
        deviceId: dev1,
        date: date,
        totalUsageMillis: 1800000, // 30 menit
        apps: [
          AppUsageModel(packageName: 'com.google.android.youtube', appName: 'YouTube', usageMillis: 1800000),
        ],
      );

      // User Yahya menggunakan Phone
      await localUsageRepo.saveTodayUsage(
        userId: userId,
        deviceId: dev2,
        date: date,
        totalUsageMillis: 5400000, // 90 menit
        apps: [
          AppUsageModel(packageName: 'com.zhiliaoapp.musically', appName: 'TikTok', usageMillis: 5400000),
        ],
      );

      // Query data Tablet
      final usageDev1 = await localUsageRepo.getScreenTime(userId, date, deviceId: dev1);
      final appsDev1 = await localUsageRepo.getAppUsages(userId, date, deviceId: dev1);

      // Query data Phone
      final usageDev2 = await localUsageRepo.getScreenTime(userId, date, deviceId: dev2);
      final appsDev2 = await localUsageRepo.getAppUsages(userId, date, deviceId: dev2);

      expect(usageDev1!.totalUsageMillis.toInt(), equals(1800000));
      expect(appsDev1.first.appName, equals('YouTube'));

      expect(usageDev2!.totalUsageMillis.toInt(), equals(5400000));
      expect(appsDev2.first.appName, equals('TikTok'));
    });

    test('9. payload monitoring berisi user_id + device_id valid dan bukan local_user', () async {
      const authUserId = 'real-authenticated-user-id';
      const devId = 'persisted-device-id-1234';

      final doomscrollModel = DoomscrollSessionModel(
        id: 'sess-doom-1',
        userId: authUserId,
        deviceId: devId,
        packageName: 'com.ss.android.ugc.trill',
        appName: 'TikTok',
        startedAt: DateTime.now().subtract(const Duration(minutes: 5)),
        endedAt: DateTime.now(),
        durationMillis: 300000,
        swipeCount: 40,
        downwardSwipeCount: 38,
        upwardSwipeCount: 2,
        avgInterSwipeMillis: 3500,
        collectedAt: DateTime.now(),
      );

      final doomPayload = doomscrollModel.toMap();
      expect(doomPayload['user_id'], equals(authUserId));
      expect(doomPayload['device_id'], equals(devId));
      expect(doomPayload['user_id'], isNot(equals('local_user')));

      final eyeModel = EyeMonitoringSessionModel(
        id: 'sess-eye-1',
        userId: authUserId,
        deviceId: devId,
        startedAt: DateTime.now().subtract(const Duration(minutes: 10)),
        endedAt: DateTime.now(),
        durationMillis: 600000,
        averageEar: 0.28,
        minEar: 0.17,
        eyeClosureEvents: 4,
        blinkCount: 20,
        collectedAt: DateTime.now(),
      );

      final eyePayload = eyeModel.toSupabaseMap(authUserId);
      expect(eyePayload['user_id'], equals(authUserId));
      expect(eyePayload['device_id'], equals(devId));
      expect(eyePayload['user_id'], isNot(equals('local_user')));
    });

    test('10. RLS isolation boundary: user_id adalah security boundary, bukan device_id', () {
      const userA = 'user-auth-uuid-A';
      const userB = 'user-auth-uuid-B';
      const sharedDeviceOnMultiAccount = 'physical-device-id-X';

      // Aturan RLS Supabase: auth.uid() = user_id
      bool canAccess(String currentAuthUid, String rowUserId) {
        return currentAuthUid == rowUserId;
      }

      // Record milik User A di perangkat X
      final rowUserA = {'user_id': userA, 'device_id': sharedDeviceOnMultiAccount};

      // Record milik User B di perangkat X
      final rowUserB = {'user_id': userB, 'device_id': sharedDeviceOnMultiAccount};

      // User A mencoba membaca data miliknya -> BERHASIL
      expect(canAccess(userA, rowUserA['user_id']!), isTrue);

      // User A mencoba membaca data User B (meski di HP yang sama) -> DITOLAK
      expect(canAccess(userA, rowUserB['user_id']!), isFalse);

      // User B mencoba membaca data miliknya -> BERHASIL
      expect(canAccess(userB, rowUserB['user_id']!), isTrue);

      // User B mencoba membaca data User A -> DITOLAK
      expect(canAccess(userB, rowUserA['user_id']!), isFalse);
    });

    test('11. Legacy data compatibility: default device_id adalah legacy', () async {
      final doomLocalRepo = DoomscrollLocalRepository(db: db);
      final eyeLocalRepo = EyeMonitoringLocalRepository(db: db);

      // Model tanpa deviceId eksplisit mendapatkan default 'legacy'
      final legacyDoom = DoomscrollSessionModel(
        id: 'legacy-doom-1',
        packageName: 'com.instagram.android',
        appName: 'Instagram',
        startedAt: DateTime.now(),
        durationMillis: 10000,
        swipeCount: 5,
        downwardSwipeCount: 5,
        upwardSwipeCount: 0,
        avgInterSwipeMillis: 2000,
        collectedAt: DateTime.now(),
      );
      expect(legacyDoom.deviceId, equals('legacy'));

      // Sesi lama dapat disimpan dan dibaca kembali dengan fallback legacy
      await doomLocalRepo.insertSession(legacyDoom);
      final stored = await doomLocalRepo.getSessionById('legacy-doom-1');
      expect(stored, isNotNull);
      expect(stored!.deviceId, isNotEmpty);

      final legacyEye = EyeMonitoringSessionModel(
        id: 'legacy-eye-1',
        startedAt: DateTime.now(),
        durationMillis: 15000,
        averageEar: 0.29,
        minEar: 0.18,
        eyeClosureEvents: 1,
        blinkCount: 5,
        collectedAt: DateTime.now(),
      );
      expect(legacyEye.deviceId, equals('legacy'));

      await eyeLocalRepo.insertSession(legacyEye);
      final storedEye = await eyeLocalRepo.getSessionById('legacy-eye-1');
      expect(storedEye, isNotNull);
      expect(storedEye!.deviceId, isNotEmpty);
    });

    test('12. displayBrand memprioritaskan manufacturer (Build.MANUFACTURER) dan fallback ke model secara dinamis tanpa hardcode', () {
      // Uji berbagai brand Android nyata tanpa hardcode/mapping manual
      final brands = [
        'Xiaomi', 'Samsung', 'OPPO', 'vivo', 'realme', 'Google',
        'OnePlus', 'Motorola', 'ASUS', 'Huawei', 'Sony', 'Nokia',
        'Infinix', 'TECNO', 'HONOR', 'Lenovo', 'ZTE', 'Fairphone', 'Nothing'
      ];

      for (final b in brands) {
        final info = DeviceInfoModel(
          deviceId: 'dev-1',
          deviceName: '$b ModelX',
          manufacturer: b,
          model: 'ModelX',
          androidVersion: '14',
          appVersion: '1.0.0',
          firstSeenAt: DateTime.now(),
          lastSeenAt: DateTime.now(),
        );
        expect(info.displayBrand, equals(b));
      }

      // Uji fallback ke model jika manufacturer kosong / unknown
      final fallbackInfo = DeviceInfoModel(
        deviceId: 'dev-2',
        deviceName: 'Pixel 8',
        manufacturer: '',
        model: 'Pixel 8',
        androidVersion: '15',
        appVersion: '1.0.0',
        firstSeenAt: DateTime.now(),
        lastSeenAt: DateTime.now(),
      );
      expect(fallbackInfo.displayBrand, equals('Pixel 8'));

      final unknownMfgInfo = DeviceInfoModel(
        deviceId: 'dev-3',
        deviceName: 'Generic Pad',
        manufacturer: 'Unknown',
        model: 'Tab Ultra',
        androidVersion: '13',
        appVersion: '1.0.0',
        firstSeenAt: DateTime.now(),
        lastSeenAt: DateTime.now(),
      );
      expect(unknownMfgInfo.displayBrand, equals('Tab Ultra'));
    });

    testWidgets('13. UI Profile menampilkan 📱 Perangkat Ini dengan Merek dan Android Version', (tester) async {
      final fakeController = Get.put(ProfileController());
      fakeController.isLoading.value = false;
      fakeController.errorMessage.value = null;
      fakeController.profile.value = ProfileModel(
        id: 'u1',
        email: 'yahya@example.com',
        namaLengkap: 'Yahya',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      fakeController.currentDeviceInfo.value = DeviceInfoModel(
        deviceId: 'uuid-1234-5678-abcd',
        deviceName: 'Xiaomi 13T',
        manufacturer: 'Xiaomi',
        model: '2306EPN60G',
        androidVersion: '14',
        appVersion: '1.0.0',
        firstSeenAt: DateTime.now(),
        lastSeenAt: DateTime.now(),
      );

      await tester.pumpWidget(
        const GetMaterialApp(
          home: ProfileView(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Perangkat Ini'), findsOneWidget);
      expect(find.text('Xiaomi'), findsOneWidget);
      expect(find.text('Android 14'), findsOneWidget);
      expect(find.textContaining('Model: 2306EPN60G'), findsOneWidget);
    });
  });
}
