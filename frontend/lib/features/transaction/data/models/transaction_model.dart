import 'category_model.dart';

class TransactionModel {
  final int id;
  final String title;
  final double amount;
  final String type; // "income" or "expense"
  final int categoryId;
  final CategoryModel? category;
  final String notes;
  final DateTime date;

  TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.categoryId,
    this.category,
    required this.notes,
    required this.date,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      type: json['type'] ?? '',
      categoryId: json['category_id'] ?? 0,
      category: json['category'] != null ? CategoryModel.fromJson(json['category']) : null,
      notes: json['notes'] ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type,
      'category_id': categoryId,
      'notes': notes,
      'date': date.toUtc().toIso8601String(),
    };
  }
}
