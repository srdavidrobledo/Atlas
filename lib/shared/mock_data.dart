// Mock data — temporal hasta integrar Firebase
// No usar Firestore ni Hive aquí

class MockUser {
  static const String memberSince = 'Enero 2026';
  static const double currentWeight = 80.6;
  static const double targetWeight = 82.0;
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

class MockSet {
  final double kg;
  final int reps;
  final int? rir;
  final bool done;
  const MockSet({required this.kg, required this.reps, this.rir, required this.done});

  Map<String, dynamic> toJson() => {'kg': kg, 'reps': reps, 'rir': rir, 'done': done};

  factory MockSet.fromJson(Map<String, dynamic> m) => MockSet(
    kg: (m['kg'] as num).toDouble(),
    reps: m['reps'] as int,
    rir: m['rir'] as int?,
    done: m['done'] as bool,
  );
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

  Map<String, dynamic> toJson() => {
    'name': name,
    'muscle': muscle,
    'sets': sets.map((s) => s.toJson()).toList(),
    'prevKg': prevKg,
    'prevReps': prevReps,
  };

  factory MockExercise.fromJson(Map<String, dynamic> m) => MockExercise(
    name: m['name'] as String,
    muscle: m['muscle'] as String,
    sets: (m['sets'] as List).map((s) => MockSet.fromJson(Map<String, dynamic>.from(s as Map))).toList(),
    prevKg: (m['prevKg'] as num).toDouble(),
    prevReps: m['prevReps'] as int,
  );
}

class MockRoutineDay {
  final String id;
  final String name;
  final List<MockExercise> exercises;

  const MockRoutineDay({
    required this.id,
    required this.name,
    required this.exercises,
  });

  int get exerciseCount => exercises.length;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'exercises': exercises.map((e) => e.toJson()).toList(),
  };

  factory MockRoutineDay.fromJson(Map<String, dynamic> m) => MockRoutineDay(
    id: m['id'] as String,
    name: m['name'] as String,
    exercises: (m['exercises'] as List).map((e) => MockExercise.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
  );
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'days': days.map((d) => d.toJson()).toList(),
    'totalSessions': totalSessions,
    'lastUsed': lastUsed,
  };

  factory MockRoutine.fromJson(Map<String, dynamic> m) => MockRoutine(
    id: m['id'] as String,
    name: m['name'] as String,
    isActive: false,
    days: (m['days'] as List).map((d) => MockRoutineDay.fromJson(Map<String, dynamic>.from(d as Map))).toList(),
    totalSessions: m['totalSessions'] as int,
    lastUsed: m['lastUsed'] as String,
  );
}

class MockData {
  // Inicia vacío. Las rutinas se cargan de Hive (RoutineStore.init)
  // o se generan al completar el onboarding (AtlasRoutineGenerator).
  static final List<MockRoutine> routines = [];

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

