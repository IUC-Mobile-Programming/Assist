import 'package:Assist/services/localization_service.dart';
import 'package:Assist/services/theme_service.dart';
import 'package:Assist/services/database_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'injection_container.dart';

void main() {
  setupDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ServiceLocator().themeService),
        ChangeNotifierProvider(create: (_) => ServiceLocator().localizationService),
        ChangeNotifierProvider(create: (_) => ServiceLocator().databaseService),
        ChangeNotifierProvider(create: (_) => ServiceLocator().homeViewModel),
        ChangeNotifierProvider(create: (_) => ServiceLocator().calendarViewModel),
        ChangeNotifierProvider(create: (_) => ServiceLocator().settingsViewModel),
      ],
      child: Consumer2<ThemeService, LocalizationService>(
        builder: (context, themeService, localizationService, _) {
          return MaterialApp(
            title: 'ASSIST AI',
            theme: themeService.currentTheme,
            locale: localizationService.currentLocale,
            home: const App(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}