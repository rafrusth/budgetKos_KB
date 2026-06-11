import 'category_model.dart';

class TransactionModel {
  final int? id;
  final String title;
  final double amount;
  final String type;
  final int categoryId;
  final CategoryModel? category;
  final String? notes;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  TransactionModel({
    this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.categoryId,
    this.category,
    this.notes,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map, {CategoryModel? category}) {
    return TransactionModel(
      id: map['id'],
      title: map['title'],
      amount: map['amount'] as double,
      type: map['type'],
      categoryId: map['category_id'],
      category: category,
      notes: map['notes'],
      date: DateTime.parse(map['date']),
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      isSynced: map['is_synced'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'amount': amount,
      'type': type,
      'category_id': categoryId,
      'notes': notes,
      'date': date.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }
}
