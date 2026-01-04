import 'package:Assist/services/localization_service.dart';
import 'package:Assist/services/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'injection_container.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final locator = ServiceLocator();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: locator.themeService),
        ChangeNotifierProvider.value(value: locator.localizationService),
        ChangeNotifierProvider.value(value: locator.homeViewModel),
        ChangeNotifierProvider.value(value: locator.calendarViewModel),
        ChangeNotifierProvider.value(value: locator.settingsViewModel),
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