import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Manages the selected language for the app and persists it locally.
// Widgets subscribe to this provider to rebuild when the language changes.
class LanguageProvider extends ChangeNotifier {
  // The saved language code, e.g. 'en' or 'ha'. Default is Hausa ('ha').
  String _languageCode = 'ha';

  // Public getter used by UI code to read the current language.
  String get languageCode => _languageCode;

  // Loads the saved language from local storage. If none exists, keeps the default.
  // Notifies listeners after loading so UI can update.
  Future<void> loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _languageCode = prefs.getString('languageCode') ?? 'ha';
    notifyListeners();
  }

  // Sets a new language, persists it, and notifies listeners to update the UI.
  // Parameters:
  // - languageCode: the new locale code to set (e.g. 'en' or 'ha').
  Future<void> setLanguage(String languageCode) async {
    _languageCode = languageCode;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', languageCode);

    notifyListeners();
  }
}
