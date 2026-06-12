import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'features/transaction/domain/repositories/transaction_repository.dart';
import 'features/transaction/presentation/bloc/transaction_bloc.dart';
import 'features/transaction/presentation/bloc/transaction_event.dart';
import 'package:toastification/toastification.dart';
import 'core/widgets/network_aware_widget.dart';
import 'core/widgets/pin_protection_widget.dart';
import 'core/theme/theme_cubit.dart';

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
        BlocProvider<ThemeCubit>(
          create: (context) => ThemeCubit(),
        ),
      ],
      child: ToastificationWrapper(
        child: BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, themeMode) {
            return MaterialApp.router(
              title: 'BudgetKos AI',
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode,
              routerConfig: appRouter,
              builder: (context, child) => NetworkAwareWidget(
                child: PinProtectionWidget(child: child ?? const SizedBox()),
              ),
            );
          },
        ),
      ),
    );
  }
}
