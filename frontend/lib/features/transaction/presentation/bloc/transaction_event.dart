import 'package:budget_kos/shared/models/transaction_model.dart';

abstract class TransactionEvent {}

class FetchTransactions extends TransactionEvent {}

class AddTransaction extends TransactionEvent {
  final String title;
  final double amount;
  final String type; // 'income' or 'expense'
  final String categoryId;
  final DateTime date;

  AddTransaction({
    required this.title,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.date,
  });
}

enum ChartFilterType { income, expense, balance }

class AddCategory extends TransactionEvent {
  final String name;
  final String type;
  AddCategory(this.name, this.type);
}

class UpdateTransaction extends TransactionEvent {
  final TransactionModel transaction;
  UpdateTransaction(this.transaction);
}

class DeleteTransaction extends TransactionEvent {
  final String transactionId;
  DeleteTransaction(this.transactionId);
}


class ChangeChartFilter extends TransactionEvent {
  final ChartFilterType filterType;

  ChangeChartFilter(this.filterType);
}
