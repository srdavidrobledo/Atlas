import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/atlas_validator.dart';
import '../../../shared/mock_data.dart';
import '../data/routine_parser.dart';
import '../data/routine_store.dart';

enum _Phase { idle, scanning, editing, preview, saving }

class ImportRoutineImageScreen extends StatefulWidget {
  const ImportRoutineImageScreen({super.key});

  @override
  State<ImportRoutineImageScreen> createState() =>
      _ImportRoutineImageScreenState();
}

class _ImportRoutineImageScreenState extends State<ImportRoutineImageScreen> {
  _Phase _phase = _Phase.idle;
  ParsedRoutine? _parsed;
  String? _imagePath;
  final _nameController = TextEditingController(text: 'Rutina importada');
  final _textController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _textController.dispose();
    super.dispose();
  }

  // ── Captura y OCR ──────────────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 90,
      maxWidth: 2000,
    );
    if (picked == null) return;

    setState(() {
      _phase = _Phase.scanning;
      _imagePath = picked.path;
    });

    final text = await _runOcr(picked.path);

    _textController.text = text.trim();
    setState(() => _phase = _Phase.editing);
  }

  Future<String> _runOcr(String path) async {
    final inputImage = InputImage.fromFilePath(path);
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(inputImage);
      return result.text;
    } catch (_) {
      return '';
    } finally {
      recognizer.close();
    }
  }

  // ── Parseo ─────────────────────────────────────────────────────────────────

  void _parseText() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final textType = AtlasValidator.classify(text);
    if (textType != RoutineTextType.validRoutine) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AtlasValidator.messageFor(textType)),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ));
      return;
    }

    final routineName = _nameController.text.trim().isEmpty
        ? 'Rutina importada'
        : _nameController.text.trim();

    final parsed = RoutineParser.parse(text, routineName: routineName);

    if (parsed.days.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'No se detectaron ejercicios. Revisa el texto y el formato.'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    setState(() {
      _parsed = parsed;
      _phase = _Phase.preview;
    });
  }

  // ── Guardar ────────────────────────────────────────────────────────────────

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
                _phase = _Phase.editing;
                _parsed = null;
              }),
              child: const Text('Editar'),
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
        _Phase.scanning => 'Escaneando imagen…',
        _Phase.editing  => 'Revisar texto OCR',
        _Phase.preview  => 'Vista previa',
        _Phase.saving   => 'Vista previa',
        _Phase.idle     => 'Importar desde foto',
      };

  Widget _buildBody() => switch (_phase) {
        _Phase.idle    => _buildIdle(),
        _Phase.scanning => _buildScanning(),
        _Phase.editing  => _buildEditing(),
        _Phase.preview  => _buildPreview(),
        _Phase.saving   => _buildPreview(),
      };

  // ── Fases ──────────────────────────────────────────────────────────────────

  Widget _buildIdle() {
    final isWeb = kIsWeb;
    return SingleChildScrollView(
      key: const ValueKey('idle'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nombre de la rutina', style: AppTextStyles.labelSmall),
          const SizedBox(height: 8),
          _nameField(),
          const SizedBox(height: 32),
          if (isWeb)
            _webNotice()
          else ...[
            _sourceButton(
              icon: Icons.camera_alt_rounded,
              label: 'Tomar foto',
              subtitle: 'Fotografía una rutina escrita o impresa',
              onTap: () => _pickImage(ImageSource.camera),
            ),
            const SizedBox(height: 16),
            _sourceButton(
              icon: Icons.photo_library_rounded,
              label: 'Elegir de galería',
              subtitle: 'Selecciona una imagen de tu dispositivo',
              onTap: () => _pickImage(ImageSource.gallery),
            ),
          ],
          const SizedBox(height: 24),
          _buildInfoBox(),
        ],
      ),
    );
  }

  Widget _nameField() {
    return Container(
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
    );
  }

  Widget _sourceButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.4),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 40, color: AppColors.primary),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: AppTextStyles.titleMedium
                          .copyWith(color: AppColors.primaryLight)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _webNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3F3F46), width: 0.5),
      ),
      child: Row(
        children: [
          const Text('📱', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'La importación por foto solo está disponible en la app móvil (Android e iOS).',
              style: AppTextStyles.bodySmall.copyWith(height: 1.5),
            ),
          ),
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
          Text('Consejos para mejores resultados',
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.primaryLight)),
          const SizedBox(height: 6),
          Text(
            '✅  Buena iluminación, sin sombras\n'
            '✅  Texto horizontal, sin inclinación\n'
            '✅  Formato: "Ejercicio 4x8" por línea\n'
            '✏️  Puedes editar el texto antes de parsear',
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

  Widget _buildScanning() {
    return Center(
      key: const ValueKey('scanning'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text('Reconociendo texto…', style: AppTextStyles.titleMedium),
          const SizedBox(height: 8),
          Text('ML Kit analizando la imagen',
              style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }

  Widget _buildEditing() {
    return Column(
      key: const ValueKey('editing'),
      children: [
        if (_imagePath != null)
          Container(
            height: 160,
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: FileImage(File(_imagePath!)),
                fit: BoxFit.cover,
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Text('Texto detectado — edita si es necesario',
                  style: AppTextStyles.labelSmall),
              const Spacer(),
              Text('${_textController.text.split('\n').length} líneas',
                  style: AppTextStyles.bodySmall),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: const Color(0xFF3F3F46), width: 0.5),
              ),
              child: TextField(
                controller: _textController,
                maxLines: null,
                expands: true,
                style: AppTextStyles.bodySmall.copyWith(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  height: 1.6,
                ),
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.all(14),
                  border: InputBorder.none,
                  hintText:
                      'Día A\nPress banca 4x8\nPress inclinado 3x10\n...',
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  _textController.text.trim().isEmpty ? null : _parseText,
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('PARSEAR RUTINA'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                textStyle: AppTextStyles.labelLarge,
              ),
            ),
          ),
        ),
      ],
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
                _buildSummaryRow(parsed, unmatched),
                const SizedBox(height: 16),
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
                  if (entry.key > 0) const Divider(height: 1, indent: 14),
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
          label:
              Text(_phase == _Phase.saving ? 'GUARDANDO…' : 'CREAR RUTINA'),
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
