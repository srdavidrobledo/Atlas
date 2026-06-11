import 'dart:math' as math;
import 'dart:ui';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Reconstrucción de tablas de rutina a partir de la **geometría** de ML Kit
/// (`boundingBox` de cada `TextLine`/`TextElement`), no del texto aplanado.
///
/// Causa raíz de BUG-001 (alias BUG-010): el pipeline usaba `result.text` y
/// descartaba las coordenadas X/Y, única señal fiable para asociar
/// celda ↔ fila ↔ columna. Este módulo (DEC-008) reconstruye la grilla real.
///
/// Contrato: función pura, determinista, sin estado, sin red, sin Flutter-UI.
///
///   OcrGridReconstructor.reconstruct(RecognizedText)
///       → String  "Nombre SxR" (una línea por ejercicio)  [éxito]
///       → null                                             [fallback]
///
/// La salida es **exactamente** el formato que ya consume `RoutineParser`
/// (líneas `Nombre 4x8`), por lo que el parser, el validator y `MockExercise`
/// no se tocan. El modelo enriquecido (rangos/pirámides) es tarea aparte
/// (DEC-009): aquí los números se emiten como texto sin truncar el rango,
/// pero el esquema final lo decide el parser actual.
///
/// Si la estructura no es tabular fiable devuelve `null` y el llamador hace
/// fallback a `TableRoutineInterpreter.normalize(result.text)`.
class OcrGridReconstructor {
  // Cotas de plausibilidad (alineadas con TableRoutineInterpreter).
  static const int _maxSets = 12;
  static const int _maxReps = 60;

  // Umbrales adaptativos (relativos al tamaño del texto, no a píxeles fijos).
  static const double _rowTolFactor = 0.6; // fracción de la altura mediana
  static const double _colTolFactor = 0.9; // fracción del ancho mediano
  static const double _minRowConfidence = 0.4;

  static final _pureNumber = RegExp(r'^\d{1,3}$');
  static final _repSpec = RegExp(r'^\d{1,3}(?:[-/]\d{1,3})+$');

  /// Stems de cabecera (singular, sin acentos). Lista corta y estructural:
  /// NO cubre ejercicios, solo columnas típicas de una planilla.
  static const Set<String> _headerStems = {
    'ejercicio', 'serie', 'rep', 'repeticion', 'set', 'semana', 'mes',
    'descanso', 'fecha', 'peso', 'carga', 'tempo', 'rir', 'rpe', 'kg', 'rm',
    'observacion', 'nota', 'objetivo', 'intensidad', 'volumen',
  };

  /// Punto de entrada único.
  static String? reconstruct(RecognizedText recognized) {
    final cells = _flatten(recognized);
    if (cells.length < 4) return null; // muy poco para inferir una tabla

    _deskew(cells);

    final rows = _clusterRows(cells);
    if (rows.length < 2) return null;

    final bands = _detectColumns(cells);
    if (bands.length < 2) return null; // sin ≥2 columnas no hay asociación

    final grid = _buildGrid(rows, bands);
    final sem = _detectSemantics(grid, bands.length);
    if (sem == null) return null;

    final lines = _emit(grid, sem);
    final composed = lines.where((l) => l.contains('x')).length;
    if (composed == 0) return null; // ninguna fila con SxR plausible → fallback

    return lines.join('\n');
  }

  // ── 1. Flatten + construcción de _Cell ──────────────────────────────────

  static List<_Cell> _flatten(RecognizedText recognized) {
    final cells = <_Cell>[];
    for (final block in recognized.blocks) {
      for (final line in block.lines) {
        cells.addAll(_lineToCells(line));
      }
    }
    return cells;
  }

  /// Una línea es una celda, salvo que sus elementos tengan gaps horizontales
  /// grandes (ML Kit fundió "Sentadilla 4 10" en una línea) → se re-segmenta.
  static List<_Cell> _lineToCells(TextLine line) {
    final els = line.elements;
    if (els.length < 2) return [_Cell.fromBox(line.text, line.boundingBox, line.confidence, line.angle)];

    final sorted = [...els]..sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));
    final medianW = _median(sorted.map((e) => e.boundingBox.width).toList());
    final gapTol = medianW * 1.4;

    final groups = <List<TextElement>>[[sorted.first]];
    for (var i = 1; i < sorted.length; i++) {
      final prev = sorted[i - 1].boundingBox;
      final cur = sorted[i].boundingBox;
      if (cur.left - prev.right > gapTol) {
        groups.add([sorted[i]]);
      } else {
        groups.last.add(sorted[i]);
      }
    }

    return groups.map((g) {
      final text = g.map((e) => e.text).join(' ');
      final box = g.map((e) => e.boundingBox).reduce((a, b) => a.expandToInclude(b));
      return _Cell.fromBox(text, box, line.confidence, line.angle);
    }).toList();
  }

  // ── 2. Deskew básico usando angle ───────────────────────────────────────

  static void _deskew(List<_Cell> cells) {
    final angles = cells.where((c) => c.angle != null).map((c) => c.angle!).toList();
    if (angles.isEmpty) return;
    final med = _median(angles);
    if (med.abs() < 2.0) return; // ruido — no rotar

    final theta = -med * math.pi / 180.0;
    final cos = math.cos(theta), sin = math.sin(theta);
    final ox = cells.map((c) => c.cx).reduce((a, b) => a + b) / cells.length;
    final oy = cells.map((c) => c.cy).reduce((a, b) => a + b) / cells.length;

    for (final c in cells) {
      final dx = c.cx - ox, dy = c.cy - oy;
      c.cx = ox + dx * cos - dy * sin;
      c.cy = oy + dx * sin + dy * cos;
    }
  }

  // ── 3. Row clustering por Y ──────────────────────────────────────────────

  static List<List<_Cell>> _clusterRows(List<_Cell> cells) {
    final sorted = [...cells]..sort((a, b) => a.cy.compareTo(b.cy));
    final medianH = _median(cells.map((c) => c.h).toList());
    final tol = medianH * _rowTolFactor;

    final rows = <List<_Cell>>[[sorted.first]];
    for (var i = 1; i < sorted.length; i++) {
      if (sorted[i].cy - sorted[i - 1].cy > tol) {
        rows.add([sorted[i]]);
      } else {
        rows.last.add(sorted[i]);
      }
    }
    for (final r in rows) {
      r.sort((a, b) => a.cx.compareTo(b.cx));
    }
    return rows;
  }

  // ── 4. Column clustering global por X ───────────────────────────────────

  /// Proyecta los centros X de TODAS las celdas y agrupa por gaps → bandas de
  /// columna alineadas aunque a una fila le falte una celda.
  static List<double> _detectColumns(List<_Cell> cells) {
    final xs = cells.map((c) => c.cx).toList()..sort();
    final medianW = _median(cells.map((c) => c.w).toList());
    final tol = math.max(medianW * _colTolFactor, 1.0);

    final clusters = <List<double>>[[xs.first]];
    for (var i = 1; i < xs.length; i++) {
      if (xs[i] - xs[i - 1] > tol) {
        clusters.add([xs[i]]);
      } else {
        clusters.last.add(xs[i]);
      }
    }
    return clusters.map((c) => c.reduce((a, b) => a + b) / c.length).toList();
  }

  // ── 5/6. Construcción de Grid ────────────────────────────────────────────

  static _Grid _buildGrid(List<List<_Cell>> rows, List<double> bands) {
    final matrix = <List<_Cell?>>[];
    for (final row in rows) {
      final slots = List<_Cell?>.filled(bands.length, null);
      for (final cell in row) {
        final col = _nearestBand(cell.cx, bands);
        final existing = slots[col];
        if (existing == null) {
          slots[col] = cell;
        } else if (!existing.isNumeric && !cell.isNumeric) {
          // Nombre en varias celdas/líneas dentro de la misma columna → merge.
          slots[col] = existing.mergedWith(cell);
        }
        // Si ya hay una numérica, conservamos la primera (descarta duplicados).
      }
      matrix.add(slots);
    }
    return _Grid(matrix, bands);
  }

  static int _nearestBand(double x, List<double> bands) {
    var best = 0;
    var bestD = (x - bands[0]).abs();
    for (var i = 1; i < bands.length; i++) {
      final d = (x - bands[i]).abs();
      if (d < bestD) {
        bestD = d;
        best = i;
      }
    }
    return best;
  }

  // ── 7. Detección de columnas nombre / series / reps ─────────────────────

  static _Semantics? _detectSemantics(_Grid grid, int nCols) {
    final n = grid.matrix.length;
    if (n == 0) return null;

    // Ratio numérico por columna (sobre celdas no vacías).
    final numericRatio = List<double>.filled(nCols, 0);
    for (var c = 0; c < nCols; c++) {
      var total = 0, numeric = 0;
      for (final row in grid.matrix) {
        final cell = row[c];
        if (cell == null) continue;
        total++;
        if (cell.isNumeric) numeric++;
      }
      numericRatio[c] = total == 0 ? 0 : numeric / total;
    }

    // Columna de nombre: menor ratio numérico (la más textual).
    var nameCol = 0;
    for (var c = 1; c < nCols; c++) {
      if (numericRatio[c] < numericRatio[nameCol]) nameCol = c;
    }
    if (numericRatio[nameCol] > 0.5) return null; // no hay columna textual clara

    // ¿La fila 0 es cabecera? (mayoría de celdas son stems de planilla)
    final header = grid.matrix.first;
    var headerHits = 0, headerCells = 0;
    for (final cell in header) {
      if (cell == null) continue;
      headerCells++;
      if (_isHeaderWord(cell.text)) headerHits++;
    }
    final isHeader = headerCells >= 2 && headerHits >= (headerCells / 2).ceil();
    final dataStart = isHeader ? 1 : 0;
    if (grid.matrix.length - dataStart < 1) return null;

    int? setsCol, repsCol;

    if (isHeader) {
      // (a) Etiquetado por cabecera detectada.
      for (var c = 0; c < nCols; c++) {
        if (c == nameCol) continue;
        final label = _headerLabel(header[c]?.text);
        if (label == _ColLabel.series) setsCol ??= c;
        if (label == _ColLabel.reps) repsCol ??= c;
      }
    }

    // (c) Fallback posicional: primeras columnas numéricas tras el nombre.
    if (setsCol == null || repsCol == null) {
      final numericCols = <int>[];
      for (var c = 0; c < nCols; c++) {
        if (c != nameCol && numericRatio[c] >= 0.5) numericCols.add(c);
      }
      numericCols.sort((a, b) => grid.bands[a].compareTo(grid.bands[b]));
      for (final c in numericCols) {
        if (setsCol == null) {
          setsCol = c;
        } else if (repsCol == null && c != setsCol) {
          repsCol = c;
          break;
        }
      }
    }

    if (setsCol == null || repsCol == null || setsCol == repsCol) return null;
    return _Semantics(nameCol: nameCol, setsCol: setsCol, repsCol: repsCol, dataStart: dataStart);
  }

  // ── 8/9. Emisión de filas + confianza ───────────────────────────────────

  static List<String> _emit(_Grid grid, _Semantics sem) {
    final out = <String>[];
    for (var r = sem.dataStart; r < grid.matrix.length; r++) {
      final row = grid.matrix[r];
      final nameCell = row[sem.nameCol];
      final name = nameCell?.text.trim() ?? '';
      if (name.isEmpty || !_hasWord3Letters(name)) continue; // separador/ruido

      final conf = _rowConfidence(row, sem);
      final sets = row[sem.setsCol]?.text.trim();
      final reps = row[sem.repsCol]?.text.trim();

      if (conf >= _minRowConfidence && sets != null && reps != null) {
        out.add(_compose(name, sets, reps));
      } else {
        out.add(name); // fila incompleta/dudosa → nombre solo (editable luego)
      }
    }
    return out;
  }

  static double _rowConfidence(List<_Cell?> row, _Semantics sem) {
    final cells = [row[sem.nameCol], row[sem.setsCol], row[sem.repsCol]];
    final present = cells.where((c) => c != null).toList();
    if (present.isEmpty) return 0;
    final avgConf = present.map((c) => c!.conf).reduce((a, b) => a + b) / present.length;
    final completeness = present.length / 3.0;
    return avgConf * completeness;
  }

  /// "Nombre SxR" si los números son plausibles; si no, solo el nombre.
  static String _compose(String name, String sets, String reps) {
    final s = int.tryParse(sets);
    if (s == null || s < 1 || s > _maxSets) return name;
    if (!_isPlausibleReps(reps)) return name;
    return '$name ${sets}x$reps';
  }

  // ── Predicados / utilidades ──────────────────────────────────────────────

  static bool _isPlausibleReps(String s) {
    if (_pureNumber.hasMatch(s)) {
      final v = int.parse(s);
      return v >= 1 && v <= _maxReps;
    }
    if (_repSpec.hasMatch(s)) {
      return s.split(RegExp(r'[-/]')).every((p) {
        final v = int.tryParse(p);
        return v != null && v >= 1 && v <= _maxReps;
      });
    }
    return false;
  }

  static bool _isHeaderWord(String w) {
    final n = _norm(w);
    if (n.isEmpty) return false;
    return _headerStems.any((s) => n == s || n.startsWith(s) || s.startsWith(n));
  }

  static _ColLabel _headerLabel(String? w) {
    if (w == null) return _ColLabel.other;
    final n = _norm(w);
    if (n.startsWith('serie') || n == 'set' || n.startsWith('sets')) return _ColLabel.series;
    if (n.startsWith('rep')) return _ColLabel.reps;
    return _ColLabel.other;
  }

  static bool _hasWord3Letters(String s) =>
      _norm(s).split(' ').any((w) => RegExp(r'^[a-z]{3,}$').hasMatch(w));

  static double _median(List<double> xs) {
    if (xs.isEmpty) return 0;
    final s = [...xs]..sort();
    final mid = s.length ~/ 2;
    return s.length.isOdd ? s[mid] : (s[mid - 1] + s[mid]) / 2;
  }

  static String _norm(String s) => s
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ü', 'u')
      .replaceAll('ñ', 'n')
      .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

// ── Estructuras internas ────────────────────────────────────────────────────

enum _ColLabel { series, reps, other }

class _Cell {
  final String text;
  double cx, cy;
  final double w, h;
  final double conf;
  final double? angle;
  final bool isNumeric;

  _Cell({
    required this.text,
    required this.cx,
    required this.cy,
    required this.w,
    required this.h,
    required this.conf,
    required this.angle,
  }) : isNumeric = OcrGridReconstructor._pureNumber.hasMatch(text.trim()) ||
            OcrGridReconstructor._repSpec.hasMatch(text.trim());

  factory _Cell.fromBox(String text, Rect box, double? confidence, double? angle) => _Cell(
        text: text,
        cx: box.center.dx,
        cy: box.center.dy,
        w: box.width,
        h: box.height,
        conf: confidence ?? 1.0,
        angle: angle,
      );

  _Cell mergedWith(_Cell other) {
    final left = cx <= other.cx ? this : other;
    final right = cx <= other.cx ? other : this;
    return _Cell(
      text: '${left.text} ${right.text}',
      cx: (cx + other.cx) / 2,
      cy: (cy + other.cy) / 2,
      w: w + other.w,
      h: math.max(h, other.h),
      conf: math.min(conf, other.conf),
      angle: angle,
    );
  }
}

class _Grid {
  final List<List<_Cell?>> matrix;
  final List<double> bands;
  const _Grid(this.matrix, this.bands);
}

class _Semantics {
  final int nameCol, setsCol, repsCol, dataStart;
  const _Semantics({
    required this.nameCol,
    required this.setsCol,
    required this.repsCol,
    required this.dataStart,
  });
}
