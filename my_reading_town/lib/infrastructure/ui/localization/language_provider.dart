import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_reading_town/infrastructure/persistence/database_helper.dart';

class LanguageProvider extends ChangeNotifier {
  static const String defaultLocale = 'en';

  static const Map<String, Map<String, String>> supportedLanguages = {
    'en': {'name': 'English', 'countryCode': 'US'},
    'es': {'name': 'Español', 'countryCode': 'ES'},
    'fr': {'name': 'Français', 'countryCode': 'FR'},
    'it': {'name': 'Italiano', 'countryCode': 'IT'},
    'pt': {'name': 'Português', 'countryCode': 'PT'},
  };

  String _currentLocale = defaultLocale;
  Map<String, String> _translations = {};

  String get currentLocale => _currentLocale;

  String translate(String key, {String? fallback}) =>
      _translations[key] ?? fallback ?? key;

  Future<void> load(String locale) async {
    final validLocale =
        supportedLanguages.containsKey(locale) ? locale : defaultLocale;
    if (_currentLocale == validLocale && _translations.isNotEmpty) return;
    _currentLocale = validLocale;
    await _loadTranslations(validLocale);
    notifyListeners();
  }

  Future<void> _loadTranslations(String locale) async {
    final jsonString =
        await rootBundle.loadString('assets/messages/$locale/$locale.json');
    final Map<String, dynamic> jsonMap = json.decode(jsonString);
    _translations =
        jsonMap.map((key, value) => MapEntry(key, value.toString()));
  }

  Future<void> changeLanguage(String locale) async {
    if (!supportedLanguages.containsKey(locale)) return;
    await _loadTranslations(locale);
    _currentLocale = locale;
    await DatabaseHelper().updateLanguage(locale);
    notifyListeners();
  }
}
