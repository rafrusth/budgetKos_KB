import 'package:injectable/injectable.dart';
import 'package:budget_kos/core/database/sqlite_helper.dart';
import 'package:budget_kos/shared/models/transaction_model.dart';
import 'package:budget_kos/features/categories/data/datasources/category_local_ds.dart';

abstract class TransactionLocalDataSource {
  Future<List<TransactionModel>> getTransactions();
  Future<int> insertTransaction(TransactionModel transaction);
  Future<void> updateTransaction(TransactionModel transaction);
  Future<void> deleteTransaction(int id);
}

@LazySingleton(as: TransactionLocalDataSource)
class TransactionLocalDataSourceImpl implements TransactionLocalDataSource {
  final SqliteHelper sqliteHelper;
  final CategoryLocalDataSource categoryLocalDs;

  TransactionLocalDataSourceImpl(this.sqliteHelper, this.categoryLocalDs);

  @override
  Future<List<TransactionModel>> getTransactions() async {
    final db = await sqliteHelper.database;
    final result = await db.query('transactions', orderBy: 'date DESC');
    
    List<TransactionModel> transactions = [];
    for (var map in result) {
      final category = await categoryLocalDs.getCategoryById(map['category_id'] as int);
      transactions.add(TransactionModel.fromMap(map, category: category));
    }
    return transactions;
  }

  @override
  Future<int> insertTransaction(TransactionModel transaction) async {
    final db = await sqliteHelper.database;
    return await db.insert('transactions', transaction.toMap());
  }

  @override
  Future<void> updateTransaction(TransactionModel transaction) async {
    final db = await sqliteHelper.database;
    await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  @override
  Future<void> deleteTransaction(int id) async {
    final db = await sqliteHelper.database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }
}
