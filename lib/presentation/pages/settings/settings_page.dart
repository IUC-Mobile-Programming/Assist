import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Assist/presentation/viewmodels/settings_viewmodel.dart';
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
            case SettingsSection.privacy:
              return _buildPrivacyPage(viewModel, context);
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
          icon: Icons.security,
          title: localizationService.privacy,
          onTap: () => viewModel.setSection(SettingsSection.privacy),
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
          title: Text(localizationService.currentLanguage == AppLanguage.turkish
              ? 'Bildirimleri Aç/Kapat'
              : 'Enable/Disable Notifications'),
          trailing: Switch(
            value: viewModel.notificationsEnabled,
            onChanged: viewModel.toggleNotifications,
          ),
        ),
        const Divider(),
        ListTile(
          title: Text(localizationService.currentLanguage == AppLanguage.turkish
              ? 'Ses'
              : 'Sound'),
          subtitle: Text(localizationService.currentLanguage == AppLanguage.turkish
              ? 'Bildirim sesini aç/kapat'
              : 'Enable/disable notification sound'),
          trailing: Switch(
            value: viewModel.soundEnabled,
            onChanged: viewModel.toggleSound,
          ),
        ),
        const Divider(),
        ListTile(
          title: Text(localizationService.currentLanguage == AppLanguage.turkish
              ? 'Titreşim'
              : 'Vibration'),
          subtitle: Text(localizationService.currentLanguage == AppLanguage.turkish
              ? 'Bildirim titreşimini aç/kapat'
              : 'Enable/disable notification vibration'),
          trailing: Switch(
            value: viewModel.vibrationEnabled,
            onChanged: viewModel.toggleVibration,
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacyPage(SettingsViewModel viewModel, BuildContext context) {
    final localizationService = Provider.of<LocalizationService>(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildBackButton(() => viewModel.setSection(SettingsSection.main), context),
        const SizedBox(height: 20),
        ListTile(
          title: Text(localizationService.currentLanguage == AppLanguage.turkish
              ? 'Veri Gizliliği'
              : 'Data Privacy'),
          subtitle: Text(localizationService.currentLanguage == AppLanguage.turkish
              ? 'Kişisel verilerinizin nasıl kullanıldığını öğrenin'
              : 'Learn how your personal data is used'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
        const Divider(),
        ListTile(
          title: Text(localizationService.currentLanguage == AppLanguage.turkish
              ? 'Konum Gizliliği'
              : 'Location Privacy'),
          subtitle: Text(localizationService.currentLanguage == AppLanguage.turkish
              ? 'Konum verilerinizin kullanımı'
              : 'Use of your location data'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
        const Divider(),
        ListTile(
          title: Text(localizationService.currentLanguage == AppLanguage.turkish
              ? 'Verilerimi Sil'
              : 'Delete My Data'),
          subtitle: Text(localizationService.currentLanguage == AppLanguage.turkish
              ? 'Tüm kişisel verilerinizi silin'
              : 'Delete all your personal data'),
          trailing: const Icon(Icons.delete_outline, color: Colors.red),
          textColor: Colors.red,
          onTap: () {},
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
          title: const Text('Türkçe'),
          value: AppLanguage.turkish,
          groupValue: viewModel.selectedLanguage,
          onChanged: (value) => viewModel.setLanguage(value!),
        ),
        const Divider(),
        RadioListTile<AppLanguage>(
          title: const Text('English'),
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
                    viewModel.selectedLanguage == AppLanguage.turkish
                        ? 'Dil Türkçe olarak değiştirildi'
                        : 'Language changed to English',
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
    return Center(
      child: Text(
        'Version 1.0.0',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).hintColor,
        ),
      ),
    );
  }
}