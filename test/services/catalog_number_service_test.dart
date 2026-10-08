import 'package:biolabelmap/core/db/database.dart';
import 'package:biolabelmap/domain/models/calendar_date.dart';
import 'package:biolabelmap/domain/models/collection_period.dart';
import 'package:biolabelmap/domain/sampling_method.dart';
import 'package:biolabelmap/domain/status.dart';
import 'package:biolabelmap/services/catalog_number_service.dart';
import 'package:biolabelmap/services/record_service.dart';
import 'package:biolabelmap/services/settings_service.dart';
import 'package:biolabelmap/services/specimen_edit_service.dart';
import 'package:biolabelmap/services/specimen_service.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late CatalogNumberService numbers;
  late SettingsService settings;
  late SpecimenEditService edit;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    numbers = CatalogNumberService(db);
    settings = SettingsService(db);
    edit = SpecimenEditService(db);
    await settings.initializeCatalog(122);
  });

  tearDown(() => db.close());

  Future<RecordResult> save({int count = 1}) => RecordService(db).save(
    RecordInput(
      position: const NewPosition(latitude: 36.94471, longitude: 139.24258),
      period: CollectionPeriod.singleDay(CalendarDate(2026, 6, 20)),
      recordedAt: DateTime(2026, 6, 20),
      samplingMethod: SamplingMethod.sweeping,
      count: count,
    ),
  );

  Future<List<String?>> texts(Iterable<int> ids) async => [
    for (final id in ids) (await (db.select(db.specimens)..where((s) => s.id.equals(id))).getSingle()).catalogText,
  ];

  group('確定', () {
    test('番号は、確定するまで付かない。確定すると、保存した順に続きの番号が付く', () async {
      final a = await save(count: 2);
      final b = await save(count: 2);
      expect(await texts([...a.specimenIds, ...b.specimenIds]), everyElement(isNull));
      expect((await settings.read()).nextCatalogNumber, 123);

      // 後から保存した記録を先に確定しても、選んだ標本の中では保存した順
      final result = await numbers.confirm([...b.specimenIds, ...a.specimenIds]);

      expect(result.count, 4);
      expect(result.range, 'KYC00123〜KYC00126');
      expect(await texts([...a.specimenIds, ...b.specimenIds]), ['KYC00123', 'KYC00124', 'KYC00125', 'KYC00126']);
      expect((await settings.read()).nextCatalogNumber, 127);
    });

    test('選んだ標本だけに番号が付き、続きの番号が進む。1件なら範囲にしない', () async {
      final a = await save(count: 3);
      final result = await numbers.confirm([a.specimenIds[1]]);
      expect(result.range, 'KYC00123');
      expect(await texts(a.specimenIds), [null, 'KYC00123', null]);
      expect((await settings.read()).nextCatalogNumber, 124);

      final more = await numbers.confirm(a.specimenIds);
      expect(more.count, 2);
      expect(await texts(a.specimenIds), ['KYC00124', 'KYC00123', 'KYC00125']);
    });

    test('確定済みの標本は変えず、番号を使わない。ごみ箱の標本も確定しない', () async {
      final a = await save(count: 3);
      await numbers.confirm([a.specimenIds[0]]);
      await edit.moveToTrash([a.specimenIds[2]]);

      final result = await numbers.confirm(a.specimenIds);
      expect(result.count, 1);
      expect(result.range, 'KYC00124');
      expect(await texts(a.specimenIds), ['KYC00123', 'KYC00124', null]);
      expect((await settings.read()).nextCatalogNumber, 125);
    });

    test('確定する標本が無ければ、何もしない', () async {
      final a = await save();
      await numbers.confirm(a.specimenIds);
      final result = await numbers.confirm(a.specimenIds);
      expect(result.count, 0);
      expect(result.range, isNull);
      expect(await numbers.confirm([]), isA<ConfirmResult>().having((r) => r.count, 'count', 0));
      expect((await settings.read()).nextCatalogNumber, 124);
    });

    test('現在の書式で番号を付ける。確定済みの番号は変えない', () async {
      final a = await save(count: 2);
      await numbers.confirm([a.specimenIds[0]]);
      await settings.setCatalogFormat(prefix: 'ABC', digits: 4);
      await numbers.confirm([a.specimenIds[1]]);
      expect(await texts(a.specimenIds), ['KYC00123', 'ABC0124']);
    });

    test('書式を変えたことで、既存の番号と同じ文字列になる番号は飛ばす(重複させない)', () async {
      final a = await save();
      // 以前 `A1`+3桁の書式で登録した番号 A1124。`A`+4桁にすると 124番は A0124…ではなく、衝突する番号を作る
      await db.into(db.specimens).insert(
        SpecimensCompanion.insert(
          collectionEventId: a.collectionEventId,
          catalogNumber: const Value(1),
          catalogText: const Value('A0123'),
        ),
      );
      await settings.setCatalogFormat(prefix: 'A', digits: 4);

      final result = await numbers.confirm(a.specimenIds);
      expect(result.range, 'A0124'); // 123番(A0123)は使用済みなので飛ばす
      expect((await settings.read()).nextCatalogNumber, 125);
    });

    test('初回設定の前は確定できない', () async {
      final fresh = AppDatabase(NativeDatabase.memory());
      addTearDown(fresh.close);
      final eventId = await _insertEvent(fresh);
      final id = await fresh.into(fresh.specimens).insert(SpecimensCompanion.insert(collectionEventId: eventId));
      await expectLater(CatalogNumberService(fresh).confirm([id]), throwsA(isA<CatalogNotInitializedException>()));
    });

    test('未確定(仮)の標本を削除しても、番号は欠番にならない', () async {
      final a = await save(count: 3);
      await edit.moveToTrash([a.specimenIds[1]]);
      await edit.deletePermanently([a.specimenIds[1]]);
      await numbers.confirm(a.specimenIds);
      expect(await texts([a.specimenIds[0], a.specimenIds[2]]), ['KYC00123', 'KYC00124']);
    });

    test('未確定の標本の数(ごみ箱を除く)', () async {
      final a = await save(count: 3);
      expect(await numbers.pendingCount(), 3);
      await numbers.confirm([a.specimenIds[0]]);
      await edit.moveToTrash([a.specimenIds[1]]);
      expect(await numbers.pendingCount(), 1);
    });

    test('保存と同時に確定するときも、同じ番号の付け方になる', () async {
      final a = await save();
      final b = await RecordService(db).save(
        RecordInput(
          position: const NewPosition(latitude: 36.94471, longitude: 139.24258),
          period: CollectionPeriod.singleDay(CalendarDate(2026, 6, 20)),
          recordedAt: DateTime(2026, 6, 20),
          samplingMethod: SamplingMethod.sweeping,
          count: 2,
          confirmNow: true,
        ),
      );
      expect(b.catalogRange, 'KYC00123〜KYC00124');
      expect(await texts(a.specimenIds), [null]);
    });
  });

  group('個体数の変更(番号が未確定の標本)', () {
    Future<int> countIn(int eventId) async =>
        (await (db.select(db.specimens)..where((s) => s.collectionEventId.equals(eventId))).get()).length;

    test('増やすと、仮の標本を足す。番号は使わない', () async {
      final a = await save(count: 2);
      await edit.setProvisionalCount(a.collectionEventId, 5);
      expect(await countIn(a.collectionEventId), 5);
      expect(await numbers.pendingCount(), 5);
      expect((await settings.read()).nextCatalogNumber, 123);
    });

    test('減らすと、保存した順の新しい標本から削除する。欠番にならない', () async {
      final a = await save(count: 4);
      await edit.setProvisionalCount(a.collectionEventId, 2, keepSpecimenId: a.specimenIds.first);
      final left = (await db.select(db.specimens).get()).map((s) => s.id);
      expect(left, [a.specimenIds[0], a.specimenIds[1]]);
      await numbers.confirm(left);
      expect(await texts(left), ['KYC00123', 'KYC00124']);
    });

    test('編集中の標本と、同定を入力した標本は減らさない', () async {
      final a = await save(count: 4);
      await db.into(db.identifications).insert(
        IdentificationsCompanion.insert(specimenId: a.specimenIds[3], status: IdentificationStatus.provisional),
      );
      // 4件 → 2件。新しい順に、同定のある4件目は飛ばして、3件目と2件目を消す(1件目は編集中)
      await edit.setProvisionalCount(a.collectionEventId, 2, keepSpecimenId: a.specimenIds[0]);
      expect((await db.select(db.specimens).get()).map((s) => s.id), [a.specimenIds[0], a.specimenIds[3]]);
    });

    test('減らしきれないときは、何も変えずにエラー', () async {
      final a = await save(count: 2);
      for (final id in a.specimenIds) {
        await db.into(db.identifications).insert(
          IdentificationsCompanion.insert(specimenId: id, status: IdentificationStatus.provisional),
        );
      }
      await expectLater(edit.setProvisionalCount(a.collectionEventId, 1), throwsStateError);
      expect(await countIn(a.collectionEventId), 2);
    });

    test('確定済みの標本とごみ箱の標本は数えず、変えない', () async {
      final a = await save(count: 4);
      await numbers.confirm([a.specimenIds[0]]);
      await edit.moveToTrash([a.specimenIds[1]]);
      // 仮は2件(3件目と4件目)
      await edit.setProvisionalCount(a.collectionEventId, 1);
      final left = (await db.select(db.specimens).get()).map((s) => s.id);
      expect(left, [a.specimenIds[0], a.specimenIds[1], a.specimenIds[2]]);
    });

    test('0件以下にはできない', () async {
      final a = await save();
      expect(() => edit.setProvisionalCount(a.collectionEventId, 0), throwsArgumentError);
    });

    test('詳細は、同じ採集の仮の標本の ID を保存した順に持つ', () async {
      final a = await save(count: 3);
      await numbers.confirm([a.specimenIds[0]]);
      final detail = (await SpecimenService(db).detail(a.specimenIds[1]))!;
      expect(detail.provisionalIdsInEvent, [a.specimenIds[1], a.specimenIds[2]]);
      expect((await SpecimenService(db).detail(a.specimenIds[0]))!.provisionalIdsInEvent, [a.specimenIds[1], a.specimenIds[2]]);
    });
  });
}

Future<int> _insertEvent(AppDatabase db) async {
  final locality = await db.into(db.localities).insert(
    LocalitiesCompanion.insert(
      latitude: 36.9,
      longitude: 139.2,
      latE4: 369000,
      lonE4: 1392000,
      elevationStatus: FetchStatus.pending,
      placeStatus: FetchStatus.pending,
    ),
  );
  return db.into(db.collectionEvents).insert(
    CollectionEventsCompanion.insert(
      localityId: locality,
      startDate: CalendarDate(2026, 6, 20),
      endDate: CalendarDate(2026, 6, 20),
      recordedAt: DateTime(2026, 6, 20),
      samplingMethod: SamplingMethod.sweeping,
    ),
  );
}
