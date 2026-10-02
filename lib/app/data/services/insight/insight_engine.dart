import '../../../core/utils/duration_formatter.dart';
import '../../models/behavioral_features.dart';
import '../../models/detection_result.dart';
import '../../models/insight_model.dart';
import '../../models/monitoring_visualization_model.dart';

/// Engine penerjemah data pemantauan dan deteksi perilaku menjadi kumpulan [InsightModel]
///
/// Prinsip:
/// - Faktual & ringkas
/// - Non-judgmental & tidak mendiagnosis medis
/// - Tanpa skor kecanduan
/// - Memberikan saran tindakan (*suggested action*) yang membutuhkan persetujuan pengguna
class InsightEngine {
  const InsightEngine();

  /// Menghasilkan daftar insight yang terurut berdasarkan prioritas penyajian
  List<InsightModel> generateInsights({
    required DetectionResult detection,
    required BehavioralFeatures features,
    EyeMonitoringSummary? eyeSummary,
    int totalScreenTimeMillis = 0,
    List<TimeSegmentUsage>? dailySegments,
    List<DayUsage>? weeklyDays,
    List<WeekUsage>? monthlyWeeks,
    String? topApp,
    String period = 'daily',
    DateTime? date,
  }) {
    final effectiveDate = date ?? features.date;
    final insights = <InsightModel>[];

    // 1. Scrolling Detection Insight (Prioritas Tertinggi)
    final scrollingInsight = _generateScrollingInsight(
      detection: detection,
      features: features,
      period: period,
      date: effectiveDate,
    );
    insights.add(scrollingInsight);

    // 2. Usage Pattern & Screen Time Insight
    final usageInsight = _generateUsagePatternInsight(
      features: features,
      totalScreenTimeMillis: totalScreenTimeMillis,
      dailySegments: dailySegments,
      weeklyDays: weeklyDays,
      monthlyWeeks: monthlyWeeks,
      topApp: topApp ?? features.topScrollingApp,
      period: period,
      date: effectiveDate,
    );
    if (usageInsight != null) {
      insights.add(usageInsight);
    }

    // 3. Eye Monitoring Context Insight
    final eyeInsight = _generateEyeInsight(
      eyeSummary: eyeSummary,
      period: period,
      date: effectiveDate,
    );
    if (eyeInsight != null) {
      insights.add(eyeInsight);
    }

    // 4. Recommendation / Suggested Action Insight
    if (detection.detected && detection.suggestedIntervention != null) {
      final recInsight = _generateRecommendationInsight(
        detection: detection,
        period: period,
        date: effectiveDate,
      );
      insights.add(recInsight);
    }

    // Urutkan berdasarkan prioritas tampilan: high -> medium -> low
    insights.sort((a, b) => a.priority.index.compareTo(b.priority.index));

    return insights;
  }

  // ===========================================================================
  // 1. SCROLLING INSIGHT
  // ===========================================================================
  InsightModel _generateScrollingInsight({
    required DetectionResult detection,
    required BehavioralFeatures features,
    required String period,
    required DateTime date,
  }) {
    final now = DateTime.now();

    if (!features.hasSessions) {
      return InsightModel(
        id: 'scroll_${period}_${date.millisecondsSinceEpoch}',
        type: InsightType.scrolling,
        title: 'Belum ada pola scrolling khusus yang terdeteksi',
        summary: 'Belum ada data sesi scrolling yang tercatat pada periode ini.',
        details:
            'Terus pantau pola penggunaanmu untuk mendapatkan insight yang lebih lengkap.',
        evidences: const [
          InsightEvidenceItem(
            label: 'Total sesi',
            value: '0 sesi',
            iconName: 'history_rounded',
          ),
          InsightEvidenceItem(
            label: 'Total swipe',
            value: '0',
            iconName: 'swipe_rounded',
          ),
        ],
        relatedApps: const [],
        period: period,
        generatedAt: now,
        priority: InsightPriority.low,
      );
    }

    if (!detection.detected) {
      return InsightModel(
        id: 'scroll_${period}_${date.millisecondsSinceEpoch}',
        type: InsightType.scrolling,
        title: 'Belum ada pola scrolling khusus yang terdeteksi',
        summary:
            'Pola penggunaan aplikasi berada dalam rentang normal berdasarkan data pemantauan.',
        details:
            'Terus pantau pola penggunaanmu untuk mendapatkan insight yang lebih lengkap.',
        evidences: [
          InsightEvidenceItem(
            label: 'Total scrolling',
            value: '${features.totalScrollingSessions} sesi',
            iconName: 'history_rounded',
          ),
          InsightEvidenceItem(
            label: 'Total swipe',
            value: '${features.totalSwipeCount}',
            iconName: 'swipe_rounded',
          ),
          InsightEvidenceItem(
            label: 'Durasi scrolling',
            value: DurationFormatter.format(features.totalScrollingDurationMillis),
            iconName: 'timer_rounded',
          ),
        ],
        relatedApps: features.involvedApps,
        period: period,
        generatedAt: now,
        priority: InsightPriority.medium,
      );
    }

    // Kasus Detection Terdeteksi
    switch (detection.type) {
      case DetectionType.longScrollSession:
        return InsightModel(
          id: 'scroll_${period}_${date.millisecondsSinceEpoch}',
          type: InsightType.scrolling,
          title: 'Sesi scrolling panjang terdeteksi',
          summary: 'Terdapat sesi scrolling yang berlangsung cukup lama.',
          details:
              'Pada periode pemantauan terdapat sesi scrolling dengan durasi terpanjang '
              '${DurationFormatter.format(features.longestSessionDurationMillis)}.',
          evidences: [
            InsightEvidenceItem(
              label: 'Sesi terpanjang',
              value: DurationFormatter.format(features.longestSessionDurationMillis),
              iconName: 'hourglass_top_rounded',
            ),
            InsightEvidenceItem(
              label: 'Total scrolling',
              value: '${features.totalScrollingSessions} sesi',
              iconName: 'history_rounded',
            ),
            InsightEvidenceItem(
              label: 'Total swipe',
              value: '${features.totalSwipeCount}',
              iconName: 'swipe_rounded',
            ),
          ],
          relatedApps: features.involvedApps,
          period: period,
          generatedAt: now,
          suggestedAction: detection.suggestedIntervention ?? 'Jeda Digital',
          priority: InsightPriority.high,
        );

      case DetectionType.repeatedScrolling:
        final avgGapStr = features.averageSessionGapMillis > 0
            ? DurationFormatter.format(features.averageSessionGapMillis)
            : '< 15m';
        return InsightModel(
          id: 'scroll_${period}_${date.millisecondsSinceEpoch}',
          type: InsightType.scrolling,
          title: 'Sesi scrolling berulang',
          summary:
              'Beberapa sesi scrolling terjadi kembali dalam jeda waktu yang relatif singkat.',
          details:
              'Terdeteksi ${features.repeatedSessionCount} kali sesi yang dibuka kembali '
              'dengan jeda rata-rata $avgGapStr.',
          evidences: [
            InsightEvidenceItem(
              label: 'Jumlah sesi',
              value: '${features.totalScrollingSessions} sesi',
              iconName: 'repeat_rounded',
            ),
            InsightEvidenceItem(
              label: 'Sesi berulang',
              value: '${features.repeatedSessionCount} kali',
              iconName: 'replay_rounded',
            ),
            InsightEvidenceItem(
              label: 'Jeda antar sesi',
              value: avgGapStr,
              iconName: 'timer_rounded',
            ),
          ],
          relatedApps: features.involvedApps,
          period: period,
          generatedAt: now,
          suggestedAction: detection.suggestedIntervention ?? 'Jeda Digital',
          priority: InsightPriority.high,
        );

      case DetectionType.highScrollActivity:
        final isDownwardPattern = detection.evidences.contains(DetectionEvidence.downwardPattern) &&
            !detection.evidences.contains(DetectionEvidence.highSwipeActivity);
        final title = isDownwardPattern
            ? 'Pola scrolling terdeteksi'
            : (detection.title.isNotEmpty ? detection.title : 'Aktivitas scrolling meningkat');
        final summary = isDownwardPattern
            ? 'Pola scrolling teridentifikasi dengan konsistensi arah gulir tinggi.'
            : 'Frekuensi navigasi dan interaksi scrolling tercatat tinggi pada periode pemantauan.';
        final details = isDownwardPattern
            ? 'Tercatat dominasi scrolling ke bawah sebanyak ${features.totalDownwardSwipeCount} kali (${(features.downwardSwipeRatio * 100).toInt()}%).'
            : 'Tercatat akumulasi ${features.totalSwipeCount} kali swipe dengan rata-rata '
                '${features.averageSwipesPerSession.toStringAsFixed(0)} swipe per sesi.';

        final evidencesList = <InsightEvidenceItem>[
          InsightEvidenceItem(
            label: 'Total swipe',
            value: '${features.totalSwipeCount}',
            iconName: 'speed_rounded',
          ),
        ];
        if (isDownwardPattern || features.downwardSwipeRatio > 0) {
          evidencesList.add(InsightEvidenceItem(
            label: 'Rasio arah',
            value: '${(features.downwardSwipeRatio * 100).toInt()}% ke bawah',
            iconName: 'arrow_downward_rounded',
          ));
        } else {
          evidencesList.add(InsightEvidenceItem(
            label: 'Rata-rata/sesi',
            value: '${features.averageSwipesPerSession.toStringAsFixed(0)} swipe',
            iconName: 'swipe_rounded',
          ));
        }
        evidencesList.add(InsightEvidenceItem(
          label: 'Total durasi',
          value: DurationFormatter.format(features.totalScrollingDurationMillis),
          iconName: 'timer_rounded',
        ));

        return InsightModel(
          id: 'scroll_${period}_${date.millisecondsSinceEpoch}',
          type: InsightType.scrolling,
          title: title,
          summary: summary,
          details: details,
          evidences: evidencesList,
          relatedApps: features.involvedApps,
          period: period,
          generatedAt: now,
          suggestedAction: detection.suggestedIntervention ??
              (isDownwardPattern ? 'Jeda Digital' : 'Mode Fokus'),
          priority: InsightPriority.high,
        );

      case DetectionType.nightScrollingPattern:
        final totalNight =
            features.nightSessionCount + features.diniHariSessionCount;
        return InsightModel(
          id: 'scroll_${period}_${date.millisecondsSinceEpoch}',
          type: InsightType.scrolling,
          title: 'Aktivitas scrolling pada malam hari',
          summary:
              'Aktivitas scrolling terpantau lebih banyak terkonsentrasi pada rentang waktu malam hari.',
          details:
              'Tercatat $totalNight sesi scrolling pada waktu malam dan dini hari '
              'berdasarkan catatan penggunaan.',
          evidences: [
            InsightEvidenceItem(
              label: 'Sesi malam',
              value: '${features.nightSessionCount} sesi',
              iconName: 'nights_stay_rounded',
            ),
            InsightEvidenceItem(
              label: 'Sesi dini hari',
              value: '${features.diniHariSessionCount} sesi',
              iconName: 'dark_mode_rounded',
            ),
            if (features.topScrollingApp != null)
              InsightEvidenceItem(
                label: 'Aplikasi utama',
                value: features.topScrollingApp!,
                iconName: 'apps_rounded',
              ),
          ],
          relatedApps: features.involvedApps,
          period: period,
          generatedAt: now,
          suggestedAction: detection.suggestedIntervention ?? 'Pengingat Istirahat',
          priority: InsightPriority.high,
        );

      case DetectionType.multiSignalScrollingPattern:
        return InsightModel(
          id: 'scroll_${period}_${date.millisecondsSinceEpoch}',
          type: InsightType.scrolling,
          title: 'Beberapa pola scrolling terdeteksi',
          summary:
              'Beberapa karakteristik penggunaan muncul bersamaan pada periode pemantauan.',
          details:
              'Kombinasi sesi berulang (${features.repeatedSessionCount} kali), '
              'durasi panjang (${DurationFormatter.format(features.longestSessionDurationMillis)}), '
              'dan ${features.totalSwipeCount} swipe navigasi tercatat secara bersamaan.',
          evidences: [
            InsightEvidenceItem(
              label: 'Sesi terpanjang',
              value: DurationFormatter.format(features.longestSessionDurationMillis),
              iconName: 'hourglass_top_rounded',
            ),
            InsightEvidenceItem(
              label: 'Total swipe',
              value: '${features.totalSwipeCount}',
              iconName: 'speed_rounded',
            ),
            InsightEvidenceItem(
              label: 'Sesi berulang',
              value: '${features.repeatedSessionCount} kali',
              iconName: 'replay_rounded',
            ),
          ],
          relatedApps: features.involvedApps,
          period: period,
          generatedAt: now,
          suggestedAction: detection.suggestedIntervention ?? 'Mode Fokus',
          priority: InsightPriority.high,
        );

      default:
        return InsightModel(
          id: 'scroll_${period}_${date.millisecondsSinceEpoch}',
          type: InsightType.scrolling,
          title: 'Pola scrolling terdeteksi',
          summary: 'Kecenderungan pola penggunaan aplikasi teramati pada periode ini.',
          details: detection.description,
          evidences: [
            InsightEvidenceItem(
              label: 'Total sesi',
              value: '${features.totalScrollingSessions} sesi',
              iconName: 'history_rounded',
            ),
            InsightEvidenceItem(
              label: 'Total swipe',
              value: '${features.totalSwipeCount}',
              iconName: 'swipe_rounded',
            ),
          ],
          relatedApps: features.involvedApps,
          period: period,
          generatedAt: now,
          suggestedAction: detection.suggestedIntervention ?? 'Jeda Digital',
          priority: InsightPriority.high,
        );
    }
  }

  // ===========================================================================
  // 2. USAGE PATTERN & SCREEN TIME INSIGHT
  // ===========================================================================
  InsightModel? _generateUsagePatternInsight({
    required BehavioralFeatures features,
    required int totalScreenTimeMillis,
    List<TimeSegmentUsage>? dailySegments,
    List<DayUsage>? weeklyDays,
    List<WeekUsage>? monthlyWeeks,
    String? topApp,
    required String period,
    required DateTime date,
  }) {
    final now = DateTime.now();
    final effectiveScreenTime = totalScreenTimeMillis > 0
        ? totalScreenTimeMillis
        : features.totalScreenTimeMillis;

    if (period == 'weekly' && weeklyDays != null && weeklyDays.isNotEmpty) {
      final daysWithData =
          weeklyDays.where((d) => d.screenTimeMillis > 0 || d.doomscrollMillis > 0).toList();
      if (daysWithData.isEmpty) return null;

      daysWithData.sort((a, b) => b.screenTimeMillis.compareTo(a.screenTimeMillis));
      final peakDay = daysWithData.first;

      return InsightModel(
        id: 'usage_weekly_${date.millisecondsSinceEpoch}',
        type: InsightType.usagePattern,
        title: 'Pola Penggunaan Mingguan',
        summary:
            'Pada minggu ini, sesi scrolling paling banyak tercatat pada hari ${peakDay.dayName}.',
        details:
            'Aktivitas layar tertinggi tercatat pada hari ${peakDay.dayName} '
            'dengan total waktu ${peakDay.screenTimeFormatted}.',
        evidences: [
          InsightEvidenceItem(
            label: 'Hari teraktif',
            value: peakDay.dayName,
            iconName: 'calendar_today_rounded',
          ),
          InsightEvidenceItem(
            label: 'Durasi hari puncak',
            value: peakDay.screenTimeFormatted,
            iconName: 'timer_rounded',
          ),
          if (peakDay.doomscrollSwipes > 0)
            InsightEvidenceItem(
              label: 'Swipe hari puncak',
              value: '${peakDay.doomscrollSwipes}',
              iconName: 'swipe_rounded',
            ),
        ],
        relatedApps: features.involvedApps,
        period: period,
        generatedAt: now,
        priority: InsightPriority.medium,
      );
    }

    if (period == 'monthly' && monthlyWeeks != null && monthlyWeeks.isNotEmpty) {
      final weeksWithData =
          monthlyWeeks.where((w) => w.screenTimeMillis > 0 || w.doomscrollMillis > 0).toList();
      if (weeksWithData.isEmpty) return null;

      weeksWithData.sort((a, b) => b.screenTimeMillis.compareTo(a.screenTimeMillis));
      final peakWeek = weeksWithData.first;

      return InsightModel(
        id: 'usage_monthly_${date.millisecondsSinceEpoch}',
        type: InsightType.usagePattern,
        title: 'Pola Penggunaan Bulanan',
        summary:
            'Akumulasi aktivitas penggunaan tertinggi tercatat pada ${peakWeek.label}.',
        details:
            'Pada bulan ini, durasi waktu layar terbanyak terkonsentrasi pada '
            '${peakWeek.label} (${peakWeek.screenTimeFormatted}).',
        evidences: [
          InsightEvidenceItem(
            label: 'Minggu teraktif',
            value: peakWeek.label,
            iconName: 'date_range_rounded',
          ),
          InsightEvidenceItem(
            label: 'Durasi minggu puncak',
            value: peakWeek.screenTimeFormatted,
            iconName: 'timer_rounded',
          ),
        ],
        relatedApps: features.involvedApps,
        period: period,
        generatedAt: now,
        priority: InsightPriority.medium,
      );
    }

    // Daily Usage Pattern
    if (dailySegments != null && dailySegments.isNotEmpty) {
      final segmentsWithData =
          dailySegments.where((s) => s.screenTimeMillis > 0 || s.doomscrollMillis > 0).toList();
      if (segmentsWithData.isNotEmpty) {
        segmentsWithData.sort((a, b) => (b.screenTimeMillis + b.doomscrollMillis)
            .compareTo(a.screenTimeMillis + a.doomscrollMillis));
        final peakSegment = segmentsWithData.first;

        return InsightModel(
          id: 'usage_daily_${date.millisecondsSinceEpoch}',
          type: InsightType.screenTime,
          title: 'Distribusi Waktu Layar',
          summary:
              'Aktivitas scrolling paling banyak tercatat pada ${peakSegment.label.toLowerCase()} hari.',
          details:
              'Total waktu layar aktif tercatat ${DurationFormatter.format(effectiveScreenTime)} '
              'dengan konsentrasi tertinggi pada periode ${peakSegment.label} (${peakSegment.timeRange}).',
          evidences: [
            InsightEvidenceItem(
              label: 'Total waktu layar',
              value: DurationFormatter.format(effectiveScreenTime),
              iconName: 'smartphone_rounded',
            ),
            InsightEvidenceItem(
              label: 'Periode teraktif',
              value: peakSegment.label,
              iconName: 'access_time_rounded',
            ),
            if (topApp != null && topApp.isNotEmpty)
              InsightEvidenceItem(
                label: 'Aplikasi terbanyak',
                value: topApp,
                iconName: 'apps_rounded',
              ),
          ],
          relatedApps: features.involvedApps,
          period: period,
          generatedAt: now,
          priority: InsightPriority.medium,
        );
      }
    }

    if (effectiveScreenTime > 0) {
      return InsightModel(
        id: 'screentime_${period}_${date.millisecondsSinceEpoch}',
        type: InsightType.screenTime,
        title: 'Total Waktu Layar',
        summary:
            'Total waktu layar aktif pada periode ini tercatat ${DurationFormatter.format(effectiveScreenTime)}.',
        details:
            'Data waktu layar diambil dari rekaman riil sistem pemantauan aplikasi.',
        evidences: [
          InsightEvidenceItem(
            label: 'Total waktu layar',
            value: DurationFormatter.format(effectiveScreenTime),
            iconName: 'smartphone_rounded',
          ),
          if (topApp != null && topApp.isNotEmpty)
            InsightEvidenceItem(
              label: 'Aplikasi terbanyak',
              value: topApp,
              iconName: 'apps_rounded',
            ),
        ],
        relatedApps: features.involvedApps,
        period: period,
        generatedAt: now,
        priority: InsightPriority.medium,
      );
    }

    return null;
  }

  // ===========================================================================
  // 3. EYE MONITORING INSIGHT
  // ===========================================================================
  InsightModel? _generateEyeInsight({
    EyeMonitoringSummary? eyeSummary,
    required String period,
    required DateTime date,
  }) {
    if (eyeSummary == null || !eyeSummary.hasData) return null;

    final now = DateTime.now();
    final isFatigueIndicated = eyeSummary.eyeClosureEvents >= 5 ||
        (eyeSummary.averageEar != null && eyeSummary.averageEar! < 0.22);

    if (isFatigueIndicated) {
      return InsightModel(
        id: 'eye_${period}_${date.millisecondsSinceEpoch}',
        type: InsightType.eyeMonitoring,
        title: 'Indikasi Mata Lelah',
        summary:
            'Terdapat indikasi mata mulai lelah berdasarkan parameter monitoring aplikasi.',
        details:
            'Parameter monitoring menunjukkan ${eyeSummary.eyeClosureEvents} kejadian '
            'penutupan mata selama ${DurationFormatter.format(eyeSummary.totalDurationMillis)} pemantauan.',
        evidences: [
          InsightEvidenceItem(
            label: 'Penutupan mata',
            value: '${eyeSummary.eyeClosureEvents} kali',
            iconName: 'visibility_off_rounded',
          ),
          InsightEvidenceItem(
            label: 'Kedipan mata',
            value: '${eyeSummary.blinkCount} kali',
            iconName: 'remove_red_eye_rounded',
          ),
          if (eyeSummary.averageEar != null)
            InsightEvidenceItem(
              label: 'Rata-rata EAR',
              value: eyeSummary.averageEar!.toStringAsFixed(2),
              iconName: 'analytics_rounded',
            ),
        ],
        period: period,
        generatedAt: now,
        suggestedAction: 'Istirahatkan Mata (Aturan 20-20-20)',
        priority: InsightPriority.medium,
      );
    }

    return InsightModel(
      id: 'eye_${period}_${date.millisecondsSinceEpoch}',
      type: InsightType.eyeMonitoring,
      title: 'Pemantauan Kondisi Mata',
      summary:
          'Parameter kedipan dan keterbukaan mata terpantau dalam rentang terukur.',
      details:
          'Tercatat ${eyeSummary.totalSessions} sesi pemantauan mata dengan total durasi '
          '${DurationFormatter.format(eyeSummary.totalDurationMillis)}.',
      evidences: [
        InsightEvidenceItem(
          label: 'Total sesi',
          value: '${eyeSummary.totalSessions} sesi',
          iconName: 'visibility_rounded',
        ),
        InsightEvidenceItem(
          label: 'Total kedipan',
          value: '${eyeSummary.blinkCount}',
          iconName: 'remove_red_eye_rounded',
        ),
      ],
      period: period,
      generatedAt: now,
      priority: InsightPriority.low,
    );
  }

  // ===========================================================================
  // 4. RECOMMENDATION INSIGHT
  // ===========================================================================
  InsightModel _generateRecommendationInsight({
    required DetectionResult detection,
    required String period,
    required DateTime date,
  }) {
    final now = DateTime.now();
    final action = detection.suggestedIntervention ?? 'Jeda Digital';

    return InsightModel(
      id: 'rec_${period}_${date.millisecondsSinceEpoch}',
      type: InsightType.recommendation,
      title: 'Saran Langkah Reflektif',
      summary:
          'Tersedia pilihan jeda untuk membantu menjaga kenyamanan digitalmu.',
      details:
          'Pilihan intervensi bersifat opsional dan sepenuhnya ditentukan oleh keputusanmu.',
      evidences: [
        InsightEvidenceItem(
          label: 'Saran tindakan',
          value: action,
          iconName: 'tips_and_updates_rounded',
        ),
      ],
      relatedApps: detection.relatedApps,
      period: period,
      generatedAt: now,
      suggestedAction: action,
      priority: InsightPriority.low,
    );
  }
}
