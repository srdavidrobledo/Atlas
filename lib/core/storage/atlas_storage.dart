import 'package:hive_flutter/hive_flutter.dart';

class AtlasStorage {
  static late Box _settings;
  static late Box _sessions;
  static late Box _routines;

  static Box get settings => _settings;
  static Box get sessions => _sessions;
  static Box get routines => _routines;

  static Future<void> init() async {
    await Hive.initFlutter();
    _settings = await Hive.openBox('settings');
    _sessions = await Hive.openBox('sessions');
    _routines = await Hive.openBox('routines');
  }
}
