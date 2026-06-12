import 'package:injectable/injectable.dart';
import '../../../../core/database/sqlite_helper.dart';
import '../../../../core/di/injection.dart';
import '../../../transaction/data/models/category_model.dart';
import '../../domain/repositories/category_repository.dart';

@LazySingleton(as: CategoryRepository)
class CategoryRepositoryImpl implements CategoryRepository {
  final SqliteHelper _sqliteHelper = getIt<SqliteHelper>();

  @override
  Future<List<CategoryModel>> getCategories() async {
    final db = await _sqliteHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('categories');
    return maps.map((map) {
      final jsonMap = Map<String, dynamic>.from(map);
      jsonMap['is_default'] = map['is_default'] == 1;
      return CategoryModel.fromJson(jsonMap);
    }).toList();
  }

  @override
  Future<CategoryModel> getCategory(int id) async {
    final db = await _sqliteHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      final jsonMap = Map<String, dynamic>.from(maps.first);
      jsonMap['is_default'] = maps.first['is_default'] == 1;
      return CategoryModel.fromJson(jsonMap);
    }
    throw Exception('Category not found');
  }

  @override
  Future<CategoryModel> createCategory(CategoryModel category) async {
    final db = await _sqliteHelper.database;
    final Map<String, dynamic> data = category.toJson();
    data.remove('id'); // Remove id since it's AUTOINCREMENT
    data['is_default'] = category.isDefault ? 1 : 0;
    data['sort_order'] = 0; // Default sort order

    final id = await db.insert('categories', data);
    return getCategory(id);
  }

  @override
  Future<CategoryModel> updateCategory(CategoryModel category) async {
    final db = await _sqliteHelper.database;
    final Map<String, dynamic> data = category.toJson();
    data['is_default'] = category.isDefault ? 1 : 0;
    data['sort_order'] = 0;

    await db.update(
      'categories',
      data,
      where: 'id = ?',
      whereArgs: [category.id],
    );
    return getCategory(category.id);
  }

  @override
  Future<void> deleteCategory(int id) async {
    final db = await _sqliteHelper.database;
    await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
