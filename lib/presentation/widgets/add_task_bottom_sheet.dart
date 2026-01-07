import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Assist/services/database_service.dart';
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
  String _selectedCategory = 'Diğer';
  bool _isImportant = false;
  String? _descriptionSuggestion;
  bool _isSuggestionLoading = false;

  void _showFloatingSnack(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
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

  @override
  Widget build(BuildContext context) {
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
                const Text(
                  'Yeni Görev Ekle',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // Başlık
                const Text('Başlık', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'Görev başlığını girin',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Açıklama
                const Text('Açıklama', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: _descriptionSuggestion ?? 'Görev açıklamasını girin',
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
                      label: const Text('Öneri al'),
                    ),
                    TextButton(
                      onPressed: _descriptionSuggestion != null &&
                              _descriptionController.text.trim().isEmpty
                          ? _applyDescriptionSuggestion
                          : null,
                      child: const Text('Öneriyi uygula'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Tarih ve Saat
                const Text('Tarih ve Saat', style: TextStyle(fontWeight: FontWeight.bold)),
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
                                : 'Tarih seçin',
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
                                : 'Saat seçin',
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
                const Text('Kategori', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  items: ['İş', 'Kişisel', 'Alışveriş', 'Sağlık', 'Diğer']
                      .map((category) => DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedCategory = value ?? 'Diğer');
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
                    const Text(
                      'Önemli olarak işaretle',
                      style: TextStyle(fontSize: 16),
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
                        _showFloatingSnack(context, 'Lütfen bir başlık girin');
                        return;
                      }

                      if (_selectedDate == null) {
                        _showFloatingSnack(context, 'Lütfen bir bitiş tarihi seçin');
                        return;
                      }

                      if (_selectedTime == null) {
                        _showFloatingSnack(context, 'Lütfen bir bitiş saati seçin');
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
                        const SnackBar(
                          content: Text('Görev başarıyla eklendi!'),
                          behavior: SnackBarBehavior.floating,
                          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                      );
                    },
                    child: const Text(
                      'Add Task',
                      style: TextStyle(
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
