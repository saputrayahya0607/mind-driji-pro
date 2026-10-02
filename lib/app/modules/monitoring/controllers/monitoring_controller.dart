import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/app_usage_model.dart';
import '../../../data/models/monitoring_visualization_model.dart';
import '../../../data/services/monitoring_data_service.dart';

class MonitoringController extends GetxController with WidgetsBindingObserver {
  final MonitoringDataService _dataService;

  MonitoringController({
    MonitoringDataService? dataService,
  }) : _dataService = dataService ?? MonitoringDataService();

  // State Reaktif
  final selectedPeriod = MonitoringPeriod.daily.obs;
  final selectedDate = DateTime.now().obs;
  final isLoading = false.obs;
  final errorMessage = RxnString();

  // Screen Time Data
  final totalScreenTimeMillis = 0.obs;
  final screenTimeComparison = ''.obs;

  // Visualisasi Charts
  final dailySegments = <TimeSegmentUsage>[].obs;
  final weeklyDays = <DayUsage>[].obs;
  final monthlyWeeks = <WeekUsage>[].obs;

  // App Usage Data
  final topApps = <AppUsageModel>[].obs;

  // Doomscroll Data
  final doomscrollSummary = const DoomscrollSummary().obs;

  // Eye Monitoring Data
  final eyeSummary = const EyeMonitoringSummary().obs;

  // Helper Getters untuk Validasi Data Real
  bool get hasAnyData =>
      totalScreenTimeMillis.value > 0 ||
      doomscrollSummary.value.hasData ||
      eyeSummary.value.hasData;

  bool get hasScreenTimeData => totalScreenTimeMillis.value > 0;
  bool get hasDoomscrollData => doomscrollSummary.value.hasData;
  bool get hasEyeData => eyeSummary.value.hasData;
  bool get hasAppUsageData => topApps.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    try {
      WidgetsBinding.instance.addObserver(this);
    } catch (_) {}
    loadData();
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
      loadData();
    }
  }

  /// Mengubah tab periode (Hari, Minggu, Bulan)
  void setPeriod(MonitoringPeriod period) {
    if (selectedPeriod.value != period) {
      selectedPeriod.value = period;
      loadData();
    }
  }

  /// Memeriksa apakah tombol navigasi periode berikutnya (Next/Future) diperbolehkan
  bool get canGoNext {
    final now = DateTime.now();
    final current = selectedDate.value;

    switch (selectedPeriod.value) {
      case MonitoringPeriod.daily:
        final todayMidnight = DateTime(now.year, now.month, now.day);
        final currentMidnight =
            DateTime(current.year, current.month, current.day);
        return currentMidnight.isBefore(todayMidnight);

      case MonitoringPeriod.weekly:
        final currentMonday =
            DateTime(current.year, current.month, current.day)
                .subtract(Duration(days: current.weekday - 1));
        final currentSunday = currentMonday.add(const Duration(days: 6));
        final nowMidnight = DateTime(now.year, now.month, now.day);
        return currentSunday.isBefore(nowMidnight);

      case MonitoringPeriod.monthly:
        if (current.year < now.year) return true;
        if (current.year == now.year && current.month < now.month) return true;
        return false;
    }
  }

  /// Berpindah ke tanggal/minggu/bulan sebelumnya
  void goToPreviousPeriod() {
    final current = selectedDate.value;
    switch (selectedPeriod.value) {
      case MonitoringPeriod.daily:
        selectedDate.value = current.subtract(const Duration(days: 1));
        break;
      case MonitoringPeriod.weekly:
        selectedDate.value = current.subtract(const Duration(days: 7));
        break;
      case MonitoringPeriod.monthly:
        selectedDate.value = DateTime(current.year, current.month - 1, 1);
        break;
    }
    loadData();
  }

  /// Berpindah ke tanggal/minggu/bulan berikutnya (jika tidak melebihi masa kini)
  void goToNextPeriod() {
    if (!canGoNext) return;
    final current = selectedDate.value;
    switch (selectedPeriod.value) {
      case MonitoringPeriod.daily:
        selectedDate.value = current.add(const Duration(days: 1));
        break;
      case MonitoringPeriod.weekly:
        selectedDate.value = current.add(const Duration(days: 7));
        break;
      case MonitoringPeriod.monthly:
        selectedDate.value = DateTime(current.year, current.month + 1, 1);
        break;
    }
    loadData();
  }

  /// Label navigasi tanggal sesuai dengan format yang diminta
  String get dateRangeLabel {
    final current = selectedDate.value;
    switch (selectedPeriod.value) {
      case MonitoringPeriod.daily:
        final day = current.day;
        final monthStr = MonitoringDataService.shortMonthNames[current.month - 1];
        return '$day $monthStr ${current.year}';

      case MonitoringPeriod.weekly:
        final monday = DateTime(current.year, current.month, current.day)
            .subtract(Duration(days: current.weekday - 1));
        final sunday = monday.add(const Duration(days: 6));
        final mShort = MonitoringDataService.shortMonthNames[monday.month - 1];
        final sShort = MonitoringDataService.shortMonthNames[sunday.month - 1];
        if (monday.month == sunday.month) {
          return '${monday.day} – ${sunday.day} $mShort';
        } else {
          return '${monday.day} $mShort – ${sunday.day} $sShort';
        }

      case MonitoringPeriod.monthly:
        final monthName = MonitoringDataService.monthNames[current.month - 1];
        return '$monthName ${current.year}';
    }
  }

  /// Subtitle tanggal untuk tab Daily (Hari)
  String get dailySubtitle {
    final current = selectedDate.value;
    final now = DateTime.now();
    final isToday = current.year == now.year &&
        current.month == now.month &&
        current.day == now.day;

    if (isToday) return 'Hari Ini';
    return MonitoringDataService.dayNames[current.weekday - 1];
  }

  /// Memuat dan mengagregasi data real untuk periode aktif
  Future<void> loadData() async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      // Kumpulkan sesi pending dari native sebelum kalkulasi data monitoring
      await _dataService.collectPendingDoomscrollSessions();

      final period = selectedPeriod.value;
      final date = selectedDate.value;

      // 1. Screen Time Summary & Comparison
      final stSummary = await _dataService.getScreenTimeSummary(
        period: period,
        date: date,
      );
      totalScreenTimeMillis.value = stSummary['totalMillis'] as int;
      screenTimeComparison.value = stSummary['comparisonText'] as String;

      // 2. Charts / Visualization Breakdown
      if (period == MonitoringPeriod.daily) {
        final segments = await _dataService.getDailySegments(date: date);
        dailySegments.assignAll(segments);
      } else if (period == MonitoringPeriod.weekly) {
        final days = await _dataService.getWeeklyDays(dateInWeek: date);
        weeklyDays.assignAll(days);
      } else {
        final weeks = await _dataService.getMonthlyWeeks(
          year: date.year,
          month: date.month,
        );
        monthlyWeeks.assignAll(weeks);
      }

      // 3. Top 5 Apps
      final apps = await _dataService.getTopApps(
        period: period,
        date: date,
      );
      topApps.assignAll(apps);

      // 4. Doomscroll Summary
      final doomSummary = await _dataService.getDoomscrollSummary(
        period: period,
        date: date,
      );
      doomscrollSummary.value = doomSummary;

      // 5. Eye Monitoring Summary
      final eye = await _dataService.getEyeMonitoringSummary(
        period: period,
        date: date,
      );
      eyeSummary.value = eye;
    } catch (e) {
      errorMessage.value = 'Gagal memuat visualisasi data monitoring.';
    } finally {
      isLoading.value = false;
    }
  }
}
