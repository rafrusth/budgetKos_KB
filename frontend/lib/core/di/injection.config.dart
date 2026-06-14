// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i1;
import 'package:injectable/injectable.dart' as _i2;

import '../../features/ai/data/datasources/ai_chat_local_ds.dart' as _i8;
import '../../features/auth/presentation/bloc/auth_bloc.dart' as _i9;
import '../../features/categories/data/datasources/category_local_ds.dart'
    as _i11;
import '../../features/categories/data/repositories/category_repository_impl.dart'
    as _i5;
import '../../features/categories/domain/repositories/category_repository.dart'
    as _i4;
import '../../features/categories/presentation/bloc/category_bloc.dart' as _i10;
import '../../features/transactions/data/datasources/transaction_local_ds.dart'
    as _i12;
import '../auth/auth_service.dart' as _i3;
import '../database/sqlite_helper.dart' as _i6;
import '../sync/sync_engine.dart' as _i7;

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
    gh.lazySingleton<_i3.AuthService>(() => _i3.AuthService());
    gh.lazySingleton<_i4.CategoryRepository>(
        () => _i5.CategoryRepositoryImpl());
    gh.lazySingleton<_i6.SqliteHelper>(() => _i6.SqliteHelper());
    gh.lazySingleton<_i7.SyncEngine>(
        () => _i7.SyncEngine(gh<_i6.SqliteHelper>()));
    gh.lazySingleton<_i8.AiChatLocalDataSource>(
        () => _i8.AiChatLocalDataSource(gh<_i6.SqliteHelper>()));
    gh.factory<_i9.AuthBloc>(() => _i9.AuthBloc(gh<_i3.AuthService>()));
    gh.factory<_i10.CategoryBloc>(
        () => _i10.CategoryBloc(gh<_i4.CategoryRepository>()));
    gh.lazySingleton<_i11.CategoryLocalDataSource>(
        () => _i11.CategoryLocalDataSourceImpl(gh<_i6.SqliteHelper>()));
    gh.lazySingleton<_i12.TransactionLocalDataSource>(
        () => _i12.TransactionLocalDataSourceImpl(
              gh<_i6.SqliteHelper>(),
              gh<_i11.CategoryLocalDataSource>(),
            ));
    return this;
  }
}
