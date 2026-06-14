import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart' as import_router;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:io' as import_io;
import 'package:window_manager/window_manager.dart';
import '../../../../core/widgets/custom_title_bar.dart';
import '../../../../core/utils/toast_helper.dart';
import '../../../../core/utils/popup_helper.dart';
import '../../../transaction/presentation/bloc/transaction_bloc.dart';
import '../../../transaction/presentation/bloc/transaction_state.dart';
import '../../../transaction/presentation/bloc/transaction_event.dart';
import '../../../transaction/presentation/widgets/transaction_bottom_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:budget_kos/shared/models/transaction_model.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/formatters.dart';
import 'package:flutter/services.dart';
import '../../../../core/utils/profile_notifier.dart';
import '../widgets/dashboard_summary_cards.dart';
import '../widgets/dashboard_charts.dart';
import '../widgets/dashboard_recent_transactions.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  double _monthlyBudget = 2000000; // Default Rp 2.000.000
  double _incomeTarget = 3000000; // Default Rp 3.000.000
  bool _hasShownWarning = false;
  String _userName = 'Mahasiswa';
  String _userEmail = '@anak_kos';

  @override
  void initState() {
    super.initState();
    _loadProfileAndBudget();
  }

  Future<void> _loadProfileAndBudget() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _monthlyBudget = prefs.getDouble('monthly_budget') ?? 2000000;
      _incomeTarget = prefs.getDouble('income_target') ?? 3000000;
      _userName = prefs.getString('user_name') ?? 'Mahasiswa';
      
      final email = prefs.getString('user_email') ?? 'anak_kos@university.edu';
      _userEmail = '@${email.split('@').first}'; // extract part before @ as handle
    });
  }

  Future<void> _saveBudget(double newBudget) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('monthly_budget', newBudget);
    setState(() {
      _monthlyBudget = newBudget;
    });
  }

  void _showSetBudgetDialog(BuildContext context) {
    _showEditTargetBottomSheet(
      context: context,
      title: 'Atur Target Pengeluaran',
      initialValue: _monthlyBudget,
      onSave: (val) => _saveBudget(val),
    );
  }

  void _updateIncomeTarget(double newTarget) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('income_target', newTarget);
    setState(() {
      _incomeTarget = newTarget;
    });
  }

  void _showEditIncomeDialog() {
    _showEditTargetBottomSheet(
      context: context,
      title: 'Atur Target Pemasukan',
      initialValue: _incomeTarget,
      onSave: (val) => _updateIncomeTarget(val),
    );
  }

  void _showEditTargetBottomSheet({required BuildContext context, required String title, required double initialValue, required Function(double) onSave}) {
    final theme = Theme.of(context);
    final controller = TextEditingController(text: initialValue.toInt().toString());
    
    // Apply initial formatting
    if (controller.text.isNotEmpty) {
      controller.text = CurrencyInputFormatter().formatEditUpdate(
        const TextEditingValue(text: ''), 
        TextEditingValue(text: controller.text)
      ).text;
    }

    PopupHelper.showAdaptivePopup(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final isDark = theme.brightness == Brightness.dark;
        Widget content = Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24, right: 24, top: 24,
          ),
          decoration: BoxDecoration(
            color: isDark ? Colors.black.withValues(alpha: 0.4) : theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border(top: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05))),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('Rp ', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey)),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        CurrencyInputFormatter(),
                      ],
                      style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        hintText: '0',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    final cleanText = controller.text.replaceAll(RegExp(r'[^\d]'), '');
                    final val = double.tryParse(cleanText);
                    if (val != null && val > 0) {
                      onSave(val);
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('Simpan Target', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );

        if (isDark) {
          content = BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
            child: content,
          );
        }

        return AnimatedPadding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            child: content,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: BlocConsumer<TransactionBloc, TransactionState>(
          listener: (context, state) {
            if (state is TransactionLoaded) {
              final double expense = state.totalExpense;
              final double progress = _monthlyBudget > 0 ? expense / _monthlyBudget : 0;
              if (progress >= 0.8 && !_hasShownWarning) {
                _hasShownWarning = true;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.white),
                        const SizedBox(width: 8),
                        Expanded(child: Text('Peringatan: Pengeluaran Anda sudah mencapai ${(progress*100).toStringAsFixed(0)}% dari batas anggaran!')),
                      ],
                    ),
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 5),
                  ),
                );
              }
            }
          },
          builder: (context, state) {
            if (state is TransactionLoading || state is TransactionInitial) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is TransactionLoaded) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 800) {
                    return _buildDesktopLayout(context, theme, state);
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<TransactionBloc>().add(FetchTransactions());
                      await _loadProfileAndBudget();
                    },
                    child: _buildMobileLayout(context, theme, state),
                  );
                },
              );
            } else if (state is TransactionError) {
              return Center(child: Text(state.message));
            }
            return const SizedBox();
          },
        ),
    );
  }
  Widget _buildMobileLayout(BuildContext context, ThemeData theme, TransactionLoaded state) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 24, 24, 120),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme),
            const SizedBox(height: 24),
            DashboardBalanceCard(state: state),
            const SizedBox(height: 24),
            DashboardBudgetCard(
              state: state, 
              monthlyBudget: _monthlyBudget, 
              onEditBudget: () => _showSetBudgetDialog(context), 
              isDesktop: false,
            ),
            const SizedBox(height: 24),
            Text('Statistik', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildQuickStats(context, theme, state, isDesktop: false),
            const SizedBox(height: 24),
            Text('Transaksi Sebelumnya', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            DashboardRecentTransactions(state: state),
          ],
        ),
      );
  }

  Widget _buildDesktopLayout(BuildContext context, ThemeData theme, TransactionLoaded state) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme),
          const SizedBox(height: 24),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double availableWidth = constraints.maxWidth;
                final bool isWide = availableWidth > 1100;

                if (isWide) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 6,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left Column (Flex 2)
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    Row(
                                      children: [
                                        Expanded(child: DashboardBalanceCard(state: state)),
                                        const SizedBox(width: 24),
                                        Expanded(child: DashboardBudgetCard(
                                          state: state, 
                                          monthlyBudget: _monthlyBudget, 
                                          onEditBudget: () => _showSetBudgetDialog(context),
                                        )),
                                      ],
                                    ),
                                  const SizedBox(height: 24),
                                  _buildSectionTitle(theme, 'Quick Stats', ''),
                                  const SizedBox(height: 16),
                                  Expanded(child: DashboardSummaryCards(
                                    state: state,
                                    monthlyBudget: _monthlyBudget,
                                    incomeTarget: _incomeTarget,
                                    onEditBudget: () => _showSetBudgetDialog(context),
                                    onEditIncome: _showEditIncomeDialog,
                                    isDesktop: true,
                                    isExpanded: true,
                                  )),
                                ],
                              ),
                            ),
                            const SizedBox(width: 32),
                            // Right Column (Flex 1)
                            Expanded(
                              flex: 1,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionTitle(theme, 'Recent Transactions', 'See all', onActionTap: () {
                                    import_router.GoRouter.of(context).go('/reports');
                                  }),
                                  const SizedBox(height: 16),
                                  Expanded(child: DashboardRecentTransactions(state: state, isExpanded: true)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        flex: 4,
                        child: DashboardCharts(state: state, isDesktop: true, isExpanded: true),
                      ),
                    ],
                  );
                } else {
                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: DashboardBalanceCard(state: state)),
                            const SizedBox(width: 24),
                            Expanded(child: DashboardBudgetCard(
                              state: state,
                              monthlyBudget: _monthlyBudget,
                              onEditBudget: () => _showSetBudgetDialog(context),
                            )),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildSectionTitle(theme, 'Quick Stats', ''),
                        const SizedBox(height: 16),
                        _buildQuickStats(context, theme, state, isDesktop: true),
                        const SizedBox(height: 24),
                        _buildSectionTitle(theme, 'Recent Transactions', 'See all', onActionTap: () {
                          import_router.GoRouter.of(context).go('/reports');
                        }),
                        const SizedBox(height: 16),
                        DashboardRecentTransactions(state: state),
                      ],
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return _buildHeaderContent(theme);
  }

  Widget _buildHeaderContent(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ValueListenableBuilder<ProfileData>(
          valueListenable: profileNotifier,
          builder: (context, profile, child) {
            final displayEmail = '@${profile.email.split('@').first}';
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Halo, ${profile.name}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 4),
                Text(displayEmail, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
              ],
            );
          },
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                context.read<TransactionBloc>().add(FetchTransactions());
              },
              tooltip: 'Refresh',
            ),
            const SizedBox(width: 8),
            const WindowButtonsRow(),
          ],
        ),
      ],
    );
  }


  Widget _buildSectionTitle(ThemeData theme, String title, String action, {VoidCallback? onActionTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: theme.textTheme.bodyLarge?.color)),
        if (action.isNotEmpty)
          GestureDetector(
            onTap: onActionTap,
            child: Text(action, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.orange, fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }







  Widget _buildQuickStats(BuildContext context, ThemeData theme, TransactionLoaded state, {bool isDesktop = false}) {
    return Column(
      children: [
        DashboardSummaryCards(
          state: state,
          monthlyBudget: _monthlyBudget,
          incomeTarget: _incomeTarget,
          onEditBudget: () => _showSetBudgetDialog(context),
          onEditIncome: _showEditIncomeDialog,
          isDesktop: isDesktop,
        ),
        const SizedBox(height: 24),
        DashboardCharts(state: state, isDesktop: isDesktop),
      ],
    );
  }



}
