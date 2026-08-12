import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _kAiEnabled = 'ai_enabled';
  static const _kApiBase = 'api_base';
  static const _kApiKey = 'api_key';
  static const _kModel = 'api_model';
  static const _kAutoTest = 'auto_test';

  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings(
      aiEnabled: prefs.getBool(_kAiEnabled) ?? false,
      apiBase: prefs.getString(_kApiBase) ?? 'https://api.openai.com/v1',
      apiKey: prefs.getString(_kApiKey) ?? '',
      model: prefs.getString(_kModel) ?? 'gpt-4o-mini',
      autoTest: prefs.getBool(_kAutoTest) ?? false,
    );
  }

  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAiEnabled, settings.aiEnabled);
    await prefs.setString(_kApiBase, settings.apiBase.trim());
    await prefs.setString(_kApiKey, settings.apiKey.trim());
    await prefs.setString(_kModel, settings.model.trim());
    await prefs.setBool(_kAutoTest, settings.autoTest);
  }
}

class AppSettings {
  final bool aiEnabled;
  final String apiBase;
  final String apiKey;
  final String model;
  final bool autoTest;

  const AppSettings({
    this.aiEnabled = false,
    this.apiBase = 'https://api.openai.com/v1',
    this.apiKey = '',
    this.model = 'gpt-4o-mini',
    this.autoTest = false,
  });

  bool get hasAiConfig => aiEnabled && apiKey.isNotEmpty;
}
