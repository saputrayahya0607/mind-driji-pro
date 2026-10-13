import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mind_drji/app/data/models/device_info_model.dart';
import 'package:mind_drji/app/data/models/profile_model.dart';
import 'package:mind_drji/app/data/repositories/profile_repository.dart';
import 'package:mind_drji/app/data/services/device_service.dart';
import 'package:mind_drji/app/modules/login/controllers/login_controller.dart';
import 'package:mind_drji/app/modules/login/views/login_view.dart';
import 'package:mind_drji/app/modules/register/controllers/register_controller.dart';
import 'package:mind_drji/app/modules/register/views/register_view.dart';
import 'package:mind_drji/app/modules/profile/controllers/profile_controller.dart';
import 'package:mind_drji/app/modules/profile/views/profile_view.dart';
import 'package:mind_drji/app/modules/profile/controllers/edit_profile_controller.dart';
import 'package:mind_drji/app/modules/profile/views/edit_profile_view.dart';
import 'package:mind_drji/app/modules/permission_guide/controllers/permission_guide_controller.dart';
import 'package:mind_drji/app/modules/permission_guide/views/permission_guide_view.dart';

class FakeAuditProfileRepo implements ProfileRepository {
  ProfileModel? mockProfile;
  @override
  Future<ProfileModel?> getMyProfile() async => mockProfile;
  @override
  Future<ProfileModel> updateMyProfile({
    String? namaLengkap,
    String? noHp,
    DateTime? tanggalLahir,
    String? jenisKelamin,
    bool clearTanggalLahir = false,
  }) async {
    mockProfile = ProfileModel(
      id: 'mock-1',
      namaLengkap: namaLengkap ?? 'User',
      email: 'test@example.com',
      noHp: noHp,
      tanggalLahir: clearTanggalLahir ? null : tanggalLahir,
      jenisKelamin: jenisKelamin,
    );
    return mockProfile!;
  }
}

class FakeAuditDeviceService extends DeviceService {
  DeviceInfoModel mockInfo = DeviceInfoModel(
    deviceId: 'samsung-galaxy-s24-ultra-12345678',
    deviceName: 'Samsung Galaxy S24 Ultra',
    manufacturer: 'Samsung',
    model: 'Galaxy S24 Ultra',
    androidVersion: '14',
    appVersion: '1.0.0',
    firstSeenAt: DateTime.now(),
    lastSeenAt: DateTime.now(),
  );
  @override
  Future<DeviceInfoModel> getDeviceInfo() async => mockInfo;
  @override
  Future<bool> checkBatteryOptimization() async => false;
}

void main() {
  setUp(() {
    Get.reset();
    FlutterError.onError = (details) {
      debugPrint('FLUTTER ERROR CAUGHT:\n${details.summary}\n${details.context}');
    };
  });

  tearDown(() {
    Get.reset();
  });

  Widget buildTestApp(Widget home) {
    return GetMaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          size: const Size(360, 640),
          textScaler: const TextScaler.linear(1.5),
        ),
        child: child!,
      ),
      home: home,
    );
  }

  testWidgets('1. LoginView renders without overflow on 360dp with 1.5x font scale', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    Get.put(LoginController());
    await tester.pumpWidget(buildTestApp(const LoginView()));
    await tester.pumpAndSettle();

    expect(find.text('Masuk'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('2. RegisterView renders without overflow on 360dp with 1.5x font scale', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    Get.put(RegisterController());
    await tester.pumpWidget(buildTestApp(const RegisterView()));
    await tester.pumpAndSettle();

    expect(find.text('Daftar Sekarang'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('3. ProfileView renders without overflow on 360dp with 1.5x font scale', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final repo = FakeAuditProfileRepo();
    final devService = FakeAuditDeviceService();

    final controller = Get.put(ProfileController(
      profileRepository: repo,
      deviceService: devService,
    ));
    controller.isLoading.value = false;
    controller.errorMessage.value = null;
    controller.profile.value = const ProfileModel(
      id: 'u-1',
      namaLengkap: 'Yahya Saputra Perdana Kusuma',
      email: 'yahyasaputra.wellness@example.com',
      noHp: '08123456789012',
      tanggalLahir: null,
      jenisKelamin: 'Laki-laki',
    );
    controller.currentDeviceInfo.value = devService.mockInfo;

    await tester.pumpWidget(buildTestApp(const ProfileView()));
    await tester.pumpAndSettle();

    expect(find.text('Profil'), findsWidgets);
    expect(find.text('Perangkat Ini'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('4. EditProfileView renders without overflow on 360dp with 1.5x font scale', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final repo = FakeAuditProfileRepo()
      ..mockProfile = const ProfileModel(
        id: 'u-1',
        namaLengkap: 'Yahya Saputra',
        email: 'yahya@example.com',
      );

    Get.put(EditProfileController(
      profileRepository: repo,
    ));

    await tester.pumpWidget(buildTestApp(const EditProfileView()));
    await tester.pumpAndSettle();

    expect(find.text('Simpan Perubahan'), findsOneWidget);
    final exc = tester.takeException();
    if (exc != null) {
      if (exc is FlutterError) {
        debugPrint('TEST 4 OVERFLOW:\n${exc.toStringDeep()}');
      }
    }
    expect(exc, isNull);
  });

  testWidgets('5. PermissionGuideView renders without overflow on 360dp with 1.5x font scale', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final devService = FakeAuditDeviceService();
    final controller = Get.put(PermissionGuideController(
      deviceService: devService,
    ));
    controller.deviceManufacturer.value = 'Samsung';
    controller.batteryOptimizationIgnored.value = false;

    await tester.pumpWidget(buildTestApp(const PermissionGuideView()));
    await tester.pumpAndSettle();

    expect(find.text('Persiapan Monitoring'), findsWidgets);
    expect(find.text('Matikan Hemat Baterai'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('6. Double submit prevention: LoginController ignores repeated login calls while loading', (tester) async {
    final controller = LoginController();
    controller.isLoading.value = true;
    controller.emailController.text = 'invalid_email';
    // Should immediately return without validating form or throwing
    await controller.login();
    expect(controller.isLoading.value, isTrue);
  });

  testWidgets('7. Double submit prevention: RegisterController ignores repeated register calls while loading', (tester) async {
    final controller = RegisterController();
    controller.isLoading.value = true;
    controller.emailController.text = 'invalid_email';
    // Should immediately return without validating form or throwing
    await controller.register();
    expect(controller.isLoading.value, isTrue);
  });

  testWidgets('8. Double submit prevention: EditProfileController ignores repeated saveProfile calls while saving', (tester) async {
    final controller = EditProfileController(profileRepository: FakeAuditProfileRepo());
    controller.isSaving.value = true;
    // Should immediately return
    await controller.saveProfile();
    expect(controller.isSaving.value, isTrue);
  });
}
