import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores only the language preference. Device credentials never go here.
class AppSettings extends ChangeNotifier {
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  static const _languageKey = 'lightning.language';
  Locale? _locale;
  bool _loading = true;
  bool _saving = false;
  bool _loadFailed = false;
  bool _saveFailed = false;
  bool _disposed = false;

  Locale? get locale => _locale;
  bool get loading => _loading;
  bool get saving => _saving;
  bool get loadFailed => _loadFailed;
  bool get saveFailed => _saveFailed;

  Future<void> load() async {
    if (_disposed || _saving) return;
    _loading = true;
    _loadFailed = false;
    notifyListeners();
    try {
      final language = await _preferences.getString(_languageKey);
      if (_disposed) return;
      _locale = language == 'en' || language == 'nl' ? Locale(language!) : null;
    } catch (_) {
      if (_disposed) return;
      _loadFailed = true;
    }
    if (_disposed) return;
    _loading = false;
    notifyListeners();
  }

  Future<void> setLanguage(String language) async {
    if (_disposed || _loading || _saving) return;
    if (!{'system', 'en', 'nl'}.contains(language)) {
      throw ArgumentError.value(language, 'language');
    }
    _saving = true;
    _saveFailed = false;
    notifyListeners();
    try {
      if (language == 'system') {
        await _preferences.remove(_languageKey);
      } else {
        await _preferences.setString(_languageKey, language);
      }
      if (_disposed) return;
      _locale = language == 'system' ? null : Locale(language);
      _loadFailed = false;
    } catch (_) {
      if (_disposed) return;
      _saveFailed = true;
    }
    if (_disposed) return;
    _saving = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class AppSettingsScope extends InheritedNotifier<AppSettings> {
  const AppSettingsScope({
    super.key,
    required AppSettings settings,
    required super.child,
  }) : super(notifier: settings);

  static AppSettings of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppSettingsScope>()!.notifier!;
}
