import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:assist_ai/presentation/viewmodels/settings_viewmodel.dart';
import 'package:assist_ai/services/localization_service.dart';

class HelpAboutPage extends StatelessWidget {
  const HelpAboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<SettingsViewModel>(context, listen: false);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBackButton(() => viewModel.setSection(SettingsSection.main), context),
          const SizedBox(height: 20),
          _buildHelpSection(theme, isDarkMode),
          const SizedBox(height: 20),
          _buildAboutSection(theme, isDarkMode),
        ],
      ),
    );
  }

  Widget _buildBackButton(VoidCallback onBack, BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
        const SizedBox(width: 8),
        Text(
          'Yardım & Hakkında',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildHelpSection(ThemeData theme, bool isDarkMode) {
    return Card(
      color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.help_outline,
                  size: 30,
                  color: theme.primaryColor,
                ),
                const SizedBox(width: 10),
                Text(
                  'Yardım',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Sıkça Sorulan Sorular',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            _buildFAQItem(
              question: 'Görev nasıl eklerim?',
              answer: 'Ana ekrandaki "+" butonuna tıklayarak veya ASSIST AI\'a sesli komut vererek görev ekleyebilirsiniz.',
              theme: theme,
            ),
            _buildFAQItem(
              question: 'Bildirimler nasıl ayarlanır?',
              answer: 'Ayarlar > Bildirimler bölümünden bildirim tercihlerinizi düzenleyebilirsiniz.',
              theme: theme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection(ThemeData theme, bool isDarkMode) {
    return Card(
      color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 30,
                  color: const Color(0xFF4CAF50),
                ),
                const SizedBox(width: 10),
                Text(
                  'Hakkında',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildAppInfo(theme, isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildAppInfo(ThemeData theme, bool isDarkMode) {
    return Center(
      child: Column(
        children: [
          Text(
            'ASSIST AI',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Version 1.0.0',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 80,
              height: 80,
              color: isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
              child: Image.asset("lib/assets/images/img.png")
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Yapay zeka destekli kişisel asistan uygulaması',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem({
    required String question,
    required String answer,
    required ThemeData theme,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            answer,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}