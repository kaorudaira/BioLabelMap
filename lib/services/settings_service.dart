import 'package:drift/drift.dart';

import '../core/db/database.dart';

/// 標本番号の初回設定が済んでいない(要件定義 第14章)。
class CatalogNotInitializedException implements Exception {
  @override
  String toString() => '標本番号の開始値が設定されていません';
}

/// 設定の読み書き(段階1は採集者名と標本番号のみ)。
class SettingsService {
  SettingsService(this._db);

  final AppDatabase _db;

  Future<AppSettingsRow> read() => _db.select(_db.appSettings).getSingle();

  Stream<AppSettingsRow> watch() => _db.select(_db.appSettings).watchSingle();

  /// 初回設定。これまでの最新番号を受け取り、次の番号をその+1にする。
  /// 標本が無ければ 0。2回目以降は変更できない。
  Future<void> initializeCatalog(int lastNumber) async {
    if (lastNumber < 0) {
      throw ArgumentError.value(lastNumber, 'lastNumber', '0以上を指定してください');
    }
    final updated =
        await (_db.update(_db.appSettings)
              ..where((s) => s.nextCatalogNumber.isNull()))
            .write(AppSettingsCompanion(nextCatalogNumber: Value(lastNumber + 1)));
    if (updated == 0) {
      throw StateError('標本番号の開始値はすでに設定されています');
    }
  }

  Future<void> setCollectorName(String? name) {
    final trimmed = name?.trim();
    return _db.update(_db.appSettings).write(
      AppSettingsCompanion(
        collectorName: Value(trimmed == null || trimmed.isEmpty ? null : trimmed),
      ),
    );
  }

  /// 接頭辞と桁数。番号を使い始めた後も変えられ、既存の標本番号は変わらない。
  Future<void> setCatalogFormat({required String prefix, required int digits}) {
    if (digits < 1) {
      throw ArgumentError.value(digits, 'digits', '1以上を指定してください');
    }
    return _db.update(_db.appSettings).write(
      AppSettingsCompanion(
        catalogPrefix: Value(prefix.trim()),
        catalogDigits: Value(digits),
      ),
    );
  }
}
