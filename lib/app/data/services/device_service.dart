import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Value;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/uuid_generator.dart';
import '../local/app_database.dart';
import '../models/device_info_model.dart';

/// Service pusat (Single Source of Truth) untuk identitas perangkat (Device ID)
/// dan registrasi perangkat ke Supabase.
///
/// PRINSIP:
/// - user_id: identitas pemilik data (security boundary & RLS).
/// - device_id: identitas instalasi/perangkat fisik (UUID v4 persisten lokal).
/// - Device ID tetap sama setelah app restart, logout, atau ganti akun di HP yang sama.
class DeviceService extends GetxService {
  static const MethodChannel _deviceChannel =
      MethodChannel('com.hn.minddriji/device_info');

  final AppDatabase? _db;
  final SupabaseClient? _supabase;
  final MethodChannel _channel;

  String? _cachedDeviceId;
  DeviceInfoModel? _cachedDeviceInfo;

  DeviceService({
    AppDatabase? db,
    SupabaseClient? supabase,
    MethodChannel? channel,
  })  : _db = db ?? _safeGetDatabase(),
        _supabase = supabase ?? _safeGetSupabaseClient(),
        _channel = channel ?? _deviceChannel;

  static DeviceService get to {
    if (Get.isRegistered<DeviceService>()) {
      return Get.find<DeviceService>();
    }
    final service = DeviceService();
    Get.put<DeviceService>(service, permanent: true);
    return service;
  }

  static AppDatabase? _safeGetDatabase() {
    try {
      if (Get.isRegistered<AppDatabase>()) {
        return Get.find<AppDatabase>();
      }
    } catch (_) {}
    return null;
  }

  static SupabaseClient? _safeGetSupabaseClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  String get deviceId => _cachedDeviceId ?? 'legacy';
  DeviceInfoModel? get deviceInfo => _cachedDeviceInfo;

  /// Inisialisasi awal saat aplikasi mulai berjalan
  Future<DeviceService> init() async {
    await getDeviceId();
    return this;
  }

  /// Mendapatkan Device ID persisten dari SQLite lokal.
  /// Jika belum ada, buat UUID v4 baru dan simpan secara persisten.
  Future<String> getDeviceId() async {
    if (_cachedDeviceId != null) {
      return _cachedDeviceId!;
    }

    final db = _db;
    if (db == null) {
      final fallbackId = UuidGenerator.v4();
      _cachedDeviceId = fallbackId;
      _cachedDeviceInfo = DeviceInfoModel(
        deviceId: fallbackId,
        deviceName: 'Android Device',
        manufacturer: 'Android',
        model: 'Model',
        androidVersion: 'Unknown',
        appVersion: '1.0.0',
        firstSeenAt: DateTime.now(),
        lastSeenAt: DateTime.now(),
      );
      return fallbackId;
    }

    try {
      final existing = await (db.select(db.localDeviceInfo)
            ..where((t) => t.id.equals('current_device')))
          .getSingleOrNull();

      if (existing != null) {
        _cachedDeviceId = existing.deviceId;
        _cachedDeviceInfo = DeviceInfoModel(
          deviceId: existing.deviceId,
          deviceName: existing.deviceName ?? 'Android Device',
          manufacturer: existing.manufacturer ?? 'Android',
          model: existing.model ?? 'Model',
          androidVersion: existing.androidVersion ?? 'Unknown',
          appVersion: existing.appVersion ?? '1.0.0',
          firstSeenAt: existing.createdAt,
          lastSeenAt: existing.lastSeenAt,
        );
        return existing.deviceId;
      }

      // Generate UUID baru untuk instalasi ini
      final newDeviceId = UuidGenerator.v4();
      final now = DateTime.now();
      final info = await _fetchNativeDeviceInfo();

      await db.into(db.localDeviceInfo).insert(
            LocalDeviceInfoCompanion.insert(
              id: 'current_device',
              deviceId: newDeviceId,
              deviceName: Value(info['deviceName']),
              manufacturer: Value(info['manufacturer']),
              model: Value(info['model']),
              androidVersion: Value(info['androidVersion']),
              appVersion: Value(info['appVersion']),
              createdAt: now,
              lastSeenAt: now,
            ),
          );

      _cachedDeviceId = newDeviceId;
      _cachedDeviceInfo = DeviceInfoModel(
        deviceId: newDeviceId,
        deviceName: info['deviceName'] ?? 'Android Device',
        manufacturer: info['manufacturer'] ?? 'Android',
        model: info['model'] ?? 'Model',
        androidVersion: info['androidVersion'] ?? 'Unknown',
        appVersion: info['appVersion'] ?? '1.0.0',
        firstSeenAt: now,
        lastSeenAt: now,
      );

      return newDeviceId;
    } catch (_) {
      // Fallback aman jika database belum siap
      _cachedDeviceId ??= UuidGenerator.v4();
      return _cachedDeviceId!;
    }
  }

  /// Membaca metadata perangkat non-sensitif dari native Android
  Future<Map<String, String>> _fetchNativeDeviceInfo() async {
    try {
      final rawMap = await _channel.invokeMapMethod<dynamic, dynamic>('getDeviceInfo');
      if (rawMap != null) {
        return {
          'deviceName': rawMap['deviceName']?.toString() ?? 'Android Device',
          'manufacturer': rawMap['manufacturer']?.toString() ?? 'Android',
          'model': rawMap['model']?.toString() ?? 'Model',
          'androidVersion': rawMap['androidVersion']?.toString() ?? 'Unknown',
          'appVersion': rawMap['appVersion']?.toString() ?? '1.0.0',
        };
      }
    } catch (_) {
      // Abaikan error native (misal di test environment)
    }

    return {
      'deviceName': 'Android Device',
      'manufacturer': 'Android',
      'model': 'Model',
      'androidVersion': 'Unknown',
      'appVersion': '1.0.0',
    };
  }

  /// Mengambil informasi lengkap perangkat
  Future<DeviceInfoModel> getDeviceInfo() async {
    if (_cachedDeviceInfo != null) {
      return _cachedDeviceInfo!;
    }
    await getDeviceId();
    return _cachedDeviceInfo ??
        DeviceInfoModel(
          deviceId: deviceId,
          deviceName: 'Android Device',
          manufacturer: 'Android',
          model: 'Model',
          androidVersion: 'Unknown',
          appVersion: '1.0.0',
          firstSeenAt: DateTime.now(),
          lastSeenAt: DateTime.now(),
        );
  }

  /// Memastikan perangkat telah terdaftar di Supabase public.user_devices.
  /// Bersifat idempotent via UPSERT pada conflict (user_id, device_id).
  Future<bool> ensureDeviceRegistered(String userId) async {
    if (userId.isEmpty || userId == 'local_user') {
      return false;
    }

    final client = _supabase;
    if (client == null) return false;

    try {
      final currentDeviceId = await getDeviceId();
      final currentInfo = await getDeviceInfo();
      final nowUtc = DateTime.now().toUtc().toIso8601String();

      await client.from('user_devices').upsert({
        'user_id': userId,
        'device_id': currentDeviceId,
        'device_name': currentInfo.deviceName,
        'manufacturer': currentInfo.manufacturer,
        'model': currentInfo.model,
        'android_version': currentInfo.androidVersion,
        'app_version': currentInfo.appVersion,
        'last_seen_at': nowUtc,
        'updated_at': nowUtc,
      }, onConflict: 'user_id, device_id');

      // Update waktu lastSeenAt di SQLite lokal jika tersedia
      final db = _db;
      if (db != null) {
        await (db.update(db.localDeviceInfo)
              ..where((t) => t.id.equals('current_device')))
            .write(LocalDeviceInfoCompanion(
          lastSeenAt: Value(DateTime.now()),
        ));
      }

      return true;
    } catch (_) {
      // Jika offline, registrasi akan di-retry otomatis saat SyncManager berjalan
      return false;
    }
  }

  /// Memeriksa apakah aplikasi telah dikecualikan dari pembatasan optimasi baterai (Doze mode)
  Future<bool> checkBatteryOptimization() async {
    try {
      final isIgnoring =
          await _channel.invokeMethod<bool>('checkBatteryOptimization');
      return isIgnoring ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Meminta pengguna untuk mengecualikan aplikasi dari optimasi baterai (Ignore Battery Optimizations)
  Future<bool> requestIgnoreBatteryOptimization() async {
    try {
      final requested = await _channel
          .invokeMethod<bool>('requestIgnoreBatteryOptimization');
      return requested ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Membuka halaman pengaturan Auto-Start khusus OEM (Xiaomi, Samsung, Oppo, Vivo, Asus, dll)
  Future<bool> openOemAutoStartSettings() async {
    try {
      final opened =
          await _channel.invokeMethod<bool>('openOemAutoStartSettings');
      return opened ?? false;
    } catch (_) {
      return false;
    }
  }
}
