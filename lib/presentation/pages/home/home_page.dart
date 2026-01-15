import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Assist/data/models/task.dart';
import 'package:Assist/presentation/viewmodels/home_viewmodel.dart';
import 'package:Assist/presentation/widgets/task_item.dart';
import 'package:Assist/presentation/widgets/recommendation_item.dart';
import 'package:Assist/presentation/pages/calendar/calendar_page.dart';
import 'package:Assist/presentation/pages/settings/settings_page.dart';
import 'package:Assist/core/app_theme.dart';
import 'package:Assist/injection_container.dart';
import 'package:Assist/services/localization_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  late HomeViewModel _viewModel;
  final TextEditingController _voiceController = TextEditingController();
  bool _isListening = false;
  Timer? _suggestionDebounce;
  String? _assistantSuggestion;
  bool _isSuggesting = false;

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
    _suggestionDebounce?.cancel();
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
      onVoiceChanged: (value) => _handleVoiceChanged(value, viewModel),
      onApplySuggestion: _applyAssistantSuggestion,
      assistantSuggestion: _assistantSuggestion,
      isSuggesting: _isSuggesting,
    );
  }

  Future<void> _toggleListening() async {
    final localization = Provider.of<LocalizationService>(context, listen: false);
    final voiceService = ServiceLocator().voiceService;

    if (_isListening) {
      await voiceService.stopListening();
      setState(() {
        _isListening = false;
        if (_voiceController.text == localization.listening) {
          _voiceController.clear();
        }
      });
    } else {
      setState(() {
        _isListening = true;
        _voiceController.text = localization.listening;
      });

      await voiceService.startListening(
        onResult: (text) {
          if (!mounted) return;
          setState(() {
            _voiceController.text = text;
             _voiceController.selection = TextSelection.collapsed(offset: text.length);
          });
        },
        onStatus: (status) {
          if (!mounted) return;
          if (status == 'notAvailable') {
             ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Sesli komut bu cihazda desteklenmiyor.')),
            );
            setState(() {
              _isListening = false;
               if (_voiceController.text == localization.listening) {
                _voiceController.clear();
              }
            });
          } else if (status == 'notListening' || status == 'done') {
            setState(() { 
              _isListening = false;
              if (_voiceController.text == localization.listening) {
                _voiceController.clear();
              }
            });
          }
        },
      );
    }
  }

  Future<void> _sendCommand() async {
    final input = _voiceController.text.trim();
    if (input.isEmpty) return;

    final viewModel = Provider.of<HomeViewModel>(context, listen: false);
    final task = Task(
      title: input,
      description: 'ASSIST AI komutuyla eklendi.',
      date: DateTime.now(),
    );

    await viewModel.addTask(task);
    if (!mounted) return;

    if (viewModel.error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Görev eklendi: "$input"'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      _voiceController.clear();
      setState(() => _assistantSuggestion = null);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viewModel.error!),
          backgroundColor: Colors.red,
        ),
      );
    }
    setState(() => _isListening = false);
  }

  void _applyAssistantSuggestion() {
    final suggestion = _assistantSuggestion?.trim();
    if (suggestion == null || suggestion.isEmpty) return;

    final current = _voiceController.text;
    final trimmedCurrent = current.trimRight();
    final trimmedSuggestion = suggestion.trimLeft();
    final updated = trimmedCurrent.isEmpty
        ? trimmedSuggestion
        : '$trimmedCurrent $trimmedSuggestion';

    _suggestionDebounce?.cancel();
    _voiceController.text = updated;
    _voiceController.selection = TextSelection.collapsed(offset: updated.length);
    setState(() {
      _assistantSuggestion = null;
      _isSuggesting = false;
    });
  }

  void _handleVoiceChanged(String value, HomeViewModel viewModel) {
    _suggestionDebounce?.cancel();
    if (_assistantSuggestion != null) {
      setState(() => _assistantSuggestion = null);
    }
    final trimmed = value.trim();
    if (trimmed.length < 3) {
      if (_isSuggesting) {
        setState(() {
          _isSuggesting = false;
        });
      }
      return;
    }

    _suggestionDebounce = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted) return;
      setState(() => _isSuggesting = true);
      try {
        final suggestion = await ServiceLocator()
            .aiService
            .generateAssistantCompletion(
              input: trimmed,
              context: viewModel.tasks,
            );
        if (!mounted) return;
        if (_voiceController.text.trim() != trimmed) return;
        setState(() => _assistantSuggestion = suggestion);
      } catch (_) {
        if (!mounted) return;
        if (_voiceController.text.trim() != trimmed) return;
        setState(() => _assistantSuggestion = null);
      } finally {
        if (!mounted) return;
        if (_voiceController.text.trim() != trimmed) return;
        setState(() => _isSuggesting = false);
      }
    });
  }
}

class _HomeContent extends StatelessWidget {
  final HomeViewModel viewModel;
  final TextEditingController voiceController;
  final bool isListening;
  final VoidCallback onToggleListening;
  final VoidCallback onSendCommand;
  final ValueChanged<String> onVoiceChanged;
  final VoidCallback onApplySuggestion;
  final String? assistantSuggestion;
  final bool isSuggesting;

  const _HomeContent({
    required this.viewModel,
    required this.voiceController,
    required this.isListening,
    required this.onToggleListening,
    required this.onSendCommand,
    required this.onVoiceChanged,
    required this.onApplySuggestion,
    required this.assistantSuggestion,
    required this.isSuggesting,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localization = Provider.of<LocalizationService>(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeSection(localization, isDarkMode),
            const SizedBox(height: 20),
            _buildQuickActions(context, localization, theme, isDarkMode),
            const SizedBox(height: 24),
            _buildUpcomingTasks(context, localization, theme, isDarkMode),
            const SizedBox(height: 24),
            _buildAIRecommendations(localization, theme, isDarkMode),
            const SizedBox(height: 24),
            _buildVoiceCommandSection(context, localization, theme, isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(LocalizationService localization, bool isDarkMode) {
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
                Text(
                  localization.welcome,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${viewModel.pendingTasksCount} ${localization.pendingTasks}',
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

  Widget _buildQuickActions(BuildContext context, LocalizationService localization, ThemeData theme, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localization.quickAccess,
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
              label: localization.calendar,
              onTap: () {
                _openQuickActionPage(
                  context,
                  localization.calendar,
                  const CalendarPage(),
                );
              },
              theme: theme,
              isDarkMode: isDarkMode,
            ),
            _buildQuickActionButton(
              context: context,
              icon: Icons.settings,
              label: localization.settings,
              onTap: () {
                _openQuickActionPage(
                  context,
                  localization.settings,
                  const SettingsPage(),
                );
              },
              theme: theme,
              isDarkMode: isDarkMode,
            ),
          ],
        ),
      ],
    );
  }

  void _openQuickActionPage(
    BuildContext context,
    String title,
    Widget page,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(title)),
          body: page,
        ),
      ),
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

  Widget _buildUpcomingTasks(BuildContext context, LocalizationService localization, ThemeData theme, bool isDarkMode) {
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
              localization.upcomingTasks,
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
              onToggle: () => _confirmToggle(context, localization, task),
            ),
        ),
      ],
    );
  }

  Widget _buildAIRecommendations(LocalizationService localization, ThemeData theme, bool isDarkMode) {
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
              localization.aiRecommendations,
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

  Widget _buildVoiceCommandSection(BuildContext context, LocalizationService localization, ThemeData theme, bool isDarkMode) {
    const inputPadding = EdgeInsets.symmetric(horizontal: 12, vertical: 14);
    final hasInput = voiceController.text.trim().isNotEmpty;
    final suggestion = assistantSuggestion?.trim();
    final showSuggestion = hasInput && suggestion != null && suggestion.isNotEmpty;
    final completionText =
        showSuggestion ? ' ${suggestion.trimLeft()}' : '';
    final baseStyle = theme.textTheme.bodyMedium ?? const TextStyle(fontSize: 14);

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
            localization.giveCommand,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            localization.voiceCommandHint,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Padding(
                          padding: inputPadding,
                          child: RichText(
                            text: TextSpan(
                              style: baseStyle.copyWith(color: Colors.transparent),
                              children: [
                                TextSpan(text: voiceController.text),
                                TextSpan(
                                  text: completionText,
                                  style: baseStyle.copyWith(color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    TextField(
                      controller: voiceController,
                      onChanged: onVoiceChanged,
                      style: baseStyle,
                      decoration: InputDecoration(
                        hintText: 'Görev ekle veya soru sor...',
                        contentPadding: inputPadding,
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
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                onPressed: onSendCommand,
                child: Text(localization.send, style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: showSuggestion ? onApplySuggestion : null,
              icon: const Icon(Icons.check),
              label: Text(localization.finalize),
            ),
          ),
          if (isSuggesting)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            localization.exampleCommand,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmToggle(BuildContext context, LocalizationService localization, dynamic task) async {
    final shouldToggle = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(localization.completeTask),
        content: Text('"${task.title}" ${localization.completeTaskConfirmation}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(localization.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(localization.confirm),
          ),
        ],
      ),
    );

    if (shouldToggle == true) {
      await viewModel.toggleTaskCompletion(task.id);
    }
  }
}
