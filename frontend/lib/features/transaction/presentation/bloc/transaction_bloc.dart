import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../domain/repositories/transaction_repository.dart';
import 'package:budget_kos/shared/models/transaction_model.dart';
import 'package:budget_kos/shared/models/category_model.dart';
import 'transaction_event.dart';
import 'transaction_state.dart';

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final TransactionRepository repository;

  TransactionBloc({required this.repository}) : super(TransactionInitial()) {
    on<FetchTransactions>(_onFetchTransactions);
    on<AddTransaction>(_onAddTransaction);
    on<AddCategory>(_onAddCategory);
    on<UpdateTransaction>(_onUpdateTransaction);
    on<DeleteTransaction>(_onDeleteTransaction);
    on<ChangeChartFilter>(_onChangeChartFilter);
  }

  Future<void> _onFetchTransactions(FetchTransactions event, Emitter<TransactionState> emit) async {
    emit(TransactionLoading());
    try {
      final transactions = await repository.getTransactions();
      final categories = await repository.getCategories();
      
      transactions.sort((a, b) => b.date.compareTo(a.date));

      double income = 0;
      double expense = 0;
      for (var tx in transactions) {
        if (tx.type == 'income') {
          income += tx.amount;
        } else {
          expense += tx.amount;
        }
      }

      final chartData = _generateChartData(transactions, ChartFilterType.income);

      emit(TransactionLoaded(
        transactions: transactions,
        categories: categories,
        totalIncome: income,
        totalExpense: expense,
        balance: income - expense,
        chartFilter: ChartFilterType.income,
        chartData: chartData,
      ));
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  Future<void> _onAddTransaction(AddTransaction event, Emitter<TransactionState> emit) async {
    if (state is TransactionLoaded) {
      try {
        final newTx = TransactionModel(
          id: null,
          title: event.title,
          amount: event.amount,
          type: event.type,
          categoryId: event.categoryId,
          notes: '',
          date: event.date,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        await repository.addTransaction(newTx);
        add(FetchTransactions()); // Re-fetch to get updated list and IDs
      } catch (e) {
        emit(TransactionError("Gagal menambahkan transaksi: $e"));
      }
    }
  }

  Future<void> _onAddCategory(
      AddCategory event, Emitter<TransactionState> emit) async {
    if (state is TransactionLoaded) {
      final currentState = state as TransactionLoaded;
      try {
        final newCategory = await repository.addCategory(event.name, event.type);
        final updatedCategories = List<CategoryModel>.from(currentState.categories)..add(newCategory);
        
        emit(currentState.copyWith(categories: updatedCategories));
      } catch (e) {
        emit(TransactionError(e.toString()));
        emit(currentState);
      }
    }
  }

  Future<void> _onUpdateTransaction(
      UpdateTransaction event, Emitter<TransactionState> emit) async {
    if (state is TransactionLoaded) {
      final currentState = state as TransactionLoaded;
      try {
        final updatedTx = await repository.updateTransaction(event.transaction);
        
        // Replace old transaction with updated one
        final updatedTransactions = currentState.transactions.map((tx) {
          return tx.id == updatedTx.id ? updatedTx : tx;
        }).toList();
        
        // Recalculate totals
        double expense = 0;
        double income = 0;
        for (var tx in updatedTransactions) {
          if (tx.type == 'expense') expense += tx.amount;
          if (tx.type == 'income') income += tx.amount;
        }

        emit(currentState.copyWith(
          transactions: updatedTransactions,
          totalExpense: expense,
          totalIncome: income,
          balance: income - expense,
        ));
      } catch (e) {
        emit(TransactionError(e.toString()));
        emit(currentState);
      }
    }
  }

  Future<void> _onDeleteTransaction(
      DeleteTransaction event, Emitter<TransactionState> emit) async {
    if (state is TransactionLoaded) {
      final currentState = state as TransactionLoaded;
      try {
        await repository.deleteTransaction(event.transactionId);
        
        // Remove transaction from list
        final updatedTransactions = currentState.transactions.where((tx) => tx.id != event.transactionId).toList();
        
        // Recalculate totals
        double expense = 0;
        double income = 0;
        for (var tx in updatedTransactions) {
          if (tx.type == 'expense') expense += tx.amount;
          if (tx.type == 'income') income += tx.amount;
        }

        emit(currentState.copyWith(
          transactions: updatedTransactions,
          totalExpense: expense,
          totalIncome: income,
          balance: income - expense,
        ));
      } catch (e) {
        emit(TransactionError(e.toString()));
        emit(currentState);
      }
    }
  }

  void _onChangeChartFilter(ChangeChartFilter event, Emitter<TransactionState> emit) {
    if (state is TransactionLoaded) {
      final currentState = state as TransactionLoaded;
      final newChartData = _generateChartData(currentState.transactions, event.filterType);
      emit(currentState.copyWith(
        chartFilter: event.filterType,
        chartData: newChartData,
      ));
    }
  }

  List<FlSpot> _generateChartData(List<TransactionModel> transactions, ChartFilterType filterType) {
    if (transactions.isEmpty) return [const FlSpot(0, 0)];

    // Sort ascending for chart
    final sortedTx = List<TransactionModel>.from(transactions)..sort((a, b) => a.date.compareTo(b.date));
    
    Map<int, double> groupedData = {};
    double runningBalance = 0;

    for (var tx in sortedTx) {
      final dateObj = tx.date.toLocal();
      final dayStart = DateTime(dateObj.year, dateObj.month, dateObj.day);
      final int dayKey = dayStart.millisecondsSinceEpoch ~/ 86400000;

      if (tx.type == 'income') runningBalance += tx.amount;
      if (tx.type == 'expense') runningBalance -= tx.amount;

      switch (filterType) {
        case ChartFilterType.income:
          if (tx.type == 'income') {
            groupedData[dayKey] = (groupedData[dayKey] ?? 0) + tx.amount;
          } else {
            groupedData.putIfAbsent(dayKey, () => 0);
          }
          break;
        case ChartFilterType.expense:
          if (tx.type == 'expense') {
            groupedData[dayKey] = (groupedData[dayKey] ?? 0) + tx.amount;
          } else {
            groupedData.putIfAbsent(dayKey, () => 0);
          }
          break;
        case ChartFilterType.balance:
          groupedData[dayKey] = runningBalance;
          break;
      }
    }

    List<FlSpot> spots = groupedData.entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value);
    }).toList();

    spots.sort((a, b) => a.x.compareTo(b.x));

    if (spots.isEmpty) return [const FlSpot(0, 0)];
    return spots;
  }
}
