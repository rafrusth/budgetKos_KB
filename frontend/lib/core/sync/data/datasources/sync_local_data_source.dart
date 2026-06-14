import 'package:injectable/injectable.dart';
import 'package:sqflite/sqflite.dart';
import '../../../database/sqlite_helper.dart';
import 'package:budget_kos/shared/models/transaction_model.dart';
import 'package:budget_kos/shared/models/category_model.dart';

abstract class ISyncLocalDataSource {
  Future<Map<String, dynamic>> getPendingData();
  Future<void> updateSyncStatusAfterPush(List<Map<String, dynamic>> pushedTxs, List<String> deletedTxIds, List<Map<String, dynamic>> pushedCats, List<String> deletedCatIds);
  Future<String> getLastPullTimestamp();
  Future<void> updateLastPullTimestamp(String timestamp);
  Future<void> upsertPulledData(List<dynamic> serverTxs, List<dynamic> serverCats);
}

@LazySingleton(as: ISyncLocalDataSource)
class SyncLocalDataSourceImpl implements ISyncLocalDataSource {
  final SqliteHelper _sqliteHelper;

  SyncLocalDataSourceImpl(this._sqliteHelper);

  @override
  Future<Map<String, dynamic>> getPendingData() async {
    final db = await _sqliteHelper.database;
    
    final pendingTxs = await db.query('transactions', where: 'sync_status != 0');
    final List<Map<String, dynamic>> pushTxs = [];
    final List<String> deletedTxIds = [];
    
    for (var map in pendingTxs) {
      if (map['is_deleted'] == 1) {
        deletedTxIds.add(map['id'] as String);
      } else {
        pushTxs.add(map);
      }
    }

    final pendingCats = await db.query('categories', where: 'sync_status != 0');
    final List<Map<String, dynamic>> pushCats = [];
    final List<String> deletedCatIds = [];
    
    for (var map in pendingCats) {
      if (map['is_deleted'] == 1) {
        deletedCatIds.add(map['id'] as String);
      } else {
        pushCats.add(map);
      }
    }

    return {
      'transactions': pushTxs.map((e) => TransactionModel.fromMap(e).toJson()).toList(),
      'categories': pushCats.map((e) => CategoryModel.fromMap(e).toJson()).toList(),
      'deleted_transaction_ids': deletedTxIds,
      'deleted_category_ids': deletedCatIds,
      'pushTxsRaw': pushTxs,
      'pushCatsRaw': pushCats,
    };
  }

  @override
  Future<void> updateSyncStatusAfterPush(List<Map<String, dynamic>> pushedTxs, List<String> deletedTxIds, List<Map<String, dynamic>> pushedCats, List<String> deletedCatIds) async {
    final db = await _sqliteHelper.database;
    await db.transaction((txn) async {
      for (var tx in pushedTxs) {
        await txn.update('transactions', {'sync_status': 0}, where: 'id = ?', whereArgs: [tx['id']]);
      }
      for (var id in deletedTxIds) {
        await txn.delete('transactions', where: 'id = ?', whereArgs: [id]);
      }
      for (var cat in pushedCats) {
        await txn.update('categories', {'sync_status': 0}, where: 'id = ?', whereArgs: [cat['id']]);
      }
      for (var id in deletedCatIds) {
        await txn.delete('categories', where: 'id = ?', whereArgs: [id]);
      }
    });
  }

  @override
  Future<String> getLastPullTimestamp() async {
    final db = await _sqliteHelper.database;
    final meta = await db.query('sync_metadata', where: 'id = 1');
    if (meta.isNotEmpty) {
      return meta.first['last_pull_timestamp'] as String;
    }
    return '';
  }

  @override
  Future<void> updateLastPullTimestamp(String timestamp) async {
    final db = await _sqliteHelper.database;
    final meta = await db.query('sync_metadata', where: 'id = 1');
    if (meta.isEmpty) {
      await db.insert('sync_metadata', {'id': 1, 'last_pull_timestamp': timestamp});
    } else {
      await db.update('sync_metadata', {'last_pull_timestamp': timestamp}, where: 'id = 1');
    }
  }

  @override
  Future<void> upsertPulledData(List<dynamic> serverTxs, List<dynamic> serverCats) async {
    final db = await _sqliteHelper.database;
    await db.transaction((txn) async {
      for (var c in serverCats) {
        var cm = CategoryModel.fromMap(c);
        if (cm.isDeleted == 1) {
           await txn.delete('categories', where: 'id = ?', whereArgs: [cm.id]);
        } else {
           final map = cm.toMap();
           map['sync_status'] = 0;
           await txn.insert('categories', map, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
      for (var t in serverTxs) {
        var tm = TransactionModel.fromMap(t);
        if (tm.isDeleted == 1) {
           await txn.delete('transactions', where: 'id = ?', whereArgs: [tm.id]);
        } else {
           final map = tm.toMap();
           map['sync_status'] = 0;
           await txn.insert('transactions', map, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    });
  }
}
