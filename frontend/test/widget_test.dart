import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App architecture dummy test', (WidgetTester tester) async {
    // Tes default Flutter (counter app) sudah dihapus karena kita
    // menggunakan struktur Clean Architecture dan BudgetKosApp.
    // Jika ingin melakukan testing UI, setup Dependency Injection 
    // perlu dilakukan di sini terlebih dahulu.
    expect(true, isTrue);
  });
}
