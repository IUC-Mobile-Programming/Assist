import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';

class DatabaseService extends ChangeNotifier {
  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initializeDB();
    return _database!;
  }

  Future<Database> _initializeDB() async {
    final databasesPath = await getDatabasesPath();
    final path_ = path.join(databasesPath, 'assist_app.db');

    return openDatabase(
      path_,
      version: 2,
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE tasks ADD COLUMN category TEXT');
        }
      },
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        dueDate TEXT,
        description TEXT,
        category TEXT,
        completed INTEGER DEFAULT 0,
        important INTEGER DEFAULT 0,
        createdAt TEXT,
        updatedAt TEXT
      )
    ''');
  }

  // CRUD Operations
  Future<int> insertTask(Map<String, dynamic> task) async {
    final db = await database;
    final id = await db.insert('tasks', task);
    notifyListeners(); // Notify UI of changes
    return id;
  }

  Future<List<Map<String, dynamic>>> getTasks() async {
    final db = await database;
    return db.query('tasks');
  }

  Future<void> updateTask(int id, Map<String, dynamic> task) async {
    final db = await database;
    await db.update('tasks', task, where: 'id = ?', whereArgs: [id]);
    notifyListeners();
  }

  Future<void> deleteTask(int id) async {
    final db = await database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
    notifyListeners();
  }

  @override
  void dispose() {
    _database?.close();
    super.dispose();
  }
}