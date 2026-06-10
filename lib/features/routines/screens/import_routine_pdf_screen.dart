import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:syncfusion_flutter_pdf/pdf.dart' as sfpdf;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/atlas_validator.dart';
import '../../../shared/mock_data.dart';
import '../data/routine_parser.dart';
import '../data/routine_store.dart';

enum _Phase { idle, extracting, ocrProcessing, editing, preview, saving }

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
  bool _isOcrSource = false;
  final _nameController = TextEditingController(text: 'Rutina importada');
  final _textController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _textController.dispose();
    super.dispose();
  }

  // ── Selección y extracción ─────────────────────────────────────────────────

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
      _isOcrSource = false;
    });

    await Future.delayed(const Duration(milliseconds: 300));

    final text = await _extractText(bytes);
    final meaningful = text.replaceAll(RegExp(r'\s+'), '').length;

    if (meaningful < 40) {
      // PDF escaneado — intentar OCR
      if (kIsWeb) {
        // ML Kit no disponible en web
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'PDF escaneado detectado. El OCR solo está disponible en la app móvil.'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
          ));
        }
        setState(() => _phase = _Phase.idle);
        return;
      }

      setState(() => _phase = _Phase.ocrProcessing);
      await _runPdfOcr(bytes, name);
      return;
    }

    _extractedText = text;

    final textType = AtlasValidator.classify(text);
    if (textType != RoutineTextType.validRoutine) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AtlasValidator.messageFor(textType)),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ));
      }
      setState(() => _phase = _Phase.idle);
      return;
    }

    _goToPreview(text, name);
  }

  // ── Extracción de texto digital ────────────────────────────────────────────

  Future<String> _extractText(Uint8List bytes) async {
    try {
      final document = sfpdf.PdfDocument(inputBytes: bytes);
      final extractor = sfpdf.PdfTextExtractor(document);
      final text = extractor.extractText();
      document.dispose();
      return text;
    } catch (_) {
      return '';
    }
  }

  // ── OCR para PDFs escaneados ───────────────────────────────────────────────

  Future<void> _runPdfOcr(Uint8List bytes, String fileName) async {
    final tempDir = Directory.systemTemp;
    final tempFiles = <File>[];
    final pageTexts = <String>[];

    try {
      final document = await pdfx.PdfDocument.openData(bytes);
      final pageCount = document.pagesCount;

      for (int pageIndex = 1; pageIndex <= pageCount; pageIndex++) {
        final page = await document.getPage(pageIndex);
        final pageImage = await page.render(
          width: page.width * 2,
          height: page.height * 2,
          format: pdfx.PdfPageImageFormat.jpeg,
          backgroundColor: '#ffffff',
        );
        await page.close();

        if (pageImage?.bytes == null) continue;

        final tempFile = File(
          '${tempDir.path}/atlas_ocr_p$pageIndex.jpg',
        );
        await tempFile.writeAsBytes(pageImage!.bytes);
        tempFiles.add(tempFile);

        final pageText = await _ocrFile(tempFile.path);
        if (pageText.trim().isNotEmpty) {
          pageTexts.add(pageText.trim());
        }
      }

      await document.close();
    } catch (e) {
      // Si pdfx no puede renderizar, no podemos continuar
    } finally {
      for (final f in tempFiles) {
        try { f.deleteSync(); } catch (_) {}
      }
    }

    if (!mounted) return;

    if (pageTexts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'No se pudo extraer texto del PDF escaneado. Prueba con la importación por foto.'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 4),
      ));
      setState(() => _phase = _Phase.idle);
      return;
    }

    final combined = pageTexts.join('\n');
    _isOcrSource = true;
    _textController.text = combined;

    final routineName = _nameController.text.trim().isEmpty
        ? fileName.replaceAll('.pdf', '')
        : _nameController.text.trim();
    _nameController.text = routineName;

    setState(() => _phase = _Phase.editing);
  }

  Future<String> _ocrFile(String path) async {
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

  // ── Parseo desde editor de texto ───────────────────────────────────────────

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
        content: Text('No se detectaron ejercicios. Revisa el texto y el formato.'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    setState(() {
      _parsed = parsed;
      _phase = _Phase.preview;
    });
  }

  // ── Flujo texto digital → preview directo ─────────────────────────────────

  void _goToPreview(String text, String fileName) {
    final routineName = _nameController.text.trim().isEmpty
        ? fileName.replaceAll('.pdf', '')
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
                _phase = _isOcrSource ? _Phase.editing : _Phase.idle;
                _parsed = null;
              }),
              child: Text(_isOcrSource ? 'Editar' : 'Reintentar'),
            ),
          if (_phase == _Phase.editing)
            TextButton(
              onPressed: () => setState(() {
                _phase = _Phase.idle;
                _isOcrSource = false;
                _textController.clear();
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
        _Phase.preview      => 'Vista previa',
        _Phase.extracting   => 'Analizando PDF…',
        _Phase.ocrProcessing => 'Aplicando OCR…',
        _Phase.editing      => 'Revisar texto OCR',
        _Phase.saving       => 'Vista previa',
        _Phase.idle         => 'Importar PDF',
      };

  Widget _buildBody() {
    return switch (_phase) {
      _Phase.idle          => _buildIdle(),
      _Phase.extracting    => _buildProcessing(
          key: 'extracting',
          message: 'Extrayendo texto del PDF…',
        ),
      _Phase.ocrProcessing => _buildProcessing(
          key: 'ocr',
          message: 'PDF escaneado detectado, aplicando OCR…',
          subtitle: 'Esto puede tardar unos segundos',
          isOcr: true,
        ),
      _Phase.editing       => _buildEditing(),
      _Phase.preview       => _buildPreview(),
      _Phase.saving        => _buildPreview(),
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
                    'Texto seleccionable o PDF escaneado',
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
            '✅  PDFs escaneados — OCR automático (móvil)\n'
            '✏️  Puedes editar el texto OCR antes de parsear\n\n'
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

  Widget _buildProcessing({
    required String key,
    required String message,
    String? subtitle,
    bool isOcr = false,
  }) {
    return Center(
      key: ValueKey(key),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isOcr) ...[
              const Text('🔍', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 20),
            ] else
              const CircularProgressIndicator(),
            if (!isOcr) const SizedBox(height: 24)
            else const SizedBox(height: 16),
            Text(
              message,
              style: AppTextStyles.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (_fileName != null) ...[
              const SizedBox(height: 8),
              Text(_fileName!, style: AppTextStyles.bodySmall),
            ],
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
            if (isOcr) ...[
              const SizedBox(height: 24),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEditing() {
    return Column(
      key: const ValueKey('editing'),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Text(
                'Texto detectado — edita si es necesario',
                style: AppTextStyles.labelSmall,
              ),
              const Spacer(),
              Text(
                '${_textController.text.split('\n').length} líneas',
                style: AppTextStyles.bodySmall,
              ),
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
                border: Border.all(color: const Color(0xFF3F3F46), width: 0.5),
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
                if (_isOcrSource)
                  _buildOcrBadge(),
                _buildSummaryRow(parsed, unmatched),
                const SizedBox(height: 16),
                if (_extractedText != null) _buildTextDebug(),
                const SizedBox(height: 8),
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

  Widget _buildOcrBadge() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.document_scanner_rounded,
                size: 16, color: AppColors.primaryLight),
            const SizedBox(width: 8),
            Text(
              'Texto extraído por OCR',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.primaryLight, fontSize: 12),
            ),
          ],
        ),
      ),
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
                Text('Texto detectado', style: AppTextStyles.labelSmall),
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
