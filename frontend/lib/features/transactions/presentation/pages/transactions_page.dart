import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../transaction/presentation/bloc/transaction_bloc.dart';
import '../../../transaction/presentation/bloc/transaction_state.dart';
import '../../../transaction/presentation/bloc/transaction_event.dart';
import '../../../transaction/presentation/widgets/transaction_bottom_sheet.dart' as import_transaction_sheet;

class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Semua Transaksi', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: BlocBuilder<TransactionBloc, TransactionState>(
        builder: (context, state) {
          if (state is TransactionLoading || state is TransactionInitial) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is TransactionLoaded) {
            if (state.transactions.isEmpty) {
              return const Center(child: Text("Belum ada transaksi"));
            }

            // We can just display all transactions sorted by date
            final transactions = List.from(state.transactions)
              ..sort((a, b) => (b as dynamic).date.compareTo((a as dynamic).date));

            return RefreshIndicator(
              onRefresh: () async {
                context.read<TransactionBloc>().add(FetchTransactions());
              },
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 100),
                itemCount: transactions.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final theme = Theme.of(context);
                  final tx = transactions[index];
                  final isIncome = tx.type == 'income';
                  final color = isIncome ? theme.colorScheme.primary : theme.colorScheme.secondary;
                  final sign = isIncome ? '+' : '-';
                  
                  return Dismissible(
                    key: Key('wallet_tx_${tx.id}'),
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
                    },
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: color.withOpacity(0.1),
                        child: Icon(isIncome ? Icons.arrow_downward : Icons.arrow_upward, color: color),
                      ),
                      title: Text(tx.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("${tx.date.day}/${tx.date.month}/${tx.date.year}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      trailing: Text(
                        "$sign Rp ${_formatMoney(tx.amount)}",
                        style: TextStyle(color: color, fontWeight: FontWeight.bold),
                      ),
                      onTap: () {
                        import_transaction_sheet.TransactionBottomSheet.show(context, type: tx.type, transaction: tx);
                      },
                    ),
                  );
                },
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  String _formatMoney(double amount) {
    if (amount == 0) return '0';
    String formatted = amount.toStringAsFixed(0);
    return formatted.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }
}
