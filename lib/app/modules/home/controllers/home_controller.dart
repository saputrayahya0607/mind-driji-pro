import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/local/repositories/intervention_history_local_repository.dart';
import '../../../data/models/detection_result.dart';
import '../../../data/models/intervention_model.dart';
import '../../../data/models/monitoring_visualization_model.dart';
import '../../../data/models/profile_model.dart';
import '../../../data/repositories/doomscroll_repository.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../data/repositories/usage_stats_repository.dart';
import '../../../data/services/detection_service.dart';
import '../../../data/services/eye_monitoring_service.dart';
import '../../../data/services/intervention_service.dart';
import '../../../data/services/monitoring_data_service.dart';
import '../../../data/sync/sync_manager.dart';

class HomeController extends GetxController with WidgetsBindingObserver {
  final ProfileRepository? _profileRepository;
  final UsageStatsRepository? _usageStatsRepository;
  final SupabaseClient? _supabaseClient;
  final EyeMonitoringService? _eyeMonitoringService;
  final DetectionService? _detectionService;
  final InterventionService? _interventionService;
  final InterventionHistoryLocalRepository? _historyRepository;
  final MonitoringDataService? _monitoringDataService;
  final DoomscrollRepository? _doomscrollRepository;

  HomeController({
    ProfileRepository? profileRepository,
    UsageStatsRepository? usageStatsRepository,
    SupabaseClient? supabaseClient,
    EyeMonitoringService? eyeMonitoringService,
    DetectionService? detectionService,
    InterventionService? interventionService,
    InterventionHistoryLocalRepository? historyRepository,
    MonitoringDataService? monitoringDataService,
    DoomscrollRepository? doomscrollRepository,
  })  : _profileRepository = profileRepository,
        _usageStatsRepository = usageStatsRepository,
        _supabaseClient = supabaseClient,
        _eyeMonitoringService = eyeMonitoringService,
        _detectionService = detectionService,
        _interventionService = interventionService,
        _historyRepository = historyRepository,
        _monitoringDataService = monitoringDataService,
        _doomscrollRepository = doomscrollRepository;

  MonitoringDataService get _dataService {
    if (_monitoringDataService != null) return _monitoringDataService;
    if (Get.isRegistered<MonitoringDataService>()) {
      return Get.find<MonitoringDataService>();
    }
    return MonitoringDataService();
  }

  DoomscrollRepository? get _doomscrollRepo {
    if (_doomscrollRepository != null) return _doomscrollRepository;
    if (Get.isRegistered<DoomscrollRepository>()) {
      return Get.find<DoomscrollRepository>();
    }
    return null;
  }

  ProfileRepository get _repository {
    if (_profileRepository != null) return _profileRepository;
    if (Get.isRegistered<ProfileRepository>()) {
      return Get.find<ProfileRepository>();
    }
    return ProfileRepository();
  }

  UsageStatsRepository get _usageRepo {
    if (_usageStatsRepository != null) return _usageStatsRepository;
    if (Get.isRegistered<UsageStatsRepository>()) {
      return Get.find<UsageStatsRepository>();
    }
    return UsageStatsRepository();
  }

  EyeMonitoringService get eyeMonitoringService {
    if (_eyeMonitoringService != null) return _eyeMonitoringService;
    if (Get.isRegistered<EyeMonitoringService>()) {
      return Get.find<EyeMonitoringService>();
    }
    return EyeMonitoringService.to;
  }

  InterventionService? get interventionService {
    if (_interventionService != null) return _interventionService;
    if (Get.isRegistered<InterventionService>()) {
      return Get.find<InterventionService>();
    }
    return null;
  }

  InterventionHistoryLocalRepository get historyRepository {
    if (_historyRepository != null) return _historyRepository;
    if (Get.isRegistered<InterventionHistoryLocalRepository>()) {
      return Get.find<InterventionHistoryLocalRepository>();
    }
    return InterventionHistoryLocalRepository();
  }

  bool get isInterventionActive => interventionService?.isActive.value ?? false;
  String get activeInterventionTitle =>
      interventionService?.activeIntervention.value?.title ?? 'Jeda Digital';
  String get activeInterventionRemaining {
    final s = interventionService?.remainingSeconds.value ?? 0;
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  // ===========================================================================
  // EYE MONITORING PRESENTER (Single Source of Truth: EyeMonitoringService)
  // ===========================================================================
  RxBool get isEyeMonitoringEnabled => eyeMonitoringService.isMonitoringEnabled;
  RxBool get isEyeSessionRunning => eyeMonitoringService.isSessionRunning;

  String get eyeMonitoringBadgeText {
    if (!eyeMonitoringService.isMonitoringEnabled.value) {
      return 'Monitoring belum aktif';
    }
    if (eyeMonitoringService.isSessionRunning.value) {
      return 'Kamera Aktif';
    }
    return 'Aktif';
  }

  Color get eyeMonitoringBadgeColor {
    if (!eyeMonitoringService.isMonitoringEnabled.value) {
      return AppColors.secondary.withValues(alpha: 0.08);
    }
    if (eyeMonitoringService.isSessionRunning.value) {
      return const Color(0xFFFEF3C7);
    }
    return const Color(0xFFDCFCE7);
  }

  Color get eyeMonitoringBadgeTextColor {
    if (!eyeMonitoringService.isMonitoringEnabled.value) {
      return AppColors.textSecondary;
    }
    if (eyeMonitoringService.isSessionRunning.value) {
      return const Color(0xFFB45309);
    }
    return const Color(0xFF15803D);
  }

  String get eyeMonitoringTitle {
    if (!eyeMonitoringService.isMonitoringEnabled.value) {
      return 'Belum ada data';
    }
    if (eyeMonitoringService.isSessionRunning.value) {
      return 'Sedang memantau';
    }
    return 'Monitoring aktif';
  }

  String get eyeMonitoringDescription {
    if (!eyeMonitoringService.isMonitoringEnabled.value) {
      return 'Aktifkan monitoring untuk memulai pemantauan mata.';
    }
    if (eyeMonitoringService.isSessionRunning.value) {
      return 'Kamera sedang digunakan untuk pemantauan mata.';
    }
    return 'Pemantauan mata berjalan otomatis.';
  }

  final isLoading = false.obs;
  final profile = Rxn<ProfileModel>();
  final errorMessage = RxnString();

  // State monitoring screen time real di Home
  final hasUsageAccess = false.obs;
  final todayScreenTimeMillis = 0.obs;

  // State ringkasan doomscrolling real hari ini
  final hasAccessibilityPermission = false.obs;
  final doomscrollSummary = const DoomscrollSummary().obs;

  bool get hasDoomscrollData => doomscrollSummary.value.hasData;
  int get doomscrollSessionCount => doomscrollSummary.value.totalSessions;
  int get doomscrollSwipes => doomscrollSummary.value.totalSwipes;
  String get doomscrollDurationFormatted =>
      doomscrollSummary.value.durationFormatted;

  /// Monitoring status: Berdasarkan izin AccessibilityService
  bool get isDoomscrollMonitoringActive => hasAccessibilityPermission.value;

  String get doomscrollMonitoringStatusText =>
      hasAccessibilityPermission.value ? 'Aktif' : 'Monitoring tidak aktif';

  String get doomscrollDataStatusText {
    if (!hasAccessibilityPermission.value) {
      return 'Monitoring tidak aktif';
    }
    if (doomscrollSessionCount == 0) {
      return 'Belum ada sesi scrolling hari ini';
    }
    return '$doomscrollSessionCount sesi • $doomscrollDurationFormatted • $doomscrollSwipes swipe';
  }

  // State hasil deteksi pola perilaku scrolling
  final todayDetection = Rxn<DetectionResult>();

  // State riwayat intervensi terakhir
  final latestIntervention = Rxn<InterventionModel>();

  String get latestInterventionSummary {
    final item = latestIntervention.value;
    if (item == null) return '';
    final statusStr = item.status == InterventionStatus.completed ? 'Selesai' : 'Dibatalkan';
    return '${item.title} · ${item.durationMinutes} menit · $statusStr';
  }

  String get detectionTitle {
    final d = todayDetection.value;
    if (d == null) return 'Menunggu Data Penggunaan';
    return d.title;
  }

  String get detectionDescription {
    final d = todayDetection.value;
    if (d == null) {
      return 'Insight akan tersedia setelah data penggunaan terkumpul.';
    }
    return d.description;
  }

  /// Ringkasan rekomendasi ramah untuk ditampilkan di Home
  String get recommendationSnippet {
    final d = todayDetection.value;
    if (d == null || !d.detected) {
      return '';
    }
    final intervention = d.suggestedIntervention ?? 'Jeda Digital';
    return '$intervention mungkin cocok untukmu';
  }

  /// Mengambil nama depan pengguna dari profil Supabase
  String get greetingName {
    final p = profile.value;
    if (p != null && p.namaLengkap != null && p.namaLengkap!.trim().isNotEmpty) {
      final name = p.namaLengkap!.trim().split(RegExp(r'\s+')).first;
      if (name.isNotEmpty) {
        return name[0].toUpperCase() + name.substring(1);
      }
    }
    return '';
  }

  /// Menghasilkan teks sapaan personal atau fallback
  String get greetingText {
    final name = greetingName;
    if (name.isNotEmpty) {
      return 'Halo, $name 👋';
    }
    return 'Halo 👋';
  }

  @override
  void onInit() {
    super.onInit();
    try {
      WidgetsBinding.instance.addObserver(this);
    } catch (_) {}
    loadHomeData();
  }

  @override
  void onClose() {
    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (_) {}
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      loadScreenTimeSummary();
      loadDoomscrollSummary();
      loadDetectionSummary();
      loadLatestIntervention();
    }
  }

  /// Memuat profil pengguna, data ringkasan screen time, dan deteksi pola
  Future<void> loadHomeData() async {
    await Future.wait([
      loadUserProfile(),
      loadScreenTimeSummary(),
      loadDoomscrollSummary(),
      loadDetectionSummary(),
      loadLatestIntervention(),
    ]);
  }

  /// Memuat ringkasan doomscrolling real hari ini via MonitoringDataService
  Future<void> loadDoomscrollSummary() async {
    try {
      final repo = _doomscrollRepo;
      if (repo != null) {
        try {
          hasAccessibilityPermission.value =
              await repo.checkAccessibilityService();
        } catch (_) {
          hasAccessibilityPermission.value = false;
        }
        try {
          await repo.collectAndPersistPendingSessions();
          if (Get.isRegistered<SyncManager>()) {
            final syncMgr = Get.find<SyncManager>();
            if (syncMgr.isOnline.value) {
              syncMgr.syncPendingData();
            }
          }
        } catch (_) {}
      }
      if (_monitoringDataService != null ||
          Get.isRegistered<MonitoringDataService>()) {
        final summary = await _dataService.getDoomscrollSummary(
          period: MonitoringPeriod.daily,
          date: DateTime.now(),
        );
        doomscrollSummary.value = summary;
      }
    } catch (_) {
      doomscrollSummary.value = const DoomscrollSummary();
    }
  }

  /// Memuat intervensi terakhir yang pernah dijalankan pengguna
  Future<void> loadLatestIntervention() async {
    try {
      final list = await historyRepository.getRecent(limit: 1);
      latestIntervention.value = list.isNotEmpty ? list.first : null;
    } catch (_) {
      latestIntervention.value = null;
    }
  }

  /// Memuat hasil deteksi pola scrolling hari ini dari DetectionService
  Future<void> loadDetectionSummary() async {
    try {
      final service = _detectionService ??
          (Get.isRegistered<DetectionService>()
              ? Get.find<DetectionService>()
              : null);
      if (service != null) {
        todayDetection.value = await service.detectToday();
      }
    } catch (_) {}
  }

  /// Mengambil profil user yang sedang login dari Supabase via ProfileRepository
  Future<void> loadUserProfile() async {
    try {
      isLoading.value = true;
      errorMessage.value = null;

      String? userId;
      try {
        final client = _supabaseClient ?? Supabase.instance.client;
        userId = client.auth.currentUser?.id;
      } catch (_) {
        userId = null;
      }

      if (userId == null) {
        errorMessage.value = 'Data pengguna belum dapat dimuat.';
        profile.value = null;
        return;
      }

      final data = await _repository.getMyProfile();
      profile.value = data;
    } catch (_) {
      errorMessage.value = 'Data pengguna belum dapat dimuat.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadScreenTimeSummary() async {
    try {
      final hasAccess = await _usageRepo.checkUsageAccess();
      hasUsageAccess.value = hasAccess;

      if (hasAccess) {
        try {
          final usage = await _usageRepo.getTodayUsage();
          todayScreenTimeMillis.value = usage.totalUsageMillis;
        } catch (_) {
          // Tetap pertahankan hasUsageAccess = true jika izin sudah diberikan
          todayScreenTimeMillis.value = 0;
        }
      } else {
        todayScreenTimeMillis.value = 0;
      }
    } catch (_) {
      hasUsageAccess.value = false;
      todayScreenTimeMillis.value = 0;
    }
  }
}
