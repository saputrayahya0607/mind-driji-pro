import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/duration_formatter.dart';
import '../local/repositories/local_usage_repository.dart';
import '../models/app_usage_model.dart';
import '../models/monitoring_visualization_model.dart';
import '../repositories/doomscroll_repository.dart';
import '../repositories/eye_monitoring_repository.dart';
import '../repositories/usage_stats_repository.dart';

class MonitoringDataService {
  final UsageStatsRepository _usageStatsRepo;
  final LocalUsageRepository _localUsageRepo;
  final DoomscrollRepository _doomscrollRepo;
  final EyeMonitoringRepository _eyeRepo;
  final SupabaseClient? _supabase;

  MonitoringDataService({
    UsageStatsRepository? usageStatsRepo,
    LocalUsageRepository? localUsageRepo,
    DoomscrollRepository? doomscrollRepo,
    EyeMonitoringRepository? eyeRepo,
    SupabaseClient? supabase,
  })  : _usageStatsRepo = usageStatsRepo ?? UsageStatsRepository(),
        _localUsageRepo = localUsageRepo ?? LocalUsageRepository(),
        _doomscrollRepo = doomscrollRepo ?? DoomscrollRepository(),
        _eyeRepo = eyeRepo ?? EyeMonitoringRepository(),
        _supabase = supabase ?? _safeGetSupabaseClient();

  static SupabaseClient? _safeGetSupabaseClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  String _resolveUserId(String? userId) {
    if (userId != null && userId.isNotEmpty && userId != 'local_user') {
      return userId;
    }
    return _supabase?.auth.currentUser?.id ??
        _safeGetSupabaseClient()?.auth.currentUser?.id ??
        'local_user';
  }

  String formatDate(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  /// Mengumpulkan antrean sesi doomscrolling dari native ke SQLite Drift
  Future<int> collectPendingDoomscrollSessions() async {
    try {
      return await _doomscrollRepo.collectAndPersistPendingSessions();
    } catch (_) {
      return 0;
    }
  }

  // ===========================================================================
  // DATE TIME HELPERS & BOUNDARIES
  // ===========================================================================

  static const List<String> dayNames = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu'
  ];

  static const List<String> shortDayNames = [
    'Sen',
    'Sel',
    'Rab',
    'Kam',
    'Jum',
    'Sab',
    'Min'
  ];

  static const List<String> monthNames = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember'
  ];

  static const List<String> shortMonthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des'
  ];

  /// Menghitung overlap milidetik antara dua rentang waktu secara presisi
  static int calculateOverlap(
    DateTime startA,
    DateTime endA,
    DateTime startB,
    DateTime endB,
  ) {
    final start = startA.isAfter(startB) ? startA : startB;
    final end = endA.isBefore(endB) ? endA : endB;
    if (end.isAfter(start)) {
      return end.difference(start).inMilliseconds;
    }
    return 0;
  }

  // ===========================================================================
  /// Definisi standar 5 segmen waktu harian (MIND DRIJI):
  /// - Dini Hari: 00:00–04:59
  /// - Pagi:      05:00–10:59
  /// - Siang:     11:00–14:59
  /// - Sore:      15:00–17:59
  /// - Malam:     18:00–23:59
  static const List<Map<String, dynamic>> standardSegmentDefinitions = [
    {'label': 'Dini Hari', 'range': '00:00–04:59', 'start': 0, 'end': 5},
    {'label': 'Pagi', 'range': '05:00–10:59', 'start': 5, 'end': 11},
    {'label': 'Siang', 'range': '11:00–14:59', 'start': 11, 'end': 15},
    {'label': 'Sore', 'range': '15:00–17:59', 'start': 15, 'end': 18},
    {'label': 'Malam', 'range': '18:00–23:59', 'start': 18, 'end': 24},
  ];

  /// Menghitung akumulasi overlap milidetik dari kumpulan UsageInterval
  /// terhadap masing-masing segmen waktu pada suatu hari tertentu secara presisi.
  ///
  /// Menangani:
  /// - Pergantian jam & segment
  /// - Pergantian hari (crossing midnight): hanya porsi waktu dalam targetDate yang dihitung
  /// - Interval panjang yang melintasi beberapa segmen
  /// - Zero duration atau interval tidak valid (end <= start)
  static Map<String, int> calculateUsageIntervalSegments({
    required DateTime targetDate,
    required List<UsageInterval> intervals,
  }) {
    final dayStart = DateTime(targetDate.year, targetDate.month, targetDate.day, 0, 0, 0);
    final dayEnd = DateTime(targetDate.year, targetDate.month, targetDate.day + 1, 0, 0, 0);

    final results = <String, int>{
      'Dini Hari': 0,
      'Pagi': 0,
      'Siang': 0,
      'Sore': 0,
      'Malam': 0,
    };

    for (final interval in intervals) {
      if (!interval.endTime.isAfter(interval.startTime)) {
        continue;
      }

      // Potong interval hanya ke dalam rentang hari targetDate [dayStart .. dayEnd)
      final effectiveStart = interval.startTime.isBefore(dayStart) ? dayStart : interval.startTime;
      final effectiveEnd = interval.endTime.isAfter(dayEnd) ? dayEnd : interval.endTime;

      if (!effectiveEnd.isAfter(effectiveStart)) {
        continue;
      }

      for (final def in standardSegmentDefinitions) {
        final label = def['label'] as String;
        final sHour = def['start'] as int;
        final eHour = def['end'] as int;

        final segStart = DateTime(targetDate.year, targetDate.month, targetDate.day, sHour, 0, 0);
        final segEnd = (eHour == 24)
            ? DateTime(targetDate.year, targetDate.month, targetDate.day + 1, 0, 0, 0)
            : DateTime(targetDate.year, targetDate.month, targetDate.day, eHour, 0, 0);

        final overlap = calculateOverlap(effectiveStart, effectiveEnd, segStart, segEnd);
        if (overlap > 0) {
          results[label] = (results[label] ?? 0) + overlap;
        }
      }
    }

    return results;
  }

  // 1. DAILY AGGREGATION
  // ===========================================================================

  /// Menghasilkan 5 segmen waktu harian dari data real:
  /// - Dini Hari: 00:00–04:59
  /// - Pagi:      05:00–10:59
  /// - Siang:     11:00–14:59
  /// - Sore:      15:00–17:59
  /// - Malam:     18:00–23:59
  Future<List<TimeSegmentUsage>> getDailySegments({
    required DateTime date,
    String? userId,
    Map<String, int>? customScreenTimeBySegment,
    List<UsageInterval>? customIntervals,
  }) async {
    final effectiveUserId = _resolveUserId(userId);
    // Kumpulkan sesi pending dari native queue sebelum kalkulasi segmen
    try {
      await _doomscrollRepo.collectAndPersistPendingSessions();
    } catch (_) {}

    final dayStart = DateTime(date.year, date.month, date.day, 0, 0, 0);
    final dayEnd = DateTime(date.year, date.month, date.day + 1, 0, 0, 0);

    // Ambil sesi doomscrolling yang bersinggungan dengan hari ini (termasuk crossing midnight)
    final doomscrollSessions = await _doomscrollRepo.getSessionsBetween(
      start: dayStart.subtract(const Duration(hours: 6)),
      end: dayEnd.add(const Duration(hours: 6)),
      userId: effectiveUserId,
    );

    // Ambil data Screen Time hari ini
    final dateStr = formatDate(date);
    int totalScreenTimeMillis = 0;
    final now = DateTime.now();
    final isToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;

    List<UsageInterval> fetchedIntervals = [];

    if (isToday) {
      try {
        final todayUsage = await _usageStatsRepo.getTodayUsage();
        totalScreenTimeMillis = todayUsage.totalUsageMillis;
        fetchedIntervals = todayUsage.intervals;
      } catch (_) {}
    }
    if (totalScreenTimeMillis == 0) {
      final local = await _localUsageRepo.getScreenTime(effectiveUserId, dateStr);
      totalScreenTimeMillis = local?.totalUsageMillis.toInt() ?? 0;
    }

    final results = <TimeSegmentUsage>[];

    // Coba hitung screen time per segmen dengan interval overlap presisi
    final segmentScreenTimes = <String, int>{};
    if (customIntervals != null && customIntervals.isNotEmpty) {
      segmentScreenTimes.addAll(
        calculateUsageIntervalSegments(targetDate: date, intervals: customIntervals),
      );
    } else if (customScreenTimeBySegment != null) {
      segmentScreenTimes.addAll(customScreenTimeBySegment);
    } else if (fetchedIntervals.isNotEmpty) {
      segmentScreenTimes.addAll(
        calculateUsageIntervalSegments(targetDate: date, intervals: fetchedIntervals),
      );
    } else if (isToday) {
      for (final def in standardSegmentDefinitions) {
        final label = def['label'] as String;
        final sHour = def['start'] as int;
        final eHour = def['end'] as int;
        final sDt = DateTime(date.year, date.month, date.day, sHour, 0, 0);
        final eDt = (eHour == 24)
            ? DateTime(date.year, date.month, date.day + 1, 0, 0, 0)
            : DateTime(date.year, date.month, date.day, eHour, 0, 0);

        if (sDt.isBefore(now)) {
          final queryEnd = eDt.isAfter(now) ? now : eDt;
          final maxSegment = queryEnd.difference(sDt).inMilliseconds;
          try {
            final segUsage = await _usageStatsRepo.getUsageRange(
              startTime: sDt,
              endTime: queryEnd,
            );
            segmentScreenTimes[label] = segUsage.totalUsageMillis.clamp(0, maxSegment);
          } catch (_) {
            segmentScreenTimes[label] = 0;
          }
        } else {
          segmentScreenTimes[label] = 0;
        }
      }
    }

    for (final def in standardSegmentDefinitions) {
      final label = def['label'] as String;
      final range = def['range'] as String;
      final sHour = def['start'] as int;
      final eHour = def['end'] as int;

      final segStart = DateTime(date.year, date.month, date.day, sHour, 0, 0);
      final segEnd = (eHour == 24)
          ? DateTime(date.year, date.month, date.day + 1, 0, 0, 0)
          : DateTime(date.year, date.month, date.day, eHour, 0, 0);
      final maxSegmentDuration = segEnd.difference(segStart).inMilliseconds;

      // Hitung agregasi doomscroll pada segmen ini (dengan penanganan edge cases time boundary)
      int segDoomscrollMillis = 0;
      int segDoomscrollSwipes = 0;

      for (final session in doomscrollSessions) {
        final sStart = session.startedAt;
        final sEnd = session.endedAt ??
            (session.durationMillis > BigInt.zero
                ? sStart.add(Duration(milliseconds: session.durationMillis.toInt()))
                : DateTime.now());

        final overlap = calculateOverlap(sStart, sEnd, segStart, segEnd);
        if (overlap > 0) {
          segDoomscrollMillis += overlap;
          final totalSessMillis = session.durationMillis.toInt();
          if (totalSessMillis > 0) {
            final swipes =
                (session.swipeCount * overlap / totalSessMillis).round();
            segDoomscrollSwipes += swipes;
          } else {
            segDoomscrollSwipes += session.swipeCount;
          }
        } else if (sStart.isAfter(segStart.subtract(const Duration(milliseconds: 1))) &&
            sStart.isBefore(segEnd)) {
          segDoomscrollMillis += session.durationMillis.toInt();
          segDoomscrollSwipes += session.swipeCount;
        }
      }

      int segScreenTimeMillis = (segmentScreenTimes[label] ?? 0).clamp(0, maxSegmentDuration);
      // Jika screen time per segmen tidak tersedia tapi ada total harian dan segmen doomscroll
      if (segScreenTimeMillis == 0 && totalScreenTimeMillis > 0) {
        if (segDoomscrollMillis > 0) {
          segScreenTimeMillis = segDoomscrollMillis.clamp(0, maxSegmentDuration);
        }
      }

      results.add(
        TimeSegmentUsage(
          label: label,
          timeRange: range,
          startHour: sHour,
          endHour: eHour == 24 ? 23 : eHour - 1,
          screenTimeMillis: segScreenTimeMillis,
          doomscrollMillis: segDoomscrollMillis,
          doomscrollSwipes: segDoomscrollSwipes,
        ),
      );
    }

    return results;
  }

  // ===========================================================================
  // 2. WEEKLY AGGREGATION
  // ===========================================================================

  /// Menghitung Screen Time & Doomscrolling per hari untuk satu minggu (Senin - Minggu)
  Future<List<DayUsage>> getWeeklyDays({
    required DateTime dateInWeek,
    String? userId,
  }) async {
    final effectiveUserId = _resolveUserId(userId);
    // Senin sebagai hari pertama (weekday: 1=Senin, 7=Minggu)
    final monday = DateTime(
      dateInWeek.year,
      dateInWeek.month,
      dateInWeek.day,
    ).subtract(Duration(days: dateInWeek.weekday - 1));

    final sunday = monday.add(const Duration(days: 6));
    final startDateStr = formatDate(monday);
    final endDateStr = formatDate(sunday);

    // Ambil data screen time harian dari Drift
    final screenTimes = await _localUsageRepo.getScreenTimesBetween(
      userId: effectiveUserId,
      startDate: startDateStr,
      endDate: endDateStr,
    );

    final screenTimeMap = <String, int>{};
    for (final st in screenTimes) {
      screenTimeMap[st.date] = st.totalUsageMillis.toInt();
    }

    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    final todayStr = formatDate(now);

    // Loop 7 hari: jika data SQLite belum ada / 0, ambil dari native UsageStats untuk hari yang sudah/sedang berjalan
    for (int i = 0; i < 7; i++) {
      final dayDt = monday.add(Duration(days: i));
      final dStr = formatDate(dayDt);
      final dStart = DateTime(dayDt.year, dayDt.month, dayDt.day, 0, 0, 0);
      final dEnd = dStart.add(const Duration(days: 1));

      if (dStr == todayStr) {
        try {
          final todayUsage = await _usageStatsRepo.getTodayUsage();
          if (todayUsage.totalUsageMillis > 0) {
            screenTimeMap[todayStr] = todayUsage.totalUsageMillis;
            try {
              await _localUsageRepo.saveTodayUsage(
                userId: effectiveUserId,
                date: todayStr,
                totalUsageMillis: todayUsage.totalUsageMillis,
                apps: todayUsage.apps,
              );
            } catch (_) {}
          }
        } catch (_) {}
      } else if (dayDt.isBefore(todayMidnight)) {
        // Hari lampau dalam minggu ini
        if (screenTimeMap[dStr] == null || screenTimeMap[dStr] == 0) {
          try {
            final pastUsage = await _usageStatsRepo.getUsageRange(
              startTime: dStart,
              endTime: dEnd,
            );
            if (pastUsage.totalUsageMillis > 0) {
              screenTimeMap[dStr] = pastUsage.totalUsageMillis;
              try {
                await _localUsageRepo.saveTodayUsage(
                  userId: effectiveUserId,
                  date: dStr,
                  totalUsageMillis: pastUsage.totalUsageMillis,
                  apps: pastUsage.apps,
                );
              } catch (_) {}
            }
          } catch (_) {}
        }
      }
    }

    // Ambil sesi doomscroll dalam rentang minggu ini
    final weekStart = DateTime(monday.year, monday.month, monday.day, 0, 0, 0);
    final weekEnd = weekStart.add(const Duration(days: 7));

    final doomscrollSessions = await _doomscrollRepo.getSessionsBetween(
      start: weekStart,
      end: weekEnd,
      userId: effectiveUserId,
    );

    final results = <DayUsage>[];
    for (int i = 0; i < 7; i++) {
      final dayDt = monday.add(Duration(days: i));
      final dStr = formatDate(dayDt);

      final dStart = DateTime(dayDt.year, dayDt.month, dayDt.day, 0, 0, 0);
      final dEnd = dStart.add(const Duration(days: 1));

      int dayDoomscrollMillis = 0;
      int dayDoomscrollSwipes = 0;

      for (final s in doomscrollSessions) {
        final sEnd = s.endedAt ??
            (s.durationMillis > BigInt.zero
                ? s.startedAt.add(Duration(milliseconds: s.durationMillis.toInt()))
                : DateTime.now());
        final overlap = calculateOverlap(s.startedAt, sEnd, dStart, dEnd);
        if (overlap > 0) {
          dayDoomscrollMillis += overlap;
          final totalSess = s.durationMillis.toInt();
          if (totalSess > 0) {
            dayDoomscrollSwipes += (s.swipeCount * overlap / totalSess).round();
          } else {
            dayDoomscrollSwipes += s.swipeCount;
          }
        } else if (s.startedAt.isAfter(dStart.subtract(const Duration(milliseconds: 1))) &&
            s.startedAt.isBefore(dEnd)) {
          dayDoomscrollMillis += s.durationMillis.toInt();
          dayDoomscrollSwipes += s.swipeCount;
        }
      }

      final stMillis = screenTimeMap[dStr] ?? 0;

      results.add(
        DayUsage(
          date: dayDt,
          dayName: dayNames[i],
          shortDayName: shortDayNames[i],
          screenTimeMillis: stMillis,
          doomscrollMillis: dayDoomscrollMillis,
          doomscrollSwipes: dayDoomscrollSwipes,
        ),
      );
    }

    return results;
  }

  // ===========================================================================
  // 3. MONTHLY AGGREGATION
  // ===========================================================================

  /// Menghitung agregasi Screen Time & Doomscrolling per minggu dalam satu bulan:
  /// Week 1 (1-7), Week 2 (8-14), Week 3 (15-21), Week 4 (22-28), Week 5 (29-31).
  /// Menangani bulan dengan 28/29/30/31 hari secara dinamis tanpa mengasumsikan Week 5 selalu ada.
  Future<List<WeekUsage>> getMonthlyWeeks({
    required int year,
    required int month,
    String? userId,
  }) async {
    final effectiveUserId = _resolveUserId(userId);
    final daysInMonth = DateTime(year, month + 1, 0).day;

    final monthStartStr = formatDate(DateTime(year, month, 1));
    final monthEndStr = formatDate(DateTime(year, month, daysInMonth));

    // Ambil data screen time sebulan penuh dari Drift
    final screenTimes = await _localUsageRepo.getScreenTimesBetween(
      userId: effectiveUserId,
      startDate: monthStartStr,
      endDate: monthEndStr,
    );

    final screenTimeMap = <String, int>{};
    for (final st in screenTimes) {
      screenTimeMap[st.date] = st.totalUsageMillis.toInt();
    }

    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    final todayStr = formatDate(now);

    // Perbarui data hari ini & backfill hari lampau jika berada di bulan yang sedang ditampilkan
    if (year == now.year && month == now.month) {
      for (int d = 1; d <= now.day; d++) {
        final dayDt = DateTime(year, month, d);
        final dStr = formatDate(dayDt);
        final dStart = DateTime(year, month, d, 0, 0, 0);
        final dEnd = dStart.add(const Duration(days: 1));

        if (dStr == todayStr) {
          try {
            final todayUsage = await _usageStatsRepo.getTodayUsage();
            if (todayUsage.totalUsageMillis > 0) {
              screenTimeMap[todayStr] = todayUsage.totalUsageMillis;
              try {
                await _localUsageRepo.saveTodayUsage(
                  userId: effectiveUserId,
                  date: todayStr,
                  totalUsageMillis: todayUsage.totalUsageMillis,
                  apps: todayUsage.apps,
                );
              } catch (_) {}
            }
          } catch (_) {}
        } else if (dayDt.isBefore(todayMidnight)) {
          if (screenTimeMap[dStr] == null || screenTimeMap[dStr] == 0) {
            try {
              final pastUsage = await _usageStatsRepo.getUsageRange(
                startTime: dStart,
                endTime: dEnd,
              );
              if (pastUsage.totalUsageMillis > 0) {
                screenTimeMap[dStr] = pastUsage.totalUsageMillis;
                try {
                  await _localUsageRepo.saveTodayUsage(
                    userId: effectiveUserId,
                    date: dStr,
                    totalUsageMillis: pastUsage.totalUsageMillis,
                    apps: pastUsage.apps,
                  );
                } catch (_) {}
              }
            } catch (_) {}
          }
        }
      }
    }

    // Ambil seluruh sesi doomscroll bulan ini
    final mStart = DateTime(year, month, 1, 0, 0, 0);
    final mEnd = DateTime(year, month + 1, 1, 0, 0, 0);

    final doomscrollSessions = await _doomscrollRepo.getSessionsBetween(
      start: mStart,
      end: mEnd,
      userId: effectiveUserId,
    );

    final weekRanges = <Map<String, dynamic>>[
      {
        'weekNumber': 1,
        'label': 'Week 1',
        'startDay': 1,
        'endDay': 7,
      },
      {
        'weekNumber': 2,
        'label': 'Week 2',
        'startDay': 8,
        'endDay': 14,
      },
      {
        'weekNumber': 3,
        'label': 'Week 3',
        'startDay': 15,
        'endDay': 21,
      },
      {
        'weekNumber': 4,
        'label': 'Week 4',
        'startDay': 22,
        'endDay': 28,
      },
      if (daysInMonth > 28)
        {
          'weekNumber': 5,
          'label': 'Week 5',
          'startDay': 29,
          'endDay': daysInMonth,
        },
    ];

    final results = <WeekUsage>[];

    for (final wr in weekRanges) {
      final wNum = wr['weekNumber'] as int;
      final label = wr['label'] as String;
      final sDay = wr['startDay'] as int;
      final eDay = wr['endDay'] as int;

      final wStart = DateTime(year, month, sDay, 0, 0, 0);
      final wEnd = (eDay == daysInMonth)
          ? DateTime(year, month + 1, 1, 0, 0, 0)
          : DateTime(year, month, eDay + 1, 0, 0, 0);

      int weekScreenTimeMillis = 0;
      for (int d = sDay; d <= eDay; d++) {
        final dStr = formatDate(DateTime(year, month, d));
        weekScreenTimeMillis += screenTimeMap[dStr] ?? 0;
      }

      int weekDoomscrollMillis = 0;
      int weekDoomscrollSwipes = 0;

      for (final s in doomscrollSessions) {
        final sEnd = s.endedAt ??
            (s.durationMillis > BigInt.zero
                ? s.startedAt.add(Duration(milliseconds: s.durationMillis.toInt()))
                : DateTime.now());
        final overlap = calculateOverlap(s.startedAt, sEnd, wStart, wEnd);
        if (overlap > 0) {
          weekDoomscrollMillis += overlap;
          final totalSess = s.durationMillis.toInt();
          if (totalSess > 0) {
            weekDoomscrollSwipes += (s.swipeCount * overlap / totalSess).round();
          } else {
            weekDoomscrollSwipes += s.swipeCount;
          }
        } else if (s.startedAt.isAfter(wStart.subtract(const Duration(milliseconds: 1))) &&
            s.startedAt.isBefore(wEnd)) {
          weekDoomscrollMillis += s.durationMillis.toInt();
          weekDoomscrollSwipes += s.swipeCount;
        }
      }

      results.add(
        WeekUsage(
          weekNumber: wNum,
          label: label,
          startDate: wStart,
          endDate: wEnd,
          screenTimeMillis: weekScreenTimeMillis,
          doomscrollMillis: weekDoomscrollMillis,
          doomscrollSwipes: weekDoomscrollSwipes,
        ),
      );
    }

    return results;
  }

  // ===========================================================================
  // 4. TOP 5 APP USAGE
  // ===========================================================================

  /// Mengambil maksimal 5 aplikasi teratas berdasarkan total durasi penggunaan (DATA REAL)
  Future<List<AppUsageModel>> getTopApps({
    required MonitoringPeriod period,
    required DateTime date,
    String? userId,
  }) async {
    final effectiveUserId = _resolveUserId(userId);
    final now = DateTime.now();

    if (period == MonitoringPeriod.daily) {
      final isToday = date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;

      if (isToday) {
        try {
          final stats = await _usageStatsRepo.getTodayUsage();
          final nonZeroApps = stats.apps.where((a) => a.usageMillis > 0).toList();
          if (nonZeroApps.isNotEmpty) {
            nonZeroApps.sort((a, b) => b.usageMillis.compareTo(a.usageMillis));
            return nonZeroApps.take(5).toList();
          }
        } catch (_) {}
      }

      final dateStr = formatDate(date);
      final localApps = await _localUsageRepo.getAppUsages(effectiveUserId, dateStr);
      final appModels = localApps
          .where((a) => a.usageMillis > BigInt.zero)
          .map((a) => AppUsageModel(
                packageName: a.packageName,
                appName: a.appName,
                usageMillis: a.usageMillis.toInt(),
              ))
          .toList();
      appModels.sort((a, b) => b.usageMillis.compareTo(a.usageMillis));
      return appModels.take(5).toList();
    } else if (period == MonitoringPeriod.weekly) {
      final monday = DateTime(date.year, date.month, date.day)
          .subtract(Duration(days: date.weekday - 1));
      final sunday = monday.add(const Duration(days: 6));
      final sStr = formatDate(monday);
      final eStr = formatDate(sunday);
      final todayStr = formatDate(now);

      final rawApps = await _localUsageRepo.getAppUsagesBetween(
        userId: effectiveUserId,
        startDate: sStr,
        endDate: eStr,
      );

      final aggregated = <String, AppUsageModel>{};
      final isCurrentWeek = monday.isBefore(now) &&
          sunday.add(const Duration(days: 1)).isAfter(now);

      // 1. Agregasi app usage dari SQLite Drift (abaikan hari ini jika minggu berjalan, agar digabung dengan live hari ini)
      for (final a in rawApps) {
        if (isCurrentWeek && a.date == todayStr) {
          continue;
        }
        final existing = aggregated[a.packageName];
        final addMillis = a.usageMillis.toInt();
        if (existing == null) {
          aggregated[a.packageName] = AppUsageModel(
            packageName: a.packageName,
            appName: a.appName,
            usageMillis: addMillis,
          );
        } else {
          aggregated[a.packageName] = AppUsageModel(
            packageName: a.packageName,
            appName: a.appName.isNotEmpty ? a.appName : existing.appName,
            usageMillis: existing.usageMillis + addMillis,
          );
        }
      }

      // 2. Gabungkan data live hari ini jika rentang minggu mencakup hari ini
      if (isCurrentWeek) {
        try {
          final todayStats = await _usageStatsRepo.getTodayUsage();
          for (final app in todayStats.apps) {
            if (app.usageMillis <= 0) continue;
            final existing = aggregated[app.packageName];
            if (existing == null) {
              aggregated[app.packageName] = app;
            } else {
              aggregated[app.packageName] = AppUsageModel(
                packageName: app.packageName,
                appName: app.appName.isNotEmpty ? app.appName : existing.appName,
                usageMillis: existing.usageMillis + app.usageMillis,
              );
            }
          }
        } catch (_) {
          for (final a in rawApps.where((a) => a.date == todayStr)) {
            final existing = aggregated[a.packageName];
            final addMillis = a.usageMillis.toInt();
            if (existing == null) {
              aggregated[a.packageName] = AppUsageModel(
                packageName: a.packageName,
                appName: a.appName,
                usageMillis: addMillis,
              );
            } else {
              aggregated[a.packageName] = AppUsageModel(
                packageName: a.packageName,
                appName: a.appName.isNotEmpty ? a.appName : existing.appName,
                usageMillis: existing.usageMillis + addMillis,
              );
            }
          }
        }
      }

      // 3. Fallback jika agregasi masih kosong sama sekali (misal user baru install dan langsung buka Tab Minggu)
      if (aggregated.isEmpty) {
        try {
          final weekStart = DateTime(monday.year, monday.month, monday.day, 0, 0, 0);
          final weekEndQuery = sunday.add(const Duration(days: 1)).isAfter(now)
              ? now
              : DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59);
          final rangeStats = await _usageStatsRepo.getUsageRange(
            startTime: weekStart,
            endTime: weekEndQuery,
          );
          for (final app in rangeStats.apps) {
            if (app.usageMillis > 0) {
              aggregated[app.packageName] = app;
            }
          }
        } catch (_) {}
      }

      final list = aggregated.values.where((a) => a.usageMillis > 0).toList();
      list.sort((a, b) => b.usageMillis.compareTo(a.usageMillis));
      return list.take(5).toList();
    } else {
      // Monthly
      final daysInMonth = DateTime(date.year, date.month + 1, 0).day;
      final mStart = DateTime(date.year, date.month, 1, 0, 0, 0);
      final mEnd = DateTime(date.year, date.month, daysInMonth, 23, 59, 59);
      final sStr = formatDate(mStart);
      final eStr = formatDate(mEnd);
      final todayStr = formatDate(now);

      final rawApps = await _localUsageRepo.getAppUsagesBetween(
        userId: effectiveUserId,
        startDate: sStr,
        endDate: eStr,
      );

      final aggregated = <String, AppUsageModel>{};
      final isCurrentMonth = date.year == now.year && date.month == now.month;

      for (final a in rawApps) {
        if (isCurrentMonth && a.date == todayStr) {
          continue;
        }
        final existing = aggregated[a.packageName];
        final addMillis = a.usageMillis.toInt();
        if (existing == null) {
          aggregated[a.packageName] = AppUsageModel(
            packageName: a.packageName,
            appName: a.appName,
            usageMillis: addMillis,
          );
        } else {
          aggregated[a.packageName] = AppUsageModel(
            packageName: a.packageName,
            appName: a.appName.isNotEmpty ? a.appName : existing.appName,
            usageMillis: existing.usageMillis + addMillis,
          );
        }
      }

      if (isCurrentMonth) {
        try {
          final todayStats = await _usageStatsRepo.getTodayUsage();
          for (final app in todayStats.apps) {
            if (app.usageMillis <= 0) continue;
            final existing = aggregated[app.packageName];
            if (existing == null) {
              aggregated[app.packageName] = app;
            } else {
              aggregated[app.packageName] = AppUsageModel(
                packageName: app.packageName,
                appName: app.appName.isNotEmpty ? app.appName : existing.appName,
                usageMillis: existing.usageMillis + app.usageMillis,
              );
            }
          }
        } catch (_) {
          for (final a in rawApps.where((a) => a.date == todayStr)) {
            final existing = aggregated[a.packageName];
            final addMillis = a.usageMillis.toInt();
            if (existing == null) {
              aggregated[a.packageName] = AppUsageModel(
                packageName: a.packageName,
                appName: a.appName,
                usageMillis: addMillis,
              );
            } else {
              aggregated[a.packageName] = AppUsageModel(
                packageName: a.packageName,
                appName: a.appName.isNotEmpty ? a.appName : existing.appName,
                usageMillis: existing.usageMillis + addMillis,
              );
            }
          }
        }
      }

      if (aggregated.isEmpty) {
        try {
          final mEndQuery = mEnd.isAfter(now) ? now : mEnd;
          final rangeStats = await _usageStatsRepo.getUsageRange(
            startTime: mStart,
            endTime: mEndQuery,
          );
          for (final app in rangeStats.apps) {
            if (app.usageMillis > 0) {
              aggregated[app.packageName] = app;
            }
          }
        } catch (_) {}
      }

      final list = aggregated.values.where((a) => a.usageMillis > 0).toList();
      list.sort((a, b) => b.usageMillis.compareTo(a.usageMillis));
      return list.take(5).toList();
    }
  }

  // ===========================================================================
  // 5. DOOMSCROLLING SUMMARY
  // ===========================================================================

  /// Menghitung ringkasan perilaku scrolling (sesi, durasi, total swipe, downward, upward)
  Future<DoomscrollSummary> getDoomscrollSummary({
    required MonitoringPeriod period,
    required DateTime date,
    String? userId,
  }) async {
    final effectiveUserId = _resolveUserId(userId);
    // Kumpulkan antrean sesi native terbaru ke SQLite Drift jika tersedia
    try {
      await _doomscrollRepo.collectAndPersistPendingSessions();
    } catch (_) {}

    DateTime start;
    DateTime end;

    if (period == MonitoringPeriod.daily) {
      start = DateTime(date.year, date.month, date.day, 0, 0, 0);
      end = DateTime(date.year, date.month, date.day + 1, 0, 0, 0);
    } else if (period == MonitoringPeriod.weekly) {
      final monday = DateTime(date.year, date.month, date.day)
          .subtract(Duration(days: date.weekday - 1));
      start = DateTime(monday.year, monday.month, monday.day, 0, 0, 0);
      end = start.add(const Duration(days: 7));
    } else {
      start = DateTime(date.year, date.month, 1, 0, 0, 0);
      end = DateTime(date.year, date.month + 1, 1, 0, 0, 0);
    }

    final sessions = await _doomscrollRepo.getSessionsBetween(
      start: start,
      end: end,
      userId: effectiveUserId,
    );

    int totalDuration = 0;
    int totalSwipes = 0;
    int downwardSwipes = 0;
    int upwardSwipes = 0;

    for (final s in sessions) {
      final sEnd = s.endedAt ??
          (s.durationMillis > BigInt.zero
              ? s.startedAt.add(Duration(milliseconds: s.durationMillis.toInt()))
              : DateTime.now());
      final overlap = calculateOverlap(s.startedAt, sEnd, start, end);
      if (overlap > 0) {
        totalDuration += overlap;
        final totalSess = s.durationMillis.toInt();
        if (totalSess > 0) {
          totalSwipes += (s.swipeCount * overlap / totalSess).round();
          downwardSwipes += (s.downwardSwipeCount * overlap / totalSess).round();
          upwardSwipes += (s.upwardSwipeCount * overlap / totalSess).round();
        } else {
          totalSwipes += s.swipeCount;
          downwardSwipes += s.downwardSwipeCount;
          upwardSwipes += s.upwardSwipeCount;
        }
      } else if (s.startedAt.isAfter(start.subtract(const Duration(milliseconds: 1))) &&
          s.startedAt.isBefore(end)) {
        totalDuration += s.durationMillis.toInt();
        totalSwipes += s.swipeCount;
        downwardSwipes += s.downwardSwipeCount;
        upwardSwipes += s.upwardSwipeCount;
      }
    }

    return DoomscrollSummary(
      totalSessions: sessions.length,
      totalDurationMillis: totalDuration,
      totalSwipes: totalSwipes,
      downwardSwipes: downwardSwipes,
      upwardSwipes: upwardSwipes,
    );
  }

  // ===========================================================================
  // 6. EYE MONITORING SUMMARY
  // ===========================================================================

  /// Menghitung ringkasan pemantauan mata (sesi, durasi, rata-rata EAR, closure, blink)
  Future<EyeMonitoringSummary> getEyeMonitoringSummary({
    required MonitoringPeriod period,
    required DateTime date,
    String? userId,
  }) async {
    final effectiveUserId = _resolveUserId(userId);
    DateTime start;
    DateTime end;

    if (period == MonitoringPeriod.daily) {
      start = DateTime(date.year, date.month, date.day, 0, 0, 0);
      end = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
    } else if (period == MonitoringPeriod.weekly) {
      final monday = DateTime(date.year, date.month, date.day)
          .subtract(Duration(days: date.weekday - 1));
      final sunday = monday.add(const Duration(days: 6));
      start = DateTime(monday.year, monday.month, monday.day, 0, 0, 0);
      end = DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59, 999);
    } else {
      final daysInMonth = DateTime(date.year, date.month + 1, 0).day;
      start = DateTime(date.year, date.month, 1, 0, 0, 0);
      end = DateTime(date.year, date.month, daysInMonth, 23, 59, 59, 999);
    }

    final sessions = await _eyeRepo.getSessionsBetween(
      start: start,
      end: end,
      userId: effectiveUserId,
    );

    int totalDuration = 0;
    double earSum = 0;
    int earCount = 0;
    int closures = 0;
    int blinks = 0;

    for (final s in sessions) {
      final sEnd = s.endedAt ??
          s.startedAt.add(Duration(milliseconds: s.durationMillis.toInt()));
      final overlap = calculateOverlap(s.startedAt, sEnd, start, end);
      if (overlap > 0) {
        totalDuration += overlap;
        if (s.averageEar > 0) {
          earSum += s.averageEar;
          earCount++;
        }
        closures += s.eyeClosureEvents;
        blinks += s.blinkCount;
      }
    }

    final avgEar = earCount > 0 ? (earSum / earCount) : null;

    return EyeMonitoringSummary(
      totalSessions: sessions.length,
      totalDurationMillis: totalDuration,
      averageEar: avgEar,
      eyeClosureEvents: closures,
      blinkCount: blinks,
    );
  }

  // ===========================================================================
  // 7. SCREEN TIME COMPARISON CALCULATION
  // ===========================================================================

  /// Menghitung total Screen Time dan kalimat perbandingan objektif tanpa diagnosis
  Future<Map<String, dynamic>> getScreenTimeSummary({
    required MonitoringPeriod period,
    required DateTime date,
    String? userId,
  }) async {
    final effectiveUserId = _resolveUserId(userId);
    final now = DateTime.now();

    if (period == MonitoringPeriod.daily) {
      final isToday = date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;

      int currentMillis = 0;
      if (isToday) {
        try {
          final todayUsage = await _usageStatsRepo.getTodayUsage();
          currentMillis = todayUsage.totalUsageMillis;
        } catch (_) {}
      }
      if (currentMillis == 0) {
        final local = await _localUsageRepo.getScreenTime(
          effectiveUserId,
          formatDate(date),
        );
        currentMillis = local?.totalUsageMillis.toInt() ?? 0;
      }

      // Bandingkan dengan kemarin
      final yesterday = date.subtract(const Duration(days: 1));
      final yesterdayRecord = await _localUsageRepo.getScreenTime(
        effectiveUserId,
        formatDate(yesterday),
      );

      String comparisonText;
      if (yesterdayRecord != null && yesterdayRecord.totalUsageMillis > BigInt.zero) {
        final yMillis = yesterdayRecord.totalUsageMillis.toInt();
        final diff = currentMillis - yMillis;
        if (diff > 0) {
          comparisonText = 'Naik ${DurationFormatter.format(diff)} dibanding kemarin';
        } else if (diff < 0) {
          comparisonText = 'Turun ${DurationFormatter.format(diff.abs())} dibanding kemarin';
        } else {
          comparisonText = 'Sama dengan kemarin';
        }
      } else {
        comparisonText = isToday
            ? '${DurationFormatter.format(currentMillis)} dari data hari ini'
            : '${DurationFormatter.format(currentMillis)} total waktu layar';
      }

      return {
        'totalMillis': currentMillis,
        'comparisonText': comparisonText,
      };
    } else if (period == MonitoringPeriod.weekly) {
      final days = await getWeeklyDays(dateInWeek: date, userId: effectiveUserId);
      final currentMillis = days.fold<int>(0, (sum, d) => sum + d.screenTimeMillis);

      // Bandingkan dengan minggu sebelumnya
      final prevMonday = date.subtract(Duration(days: date.weekday - 1 + 7));
      final prevDays = await getWeeklyDays(dateInWeek: prevMonday, userId: effectiveUserId);
      final prevMillis = prevDays.fold<int>(0, (sum, d) => sum + d.screenTimeMillis);

      String comparisonText;
      if (prevMillis > 0) {
        final diff = currentMillis - prevMillis;
        if (diff > 0) {
          comparisonText = 'Naik ${DurationFormatter.format(diff)} dibanding minggu lalu';
        } else if (diff < 0) {
          comparisonText = 'Turun ${DurationFormatter.format(diff.abs())} dibanding minggu lalu';
        } else {
          comparisonText = 'Sama dengan minggu lalu';
        }
      } else {
        comparisonText = '${DurationFormatter.format(currentMillis)} dari data minggu ini';
      }

      return {
        'totalMillis': currentMillis,
        'comparisonText': comparisonText,
      };
    } else {
      // Monthly
      final weeks = await getMonthlyWeeks(
        year: date.year,
        month: date.month,
        userId: effectiveUserId,
      );
      final currentMillis = weeks.fold<int>(0, (sum, w) => sum + w.screenTimeMillis);

      // Bandingkan dengan bulan sebelumnya
      final prevMonthDate = DateTime(date.year, date.month - 1, 1);
      final prevWeeks = await getMonthlyWeeks(
        year: prevMonthDate.year,
        month: prevMonthDate.month,
        userId: effectiveUserId,
      );
      final prevMillis = prevWeeks.fold<int>(0, (sum, w) => sum + w.screenTimeMillis);

      String comparisonText;
      if (prevMillis > 0) {
        final diff = currentMillis - prevMillis;
        if (diff > 0) {
          comparisonText = 'Naik ${DurationFormatter.format(diff)} dibanding bulan lalu';
        } else if (diff < 0) {
          comparisonText = 'Turun ${DurationFormatter.format(diff.abs())} dibanding bulan lalu';
        } else {
          comparisonText = 'Sama dengan bulan lalu';
        }
      } else {
        comparisonText = '${DurationFormatter.format(currentMillis)} dari data bulan ini';
      }

      return {
        'totalMillis': currentMillis,
        'comparisonText': comparisonText,
      };
    }
  }
}
