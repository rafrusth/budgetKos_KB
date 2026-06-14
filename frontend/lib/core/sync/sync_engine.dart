import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../database/sqlite_helper.dart';
import 'package:budget_kos/shared/models/transaction_model.dart';
import 'package:budget_kos/shared/models/category_model.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

@lazySingleton
class SyncEngine {
  final SqliteHelper _sqliteHelper;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  String get _baseUrl => dotenv.env['BACKEND_URL'] ?? 'http://127.0.0.1:8080/api';

  SyncEngine(this._sqliteHelper);

  Future<void> syncData() async {
    try {
      debugPrint('SyncEngine: Starting sync...');
      await pushData();
      await pullData();
      debugPrint('SyncEngine: Sync completed successfully.');
    } catch (e) {
      debugPrint('SyncEngine: Sync failed: $e');
      rethrow;
    }
  }

  Future<void> pushData() async {
    final db = await _sqliteHelper.database;
    
    // Get pending transactions
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

    // Get pending categories
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

    if (pushTxs.isEmpty && deletedTxIds.isEmpty && pushCats.isEmpty && deletedCatIds.isEmpty) {
      debugPrint('SyncEngine: Nothing to push.');
      return;
    }

    // Build payload
    final payload = {
      'transactions': pushTxs.map((e) => TransactionModel.fromMap(e).toJson()).toList(),
      'categories': pushCats.map((e) => CategoryModel.fromMap(e).toJson()).toList(),
      'deleted_transaction_ids': deletedTxIds,
      'deleted_category_ids': deletedCatIds,
    };

    final token = await _storage.read(key: 'jwt_token');
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final response = await http.post(
      Uri.parse('$_baseUrl/sync/push'),
      headers: headers,
      body: jsonEncode(payload),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      debugPrint('SyncEngine: Push successful. Updating local status.');
      // Mark as synced
      await db.transaction((txn) async {
        for (var tx in pushTxs) {
          await txn.update('transactions', {'sync_status': 0}, where: 'id = ?', whereArgs: [tx['id']]);
        }
        for (var id in deletedTxIds) {
          await txn.delete('transactions', where: 'id = ?', whereArgs: [id]); // physically delete after sync
        }
        for (var cat in pushCats) {
          await txn.update('categories', {'sync_status': 0}, where: 'id = ?', whereArgs: [cat['id']]);
        }
        for (var id in deletedCatIds) {
          await txn.delete('categories', where: 'id = ?', whereArgs: [id]); // physically delete after sync
        }
      });
    } else {
      throw Exception('Push failed with status ${response.statusCode}');
    }
  }

  Future<void> pullData() async {
    final db = await _sqliteHelper.database;
    final meta = await db.query('sync_metadata', where: 'id = 1');
    String since = '';
    if (meta.isNotEmpty) {
      since = meta.first['last_pull_timestamp'] as String;
    }

    final pullStartTime = DateTime.now().toIso8601String();
    final url = since.isEmpty ? '$_baseUrl/sync/pull' : '$_baseUrl/sync/pull?since=$since';
    
    final token = await _storage.read(key: 'jwt_token');
    final headers = {
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body);
      final data = json['data'];
      if (data == null) return;

      final serverTxs = data['transactions'] as List<dynamic>? ?? [];
      final serverCats = data['categories'] as List<dynamic>? ?? [];

      await db.transaction((txn) async {
        // Upsert categories
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
        // Upsert transactions
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

      // Update sync_metadata
      if (meta.isEmpty) {
        await db.insert('sync_metadata', {'id': 1, 'last_pull_timestamp': pullStartTime});
      } else {
        await db.update('sync_metadata', {'last_pull_timestamp': pullStartTime}, where: 'id = 1');
      }
      debugPrint('SyncEngine: Pull successful.');
    } else {
      throw Exception('Pull failed with status ${response.statusCode}');
    }
  }
}
