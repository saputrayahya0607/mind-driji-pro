import 'package:get/get.dart';
import '../../../core/utils/uuid_generator.dart';
import '../../../data/models/intervention_model.dart';
import '../../../data/services/intervention_service.dart';

/// Controller untuk mengelola interaksi pengguna pada layar intervensi.
class InterventionController extends GetxController {
  final InterventionService service;

  InterventionController({InterventionService? interventionService})
      : service = interventionService ?? Get.find<InterventionService>();

  InterventionModel? get activeIntervention => service.activeIntervention.value;
  int get remainingSeconds => service.remainingSeconds.value;
  bool get isActive => service.isActive.value;
  int get eyeStep => service.eyeRelaxationStep.value;

  /// Format sisa waktu menjadi `mm:ss` (contoh: 14:32)
  String get formattedRemainingTime {
    final secs = remainingSeconds;
    if (secs <= 0) return '00:00';
    final minutes = secs ~/ 60;
    final remainingSecs = secs % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSecs.toString().padLeft(2, '0')}';
  }

  /// Judul intervensi aktif
  String get title {
    return activeIntervention?.title ?? 'Intervensi Aktif';
  }

  /// Progres intervensi (0.0 sampai 1.0)
  double get progress {
    return activeIntervention?.progress ?? 0.0;
  }

  // State Form Kustom
  final selectedCustomMinutes = 20.obs;
  final isCustomFocus = true.obs;
  final isStarting = false.obs;

  /// Memulai Jeda Digital dengan durasi tertentu
  Future<void> startDigitalBreak(int minutes) async {
    try {
      isStarting.value = true;
      await service.startDigitalBreak(minutes);
    } finally {
      isStarting.value = false;
    }
  }

  /// Memulai Mode Fokus dengan durasi tertentu
  Future<bool> startFocusMode(int minutes) async {
    try {
      isStarting.value = true;
      return await service.startFocusMode(minutes);
    } finally {
      isStarting.value = false;
    }
  }

  /// Memulai sesi Pomodoro (25 menit fokus)
  Future<bool> startPomodoro() async {
    try {
      isStarting.value = true;
      return await service.startPomodoro(focusMinutes: 25);
    } finally {
      isStarting.value = false;
    }
  }

  /// Memulai intervensi kustom dengan validasi durasi (1-180 menit)
  Future<bool> startCustom({int? minutes, bool? isFocus}) async {
    final mins = minutes ?? selectedCustomMinutes.value;
    final focus = isFocus ?? isCustomFocus.value;

    if (mins <= 0 || mins > 180) {
      Get.snackbar(
        'Durasi Tidak Valid',
        'Durasi harus antara 1 sampai 180 menit.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    try {
      isStarting.value = true;
      return await service.startCustomIntervention(
        durationMinutes: mins,
        isFocusMode: focus,
      );
    } finally {
      isStarting.value = false;
    }
  }

  /// Batalkan intervensi atas permintaan pengguna
  Future<void> cancel() async {
    await service.cancelIntervention();
  }

  /// Selesaikan intervensi
  Future<void> complete() async {
    if (service.activeIntervention.value != null && service.isActive.value) {
      await service.completeIntervention();
    } else {
      // Catat sesi relaksasi manual jika dijalankan mandiri tanpa timer aktif
      try {
        final now = DateTime.now();
        final model = InterventionModel(
          id: 'eye_relax_${UuidGenerator.v4()}',
          type: InterventionType.eyeRelaxation,
          title: 'Relaksasi Mata',
          durationMinutes: 1,
          startedAt: now.subtract(const Duration(minutes: 1)),
          endedAt: now,
          status: InterventionStatus.completed,
          createdAt: now,
        );
        await service.historyRepository.insert(model);
      } catch (_) {}
    }
  }

  /// Melangkah ke tahap panduan relaksasi mata berikutnya atau menyelesaikan sesi
  void nextEyeStep() {
    if (eyeStep < eyeRelaxationSteps.length - 1) {
      service.nextEyeRelaxationStep();
    } else {
      complete();
      service.setEyeRelaxationStep(0);
      _closeRelaxationScreen();
    }
  }

  void _closeRelaxationScreen() {
    try {
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      Get.back();
    } catch (_) {}
  }

  void setEyeStep(int step) {
    if (step >= 0 && step < eyeRelaxationSteps.length) {
      service.setEyeRelaxationStep(step);
    }
  }

  /// Daftar tahapan panduan relaksasi mata yang santai, edukatif, dan bebas klaim medis.
  static const List<Map<String, String>> eyeRelaxationSteps = [
    {
      'title': 'Alihkan pandangan dari layar',
      'description':
          'Arahkan pandanganmu ke luar jendela atau ke sudut ruangan terjauh.',
      'icon': 'look_away',
    },
    {
      'title': 'Fokus pada objek jauh',
      'description':
          'Amati detail objek berjarak minimal 6 meter untuk meregangkan fokus otot mata.',
      'icon': 'far_object',
    },
    {
      'title': 'Kedip perlahan',
      'description':
          'Tutup dan buka mata secara lembut beberapa kali agar permukaan mata tetap lembap.',
      'icon': 'blink',
    },
    {
      'title': 'Tarik napas rileks',
      'description':
          'Tarik napas dalam, hembuskan perlahan, dan lepaskan ketegangan pada bahu serta leher.',
      'icon': 'breathe',
    },
    {
      'title': 'Selesai',
      'description':
          'Istirahat mata telah tuntas. Lanjutkan aktivitasmu dengan nyaman dan berkesadaran.',
      'icon': 'check_circle',
    },
  ];
}
