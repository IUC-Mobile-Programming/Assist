import 'package:Assist/services/localization_service.dart';
import 'package:Assist/services/theme_service.dart';
import 'package:Assist/services/database_service.dart';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'app.dart';
import 'injection_container.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _initDatabaseFactory();
  
  // Uygulamayı başlat, servisleri sonra yükle
  runApp(const MyApp());
  
  // Ağır işlemleri ilk çerçeveden sonra yap
  WidgetsBinding.instance.addPostFrameCallback((_) {
    setupDependencies();
  });
}

void _initDatabaseFactory() {
  if (kIsWeb) {
    return;
  }
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
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
            home: const _AppInitializer(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

class _AppInitializer extends StatelessWidget {
  const _AppInitializer();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _waitForInitialization(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Initializing...'),
                ],
              ),
            ),
          );
        }
        return const App();
      },
    );
  }

  Future<void> _waitForInitialization() async {
    while (!ServiceLocator().isInitialized) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }
}
