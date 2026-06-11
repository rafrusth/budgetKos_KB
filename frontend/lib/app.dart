import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'features/transaction/domain/repositories/transaction_repository.dart';
import 'features/transaction/presentation/bloc/transaction_bloc.dart';
import 'features/transaction/presentation/bloc/transaction_event.dart';

class BudgetKosApp extends StatelessWidget {
  const BudgetKosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<TransactionBloc>(
          create: (context) => TransactionBloc(
            repository: TransactionRepository(),
          )..add(FetchTransactions()),
        ),
      ],
      child: MaterialApp.router(
        title: 'BudgetKos AI',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: appRouter,
      ),
    );
  }
}
