import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../domain/elevation_rounding.dart';
import '../../domain/dictionary.dart';
import '../../domain/sampling_method.dart';
import '../../domain/status.dart';
import '../../domain/models/calendar_date.dart';
import 'converters.dart';
import 'tables.dart';

// `part` で、生成されたコード(database.g.dart)をこのファイルの一部として取り込む。
// 生成は `dart run build_runner build` で行う。Java のアノテーションプロセッサに近い。
part 'database.g.dart';

@DriftDatabase(
  tables: [
    Localities,
    CollectionEvents,
    Specimens,
    Identifications,
    EnrichmentQueue,
    Drafts,
    AppSettings,
    PlaceRomajiDict,
    OfflineAreas,
    SpeciesDict,
    TextDict,
  ],
)
class AppDatabase extends _$AppDatabase {
  // `super.executor` は、受け取った引数をそのまま親クラスのコンストラクタに渡す糖衣構文。
  AppDatabase(super.executor);

  /// 端末内の SQLite ファイルを開く。テストでは `AppDatabase(NativeDatabase.memory())` を使う。
  factory AppDatabase.open() => AppDatabase(driftDatabase(name: 'biolabelmap'));

  /// [tables] のどれかが変わるたびに流れる合図。
  ///
  /// drift は、同じ SQL の監視を1つの流れに共有する(読むテーブルが違っても、SQL が同じなら同じ流れ)。
  /// そのため SQL は、読むテーブルの組ごとに別の文字列にする。
  /// 共通の `SELECT 1` にすると、先に作られた流れの組が使われ、他の画面の変更が届かなくなる。
  Stream<void> changesOf(Set<TableInfo> tables) {
    final names = [for (final t in tables) t.actualTableName]..sort();
    return customSelect("SELECT '${names.join(',')}'", readsFrom: tables).watch();
  }

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      // 設定は常に1行ある状態にする。
      await into(appSettings).insert(AppSettingsCompanion.insert());
    },
    onUpgrade: (m, from, to) async {
      // 1 → 2: 最後にバックアップした日時
      if (from < 2) {
        await m.addColumn(appSettings, appSettings.lastBackupAt);
      }
      // 2 → 3: オフライン地図
      if (from < 3) {
        await m.createTable(offlineAreas);
      }
      // 3 → 4: 種の辞書、環境・寄主植物の辞書
      if (from < 4) {
        await m.createTable(speciesDict);
        await m.createTable(textDict);
      }
    },
    beforeOpen: (details) async {
      // SQLite は既定で外部キーを検査しないため、接続ごとに有効にする。
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
