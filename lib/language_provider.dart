import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  String _languageCode = 'en';

  String get languageCode => _languageCode;

  Future<void> loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _languageCode = prefs.getString('languageCode') ?? 'en';
    notifyListeners();
  }

  Future<void> setLanguage(String languageCode) async {
    _languageCode = languageCode;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', languageCode);

    notifyListeners();
  }
}
