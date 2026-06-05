import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/router/route_names.dart';
import '../../../shared/widgets/atlas_widgets.dart';
import '../data/workout_session_store.dart';

class WorkoutSummaryScreen extends StatefulWidget {
  const WorkoutSummaryScreen({super.key});

  @override
  State<WorkoutSummaryScreen> createState() => _WorkoutSummaryScreenState();
}

class _WorkoutSummaryScreenState extends State<WorkoutSummaryScreen> {
  int? _selectedFeeling;
  final _notesController = TextEditingController();

  // Snapshot inmutable tomado al entrar — captura datos y destacado
  // antes de que saveSession() limpie activeSession.
  late final _SessionSnapshot _snapshot;

  static const _feelings = [
    _FeelingOption('😀', 'Excelente', AppColors.success),
    _FeelingOption('🙂', 'Bien', Color(0xFF84CC16)),
    _FeelingOption('😐', 'Normal', AppColors.secondary),
    _FeelingOption('😕', 'Cansado', AppColors.warning),
    _FeelingOption('😫', 'Agotado', AppColors.error),
  ];

  @override
  void initState() {
    super.initState();
    final session = WorkoutSessionStore.activeSession;
    _snapshot = session != null
        ? _SessionSnapshot.fromActive(session)
        : _SessionSnapshot.empty();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveAndExit() async {
    final feelingEmoji =
        _selectedFeeling != null ? _feelings[_selectedFeeling!].emoji : null;
    await WorkoutSessionStore.saveSession(
      feeling: feelingEmoji,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );
    if (mounted) context.go(RouteNames.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHero()),
            SliverToBoxAdapter(child: _buildStats()),
            SliverToBoxAdapter(child: _buildProgressHighlight()),
            SliverToBoxAdapter(child: _buildFeelingSection()),
            SliverToBoxAdapter(child: _buildNotesSection()),
            SliverToBoxAdapter(child: _buildSaveButton()),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  // ─── Hero ────────────────────────────────────────────────────────────

  Widget _buildHero() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 28),
      decoration: const BoxDecoration(
        gradient: AppColors.cardGradient,
        border: Border(
          bottom: BorderSide(color: Color(0xFF3D2260), width: 0.5),
        ),
      ),
      child: Column(
        children: [
          const Text('🏆', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 12),
          Text(
            '¡Entrenamiento completado!',
            style: AppTextStyles.displayMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            '${_snapshot.dayName} · ${_snapshot.dateLabel}',
            style:
                AppTextStyles.bodyMedium.copyWith(color: AppColors.primaryLight),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ─── Stats ───────────────────────────────────────────────────────────

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Row(
        children: [
          _StatCard(value: _snapshot.durationLabel, label: 'DURACIÓN'),
          const SizedBox(width: 10),
          _StatCard(value: '${_snapshot.completedSets}', label: 'SERIES'),
          const SizedBox(width: 10),
          _StatCard(value: _snapshot.maxWeightLabel, label: 'PESO MÁX'),
        ],
      ),
    );
  }

  // ─── Destacado de progreso ────────────────────────────────────────────

  Widget _buildProgressHighlight() {
    final h = _snapshot.highlight;
    if (h == null) return const SizedBox.shrink();

    final isFirst = h.improvementPercent == null;
    final pct = h.improvementPercent ?? 0;
    final isImproved = pct > 0;
    final isNeutral = pct == 0;

    // Color e ícono según resultado
    final Color accentColor;
    final String badge;
    if (isFirst) {
      accentColor = AppColors.primaryLight;
      badge = '🆕  PRIMERA REFERENCIA';
    } else if (isImproved) {
      accentColor = AppColors.success;
      badge = '🏆  MAYOR PROGRESO DE HOY';
    } else if (isNeutral) {
      accentColor = AppColors.secondary;
      badge = '📊  MAYOR PROGRESO DE HOY';
    } else {
      accentColor = AppColors.warning;
      badge = '📊  MAYOR PROGRESO DE HOY';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accentColor.withValues(alpha: 0.28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badge,
                style: AppTextStyles.labelSmall.copyWith(
                  color: accentColor,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Nombre del ejercicio
            Text(h.exerciseName, style: AppTextStyles.titleMedium),
            const SizedBox(height: 6),

            if (isFirst) ...[
              Text(
                'Primera referencia registrada',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                '${_kgLabel(h.currentKg)} × ${h.currentReps} reps',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
            ] else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(1)}%',
                    style: AppTextStyles.numericLarge.copyWith(
                      fontSize: 28,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${_kgLabel(h.currentKg)} × ${h.currentReps} reps',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Feeling ─────────────────────────────────────────────────────────

  Widget _buildFeelingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AtlasSectionTitle(title: '¿Cómo te sentiste hoy?'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AtlasCard(
            child: Row(
              children: List.generate(_feelings.length, (i) {
                final f = _feelings[i];
                final isSelected = _selectedFeeling == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedFeeling = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: EdgeInsets.only(right: i < 4 ? 6 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? f.color.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? f.color.withValues(alpha: 0.5)
                              : Colors.transparent,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            f.emoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            f.label,
                            style: AppTextStyles.labelSmall.copyWith(
                              fontSize: 9,
                              color: isSelected
                                  ? f.color
                                  : AppColors.textDisabled,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Notas ───────────────────────────────────────────────────────────

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AtlasSectionTitle(title: 'Notas opcionales'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _notesController,
            maxLines: 3,
            style: AppTextStyles.bodyMedium,
            decoration: const InputDecoration(
              hintText: '¿Algo que destacar de la sesión?',
            ),
          ),
        ),
      ],
    );
  }

  // ─── Guardar ─────────────────────────────────────────────────────────

  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: AtlasButton(
        label: 'GUARDAR Y SALIR',
        variant: AtlasButtonVariant.accent,
        onTap: _saveAndExit,
      ),
    );
  }

  // ─── Helper ──────────────────────────────────────────────────────────

  String _kgLabel(double kg) =>
      kg == kg.roundToDouble() ? '${kg.toInt()} kg' : '${kg} kg';
}

// ─── Snapshot inmutable de la sesión ──────────────────────────────────────

class _SessionSnapshot {
  final String dayName;
  final String dateLabel;
  final int completedSets;
  final int durationSeconds;
  final double totalVolume;
  final double maxWeightLifted;
  final SessionHighlight? highlight;

  const _SessionSnapshot({
    required this.dayName,
    required this.dateLabel,
    required this.completedSets,
    required this.durationSeconds,
    required this.totalVolume,
    required this.maxWeightLifted,
    required this.highlight,
  });

  factory _SessionSnapshot.fromActive(ActiveWorkoutSession s) {
    return _SessionSnapshot(
      dayName: s.dayName,
      dateLabel: _formatDate(s.startedAt),
      completedSets: s.completedSets,
      durationSeconds: s.elapsedSeconds,
      totalVolume: s.totalVolume,
      maxWeightLifted: s.maxWeightLifted,
      highlight: WorkoutSessionStore.computeHighlight(s),
    );
  }

  factory _SessionSnapshot.empty() {
    return _SessionSnapshot(
      dayName: '—',
      dateLabel: _formatDate(DateTime.now()),
      completedSets: 0,
      durationSeconds: 0,
      totalVolume: 0,
      maxWeightLifted: 0,
      highlight: null,
    );
  }

  String get durationLabel {
    final m = (durationSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (durationSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String get volumeLabel {
    if (totalVolume >= 1000) {
      return '${(totalVolume / 1000).toStringAsFixed(1)}t';
    }
    return '${totalVolume.toStringAsFixed(0)} kg';
  }

  String get maxWeightLabel {
    if (maxWeightLifted <= 0) return '—';
    return maxWeightLifted == maxWeightLifted.roundToDouble()
        ? '${maxWeightLifted.toInt()} kg'
        : '${maxWeightLifted} kg';
  }

  static String _formatDate(DateTime dt) {
    const dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    const meses = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    final dia = dias[dt.weekday - 1];
    final mes = meses[dt.month - 1];
    return '$dia ${dt.day} $mes';
  }
}

// ─── Widgets locales ───────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String value;
  final String label;

  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AtlasCard(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        child: Column(
          children: [
            Text(
              value,
              style: AppTextStyles.numericLarge.copyWith(fontSize: 22),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(fontSize: 9),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _FeelingOption {
  final String emoji;
  final String label;
  final Color color;
  const _FeelingOption(this.emoji, this.label, this.color);
}
