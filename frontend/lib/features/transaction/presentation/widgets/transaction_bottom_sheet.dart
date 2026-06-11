import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/transaction_bloc.dart';
import '../bloc/transaction_event.dart';
import '../bloc/transaction_state.dart';
import '../../data/models/transaction_model.dart';

class TransactionBottomSheet extends StatefulWidget {
  final String initialType; // 'income' or 'expense'
  final TransactionModel? initialTransaction;

  const TransactionBottomSheet({super.key, required this.initialType, this.initialTransaction});

  static void show(BuildContext context, {String type = 'expense', TransactionModel? transaction}) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: TransactionBottomSheet(initialType: type, initialTransaction: transaction),
      ),
    );
  }

  @override
  State<TransactionBottomSheet> createState() => _TransactionBottomSheetState();
}

class _TransactionBottomSheetState extends State<TransactionBottomSheet> {
  late String _selectedType;
  int? _selectedCategoryId;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.initialTransaction != null) {
      final tx = widget.initialTransaction!;
      _selectedType = tx.type;
      _selectedCategoryId = tx.categoryId;
      _amountController.text = _formatMoney(tx.amount);
      _titleController.text = tx.title;
      _selectedDate = tx.date;
    } else {
      _selectedType = widget.initialType;
    }
  }

  String _formatMoney(double amount) {
    if (amount == 0) return '0';
    String formatted = amount.toStringAsFixed(0);
    return formatted.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_amountController.text.isEmpty || _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal dan Kategori harus diisi')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.replaceAll('.', '').replaceAll(',', '')) ?? 0;
    
    String title = _titleController.text.trim();
    if (title.isEmpty) {
      final state = context.read<TransactionBloc>().state;
      if (state is TransactionLoaded) {
        try {
          final cat = state.categories.firstWhere((c) => c.id == _selectedCategoryId);
          title = cat.name;
        } catch (_) {
          title = _selectedType == 'income' ? 'Pemasukan' : 'Pengeluaran';
        }
      } else {
        title = _selectedType == 'income' ? 'Pemasukan' : 'Pengeluaran';
      }
    }
    
    if (widget.initialTransaction != null) {
      context.read<TransactionBloc>().add(UpdateTransaction(
        TransactionModel(
          id: widget.initialTransaction!.id,
          title: title,
          amount: amount,
          type: _selectedType,
          categoryId: _selectedCategoryId!,
          date: _selectedDate,
          notes: widget.initialTransaction!.notes,
        )
      ));
    } else {
      context.read<TransactionBloc>().add(AddTransaction(
        title: title,
        amount: amount,
        type: _selectedType,
        categoryId: _selectedCategoryId!,
        date: _selectedDate,
      ));
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
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
          if (widget.initialTransaction != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text("Edit Transaksi", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ),
          Row(
            children: [
              Expanded(
                child: _typeButton('Pengeluaran', 'expense', isDark),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _typeButton('Pemasukan', 'income', isDark),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('Rp ', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey)),
              Expanded(
                child: TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _CurrencyInputFormatter(),
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
          const Divider(),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              hintText: 'Keterangan (mis: Makan Siang)',
              filled: true,
              fillColor: theme.cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Kategori', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          BlocBuilder<TransactionBloc, TransactionState>(
            builder: (context, state) {
              if (state is TransactionLoaded) {
                final categories = state.categories.where((c) => c.type == _selectedType).toList();
                if (categories.isEmpty) return const Text("Tidak ada kategori");
                
                if (_selectedCategoryId == null && categories.isNotEmpty) {
                  _selectedCategoryId = categories.first.id;
                }
                
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...categories.map((cat) {
                      final isSelected = cat.id == _selectedCategoryId;
                      return ChoiceChip(
                        label: Text(cat.name),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) setState(() => _selectedCategoryId = cat.id);
                        },
                        selectedColor: theme.colorScheme.primary.withOpacity(0.2),
                        backgroundColor: theme.cardColor,
                        labelStyle: TextStyle(
                          color: isSelected ? theme.colorScheme.primary : theme.textTheme.bodyMedium?.color,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      );
                    }),
                    ActionChip(
                      label: const Text('+ Kategori Baru', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
                      onPressed: () => _showAddCategoryDialog(context),
                    ),
                  ],
                );
              }
              return const CircularProgressIndicator();
            },
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text('Simpan Transaksi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _typeButton(String title, String type, bool isDark) {
    final isSelected = _selectedType == type;
    final color = type == 'income' ? Colors.green : Colors.orange;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedType = type;
          _selectedCategoryId = null; // Reset category when switching
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : (isDark ? Colors.grey[800] : Colors.grey[100]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? color : (isDark ? Colors.white70 : Colors.black54),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final TextEditingController newCatController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Kategori Baru', style: TextStyle(fontWeight: FontWeight.bold)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: TextField(
            controller: newCatController,
            decoration: InputDecoration(
              hintText: 'Misal: Asuransi',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext), 
              child: const Text('Batal', style: TextStyle(color: Colors.grey))
            ),
            ElevatedButton(
              onPressed: () {
                if (newCatController.text.trim().isNotEmpty) {
                  context.read<TransactionBloc>().add(AddCategory(newCatController.text.trim(), _selectedType));
                }
                Navigator.pop(dialogContext);
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: Colors.blue,
              ),
              child: const Text('Simpan', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}

class _CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    String cleanText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanText.isEmpty) return newValue.copyWith(text: '');

    String formatted = cleanText;
    if (formatted.length > 3) {
      formatted = formatted.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
