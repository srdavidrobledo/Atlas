// Mock data — temporal hasta integrar Firebase
// No usar Firestore ni Hive aquí

class MockUser {
  static const String name = 'David';
  static const String fullName = 'David Robledo';
  static const String memberSince = 'Enero 2026';
  static const double currentWeight = 80.6;
  static const double targetWeight = 82.0;
  static String goal = 'Ganar músculo';
  static const int weeklyDays = 3;
  static const int defaultRest = 90;
}

class MockStats {
  static const int totalSessions = 47;
  static const String totalHours = '38h';
  static const String totalVolume = '2.1t';
  static const int totalRecords = 12;
  static const int weekSessions = 3;
  static const int monthSessions = 11;
  static const String weekHours = '4.5h';
  static const int streak = 2; // semanas
}

class MockRoutineDay {
  final String id;
  final String name;
  final int exerciseCount;

  const MockRoutineDay({
    required this.id,
    required this.name,
    required this.exerciseCount,
  });
}

class MockRoutine {
  final String id;
  final String name;
  final bool isActive;
  final List<MockRoutineDay> days;
  final int totalSessions;
  final String lastUsed;

  const MockRoutine({
    required this.id,
    required this.name,
    required this.isActive,
    required this.days,
    required this.totalSessions,
    required this.lastUsed,
  });
}

class MockData {
  static final List<MockRoutine> routines = [
    MockRoutine(
      id: 'r1',
      name: 'Push Pull Legs',
      isActive: true,
      totalSessions: 34,
      lastUsed: 'Hoy',
      days: const [
        MockRoutineDay(id: 'd1', name: 'Día A — Push', exerciseCount: 6),
        MockRoutineDay(id: 'd2', name: 'Día B — Pull', exerciseCount: 6),
        MockRoutineDay(id: 'd3', name: 'Día C — Piernas', exerciseCount: 7),
      ],
    ),
    MockRoutine(
      id: 'r2',
      name: 'Full Body',
      isActive: false,
      totalSessions: 12,
      lastUsed: 'Hace 2 meses',
      days: const [
        MockRoutineDay(id: 'd4', name: 'Full Body A', exerciseCount: 8),
        MockRoutineDay(id: 'd5', name: 'Full Body B', exerciseCount: 8),
      ],
    ),
    MockRoutine(
      id: 'r3',
      name: 'Upper / Lower',
      isActive: false,
      totalSessions: 8,
      lastUsed: 'Hace 4 meses',
      days: const [
        MockRoutineDay(id: 'd6', name: 'Upper A', exerciseCount: 7),
        MockRoutineDay(id: 'd7', name: 'Lower A', exerciseCount: 6),
        MockRoutineDay(id: 'd8', name: 'Upper B', exerciseCount: 7),
        MockRoutineDay(id: 'd9', name: 'Lower B', exerciseCount: 6),
      ],
    ),
  ];

  static final List<MockRecord> records = [
    MockRecord(exercise: 'Press Inclinado', value: '72.5 kg × 4', date: 'Jun 2'),
    MockRecord(exercise: 'Press Militar', value: '55 kg × 6', date: 'May 30'),
    MockRecord(exercise: 'Dominadas', value: '+10 kg × 4', date: 'May 28'),
    MockRecord(exercise: 'Press Banca', value: '85 kg × 5', date: 'May 25'),
    MockRecord(exercise: 'Sentadilla', value: '100 kg × 4', date: 'May 22'),
  ];

  static final List<MockWorkoutHistory> history = [
    MockWorkoutHistory(
      day: 'Día A — Push',
      date: 'Lun 2 Jun',
      duration: '54 min',
      volume: '4.230 kg',
      sets: 18,
      feeling: '😀',
    ),
    MockWorkoutHistory(
      day: 'Día C — Piernas',
      date: 'Vie 30 May',
      duration: '62 min',
      volume: '5.100 kg',
      sets: 20,
      feeling: '🙂',
    ),
    MockWorkoutHistory(
      day: 'Día B — Pull',
      date: 'Mié 28 May',
      duration: '48 min',
      volume: '3.840 kg',
      sets: 16,
      feeling: '😐',
    ),
    MockWorkoutHistory(
      day: 'Día A — Push',
      date: 'Lun 26 May',
      duration: '51 min',
      volume: '4.050 kg',
      sets: 18,
      feeling: '🙂',
    ),
  ];

  // Datos del workout activo mock
  static final List<MockExercise> workoutExercises = [
    MockExercise(
      name: 'Press de Banca',
      muscle: 'Pecho · Barra',
      sets: [
        MockSet(kg: 75, reps: 4, rir: 2, done: true),
        MockSet(kg: 75, reps: 4, rir: 2, done: true),
        MockSet(kg: 75, reps: 0, rir: null, done: false),
        MockSet(kg: 75, reps: 0, rir: null, done: false),
      ],
      prevKg: 72.5,
      prevReps: 4,
    ),
    MockExercise(
      name: 'Press Inclinado',
      muscle: 'Pecho superior · Mancuernas',
      sets: [
        MockSet(kg: 32, reps: 0, rir: null, done: false),
        MockSet(kg: 32, reps: 0, rir: null, done: false),
        MockSet(kg: 32, reps: 0, rir: null, done: false),
      ],
      prevKg: 30,
      prevReps: 10,
    ),
    MockExercise(
      name: 'Aperturas',
      muscle: 'Pecho · Mancuernas',
      sets: [
        MockSet(kg: 16, reps: 0, rir: null, done: false),
        MockSet(kg: 16, reps: 0, rir: null, done: false),
        MockSet(kg: 16, reps: 0, rir: null, done: false),
      ],
      prevKg: 16,
      prevReps: 12,
    ),
  ];

  // Pesos para gráficos mock
  static final List<double> weightHistory = [
    78.2, 78.5, 78.8, 79.0, 79.3, 79.1, 79.6,
    79.8, 80.0, 80.2, 80.4, 80.6,
  ];

  static final List<double> strengthHistory = [
    62.5, 65.0, 65.0, 67.5, 67.5, 70.0, 70.0, 72.5,
  ];
}

class MockRecord {
  final String exercise;
  final String value;
  final String date;
  const MockRecord({required this.exercise, required this.value, required this.date});
}

class MockWorkoutHistory {
  final String day;
  final String date;
  final String duration;
  final String volume;
  final int sets;
  final String feeling;
  const MockWorkoutHistory({
    required this.day, required this.date, required this.duration,
    required this.volume, required this.sets, required this.feeling,
  });
}

class MockExercise {
  final String name;
  final String muscle;
  final List<MockSet> sets;
  final double prevKg;
  final int prevReps;
  const MockExercise({
    required this.name, required this.muscle, required this.sets,
    required this.prevKg, required this.prevReps,
  });
}

class MockSet {
  final double kg;
  final int reps;
  final int? rir;
  final bool done;
  const MockSet({required this.kg, required this.reps, this.rir, required this.done});
}
