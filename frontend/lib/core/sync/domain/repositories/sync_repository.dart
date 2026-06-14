abstract class ISyncRepository {
  Future<void> syncData();
  Future<void> pushData();
  Future<void> pullData();
}
