import 'package:flutter/material.dart';

enum AppLanguage { turkish, english }

class LocalizationService extends ChangeNotifier {
  AppLanguage _currentLanguage = AppLanguage.turkish;

  AppLanguage get currentLanguage => _currentLanguage;

  Locale get currentLocale {
    switch (_currentLanguage) {
      case AppLanguage.turkish:
        return const Locale('tr', 'TR');
      case AppLanguage.english:
        return const Locale('en', 'US');
      default:
        return const Locale('tr', 'TR');
    }
  }

  void setLanguage(AppLanguage language) {
    _currentLanguage = language;
    notifyListeners();
  }

  // UI Texts - Home Page
  String get appTitle => 'ASSIST AI';

  String get welcome {
    return _currentLanguage == AppLanguage.turkish
        ? 'Hoş Geldiniz!'
        : 'Welcome!';
  }

  String get pendingTasks {
    return _currentLanguage == AppLanguage.turkish
        ? 'bekleyen göreviniz var'
        : 'pending tasks';
  }

  String get quickAccess {
    return _currentLanguage == AppLanguage.turkish
        ? 'Hızlı Erişim'
        : 'Quick Access';
  }

  String get calendar {
    return _currentLanguage == AppLanguage.turkish
        ? 'Takvim'
        : 'Calendar';
  }

  String get settings {
    return _currentLanguage == AppLanguage.turkish
        ? 'Ayarlar'
        : 'Settings';
  }

  String get upcomingTasks {
    return _currentLanguage == AppLanguage.turkish
        ? 'Yaklaşan Görevler'
        : 'Upcoming Tasks';
  }

  String get aiRecommendations {
    return _currentLanguage == AppLanguage.turkish
        ? 'ASSIST AI Önerileri'
        : 'ASSIST AI Recommendations';
  }

  String get addEvent {
    return _currentLanguage == AppLanguage.turkish
        ? 'Etkinlik Ekle'
        : 'Add Event';
  }

  String get month {
    return _currentLanguage == AppLanguage.turkish
        ? 'Ay'
        : 'Month';
  }

  String get week {
    return _currentLanguage == AppLanguage.turkish
        ? 'Hafta'
        : 'Week';
  }

  String get today {
    return _currentLanguage == AppLanguage.turkish
        ? 'BUGÜN'
        : 'TODAY';
  }

  // Settings Page Texts
  String get notifications {
    return _currentLanguage == AppLanguage.turkish
        ? 'Bildirimler'
        : 'Notifications';
  }

  String get privacy {
    return _currentLanguage == AppLanguage.turkish
        ? 'Gizlilik'
        : 'Privacy';
  }

  String get language {
    return _currentLanguage == AppLanguage.turkish
        ? 'Dil'
        : 'Language';
  }

  String get helpAbout {
    return _currentLanguage == AppLanguage.turkish
        ? 'Yardım & Hakkında'
        : 'Help & About';
  }

  String get appLanguage {
    return _currentLanguage == AppLanguage.turkish
        ? 'Uygulama Dili'
        : 'App Language';
  }

  String get selectLanguage {
    return _currentLanguage == AppLanguage.turkish
        ? 'Uygulamanın görüntüleneceği dili seçin'
        : 'Select the language for the app';
  }

  String get save {
    return _currentLanguage == AppLanguage.turkish
        ? 'Kaydet'
        : 'Save';
  }

  String get help {
    return _currentLanguage == AppLanguage.turkish
        ? 'Yardım'
        : 'Help';
  }

  String get about {
    return _currentLanguage == AppLanguage.turkish
        ? 'Hakkında'
        : 'About';
  }

  String get faq {
    return _currentLanguage == AppLanguage.turkish
        ? 'Sıkça Sorulan Sorular'
        : 'Frequently Asked Questions';
  }

  String get developerTeam {
    return _currentLanguage == AppLanguage.turkish
        ? 'Geliştirici Ekibi'
        : 'Developer Team';
  }

  String get contact {
    return _currentLanguage == AppLanguage.turkish
        ? 'İletişim'
        : 'Contact';
  }

  // Voice Command Section
  String get giveCommand {
    return _currentLanguage == AppLanguage.turkish
        ? "ASSIST AI'a Komut Ver"
        : 'Give Command to ASSIST AI';
  }

  String get voiceCommandHint {
    return _currentLanguage == AppLanguage.turkish
        ? 'Sesli veya yazılı olarak görev ekleyin'
        : 'Add tasks via voice or text';
  }

  String get exampleCommand {
    return _currentLanguage == AppLanguage.turkish
        ? 'Örnek: "Yarın saat 15:00\'te toplantı ekle"'
        : 'Example: "Add meeting tomorrow at 3:00 PM"';
  }

  String get listening {
    return _currentLanguage == AppLanguage.turkish
        ? 'Dinleniyor...'
        : 'Listening...';
  }

  String get send {
    return _currentLanguage == AppLanguage.turkish
        ? 'Gönder'
        : 'Send';
  }

  // Calendar Page
  String get noEvents {
    return _currentLanguage == AppLanguage.turkish
        ? 'Etkinlik yok'
        : 'No events';
  }

  String get longPressToAdd {
    return _currentLanguage == AppLanguage.turkish
        ? 'Eklemek için uzun basın'
        : 'Long press to add';
  }

  // Form/Dialog Texts
  String get cancel {
    return _currentLanguage == AppLanguage.turkish
        ? 'İptal'
        : 'Cancel';
  }

  String get eventTitle {
    return _currentLanguage == AppLanguage.turkish
        ? 'Etkinlik Başlığı*'
        : 'Event Title*';
  }

  String get start {
    return _currentLanguage == AppLanguage.turkish
        ? 'Başlangıç:'
        : 'Start:';
  }

  String get end {
    return _currentLanguage == AppLanguage.turkish
        ? 'Bitiş:'
        : 'End:';
  }

  String get hour {
    return _currentLanguage == AppLanguage.turkish
        ? 'Saat'
        : 'Hour';
  }

  String get minute {
    return _currentLanguage == AppLanguage.turkish
        ? 'Dakika'
        : 'Minute';
  }

  String get descriptionOptional {
    return _currentLanguage == AppLanguage.turkish
        ? 'Açıklama (İsteğe Bağlı)'
        : 'Description (Optional)';
  }

  String get requiredFields {
    return _currentLanguage == AppLanguage.turkish
        ? '* Zorunlu alanlar\nSaat ve dakikayı 24 saat formatında giriniz'
        : '* Required fields\nEnter hour and minute in 24-hour format';
  }

  // Error Messages
  String get fillRequiredFields {
    return _currentLanguage == AppLanguage.turkish
        ? 'Lütfen zorunlu alanları doldurun'
        : 'Please fill in all required fields';
  }

  String get invalidTimeFormat {
    return _currentLanguage == AppLanguage.turkish
        ? 'Geçersiz saat formatı. Lütfen geçerli bir saat giriniz'
        : 'Invalid time format. Please enter a valid time';
  }

  String get eventAdded {
    return _currentLanguage == AppLanguage.turkish
        ? 'etkinliği eklendi'
        : 'event added';
  }

  // Date formatting
  String formatDate(DateTime date, {String format = 'dd.MM.yyyy'}) {
    final dayStr = date.day.toString().padLeft(2, '0');
    final monthStr = date.month.toString().padLeft(2, '0');
    final yearStr = date.year.toString();

    return format
        .replaceAll('dd', dayStr)
        .replaceAll('MM', monthStr)
        .replaceAll('yyyy', yearStr);
  }

  String getMonthName(int month) {
    final months = _currentLanguage == AppLanguage.turkish
        ? const ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık']
        : const ['January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'];

    return months[month - 1];
  }

  String getDayName(int weekday, {bool short = true}) {
    if (_currentLanguage == AppLanguage.turkish) {
      return short
          ? const ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'][weekday - 1]
          : const ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'][weekday - 1];
    } else {
      return short
          ? const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][weekday - 1]
          : const ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][weekday - 1];
    }
  }
}