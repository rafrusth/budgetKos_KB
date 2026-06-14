import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/transaction_bloc.dart';
import '../bloc/transaction_event.dart';
import '../bloc/transaction_state.dart';
import 'package:budget_kos/shared/models/transaction_model.dart';
import '../../../../core/utils/toast_helper.dart';
import '../../../../core/utils/popup_helper.dart';

class TransactionBottomSheet extends StatefulWidget {
  final String initialType; // 'income' or 'expense'
  final TransactionModel? initialTransaction;

  const TransactionBottomSheet({super.key, required this.initialType, this.initialTransaction});

  static void show(BuildContext context, {String type = 'expense', TransactionModel? transaction}) {
    PopupHelper.showAdaptivePopup(
      context: context,
      isScrollControlled: true,
      builder: (context) => AnimatedPadding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        child: TransactionBottomSheet(initialType: type, initialTransaction: transaction),
      ),
    );
  }

  @override
  State<TransactionBottomSheet> createState() => _TransactionBottomSheetState();
}

class _TransactionBottomSheetState extends State<TransactionBottomSheet> {
  late String _selectedType;
  String? _selectedCategoryId;
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
    FocusManager.instance.primaryFocus?.unfocus();
    _amountController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_amountController.text.isEmpty || _selectedCategoryId == null) {
      ToastHelper.showError(context, 'Nominal dan Kategori harus diisi');
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
          createdAt: widget.initialTransaction!.createdAt,
          updatedAt: DateTime.now(),
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
    ToastHelper.showSuccess(context, widget.initialTransaction != null ? 'Berhasil mengubah transaksi' : 'Berhasil memasukkan transaksi');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget content = Container(
      padding: const EdgeInsets.all(24),
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
          if (widget.initialTransaction != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text("Edit Transaksi", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ),
          Row(
            children: [
              Expanded(child: _typeButton(theme, 'Pengeluaran', 'expense', isDark)),
              const SizedBox(width: 16),
              Expanded(child: _typeButton(theme, 'Pemasukan', 'income', isDark)),
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
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tanggal', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              TextButton.icon(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    setState(() {
                      _selectedDate = date;
                    });
                  }
                },
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}', style: const TextStyle(fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                  foregroundColor: theme.colorScheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
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
                        selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                        backgroundColor: theme.cardColor,
                        labelStyle: TextStyle(
                          color: isSelected ? theme.colorScheme.primary : theme.textTheme.bodyMedium?.color,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      );
                    }),
                    ActionChip(
                      label: Text('+ Kategori Baru', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
                      onPressed: () => _showAddCategoryDialog(context, theme),
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

    if (isDark) {
      content = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
        child: content,
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: content,
    );
  }

  Widget _typeButton(ThemeData theme, String label, String type, bool isDark) {
    final isSelected = _selectedType == type;
    final color = type == 'income' ? theme.colorScheme.primary : theme.colorScheme.secondary;

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
          color: isSelected ? color.withValues(alpha: 0.1) : (isDark ? Colors.grey[800] : Colors.grey[100]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : (isDark ? Colors.white70 : Colors.black54),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context, ThemeData theme) {
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
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
              child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold)),
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
