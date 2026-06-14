import 'category_model.dart';

class TransactionModel {
  final String? id;
  final String title;
  final double amount;
  final String type;
  final String categoryId;
  final CategoryModel? category;
  final String? notes;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int syncStatus;
  final int isDeleted;

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
    this.syncStatus = 0,
    this.isDeleted = 0,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map, {CategoryModel? category}) {
    return TransactionModel(
      id: map['id']?.toString(),
      title: map['title'],
      amount: (map['amount'] as num).toDouble(),
      type: map['type'],
      categoryId: map['category_id']?.toString() ?? '',
      category: category,
      notes: map['notes'],
      date: DateTime.parse(map['date']),
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      syncStatus: map['sync_status'] ?? 0,
      isDeleted: map['is_deleted'] ?? 0,
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
      'sync_status': syncStatus,
      'is_deleted': isDeleted,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'amount': amount,
      'type': type,
      'category_id': categoryId,
      'notes': notes,
      'date': date.toUtc().toIso8601String(),
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }
}
