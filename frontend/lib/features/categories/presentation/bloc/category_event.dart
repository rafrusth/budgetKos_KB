import '../../../transaction/data/models/category_model.dart';

abstract class CategoryEvent {}

class FetchCategories extends CategoryEvent {}

class AddCategory extends CategoryEvent {
  final CategoryModel category;
  AddCategory(this.category);
}

class UpdateCategory extends CategoryEvent {
  final CategoryModel category;
  UpdateCategory(this.category);
}

class DeleteCategory extends CategoryEvent {
  final int id;
  DeleteCategory(this.id);
}
