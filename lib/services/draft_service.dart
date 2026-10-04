import 'dart:convert';

import 'package:drift/drift.dart';

import '../core/db/database.dart';

/// 記録画面の下書き(要件定義 第14章)。
///
/// フォームの内容を JSON で丸ごと持つ。番号は付けず、保存して初めて標本になる。
/// 段階1の画面では1件として扱うが、テーブルは複数件を持てる。
class DraftService {
  DraftService(this._db);

  final AppDatabase _db;

  /// 保存する。id を渡すと上書きし、渡さなければ新しく作る。保存した id を返す。
  Future<int> save(Map<String, Object?> form, {int? id}) async {
    final json = jsonEncode(form);
    if (id == null) {
      return _db.into(_db.drafts).insert(DraftsCompanion.insert(formJson: json));
    }
    await (_db.update(_db.drafts)..where((d) => d.id.equals(id))).write(
      DraftsCompanion(
        formJson: Value(json),
        updatedAt: Value(DateTime.now()),
      ),
    );
    return id;
  }

  /// フォームの内容を読み出す。無ければ null。
  Future<Map<String, Object?>?> load(int id) async {
    final draft = await (_db.select(_db.drafts)..where((d) => d.id.equals(id)))
        .getSingleOrNull();
    if (draft == null) return null;
    return jsonDecode(draft.formJson) as Map<String, Object?>;
  }

  Future<void> delete(int id) =>
      (_db.delete(_db.drafts)..where((d) => d.id.equals(id))).go();

  /// 下書きの一覧(新しい順)。地図画面の「下書き ◯件」に使う。
  Stream<List<Draft>> watchAll() => (_db.select(_db.drafts)
        ..orderBy([(d) => OrderingTerm.desc(d.updatedAt)]))
      .watch();
}
