import 'package:drift/drift.dart';

import '../core/db/database.dart';
import '../domain/catalog_number.dart';

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
    final trimmed = prefix.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(prefix, 'prefix', '接頭辞を入力してください');
    }
    if (digits < 1 || digits > maxCatalogDigits) {
      throw ArgumentError.value(digits, 'digits', '1〜$maxCatalogDigitsを指定してください');
    }
    return _db.update(_db.appSettings).write(
      AppSettingsCompanion(
        catalogPrefix: Value(trimmed),
        catalogDigits: Value(digits),
      ),
    );
  }

  /// 新しい書式でこれから発行する番号が、既存の標本番号(ごみ箱の中も含む)と
  /// 同じ文字列になるかを調べる。なるときはその標本番号を、ならなければ null を返す。
  ///
  /// 例: `A1`+3桁で作った `A1005` は、`A`+4桁の 1005番と同じ文字列になる。
  /// そのまま発行すると、保存時に一意制約で失敗する。
  Future<String?> findFormatConflict({
    required String prefix,
    required int digits,
  }) async {
    final next = (await read()).nextCatalogNumber ?? 0;
    final format = CatalogNumberFormat(prefix: prefix.trim(), digits: digits);
    final texts = await (_db.selectOnly(_db.specimens)
          ..addColumns([_db.specimens.catalogText]))
        .map((row) => row.read(_db.specimens.catalogText)!)
        .get();
    for (final text in texts) {
      if (!text.startsWith(format.prefix)) continue;
      final number = int.tryParse(text.substring(format.prefix.length));
      if (number == null || number < next) continue;
      if (format.format(number) == text) return text;
    }
    return null;
  }

  /// バックアップを書き出した日時を記録する。
  Future<void> markBackedUp(DateTime at) => _db.update(_db.appSettings).write(
    AppSettingsCompanion(lastBackupAt: Value(at)),
  );
}

/// 標本番号の桁数の上限。
const maxCatalogDigits = 10;
