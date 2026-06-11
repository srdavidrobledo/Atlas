import 'dart:convert';
import '../../../core/storage/atlas_storage.dart';
import '../models/onboarding_models.dart';

class OnboardingStore {
  static const _key = 'onboarding_data';
  static OnboardingData _data = OnboardingData.defaults();

  static OnboardingData get data => _data;
  static bool get isCompleted => _data.onboardingCompleted;

  static Future<void> init() async {
    final raw = AtlasStorage.settings.get(_key) as String?;
    if (raw != null) {
      _data = OnboardingData.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    }
  }

  static Future<void> save(OnboardingData data) async {
    _data = data;
    await AtlasStorage.settings.put(_key, jsonEncode(data.toJson()));
  }

  static Future<void> complete(OnboardingData data) async {
    await save(data.copyWith(onboardingCompleted: true));
  }

  /// Auto-completa el onboarding para usuarios existentes que ya tienen datos.
  /// Llamar DESPUÉS de inicializar RoutineStore y WorkoutSessionStore.
  static Future<void> migrateIfNeeded({
    required bool hasUserRoutines,
    required bool hasSessions,
  }) async {
    if (isCompleted) return;
    if (hasUserRoutines || hasSessions) {
      await complete(OnboardingData.defaults());
    }
  }

  static Future<void> reset() async {
    _data = OnboardingData.defaults();
    await AtlasStorage.settings.delete(_key);
  }
}
