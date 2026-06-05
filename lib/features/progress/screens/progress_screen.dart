import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/atlas_widgets.dart';
import '../../../shared/mock_data.dart';
import '../../workout/data/workout_session_store.dart';

// ─── Modelos de cómputo ────────────────────────────────────────────────────

class _ExerciseRecord {
  final String name;
  final double maxKg;
  final int reps;
  final DateTime date;
  const _ExerciseRecord({
    required this.name,
    required this.maxKg,
    required this.reps,
    required this.date,
  });
}

class _ExerciseProgress {
  final String name;
  final double pctGain;     // % de mejora de primera a última sesión
  final double firstKg;
  final double currentKg;
  final int sessionCount;
  const _ExerciseProgress({
    required this.name,
    required this.pctGain,
    required this.firstKg,
    required this.currentKg,
    required this.sessionCount,
  });
}

class _ProgressStats {
  final List<SavedWorkoutSession> sessions;

  _ProgressStats(this.sessions) {
    _prsBySession = _computePRs();
  }

  late final Map<DateTime, Set<String>> _prsBySession;

  Map<DateTime, Set<String>> _computePRs() {
    // Recorre cronológicamente (sessions está newest-first → reversed = oldest-first)
    final runningMax = <String, double>{};
    final result = <DateTime, Set<String>>{};
    for (final s in sessions.reversed) {
      final prs = <String>{};
      for (final e in s.exerciseStats) {
        if (e.maxKg <= 0) continue;
        if (e.maxKg > (runningMax[e.name] ?? 0)) {
          prs.add(e.name);
          runningMax[e.name] = e.maxKg;
        }
      }
      result[s.savedAt] = prs;
    }
    return result;
  }

  bool sessionHasPR(SavedWorkoutSession s) =>
      (_prsBySession[s.savedAt] ?? {}).isNotEmpty;

  Set<String> prExercisesIn(SavedWorkoutSession s) =>
      _prsBySession[s.savedAt] ?? {};

  bool get isEmpty => sessions.isEmpty;

  int get totalSessions => sessions.length;

  double get maxWeightLifted {
    double max = 0;
    for (final s in sessions) {
      for (final e in s.exerciseStats) {
        if (e.maxKg > max) max = e.maxKg;
      }
    }
    return max;
  }

  String get avgDuration {
    if (sessions.isEmpty) return '–';
    final avg = sessions.fold(0, (sum, s) => sum + s.durationSeconds) ~/
        sessions.length;
    return '${avg ~/ 60} min';
  }

  String get totalTime {
    final secs = sessions.fold(0, (sum, s) => sum + s.durationSeconds);
    final h = secs ~/ 3600;
    final m = (secs % 3600) ~/ 60;
    if (h == 0 && m == 0) return '0m';
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  List<_ExerciseRecord> get topRecords {
    final map = <String, _ExerciseRecord>{};
    for (final s in sessions) {
      for (final e in s.exerciseStats) {
        if (e.maxKg <= 0) continue;
        final prev = map[e.name];
        if (prev == null || e.maxKg > prev.maxKg) {
          map[e.name] = _ExerciseRecord(
            name: e.name,
            maxKg: e.maxKg,
            reps: e.repsAtMaxKg,
            date: s.savedAt,
          );
        }
      }
    }
    return (map.values.toList()..sort((a, b) => b.maxKg.compareTo(a.maxKg)))
        .take(5)
        .toList();
  }

  // Ranking de ejercicios por % de mejora (requiere ≥2 sesiones con ese ejercicio)
  List<_ExerciseProgress> get exerciseRanking {
    // Recoge lista cronológica de maxKg por ejercicio
    final map = <String, List<double>>{};
    for (final s in sessions.reversed) {
      for (final e in s.exerciseStats) {
        if (e.maxKg <= 0) continue;
        map.putIfAbsent(e.name, () => []).add(e.maxKg);
      }
    }
    final result = <_ExerciseProgress>[];
    for (final entry in map.entries) {
      if (entry.value.length < 2) continue;
      final first = entry.value.first;
      final current = entry.value.reduce((a, b) => a > b ? a : b);
      if (first <= 0) continue;
      result.add(_ExerciseProgress(
        name: entry.key,
        pctGain: (current - first) / first * 100,
        firstKg: first,
        currentKg: current,
        sessionCount: entry.value.length,
      ));
    }
    return result..sort((a, b) => b.pctGain.compareTo(a.pctGain));
  }

  List<String> get exerciseNames {
    final seen = <String>{};
    for (final s in sessions) {
      for (final e in s.exerciseStats) {
        if (e.maxKg > 0) seen.add(e.name);
      }
    }
    return seen.toList();
  }

  List<double> maxKgPerSession(String exercise) {
    return sessions.reversed
        .map((s) => s.exerciseStats
            .where((e) => e.name == exercise)
            .fold(0.0, (max, e) => e.maxKg > max ? e.maxKg : max))
        .where((v) => v > 0)
        .toList();
  }
}

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  int _selectedTab = 1; // 0=Semana 1=Mes 2=Año
  int _selectedExerciseIndex = 0;

  static const _tabs = ['Semana', 'Mes', 'Año'];
  static const _mockExerciseOptions = [
    'Press Inclinado', 'Press Banca', 'Sentadilla', 'Dominadas',
  ];

  @override
  Widget build(BuildContext context) {
    final stats = _ProgressStats(WorkoutSessionStore.sessions);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildTabs()),
            SliverToBoxAdapter(child: _buildSummaryStats(stats)),
            SliverToBoxAdapter(child: _buildWeightSection()),
            SliverToBoxAdapter(child: _buildStrengthSection(stats)),
            SliverToBoxAdapter(child: _buildRecordsSection(stats)),
            SliverToBoxAdapter(child: _buildProgressRankingSection(stats)),
            SliverToBoxAdapter(child: _buildHistorySection(stats)),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Text('Progreso', style: AppTextStyles.displayMedium),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF3F3F46), width: 0.5),
        ),
        child: Row(
          children: List.generate(_tabs.length, (i) {
            final isActive = _selectedTab == i;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedTab = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _tabs[i],
                    style: AppTextStyles.labelLarge.copyWith(
                      fontSize: 13,
                      color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildSummaryStats(_ProgressStats stats) {
    final items = [
      ('🏋️', 'Sesiones', '${stats.totalSessions}'),
      ('⚡', 'Peso máx.', stats.isEmpty ? '–' : '${stats.maxWeightLifted.toStringAsFixed(1)} kg'),
      ('⏱️', 'Duración media', stats.avgDuration),
      ('🕐', 'Tiempo total', stats.totalTime),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 2.2,
        children: items.map((item) {
          return AtlasCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Text(item.$1, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(item.$3,
                          style: AppTextStyles.titleMedium.copyWith(
                              color: AppColors.secondary)),
                      Text(item.$2, style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWeightSection() {
    final weights = MockData.weightHistory;
    final current = weights.last;
    final prev = weights[weights.length - 2];
    final diff = current - prev;
    final isUp = diff >= 0;

    final spots = weights.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AtlasSectionTitle(title: 'Peso corporal'),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: AtlasCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Actual', style: AppTextStyles.bodySmall),
                        const SizedBox(height: 2),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '${current.toStringAsFixed(1)}',
                                style: AppTextStyles.numericHero,
                              ),
                              TextSpan(
                                text: ' kg',
                                style: AppTextStyles.bodyLarge.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Tendencia', style: AppTextStyles.bodySmall),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                              color: isUp ? AppColors.success : AppColors.error,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${isUp ? '+' : ''}${diff.toStringAsFixed(1)} kg/sem',
                              style: AppTextStyles.titleMedium.copyWith(
                                color: isUp ? AppColors.success : AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 100,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (_) => AppColors.surface,
                          getTooltipItems: (spots) => spots.map((s) {
                            return LineTooltipItem(
                              '${s.y.toStringAsFixed(1)} kg',
                              AppTextStyles.bodySmall.copyWith(
                                color: AppColors.primaryLight,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: AppColors.primary,
                          barWidth: 2.5,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, _, __, i) {
                              final isLast = i == spots.length - 1;
                              return FlDotCirclePainter(
                                radius: isLast ? 5 : 3,
                                color: isLast ? AppColors.secondary : AppColors.primary,
                                strokeWidth: 0,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withOpacity(0.25),
                                AppColors.primary.withOpacity(0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                      minY: weights.reduce((a, b) => a < b ? a : b) - 1,
                      maxY: weights.reduce((a, b) => a > b ? a : b) + 1,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Abr', style: AppTextStyles.labelSmall),
                    Text('May', style: AppTextStyles.labelSmall),
                    Text(
                      'Jun',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStrengthSection(_ProgressStats stats) {
    final exerciseOptions = stats.isEmpty ? _mockExerciseOptions : stats.exerciseNames;
    final clampedIndex = _selectedExerciseIndex.clamp(0, exerciseOptions.isEmpty ? 0 : exerciseOptions.length - 1);
    final selectedExercise = exerciseOptions.isEmpty ? '' : exerciseOptions[clampedIndex];
    final barData = stats.isEmpty
        ? MockData.strengthHistory
        : stats.maxKgPerSession(selectedExercise);
    final currentMax = barData.isEmpty ? 0.0 : barData.last;
    final prevMax = barData.length > 1 ? barData[barData.length - 2] : currentMax;
    final pct = prevMax > 0 ? ((currentMax - prevMax) / prevMax * 100) : 0.0;
    final pctLabel = pct >= 0 ? '+${pct.toStringAsFixed(1)}%' : '${pct.toStringAsFixed(1)}%';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AtlasSectionTitle(title: 'Progresión de fuerza'),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: exerciseOptions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final isActive = clampedIndex == i;
              return GestureDetector(
                onTap: () => setState(() => _selectedExerciseIndex = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary.withOpacity(0.25) : AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive ? AppColors.primary : const Color(0xFF3F3F46),
                      width: isActive ? 1.5 : 0.5,
                    ),
                  ),
                  child: Text(
                    exerciseOptions[i],
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isActive ? AppColors.primaryLight : AppColors.textSecondary,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AtlasCard(
            child: barData.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text('Sin datos para este ejercicio',
                          style: AppTextStyles.bodySmall),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(selectedExercise, style: AppTextStyles.bodySmall),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: currentMax.toStringAsFixed(1),
                                      style: AppTextStyles.numericLarge,
                                    ),
                                    TextSpan(
                                      text: ' kg',
                                      style: AppTextStyles.bodyLarge.copyWith(
                                          color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          if (barData.length > 1)
                            AtlasBadge(
                              label: pctLabel,
                              color: pct >= 0 ? AppColors.success : AppColors.error,
                              textColor: pct >= 0 ? AppColors.success : AppColors.error,
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 90,
                        child: BarChart(
                          BarChartData(
                            gridData: const FlGridData(show: false),
                            titlesData: const FlTitlesData(show: false),
                            borderData: FlBorderData(show: false),
                            barTouchData: BarTouchData(
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipColor: (_) => AppColors.surface,
                                getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                                  '${rod.toY.toStringAsFixed(1)} kg',
                                  AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.primaryLight),
                                ),
                              ),
                            ),
                            barGroups: barData.asMap().entries.map((e) {
                              final isLast = e.key == barData.length - 1;
                              return BarChartGroupData(
                                x: e.key,
                                barRods: [
                                  BarChartRodData(
                                    toY: e.value,
                                    color: isLast
                                        ? AppColors.secondary
                                        : AppColors.primary.withOpacity(0.5),
                                    width: 20,
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(6)),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecordsSection(_ProgressStats stats) {
    final records = stats.isEmpty ? null : stats.topRecords;
    final useMock = records == null || records.isEmpty;

    Widget buildRow(int i, String exercise, String value, String date) {
      return Column(
        children: [
          if (i > 0) const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      i == 0 ? '🥇' : i == 1 ? '🥈' : i == 2 ? '🥉' : '${i + 1}',
                      style: TextStyle(fontSize: i <= 2 ? 14 : 11),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(exercise, style: AppTextStyles.titleMedium),
                      Text(date, style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
                Text(value,
                    style: AppTextStyles.titleMedium
                        .copyWith(color: AppColors.secondary)),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AtlasSectionTitle(
          title: useMock ? 'Récords personales (demo)' : 'Récords personales',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AtlasCard(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
            child: Column(
              children: useMock
                  ? MockData.records.asMap().entries.map((entry) {
                      final r = entry.value;
                      return buildRow(entry.key, r.exercise, r.value, r.date);
                    }).toList()
                  : records.asMap().entries.map((entry) {
                      final i = entry.key;
                      final r = entry.value;
                      final value = '${r.maxKg.toStringAsFixed(1)} kg × ${r.reps}';
                      final date = _formatDate(r.date);
                      return buildRow(i, r.name, value, date);
                    }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressRankingSection(_ProgressStats stats) {
    final ranking = stats.exerciseRanking;
    if (ranking.isEmpty) return const SizedBox.shrink();

    final maxPct = ranking.first.pctGain;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AtlasSectionTitle(title: 'Mayor progreso histórico'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AtlasCard(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Column(
              children: ranking.take(5).toList().asMap().entries.map((entry) {
                final i = entry.key;
                final p = entry.value;
                final barWidth = maxPct > 0 ? (p.pctGain / maxPct).clamp(0.0, 1.0) : 0.0;
                final pctLabel = p.pctGain >= 0
                    ? '+${p.pctGain.toStringAsFixed(1)}%'
                    : '${p.pctGain.toStringAsFixed(1)}%';
                return Column(
                  children: [
                    if (i > 0) const SizedBox(height: 12),
                    Row(
                      children: [
                        SizedBox(
                          width: 20,
                          child: Text(
                            i == 0 ? '🥇' : i == 1 ? '🥈' : i == 2 ? '🥉' : '${i + 1}.',
                            style: TextStyle(fontSize: i <= 2 ? 13 : 11),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      p.name,
                                      style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.textPrimary),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    pctLabel,
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: p.pctGain >= 0
                                          ? AppColors.success
                                          : AppColors.error,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: barWidth,
                                  minHeight: 5,
                                  backgroundColor: AppColors.surface,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    i == 0 ? AppColors.secondary : AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${p.firstKg.toStringAsFixed(1)} → ${p.currentKg.toStringAsFixed(1)} kg  ·  ${p.sessionCount} sesiones',
                                style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistorySection(_ProgressStats stats) {
    final realSessions = WorkoutSessionStore.sessions;
    final useMock = realSessions.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AtlasSectionTitle(
          title: useMock ? 'Historial reciente (demo)' : 'Historial reciente',
        ),
        if (useMock)
          ...MockData.history.map((w) => _buildMockHistoryCard(w))
        else
          ...realSessions.take(10).map((s) => _buildRealHistoryCard(s, stats)),
      ],
    );
  }

  Widget _buildMockHistoryCard(MockWorkoutHistory w) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: AtlasCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(w.date, style: AppTextStyles.bodySmall),
                  const SizedBox(height: 2),
                  Text(w.day, style: AppTextStyles.titleMedium),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(w.duration, style: AppTextStyles.bodySmall),
                      const SizedBox(width: 12),
                      Text(w.volume, style: AppTextStyles.bodySmall),
                      const SizedBox(width: 12),
                      Text('${w.sets} sets', style: AppTextStyles.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
            Text(w.feeling, style: const TextStyle(fontSize: 28)),
          ],
        ),
      ),
    );
  }

  Widget _buildRealHistoryCard(SavedWorkoutSession s, _ProgressStats stats) {
    final duration = _formatDuration(s.durationSeconds);
    final volume = s.totalVolume >= 1000
        ? '${(s.totalVolume / 1000).toStringAsFixed(1)}t'
        : '${s.totalVolume.toStringAsFixed(0)} kg';
    final date = _formatDate(s.savedAt);
    final hasPR = stats.sessionHasPR(s);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: AtlasCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(date, style: AppTextStyles.bodySmall),
                      if (hasPR) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: AppColors.secondary.withOpacity(0.4)),
                          ),
                          child: Text(
                            '🏆 PR',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.secondary,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(s.dayName, style: AppTextStyles.titleMedium),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(duration, style: AppTextStyles.bodySmall),
                      const SizedBox(width: 12),
                      Text(volume, style: AppTextStyles.bodySmall),
                      const SizedBox(width: 12),
                      Text(
                        '${s.completedSets} sets',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              s.feeling ?? '😐',
              style: const TextStyle(fontSize: 28),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  static String _formatDate(DateTime dt) {
    const dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    const meses = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${dias[dt.weekday - 1]} ${dt.day} ${meses[dt.month - 1]}';
  }
}
