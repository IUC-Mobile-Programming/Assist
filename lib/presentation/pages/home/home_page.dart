import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Assist/presentation/viewmodels/home_viewmodel.dart';
import 'package:Assist/presentation/widgets/task_item.dart';
import 'package:Assist/presentation/widgets/recommendation_item.dart';
import 'package:Assist/core/app_theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  late HomeViewModel _viewModel;
  final TextEditingController _voiceController = TextEditingController();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    // Get the ViewModel from Provider after first frame and attach listener
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel = Provider.of<HomeViewModel>(context, listen: false);
      _viewModel.addListener(_onViewModelChange);
    });
  }

  @override
  void dispose() {
    // Remove listener if viewmodel was attached
    try {
      _viewModel.removeListener(_onViewModelChange);
    } catch (_) {}
    _voiceController.dispose();
    super.dispose();
  }

  void _onViewModelChange() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<HomeViewModel>(context);

    if (viewModel.isLoading && viewModel.tasks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(viewModel.error!),
            ElevatedButton(
              onPressed: () => viewModel.loadTasks(),
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    return _HomeContent(
      viewModel: viewModel,
      voiceController: _voiceController,
      isListening: _isListening,
      onToggleListening: _toggleListening,
      onSendCommand: _sendCommand,
    );
  }

  void _toggleListening() {
    setState(() {
      _isListening = !_isListening;
      if (_isListening) {
        _voiceController.text = 'Dinleniyor...';
      }
    });
  }

  void _sendCommand() {
    if (_voiceController.text.isEmpty) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Komut işlendi: "${_voiceController.text}"'),
        backgroundColor: AppTheme.successColor,
      ),
    );
    _voiceController.clear();
    setState(() => _isListening = false);
  }
}

class _HomeContent extends StatelessWidget {
  final HomeViewModel viewModel;
  final TextEditingController voiceController;
  final bool isListening;
  final VoidCallback onToggleListening;
  final VoidCallback onSendCommand;

  const _HomeContent({
    required this.viewModel,
    required this.voiceController,
    required this.isListening,
    required this.onToggleListening,
    required this.onSendCommand,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeSection(isDarkMode),
            const SizedBox(height: 20),
            _buildQuickActions(context, theme, isDarkMode),
            const SizedBox(height: 24),
            _buildUpcomingTasks(context, theme, isDarkMode),
            const SizedBox(height: 24),
            _buildAIRecommendations(theme, isDarkMode),
            const SizedBox(height: 24),
            _buildVoiceCommandSection(context, theme, isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 50,
              width: 50,
              color: isDarkMode ? AppTheme.darkSecondary : Colors.white,
              child: Image.asset("lib/assets/images/img.png")
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hoş Geldiniz!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${viewModel.pendingTasksCount} bekleyen göreviniz var',
                  style: const TextStyle(
                    color: Color.fromRGBO(255, 255, 255, 0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, ThemeData theme, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hızlı Erişim',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildQuickActionButton(
              context: context,
              icon: Icons.calendar_today,
              label: 'Takvim',
              onTap: () {
                // Navigate to calendar
              },
              theme: theme,
              isDarkMode: isDarkMode,
            ),
            _buildQuickActionButton(
              context: context,
              icon: Icons.settings,
              label: 'Ayarlar',
              onTap: () {
                // Navigate to settings
              },
              theme: theme,
              isDarkMode: isDarkMode,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ThemeData theme,
    required bool isDarkMode,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isDarkMode ? AppTheme.darkBackground : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkMode ? Colors.grey[800]! : Colors.blue.shade100,
              ),
            ),
            child: Icon(icon, size: 30, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingTasks(BuildContext context, ThemeData theme, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.notifications_active,
              color: theme.primaryColor,
            ),
            const SizedBox(width: 8),
            Text(
              'Yaklaşan Görevler',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...viewModel.upcomingTasks.map((task) =>
            TaskItem(
              task: task,
              onToggle: () => _confirmToggle(context, task),
            ),
        ),
      ],
    );
  }

  Widget _buildAIRecommendations(ThemeData theme, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.auto_awesome,
              color: AppTheme.successColor,
            ),
            const SizedBox(width: 8),
            Text(
              'ASSIST AI Önerileri',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...viewModel.recommendations.map((recommendation) =>
            RecommendationItem(
              recommendation: recommendation,
              onApply: () => viewModel.applyRecommendation(recommendation.id),
            ),
        ),
      ],
    );
  }

  Widget _buildVoiceCommandSection(BuildContext context, ThemeData theme, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkBackground : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey[800]! : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "ASSIST AI'a Komut Ver",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sesli veya yazılı olarak görev ekleyin',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: voiceController,
                  decoration: InputDecoration(
                    hintText: 'Görev ekle veya soru sor...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        isListening ? Icons.mic_off : Icons.mic,
                        color: isListening ? Colors.red : Colors.blue,
                      ),
                      onPressed: onToggleListening,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                onPressed: onSendCommand,
                child: const Text('Gönder', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Örnek: "Yarın saat 15:00\'te toplantı ekle"',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmToggle(BuildContext context, dynamic task) async {
    final shouldToggle = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Görevi Tamamla?'),
        content: Text('"${task.title}" görevini tamamlandı olarak işaretlemek istiyor musunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Onayla'),
          ),
        ],
      ),
    );

    if (shouldToggle == true) {
      await viewModel.toggleTaskCompletion(task.id);
    }
  }
}