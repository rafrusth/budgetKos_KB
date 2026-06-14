import 'package:uuid/uuid.dart';
import '../../../../core/database/sqlite_helper.dart';
import '../../../../core/di/injection.dart';
import 'package:budget_kos/shared/models/transaction_model.dart';
import 'package:budget_kos/shared/models/category_model.dart';

class TransactionRepository {
  final SqliteHelper _sqliteHelper = getIt<SqliteHelper>();
  final Uuid _uuid = const Uuid();

  Future<List<TransactionModel>> getTransactions() async {
    final db = await _sqliteHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('transactions', 
      where: 'is_deleted = 0',
      orderBy: 'date DESC, created_at DESC');
    
    List<TransactionModel> transactions = [];
    for (var map in maps) {
      final jsonMap = Map<String, dynamic>.from(map);
      
      // Fetch category
      final categoryId = jsonMap['category_id'] as String?;
      if (categoryId != null && categoryId.isNotEmpty) {
        final catMaps = await db.query('categories', where: 'id = ? AND is_deleted = 0', whereArgs: [categoryId]);
        if (catMaps.isNotEmpty) {
          final catJsonMap = Map<String, dynamic>.from(catMaps.first);
          catJsonMap['is_default'] = catJsonMap['is_default'] == 1;
          jsonMap['category'] = catJsonMap;
        }
      }
      transactions.add(TransactionModel.fromMap(jsonMap));
    }
    return transactions;
  }

  Future<List<CategoryModel>> getCategories() async {
    final db = await _sqliteHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('categories', where: 'is_deleted = 0');
    return maps.map((map) {
      final jsonMap = Map<String, dynamic>.from(map);
      jsonMap['is_default'] = map['is_default'] == 1;
      return CategoryModel.fromMap(jsonMap);
    }).toList();
  }

  Future<CategoryModel> addCategory(String name, String type) async {
    final db = await _sqliteHelper.database;
    final id = _uuid.v4();
    final now = DateTime.now().toIso8601String();
    
    await db.insert('categories', {
      'id': id,
      'name': name,
      'icon': 'custom',
      'color': '#2196F3',
      'type': type,
      'is_default': 0,
      'sort_order': 0,
      'created_at': now,
      'updated_at': now,
      'sync_status': 1, // pending_insert
      'is_deleted': 0,
    });
    
    final maps = await db.query('categories', where: 'id = ?', whereArgs: [id]);
    final jsonMap = Map<String, dynamic>.from(maps.first);
    jsonMap['is_default'] = jsonMap['is_default'] == 1;
    return CategoryModel.fromMap(jsonMap);
  }

  Future<TransactionModel> addTransaction(TransactionModel transaction) async {
    final db = await _sqliteHelper.database;
    final Map<String, dynamic> data = transaction.toMap();
    final newId = _uuid.v4();
    data['id'] = newId;
    data.remove('category'); // We don't insert the joined category object
    
    final now = DateTime.now().toIso8601String();
    data['created_at'] = now;
    data['updated_at'] = now;
    data['sync_status'] = 1; // pending_insert
    data['is_deleted'] = 0;

    await db.insert('transactions', data);
    
    // Fetch and return the full created transaction
    final txMaps = await db.query('transactions', where: 'id = ?', whereArgs: [newId]);
    final jsonMap = Map<String, dynamic>.from(txMaps.first);
    
    final catMaps = await db.query('categories', where: 'id = ? AND is_deleted = 0', whereArgs: [jsonMap['category_id']]);
    if (catMaps.isNotEmpty) {
      final catJsonMap = Map<String, dynamic>.from(catMaps.first);
      catJsonMap['is_default'] = catJsonMap['is_default'] == 1;
      jsonMap['category'] = catJsonMap;
    }
    
    return TransactionModel.fromMap(jsonMap);
  }

  Future<TransactionModel> updateTransaction(TransactionModel transaction) async {
    final db = await _sqliteHelper.database;
    final Map<String, dynamic> data = transaction.toMap();
    data.remove('category'); // Don't update the joined category object
    data['updated_at'] = DateTime.now().toIso8601String();
    data['sync_status'] = 2; // pending_update

    await db.update('transactions', data, where: 'id = ?', whereArgs: [transaction.id]);
    
    // Fetch and return updated
    final txMaps = await db.query('transactions', where: 'id = ?', whereArgs: [transaction.id]);
    final jsonMap = Map<String, dynamic>.from(txMaps.first);
    
    final catMaps = await db.query('categories', where: 'id = ? AND is_deleted = 0', whereArgs: [jsonMap['category_id']]);
    if (catMaps.isNotEmpty) {
      final catJsonMap = Map<String, dynamic>.from(catMaps.first);
      catJsonMap['is_default'] = catJsonMap['is_default'] == 1;
      jsonMap['category'] = catJsonMap;
    }
    
    return TransactionModel.fromMap(jsonMap);
  }

  Future<void> deleteTransaction(String id) async {
    final db = await _sqliteHelper.database;
    final now = DateTime.now().toIso8601String();
    
    await db.update('transactions', {
      'is_deleted': 1,
      'sync_status': 3, // pending_delete
      'updated_at': now,
    }, where: 'id = ?', whereArgs: [id]);
  }
}
