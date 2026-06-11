import 'package:injectable/injectable.dart';
import 'package:budget_kos/core/database/sqlite_helper.dart';
import 'package:budget_kos/shared/models/category_model.dart';

abstract class CategoryLocalDataSource {
  Future<List<CategoryModel>> getCategories();
  Future<CategoryModel?> getCategoryById(int id);
  Future<int> insertCategory(CategoryModel category);
  Future<void> updateCategory(CategoryModel category);
  Future<void> deleteCategory(int id);
}

@LazySingleton(as: CategoryLocalDataSource)
class CategoryLocalDataSourceImpl implements CategoryLocalDataSource {
  final SqliteHelper sqliteHelper;

  CategoryLocalDataSourceImpl(this.sqliteHelper);

  @override
  Future<List<CategoryModel>> getCategories() async {
    final db = await sqliteHelper.database;
    final result = await db.query('categories', orderBy: 'sort_order ASC');
    return result.map((e) => CategoryModel.fromMap(e)).toList();
  }

  @override
  Future<CategoryModel?> getCategoryById(int id) async {
    final db = await sqliteHelper.database;
    final result = await db.query('categories', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) {
      return CategoryModel.fromMap(result.first);
    }
    return null;
  }

  @override
  Future<int> insertCategory(CategoryModel category) async {
    final db = await sqliteHelper.database;
    return await db.insert('categories', category.toMap());
  }

  @override
  Future<void> updateCategory(CategoryModel category) async {
    final db = await sqliteHelper.database;
    await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  @override
  Future<void> deleteCategory(int id) async {
    final db = await sqliteHelper.database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }
}
