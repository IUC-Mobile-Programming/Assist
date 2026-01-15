import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Assist/services/database_service.dart';
import 'package:Assist/services/localization_service.dart';
import 'package:Assist/presentation/viewmodels/home_viewmodel.dart';
import 'package:Assist/injection_container.dart';

class AddTaskBottomSheet extends StatefulWidget {
  const AddTaskBottomSheet({super.key});

  @override
  State<AddTaskBottomSheet> createState() => _AddTaskBottomSheetState();
}

class _AddTaskBottomSheetState extends State<AddTaskBottomSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _selectedCategory = 'other';
  bool _isImportant = false;
  String? _descriptionSuggestion;
  bool _isSuggestionLoading = false;
  bool _isListening = false;

  final _categoryMap = {
    'work': (LocalizationService loc) => loc.categoryWork,
    'personal': (LocalizationService loc) => loc.categoryPersonal,
    'shopping': (LocalizationService loc) => loc.categoryShopping,
    'health': (LocalizationService loc) => loc.categoryHealth,
    'other': (LocalizationService loc) => loc.categoryOther,
  };

  List<String> get _categoryKeys => _categoryMap.keys.toList();

  void _showFloatingSnack(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(Provider.of<LocalizationService>(context, listen: false).ok),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _fetchDescriptionSuggestion() async {
    if (_isSuggestionLoading) return;
    if (_descriptionController.text.trim().isNotEmpty) {
      return;
    }

    setState(() => _isSuggestionLoading = true);
    try {
      final aiService = ServiceLocator().aiService;
      final suggestion = await aiService.generateTaskDescriptionSuggestion(
        title: _titleController.text,
        category: _selectedCategory,
      );
      if (!mounted) return;
      setState(() => _descriptionSuggestion = suggestion);
    } catch (_) {
      if (!mounted) return;
      setState(() => _descriptionSuggestion = null);
    } finally {
      if (!mounted) return;
      setState(() => _isSuggestionLoading = false);
    }
  }

  void _applyDescriptionSuggestion() {
    final suggestion = _descriptionSuggestion?.trim();
    if (suggestion == null || suggestion.isEmpty) return;
    _descriptionController.text = suggestion;
    _descriptionController.selection = TextSelection.collapsed(
      offset: suggestion.length,
    );
    setState(() => _descriptionSuggestion = null);
  }

  Future<void> _toggleListening() async {
    final voiceService = ServiceLocator().voiceService;

    if (_isListening) {
      await voiceService.stopListening();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      await voiceService.startListening(
        onResult: (text) {
          setState(() {
            _titleController.text = text;
            _titleController.selection = TextSelection.collapsed(
              offset: text.length,
            );
          });
        },
        onStatus: (status) {
          if (status == 'notListening' || status == 'done') {
            setState(() => _isListening = false);
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationService>(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  localization.addNewTask,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // Başlık
                Text(localization.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: localization.enterTaskTitle,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: _isListening ? Colors.red : null,
                      ),
                      onPressed: _toggleListening,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Açıklama
                Text(localization.description, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: _descriptionSuggestion ?? localization.enterTaskDescription,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    if (value.trim().isNotEmpty && _descriptionSuggestion != null) {
                      setState(() => _descriptionSuggestion = null);
                    }
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: _descriptionController.text.trim().isEmpty &&
                              !_isSuggestionLoading
                          ? _fetchDescriptionSuggestion
                          : null,
                      icon: _isSuggestionLoading
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome, size: 18),
                      label: Text(localization.getSuggestion),
                    ),
                    TextButton(
                      onPressed: _descriptionSuggestion != null &&
                              _descriptionController.text.trim().isEmpty
                          ? _applyDescriptionSuggestion
                          : null,
                      child: Text(localization.applySuggestion),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Tarih ve Saat
                Text(localization.dateAndTime, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (pickedDate != null) {
                            setState(() => _selectedDate = pickedDate);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _selectedDate != null
                                ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                                : localization.selectDate,
                            style: TextStyle(
                              color: _selectedDate != null ? Colors.black : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final pickedTime = await showTimePicker(
                            context: context,
                            initialTime: _selectedTime ?? TimeOfDay.now(),
                          );
                          if (pickedTime != null) {
                            setState(() => _selectedTime = pickedTime);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _selectedTime != null
                                ? _selectedTime!.format(context)
                                : localization.selectTime,
                            style: TextStyle(
                              color: _selectedTime != null ? Colors.black : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Görev Kategorisi
                Text(localization.category, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  items: _categoryKeys
                      .map((categoryKey) => DropdownMenuItem(
                            value: categoryKey,
                            child:
                                Text(_categoryMap[categoryKey]!(localization)),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedCategory = value ?? 'other');
                  },
                ),
                const SizedBox(height: 16),

                // Önemli İşareti
                Row(
                  children: [
                    Checkbox(
                      value: _isImportant,
                      onChanged: (value) {
                        setState(() => _isImportant = value ?? false);
                      },
                    ),
                    Text(
                      localization.markAsImportant,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Ekleme Butonu
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () async {
                      // Validation
                      if (_titleController.text.isEmpty) {
                        _showFloatingSnack(context, localization.enterTitle);
                        return;
                      }

                      if (_selectedDate == null) {
                        _showFloatingSnack(context, localization.selectDueDate);
                        return;
                      }

                      if (_selectedTime == null) {
                        _showFloatingSnack(context, localization.selectDueTime);
                        return;
                      }

                      final dbService = Provider.of<DatabaseService>(
                        context,
                        listen: false,
                      );

                      // Tarihi ve saati birleştir
                      DateTime? dueDate;
                      if (_selectedDate != null) {
                        final time = _selectedTime ?? const TimeOfDay(hour: 0, minute: 0);
                        dueDate = DateTime(
                          _selectedDate!.year,
                          _selectedDate!.month,
                          _selectedDate!.day,
                          time.hour,
                          time.minute,
                        );
                      }

                      // Veritabanına ekle
                      await dbService.insertTask({
                        'title': _titleController.text,
                        'dueDate': dueDate?.toIso8601String(),
                        'description': _descriptionController.text,
                        'category': _selectedCategory,
                        'important': _isImportant ? 1 : 0,
                        'completed': 0,
                        'createdAt': DateTime.now().toString(),
                        'updatedAt': DateTime.now().toString(),
                      });

                      if (!context.mounted) return;

                      // Refresh tasks in HomeViewModel
                      final homeViewModel = Provider.of<HomeViewModel>(context, listen: false);
                      await homeViewModel.loadTasks();

                      final messenger = ScaffoldMessenger.of(context);
                      Navigator.pop(context);
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(localization.taskAddedSuccessfully),
                          behavior: SnackBarBehavior.floating,
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                      );
                    },
                    child: Text(
                      localization.addTask,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
