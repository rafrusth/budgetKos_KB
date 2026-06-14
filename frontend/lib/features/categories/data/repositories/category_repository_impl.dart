import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/sqlite_helper.dart';
import '../../../../core/di/injection.dart';
import 'package:budget_kos/shared/models/category_model.dart';
import '../../domain/repositories/category_repository.dart';

@LazySingleton(as: CategoryRepository)
class CategoryRepositoryImpl implements CategoryRepository {
  final SqliteHelper _sqliteHelper = getIt<SqliteHelper>();
  final Uuid _uuid = const Uuid();

  @override
  Future<List<CategoryModel>> getCategories() async {
    final db = await _sqliteHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('categories', where: 'is_deleted = 0');
    return maps.map((map) {
      final jsonMap = Map<String, dynamic>.from(map);
      jsonMap['is_default'] = map['is_default'] == 1;
      return CategoryModel.fromMap(jsonMap);
    }).toList();
  }

  @override
  Future<CategoryModel> getCategory(String id) async {
    final db = await _sqliteHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      final jsonMap = Map<String, dynamic>.from(maps.first);
      jsonMap['is_default'] = maps.first['is_default'] == 1;
      return CategoryModel.fromMap(jsonMap);
    }
    throw Exception('Category not found');
  }

  @override
  Future<CategoryModel> createCategory(CategoryModel category) async {
    final db = await _sqliteHelper.database;
    final Map<String, dynamic> data = category.toMap();
    final newId = _uuid.v4();
    data['id'] = newId;
    data['is_default'] = category.isDefault ? 1 : 0;
    data['sort_order'] = 0; // Default sort order
    
    final now = DateTime.now().toIso8601String();
    data['created_at'] = now;
    data['updated_at'] = now;
    data['sync_status'] = 1; // pending_insert
    data['is_deleted'] = 0;

    await db.insert('categories', data);
    return getCategory(newId);
  }

  @override
  Future<CategoryModel> updateCategory(CategoryModel category) async {
    final db = await _sqliteHelper.database;
    final Map<String, dynamic> data = category.toMap();
    data['is_default'] = category.isDefault ? 1 : 0;
    data['sort_order'] = 0;
    
    final now = DateTime.now().toIso8601String();
    data['updated_at'] = now;
    data['sync_status'] = 2; // pending_update

    await db.update(
      'categories',
      data,
      where: 'id = ?',
      whereArgs: [category.id],
    );
    return getCategory(category.id!);
  }

  @override
  Future<void> deleteCategory(String id) async {
    final db = await _sqliteHelper.database;
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
