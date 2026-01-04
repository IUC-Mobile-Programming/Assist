import 'package:flutter/material.dart';
import 'package:Assist/services/theme_service.dart';
import 'package:Assist/services/localization_service.dart';
import 'package:Assist/presentation/viewmodels/base_viewmodel.dart';

enum SettingsSection { main, notifications, privacy, language, helpAbout }

class SettingsViewModel extends BaseViewModel {
  final ThemeService? _themeService;
  final LocalizationService _localizationService;

  SettingsSection _currentSection = SettingsSection.main;
  SettingsSection get currentSection => _currentSection;

  bool _notificationsEnabled = true;
  bool get notificationsEnabled => _notificationsEnabled;

  bool _soundEnabled = true;
  bool get soundEnabled => _soundEnabled;

  bool _vibrationEnabled = true;
  bool get vibrationEnabled => _vibrationEnabled;

  AppLanguage _selectedLanguage = AppLanguage.turkish;
  AppLanguage get selectedLanguage => _selectedLanguage;

  SettingsViewModel({
    ThemeService? themeService,
    required LocalizationService localizationService,
  }) : _themeService = themeService,
        _localizationService = localizationService {
    _selectedLanguage = _localizationService.currentLanguage;
  }

  void setSection(SettingsSection section) {
    _currentSection = section;
    notifyListeners();
  }

  void toggleNotifications(bool value) {
    _notificationsEnabled = value;
    notifyListeners();
  }

  void toggleSound(bool value) {
    _soundEnabled = value;
    notifyListeners();
  }

  void toggleVibration(bool value) {
    _vibrationEnabled = value;
    notifyListeners();
  }

  void setLanguage(AppLanguage language) {
    _selectedLanguage = language;
    notifyListeners();
  }

  void saveLanguage() {
    _localizationService.setLanguage(_selectedLanguage);
    notifyListeners();
  }

  void toggleTheme() {
    if (_themeService != null) {
      _themeService!.toggleTheme();
    }
  }

  bool get isDarkMode => _themeService?.isDarkMode ?? false;
}