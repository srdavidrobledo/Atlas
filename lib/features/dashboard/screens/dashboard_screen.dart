import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/router/route_names.dart';
import '../../../shared/widgets/atlas_widgets.dart';
import '../../../shared/mock_data.dart';
import '../../workout/data/workout_session_store.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WorkoutSessionStore.onActiveDayChanged = () {
      if (mounted) setState(() {});
    };
  }

  @override
  void dispose() {
    WorkoutSessionStore.onActiveDayChanged = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _Header()),
            SliverToBoxAdapter(child: _GoalCard()),
            SliverToBoxAdapter(child: _StatsRow()),
            SliverToBoxAdapter(child: _AchievementsSection()),
            SliverToBoxAdapter(child: _NextWorkoutCard(context)),
            SliverToBoxAdapter(child: _InsightsSection()),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  Widget _Header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Buenos días 👋',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(MockUser.name, style: AppTextStyles.displayMedium),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.secondary.withOpacity(0.25),
              ),
            ),
            child: Text(
              MockUser.goal,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.secondary,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _GoalCard() {
    final progress = (MockUser.currentWeight - 77) / (MockUser.targetWeight - 77);
    final remaining = MockUser.targetWeight - MockUser.currentWeight;
    final percent = (progress.clamp(0.0, 1.0) * 100).round();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: AtlasCard(
        gradient: AppColors.cardGradient,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PROGRESO HACIA TU OBJETIVO',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.primaryLight,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Peso actual',
                      style: AppTextStyles.bodySmall,
                    ),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text:
                                '${MockUser.currentWeight.toStringAsFixed(1)}',
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
                    Text('Meta', style: AppTextStyles.bodySmall),
                    Text(
                      '${MockUser.targetWeight.toStringAsFixed(0)} kg',
                      style: AppTextStyles.numericLarge.copyWith(
                        color: AppColors.primaryLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            AtlasProgressBar(value: progress, height: 8),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$percent% completado',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.success,
                  ),
                ),
                Text(
                  '${remaining.toStringAsFixed(1)} kg restantes',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primaryLight,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _StatsRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: AtlasCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Esta semana', style: AppTextStyles.labelSmall),
                  const SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${MockStats.weekSessions}',
                          style: AppTextStyles.numericLarge.copyWith(
                            color: AppColors.secondary,
                          ),
                        ),
                        TextSpan(
                          text: ' / ${MockUser.weeklyDays}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'entrenamientos',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AtlasCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Este mes', style: AppTextStyles.labelSmall),
                  const SizedBox(height: 8),
                  Text(
                    MockStats.totalHours,
                    style: AppTextStyles.numericLarge.copyWith(
                      color: AppColors.primaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'horas entrenadas',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _AchievementsSection() {
    final items = [
      _AchievementData('🏆', 'Nuevo récord', 'Press Inclinado\n72.5 kg × 4'),
      _AchievementData('📈', 'Más volumen', '+12%\nvs semana anterior'),
      _AchievementData('🔥', 'Constancia', '${MockStats.streak} sem. consecutivas'),
      _AchievementData('⚡', 'Esta semana', '${MockStats.weekSessions} de ${MockUser.weeklyDays} días'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AtlasSectionTitle(title: 'Logros recientes'),
        SizedBox(
          height: 124,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final a = items[i];
              return AtlasCard(
                padding: const EdgeInsets.all(14),
                child: SizedBox(
                  width: 130,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.emoji, style: const TextStyle(fontSize: 22)),
                      const SizedBox(height: 6),
                      Text(
                        a.title,
                        style: AppTextStyles.labelSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        a.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textPrimary,
                          height: 1.3,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _NextWorkoutCard(BuildContext context) {
    final day = WorkoutSessionStore.activeDay;
    final routine = WorkoutSessionStore.activeRoutine;
    final exerciseCount = day.exerciseCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AtlasSectionTitle(title: 'Próximo entrenamiento'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AtlasCard(
            gradient: AppColors.cardGradient,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AtlasBadge(
                      label: 'HOY',
                      color: AppColors.success,
                      textColor: AppColors.success,
                    ),
                    const Spacer(),
                    Text(
                      routine.name,
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  day.name,
                  style: AppTextStyles.titleLarge,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _NextStat(
                      Icons.fitness_center_rounded,
                      exerciseCount > 0
                          ? '$exerciseCount ejercicios'
                          : 'Sin ejercicios',
                    ),
                    const SizedBox(width: 16),
                    _NextStat(Icons.timer_outlined, '~55 min'),
                  ],
                ),
                const SizedBox(height: 16),
                AtlasButton(
                  label: 'ENTRENAR',
                  variant: AtlasButtonVariant.accent,
                  icon: Icons.play_arrow_rounded,
                  onTap: () => context.go(RouteNames.workout),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _NextStat(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.bodySmall),
      ],
    );
  }

  Widget _InsightsSection() {
    final insights = [
      _InsightData(
        '📊',
        'Tu mejor ejercicio este mes fue **Press Inclinado**. Progresaste +7.5 kg en 4 semanas.',
      ),
      _InsightData(
        '🔥',
        'Llevas **${MockStats.streak} semanas consecutivas** entrenando. Vas camino a tu mejor racha.',
      ),
      _InsightData(
        '🏋️',
        'El volumen total de esta semana fue **+12%** respecto a la semana anterior.',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AtlasSectionTitle(title: 'Insights'),
        ...insights.map(
          (i) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: AtlasCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(i.emoji, style: const TextStyle(fontSize: 17)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _RichInsightText(i.text),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RichInsightText extends StatelessWidget {
  final String text;
  const _RichInsightText(this.text);

  @override
  Widget build(BuildContext context) {
    final spans = <TextSpan>[];
    final parts = text.split('**');
    for (var i = 0; i < parts.length; i++) {
      spans.add(TextSpan(
        text: parts[i],
        style: i % 2 == 1
            ? AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              )
            : AppTextStyles.bodySmall.copyWith(fontSize: 13),
      ));
    }
    return RichText(
      text: TextSpan(children: spans),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _AchievementData {
  final String emoji;
  final String title;
  final String subtitle;
  const _AchievementData(this.emoji, this.title, this.subtitle);
}

class _InsightData {
  final String emoji;
  final String text;
  const _InsightData(this.emoji, this.text);
}
