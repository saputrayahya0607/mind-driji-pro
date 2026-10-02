import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mind_drji/app/data/models/profile_model.dart';
import 'package:mind_drji/app/data/repositories/profile_repository.dart';
import 'package:mind_drji/app/modules/profile/controllers/edit_profile_controller.dart';
import 'package:mind_drji/app/modules/profile/views/edit_profile_view.dart';

class FakeEditProfileRepository implements ProfileRepository {
  ProfileModel? mockProfile;
  bool shouldThrow = false;
  Map<String, dynamic>? lastUpdatedData;

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
    if (shouldThrow) {
      throw Exception('Update failed');
    }
    lastUpdatedData = {
      'nama_lengkap': namaLengkap,
      'tanggal_lahir': tanggalLahir,
      'no_hp': noHp,
      'jenis_kelamin': jenisKelamin,
      'clearTanggalLahir': clearTanggalLahir,
    };
    mockProfile = ProfileModel(
      id: mockProfile?.id ?? 'test-user-id',
      namaLengkap: namaLengkap ?? mockProfile?.namaLengkap,
      email: mockProfile?.email ?? 'test@example.com',
      tanggalLahir:
          clearTanggalLahir ? null : (tanggalLahir ?? mockProfile?.tanggalLahir),
      noHp: noHp ?? mockProfile?.noHp,
      jenisKelamin: jenisKelamin ?? mockProfile?.jenisKelamin,
    );
    return mockProfile!;
  }
}

void main() {
  late FakeEditProfileRepository fakeRepo;

  setUp(() {
    Get.reset();
    fakeRepo = FakeEditProfileRepository();
  });

  tearDown(() {
    Get.reset();
  });

  group('EditProfileController Validation Tests', () {
    test('Validasi Nama Lengkap wajib dan minimal 2 karakter', () {
      final controller = EditProfileController(profileRepository: fakeRepo);

      expect(controller.validateNamaLengkap(null), 'Nama lengkap wajib diisi');
      expect(controller.validateNamaLengkap(''), 'Nama lengkap wajib diisi');
      expect(controller.validateNamaLengkap('   '), 'Nama lengkap wajib diisi');
      expect(
          controller.validateNamaLengkap('A'), 'Nama lengkap minimal 2 karakter');
      expect(controller.validateNamaLengkap('Al'), isNull);
      expect(controller.validateNamaLengkap('Misya Amalia'), isNull);
    });

    test('Validasi Nomor HP boleh kosong dan valid format nomor', () {
      final controller = EditProfileController(profileRepository: fakeRepo);

      expect(controller.validateNoHp(null), isNull);
      expect(controller.validateNoHp(''), isNull);
      expect(controller.validateNoHp('   '), isNull);
      expect(controller.validateNoHp('08123456789'), isNull);
      expect(controller.validateNoHp('+62 812-3456-7890'), isNull);
      expect(controller.validateNoHp('abc-def'), 'Format nomor HP tidak valid');
    });
  });

  group('EditProfileController Data Population Tests', () {
    test('Populate form controllers dari initial profile async', () async {
      fakeRepo.mockProfile = ProfileModel(
        id: 'user-123',
        namaLengkap: 'Misya Amalia',
        email: 'misya@example.com',
        noHp: '081234567890',
        tanggalLahir: DateTime(2000, 5, 15),
        jenisKelamin: 'Perempuan',
      );

      final controller = EditProfileController(profileRepository: fakeRepo);
      await controller.loadInitialProfile();

      expect(controller.namaLengkapController.text, 'Misya Amalia');
      expect(controller.emailController.text, 'misya@example.com');
      expect(controller.noHpController.text, '081234567890');
      expect(controller.tanggalLahir.value, DateTime(2000, 5, 15));
      expect(controller.jenisKelamin.value, 'Perempuan');
    });

    test('Nilai null di database menampilkan form kosong / null', () async {
      fakeRepo.mockProfile = const ProfileModel(
        id: 'user-124',
        namaLengkap: null,
        email: 'misya@example.com',
        noHp: null,
        tanggalLahir: null,
        jenisKelamin: null,
      );

      final controller = EditProfileController(profileRepository: fakeRepo);
      await controller.loadInitialProfile();

      expect(controller.namaLengkapController.text, '');
      expect(controller.noHpController.text, '');
      expect(controller.tanggalLahir.value, isNull);
      expect(controller.jenisKelamin.value, isNull);
    });
  });

  group('EditProfileView Widget Tests', () {
    testWidgets('Tampilkan seluruh elemen formulir Edit Profil', (tester) async {
      fakeRepo.mockProfile = ProfileModel(
        id: 'user-123',
        namaLengkap: 'Misya',
        email: 'misyaamalia001@gmail.com',
        noHp: null,
        tanggalLahir: null,
        jenisKelamin: null,
      );

      Get.put(EditProfileController(profileRepository: fakeRepo));

      await tester.pumpWidget(
        const GetMaterialApp(
          home: EditProfileView(),
        ),
      );

      // Verifikasi Header AppBar & Judul
      expect(find.text('Edit Profil'), findsOneWidget);
      expect(find.text('Perbarui Data Diri'), findsOneWidget);

      // Verifikasi Label Field
      expect(find.text('Email (Informasi Akun)'), findsOneWidget);
      expect(find.text('misyaamalia001@gmail.com'), findsOneWidget);
      expect(find.text('Nama Lengkap *'), findsOneWidget);
      expect(find.text('Nomor HP'), findsOneWidget);
      expect(find.text('Tanggal Lahir'), findsOneWidget);
      expect(find.text('Jenis Kelamin'), findsOneWidget);

      // Verifikasi Tombol Simpan
      expect(find.text('Simpan Perubahan'), findsOneWidget);

      // Verifikasi Fallback Null
      expect(find.text('Pilih tanggal'), findsOneWidget);
      expect(find.text('Pilih jenis kelamin'), findsOneWidget);
    });
  });
}
