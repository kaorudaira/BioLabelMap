import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database.dart';

/// アプリ全体で1つの DB 接続を共有する。
///
/// Riverpod の Provider は、Spring のシングルトン Bean に近い。
/// 画面やサービスからは `ref.watch(databaseProvider)` で取り出す。
/// テストでは `ProviderContainer(overrides: [...])` でメモリ上の DB に差し替える。
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.open();
  ref.onDispose(db.close);
  return db;
});
