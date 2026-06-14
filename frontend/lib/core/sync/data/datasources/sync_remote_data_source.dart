import 'dart:convert';
import 'package:injectable/injectable.dart';
import '../../../network/api_client.dart';

abstract class ISyncRemoteDataSource {
  Future<void> pushData(Map<String, dynamic> payload);
  Future<Map<String, dynamic>> pullData(String sinceTimestamp);
}

@LazySingleton(as: ISyncRemoteDataSource)
class SyncRemoteDataSourceImpl implements ISyncRemoteDataSource {
  @override
  Future<void> pushData(Map<String, dynamic> payload) async {
    final response = await ApiClient.post('/sync/push', body: payload);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Push failed with status ${response.statusCode}, body: ${response.body}');
    }
  }

  @override
  Future<Map<String, dynamic>> pullData(String sinceTimestamp) async {
    final url = sinceTimestamp.isEmpty ? '/sync/pull' : '/sync/pull?since=$sinceTimestamp';
    final response = await ApiClient.get(url);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body);
      return json['data'] ?? {};
    } else {
      throw Exception('Pull failed with status ${response.statusCode}');
    }
  }
}
