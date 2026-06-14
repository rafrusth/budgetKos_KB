import 'package:injectable/injectable.dart';
import 'package:budget_kos/core/database/sqlite_helper.dart';
import 'package:budget_kos/shared/models/transaction_model.dart';
import 'package:budget_kos/features/categories/data/datasources/category_local_ds.dart';
import 'package:uuid/uuid.dart';

abstract class TransactionLocalDataSource {
  Future<List<TransactionModel>> getTransactions();
  Future<String> insertTransaction(TransactionModel transaction);
  Future<void> updateTransaction(TransactionModel transaction);
  Future<void> deleteTransaction(String id);
}

@LazySingleton(as: TransactionLocalDataSource)
class TransactionLocalDataSourceImpl implements TransactionLocalDataSource {
  final SqliteHelper sqliteHelper;
  final CategoryLocalDataSource categoryLocalDs;
  final Uuid _uuid = const Uuid();

  TransactionLocalDataSourceImpl(this.sqliteHelper, this.categoryLocalDs);

  @override
  Future<List<TransactionModel>> getTransactions() async {
    final db = await sqliteHelper.database;
    final result = await db.query('transactions', where: 'is_deleted = 0', orderBy: 'date DESC');
    
    List<TransactionModel> transactions = [];
    for (var map in result) {
      final category = await categoryLocalDs.getCategoryById(map['category_id'] as String);
      transactions.add(TransactionModel.fromMap(map, category: category));
    }
    return transactions;
  }

  @override
  Future<String> insertTransaction(TransactionModel transaction) async {
    final db = await sqliteHelper.database;
    final id = transaction.id ?? _uuid.v4();
    final now = DateTime.now().toIso8601String();

    final data = transaction.toMap();
    data['id'] = id;
    data['created_at'] = now;
    data['updated_at'] = now;
    data['sync_status'] = 1; // pending_insert
    data['is_deleted'] = 0;

    await db.insert('transactions', data);
    return id;
  }

  @override
  Future<void> updateTransaction(TransactionModel transaction) async {
    final db = await sqliteHelper.database;
    final data = transaction.toMap();
    final now = DateTime.now().toIso8601String();
    
    data['updated_at'] = now;
    data['sync_status'] = 2; // pending_update

    await db.update(
      'transactions',
      data,
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  @override
  Future<void> deleteTransaction(String id) async {
    final db = await sqliteHelper.database;
    final now = DateTime.now().toIso8601String();
    
    await db.update(
      'transactions',
      {
        'is_deleted': 1,
        'sync_status': 3, // pending_delete
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
