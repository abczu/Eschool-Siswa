import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

enum Environment { prod, testing, dev }

class AppConfig {
  static const String _envBoxKey = "envBox";
  static const String _currentEnvKey = "currentEnv";

  // === Daftar URL per environment ===
  static const String devUrl = "https://devapisekolah.eschool.ac.id";
  static const String prodUrl = "https://apisekolah.eschool.ac.id";
  static const String testingUrl = "https://testapisekolah.eschool.ac.id";

  // State aktif environment
  static Environment _currentEnv = Environment.prod;

  // Notifier untuk merebuild widget root saat environment berubah
  static final ValueNotifier<Environment> envNotifier =
      ValueNotifier(_currentEnv);

  static Environment get currentEnv => _currentEnv;
  static bool get isDev => _currentEnv == Environment.dev;
  static bool get isProd => _currentEnv == Environment.prod;
  static bool get isTesting => _currentEnv == Environment.testing;

  /// Panggil ini di [initializeApp] sebelum runApp()
  static Future<void> init() async {
    final box = await Hive.openBox(_envBoxKey);
    final savedIndex =
        box.get(_currentEnvKey, defaultValue: Environment.prod.index) as int;

    if (savedIndex >= 0 && savedIndex < Environment.values.length) {
      _currentEnv = Environment.values[savedIndex];
    } else {
      _currentEnv = Environment.prod;
    }
    envNotifier.value = _currentEnv;
  }

  /// Simpan pilihan environment dan perbarui state
  static Future<void> setEnvironment(Environment env) async {
    _currentEnv = env;
    envNotifier.value = env;
    final box = Hive.box(_envBoxKey);
    await box.put(_currentEnvKey, env.index);
  }

  /// URL dasar yang sedang aktif
  static String get baseUrl {
    switch (_currentEnv) {
      case Environment.dev:
        return devUrl;
      case Environment.testing:
        return testingUrl;
      case Environment.prod:
        return prodUrl;
    }
  }

  static String get databaseUrl => "$baseUrl/api/";

  /// Label untuk ditampilkan di UI
  static String get envName {
    switch (_currentEnv) {
      case Environment.dev:
        return "Development";
      case Environment.testing:
        return "Testing";
      case Environment.prod:
        return "Production";
    }
  }

  /// Warna badge untuk DevMode banner
  static String get envColor {
    switch (_currentEnv) {
      case Environment.dev:
        return "0xFFFF9800"; // orange
      case Environment.testing:
        return "0xFF2196F3"; // biru
      case Environment.prod:
        return "0xFF4CAF50"; // hijau
    }
  }
}
