import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:atlas/features/routines/data/ocr_grid_reconstructor.dart';

// ── Helpers de fixture ──────────────────────────────────────────────────────
//
// Construyen un RecognizedText sintético colocando cada celda como una TextLine
// con su boundingBox. Coordenadas en píxeles ficticios; lo único que importa es
// la geometría relativa (filas por Y, columnas por X).

const double _cellH = 24;

/// Celda centrada en (cx, cy) con ancho [w].
TextLine _cell(String text, double cx, double cy, {double w = 40, double? angle}) {
  final box = Rect.fromCenter(center: Offset(cx, cy), width: w, height: _cellH);
  return TextLine(
    text: text,
    elements: const [],
    boundingBox: box,
    recognizedLanguages: const [],
    cornerPoints: const [],
    confidence: null,
    angle: angle,
  );
}

RecognizedText _image(List<TextLine> lines) {
  final text = lines.map((l) => l.text).join('\n');
  return RecognizedText(
    text: text,
    blocks: [
      TextBlock(
        text: text,
        lines: lines,
        boundingBox: Rect.zero,
        recognizedLanguages: const [],
        cornerPoints: const [],
      ),
    ],
  );
}

/// Rota un punto θ grados alrededor del origen (para simular tabla inclinada).
Offset _rotate(double x, double y, double deg) {
  final t = deg * math.pi / 180.0;
  return Offset(x * math.cos(t) - y * math.sin(t), x * math.sin(t) + y * math.cos(t));
}

// Bandas X de referencia.
const double _xName = 80, _xSeries = 240, _xReps = 320, _xKg = 400;

void main() {
  group('OcrGridReconstructor', () {
    test('CASO A — tabla simple sin cabecera', () {
      final r = _image([
        _cell('Press banca', _xName, 100, w: 130),
        _cell('4', _xSeries, 100),
        _cell('8', _xReps, 100),
        _cell('Remo barra', _xName, 140, w: 130),
        _cell('4', _xSeries, 140),
        _cell('10', _xReps, 140),
      ]);

      final out = OcrGridReconstructor.reconstruct(r);
      expect(out, isNotNull);
      final lines = out!.split('\n');
      expect(lines, contains('Press banca 4x8'));
      expect(lines, contains('Remo barra 4x10'));
    });

    test('CASO B — tabla con cabecera Ejercicio/Series/Reps', () {
      final r = _image([
        _cell('Ejercicio', _xName, 60, w: 130),
        _cell('Series', _xSeries, 60, w: 60),
        _cell('Reps', _xReps, 60, w: 50),
        _cell('Sentadilla', _xName, 100, w: 130),
        _cell('4', _xSeries, 100),
        _cell('10', _xReps, 100),
        _cell('Press militar', _xName, 140, w: 130),
        _cell('3', _xSeries, 140),
        _cell('12', _xReps, 140),
      ]);

      final out = OcrGridReconstructor.reconstruct(r);
      expect(out, isNotNull);
      final lines = out!.split('\n');
      // La cabecera no debe emitirse como ejercicio.
      expect(lines.any((l) => l.toLowerCase().startsWith('ejercicio')), isFalse);
      expect(lines, contains('Sentadilla 4x10'));
      expect(lines, contains('Press militar 3x12'));
    });

    test('CASO C — columna peso (kg) se descarta', () {
      final r = _image([
        _cell('Ejercicio', _xName, 60, w: 130),
        _cell('Series', _xSeries, 60, w: 60),
        _cell('Reps', _xReps, 60, w: 50),
        _cell('Kg', _xKg, 60),
        _cell('Peso muerto', _xName, 100, w: 130),
        _cell('5', _xSeries, 100),
        _cell('5', _xReps, 100),
        _cell('100', _xKg, 100),
      ]);

      final out = OcrGridReconstructor.reconstruct(r);
      expect(out, isNotNull);
      // Debe asociar series×reps, NO el peso.
      expect(out, contains('Peso muerto 5x5'));
      expect(out!.contains('100'), isFalse);
    });

    test('CASO D — tabla inclinada (deskew por angle)', () {
      const skew = 7.0;
      // Centros limpios idénticos al CASO A, rotados +skew°; angle=skew en cada celda.
      TextLine skewed(String text, double cx, double cy, double w) {
        final p = _rotate(cx, cy, skew);
        return _cell(text, p.dx, p.dy, w: w, angle: skew);
      }

      final r = _image([
        skewed('Press banca', _xName, 100, 130),
        skewed('4', _xSeries, 100, 40),
        skewed('8', _xReps, 100, 40),
        skewed('Remo barra', _xName, 140, 130),
        skewed('4', _xSeries, 140, 40),
        skewed('10', _xReps, 140, 40),
      ]);

      final out = OcrGridReconstructor.reconstruct(r);
      expect(out, isNotNull);
      final lines = out!.split('\n');
      expect(lines, contains('Press banca 4x8'));
      expect(lines, contains('Remo barra 4x10'));
    });

    test('CASO E — OCR parcial: fila incompleta no rompe la reconstrucción', () {
      final r = _image([
        _cell('Sentadilla', _xName, 100, w: 130),
        _cell('4', _xSeries, 100),
        _cell('10', _xReps, 100),
        // Segunda fila sin la celda de reps (OCR perdió el dato).
        _cell('Hip thrust', _xName, 140, w: 130),
        _cell('3', _xSeries, 140),
      ]);

      final out = OcrGridReconstructor.reconstruct(r);
      expect(out, isNotNull);
      final lines = out!.split('\n');
      // La fila completa se compone correctamente.
      expect(lines, contains('Sentadilla 4x10'));
      // La incompleta sobrevive como nombre (no se descarta en silencio),
      // pero sin esquema inventado.
      expect(lines.any((l) => l.startsWith('Hip thrust')), isTrue);
      expect(lines, isNot(contains('Hip thrust 3x')));
    });

    test('CASO F — sin estructura tabular activa el fallback (null)', () {
      // Una sola columna de texto libre: no hay ≥2 columnas → null.
      final r = _image([
        _cell('Rutina de fuerza', _xName, 100, w: 160),
        _cell('para principiantes', _xName, 140, w: 160),
        _cell('tres veces por semana', _xName, 180, w: 200),
        _cell('con progresion lineal', _xName, 220, w: 200),
      ]);

      final out = OcrGridReconstructor.reconstruct(r);
      expect(out, isNull); // el llamador hará fallback a TableRoutineInterpreter
    });
  });
}
