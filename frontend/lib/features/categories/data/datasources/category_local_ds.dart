import 'package:injectable/injectable.dart';
import 'package:budget_kos/core/database/sqlite_helper.dart';
import 'package:budget_kos/shared/models/category_model.dart';
import 'package:uuid/uuid.dart';

abstract class CategoryLocalDataSource {
  Future<List<CategoryModel>> getCategories();
  Future<CategoryModel?> getCategoryById(String id);
  Future<String> insertCategory(CategoryModel category);
  Future<void> updateCategory(CategoryModel category);
  Future<void> deleteCategory(String id);
}

@LazySingleton(as: CategoryLocalDataSource)
class CategoryLocalDataSourceImpl implements CategoryLocalDataSource {
  final SqliteHelper sqliteHelper;
  final Uuid _uuid = const Uuid();

  CategoryLocalDataSourceImpl(this.sqliteHelper);

  @override
  Future<List<CategoryModel>> getCategories() async {
    final db = await sqliteHelper.database;
    final result = await db.query('categories', where: 'is_deleted = 0', orderBy: 'sort_order ASC');
    return result.map((e) => CategoryModel.fromMap(e)).toList();
  }

  @override
  Future<CategoryModel?> getCategoryById(String id) async {
    final db = await sqliteHelper.database;
    final result = await db.query('categories', where: 'id = ? AND is_deleted = 0', whereArgs: [id]);
    if (result.isNotEmpty) {
      return CategoryModel.fromMap(result.first);
    }
    return null;
  }

  @override
  Future<String> insertCategory(CategoryModel category) async {
    final db = await sqliteHelper.database;
    final id = category.id ?? _uuid.v4();
    final now = DateTime.now().toIso8601String();

    final data = category.toMap();
    data['id'] = id;
    data['created_at'] = now;
    data['updated_at'] = now;
    data['sync_status'] = 1; // pending_insert
    data['is_deleted'] = 0;

    await db.insert('categories', data);
    return id;
  }

  @override
  Future<void> updateCategory(CategoryModel category) async {
    final db = await sqliteHelper.database;
    final data = category.toMap();
    final now = DateTime.now().toIso8601String();
    
    data['updated_at'] = now;
    data['sync_status'] = 2; // pending_update

    await db.update(
      'categories',
      data,
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  @override
  Future<void> deleteCategory(String id) async {
    final db = await sqliteHelper.database;
    final now = DateTime.now().toIso8601String();
    
    await db.update(
      'categories',
      {
        'is_deleted': 1,
        'sync_status': 3, // pending_delete
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
