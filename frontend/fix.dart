import 'dart:io';

void main() {
  final filePaths = [
    'lib/features/categories/data/repositories/category_repository_impl.dart',
    'lib/features/transaction/domain/repositories/transaction_repository.dart',
    'lib/features/categories/presentation/pages/categories_page.dart',
    'lib/features/dashboard/presentation/pages/dashboard_page.dart',
    'lib/features/reports/presentation/pages/reports_page.dart'
  ];

  for (final path in filePaths) {
    final file = File(path);
    if (!file.existsSync()) continue;
    
    String content = file.readAsStringSync();
    
    // Replace fromJson -> fromMap and toJson -> toMap
    if (path.contains('repository')) {
      content = content.replaceAll('fromJson(', 'fromMap(');
      content = content.replaceAll('toJson()', 'toMap()');
    }
    
    // Fix String? to String using !
    if (path.contains('category_repository_impl.dart')) {
      content = content.replaceAll('localDataSource.deleteCategory(id)', 'localDataSource.deleteCategory(id!)');
    }
    if (path.contains('categories_page.dart')) {
      content = content.replaceAll('context.read<CategoryBloc>().add(DeleteCategory(category.id));', 'context.read<CategoryBloc>().add(DeleteCategory(category.id!));');
    }
    if (path.contains('dashboard_page.dart')) {
      content = content.replaceAll('context.read<TransactionBloc>().add(DeleteTransaction(tx.id));', 'context.read<TransactionBloc>().add(DeleteTransaction(tx.id!));');
    }
    if (path.contains('reports_page.dart')) {
      content = content.replaceAll('context.read<TransactionBloc>().add(DeleteTransaction(tx.id));', 'context.read<TransactionBloc>().add(DeleteTransaction(tx.id!));');
    }
    
    file.writeAsStringSync(content);
    print('Updated \$path');
  }
}
