class AppFormatters {
  static String formatMoney(double amount) {
    String res = amount.toInt().toString();
    if (res.length > 3) {
      res = res.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
    }
    return res;
  }
}
