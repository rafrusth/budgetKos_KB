import 'package:injectable/injectable.dart';
import 'package:budget_kos/core/database/sqlite_helper.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AiChatModel {
  final int? id;
  final String prompt;
  final String response;
  final DateTime timestamp;

  AiChatModel({this.id, required this.prompt, required this.response, required this.timestamp});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'prompt': prompt,
      'response': response,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory AiChatModel.fromMap(Map<String, dynamic> map) {
    return AiChatModel(
      id: map['id'],
      prompt: map['prompt'],
      response: map['response'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}

@lazySingleton
class AiChatLocalDataSource {
  final SqliteHelper sqliteHelper;
  final List<AiChatModel> _memoryHistory = [];

  AiChatLocalDataSource(this.sqliteHelper);

  Future<List<AiChatModel>> getChatHistory() async {
    if (kIsWeb) return _memoryHistory.toList();
    try {
      final db = await sqliteHelper.database;
      final result = await db.query('ai_chats', orderBy: 'timestamp ASC');
      return result.map((m) => AiChatModel.fromMap(m)).toList();
    } catch (e) {
      return _memoryHistory.toList();
    }
  }

  Future<int> insertChat(AiChatModel chat) async {
    if (kIsWeb) {
      _memoryHistory.add(chat);
      return _memoryHistory.length;
    }
    try {
      final db = await sqliteHelper.database;
      return await db.insert('ai_chats', chat.toMap());
    } catch (e) {
      _memoryHistory.add(chat);
      return _memoryHistory.length;
    }
  }

  Future<void> clearHistory() async {
    if (kIsWeb) {
      _memoryHistory.clear();
      return;
    }
    try {
      final db = await sqliteHelper.database;
      await db.delete('ai_chats');
    } catch (e) {
      _memoryHistory.clear();
    }
  }
}
