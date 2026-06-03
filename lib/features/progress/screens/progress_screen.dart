import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/atlas_widgets.dart';
import '../../../shared/mock_data.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  int _selectedTab = 1; // 0=Semana 1=Mes 2=Año
  int _selectedExerciseIndex = 0;

  static const _tabs = ['Semana', 'Mes', 'Año'];
  static const _exerciseOptions = [
    'Press Inclinado',
    'Press Banca',
    'Sentadilla',
    'Dominadas',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildTabs()),
            SliverToBoxAdapter(child: _buildWeightSection()),
            SliverToBoxAdapter(child: _buildStrengthSection()),
            SliverToBoxAdapter(child: _buildRecordsSection()),
            SliverToBoxAdapter(child: _buildHistorySection()),
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

  Widget _buildStrengthSection() {
    final strengthData = MockData.strengthHistory;
    final spots = strengthData.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AtlasSectionTitle(title: 'Progresión de fuerza'),
        // Exercise selector chips
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _exerciseOptions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final isActive = _selectedExerciseIndex == i;
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
                    _exerciseOptions[i],
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _exerciseOptions[_selectedExerciseIndex],
                          style: AppTextStyles.bodySmall,
                        ),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '72.5',
                                style: AppTextStyles.numericLarge,
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
                    AtlasBadge(
                      label: '+10.7%',
                      color: AppColors.success,
                      textColor: AppColors.success,
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
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                              '${rod.toY.toStringAsFixed(1)} kg',
                              AppTextStyles.bodySmall.copyWith(
                                color: AppColors.primaryLight,
                              ),
                            );
                          },
                        ),
                      ),
                      barGroups: strengthData.asMap().entries.map((e) {
                        final isLast = e.key == strengthData.length - 1;
                        return BarChartGroupData(
                          x: e.key,
                          barRods: [
                            BarChartRodData(
                              toY: e.value,
                              color: isLast ? AppColors.secondary : AppColors.primary.withOpacity(0.5),
                              width: 20,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
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

  Widget _buildRecordsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AtlasSectionTitle(title: 'Récords personales'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AtlasCard(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
            child: Column(
              children: MockData.records.asMap().entries.map((entry) {
                final i = entry.key;
                final r = entry.value;
                return Column(
                  children: [
                    if (i > 0) const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                i == 0 ? '🥇' : i == 1 ? '🥈' : i == 2 ? '🥉' : '${i + 1}',
                                style:  TextStyle(fontSize: i <= 2 ? 14 : 11),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.exercise, style: AppTextStyles.titleMedium),
                                Text(r.date, style: AppTextStyles.bodySmall),
                              ],
                            ),
                          ),
                          Text(
                            r.value,
                            style: AppTextStyles.titleMedium.copyWith(
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AtlasSectionTitle(title: 'Historial reciente'),
        ...MockData.history.map((w) {
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
                            Text(
                              '${w.sets} sets',
                              style: AppTextStyles.bodySmall,
                            ),
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
        }),
      ],
    );
  }
}
