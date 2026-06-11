import 'package:flutter_test/flutter_test.dart';
import 'package:atlas/features/routines/data/table_routine_interpreter.dart';

void main() {
  String norm(String s) => TableRoutineInterpreter.normalize(s);

  List<String> lines(String s) =>
      s.split('\n').where((l) => l.trim().isNotEmpty).toList();

  group('CASO A — texto libre (no debe romperse)', () {
    test('líneas con NxM se conservan intactas', () {
      const input = 'Press banca 4x8\nDominadas 4x6\nRemo 3x10';
      final out = norm(input);
      expect(lines(out), [
        'Press banca 4x8',
        'Dominadas 4x6',
        'Remo 3x10',
      ]);
    });

    test('soporta separadores x / X / ×', () {
      const input = 'Press banca 4X8\nCurl 3×12';
      expect(lines(norm(input)), ['Press banca 4X8', 'Curl 3×12']);
    });
  });

  group('CASO B — números aislados en líneas separadas', () {
    test('Press inclinado / 3 / 8 → Press inclinado 3x8', () {
      const input = 'Press inclinado\n3\n8';
      expect(lines(norm(input)), ['Press inclinado 3x8']);
    });

    test('varios ejercicios interleaved', () {
      const input = 'Press inclinado\n3\n8\nRemo horizontal\n3\n8';
      expect(lines(norm(input)), [
        'Press inclinado 3x8',
        'Remo horizontal 3x8',
      ]);
    });

    test('números compartiendo línea (3 8)', () {
      const input = 'Apertura en polea\n3 8';
      expect(lines(norm(input)), ['Apertura en polea 3x8']);
    });
  });

  group('CASO C — fuerza estructural / pirámides', () {
    test('Tirón al pecho abierto / 4 / 10-8-6-4', () {
      const input = 'Tirón al pecho abierto\n4\n10-8-6-4';
      expect(lines(norm(input)), ['Tirón al pecho abierto 4x10-8-6-4']);
    });

    test('pirámide inline en una sola fila', () {
      const input = 'Sentadilla 4 10-8-6-4';
      expect(lines(norm(input)), ['Sentadilla 4x10-8-6-4']);
    });
  });

  group('CASO D — encabezados basura → ruido', () {
    test('SEMANA / ADAPTACION / EJERCICIO se eliminan por completo', () {
      const input = 'SEMANA 1\nADAPTACION\nEJERCICIO';
      expect(norm(input).trim(), isEmpty);
    });

    test('columnas S R SERIES REPS MESOCICLO se eliminan', () {
      const input = 'EJERCICIO\nSERIES\nREPS\nS\nR\nMESOCICLO\nDESCANSO';
      expect(norm(input).trim(), isEmpty);
    });
  });

  group('CASO E — tabla real de gimnasio', () {
    test('tabla columnar con pipes', () {
      const input = '''
EJERCICIO | S | R
Press inclinado | 3 | 8
Remo horizontal | 3 | 8
Apertura polea | 3 | 10''';
      expect(lines(norm(input)), [
        'Press inclinado 3x8',
        'Remo horizontal 3x8',
        'Apertura polea 3x10',
      ]);
    });

    test('tabla leída columna-mayor (todos los nombres, luego columnas)', () {
      const input = '''
Press inclinado
Remo horizontal
Apertura polea
3
3
3
8
8
10''';
      expect(lines(norm(input)), [
        'Press inclinado 3x8',
        'Remo horizontal 3x8',
        'Apertura polea 3x10',
      ]);
    });

    test('tabla con cabecera de planilla + ejercicios interleaved', () {
      const input = '''
EJERCICIO
SEMANA 1
ADAPTACION
S
R
Press plano
4
8
Remo abierto con TRX
3
12
Serrucho con mancuerna
3
10''';
      expect(lines(norm(input)), [
        'Press plano 4x8',
        'Remo abierto con TRX 3x12',
        'Serrucho con mancuerna 3x10',
      ]);
    });
  });

  group('Robustez — no romper ni fabricar', () {
    test('"Peso muerto" NO se trata como cabecera basura', () {
      const input = 'Peso muerto\n4\n8';
      expect(lines(norm(input)), ['Peso muerto 4x8']);
    });

    test('planilla de pesos no fabrica un esquema SxR falso', () {
      // 80/85/90 son pesos, no series×reps → no debe inventar "80x85".
      const input = 'Press banca\n80\n85\n90';
      final out = norm(input);
      expect(out.contains('x'), isFalse);
      expect(out.contains('×'), isFalse);
    });

    test('cabeceras de día se conservan', () {
      const input = 'Día A\nPress inclinado\n3\n8';
      expect(lines(norm(input)), ['Día A', 'Press inclinado 3x8']);
    });

    test('entrada vacía devuelve cadena vacía', () {
      expect(norm('   \n  \n'), isEmpty);
    });
  });
}
