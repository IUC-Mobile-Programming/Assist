class Task {
  final String id;
  final String title;
  final DateTime date;
  final String description;
  bool isCompleted;
  final bool isImportant;
  final DateTime? reminder;
  final String? category;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Task({
    String? id,
    required this.title,
    required this.date,
    required this.description,
    this.isCompleted = false,
    this.isImportant = false,
    this.reminder,
    this.category,
    DateTime? createdAt,
    this.updatedAt,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt = createdAt ?? DateTime.now();

  Task copyWith({
    String? id,
    String? title,
    DateTime? date,
    String? description,
    bool? isCompleted,
    bool? isImportant,
    DateTime? reminder,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      isImportant: isImportant ?? this.isImportant,
      reminder: reminder ?? this.reminder,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'date': date.toIso8601String(),
      'description': description,
      'isCompleted': isCompleted,
      'isImportant': isImportant,
      'reminder': reminder?.toIso8601String(),
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      date: DateTime.parse(map['date']),
      description: map['description'],
      isCompleted: map['isCompleted'],
      isImportant: map['isImportant'],
      reminder: map['reminder'] != null ? DateTime.parse(map['reminder']) : null,
      category: map['category'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }

  @override
  String toString() {
    return 'Task(id: $id, title: $title, date: $date, completed: $isCompleted)';
  }
}