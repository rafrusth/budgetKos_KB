import '../../../../core/database/sqlite_helper.dart';
import '../../../../core/di/injection.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/category_model.dart';

class TransactionRepository {
  final SqliteHelper _sqliteHelper = getIt<SqliteHelper>();

  Future<List<TransactionModel>> getTransactions() async {
    final db = await _sqliteHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('transactions', orderBy: 'date DESC, created_at DESC');
    
    List<TransactionModel> transactions = [];
    for (var map in maps) {
      final jsonMap = Map<String, dynamic>.from(map);
      
      // Fetch category
      final categoryId = jsonMap['category_id'] as int?;
      if (categoryId != null) {
        final catMaps = await db.query('categories', where: 'id = ?', whereArgs: [categoryId]);
        if (catMaps.isNotEmpty) {
          final catJsonMap = Map<String, dynamic>.from(catMaps.first);
          catJsonMap['is_default'] = catJsonMap['is_default'] == 1;
          jsonMap['category'] = catJsonMap;
        }
      }
      transactions.add(TransactionModel.fromJson(jsonMap));
    }
    return transactions;
  }

  Future<List<CategoryModel>> getCategories() async {
    final db = await _sqliteHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('categories');
    return maps.map((map) {
      final jsonMap = Map<String, dynamic>.from(map);
      jsonMap['is_default'] = map['is_default'] == 1;
      return CategoryModel.fromJson(jsonMap);
    }).toList();
  }

  Future<CategoryModel> addCategory(String name, String type) async {
    final db = await _sqliteHelper.database;
    final id = await db.insert('categories', {
      'name': name,
      'icon': 'custom',
      'color': '#2196F3',
      'type': type,
      'is_default': 0,
      'sort_order': 0,
    });
    
    final maps = await db.query('categories', where: 'id = ?', whereArgs: [id]);
    final jsonMap = Map<String, dynamic>.from(maps.first);
    jsonMap['is_default'] = jsonMap['is_default'] == 1;
    return CategoryModel.fromJson(jsonMap);
  }

  Future<TransactionModel> addTransaction(TransactionModel transaction) async {
    final db = await _sqliteHelper.database;
    final Map<String, dynamic> data = transaction.toJson();
    data.remove('id'); // Remove id for AUTOINCREMENT
    data.remove('category'); // We don't insert the joined category object
    data['created_at'] = DateTime.now().toIso8601String();
    data['updated_at'] = DateTime.now().toIso8601String();
    data['is_synced'] = 0;

    final id = await db.insert('transactions', data);
    
    // Fetch and return the full created transaction
    final txMaps = await db.query('transactions', where: 'id = ?', whereArgs: [id]);
    final jsonMap = Map<String, dynamic>.from(txMaps.first);
    
    final catMaps = await db.query('categories', where: 'id = ?', whereArgs: [jsonMap['category_id']]);
    if (catMaps.isNotEmpty) {
      final catJsonMap = Map<String, dynamic>.from(catMaps.first);
      catJsonMap['is_default'] = catJsonMap['is_default'] == 1;
      jsonMap['category'] = catJsonMap;
    }
    
    return TransactionModel.fromJson(jsonMap);
  }

  Future<TransactionModel> updateTransaction(TransactionModel transaction) async {
    final db = await _sqliteHelper.database;
    final Map<String, dynamic> data = transaction.toJson();
    data.remove('category'); // Don't update the joined category object
    data['updated_at'] = DateTime.now().toIso8601String();

    await db.update('transactions', data, where: 'id = ?', whereArgs: [transaction.id]);
    
    // Fetch and return updated
    final txMaps = await db.query('transactions', where: 'id = ?', whereArgs: [transaction.id]);
    final jsonMap = Map<String, dynamic>.from(txMaps.first);
    
    final catMaps = await db.query('categories', where: 'id = ?', whereArgs: [jsonMap['category_id']]);
    if (catMaps.isNotEmpty) {
      final catJsonMap = Map<String, dynamic>.from(catMaps.first);
      catJsonMap['is_default'] = catJsonMap['is_default'] == 1;
      jsonMap['category'] = catJsonMap;
    }
    
    return TransactionModel.fromJson(jsonMap);
  }

  Future<void> deleteTransaction(int id) async {
    final db = await _sqliteHelper.database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }
}
