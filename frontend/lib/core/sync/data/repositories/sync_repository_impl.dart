import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import '../../domain/repositories/sync_repository.dart';
import '../../data/datasources/sync_local_data_source.dart';
import '../../data/datasources/sync_remote_data_source.dart';

@LazySingleton(as: ISyncRepository)
class SyncRepositoryImpl implements ISyncRepository {
  final ISyncLocalDataSource _localDataSource;
  final ISyncRemoteDataSource _remoteDataSource;

  SyncRepositoryImpl(this._localDataSource, this._remoteDataSource);

  @override
  Future<void> syncData() async {
    try {
      debugPrint('SyncRepository: Starting sync...');
      await pushData();
      await pullData();
      debugPrint('SyncRepository: Sync completed successfully.');
    } catch (e) {
      debugPrint('SyncRepository: Sync failed: $e');
      rethrow;
    }
  }

  @override
  Future<void> pushData() async {
    final pendingData = await _localDataSource.getPendingData();
    
    final pushTxsRaw = pendingData['pushTxsRaw'] as List<Map<String, dynamic>>;
    final pushCatsRaw = pendingData['pushCatsRaw'] as List<Map<String, dynamic>>;
    final deletedTxIds = pendingData['deleted_transaction_ids'] as List<String>;
    final deletedCatIds = pendingData['deleted_category_ids'] as List<String>;

    if (pushTxsRaw.isEmpty && deletedTxIds.isEmpty && pushCatsRaw.isEmpty && deletedCatIds.isEmpty) {
      debugPrint('SyncRepository: Nothing to push.');
      return;
    }

    final payload = {
      'transactions': pendingData['transactions'],
      'categories': pendingData['categories'],
      'deleted_transaction_ids': deletedTxIds,
      'deleted_category_ids': deletedCatIds,
    };

    await _remoteDataSource.pushData(payload);
    
    debugPrint('SyncRepository: Push successful. Updating local status.');
    await _localDataSource.updateSyncStatusAfterPush(pushTxsRaw, deletedTxIds, pushCatsRaw, deletedCatIds);
  }

  @override
  Future<void> pullData() async {
    final since = await _localDataSource.getLastPullTimestamp();
    final pullStartTime = DateTime.now().toIso8601String();
    
    final data = await _remoteDataSource.pullData(since);
    
    if (data.isEmpty) {
      debugPrint('SyncRepository: Pull returned no data.');
      return;
    }

    final serverTxs = data['transactions'] as List<dynamic>? ?? [];
    final serverCats = data['categories'] as List<dynamic>? ?? [];

    await _localDataSource.upsertPulledData(serverTxs, serverCats);
    await _localDataSource.updateLastPullTimestamp(pullStartTime);
    
    debugPrint('SyncRepository: Pull successful.');
  }
}
