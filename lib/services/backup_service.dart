import 'dart:convert';

import 'package:drift/drift.dart';

import '../core/db/database.dart';

/// バックアップのファイル形式の名前。復元時に、別のファイルを読み込んでいないかを確かめる。
const backupFormatName = 'biolabelmap-backup';

/// バックアップの中身の概要。復元前の確認画面(段階4)とバックアップ画面に出す。
class BackupSummary {
  const BackupSummary({
    required this.specimenCount,
    this.firstDate,
    this.lastDate,
  });

  /// 標本の件数(ごみ箱の中は除く)。
  final int specimenCount;

  /// 採集日の範囲(`2026-06-19` 形式)。標本が無ければ null。
  final String? firstDate;
  final String? lastDate;

  Map<String, Object?> toJson() => {
    'specimenCount': specimenCount,
    'firstDate': firstDate,
    'lastDate': lastDate,
  };

  factory BackupSummary.fromJson(Map<String, Object?> json) => BackupSummary(
    specimenCount: json['specimenCount']! as int,
    firstDate: json['firstDate'] as String?,
    lastDate: json['lastDate'] as String?,
  );
}

/// 書き出したバックアップ。
class BackupFile {
  const BackupFile({
    required this.fileName,
    required this.bytes,
    required this.summary,
  });

  /// 例: `konchu-backup-20261004.json`
  final String fileName;
  final Uint8List bytes;
  final BackupSummary summary;
}

/// 読み込めないバックアップファイル。
class InvalidBackupException implements Exception {
  InvalidBackupException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// 全データを1つのファイルに書き出す(要件定義 F-17・S-09)。
///
/// 各テーブルの行を、SQLite に入っている値のまま JSON にする。
/// 列を1つずつ変換しないので、列を足しても書き出しの漏れが起きない。
/// 段階1では写真が無いため、ファイルは JSON 1つだけ。
class BackupService {
  BackupService(this._db);

  final AppDatabase _db;

  /// 標本の件数と採集日の範囲。
  Future<BackupSummary> summarize() async {
    final row = await _db.customSelect(
      'SELECT COUNT(*) AS n, MIN(e.start_date) AS first, MAX(e.end_date) AS last '
      'FROM specimens s JOIN collection_events e ON e.id = s.collection_event_id '
      'WHERE s.deleted_at IS NULL',
      readsFrom: {_db.specimens, _db.collectionEvents},
    ).getSingle();
    return BackupSummary(
      specimenCount: row.read<int>('n'),
      firstDate: row.read<String?>('first'),
      lastDate: row.read<String?>('last'),
    );
  }

  /// 全テーブルを書き出す。1つのトランザクションで読むので、途中で記録が増えても食い違わない。
  Future<BackupFile> export({DateTime? now}) async {
    final at = now ?? DateTime.now();
    return _db.transaction(() async {
      final tables = <String, List<Map<String, Object?>>>{};
      for (final table in _db.allTables) {
        final rows = await _db
            .customSelect(
              'SELECT * FROM "${table.actualTableName}" ORDER BY rowid',
              readsFrom: {table},
            )
            .get();
        tables[table.actualTableName] = [for (final r in rows) r.data];
      }
      final summary = await summarize();
      final json = {
        'format': backupFormatName,
        'schemaVersion': _db.schemaVersion,
        'exportedAt': at.toUtc().toIso8601String(),
        'summary': summary.toJson(),
        'tables': tables,
      };
      return BackupFile(
        fileName: 'konchu-backup-${_yyyymmdd(at)}.json',
        bytes: Uint8List.fromList(
          utf8.encode(const JsonEncoder.withIndent(' ').convert(json)),
        ),
        summary: summary,
      );
    });
  }

  /// ファイルの中身を確かめ、概要を返す(復元前の確認用)。
  BackupSummary inspect(Uint8List bytes) =>
      BackupSummary.fromJson(_decode(bytes)['summary']! as Map<String, Object?>);

  /// 現在のデータをすべて消し、バックアップの内容に置き換える。
  ///
  /// 復元の画面は段階4(S-09)で作る。ここでは、書き出したファイルで
  /// 元に戻せることをテストで確かめるために置いておく。
  Future<void> restore(Uint8List bytes) async {
    final json = _decode(bytes);
    final tables = json['tables']! as Map<String, Object?>;
    final known = {for (final t in _db.allTables) t.actualTableName: t};
    for (final name in tables.keys) {
      if (!known.containsKey(name)) {
        throw InvalidBackupException('知らないテーブルがあります: $name');
      }
    }

    await _db.transaction(() async {
      // 外部キーの向きに合わせて、子から消して親から入れる
      for (final table in _db.allTables.toList().reversed) {
        await _db.customStatement('DELETE FROM "${table.actualTableName}"');
      }
      for (final table in _db.allTables) {
        final columns = {for (final c in table.$columns) c.name};
        final rows = (tables[table.actualTableName] as List<Object?>?) ?? [];
        for (final row in rows.cast<Map<String, Object?>>()) {
          final names = row.keys.where(columns.contains).toList();
          await _db.customInsert(
            'INSERT INTO "${table.actualTableName}" '
            '(${names.map((n) => '"$n"').join(', ')}) '
            'VALUES (${List.filled(names.length, '?').join(', ')})',
            variables: [for (final n in names) Variable<Object>(row[n])],
          );
        }
      }
      // 設定は常に1行ある状態にする
      final settings = await _db.select(_db.appSettings).get();
      if (settings.isEmpty) {
        await _db.into(_db.appSettings).insert(AppSettingsCompanion.insert());
      }
    });
  }

  Map<String, Object?> _decode(Uint8List bytes) {
    final Object? json;
    try {
      json = jsonDecode(utf8.decode(bytes));
    } on FormatException {
      throw InvalidBackupException('バックアップのファイルではありません');
    }
    if (json is! Map<String, Object?> || json['format'] != backupFormatName) {
      throw InvalidBackupException('バックアップのファイルではありません');
    }
    final version = json['schemaVersion'];
    if (version is! int || version > _db.schemaVersion) {
      throw InvalidBackupException('新しい版のアプリで作ったバックアップです。アプリを更新してください');
    }
    return json;
  }

  static String _yyyymmdd(DateTime d) =>
      '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';
}
