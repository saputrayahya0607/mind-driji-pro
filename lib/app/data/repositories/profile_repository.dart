import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';

class ProfileRepository {
  final SupabaseClient _client;

  ProfileRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Mengambil data profile milik pengguna yang sedang login.
  /// Mengembalikan null jika pengguna belum login atau data profil belum ditemukan.
  Future<ProfileModel?> getMyProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return null;
    }

    final response = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return ProfileModel.fromJson(response);
  }

  /// Memperbarui data profile pengguna yang sedang login.
  /// Hanya field yang disediakan yang akan di-update.
  Future<ProfileModel> updateMyProfile({
    String? namaLengkap,
    DateTime? tanggalLahir,
    String? noHp,
    String? jenisKelamin,
    bool clearTanggalLahir = false,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('User belum login.');
    }

    final updateData = <String, dynamic>{};
    if (namaLengkap != null) {
      updateData['nama_lengkap'] = namaLengkap.trim();
    }
    if (clearTanggalLahir) {
      updateData['tanggal_lahir'] = null;
    } else if (tanggalLahir != null) {
      updateData['tanggal_lahir'] =
          '${tanggalLahir.year.toString().padLeft(4, '0')}-${tanggalLahir.month.toString().padLeft(2, '0')}-${tanggalLahir.day.toString().padLeft(2, '0')}';
    }
    if (noHp != null) {
      updateData['no_hp'] = noHp.trim().isEmpty ? null : noHp.trim();
    }
    if (jenisKelamin != null) {
      updateData['jenis_kelamin'] =
          jenisKelamin.trim().isEmpty ? null : jenisKelamin.trim();
    }

    if (updateData.isEmpty) {
      final currentProfile = await getMyProfile();
      if (currentProfile != null) return currentProfile;
      throw const PostgrestException(message: 'Tidak ada data untuk diperbarui.');
    }

    final response = await _client
        .from('profiles')
        .update(updateData)
        .eq('id', userId)
        .select()
        .single();

    return ProfileModel.fromJson(response);
  }
}
