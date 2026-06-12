// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i1;
import 'package:injectable/injectable.dart' as _i2;

import '../../features/ai/data/datasources/ai_chat_local_ds.dart' as _i6;
import '../../features/categories/data/datasources/category_local_ds.dart'
    as _i8;
import '../../features/categories/data/repositories/category_repository_impl.dart'
    as _i4;
import '../../features/categories/domain/repositories/category_repository.dart'
    as _i3;
import '../../features/categories/presentation/bloc/category_bloc.dart' as _i7;
import '../../features/transactions/data/datasources/transaction_local_ds.dart'
    as _i9;
import '../database/sqlite_helper.dart' as _i5;

extension GetItInjectableX on _i1.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  _i1.GetIt init({
    String? environment,
    _i2.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i2.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    gh.lazySingleton<_i3.CategoryRepository>(
        () => _i4.CategoryRepositoryImpl());
    gh.lazySingleton<_i5.SqliteHelper>(() => _i5.SqliteHelper());
    gh.lazySingleton<_i6.AiChatLocalDataSource>(
        () => _i6.AiChatLocalDataSource(gh<_i5.SqliteHelper>()));
    gh.factory<_i7.CategoryBloc>(
        () => _i7.CategoryBloc(gh<_i3.CategoryRepository>()));
    gh.lazySingleton<_i8.CategoryLocalDataSource>(
        () => _i8.CategoryLocalDataSourceImpl(gh<_i5.SqliteHelper>()));
    gh.lazySingleton<_i9.TransactionLocalDataSource>(
        () => _i9.TransactionLocalDataSourceImpl(
              gh<_i5.SqliteHelper>(),
              gh<_i8.CategoryLocalDataSource>(),
            ));
    return this;
  }
}
