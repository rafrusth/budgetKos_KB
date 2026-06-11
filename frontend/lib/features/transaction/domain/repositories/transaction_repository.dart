import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/category_model.dart';

class TransactionRepository {
  final Dio _dio = ApiClient.instance;

  Future<List<TransactionModel>> getTransactions() async {
    try {
      final response = await _dio.get('/transactions');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => TransactionModel.fromJson(json)).toList();
      }
      throw Exception('Failed to load transactions');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await _dio.get('/categories');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => CategoryModel.fromJson(json)).toList();
      }
      throw Exception('Failed to load categories');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<CategoryModel> addCategory(String name, String type) async {
    try {
      final response = await _dio.post('/categories', data: {
        'name': name,
        'type': type,
        'icon': 'custom',
        'color': '#2196F3',
      });
      if (response.statusCode == 201) {
        return CategoryModel.fromJson(response.data['data']);
      }
      throw Exception('Failed to add category');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<TransactionModel> addTransaction(TransactionModel transaction) async {
    try {
      final response = await _dio.post(
        '/transactions',
        data: transaction.toJson(),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return TransactionModel.fromJson(response.data['data']);
      }
      throw Exception('Failed to create transaction');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<TransactionModel> updateTransaction(TransactionModel transaction) async {
    try {
      final response = await _dio.put(
        '/transactions/${transaction.id}',
        data: transaction.toJson(),
      );
      if (response.statusCode == 200) {
        return TransactionModel.fromJson(response.data['data']);
      }
      throw Exception('Failed to update transaction');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<void> deleteTransaction(int id) async {
    try {
      final response = await _dio.delete('/transactions/$id');
      if (response.statusCode != 200) {
        throw Exception('Failed to delete transaction');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
