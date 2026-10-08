import 'package:biolabelmap/core/db/database.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('スキーマ4から5へ:既存の標本の番号は残り、これからは番号なし(仮)の標本も保存できる', () async {
    // スキーマ4の標本テーブル(標本番号が必須)に、標本を1件入れた端末を再現する
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw.execute('''
            CREATE TABLE specimens (
              id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              collection_event_id INTEGER NOT NULL,
              catalog_number INTEGER NOT NULL,
              catalog_text TEXT NOT NULL UNIQUE,
              sex TEXT NULL,
              remarks TEXT NULL,
              printed_at INTEGER NULL,
              printed_elevation TEXT NULL,
              printed_place TEXT NULL,
              deleted_at INTEGER NULL,
              created_at INTEGER NOT NULL DEFAULT (strftime('%s', CURRENT_TIMESTAMP))
            )
          ''');
          // 標本を参照する同定(外部キー)。標本テーブルを作り直しても、参照が切れないこと
          raw.execute('''
            CREATE TABLE identifications (
              id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              specimen_id INTEGER NOT NULL REFERENCES specimens (id),
              status TEXT NOT NULL,
              created_at INTEGER NOT NULL DEFAULT (strftime('%s', CURRENT_TIMESTAMP))
            )
          ''');
          raw.execute("INSERT INTO specimens (collection_event_id, catalog_number, catalog_text, remarks) VALUES (1, 123, 'KYC00123', '朝霧')");
          raw.execute("INSERT INTO identifications (specimen_id, status) VALUES (1, 'provisional')");
          raw.execute('PRAGMA user_version = 4');
        },
      ),
    );
    addTearDown(db.close);

    // 開くと移行が走る。既存の標本は、番号もメモも、そのまま
    final existing = await db.select(db.specimens).getSingle();
    expect(existing.catalogNumber, 123);
    expect(existing.catalogText, 'KYC00123');
    expect(existing.remarks, '朝霧');

    // 同定の参照は、新しい標本テーブルを指したまま、切れていない
    final fk = await db.customSelect('PRAGMA foreign_key_list(identifications)').get();
    expect(fk.single.read<String>('table'), 'specimens');
    expect(await db.customSelect('PRAGMA foreign_key_check(identifications)').get(), isEmpty);
    expect(await db.select(db.identifications).get(), hasLength(1));

    // 移行後は、番号なしの標本を何件でも保存できる(番号の一意制約は、番号があるものだけ)
    await db.customStatement('PRAGMA foreign_keys = OFF');
    await db.into(db.specimens).insert(SpecimensCompanion.insert(collectionEventId: 1));
    await db.into(db.specimens).insert(SpecimensCompanion.insert(collectionEventId: 1));
    final all = await db.select(db.specimens).get();
    expect(all.map((s) => s.catalogNumber), [123, null, null]);

    // 番号がある標本どうしは、これまでどおり重複させない
    await expectLater(
      db.into(db.specimens).insert(
        SpecimensCompanion.insert(
          collectionEventId: 1,
          catalogNumber: const Value(124),
          catalogText: const Value('KYC00123'),
        ),
      ),
      throwsA(anything),
    );
  });
}
