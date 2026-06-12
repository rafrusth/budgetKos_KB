import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart' as import_router;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/utils/toast_helper.dart';
import '../../../transaction/presentation/bloc/transaction_bloc.dart';
import '../../../transaction/presentation/bloc/transaction_state.dart';
import '../../../transaction/presentation/bloc/transaction_event.dart';
import '../../../transaction/presentation/widgets/transaction_bottom_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../transaction/data/models/transaction_model.dart';
import '../../../../core/utils/currency_formatter.dart';
import 'package:flutter/services.dart';

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

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = theme.brightness == Brightness.dark;
        Widget content = Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? Colors.black.withOpacity(0.4) : theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border(top: BorderSide(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05))),
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
                    color: Colors.grey.withOpacity(0.3),
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

        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
    final isDark = theme.brightness == Brightness.dark;
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
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<TransactionBloc>().add(FetchTransactions());
                  await _loadProfileAndBudget();
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 16, bottom: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 24.0), child: _buildHeader(theme)),
                      const SizedBox(height: 30),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 24.0), child: _buildBalanceCard(theme, state)),
                      const SizedBox(height: 24),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 24.0), child: _buildBudgetCard(theme, state)),
                      const SizedBox(height: 32),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 24.0), child: _buildSectionTitle(theme, 'Quick Stats', '')),
                      const SizedBox(height: 16),
                      _buildQuickStats(context, theme, state),
                      const SizedBox(height: 32),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 24.0), child: _buildSectionTitle(theme, 'Recent Transactions', 'See all', onActionTap: () {
                        import_router.GoRouter.of(context).go('/reports');
                      })),
                      const SizedBox(height: 16),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 24.0), child: _buildRecentTransactions(context, theme, state)),
                      const SizedBox(height: 100), // padding for bottom nav
                    ],
                  ),
                ),
              );
            } else if (state is TransactionError) {
              return Center(child: Text(state.message));
            }
            return const SizedBox();
          },
        ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Halo, $_userName', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 4),
            Text(_userEmail, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
          ],
        ),
      ],
    );
  }

  Widget _buildBalanceCard(ThemeData theme, TransactionLoaded state) {
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0);
    final totalDays = lastDay.day;
    final currentDay = now.day;
    final progress = currentDay / totalDays;
    
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    final monthName = months[now.month - 1];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiary, // Light Blue Card
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.tertiary.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue,
                ),
                child: const Icon(Icons.account_balance_wallet, size: 12, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Text('Sisa Saldo', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 16),
          Text('Rp ${_formatMoney(state.balance)}', style: theme.textTheme.headlineLarge?.copyWith(color: Colors.black, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("1 $monthName", style: const TextStyle(color: Colors.black54, fontSize: 12)),
              Text("Hari ini ($currentDay)", style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 12)),
              Text("${lastDay.day} $monthName", style: const TextStyle(color: Colors.black54, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.5),
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.secondary),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  String _formatMoney(double amount) {
    // Simple formatter without intl
    String res = amount.toInt().toString();
    if (res.length > 3) {
      res = res.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
    }
    return res;
  }

  Widget _buildBudgetCard(ThemeData theme, TransactionLoaded state) {
    final isDark = theme.brightness == Brightness.dark;
    final double expense = state.totalExpense;
    double progress = _monthlyBudget > 0 ? expense / _monthlyBudget : 0;
    if (progress > 1.0) progress = 1.0;

    final Color progressColor = progress > 0.8 ? Colors.red : (progress > 0.5 ? Colors.orange : Colors.green);

    return GestureDetector(
      onTap: () => _showSetBudgetDialog(context),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Target Pengeluaran Bulanan', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                const Icon(Icons.edit, size: 16, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('Rp ${_formatMoney(expense)}', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: progressColor)),
                Text(' / Rp ${_formatMoney(_monthlyBudget)}', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 16),
            Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: progressColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              progress >= 1.0 ? 'Batas budget telah terlampaui!' : 'Tersisa Rp ${_formatMoney(_monthlyBudget - expense)}',
              style: theme.textTheme.labelSmall?.copyWith(color: progress >= 1.0 ? Colors.red : Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _actionButton(context, theme, CupertinoIcons.plus_circle, 'Transaksi', () {
          TransactionBottomSheet.show(context, type: 'expense');
        }),
        _actionButton(context, theme, CupertinoIcons.chart_pie, 'Laporan', () {
          import_router.GoRouter.of(context).push('/reports');
        }),
        _actionButton(context, theme, CupertinoIcons.chat_bubble_2, 'AI Chat', () {
          import_router.GoRouter.of(context).push('/ai');
        }),
      ],
    );
  }

  Widget _actionButton(BuildContext context, ThemeData theme, IconData icon, String label, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: theme.colorScheme.primary.withOpacity(0.1),
        highlightColor: theme.colorScheme.primary.withOpacity(0.05),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark ? theme.cardColor : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.2 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(icon, color: theme.textTheme.bodyMedium?.color),
            ),
            const SizedBox(height: 8),
            Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.textTheme.bodyMedium?.color, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
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

  List<FlSpot> _generateChartData(List<TransactionModel> transactions, ChartFilterType filterType) {
    if (transactions.isEmpty) return [const FlSpot(0, 0)];

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

  Widget _buildQuickStats(BuildContext context, ThemeData theme, TransactionLoaded state) {
    final isDark = theme.brightness == Brightness.dark;
    
    double incomeProgress = _incomeTarget > 0 ? state.totalIncome / _incomeTarget : 0;
    double expenseProgress = _monthlyBudget > 0 ? state.totalExpense / _monthlyBudget : 0;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _showEditIncomeDialog,
                  child: _statCard(theme, 'Pemasukan', 'Rp ${_formatMoney(state.totalIncome)}', theme.colorScheme.primary, incomeProgress),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: () => _showSetBudgetDialog(context), // Reuse edit budget for expense target
                  child: _statCard(theme, 'Pengeluaran', 'Rp ${_formatMoney(state.totalExpense)}', theme.colorScheme.secondary, expenseProgress),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: MediaQuery.of(context).size.width * 0.85, // Make it roughly square based on viewportFraction
          child: PageView(
            controller: PageController(viewportFraction: 0.9),
            padEnds: false,
            children: [
              _buildChartCard(theme, isDark, state, ChartFilterType.income, state.totalIncome, true),
              _buildChartCard(theme, isDark, state, ChartFilterType.expense, state.totalExpense, false),
              _buildChartCard(theme, isDark, state, ChartFilterType.balance, state.balance, false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChartCard(ThemeData theme, bool isDark, TransactionLoaded state, ChartFilterType type, double total, bool isFirst) {
    final chartData = _generateChartData(state.transactions, type);
    final String title = type == ChartFilterType.income ? "Pemasukan" : type == ChartFilterType.expense ? "Pengeluaran" : "Saldo";
    
    return Container(
      margin: EdgeInsets.only(left: isFirst ? 24 : 8, right: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _getChartColor(theme, type).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              "Grafik $title",
              style: theme.textTheme.titleSmall?.copyWith(
                color: _getChartColor(theme, type),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final amountText = 'Rp ${_formatMoney(spot.y)}';
                        final date = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt() * 86400000);
                        return LineTooltipItem(
                          '$title (${date.day}/${date.month})\n',
                          TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 12),
                          children: [
                            TextSpan(
                              text: amountText,
                              style: TextStyle(
                                color: _getChartColor(theme, type),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withOpacity(0.1),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final date = DateTime.fromMillisecondsSinceEpoch(value.toInt() * 86400000);
                        return SideTitleWidget(
                          meta: meta,
                          child: Text("${date.day}/${date.month}", style: theme.textTheme.labelSmall?.copyWith(fontSize: 10, color: Colors.grey)),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      getTitlesWidget: (value, meta) {
                        if (value == meta.max && value != 0) return const SizedBox.shrink();
                        String text;
                        if (value.abs() >= 1000000) {
                          text = '${(value / 1000000).toStringAsFixed(1)}Jt';
                        } else if (value.abs() >= 1000) {
                          text = '${(value / 1000).toStringAsFixed(0)}K';
                        } else {
                          text = value.toStringAsFixed(0);
                        }
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(text, style: theme.textTheme.labelSmall?.copyWith(fontSize: 10, color: Colors.grey)),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: chartData,
                    isCurved: true,
                    color: _getChartColor(theme, type),
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: _getChartColor(theme, type).withOpacity(0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total $title', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
              Text('Rp ${_formatMoney(total)}', style: theme.textTheme.titleMedium?.copyWith(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }

  Widget _statCard(ThemeData theme, String title, String amount, Color color, double progress) {
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              title == 'Pemasukan' ? Icons.arrow_downward : Icons.arrow_upward,
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(height: 16),
          Text(title, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text(amount, style: theme.textTheme.titleMedium?.copyWith(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          // Progress text on top
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${(progress * 100).toInt()}%', 
              style: theme.textTheme.labelLarge?.copyWith(
                color: color, 
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('0%', style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey, fontSize: 10)),
              const Spacer(),
              Text('100%', style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Color _getChartColor(ThemeData theme, ChartFilterType type) {
    switch (type) {
      case ChartFilterType.income: return theme.colorScheme.primary;
      case ChartFilterType.expense: return theme.colorScheme.secondary;
      case ChartFilterType.balance: return theme.colorScheme.tertiary;
    }
  }

  String _getChartTotal(TransactionLoaded state) {
    switch (state.chartFilter) {
      case ChartFilterType.income: return _formatMoney(state.totalIncome);
      case ChartFilterType.expense: return _formatMoney(state.totalExpense);
      case ChartFilterType.balance: return _formatMoney(state.balance);
    }
  }

  Widget _filterChip(BuildContext context, ThemeData theme, String label, ChartFilterType type, ChartFilterType current) {
    final isSelected = type == current;
    return GestureDetector(
      onTap: () {
        context.read<TransactionBloc>().add(ChangeChartFilter(type));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isSelected ? theme.colorScheme.primary : Colors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(BuildContext context, ThemeData theme, TransactionLoaded state) {
    final isDark = theme.brightness == Brightness.dark;
    
    if (state.transactions.isEmpty) {
      return const Center(child: Text("Belum ada transaksi", style: TextStyle(color: Colors.grey)));
    }

    final recentTx = state.transactions.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: recentTx.asMap().entries.map((entry) {
          final tx = entry.value;
          final isLast = entry.key == recentTx.length - 1;
          final isIncome = tx.type == 'income';
          final color = isIncome ? Colors.green : Colors.orange;
          final iconData = _getCategoryIcon(tx.category?.name, isIncome);
          final sign = isIncome ? '+' : '-';
          
          return Dismissible(
            key: Key('dash_tx_${tx.id}'),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              color: Colors.red,
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            confirmDismiss: (direction) async {
              return await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text("Konfirmasi"),
                    content: const Text("Apakah Anda yakin ingin menghapus transaksi ini?"),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("Batal")),
                      TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text("Hapus", style: TextStyle(color: Colors.red))),
                    ],
                  );
                },
              );
            },
            onDismissed: (direction) {
              context.read<TransactionBloc>().add(DeleteTransaction(tx.id));
              ToastHelper.showSuccess(context, 'Transaksi berhasil dihapus');
            },
            child: InkWell(
              onTap: () {
                TransactionBottomSheet.show(context, type: tx.type, transaction: tx);
              },
              child: Column(
                children: [
                  _txItem(
                    theme, 
                    tx.title, 
                    "${tx.date.day}/${tx.date.month}/${tx.date.year}", 
                    "$sign Rp ${_formatMoney(tx.amount)}", 
                    color, 
                    iconData,
                  ),
                  if (!isLast)
                    const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _getCategoryIcon(String? categoryName, bool isIncome) {
    if (categoryName == null) return isIncome ? Icons.arrow_downward : Icons.arrow_upward;
    
    final name = categoryName.toLowerCase();
    if (name.contains('makan') || name.contains('food')) return Icons.fastfood;
    if (name.contains('minum') || name.contains('drink')) return Icons.local_cafe;
    if (name.contains('transport') || name.contains('bensin') || name.contains('gojek') || name.contains('grab')) return Icons.directions_car;
    if (name.contains('belanja') || name.contains('shop') || name.contains('pakaian')) return Icons.shopping_bag;
    if (name.contains('tagihan') || name.contains('bill') || name.contains('listrik') || name.contains('air')) return Icons.receipt;
    if (name.contains('gaji') || name.contains('salary') || name.contains('pendapatan') || name.contains('bonus')) return Icons.account_balance_wallet;
    if (name.contains('hiburan') || name.contains('entertainment') || name.contains('nonton') || name.contains('game')) return Icons.movie;
    if (name.contains('kesehatan') || name.contains('health') || name.contains('obat') || name.contains('rs') || name.contains('dokter')) return Icons.medical_services;
    if (name.contains('pendidikan') || name.contains('education') || name.contains('sekolah') || name.contains('kuliah') || name.contains('buku')) return Icons.school;
    if (name.contains('kos') || name.contains('sewa') || name.contains('rent') || name.contains('rumah')) return Icons.house;
    if (name.contains('transfer') || name.contains('kirim')) return Icons.sync_alt;
    if (name.contains('investasi') || name.contains('saham') || name.contains('crypto')) return Icons.trending_up;
    
    return isIncome ? Icons.arrow_downward : Icons.arrow_upward;
  }

  Widget _txItem(ThemeData theme, String title, String subtitle, String amount, Color iconColor, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: iconColor),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
              const SizedBox(height: 4),
              Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
            ],
          ),
        ),
        Text(amount, style: theme.textTheme.titleMedium?.copyWith(
          color: amount.startsWith('+') ? Colors.green : theme.textTheme.bodyLarge?.color, 
          fontWeight: FontWeight.w800
        )),
      ],
    );
  }
}
