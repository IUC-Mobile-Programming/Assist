import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Assist/presentation/viewmodels/settings_viewmodel.dart';
import 'package:Assist/presentation/viewmodels/home_viewmodel.dart';
import 'package:Assist/presentation/pages/settings/help_about_page.dart';
import 'package:Assist/services/localization_service.dart';
import 'package:Assist/core/app_theme.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizationService = Provider.of<LocalizationService>(context);

    return ChangeNotifierProvider(
      create: (_) => SettingsViewModel(
        localizationService: localizationService,
      ),
      child: Consumer<SettingsViewModel>(
        builder: (context, viewModel, _) {
          switch (viewModel.currentSection) {
            case SettingsSection.main:
              return _buildMainSettings(viewModel, context);
            case SettingsSection.notifications:
              return _buildNotificationsPage(viewModel, context);
            case SettingsSection.data:
              return _buildDataPage(viewModel, context);
            case SettingsSection.language:
              return _buildLanguagePage(viewModel, context);
            case SettingsSection.helpAbout:
              return const HelpAboutPage();
          }
        },
      ),
    );
  }

  Widget _buildMainSettings(SettingsViewModel viewModel, BuildContext context) {
    final localizationService = Provider.of<LocalizationService>(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 20),
        Text(
          localizationService.settings,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        _buildSettingItem(
          icon: Icons.notifications,
          title: localizationService.notifications,
          onTap: () => viewModel.setSection(SettingsSection.notifications),
          context: context,
        ),
        const Divider(),
        _buildSettingItem(
          icon: Icons.storage,
          title: localizationService.data,
          onTap: () => viewModel.setSection(SettingsSection.data),
          context: context,
        ),
        const Divider(),
        _buildSettingItem(
          icon: Icons.language,
          title: localizationService.language,
          onTap: () => viewModel.setSection(SettingsSection.language),
          context: context,
        ),
        const Divider(),
        _buildSettingItem(
          icon: Icons.help_outline,
          title: localizationService.helpAbout,
          onTap: () => viewModel.setSection(SettingsSection.helpAbout),
          context: context,
        ),
        const SizedBox(height: 30),
        _buildAppVersion(context),
      ],
    );
  }

  Widget _buildNotificationsPage(SettingsViewModel viewModel, BuildContext context) {
    final localizationService = Provider.of<LocalizationService>(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildBackButton(() => viewModel.setSection(SettingsSection.main), context),
        const SizedBox(height: 20),
        ListTile(
          title: Text(localizationService.enableDisableNotifications),
          trailing: Switch(
            value: viewModel.notificationsEnabled,
            onChanged: viewModel.toggleNotifications,
          ),
        ),
        const Divider(),
        ListTile(
          title: Text(localizationService.sound),
          subtitle: Text(localizationService.enableDisableNotificationSound),
          trailing: Switch(
            value: viewModel.soundEnabled,
            onChanged: viewModel.toggleSound,
          ),
        ),
        const Divider(),
        ListTile(
          title: Text(localizationService.vibration),
          subtitle: Text(localizationService.enableDisableNotificationVibration),
          trailing: Switch(
            value: viewModel.vibrationEnabled,
            onChanged: viewModel.toggleVibration,
          ),
        ),
      ],
    );
  }

  Widget _buildDataPage(SettingsViewModel viewModel, BuildContext context) {
    final localizationService = Provider.of<LocalizationService>(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildBackButton(() => viewModel.setSection(SettingsSection.main), context),
        const SizedBox(height: 20),
        ListTile(
          title: Text(localizationService.deleteMyData),
          subtitle: Text(localizationService.deleteAllPersonalData),
          trailing: const Icon(Icons.delete_outline, color: Colors.red),
          textColor: Colors.red,
          onTap: () => _showDeleteConfirmationDialog(context, viewModel, localizationService),
        ),
      ],
    );
  }

  Widget _buildLanguagePage(SettingsViewModel viewModel, BuildContext context) {
    final localizationService = Provider.of<LocalizationService>(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildBackButton(() => viewModel.setSection(SettingsSection.main), context),
        const SizedBox(height: 20),
        ListTile(
          title: Text(localizationService.appLanguage),
          subtitle: Text(localizationService.selectLanguage),
        ),
        const Divider(),
        RadioListTile<AppLanguage>(
          title: Text(localizationService.turkish),
          value: AppLanguage.turkish,
          groupValue: viewModel.selectedLanguage,
          onChanged: (value) => viewModel.setLanguage(value!),
        ),
        const Divider(),
        RadioListTile<AppLanguage>(
          title: Text(localizationService.english),
          value: AppLanguage.english,
          groupValue: viewModel.selectedLanguage,
          onChanged: (value) => viewModel.setLanguage(value!),
        ),
        const SizedBox(height: 30),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ElevatedButton(
            onPressed: () {
              viewModel.saveLanguage();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    localizationService.languageChanged,
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            },
            child: Text(localizationService.save),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required BuildContext context,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildBackButton(VoidCallback onBack, BuildContext context) {
    final localizationService = Provider.of<LocalizationService>(context);

    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
        const SizedBox(width: 8),
        Text(
          localizationService.settings,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAppVersion(BuildContext context) {
    final localizationService = Provider.of<LocalizationService>(context);
    
    return Center(
      child: Text(
        localizationService.appVersion,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).hintColor,
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, SettingsViewModel viewModel, LocalizationService localizationService) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(localizationService.deleteMyData),
          content: Text(localizationService.deleteDataConfirmation),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(localizationService.cancel),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await viewModel.deleteAllData();
                  if (context.mounted) {
                    Navigator.of(context).pop(); // Close dialog
                    
                    // Reload HomeViewModel before popping back to home page
                    try {
                      final homeViewModel = Provider.of<HomeViewModel>(context, listen: false);
                      await homeViewModel.loadTasks();
                    } catch (_) {
                      // HomeViewModel might not be in scope, continue anyway
                    }
                    
                    if (context.mounted) {
                      Navigator.of(context).pop(); // Close settings page and return to home
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            localizationService.deleteDataSuccess,
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: AppTheme.successColor,
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.of(context).pop(); // Close dialog on error
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          localizationService.deleteDataError,
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Text(
                localizationService.delete,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}