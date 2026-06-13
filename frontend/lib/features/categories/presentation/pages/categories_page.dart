import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/cupertino.dart';
import '../../../../core/di/injection.dart';
import '../bloc/category_bloc.dart';
import '../bloc/category_event.dart';
import '../bloc/category_state.dart';
import 'category_form_page.dart';
import '../../../../core/utils/toast_helper.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<CategoryBloc>()..add(FetchCategories()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kelola Kategori', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: BlocBuilder<CategoryBloc, CategoryState>(
          builder: (context, state) {
            if (state is CategoryLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is CategoryError) {
              return Center(child: Text('Error: ${state.message}'));
            } else if (state is CategoryLoaded) {
              if (state.categories.isEmpty) {
                return const Center(child: Text('Belum ada kategori.'));
              }
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<CategoryBloc>().add(FetchCategories());
                },
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: state.categories.length,
                  itemBuilder: (context, index) {
                    final category = state.categories[index];
                    // Convert hex color to Color
                    Color categoryColor = Colors.grey;
                    try {
                      categoryColor = Color(int.parse(category.color.replaceAll('#', '0xff')));
                    } catch (e) {
                      // Ignore
                    }
                    
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: categoryColor.withValues(alpha: 0.2),
                          child: Icon(Icons.category, color: categoryColor), // Fallback icon
                        ),
                        title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(category.type == 'income' ? 'Pemasukan' : 'Pengeluaran'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(CupertinoIcons.pencil, color: Colors.blue),
                              onPressed: () {
                                Navigator.of(context, rootNavigator: true).push(
                                  MaterialPageRoute(
                                    builder: (_) => BlocProvider.value(
                                      value: context.read<CategoryBloc>(),
                                      child: CategoryFormPage(category: category),
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(CupertinoIcons.trash, color: Colors.red),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Hapus Kategori?'),
                                    content: Text('Anda yakin ingin menghapus kategori "${category.name}"?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(ctx);
                                          context.read<CategoryBloc>().add(DeleteCategory(category.id));
                                          ToastHelper.showSuccess(context, 'Kategori dihapus');
                                        },
                                        child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            }
            return const SizedBox();
          },
        ),
        floatingActionButton: Builder(
          builder: (context) => FloatingActionButton(
            onPressed: () {
              Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: context.read<CategoryBloc>(),
                    child: const CategoryFormPage(),
                  ),
                ),
              );
            },
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }
}
