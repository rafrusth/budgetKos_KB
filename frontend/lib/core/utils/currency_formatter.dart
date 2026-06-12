import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final int selectionIndexFromTheRight =
        newValue.text.length - newValue.selection.end;
    
    // Allow only digits
    final String cleanText = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanText.isEmpty) return newValue.copyWith(text: '');

    final NumberFormat formatter = NumberFormat.decimalPattern('id');
    final String newText = formatter.format(int.parse(cleanText));

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: newText.length - selectionIndexFromTheRight,
      ),
    );
  }
}
