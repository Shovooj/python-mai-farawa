import 'package:shared_preferences/shared_preferences.dart';

// Simple wrapper around SharedPreferences for reading and writing the
// currently selected app language.
class LanguageService {
  static const String _languageKey = 'selected_language';

  Future<void> setSelectedLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language);
  }

  Future<String> getSelectedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey) ?? 'ha';
  }
}
