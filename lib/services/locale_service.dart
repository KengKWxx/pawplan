import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleService extends ChangeNotifier {
  static const _key = 'pawplan_locale_code';

  String _languageCode = 'th';
  Locale get locale => Locale(_languageCode);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final String? saved = prefs.getString(_key);
    if (saved == 'en' || saved == 'th') {
      _languageCode = saved!;
    } else {
      _languageCode = 'th';
    }
    notifyListeners();
  }

  Future<void> setLanguageCode(String code) async {
    if (code != 'en' && code != 'th') return;
    _languageCode = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _languageCode);
    notifyListeners();
  }
}


