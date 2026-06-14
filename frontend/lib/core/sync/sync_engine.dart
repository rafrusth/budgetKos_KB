import 'package:injectable/injectable.dart';
import 'domain/repositories/sync_repository.dart';

@lazySingleton
class SyncEngine {
  final ISyncRepository _repository;

  SyncEngine(this._repository);

  Future<void> syncData() async {
    await _repository.syncData();
  }

  Future<void> pushData() async {
    await _repository.pushData();
  }

  Future<void> pullData() async {
    await _repository.pullData();
  }
}
