// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i1;
import 'package:injectable/injectable.dart' as _i2;

import '../../features/ai/data/datasources/ai_chat_local_ds.dart' as _i4;
import '../../features/categories/data/datasources/category_local_ds.dart'
    as _i5;
import '../../features/transactions/data/datasources/transaction_local_ds.dart'
    as _i6;
import '../database/sqlite_helper.dart' as _i3;

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
    gh.lazySingleton<_i3.SqliteHelper>(() => _i3.SqliteHelper());
    gh.lazySingleton<_i4.AiChatLocalDataSource>(
        () => _i4.AiChatLocalDataSource(gh<_i3.SqliteHelper>()));
    gh.lazySingleton<_i5.CategoryLocalDataSource>(
        () => _i5.CategoryLocalDataSourceImpl(gh<_i3.SqliteHelper>()));
    gh.lazySingleton<_i6.TransactionLocalDataSource>(
        () => _i6.TransactionLocalDataSourceImpl(
              gh<_i3.SqliteHelper>(),
              gh<_i5.CategoryLocalDataSource>(),
            ));
    return this;
  }
}
