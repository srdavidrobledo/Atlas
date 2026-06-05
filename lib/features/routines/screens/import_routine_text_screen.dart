import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/mock_data.dart';
import '../../../shared/routine_parser.dart';
import '../data/routine_store.dart';

class ImportRoutineTextScreen extends StatefulWidget {
  const ImportRoutineTextScreen({super.key});

  @override
  State<ImportRoutineTextScreen> createState() =>
      _ImportRoutineTextScreenState();
}

enum _Phase { idle, preview, saving }

class _ImportRoutineTextScreenState extends State<ImportRoutineTextScreen> {
  final _textController = TextEditingController();
  final _nameController = TextEditingController(text: 'Rutina importada');
  _Phase _phase = _Phase.idle;
  ParsedRoutine? _parsed;

  @override
  void dispose() {
    _textController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _analyze() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    final parsed = RoutineParser.parse(text, routineName: _nameController.text.trim());
    if (parsed.days.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se detectaron ejercicios. Revisa el formato.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() {
      _parsed = parsed;
      _phase = _Phase.preview;
    });
  }

  Future<void> _save() async {
    if (_parsed == null) return;
    setState(() => _phase = _Phase.saving);

    final name = _nameController.text.trim().isEmpty
        ? 'Rutina importada'
        : _nameController.text.trim();

    final id = 'r_${DateTime.now().millisecondsSinceEpoch}';
    final mockRoutine = _parsed!.toMockRoutine(id);

    final routine = RoutineStore.createRoutine(name);
    for (final day in mockRoutine.days) {
      routine.days.add(MockRoutineDay(
        id: day.id,
        name: day.name,
        exercises: day.exercises,
      ));
    }
    await RoutineStore.persistRoutines();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rutina "$name" importada'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop(true);
    }
  }

  void _reset() => setState(() {
        _phase = _Phase.idle;
        _parsed = null;
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _phase == _Phase.preview ? 'Vista previa' : 'Importar texto',
          style: AppTextStyles.titleLarge,
        ),
        actions: [
          if (_phase == _Phase.preview)
            TextButton(
              onPressed: _reset,
              child: const Text('Editar'),
            ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _phase == _Phase.preview
            ? _buildPreview()
            : _buildInput(),
      ),
    );
  }

  // ── Input ────────────────────────────────────────────────────────────────

  Widget _buildInput() {
    return Column(
      key: const ValueKey('input'),
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNameField(),
                const SizedBox(height: 16),
                Text('Texto de la rutina', style: AppTextStyles.labelSmall),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF3F3F46), width: 0.5),
                  ),
                  child: TextField(
                    controller: _textController,
                    maxLines: 16,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontFamily: 'monospace',
                      height: 1.6,
                    ),
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.all(14),
                      border: InputBorder.none,
                      hintText: 'Día A\nPress banca 4x8\nPress inclinado 3x10\n\nDía B\nDominadas 4x6\nRemo con barra 3x10',
                      hintStyle: TextStyle(
                        color: Color(0xFF52525B),
                        fontSize: 12,
                        height: 1.6,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildFormatHint(),
              ],
            ),
          ),
        ),
        _buildAnalyzeButton(),
      ],
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Nombre de la rutina', style: AppTextStyles.labelSmall),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF3F3F46), width: 0.5),
          ),
          child: TextField(
            controller: _nameController,
            style: AppTextStyles.bodyMedium,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: InputBorder.none,
              hintText: 'Nombre de la rutina',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormatHint() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Formato recomendado',
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.primaryLight),
          ),
          const SizedBox(height: 6),
          Text(
            'Día A  →  cabecera de día\nPress banca 4x8  →  ejercicio sets×reps\n\nSoporta: Día X, Push, Pull, Piernas, Lunes…',
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 11,
              height: 1.6,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzeButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _analyze,
          icon: const Icon(Icons.search_rounded),
          label: const Text('ANALIZAR'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textPrimary,
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: AppTextStyles.labelLarge,
          ),
        ),
      ),
    );
  }

  // ── Preview ──────────────────────────────────────────────────────────────

  Widget _buildPreview() {
    final parsed = _parsed!;
    final unmatched = parsed.totalExercises - parsed.matchedExercises;

    return Column(
      key: const ValueKey('preview'),
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildParseSummary(parsed, unmatched),
                const SizedBox(height: 16),
                ...parsed.days.map((day) => _buildDayCard(day)),
                if (unmatched > 0) ...[
                  const SizedBox(height: 12),
                  _buildUnmatchedNote(unmatched),
                ],
              ],
            ),
          ),
        ),
        _buildSaveButton(),
      ],
    );
  }

  Widget _buildParseSummary(ParsedRoutine parsed, int unmatched) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3F3F46), width: 0.5),
      ),
      child: Row(
        children: [
          _SummaryChip('${parsed.totalDays}', 'días'),
          const SizedBox(width: 16),
          _SummaryChip('${parsed.totalExercises}', 'ejercicios'),
          const SizedBox(width: 16),
          _SummaryChip('${parsed.matchedExercises}', 'en catálogo',
              color: AppColors.success),
          if (unmatched > 0) ...[
            const SizedBox(width: 16),
            _SummaryChip('$unmatched', 'nuevos',
                color: AppColors.secondary),
          ],
        ],
      ),
    );
  }

  Widget _buildDayCard(ParsedDay day) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF3F3F46), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: Row(
                children: [
                  Text(day.name, style: AppTextStyles.titleMedium),
                  const Spacer(),
                  Text(
                    '${day.exercises.length} ejercicios',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ...day.exercises.asMap().entries.map((entry) {
              final i = entry.key;
              final ex = entry.value;
              return Column(
                children: [
                  if (i > 0)
                    const Divider(height: 1, indent: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ex.resolvedName,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (!ex.isFromCatalog)
                                Text(
                                  'Nuevo · ${ex.rawName}',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontSize: 11,
                                    color: AppColors.secondary,
                                  ),
                                )
                              else
                                Text(
                                  ex.resolvedMuscle,
                                  style: AppTextStyles.bodySmall.copyWith(
                                      fontSize: 11),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          '${ex.sets}×${ex.reps}',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: ex.isFromCatalog
                                ? AppColors.primaryLight
                                : AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildUnmatchedNote(int count) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.secondary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Text('💡', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$count ${count == 1 ? 'ejercicio no está' : 'ejercicios no están'} en el catálogo y se añadirán como nuevos.',
              style: AppTextStyles.bodySmall.copyWith(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _phase == _Phase.saving ? null : _save,
          icon: _phase == _Phase.saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check_rounded),
          label: Text(_phase == _Phase.saving ? 'GUARDANDO...' : 'CREAR RUTINA'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            foregroundColor: Colors.black,
            minimumSize: const Size(double.infinity, 48),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: AppTextStyles.labelLarge,
          ),
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String value;
  final String label;
  final Color? color;
  const _SummaryChip(this.value, this.label, {this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: AppTextStyles.titleLarge.copyWith(
            color: color ?? AppColors.primaryLight,
          ),
        ),
        Text(label, style: AppTextStyles.bodySmall),
      ],
    );
  }
}
