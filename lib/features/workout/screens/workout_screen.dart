import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_names.dart';
import '../../../core/storage/atlas_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/mock_data.dart';
import '../../../shared/widgets/atlas_widgets.dart';
import '../data/workout_session_store.dart';

enum _WorkoutPhase { preStart, active, resting }

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  late ActiveWorkoutSession _session;

  int _elapsedSeconds = 0;
  Timer? _sessionTimer;

  int _restSeconds = 0;
  int _restTotal = 90;
  Timer? _restTimer;
  bool _restFinished = false;

  int _currentExerciseIndex = 0;
  int _currentSetIndex = 0;
  double _currentKg = 0;
  int _currentReps = 1;
  int? _currentRir;
  double _weightStep = 2.5;
  _WorkoutPhase _phase = _WorkoutPhase.preStart;
  bool _inDayView = true;

  SessionExercise get _currentExercise => _session.exercises[_currentExerciseIndex];

  SessionSet get _currentSet => _currentExercise.sets[_currentSetIndex];

  bool get _isResting => _phase == _WorkoutPhase.resting;

  bool get _hasStarted => _phase != _WorkoutPhase.preStart || _elapsedSeconds > 0;

  int get _completedExercises {
    return _session.exercises.where((exercise) {
      return exercise.targetSets > 0 && exercise.completedSets == exercise.targetSets;
    }).length;
  }

  int get _pendingExercises => _session.exerciseCount - _completedExercises;

  int get _currentSetNumber {
    if (_currentExercise.sets.isEmpty) return 0;
    return (_currentSetIndex + 1).clamp(1, _currentExercise.targetSets);
  }

  @override
  void initState() {
    super.initState();
    _session = WorkoutSessionStore.ensureSession();
    _elapsedSeconds = _session.elapsedSeconds;
    _restTotal = (AtlasStorage.settings.get('rest_total') as int?) ?? 90;
    _weightStep = (AtlasStorage.settings.get('weight_step') as double?) ?? 2.5;
    if (_session.started) {
      _phase = _WorkoutPhase.active;
      _inDayView = false;
      _startSessionTimer();
    }
    _syncToNextPendingSet();
  }

  void _startWorkout() {
    _session.started = true;
    setState(() {
      _phase = _WorkoutPhase.active;
      _inDayView = false;
    });
    _startSessionTimer();
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _elapsedSeconds++);
        _session.elapsedSeconds = _elapsedSeconds;
      }
    });
  }

  void _startRestTimer() {
    _restTimer?.cancel();
    setState(() {
      _phase = _WorkoutPhase.resting;
      _restFinished = false;
      _restSeconds = _restTotal;
    });

    _restTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_restSeconds > 0) {
          _restSeconds--;
        } else {
          _restFinished = true;
          _restTimer?.cancel();
          HapticFeedback.vibrate();
        }
      });
    });
  }

  void _skipRest() {
    _restTimer?.cancel();
    setState(() {
      _restSeconds = 0;
      _restFinished = true;
    });
  }

  void _readyAfterRest() {
    setState(() {
      _phase = _WorkoutPhase.active;
      _restFinished = false;
      _restSeconds = 0;
    });
  }

  void _setRestTotal(int seconds) {
    setState(() {
      _restTotal = seconds;
      if (_isResting && !_restFinished && _restSeconds > seconds) {
        _restSeconds = seconds;
      }
    });
  }

  void _syncToNextPendingSet() {
    for (var exerciseIndex = 0; exerciseIndex < _session.exercises.length; exerciseIndex++) {
      final exercise = _session.exercises[exerciseIndex];
      for (var setIndex = 0; setIndex < exercise.sets.length; setIndex++) {
        if (!exercise.sets[setIndex].done) {
          _currentExerciseIndex = exerciseIndex;
          _currentSetIndex = setIndex;
          _loadCurrentSetValues();
          return;
        }
      }
    }

    _currentExerciseIndex = (_session.exercises.length - 1).clamp(0, _session.exercises.length);
    _currentSetIndex = (_currentExercise.sets.length - 1).clamp(0, _currentExercise.sets.length);
    _loadCurrentSetValues();
  }

  // Navegación explícita por tap — busca el primer set pendiente dentro del ejercicio indicado
  // sin sobreescribir con el primer pendiente global.
  void _jumpToExercise(int exerciseIndex) {
    final exercise = _session.exercises[exerciseIndex];
    _currentExerciseIndex = exerciseIndex;

    for (var setIndex = 0; setIndex < exercise.sets.length; setIndex++) {
      if (!exercise.sets[setIndex].done) {
        _currentSetIndex = setIndex;
        _loadCurrentSetValues();
        return;
      }
    }

    // Todos los sets completados: apuntar al último set del ejercicio
    _currentSetIndex = (exercise.sets.length - 1).clamp(0, exercise.sets.length);
    _loadCurrentSetValues();
  }

  void _goToExercise(int exerciseIndex) {
    setState(() {
      _jumpToExercise(exerciseIndex);
      _inDayView = false;
    });
  }

  void _backToDayView() {
    setState(() => _inDayView = true);
  }

  bool _moveToNextPendingSet() {
    for (var exerciseIndex = _currentExerciseIndex; exerciseIndex < _session.exercises.length; exerciseIndex++) {
      final exercise = _session.exercises[exerciseIndex];
      final startSet = exerciseIndex == _currentExerciseIndex ? _currentSetIndex + 1 : 0;
      for (var setIndex = startSet; setIndex < exercise.sets.length; setIndex++) {
        if (!exercise.sets[setIndex].done) {
          setState(() {
            _currentExerciseIndex = exerciseIndex;
            _currentSetIndex = setIndex;
            _loadCurrentSetValues();
          });
          return true;
        }
      }
    }
    return false;
  }

  void _loadCurrentSetValues() {
    final set = _currentSet;
    _currentKg = set.kg;
    _currentReps = set.reps;
    _currentRir = set.rir;
  }

  void _completeSet() {
    if (_phase != _WorkoutPhase.active) return;

    setState(() {
      _currentSet
        ..kg = _currentKg
        ..reps = _currentReps
        ..rir = _currentRir
        ..done = true;
    });

    final hasNext = _moveToNextPendingSet();
    if (hasNext) {
      _startRestTimer();
    }
  }

  void _toggleSetDone(int index, bool done) {
    if (_phase == _WorkoutPhase.preStart) return;

    setState(() {
      final set = _currentExercise.sets[index];
      if (done) {
        set
          ..kg = index == _currentSetIndex ? _currentKg : set.kg
          ..reps = index == _currentSetIndex ? _currentReps : set.reps
          ..rir = index == _currentSetIndex ? _currentRir : set.rir
          ..done = true;
      } else {
        set.done = false;
      }
      _syncToNextPendingSet();
    });
  }

  void _finishWorkout() {
    _sessionTimer?.cancel();
    _restTimer?.cancel();
    WorkoutSessionStore.finishSession(elapsedSeconds: _elapsedSeconds);
    context.go(RouteNames.workoutSummary);
  }

  String get _sessionTime {
    final minutes = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String get _restTimeDisplay {
    final minutes = (_restSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_restSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _restTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_inDayView) return _buildDayView();
    return _buildExerciseView();
  }

  Widget _buildExerciseView() {
    final exercise = _currentExercise;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildExerciseHeader(exercise),
                    const SizedBox(height: 12),
                    _buildSessionStatus(exercise),
                    const SizedBox(height: 12),
                    _buildSuggestion(exercise),
                    const SizedBox(height: 12),
                    _buildSetsTable(exercise),
                    const SizedBox(height: 14),
                    _buildInputSection(),
                    const SizedBox(height: 14),
                    _buildWeightStepSelector(),
                    const SizedBox(height: 14),
                    _buildRirSection(),
                    const SizedBox(height: 14),
                    _buildRestSelector(),
                    const SizedBox(height: 20),
                    _buildPrimaryAction(),
                    const SizedBox(height: 12),
                    AtlasButton(
                      label: 'Finalizar entrenamiento',
                      variant: AtlasButtonVariant.outline,
                      onTap: _finishWorkout,
                    ),
                    const SizedBox(height: 8),
                    AtlasButton(
                      label: 'Ver todos los ejercicios',
                      variant: AtlasButtonVariant.ghost,
                      icon: Icons.list_rounded,
                      onTap: _backToDayView,
                    ),
                  ],
                ),
              ),
            ),
            if (_isResting) _buildRestBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: Color(0xFF1C0E2E),
        border: Border(bottom: BorderSide(color: Color(0xFF3D2260), width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => _showExitDialog(),
                child: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _session.dayName,
                  style: AppTextStyles.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
                ),
                child: Text(
                  _sessionTime,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.secondary,
                    fontFamily: 'monospace',
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
          _buildDaySelector(),
          const SizedBox(height: 10),
          if (!_inDayView) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Ejercicio ${_currentExerciseIndex + 1} de ${_session.exerciseCount}',
                    style: AppTextStyles.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${_session.completedSets} de ${_session.totalSets} series',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.primaryLight),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '$_completedExercises ejercicios completados · $_pendingExercises pendientes',
              style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
            ),
            const SizedBox(height: 6),
          ],
          AtlasProgressBar(value: _session.progress, height: 5),
        ],
      ),
    );
  }

  Widget _buildDaySelector() {
    final days = WorkoutSessionStore.activeRoutine.days;
    if (days.length <= 1) return const SizedBox.shrink();

    final isLocked = _phase != _WorkoutPhase.preStart;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: days.map((day) {
          final isSelected = day.id == _session.dayId;
          return ChoiceChip(
            selected: isSelected,
            label: Text(day.name),
            onSelected: isSelected
                ? null
                : isLocked
                    ? (_) => _showDayLockedDialog()
                    : (_) => _changeDay(day),
            labelStyle: AppTextStyles.bodySmall.copyWith(
              color: isSelected
                  ? AppColors.textPrimary
                  : isLocked
                      ? AppColors.textDisabled
                      : AppColors.primaryLight,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
            ),
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            side: BorderSide(
              color: isSelected
                  ? AppColors.primaryLight
                  : isLocked
                      ? const Color(0xFF3F3F46)
                      : AppColors.primary.withOpacity(0.3),
              width: isSelected ? 1.2 : 0.5,
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          );
        }).toList(),
      ),
    );
  }

  void _changeDay(MockRoutineDay newDay) {
    _sessionTimer?.cancel();
    _restTimer?.cancel();
    WorkoutSessionStore.activeDay = newDay;
    WorkoutSessionStore.activeSession = null;
    final newSession = WorkoutSessionStore.startSession(
      routine: WorkoutSessionStore.activeRoutine,
      day: newDay,
    );
    setState(() {
      _session = newSession;
      _currentExerciseIndex = 0;
      _currentSetIndex = 0;
      _phase = _WorkoutPhase.preStart;
      _elapsedSeconds = 0;
      _restSeconds = 0;
      _restFinished = false;
      _inDayView = true;
    });
    _syncToNextPendingSet();
  }

  void _showDayLockedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Entrenamiento en curso'),
        content: Text(
          'Tienes un entrenamiento activo en este día. Finalízalo antes de cambiar.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continuar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _finishWorkout();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDayView() {
    final isStarted = _session.started;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Resumen del día
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Text(
                          '${_session.exerciseCount} ejercicios',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('·',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textDisabled)),
                        const SizedBox(width: 8),
                        Text(
                          '${_session.totalSets} series',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Lista completa de ejercicios
                  ...List.generate(
                    _session.exercises.length,
                    (index) => _buildExerciseListItem(index),
                  ),
                  const SizedBox(height: 20),
                  // Botón principal
                  AtlasButton(
                    label: isStarted
                        ? 'Continuar entrenamiento'
                        : 'Comenzar entrenamiento',
                    icon: Icons.play_arrow_rounded,
                    onTap: isStarted ? () => _goToExercise(_currentExerciseIndex) : _startWorkout,
                    height: 56,
                  ),
                  if (isStarted) ...[
                    const SizedBox(height: 8),
                    AtlasButton(
                      label: 'Finalizar entrenamiento',
                      variant: AtlasButtonVariant.outline,
                      onTap: _finishWorkout,
                    ),
                  ],
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseListItem(int index) {
    final exercise = _session.exercises[index];
    final isActive = index == _currentExerciseIndex;
    final isCompleted =
        exercise.targetSets > 0 && exercise.completedSets == exercise.targetSets;

    return GestureDetector(
      onTap: () => _goToExercise(index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withOpacity(0.12) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? AppColors.primaryLight.withOpacity(0.4)
                : const Color(0xFF3F3F46),
            width: isActive ? 1.0 : 0.5,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check_circle_rounded,
                        size: 18, color: AppColors.primaryLight)
                    : isActive
                        ? const Icon(Icons.play_arrow_rounded,
                            size: 18, color: AppColors.secondary)
                        : Text(
                            '${index + 1}',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textDisabled),
                          ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isCompleted
                          ? AppColors.primaryLight
                          : isActive
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    exercise.muscle,
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
            Text(
              '${exercise.completedSets}/${exercise.targetSets} series',
              style: AppTextStyles.bodySmall.copyWith(
                color: isCompleted ? AppColors.primaryLight : AppColors.textDisabled,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: isActive ? AppColors.primaryLight : AppColors.textDisabled,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseHeader(SessionExercise exercise) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(exercise.name, style: AppTextStyles.titleLarge),
        const SizedBox(height: 2),
        Text(exercise.muscle, style: AppTextStyles.bodySmall),
      ],
    );
  }

  Widget _buildSessionStatus(SessionExercise exercise) {
    return AtlasCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AtlasBadge(
                label: 'Serie $_currentSetNumber de ${exercise.targetSets}',
                color: AppColors.primaryLight,
                textColor: AppColors.primaryLight,
              ),
              const Spacer(),
              Text(
                '${exercise.completedSets} de ${exercise.targetSets} completadas',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 10),
          AtlasProgressBar(
            value: exercise.targetSets == 0 ? 0 : exercise.completedSets / exercise.targetSets,
            height: 5,
            color: AppColors.primaryLight,
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestion(SessionExercise exercise) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.secondary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.tips_and_updates_outlined, size: 16, color: AppColors.secondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Objetivo: ${exercise.targetSets} series · ${exercise.suggestedKg.toStringAsFixed(1)} kg · ${exercise.suggestedReps} reps',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetsTable(SessionExercise exercise) {
    return AtlasCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(width: 40, child: Text('SET', style: AppTextStyles.labelSmall)),
                Expanded(child: Text('KG', style: AppTextStyles.labelSmall, textAlign: TextAlign.center)),
                Expanded(child: Text('REPS', style: AppTextStyles.labelSmall, textAlign: TextAlign.center)),
                Expanded(child: Text('RIR', style: AppTextStyles.labelSmall, textAlign: TextAlign.center)),
                SizedBox(width: 40, child: Text('OK', style: AppTextStyles.labelSmall, textAlign: TextAlign.center)),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 0.5),
          ...List.generate(exercise.sets.length, (index) {
            final set = exercise.sets[index];
            final isActive = index == _currentSetIndex && !set.done;
            final isDone = set.done;

            return Container(
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary.withOpacity(0.08) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      child: Center(
                        child: isDone
                            ? const Icon(Icons.check_rounded, size: 16, color: AppColors.primaryLight)
                            : isActive
                                ? const Icon(Icons.play_arrow_rounded, size: 16, color: AppColors.secondary)
                                : Text(
                                    '${index + 1}',
                                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textDisabled),
                                  ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _setKgLabel(set, isActive),
                        style: _setTextStyle(isDone, isActive),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _setRepsLabel(set, isActive),
                        style: _setTextStyle(isDone, isActive),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _setRirLabel(set, isActive),
                        style: _setTextStyle(isDone, isActive),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(
                      width: 40,
                      child: Checkbox(
                        value: set.done,
                        onChanged: _phase == _WorkoutPhase.preStart
                            ? null
                            : (value) => _toggleSetDone(index, value ?? false),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  TextStyle _setTextStyle(bool isDone, bool isActive) {
    return AppTextStyles.bodyMedium.copyWith(
      color: isDone
          ? AppColors.primaryLight
          : isActive
              ? AppColors.textPrimary
              : AppColors.textDisabled,
      fontWeight: FontWeight.w600,
    );
  }

  String _setKgLabel(SessionSet set, bool isActive) {
    return isActive ? _currentKg.toStringAsFixed(1) : set.kg.toStringAsFixed(1);
  }

  String _setRepsLabel(SessionSet set, bool isActive) {
    return isActive ? '$_currentReps' : '${set.reps}';
  }

  String _setRirLabel(SessionSet set, bool isActive) {
    final rir = isActive ? _currentRir : set.rir;
    return rir == null ? '-' : '$rir';
  }

  Widget _buildInputSection() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PESO',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              AtlasNumberPicker(
                value: _currentKg,
                step: _weightStep,
                min: 0,
                max: 400,
                unit: 'kg',
                showDecimals: true,
                onChanged: (value) => setState(() => _currentKg = value),
                onTapValue: () => _showValueDialog(
                  label: 'Peso',
                  initialValue: _currentKg,
                  isDecimal: true,
                  unit: 'kg',
                  onSave: (v) => setState(() => _currentKg = v.clamp(0, 400)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'REPETICIONES',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              AtlasNumberPicker(
                value: _currentReps.toDouble(),
                step: 1,
                min: 1,
                max: 99,
                onChanged: (value) => setState(() => _currentReps = value.toInt()),
                onTapValue: () => _showValueDialog(
                  label: 'Repeticiones',
                  initialValue: _currentReps.toDouble(),
                  isDecimal: false,
                  onSave: (v) => setState(() => _currentReps = v.toInt().clamp(1, 99)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeightStepSelector() {
    const presets = [0.5, 1.0, 1.25, 2.5, 5.0];
    final isCustom = !presets.contains(_weightStep);

    String stepLabel(double v) {
      if (v == v.roundToDouble()) return '${v.toInt()} kg';
      return '${v.toStringAsFixed(v == 1.25 ? 2 : 1)} kg';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'INCREMENTO DE PESO',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...presets.map((option) {
              final isSelected = option == _weightStep;
              return ChoiceChip(
                selected: isSelected,
                label: Text(stepLabel(option)),
                onSelected: (_) {
                  setState(() => _weightStep = option);
                  AtlasStorage.settings.put('weight_step', option);
                },
                labelStyle: AppTextStyles.bodySmall.copyWith(
                  color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.surface,
                side: BorderSide(
                  color: isSelected ? AppColors.primaryLight : const Color(0xFF3F3F46),
                  width: isSelected ? 1.2 : 0.5,
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            }),
            ChoiceChip(
              selected: isCustom,
              label: Text(isCustom ? stepLabel(_weightStep) : 'Otro'),
              onSelected: (_) => _showValueDialog(
                label: 'Incremento de peso',
                initialValue: _weightStep,
                isDecimal: true,
                unit: 'kg',
                onSave: (v) {
                  if (v > 0) {
                    setState(() => _weightStep = v);
                    AtlasStorage.settings.put('weight_step', v);
                  }
                },
              ),
              labelStyle: AppTextStyles.bodySmall.copyWith(
                color: isCustom ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight: isCustom ? FontWeight.w700 : FontWeight.w500,
              ),
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surface,
              side: BorderSide(
                color: isCustom ? AppColors.primaryLight : const Color(0xFF3F3F46),
                width: isCustom ? 1.2 : 0.5,
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRirSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RIR - REPETICIONES EN RESERVA',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        AtlasRirSelector(
          selected: _currentRir,
          onChanged: (value) => setState(() => _currentRir = value),
        ),
      ],
    );
  }

  Widget _buildRestSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DESCANSO ENTRE SERIES',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        AtlasNumberPicker(
          value: _restTotal.toDouble(),
          step: 15,
          min: 15,
          max: 600,
          unit: 's',
          onChanged: (v) {
            _setRestTotal(v.toInt());
            AtlasStorage.settings.put('rest_total', v.toInt());
          },
          onTapValue: () => _showValueDialog(
            label: 'Descanso',
            initialValue: _restTotal.toDouble(),
            isDecimal: false,
            unit: 's',
            onSave: (v) {
              final secs = v.toInt().clamp(15, 600);
              _setRestTotal(secs);
              AtlasStorage.settings.put('rest_total', secs);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryAction() {
    switch (_phase) {
      case _WorkoutPhase.preStart:
        return AtlasButton(
          label: 'Comenzar entrenamiento',
          icon: Icons.play_arrow_rounded,
          onTap: _startWorkout,
          height: 56,
        );
      case _WorkoutPhase.active:
        return AtlasButton(
          label: 'Completar serie',
          onTap: _completeSet,
          height: 56,
        );
      case _WorkoutPhase.resting:
        return AtlasButton(
          label: _restFinished ? 'Estoy listo' : 'Descansando',
          variant: _restFinished ? AtlasButtonVariant.accent : AtlasButtonVariant.outline,
          onTap: _restFinished ? _readyAfterRest : null,
          height: 56,
        );
    }
  }

  Widget _buildRestBar() {
    final progress = _restTotal == 0 ? 0.0 : _restSeconds / _restTotal;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: Color(0xFF3F3F46), width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _restFinished ? 'DESCANSO TERMINADO' : 'DESCANSO',
                style: AppTextStyles.labelSmall.copyWith(letterSpacing: 1.0),
              ),
              const Spacer(),
              Text(
                _restTimeDisplay,
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.secondary,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Proximo: ${_currentExercise.name} · Serie $_currentSetNumber de ${_currentExercise.targetSets}',
            style: AppTextStyles.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          AtlasProgressBar(
            value: progress,
            height: 5,
            color: AppColors.secondary,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _restFinished
                      ? null
                      : () => setState(() {
                            _restSeconds = (_restSeconds + 30).clamp(0, 300);
                          }),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 38),
                    padding: EdgeInsets.zero,
                    textStyle: AppTextStyles.bodySmall.copyWith(fontSize: 13),
                  ),
                  child: const Text('+30s'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: _restFinished ? _readyAfterRest : _skipRest,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 38),
                    padding: EdgeInsets.zero,
                    foregroundColor: AppColors.secondary,
                    side: const BorderSide(color: AppColors.secondary, width: 0.5),
                    textStyle: AppTextStyles.bodySmall.copyWith(
                      fontSize: 13,
                      color: AppColors.secondary,
                    ),
                  ),
                  child: Text(_restFinished ? 'Estoy listo' : 'Saltar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showValueDialog({
    required String label,
    required double initialValue,
    required ValueChanged<double> onSave,
    bool isDecimal = false,
    String? unit,
  }) {
    final controller = TextEditingController(
      text: isDecimal
          ? initialValue.toStringAsFixed(1)
          : initialValue.toInt().toString(),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(label),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
          decoration: InputDecoration(
            suffixText: unit,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (_) {
            final v = double.tryParse(controller.text.replaceAll(',', '.'));
            if (v != null) onSave(v);
            Navigator.pop(ctx);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final v = double.tryParse(controller.text.replaceAll(',', '.'));
              if (v != null) onSave(v);
              Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showExitDialog() {
    final title = _hasStarted || _session.completedSets > 0
        ? 'Tienes un entrenamiento en curso'
        : 'Salir del entrenamiento';
    final content = _hasStarted || _session.completedSets > 0
        ? 'Si sales ahora, el progreso quedara en memoria hasta que vuelvas al entrenamiento.'
        : 'Todavia no comenzaste la sesion.';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title),
        content: Text(
          content,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continuar entrenamiento'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go(RouteNames.dashboard);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Salir del entrenamiento'),
          ),
        ],
      ),
    );
  }
}
