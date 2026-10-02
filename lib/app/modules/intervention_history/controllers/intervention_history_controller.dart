import 'package:get/get.dart';
import '../../../data/local/repositories/intervention_history_local_repository.dart';
import '../../../data/models/intervention_model.dart';

enum HistoryTypeFilter {
  all,
  digitalBreak,
  eyeRelaxation;

  String get label {
    switch (this) {
      case HistoryTypeFilter.all:
        return 'Semua';
      case HistoryTypeFilter.digitalBreak:
        return 'Jeda Digital';
      case HistoryTypeFilter.eyeRelaxation:
        return 'Istirahat Mata';
    }
  }

  InterventionType? get toInterventionType {
    switch (this) {
      case HistoryTypeFilter.digitalBreak:
        return InterventionType.digitalBreak;
      case HistoryTypeFilter.eyeRelaxation:
        return InterventionType.eyeRelaxation;
      case HistoryTypeFilter.all:
        return null;
    }
  }
}

enum HistoryDateFilter {
  all,
  today,
  week,
  month;

  String get label {
    switch (this) {
      case HistoryDateFilter.all:
        return 'Semua Waktu';
      case HistoryDateFilter.today:
        return 'Hari Ini';
      case HistoryDateFilter.week:
        return 'Minggu Ini';
      case HistoryDateFilter.month:
        return 'Bulan Ini';
    }
  }
}

class InterventionHistoryController extends GetxController {
  final InterventionHistoryLocalRepository repository;

  InterventionHistoryController({InterventionHistoryLocalRepository? repo})
      : repository = repo ??
            (Get.isRegistered<InterventionHistoryLocalRepository>()
                ? Get.find<InterventionHistoryLocalRepository>()
                : InterventionHistoryLocalRepository());

  final historyList = <InterventionModel>[].obs;
  final statistics = Rxn<InterventionStatistics>();
  final isLoading = false.obs;
  final selectedType = HistoryTypeFilter.all.obs;
  final selectedDateFilter = HistoryDateFilter.all.obs;
  final limit = 10.obs;
  final hasMore = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadHistory();
  }

  Future<void> loadHistory({bool resetLimit = true}) async {
    if (resetLimit) {
      limit.value = 10;
    }
    isLoading.value = true;
    try {
      final now = DateTime.now();
      DateTime? start;
      DateTime? end;

      switch (selectedDateFilter.value) {
        case HistoryDateFilter.today:
          start = DateTime(now.year, now.month, now.day);
          end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
          break;
        case HistoryDateFilter.week:
          final monday = now.subtract(Duration(days: now.weekday - 1));
          start = DateTime(monday.year, monday.month, monday.day);
          end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
          break;
        case HistoryDateFilter.month:
          start = DateTime(now.year, now.month, 1);
          end = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
          break;
        case HistoryDateFilter.all:
          start = null;
          end = null;
          break;
      }

      // Ambil data riwayat
      List<InterventionModel> items;
      if (start != null && end != null) {
        items = await repository.getBetween(
          start,
          end,
          type: selectedType.value.toInterventionType,
        );
      } else {
        items = await repository.getRecent(
          limit: limit.value,
          type: selectedType.value.toInterventionType,
        );
      }

      historyList.assignAll(items);
      hasMore.value = items.length >= limit.value;

      // Ambil statistik agregasi
      statistics.value = await repository.getStatistics(
        start: start,
        end: end,
      );
    } catch (_) {
      historyList.clear();
      statistics.value = InterventionStatistics.empty();
    } finally {
      isLoading.value = false;
    }
  }

  void setTypeFilter(HistoryTypeFilter filter) {
    if (selectedType.value != filter) {
      selectedType.value = filter;
      loadHistory();
    }
  }

  void setDateFilter(HistoryDateFilter filter) {
    if (selectedDateFilter.value != filter) {
      selectedDateFilter.value = filter;
      loadHistory();
    }
  }

  Future<void> loadMore() async {
    limit.value += 10;
    await loadHistory(resetLimit: false);
  }
}
