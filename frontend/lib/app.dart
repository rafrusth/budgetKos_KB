import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'features/transaction/domain/repositories/transaction_repository.dart';
import 'features/transaction/presentation/bloc/transaction_bloc.dart';
import 'features/transaction/presentation/bloc/transaction_event.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'core/di/injection.dart';
import 'package:toastification/toastification.dart';
import 'core/widgets/network_aware_widget.dart';
import 'core/widgets/pin_protection_widget.dart';
import 'core/widgets/auto_sync_widget.dart';
import 'core/theme/theme_cubit.dart';
import 'core/widgets/custom_title_bar.dart';

class BudgetKosApp extends StatelessWidget {
  const BudgetKosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => getIt<AuthBloc>(),
        ),
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
              builder: (context, child) => CallbackShortcuts(
                bindings: {
                  const SingleActivator(LogicalKeyboardKey.escape): () {
                    final context = FocusManager.instance.primaryFocus?.context;
                    if (context != null && Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                      return;
                    }
                    if (appRouter.canPop()) {
                      appRouter.pop();
                    }
                  },
                },
                child: Column(
                  children: [
                    Expanded(
                      child: Focus(
                        autofocus: true,
                        child: AutoSyncWidget(
                          child: PinProtectionWidget(
                            child: NetworkAwareWidget(
                              child: child!,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
