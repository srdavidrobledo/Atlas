import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/mock_data.dart';
import '../../../shared/routine_parser.dart';
import '../data/routine_store.dart';

enum _Phase { idle, extracting, scanned, preview, saving }

class ImportRoutinePdfScreen extends StatefulWidget {
  const ImportRoutinePdfScreen({super.key});

  @override
  State<ImportRoutinePdfScreen> createState() => _ImportRoutinePdfScreenState();
}

class _ImportRoutinePdfScreenState extends State<ImportRoutinePdfScreen> {
  _Phase _phase = _Phase.idle;
  ParsedRoutine? _parsed;
  String? _fileName;
  String? _extractedText;
  final _nameController = TextEditingController(text: 'Rutina importada');

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // ── Selección y extracción ────────────────────────────────────────────────

  Future<void> _pickAndExtract() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;

    final bytes = result.files.single.bytes!;
    final name = result.files.single.name;

    setState(() {
      _phase = _Phase.extracting;
      _fileName = name;
    });

    // Pequeño delay para que el spinner sea visible
    await Future.delayed(const Duration(milliseconds: 300));

    final text = await _extractText(bytes);
    final meaningful = text.replaceAll(RegExp(r'\s+'), '').length;

    if (meaningful < 40) {
      setState(() => _phase = _Phase.scanned);
      return;
    }

    _extractedText = text;
    final routineName = _nameController.text.trim().isEmpty
        ? name.replaceAll('.pdf', '')
        : _nameController.text.trim();
    _nameController.text = routineName;

    final parsed = RoutineParser.parse(text, routineName: routineName);

    if (parsed.days.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No se detectaron ejercicios. Revisa el formato del PDF.'),
          behavior: SnackBarBehavior.floating,
        ));
      }
      setState(() => _phase = _Phase.idle);
      return;
    }

    setState(() {
      _parsed = parsed;
      _phase = _Phase.preview;
    });
  }

  Future<String> _extractText(Uint8List bytes) async {
    try {
      final document = PdfDocument(inputBytes: bytes);
      final extractor = PdfTextExtractor(document);
      final text = extractor.extractText();
      document.dispose();
      return text;
    } catch (_) {
      return '';
    }
  }

  // ── Guardar ───────────────────────────────────────────────────────────────

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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Rutina "$name" importada'),
        behavior: SnackBarBehavior.floating,
      ));
      context.pop(true);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

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
        title: Text(_appBarTitle, style: AppTextStyles.titleLarge),
        actions: [
          if (_phase == _Phase.preview)
            TextButton(
              onPressed: () => setState(() {
                _phase = _Phase.idle;
                _parsed = null;
              }),
              child: const Text('Reintentar'),
            ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _buildBody(),
      ),
    );
  }

  String get _appBarTitle => switch (_phase) {
        _Phase.preview => 'Vista previa',
        _Phase.extracting => 'Analizando PDF…',
        _Phase.scanned => 'PDF escaneado',
        _ => 'Importar PDF',
      };

  Widget _buildBody() {
    return switch (_phase) {
      _Phase.idle    => _buildIdle(),
      _Phase.extracting => _buildExtracting(),
      _Phase.scanned => _buildScanned(),
      _Phase.preview => _buildPreview(),
      _Phase.saving  => _buildPreview(),
    };
  }

  // ── Fases ─────────────────────────────────────────────────────────────────

  Widget _buildIdle() {
    return SingleChildScrollView(
      key: const ValueKey('idle'),
      padding: const EdgeInsets.all(24),
      child: Column(
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
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: InputBorder.none,
                hintText: 'Nombre de la rutina',
              ),
            ),
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: _pickAndExtract,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.picture_as_pdf_rounded,
                    size: 48,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Seleccionar PDF',
                    style: AppTextStyles.titleLarge
                        .copyWith(color: AppColors.primaryLight),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Solo archivos .pdf con texto seleccionable',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildInfoBox(),
        ],
      ),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('¿Qué PDFs funcionan?',
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.primaryLight)),
          const SizedBox(height: 6),
          Text(
            '✅  PDFs con texto seleccionable (creados digitalmente)\n'
            '❌  PDFs escaneados / imágenes → OCR próximamente\n\n'
            'Formato recomendado:\n'
            'Día A\nPress banca 4x8\nPress inclinado 3x10',
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 12,
              height: 1.6,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExtracting() {
    return Center(
      key: const ValueKey('extracting'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text('Extrayendo texto del PDF…', style: AppTextStyles.titleMedium),
          if (_fileName != null) ...[
            const SizedBox(height: 8),
            Text(_fileName!, style: AppTextStyles.bodySmall),
          ],
        ],
      ),
    );
  }

  Widget _buildScanned() {
    return Center(
      key: const ValueKey('scanned'),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🔍', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 20),
            Text(
              'PDF escaneado detectado',
              style: AppTextStyles.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Este PDF parece ser una imagen escaneada.\nOCR llegará en una próxima versión.',
              style: AppTextStyles.bodySmall.copyWith(height: 1.6),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () => setState(() => _phase = _Phase.idle),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }

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
                // Resumen
                _buildSummaryRow(parsed, unmatched),
                const SizedBox(height: 16),
                // Texto detectado (colapsable)
                if (_extractedText != null) _buildTextDebug(),
                const SizedBox(height: 8),
                // Días
                ...parsed.days.map(_buildDayCard),
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

  Widget _buildSummaryRow(ParsedRoutine parsed, int unmatched) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3F3F46), width: 0.5),
      ),
      child: Row(
        children: [
          _Chip('${parsed.totalDays}', 'días'),
          const SizedBox(width: 16),
          _Chip('${parsed.totalExercises}', 'ejercicios'),
          const SizedBox(width: 16),
          _Chip('${parsed.matchedExercises}', 'en catálogo',
              color: AppColors.success),
          if (unmatched > 0) ...[
            const SizedBox(width: 16),
            _Chip('$unmatched', 'nuevos', color: AppColors.secondary),
          ],
        ],
      ),
    );
  }

  bool _showRawText = false;

  Widget _buildTextDebug() {
    return GestureDetector(
      onTap: () => setState(() => _showRawText = !_showRawText),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF3F3F46), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Texto detectado',
                    style: AppTextStyles.labelSmall),
                const Spacer(),
                Icon(
                  _showRawText
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
            if (_showRawText) ...[
              const SizedBox(height: 8),
              Text(
                _extractedText!.trim().length > 600
                    ? '${_extractedText!.trim().substring(0, 600)}…'
                    : _extractedText!.trim(),
                style: AppTextStyles.bodySmall.copyWith(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
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
                  Text('${day.exercises.length} ejercicios',
                      style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            const Divider(height: 1),
            ...day.exercises.asMap().entries.map((entry) {
              final ex = entry.value;
              return Column(
                children: [
                  if (entry.key > 0)
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
                              Text(
                                ex.isFromCatalog
                                    ? ex.resolvedMuscle
                                    : 'Nuevo · ${ex.rawName}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontSize: 11,
                                  color: ex.isFromCatalog
                                      ? AppColors.textSecondary
                                      : AppColors.secondary,
                                ),
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
              '$count ${count == 1 ? 'ejercicio' : 'ejercicios'} no ${count == 1 ? 'está' : 'están'} en el catálogo y se añadirán como nuevos.',
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
          label: Text(
              _phase == _Phase.saving ? 'GUARDANDO…' : 'CREAR RUTINA'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            foregroundColor: Colors.black,
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            textStyle: AppTextStyles.labelLarge,
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String value;
  final String label;
  final Color? color;
  const _Chip(this.value, this.label, {this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: AppTextStyles.titleLarge
                .copyWith(color: color ?? AppColors.primaryLight)),
        Text(label, style: AppTextStyles.bodySmall),
      ],
    );
  }
}
