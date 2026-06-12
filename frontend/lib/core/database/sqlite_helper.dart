import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class SqliteHelper {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'budgetkos.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE ai_chats (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              prompt TEXT NOT NULL,
              response TEXT NOT NULL,
              timestamp TEXT NOT NULL
            )
          ''');
        }
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        category_id INTEGER,
        notes TEXT,
        date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0
      )
    ''');
    
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        color TEXT NOT NULL,
        type TEXT NOT NULL,
        is_default INTEGER NOT NULL DEFAULT 0,
        sort_order INTEGER NOT NULL DEFAULT 0
      )
    ''');
    
    await db.execute('''
      CREATE TABLE ai_chats (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        prompt TEXT NOT NULL,
        response TEXT NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');
    
    // Seed default categories
    final defaultCategories = [
      {'name': 'Makanan', 'icon': 'restaurant', 'color': '#FF9800', 'type': 'expense'},
      {'name': 'Transportasi', 'icon': 'directions_car', 'color': '#2196F3', 'type': 'expense'},
      {'name': 'Tagihan', 'icon': 'receipt', 'color': '#F44336', 'type': 'expense'},
      {'name': 'Belanja', 'icon': 'shopping_cart', 'color': '#9C27B0', 'type': 'expense'},
      {'name': 'Gaji', 'icon': 'account_balance_wallet', 'color': '#4CAF50', 'type': 'income'},
      {'name': 'Bonus', 'icon': 'card_giftcard', 'color': '#00BCD4', 'type': 'income'},
    ];

    for (var cat in defaultCategories) {
      await db.insert('categories', {
        'name': cat['name'],
        'icon': cat['icon'],
        'color': cat['color'],
        'type': cat['type'],
        'is_default': 1,
        'sort_order': 0,
      });
    }
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('transactions');
    await db.delete('categories');
    await db.delete('ai_chats');
  }
}
