import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mind_drji/app/data/models/profile_model.dart';
import 'package:mind_drji/app/data/repositories/profile_repository.dart';
import 'package:mind_drji/app/modules/profile/controllers/profile_controller.dart';
import 'package:mind_drji/app/modules/profile/views/profile_view.dart';

class FakeProfileRepository implements ProfileRepository {
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

void main() {
  late FakeProfileRepository fakeRepo;

  setUp(() {
    Get.reset();
    fakeRepo = FakeProfileRepository();
  });

  tearDown(() {
    Get.reset();
  });

  group('ProfileController Logic Tests', () {
    test('loadProfile menghasilkan error state jika user belum login / client auth null', () async {
      final controller = ProfileController(profileRepository: fakeRepo);
      // Supabase auth client belum login / null di lingkungan test
      await controller.loadProfile();

      expect(controller.errorMessage.value, 'Data profil belum dapat dimuat.');
      expect(controller.profile.value, isNull);
      expect(controller.isLoading.value, isFalse);
    });
  });

  group('ProfileView Widget Tests', () {
    testWidgets('Tampilkan loading state saat controller.isLoading bernilai true',
        (tester) async {
      final controller = Get.put(ProfileController(profileRepository: fakeRepo));
      controller.isLoading.value = true;
      controller.errorMessage.value = null;
      controller.profile.value = null;

      await tester.pumpWidget(
        const GetMaterialApp(
          home: ProfileView(),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Memuat profil...'), findsOneWidget);
    });

    testWidgets('Tampilkan error state saat controller.errorMessage memiliki nilai',
        (tester) async {
      final controller = Get.put(ProfileController(profileRepository: fakeRepo));
      controller.isLoading.value = false;
      controller.errorMessage.value = 'Data profil belum dapat dimuat.';
      controller.profile.value = null;

      await tester.pumpWidget(
        const GetMaterialApp(
          home: ProfileView(),
        ),
      );

      expect(find.text('Data profil belum dapat dimuat.'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);
    });

    testWidgets(
        'Tampilkan empty state saat profile bernilai null tanpa error',
        (tester) async {
      final controller = Get.put(ProfileController(profileRepository: fakeRepo));
      controller.isLoading.value = false;
      controller.errorMessage.value = null;
      controller.profile.value = null;

      await tester.pumpWidget(
        const GetMaterialApp(
          home: ProfileView(),
        ),
      );

      expect(find.text('Profil belum tersedia'), findsOneWidget);
      expect(find.text('Muat Ulang'), findsOneWidget);
    });

    testWidgets('Tampilkan data profile lengkap dan fallback Belum diisi untuk null fields',
        (tester) async {
      final controller = Get.put(ProfileController(profileRepository: fakeRepo));
      controller.isLoading.value = false;
      controller.errorMessage.value = null;
      controller.profile.value = const ProfileModel(
        id: 'test-user-id',
        namaLengkap: 'Budi Santoso',
        email: 'budi@example.com',
        noHp: null,
        tanggalLahir: null,
        jenisKelamin: null,
      );

      await tester.pumpWidget(
        const GetMaterialApp(
          home: ProfileView(),
        ),
      );

      // Verifikasi Header
      expect(find.text('Profil'), findsWidgets); // Header & Navigation
      expect(
        find.text('Informasi akun dan data diri digital wellness Anda'),
        findsOneWidget,
      );

      // Verifikasi Profile Card
      expect(find.text('Budi Santoso'), findsNWidgets(2)); // Card & Personal Info
      expect(find.text('budi@example.com'), findsNWidgets(2)); // Card & Personal Info
      expect(find.text('BS'), findsOneWidget); // Inisial avatar

      // Verifikasi field null menampilkan "Belum diisi"
      // Ada 3 field null: Nomor HP, Tanggal Lahir, Jenis Kelamin
      expect(find.text('Belum diisi'), findsNWidgets(3));
    });

    testWidgets('Tampilkan data tanggal lahir dan jenis kelamin terformat dengan benar',
        (tester) async {
      final controller = Get.put(ProfileController(profileRepository: fakeRepo));
      controller.isLoading.value = false;
      controller.errorMessage.value = null;
      controller.profile.value = ProfileModel(
        id: 'test-user-id-2',
        namaLengkap: 'Siti Aminah',
        email: 'siti@example.com',
        noHp: '081234567890',
        tanggalLahir: DateTime(2000, 5, 15),
        jenisKelamin: 'P',
      );

      await tester.pumpWidget(
        const GetMaterialApp(
          home: ProfileView(),
        ),
      );

      expect(find.text('Siti Aminah'), findsNWidgets(2));
      expect(find.text('siti@example.com'), findsNWidgets(2));
      expect(find.text('081234567890'), findsOneWidget);
      expect(find.text('15 Mei 2000'), findsOneWidget);
      expect(find.text('Perempuan'), findsOneWidget);
      expect(find.text('Belum diisi'), findsNothing);
    });
  });
}
