import 'package:drift/drift.dart';

import '../core/db/database.dart';
import '../domain/catalog_number.dart';
import 'settings_service.dart';

/// 番号を確定した結果。
class ConfirmResult {
  const ConfirmResult({required this.count, this.range});

  /// 番号を割り当てた標本の数。
  final int count;

  /// 割り当てた番号。例: `KYC00123〜KYC00137`。1件なら `KYC00123`。割り当てが無ければ null。
  final String? range;
}

/// 標本番号の確定(要件定義 第14章)。
///
/// 記録を保存した標本は、番号の無い「仮」の状態になる。個体数などを直してから、
/// 確定の操作で、その時点の次の番号を保存した順に割り当てる。仮の標本は番号を使わないので、
/// 削除したり個体数を変えたりしても、欠番にならない。確定した番号は戻せない。
class CatalogNumberService {
  CatalogNumberService(this._db);

  final AppDatabase _db;

  /// 選んだ標本のうち、番号が未確定でごみ箱に入っていないものに、番号を割り当てる。
  /// 確定済みの標本は変えない。保存した順(作成日時、同じなら ID)に、続きの番号を付ける。
  Future<ConfirmResult> confirm(Iterable<int> specimenIds) =>
      _db.transaction(() => confirmWithin(_db, specimenIds));

  /// 呼び出し側のトランザクションの中で確定する(記録の保存と、まとめて確定するときに使う)。
  static Future<ConfirmResult> confirmWithin(AppDatabase db, Iterable<int> specimenIds) async {
    final ids = specimenIds.toSet();
    final pending =
        await (db.select(db.specimens)
              ..where((s) => s.id.isIn(ids) & s.catalogNumber.isNull() & s.deletedAt.isNull())
              ..orderBy([(s) => OrderingTerm.asc(s.createdAt), (s) => OrderingTerm.asc(s.id)]))
            .get();
    if (pending.isEmpty) return const ConfirmResult(count: 0);

    final settings = await db.select(db.appSettings).getSingle();
    var next = settings.nextCatalogNumber;
    if (next == null) throw CatalogNotInitializedException();
    final format = CatalogNumberFormat(prefix: settings.catalogPrefix, digits: settings.catalogDigits);

    // 書式を変えたあとで、既存の番号と同じ文字列になる番号は飛ばす(重複させない)
    final taken = {
      for (final t in await (db.selectOnly(db.specimens)..addColumns([db.specimens.catalogText]))
          .map((r) => r.read(db.specimens.catalogText))
          .get())
        ?t,
    };

    String? first, last;
    for (final s in pending) {
      while (taken.contains(format.format(next!))) {
        next++;
      }
      final text = format.format(next);
      await (db.update(db.specimens)..where((x) => x.id.equals(s.id))).write(
        SpecimensCompanion(catalogNumber: Value(next), catalogText: Value(text)),
      );
      taken.add(text);
      first ??= text;
      last = text;
      next++;
    }
    await db.update(db.appSettings).write(AppSettingsCompanion(nextCatalogNumber: Value(next)));
    return ConfirmResult(count: pending.length, range: first == last ? first : '$first〜$last');
  }

  /// 番号が未確定の標本の数(ごみ箱を除く)。
  Future<int> pendingCount() async {
    final count = _db.specimens.id.count();
    final row = await (_db.selectOnly(_db.specimens)
          ..addColumns([count])
          ..where(_db.specimens.catalogNumber.isNull() & _db.specimens.deletedAt.isNull()))
        .getSingle();
    return row.read(count)!;
  }
}
