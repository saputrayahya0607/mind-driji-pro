class ProfileModel {
  final String id;
  final String? namaLengkap;
  final String? email;
  final DateTime? tanggalLahir;
  final String? noHp;
  final String? jenisKelamin;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProfileModel({
    required this.id,
    this.namaLengkap,
    this.email,
    this.tanggalLahir,
    this.noHp,
    this.jenisKelamin,
    this.createdAt,
    this.updatedAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      namaLengkap: json['nama_lengkap'] as String?,
      email: json['email'] as String?,
      tanggalLahir: json['tanggal_lahir'] != null
          ? DateTime.tryParse(json['tanggal_lahir'] as String)
          : null,
      noHp: json['no_hp'] as String?,
      jenisKelamin: json['jenis_kelamin'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama_lengkap': namaLengkap,
      'email': email,
      'tanggal_lahir': tanggalLahir != null
          ? '${tanggalLahir!.year.toString().padLeft(4, '0')}-${tanggalLahir!.month.toString().padLeft(2, '0')}-${tanggalLahir!.day.toString().padLeft(2, '0')}'
          : null,
      'no_hp': noHp,
      'jenis_kelamin': jenisKelamin,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  ProfileModel copyWith({
    String? id,
    String? namaLengkap,
    String? email,
    DateTime? tanggalLahir,
    String? noHp,
    String? jenisKelamin,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      namaLengkap: namaLengkap ?? this.namaLengkap,
      email: email ?? this.email,
      tanggalLahir: tanggalLahir ?? this.tanggalLahir,
      noHp: noHp ?? this.noHp,
      jenisKelamin: jenisKelamin ?? this.jenisKelamin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
