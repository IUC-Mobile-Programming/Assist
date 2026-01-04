import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Assist/presentation/pages/home/home_page.dart';
import 'package:Assist/presentation/pages/calendar/calendar_page.dart';
import 'package:Assist/presentation/pages/settings/settings_page.dart';
import 'package:Assist/services/theme_service.dart';
import 'package:Assist/services/localization_service.dart';
import 'package:Assist/presentation/widgets/add_task_bottom_sheet.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {


  int _currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final localizationService = Provider.of<LocalizationService>(context);

    return Scaffold(
      drawer: _buildDrawer(context),
      appBar: _buildAppBar(context, localizationService),
      body: _buildCurrentPage(),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  Widget _buildCurrentPage() {
    switch (_currentPageIndex) {
      case 0:
        return const HomePage();
      case 1:
        return const CalendarPage();
      case 2:
        return const SettingsPage();
      default:
        return const HomePage();
    }
  }

  Widget _buildDrawer(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildDrawerHeader(context),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Ana Ekran'),
            onTap: () {
              setState(() => _currentPageIndex = 0);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Takvim'),
            onTap: () {
              setState(() => _currentPageIndex = 1);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(themeService.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            title: const Text('Tema Değiştir'),
            trailing: Switch(
              value: themeService.isDarkMode,
              onChanged: (_) => themeService.toggleTheme(),
            ),
            onTap: themeService.toggleTheme,
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Ayarlar'),
            onTap: () {
              setState(() => _currentPageIndex = 2);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);

    return DrawerHeader(
      decoration: BoxDecoration(
        color: themeService.isDarkMode
            ? const Color(0xFF1E1E1E)
            : const Color(0xFF2196F3),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: themeService.isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Image.asset("lib/assets/images/img.png")
          ),
          const SizedBox(height: 16),
          const Text(
            'ASSIST AI',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, LocalizationService localizationService) {
    final themeService = Provider.of<ThemeService>(context);
    final titles = ['ASSIST AI', 'Takvim', 'Ayarlar'];

    return AppBar(
      title: Text(titles[_currentPageIndex]),
      backgroundColor: themeService.isDarkMode
          ? Colors.grey[900]
          : const Color(0xFF2196F3),
      foregroundColor: Colors.white,
      elevation: 4,
    );
  }

  Widget? _buildFloatingActionButton(BuildContext context) {
    if (_currentPageIndex != 0) return null;

    return FloatingActionButton(
      backgroundColor: const Color(0xFF4CAF50),
      onPressed: () {
        _showAddTaskBottomSheet(context);
      },
      child: const Icon(Icons.add, color: Colors.white),
    );
  }

  void _showAddTaskBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddTaskBottomSheet(),
    );
  }
}