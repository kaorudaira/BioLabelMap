import 'package:biolabelmap/core/db/database.dart';
import 'package:biolabelmap/domain/elevation_rounding.dart';
import 'package:biolabelmap/domain/models/calendar_date.dart';
import 'package:biolabelmap/domain/sampling_method.dart';
import 'package:biolabelmap/domain/status.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // `late` は「宣言時には初期化しないが、使う前に必ず代入する」という印。
  // JUnit の @BeforeEach で代入するフィールドと同じ使い方。
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  // `async` / `await` は Java の CompletableFuture を同期的に書ける構文。
  // `Future<int>` は CompletableFuture<Integer> に相当する。
  Future<int> insertLocality() => db.into(db.localities).insert(
    LocalitiesCompanion.insert(
      latitude: 36.9447,
      longitude: 139.2426,
      latE4: 369447,
      lonE4: 1392426,
      elevationStatus: FetchStatus.pending,
      placeStatus: FetchStatus.pending,
    ),
  );

  Future<int> insertEvent(int localityId) => db.into(db.collectionEvents).insert(
    CollectionEventsCompanion.insert(
      localityId: localityId,
      startDate: CalendarDate(2026, 6, 19),
      endDate: CalendarDate(2026, 6, 20),
      recordedAt: DateTime(2026, 6, 20, 10, 30),
      samplingMethod: SamplingMethod.lightTrap,
    ),
  );

  Future<int> insertSpecimen(int eventId, int number) =>
      db.into(db.specimens).insert(
        SpecimensCompanion.insert(
          collectionEventId: eventId,
          catalogNumber: number,
          catalogText: 'KYC${number.toString().padLeft(5, '0')}',
        ),
      );

  test('作成直後に設定が1行あり、既定値が入っている', () async {
    final settings = await db.select(db.appSettings).getSingle();
    expect(settings.catalogPrefix, 'KYC');
    expect(settings.catalogDigits, 5);
    expect(settings.elevationRounding, ElevationRounding.tenMeters);
    // 初回設定が済むまでは null(記録を始められない)
    expect(settings.nextCatalogNumber, isNull);
  });

  test('設定の2行目は入らない', () async {
    expect(
      () => db.into(db.appSettings).insert(
        AppSettingsCompanion.insert(id: const Value(2)),
      ),
      throwsA(isA<SqliteException>()),
    );
  });

  test('地点・採集・標本を保存して読み戻せる(日付と enum の変換)', () async {
    final localityId = await insertLocality();
    final eventId = await insertEvent(localityId);
    await insertSpecimen(eventId, 123);

    final event = await (db.select(db.collectionEvents)
          ..where((e) => e.id.equals(eventId)))
        .getSingle();
    // `..` はカスケード演算子。同じオブジェクトに続けて操作し、そのオブジェクト自身を返す。
    // Java のビルダーで `return this;` を書くのと同じ効果。
    expect(event.startDate, CalendarDate(2026, 6, 19));
    expect(event.endDate, CalendarDate(2026, 6, 20));
    expect(event.samplingMethod, SamplingMethod.lightTrap);

    final specimen = await db.select(db.specimens).getSingle();
    expect(specimen.catalogText, 'KYC00123');
    expect(specimen.deletedAt, isNull);
  });

  test('標本番号の文字列は重複できない', () async {
    final eventId = await insertEvent(await insertLocality());
    await insertSpecimen(eventId, 123);
    expect(
      () => insertSpecimen(eventId, 123),
      throwsA(isA<SqliteException>()),
    );
  });

  test('外部キーが有効(存在しない採集には標本を付けられない)', () async {
    expect(
      () => insertSpecimen(9999, 1),
      throwsA(isA<SqliteException>()),
    );
  });

  test('補完待ちは地点ごと・種類ごとに1件まで', () async {
    final localityId = await insertLocality();
    final entry = EnrichmentQueueCompanion.insert(
      localityId: localityId,
      kind: EnrichmentKind.elevation,
    );
    await db.into(db.enrichmentQueue).insert(entry);
    await db.into(db.enrichmentQueue).insert(
      EnrichmentQueueCompanion.insert(
        localityId: localityId,
        kind: EnrichmentKind.place,
      ),
    );
    expect(
      () => db.into(db.enrichmentQueue).insert(entry),
      throwsA(isA<SqliteException>()),
    );
  });

  test('トランザクション内で失敗すると、全部が無かったことになる', () async {
    final eventId = await insertEvent(await insertLocality());
    await insertSpecimen(eventId, 1);

    // 2件目が重複して失敗 → 同じトランザクションの番号更新も取り消される
    await expectLater(
      db.transaction(() async {
        await insertSpecimen(eventId, 2);
        await insertSpecimen(eventId, 1);
        await db.update(db.appSettings).write(
          const AppSettingsCompanion(nextCatalogNumber: Value(3)),
        );
      }),
      throwsA(isA<SqliteException>()),
    );

    expect(await db.select(db.specimens).get(), hasLength(1));
    final settings = await db.select(db.appSettings).getSingle();
    expect(settings.nextCatalogNumber, isNull);
  });
}
