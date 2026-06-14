import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:budget_kos/shared/models/transaction_model.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/toast_helper.dart';
import '../../../transaction/presentation/bloc/transaction_bloc.dart';
import '../../../transaction/presentation/bloc/transaction_event.dart';
import '../../../transaction/presentation/bloc/transaction_state.dart';
import '../../../transaction/presentation/widgets/transaction_bottom_sheet.dart';

class DashboardRecentTransactions extends StatelessWidget {
  final TransactionLoaded state;
  final bool isExpanded;

  const DashboardRecentTransactions({
    super.key,
    required this.state,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
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
              context.read<TransactionBloc>().add(DeleteTransaction(tx.id!));
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
                    "$sign Rp ${AppFormatters.formatMoney(tx.amount)}", 
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
            color: iconColor.withValues(alpha: 0.1),
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
