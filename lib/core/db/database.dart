import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../domain/elevation_rounding.dart';
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
  ],
)
class AppDatabase extends _$AppDatabase {
  // `super.executor` は、受け取った引数をそのまま親クラスのコンストラクタに渡す糖衣構文。
  AppDatabase(super.executor);

  /// 端末内の SQLite ファイルを開く。テストでは `AppDatabase(NativeDatabase.memory())` を使う。
  factory AppDatabase.open() => AppDatabase(driftDatabase(name: 'biolabelmap'));

  @override
  int get schemaVersion => 2;

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
    },
    beforeOpen: (details) async {
      // SQLite は既定で外部キーを検査しないため、接続ごとに有効にする。
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
