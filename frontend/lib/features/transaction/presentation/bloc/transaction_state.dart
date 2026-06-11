import 'package:fl_chart/fl_chart.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/category_model.dart';
import 'transaction_event.dart';

abstract class TransactionState {}

class TransactionInitial extends TransactionState {}

class TransactionLoading extends TransactionState {}

class TransactionLoaded extends TransactionState {
  final List<TransactionModel> transactions;
  final List<CategoryModel> categories;
  final double totalIncome;
  final double totalExpense;
  final double balance;
  
  final ChartFilterType chartFilter;
  final List<FlSpot> chartData;

  TransactionLoaded({
    required this.transactions,
    required this.categories,
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.chartFilter,
    required this.chartData,
  });

  TransactionLoaded copyWith({
    List<TransactionModel>? transactions,
    List<CategoryModel>? categories,
    double? totalIncome,
    double? totalExpense,
    double? balance,
    ChartFilterType? chartFilter,
    List<FlSpot>? chartData,
  }) {
    return TransactionLoaded(
      transactions: transactions ?? this.transactions,
      categories: categories ?? this.categories,
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpense: totalExpense ?? this.totalExpense,
      balance: balance ?? this.balance,
      chartFilter: chartFilter ?? this.chartFilter,
      chartData: chartData ?? this.chartData,
    );
  }
}

class TransactionError extends TransactionState {
  final String message;
  TransactionError(this.message);
}
