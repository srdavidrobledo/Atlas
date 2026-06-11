import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/atlas_widgets.dart';
import '../../../features/routines/data/routine_store.dart';
import '../data/onboarding_store.dart';
import '../generators/atlas_routine_generator.dart';
import '../models/onboarding_models.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;
  static const int _totalSteps = 4;

  final _nameController = TextEditingController();
  String _goal = 'Ganar músculo';
  int _trainingDays = 3;
  String _experience = 'Intermedio';

  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _canAdvance => switch (_step) {
        0 => _nameController.text.trim().isNotEmpty,
        _ => true,
      };

  Future<void> _finish() async {
    setState(() => _saving = true);
    final data = OnboardingData(
      userName: _nameController.text.trim(),
      goal: _goal,
      trainingDays: _trainingDays,
      experience: _experience,
    );
    await OnboardingStore.complete(data);
    final alreadyGenerated =
        RoutineStore.all.any((r) => r.id.startsWith('r_atlas_'));
    if (!alreadyGenerated) {
      final generated = AtlasRoutineGenerator.generate(data);
      await RoutineStore.addRoutine(generated);
      RoutineStore.activateRoutine(generated.id);
    }
    if (mounted) context.go(RouteNames.dashboard);
  }

  void _next() {
    if (_step < _totalSteps - 1) {
      setState(() => _step++);
    } else {
      _finish();
    }
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildProgressBar(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.04, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(
                  key: ValueKey(_step),
                  child: _buildStep(),
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Paso ${_step + 1} de $_totalSteps',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                '${((_step + 1) / _totalSteps * 100).toInt()}%',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.primaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AtlasProgressBar(
            value: (_step + 1) / _totalSteps,
            height: 4,
            color: AppColors.primaryLight,
          ),
        ],
      ),
    );
  }

  Widget _buildStep() => switch (_step) {
        0 => _buildNameStep(),
        1 => _buildGoalStep(),
        2 => _buildDaysStep(),
        3 => _buildExperienceStep(),
        _ => const SizedBox.shrink(),
      };

  // ── Paso 1 — Nombre ────────────────────────────────────────────────────────

  Widget _buildNameStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('¿Cómo te\nllamás?', style: AppTextStyles.displayMedium),
          const SizedBox(height: 10),
          Text(
            'Así podremos personalizar tu experiencia.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 40),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF3F3F46), width: 0.5),
            ),
            child: TextField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              style: AppTextStyles.titleLarge,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                border: InputBorder.none,
                hintText: 'Tu nombre',
                hintStyle: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.textDisabled,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Paso 2 — Objetivo ──────────────────────────────────────────────────────

  static final _goals = [
    ('Ganar músculo',         Icons.fitness_center_rounded),
    ('Perder grasa',          Icons.local_fire_department_rounded),
    ('Ganar fuerza',          Icons.sports_gymnastics_rounded),
    ('Mejorar salud',         Icons.favorite_rounded),
    ('Rendimiento deportivo', Icons.directions_run_rounded),
  ];

  Widget _buildGoalStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('¿Cuál es tu\nobjetivo?', style: AppTextStyles.displayMedium),
          const SizedBox(height: 10),
          Text(
            'Podés cambiarlo en cualquier momento desde tu perfil.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          ..._goals.map((g) {
            final isSelected = _goal == g.$1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => setState(() => _goal = g.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.18)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryLight
                          : const Color(0xFF3F3F46),
                      width: isSelected ? 1.5 : 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        g.$2,
                        size: 24,
                        color: isSelected
                            ? AppColors.primaryLight
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          g.$1,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: isSelected
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 20,
                          color: AppColors.primaryLight,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Paso 3 — Días por semana ───────────────────────────────────────────────

  Widget _buildDaysStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('¿Cuántos días\nentrenas?', style: AppTextStyles.displayMedium),
          const SizedBox(height: 10),
          Text(
            'Días por semana en promedio.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 48),
          AtlasNumberPicker(
            value: _trainingDays.toDouble(),
            step: 1,
            min: 2,
            max: 7,
            unit: 'días',
            onChanged: (v) => setState(() => _trainingDays = v.toInt()),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              _daysHint(_trainingDays),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _daysHint(int days) => switch (days) {
        2 => 'Ideal para comenzar o volver al ritmo',
        3 => 'El punto dulce para la mayoría',
        4 => 'Buena frecuencia para progresar',
        5 => 'Alta frecuencia — requiere buena recuperación',
        6 => 'Frecuencia alta — requiere buena recuperación',
        7 => 'Frecuencia máxima — atletas avanzados',
        _ => '',
      };

  // ── Paso 4 — Experiencia ───────────────────────────────────────────────────

  static final _experiences = [
    ('Principiante', 'Menos de 1 año entrenando', Icons.star_outline_rounded),
    ('Intermedio', '1 a 3 años entrenando', Icons.trending_up_rounded),
    ('Avanzado', 'Más de 3 años entrenando', Icons.military_tech_rounded),
  ];

  Widget _buildExperienceStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('¿Cuánta experiencia\ntenés?', style: AppTextStyles.displayMedium),
          const SizedBox(height: 10),
          Text(
            'Esto ayuda a calibrar las sugerencias de entrenamiento.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          ..._experiences.map((e) {
            final isSelected = _experience == e.$1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => setState(() => _experience = e.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.18)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryLight
                          : const Color(0xFF3F3F46),
                      width: isSelected ? 1.5 : 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        e.$3,
                        size: 24,
                        color: isSelected
                            ? AppColors.primaryLight
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.$1,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: isSelected
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              e.$2,
                              style: AppTextStyles.bodySmall.copyWith(
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 20,
                          color: AppColors.primaryLight,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Barra inferior ─────────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    final isLast = _step == _totalSteps - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(color: Color(0xFF3F3F46), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          if (_step > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _back,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 52),
                ),
                child: const Text('Anterior'),
              ),
            ),
          if (_step > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: (_canAdvance && !_saving) ? _next : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: isLast
                    ? AppColors.secondary
                    : AppColors.primary,
                foregroundColor: isLast ? Colors.black : Colors.white,
                minimumSize: const Size(0, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      isLast ? 'Comenzar' : 'Siguiente',
                      style: AppTextStyles.labelLarge,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
