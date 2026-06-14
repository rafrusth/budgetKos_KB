import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/cupertino.dart';
import '../../../../core/di/injection.dart';
import '../bloc/category_bloc.dart';
import '../bloc/category_event.dart';
import '../bloc/category_state.dart';
import 'category_form_page.dart';
import '../../../../core/utils/toast_helper.dart';
import '../../../transaction/presentation/bloc/transaction_bloc.dart';
import '../../../transaction/presentation/bloc/transaction_event.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<CategoryBloc>()..add(FetchCategories()),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text('Profil', style: TextStyle(color: Colors.grey, fontSize: 16)),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
              const Text('Kelola Kategori', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleSpacing: 0,
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
                              onPressed: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => BlocProvider.value(
                                      value: context.read<CategoryBloc>(),
                                      child: CategoryFormPage(category: category),
                                    ),
                                  ),
                                );
                                if (context.mounted) {
                                  context.read<CategoryBloc>().add(FetchCategories());
                                  context.read<TransactionBloc>().add(FetchTransactions());
                                }
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
                                          context.read<CategoryBloc>().add(DeleteCategory(category.id!));
                                          context.read<TransactionBloc>().add(FetchTransactions());
                                          Navigator.pop(ctx);
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
          builder: (context) {
            final isDesktop = MediaQuery.of(context).size.width > 800;
            return Padding(
              padding: EdgeInsets.only(bottom: isDesktop ? 0 : 100.0),
              child: FloatingActionButton(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: context.read<CategoryBloc>(),
                        child: const CategoryFormPage(),
                      ),
                    ),
                  );
                  if (context.mounted) {
                    context.read<CategoryBloc>().add(FetchCategories());
                    context.read<TransactionBloc>().add(FetchTransactions());
                  }
                },
                child: const Icon(Icons.add),
              ),
            );
          }
        ),
      ),
    );
  }
}
