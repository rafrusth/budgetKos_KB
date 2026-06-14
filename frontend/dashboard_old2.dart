import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart' as import_router;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../transaction/presentation/bloc/transaction_bloc.dart';
import '../../../transaction/presentation/bloc/transaction_state.dart';
import '../../../transaction/presentation/bloc/transaction_event.dart';
import '../../../transaction/presentation/widgets/transaction_bottom_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../transaction/data/models/transaction_model.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  double _monthlyBudget = 2000000; // Default Rp 2.000.000
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
    final TextEditingController controller = TextEditingController(text: _monthlyBudget.toInt().toString());
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Atur Target Pengeluaran"),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              prefixText: 'Rp ',
              hintText: 'Misal: 2000000',
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
            ElevatedButton(
              onPressed: () {
                final val = double.tryParse(controller.text.replaceAll(RegExp(r'[^0-9]'), ''));
                if (val != null && val > 0) {
                  _saveBudget(val);
                }
                Navigator.pop(context);
              },
              child: const Text("Simpan"),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? theme.colorScheme.background : const Color(0xFFF7F7F0); 
    
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: BlocBuilder<TransactionBloc, TransactionState>(
          builder: (context, state) {
            if (state is TransactionLoading || state is TransactionInitial) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is TransactionLoaded) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(theme),
                    const SizedBox(height: 30),
                    _buildBalanceCard(theme, state),
                    const SizedBox(height: 24),
                    _buildBudgetCard(theme, state),
                    const SizedBox(height: 32),
                    _buildSectionTitle(theme, 'Quick Stats', ''),
                    const SizedBox(height: 16),
                    _buildQuickStats(context, theme, state),
                    const SizedBox(height: 32),
                    _buildSectionTitle(theme, 'Recent Transactions', 'See all', onActionTap: () {
                      import_router.GoRouter.of(context).go('/reports');
                    }),
                    const SizedBox(height: 16),
                    _buildRecentTransactions(context, theme, state),
                    const SizedBox(height: 100), // padding for bottom nav
                  ],
                ),
              );
            } else if (state is TransactionError) {
              return Center(child: Text(state.message));
            }
            return const SizedBox();
          },
        ),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFCC66), // Yellow/Orange card from image
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFCC66).withOpacity(0.4),
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
            children: [
              const Icon(Icons.fiber_manual_record, size: 8, color: Colors.black87),
              const SizedBox(width: 8),
              Text('Bulan Ini', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black87, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('Data Riil', style: theme.textTheme.bodySmall?.copyWith(color: Colors.black87, fontWeight: FontWeight.bold)),
          )
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

  Widget _buildQuickStats(BuildContext context, ThemeData theme, TransactionLoaded state) {
    final isDark = theme.brightness == Brightness.dark;
    
    // Calculate progress roughly for visualization
    double maxAmount = state.totalIncome > state.totalExpense ? state.totalIncome : state.totalExpense;
    if (maxAmount == 0) maxAmount = 1; // prevent division by zero
    double incomeProgress = state.totalIncome / maxAmount;
    double expenseProgress = state.totalExpense / maxAmount;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _statCard(theme, 'Pemasukan', 'Rp ${_formatMoney(state.totalIncome)}', Colors.green, incomeProgress),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _statCard(theme, 'Pengeluaran', 'Rp ${_formatMoney(state.totalExpense)}', Colors.orange, expenseProgress),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _filterChip(context, theme, 'Pemasukan', ChartFilterType.income, state.chartFilter),
                  _filterChip(context, theme, 'Pengeluaran', ChartFilterType.expense, state.chartFilter),
                  _filterChip(context, theme, 'Saldo', ChartFilterType.balance, state.chartFilter),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 220,
                child: LineChart(
                  LineChartData(
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            final amountText = 'Rp ${_formatMoney(spot.y)}';
                            final date = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt() * 86400000);
                            
                            String title = "Total (${date.day}/${date.month})";
                            
                            if (state.chartFilter == ChartFilterType.balance) {
                              title = 'Saldo (${date.day}/${date.month})';
                            } else if (state.chartFilter == ChartFilterType.income) {
                              title = 'Pemasukan (${date.day}/${date.month})';
                            } else if (state.chartFilter == ChartFilterType.expense) {
                              title = 'Pengeluaran (${date.day}/${date.month})';
                            }
                            
                            return LineTooltipItem(
                              '$title\n',
                              TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 12),
                              children: [
                                TextSpan(
                                  text: amountText,
                                  style: TextStyle(
                                    color: _getChartColor(state.chartFilter),
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
                        spots: state.chartData,
                        isCurved: true,
                        color: _getChartColor(state.chartFilter),
                        barWidth: 4,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: _getChartColor(state.chartFilter).withOpacity(0.2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total ${state.chartFilter.name}', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                  Text('Rp ${_getChartTotal(state)}', style: theme.textTheme.titleMedium?.copyWith(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
                ],
              )
            ],
          ),
        )
      ],
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
          // Progress bar representation
          Row(
            children: [
              Text('0%', style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey, fontSize: 10)),
              const Spacer(),
              Text('${(progress * 100).toInt()}%', style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey, fontSize: 10)),
              const Spacer(),
              Text('100%', style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 4),
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
          )
        ],
      ),
    );
  }

  Color _getChartColor(ChartFilterType type) {
    switch (type) {
      case ChartFilterType.income: return Colors.green;
      case ChartFilterType.expense: return Colors.orange;
      case ChartFilterType.balance: return Colors.blue;
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Transaksi berhasil dihapus')),
              );
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
