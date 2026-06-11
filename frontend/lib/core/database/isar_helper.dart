import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class IsarHelper {
  static Isar? _isar;

  Future<Isar> get database async {
    if (_isar != null) return _isar!;
    _isar = await _initIsar();
    return _isar!;
  }

  Future<Isar> _initIsar() async {
    final dir = await getApplicationDocumentsDirectory();
    return await Isar.open(
      [], // schemas here later
      directory: dir.path,
    );
  }
}
