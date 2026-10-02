import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../local/repositories/intervention_history_local_repository.dart';
import '../models/intervention_model.dart';
import '../models/recommendation_model.dart';
import '../providers/intervention_native_provider.dart';
import 'intervention/focus_mode_executor.dart';
import '../../core/utils/uuid_generator.dart';

/// Service inti pengelola eksekusi intervensi di MIND DRIJI.
///
/// Fitur Utama:
/// 1. Berbasis Timestamp Mutlak: Perhitungan sisa waktu tidak bergantung pada
///    jumlah tick timer, sehingga tetap presisi saat aplikasi masuk background,
///    layar dimatikan, atau aktivitas di-recreate.
/// 2. Lifecycle-Aware: Mengamati perubahan status siklus hidup aplikasi (resumed, paused, dll).
/// 3. User-Initiated: Hanya berjalan jika diinisiasi oleh pengguna secara sadar.
/// 4. Non-Medical & Non-Addiction: Bebas klaim medis/kecanduan.
/// 5. Persistent History: Setiap siklus hidup intervensi dicatat ke Drift SQLite secara offline-first.
class InterventionService extends GetxService with WidgetsBindingObserver {
  final InterventionNativeProvider _nativeProvider;
  final InterventionHistoryLocalRepository? _historyRepo;
  final FocusModeExecutor _focusModeExecutor;

  InterventionService({
    InterventionNativeProvider? nativeProvider,
    InterventionHistoryLocalRepository? historyRepository,
    FocusModeExecutor? focusModeExecutor,
  })  : _nativeProvider = nativeProvider ?? InterventionNativeProvider(),
        _historyRepo = historyRepository,
        _focusModeExecutor = focusModeExecutor ??
            AccessibilityFocusModeExecutor(
              nativeProvider: nativeProvider ?? InterventionNativeProvider(),
            );

  FocusModeExecutor get focusModeExecutor => _focusModeExecutor;

  InterventionHistoryLocalRepository get historyRepository {
    if (_historyRepo != null) return _historyRepo;
    if (Get.isRegistered<InterventionHistoryLocalRepository>()) {
      return Get.find<InterventionHistoryLocalRepository>();
    }
    return InterventionHistoryLocalRepository();
  }

  // Reactive State
  final activeIntervention = Rxn<InterventionModel>();
  final remainingSeconds = 0.obs;
  final isActive = false.obs;

  // State khusus alur panduan relaksasi mata (Eye Relaxation)
  final eyeRelaxationStep = 0.obs;

  Timer? _tickerTimer;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _restoreActiveIntervention();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _tickerTimer?.cancel();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    handleLifecycle(state);
  }

  /// Menangani perubahan siklus hidup aplikasi.
  ///
  /// PENTING:
  /// Tidak me-reset intervensi yang sedang berjalan saat status menjadi
  /// paused atau inactive. Saat resumed, hitung ulang sisa waktu seketika.
  void handleLifecycle(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        handleAppResume();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // Biarkan state tetap aktif berdasarkan timestamp
        break;
    }
  }

  /// Sinkronisasi sisa waktu saat aplikasi kembali ke foreground.
  void handleAppResume() {
    final current = activeIntervention.value;
    if (current != null && current.status == InterventionStatus.active) {
      _updateRemainingTime();
      if (_tickerTimer == null || !_tickerTimer!.isActive) {
        _startTicker();
      }
    }
  }

  /// Memulai Digital Break dengan durasi tertentu (dalam menit).
  Future<void> startDigitalBreak(
    int durationMinutes, {
    RecommendationModel? source,
  }) async {
    final now = DateTime.now();
    final ended = now.add(Duration(minutes: durationMinutes));
    final id = 'break_${UuidGenerator.v4()}';

    final model = InterventionModel(
      id: id,
      type: InterventionType.digitalBreak,
      title: 'Jeda Digital',
      durationMinutes: durationMinutes,
      startedAt: now,
      endedAt: ended,
      status: InterventionStatus.active,
      sourceRecommendation: source,
      createdAt: now,
    );

    await startIntervention(model);

    // Kirim ke platform native untuk notifikasi & persistensi SharedPreferences
    await _nativeProvider.startDigitalBreak(
      id: id,
      durationMinutes: durationMinutes,
      endTimestampMillis: ended.millisecondsSinceEpoch,
    );
  }

  /// Memulai panduan Eye Relaxation (Relaksasi Mata).
  Future<void> startEyeRelaxation({
    int durationSeconds = 60,
    RecommendationModel? source,
  }) async {
    final now = DateTime.now();
    final ended = now.add(Duration(seconds: durationSeconds));
    final id = 'eye_relax_${UuidGenerator.v4()}';

    eyeRelaxationStep.value = 0;

    final model = InterventionModel(
      id: id,
      type: InterventionType.eyeRelaxation,
      title: 'Relaksasi Mata',
      durationMinutes: (durationSeconds / 60).ceil(),
      startedAt: now,
      endedAt: ended,
      status: InterventionStatus.active,
      sourceRecommendation: source,
      createdAt: now,
    );

    await startIntervention(model);
  }

  /// Memulai Focus Mode dengan durasi tertentu (dalam menit).
  ///
  /// Menjalankan soft-blocking berbasis Accessibility Service pada aplikasi target.
  Future<bool> startFocusMode(
    int durationMinutes, {
    RecommendationModel? source,
  }) async {
    if (durationMinutes <= 0) {
      throw ArgumentError('Durasi Focus Mode harus lebih besar dari 0 menit');
    }

    // Jika ada intervensi aktif yang sedang berjalan, batalkan terlebih dahulu
    if (activeIntervention.value != null &&
        activeIntervention.value!.status == InterventionStatus.active) {
      await cancelIntervention();
    }

    final now = DateTime.now();
    final ended = now.add(Duration(minutes: durationMinutes));
    final id = 'focus_${UuidGenerator.v4()}';

    final model = InterventionModel(
      id: id,
      type: InterventionType.focusMode,
      title: 'Mode Fokus',
      durationMinutes: durationMinutes,
      startedAt: now,
      endedAt: ended,
      status: InterventionStatus.active,
      sourceRecommendation: source,
      createdAt: now,
    );

    // 1. Simpan riwayat intervensi sebagai status ACTIVE
    try {
      await historyRepository.insert(model);
    } catch (_) {}

    // 2. Jalankan Focus Mode pada platform native via executor
    final nativeStarted = await _focusModeExecutor.start(
      id: id,
      duration: Duration(minutes: durationMinutes),
    );

    if (!nativeStarted) {
      // Rollback riwayat jika platform native gagal memulai
      try {
        await historyRepository.update(model.copyWith(
          status: InterventionStatus.cancelled,
          cancelledAt: DateTime.now(),
          endedAt: DateTime.now(),
        ));
      } catch (_) {}
      return false;
    }

    activeIntervention.value = model;
    isActive.value = true;
    _updateRemainingTime();
    _startTicker();

    return true;
  }

  /// Memulai sesi Pomodoro: 25 menit fokus dengan native soft blocking
  /// yang berbasis timestamp mutlak dan tahan backgrounding.
  Future<bool> startPomodoro({
    int focusMinutes = 25,
    RecommendationModel? source,
  }) async {
    final now = DateTime.now();
    final ended = now.add(Duration(minutes: focusMinutes));
    final id = 'pomodoro_${UuidGenerator.v4()}';

    final model = InterventionModel(
      id: id,
      type: InterventionType.pomodoro,
      title: 'Pomodoro (Fokus)',
      durationMinutes: focusMinutes,
      startedAt: now,
      endedAt: ended,
      status: InterventionStatus.active,
      sourceRecommendation: source,
      createdAt: now,
    );

    if (activeIntervention.value != null &&
        activeIntervention.value!.status == InterventionStatus.active) {
      await cancelIntervention();
    }

    try {
      await historyRepository.insert(model);
    } catch (_) {}

    final nativeStarted = await _focusModeExecutor.start(
      id: id,
      duration: Duration(minutes: focusMinutes),
    );

    if (!nativeStarted) {
      try {
        await historyRepository.update(model.copyWith(
          status: InterventionStatus.cancelled,
          cancelledAt: DateTime.now(),
          endedAt: DateTime.now(),
        ));
      } catch (_) {}
      return false;
    }

    activeIntervention.value = model;
    isActive.value = true;
    _updateRemainingTime();
    _startTicker();

    return true;
  }

  /// Memulai Custom Intervention dengan durasi tertentu yang ditentukan pengguna
  Future<bool> startCustomIntervention({
    required int durationMinutes,
    required bool isFocusMode,
    RecommendationModel? source,
  }) async {
    if (durationMinutes <= 0) {
      throw ArgumentError('Durasi intervensi harus lebih besar dari 0 menit');
    }

    if (isFocusMode) {
      return await startFocusMode(durationMinutes, source: source);
    } else {
      await startDigitalBreak(durationMinutes, source: source);
      return true;
    }
  }

  /// Menjalankan model intervensi secara terpadu dan mencatatnya ke database.
  Future<void> startIntervention(InterventionModel model) async {
    // Pencegahan multiple intervention yang bertumpuk: selesaikan atau batalkan sebelumnya
    if (activeIntervention.value != null &&
        activeIntervention.value!.status == InterventionStatus.active) {
      await cancelIntervention();
    }

    activeIntervention.value = model;
    isActive.value = true;
    _updateRemainingTime();
    _startTicker();

    try {
      await historyRepository.insert(model);
    } catch (_) {}
  }

  /// Membatalkan intervensi yang sedang aktif atas inisiatif pengguna.
  Future<void> cancelIntervention() async {
    final current = activeIntervention.value;
    if (current == null) return;

    _tickerTimer?.cancel();
    _tickerTimer = null;

    final now = DateTime.now();
    final updated = current.copyWith(
      status: InterventionStatus.cancelled,
      cancelledAt: now,
      endedAt: now,
      updatedAt: now,
    );

    activeIntervention.value = updated;
    isActive.value = false;
    remainingSeconds.value = 0;

    try {
      await historyRepository.update(updated);
    } catch (_) {}

    if (current.type == InterventionType.digitalBreak) {
      await _nativeProvider.stopDigitalBreak();
    } else if (current.type == InterventionType.focusMode ||
        current.type == InterventionType.pomodoro ||
        current.type == InterventionType.custom) {
      await _focusModeExecutor.stop();
      await _nativeProvider.stopDigitalBreak();
    }
  }

  /// Menyelesaikan intervensi setelah waktu berakhir secara wajar.
  Future<void> completeIntervention() async {
    final current = activeIntervention.value;
    if (current == null) return;

    _tickerTimer?.cancel();
    _tickerTimer = null;

    final now = DateTime.now();
    final updated = current.copyWith(
      status: InterventionStatus.completed,
      endedAt: now,
      updatedAt: now,
    );

    activeIntervention.value = updated;
    isActive.value = false;
    remainingSeconds.value = 0;

    try {
      await historyRepository.update(updated);
    } catch (_) {}

    if (current.type == InterventionType.digitalBreak) {
      await _nativeProvider.stopDigitalBreak();
    } else if (current.type == InterventionType.focusMode ||
        current.type == InterventionType.pomodoro ||
        current.type == InterventionType.custom) {
      await _focusModeExecutor.stop();
      await _nativeProvider.stopDigitalBreak();
    }
  }

  InterventionModel? getActiveIntervention() {
    if (isActive.value && activeIntervention.value?.status == InterventionStatus.active) {
      return activeIntervention.value;
    }
    return null;
  }

  int getRemainingSeconds() => remainingSeconds.value;

  /// Memperbarui step pada alur Eye Relaxation
  void setEyeRelaxationStep(int step) {
    eyeRelaxationStep.value = step;
  }

  void nextEyeRelaxationStep() {
    eyeRelaxationStep.value++;
  }

  void _startTicker() {
    _tickerTimer?.cancel();
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateRemainingTime();
    });
  }

  void _updateRemainingTime() {
    final current = activeIntervention.value;
    if (current == null || current.status != InterventionStatus.active) {
      remainingSeconds.value = 0;
      isActive.value = false;
      _tickerTimer?.cancel();
      return;
    }

    final diff = current.endedAt.difference(DateTime.now()).inSeconds;
    if (diff <= 0) {
      remainingSeconds.value = 0;
      completeIntervention();
    } else {
      remainingSeconds.value = diff;
    }
  }

  /// Memulihkan status intervensi yang tersimpan di native layer atau database saat cold-start.
  Future<void> restoreActiveIntervention() => _restoreActiveIntervention();

  Future<void> _restoreActiveIntervention() async {
    final data = await _nativeProvider.getInterventionStatus();
    if (data != null && data.isNotEmpty) {
      try {
        final model = InterventionModel.fromMap(data);
        if (model.status == InterventionStatus.active) {
          if (DateTime.now().isBefore(model.endedAt)) {
            // Cegah menghidupkan kembali sesi yang sudah diselesaikan atau dibatalkan
            if (activeIntervention.value != null &&
                activeIntervention.value!.id == model.id &&
                activeIntervention.value!.status != InterventionStatus.active) {
              return;
            }

            // Cegah duplikasi: gunakan record yang sudah ada di database jika tersedia
            InterventionModel effectiveModel = model;
            try {
              final existing = await historyRepository.getById(model.id);
              if (existing != null) {
                effectiveModel = existing;
              } else {
                await historyRepository.insert(model);
              }
            } catch (_) {}

            activeIntervention.value = effectiveModel;
            isActive.value = true;
            _updateRemainingTime();
            _startTicker();
            return;
          } else {
            // Durasi sudah lewat saat app tertutup, selesaikan di database & bersihkan native
            try {
              final existing = await historyRepository.getById(model.id);
              if (existing != null) {
                await historyRepository.update(model.copyWith(
                  status: InterventionStatus.completed,
                  endedAt: model.endedAt,
                ));
              } else {
                await historyRepository.insert(model.copyWith(
                  status: InterventionStatus.completed,
                  endedAt: model.endedAt,
                ));
              }
            } catch (_) {}
            if (model.type == InterventionType.digitalBreak) {
              await _nativeProvider.stopDigitalBreak();
            } else if (model.type == InterventionType.focusMode ||
                model.type == InterventionType.pomodoro ||
                model.type == InterventionType.custom) {
              await _focusModeExecutor.stop();
              await _nativeProvider.stopDigitalBreak();
            }
          }
        }
      } catch (_) {}
    }

    // Fallback: pulihkan dari database lokal jika native status kosong
    try {
      final activeList =
          await historyRepository.getByStatus(InterventionStatus.active);
      if (activeList.isNotEmpty) {
        final dbModel = activeList.first;

        // Cegah menghidupkan kembali sesi yang sudah diselesaikan atau dibatalkan
        if (activeIntervention.value != null &&
            activeIntervention.value!.id == dbModel.id &&
            activeIntervention.value!.status != InterventionStatus.active) {
          return;
        }

        if (DateTime.now().isBefore(dbModel.endedAt)) {
          activeIntervention.value = dbModel;
          isActive.value = true;
          _updateRemainingTime();
          _startTicker();
        } else {
          await historyRepository.update(dbModel.copyWith(
            status: InterventionStatus.completed,
            endedAt: DateTime.now(),
          ));
          if (dbModel.type == InterventionType.digitalBreak) {
            await _nativeProvider.stopDigitalBreak();
          } else if (dbModel.type == InterventionType.focusMode ||
              dbModel.type == InterventionType.pomodoro ||
              dbModel.type == InterventionType.custom) {
            await _focusModeExecutor.stop();
            await _nativeProvider.stopDigitalBreak();
          }
        }
      }
    } catch (_) {}
  }
}
