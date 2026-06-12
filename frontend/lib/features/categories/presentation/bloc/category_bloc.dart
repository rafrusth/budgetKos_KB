import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../domain/repositories/category_repository.dart';
import 'category_event.dart';
import 'category_state.dart';

@injectable
class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final CategoryRepository repository;

  CategoryBloc(this.repository) : super(CategoryInitial()) {
    on<FetchCategories>(_onFetchCategories);
    on<AddCategory>(_onAddCategory);
    on<UpdateCategory>(_onUpdateCategory);
    on<DeleteCategory>(_onDeleteCategory);
  }

  Future<void> _onFetchCategories(FetchCategories event, Emitter<CategoryState> emit) async {
    emit(CategoryLoading());
    try {
      final categories = await repository.getCategories();
      emit(CategoryLoaded(categories));
    } catch (e) {
      emit(CategoryError(e.toString()));
    }
  }

  Future<void> _onAddCategory(AddCategory event, Emitter<CategoryState> emit) async {
    if (state is CategoryLoaded) {
      final currentState = state as CategoryLoaded;
      try {
        final newCategory = await repository.createCategory(event.category);
        final updatedList = List.of(currentState.categories)..add(newCategory);
        emit(CategoryLoaded(updatedList));
      } catch (e) {
        emit(CategoryError(e.toString()));
        emit(currentState);
      }
    }
  }

  Future<void> _onUpdateCategory(UpdateCategory event, Emitter<CategoryState> emit) async {
    if (state is CategoryLoaded) {
      final currentState = state as CategoryLoaded;
      try {
        final updatedCategory = await repository.updateCategory(event.category);
        final updatedList = currentState.categories.map((c) => c.id == updatedCategory.id ? updatedCategory : c).toList();
        emit(CategoryLoaded(updatedList));
      } catch (e) {
        emit(CategoryError(e.toString()));
        emit(currentState);
      }
    }
  }

  Future<void> _onDeleteCategory(DeleteCategory event, Emitter<CategoryState> emit) async {
    if (state is CategoryLoaded) {
      final currentState = state as CategoryLoaded;
      try {
        await repository.deleteCategory(event.id);
        final updatedList = currentState.categories.where((c) => c.id != event.id).toList();
        emit(CategoryLoaded(updatedList));
      } catch (e) {
        emit(CategoryError(e.toString()));
        emit(currentState);
      }
    }
  }
}
