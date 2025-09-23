import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  // Set Arabic as the default locale
  Locale _locale = const Locale('ar'); // Changed from 'en' to 'ar'

  Locale get locale => _locale;

  LanguageProvider() {
    _loadSavedLanguage();
  }

  // Load saved language preference or default to Arabic
  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguageCode = prefs.getString('selected_language');

      if (savedLanguageCode != null) {
        // Use saved language if available
        _locale = Locale(savedLanguageCode);
        print('Loaded saved language: $savedLanguageCode');
      } else {
        // Default to Arabic if no saved preference
        _locale = const Locale('ar');
        print('No saved language - defaulting to Arabic');
      }

      notifyListeners();
    } catch (e) {
      print('Error loading language preference: $e');
      // Keep default Arabic locale on error
      _locale = const Locale('ar');
      notifyListeners();
    }
  }

  // Change language and save preference
  Future<void> changeLanguage(String languageCode) async {
    try {
      _locale = Locale(languageCode);

      // Save the selected language
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_language', languageCode);

      print('Language changed to: $languageCode');
      notifyListeners();
    } catch (e) {
      print('Error changing language: $e');
    }
  }

  // Toggle between Arabic and English
  Future<void> toggleLanguage() async {
    final newLanguageCode = _locale.languageCode == 'ar' ? 'en' : 'ar';
    await changeLanguage(newLanguageCode);
  }

  // Check if current language is Arabic
  bool get isArabic => _locale.languageCode == 'ar';

  // Check if current language is English
  bool get isEnglish => _locale.languageCode == 'en';

  // Get language display name
  String get currentLanguageName {
    switch (_locale.languageCode) {
      case 'ar':
        return 'العربية';
      case 'en':
        return 'English';
      default:
        return 'العربية'; // Default to Arabic
    }
  }
}