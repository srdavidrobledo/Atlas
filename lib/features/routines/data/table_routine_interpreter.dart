/// Capa intermedia entre el OCR y [RoutineParser].
///
/// Su única responsabilidad es **normalizar** el texto crudo que produce el OCR
/// (o la extracción de PDF) a un formato que el parser ya entiende:
///
///   Nombre del ejercicio  S x R   (una línea por ejercicio)
///
/// No tiene estado, no usa red, no depende de Flutter. Es una función pura:
///
///   TableRoutineInterpreter.normalize(rawOcrText) -> textoReconstruido
///
/// Decide automáticamente entre tres situaciones:
///
///   1. Texto libre        → se devuelve intacto (no se rompe el flujo actual).
///   2. Tabla columnar     → "Press inclinado | 3 | 8"  →  "Press inclinado 3x8"
///   3. Tabla aplanada     → nombre y números en líneas separadas se recomponen.
///
/// Los encabezados de planilla (EJERCICIO, SEMANA, S, R, SERIES, REPS…) se
/// eliminan mediante una heurística estructural, no con listas fijas gigantes:
/// una línea es basura solo si TODAS sus palabras significativas son stems de
/// cabecera, números o letras sueltas. Así "Peso muerto" sobrevive aunque
/// "peso" sea un stem.
class TableRoutineInterpreter {
  // Cotas de plausibilidad: protegen contra planillas de peso/seguimiento.
  // Un número de series > 12 o de reps > 60 casi nunca es un esquema SxR real,
  // sino un peso en kg o una marca → no se reconstruye (evita fabricar rutinas).
  static const int _maxSets = 12;
  static const int _maxReps = 60;

  /// Stems de cabecera (en singular, sin acentos). Se comparan tras singularizar
  /// la palabra. Es una lista corta y deliberada: NO pretende cubrir cada
  /// ejercicio, solo las columnas/cabeceras típicas de una planilla.
  static const Set<String> _headerStems = {
    'ejercicio', 'serie', 'rep', 'repeticion', 'semana', 'mes', 'mesociclo',
    'microciclo', 'macrociclo', 'adaptacion', 'acumulacion', 'intensificacion',
    'realizacion', 'descarga', 'descanso', 'fecha', 'bloque', 'fase', 'objetivo',
    'peso', 'carga', 'tempo', 'rir', 'rpe', 'kg', 'rm', 'observacion', 'nota',
    'total', 'columna', 'intensidad', 'volumen', 'descripcion',
  };

  static final _nxmRegex = RegExp(r'\d+\s*[xX×]\s*\d+');
  static final _pureNumber = RegExp(r'^\d{1,3}$');
  static final _repSpec = RegExp(r'^\d{1,3}(?:[-/]\d{1,3})+$');
  static final _inlineRow = RegExp(
    r'^(.*?[A-Za-zÁÉÍÓÚÜÑáéíóúüñ])\s+(\d{1,3})(?:\s+(\d{1,3}(?:[-/]\d{1,3})*))?\s*$',
  );
  static final _columnSplit = RegExp(r'\s*\|\s*|\t+|\s{2,}');
  static final _wideGap = RegExp(r'\S\s{2,}\S');
  static final _dayHeader = RegExp(
    r'^(dia|day|push|pull|piernas|legs|upper|lower|torso|empuje|full\s*body|'
    r'lunes|martes|miercoles|jueves|viernes|sabado|domingo)(\s|$)',
  );

  /// Punto de entrada único. Devuelve el texto reconstruido (líneas `Nombre SxR`).
  /// Si la entrada ya es texto libre con `NxM`, se devuelve esencialmente igual.
  static String normalize(String raw) {
    if (raw.trim().isEmpty) return '';

    final lines = raw
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final tokens = <_Tok>[];
    for (final line in lines) {
      tokens.addAll(_classifyLine(line));
    }

    return _reconstruct(tokens).join('\n');
  }

  // ── Clasificación por línea física ───────────────────────────────────────

  static List<_Tok> _classifyLine(String line) {
    // 1. Ya es un ejercicio completo (texto libre) → passthrough intacto.
    if (_nxmRegex.hasMatch(line)) return [_Tok.complete(line)];

    // 2. Fila de tabla con separadores explícitos (| , tab, 2+ espacios).
    if (_hasColumnSeparator(line)) {
      final t = _reconstructColumnarRow(line);
      return t == null ? const [] : [t];
    }

    // 3. Cabecera de día (corta y con keyword) → se conserva tal cual.
    if (_isDayHeaderLine(line)) return [_Tok.name(line)];

    // 4. Línea compuesta solo de números / pirámides ("3", "3 8", "10-8-6-4").
    final nums = _asNumberLine(line);
    if (nums != null) return nums;

    // 5. Fila inline: nombre seguido de números al final ("Press inclinado 3 8").
    final inline = _reconstructInlineRow(line);
    if (inline != null) return [inline];

    // 6. Basura estructural (encabezados, columnas sueltas).
    if (_isJunkLine(line)) return const [];

    // 7. Nombre suelto de ejercicio (los números pueden venir en líneas siguientes).
    return [_Tok.name(line)];
  }

  // ── Reconstrucción (bloque columnar + interleaved) ───────────────────────

  static List<String> _reconstruct(List<_Tok> tokens) {
    // Pasada A: detectar bloques "N nombres seguidos de ≥2N números"
    // (tablas leídas columna-mayor por el OCR) y emparejarlos por columnas.
    final pre = <_Tok>[];
    var i = 0;
    while (i < tokens.length) {
      if (tokens[i].kind != _Kind.name) {
        pre.add(tokens[i]);
        i++;
        continue;
      }
      var j = i;
      final names = <_Tok>[];
      while (j < tokens.length && tokens[j].kind == _Kind.name) {
        names.add(tokens[j]);
        j++;
      }
      var k = j;
      final nums = <_Tok>[];
      while (k < tokens.length &&
          (tokens[k].kind == _Kind.number || tokens[k].kind == _Kind.reps)) {
        nums.add(tokens[k]);
        k++;
      }

      if (names.length >= 2 && nums.length >= names.length * 2) {
        final n = names.length;
        for (var x = 0; x < n; x++) {
          pre.add(_Tok.complete(
            _composeExercise(names[x].value, [nums[x].value, nums[n + x].value]),
          ));
        }
        // Columnas extra (peso, semana 2…) se descartan.
      } else {
        pre.addAll(names);
        pre.addAll(nums);
      }
      i = k;
    }

    // Pasada B: máquina de estados interleaved — cada nombre absorbe los
    // números que lo siguen ("Press inclinado", "3", "8" → "Press inclinado 3x8").
    final out = <String>[];
    String? pendingName;
    final pendingNums = <String>[];

    void flush() {
      if (pendingName == null) return;
      out.add(_composeExercise(pendingName!, pendingNums));
      pendingName = null;
      pendingNums.clear();
    }

    for (final t in pre) {
      switch (t.kind) {
        case _Kind.complete:
          flush();
          out.add(t.value);
        case _Kind.name:
          flush();
          pendingName = t.value;
        case _Kind.number:
        case _Kind.reps:
          if (pendingName != null) pendingNums.add(t.value);
      }
    }
    flush();

    return out.where((l) => l.trim().isNotEmpty).toList();
  }

  // ── Reconstrucción de una fila ───────────────────────────────────────────

  static _Tok? _reconstructColumnarRow(String line) {
    final cells = line
        .split(_columnSplit)
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty)
        .toList();

    final nameParts = <String>[];
    final numParts = <String>[];
    for (final c in cells) {
      if (_pureNumber.hasMatch(c) || _repSpec.hasMatch(c)) {
        numParts.add(c);
      } else if (_isJunkLine(c)) {
        continue; // celda de cabecera (EJERCICIO, S, R) → se descarta
      } else if (_hasWord3Letters(c)) {
        nameParts.add(c);
      }
    }

    if (nameParts.isEmpty) return null;
    return _Tok.complete(_composeExercise(nameParts.join(' '), numParts));
  }

  static _Tok? _reconstructInlineRow(String line) {
    final m = _inlineRow.firstMatch(line);
    if (m == null) return null;

    final name = m.group(1)!.trim();
    if (!_hasWord3Letters(name) || _isJunkLine(name)) return null;

    final nums = <String>[m.group(2)!];
    final reps = m.group(3);
    if (reps != null) nums.add(reps);
    return _Tok.complete(_composeExercise(name, nums));
  }

  /// Compone "Nombre SxR" si los números son plausibles; si no, devuelve solo
  /// el nombre (nunca fabrica un esquema imposible a partir de pesos/marcas).
  static String _composeExercise(String name, List<String> nums) {
    if (nums.isEmpty) return name;

    final setsStr = nums[0];
    final setsVal = int.tryParse(setsStr);
    if (setsVal == null || setsVal < 1 || setsVal > _maxSets) return name;

    if (nums.length < 2) return name;
    final repsStr = nums[1];
    if (!_isPlausibleReps(repsStr)) return name;

    return '$name ${setsStr}x$repsStr';
  }

  // ── Predicados / utilidades ──────────────────────────────────────────────

  static bool _hasColumnSeparator(String line) =>
      line.contains('|') || line.contains('\t') || _wideGap.hasMatch(line);

  static bool _isDayHeaderLine(String line) {
    final norm = _normalize(line);
    if (norm.isEmpty || norm.split(' ').length > 4) return false;
    return _dayHeader.hasMatch(norm);
  }

  /// Devuelve tokens numéricos si la línea es SOLO números/pirámides; si no, null.
  static List<_Tok>? _asNumberLine(String line) {
    final parts = line.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return null;

    final toks = <_Tok>[];
    for (final p in parts) {
      if (_pureNumber.hasMatch(p)) {
        toks.add(_Tok.number(p));
      } else if (_repSpec.hasMatch(p)) {
        toks.add(_Tok.reps(p));
      } else {
        return null;
      }
    }
    return toks;
  }

  /// Heurística de basura: la línea es ruido solo si TODAS sus palabras
  /// significativas son stems de cabecera, números o letras sueltas (≤2).
  static bool _isJunkLine(String line) {
    final norm = _normalize(line);
    if (norm.isEmpty) return true;
    final words = norm.split(' ').where((w) => w.isNotEmpty);
    if (words.isEmpty) return true;
    return words.every((w) =>
        w.length <= 2 ||
        _pureNumber.hasMatch(w) ||
        _headerStems.contains(_singularize(w)));
  }

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

  static bool _hasWord3Letters(String s) => _normalize(s)
      .split(' ')
      .any((w) => RegExp(r'^[a-z]{3,}$').hasMatch(w));

  static String _singularize(String w) =>
      (w.length > 3 && w.endsWith('s')) ? w.substring(0, w.length - 1) : w;

  static String _normalize(String s) => s
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

// ── Token interno ──────────────────────────────────────────────────────────

enum _Kind { complete, name, number, reps }

class _Tok {
  final _Kind kind;
  final String value;
  const _Tok._(this.kind, this.value);

  factory _Tok.complete(String v) => _Tok._(_Kind.complete, v);
  factory _Tok.name(String v) => _Tok._(_Kind.name, v);
  factory _Tok.number(String v) => _Tok._(_Kind.number, v);
  factory _Tok.reps(String v) => _Tok._(_Kind.reps, v);
}
