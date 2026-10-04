import 'package:biolabelmap/core/db/database.dart';
import 'package:biolabelmap/domain/models/calendar_date.dart';
import 'package:biolabelmap/domain/models/collection_period.dart';
import 'package:biolabelmap/domain/models/place_info.dart';
import 'package:biolabelmap/domain/sampling_method.dart';
import 'package:biolabelmap/domain/status.dart';
import 'package:biolabelmap/services/draft_service.dart';
import 'package:biolabelmap/services/record_service.dart';
import 'package:biolabelmap/services/settings_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late RecordService records;
  late SettingsService settings;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    records = RecordService(db);
    settings = SettingsService(db);
  });

  tearDown(() => db.close());

  RecordInput input({
    RecordPosition position = const NewPosition(
      latitude: 36.94471,
      longitude: 139.24258,
      accuracyMeters: 8,
    ),
    int count = 1,
    int? draftId,
  }) => RecordInput(
    position: position,
    period: CollectionPeriod.singleDay(CalendarDate(2026, 6, 20)),
    recordedAt: DateTime(2026, 6, 20, 10, 30),
    samplingMethod: SamplingMethod.sweeping,
    habitat: '  ブナ林  ',
    count: count,
    draftId: draftId,
  );

  group('初回設定', () {
    test('設定前は保存できない', () async {
      expect(
        () => records.save(input()),
        throwsA(isA<CatalogNotInitializedException>()),
      );
      expect(await records.previewCatalogRange(1), isNull);
    });

    test('最新番号+1から始まる。2回目は設定できない', () async {
      await settings.initializeCatalog(122);
      expect((await settings.read()).nextCatalogNumber, 123);
      expect(() => settings.initializeCatalog(500), throwsStateError);
    });

    test('標本が無ければ 0 を入力し、1から始まる', () async {
      await settings.initializeCatalog(0);
      expect(await records.previewCatalogRange(1), 'KYC00001');
    });
  });

  group('標本番号の書式の変更', () {
    setUp(() async {
      await settings.initializeCatalog(122);
    });

    test('接頭辞の前後の空白は除く', () async {
      await settings.setCatalogFormat(prefix: ' ABC ', digits: 4);
      expect(await records.previewCatalogRange(1), 'ABC0123');
    });

    test('空の接頭辞と範囲外の桁数は受け付けない', () async {
      expect(() => settings.setCatalogFormat(prefix: '  ', digits: 5), throwsArgumentError);
      expect(() => settings.setCatalogFormat(prefix: 'KYC', digits: 0), throwsArgumentError);
      expect(() => settings.setCatalogFormat(prefix: 'KYC', digits: 11), throwsArgumentError);
    });

    test('これから発行する番号が既存の番号と同じ文字列になる書式を見つける', () async {
      await records.save(input()); // KYC00123。次は124
      // 以前 `A1`+3桁の書式で登録した 5番
      await db.into(db.specimens).insert(
        SpecimensCompanion.insert(collectionEventId: 1, catalogNumber: 5, catalogText: 'A1005'),
      );

      // `A`+4桁では、これから発行する 1005番が `A1005` になる
      expect(await settings.findFormatConflict(prefix: 'A', digits: 4), 'A1005');
      // 同じ文字列になる番号が、すでに発行済みの範囲(124未満)なら重ならない
      expect(await settings.findFormatConflict(prefix: 'A1', digits: 3), isNull);
      expect(await settings.findFormatConflict(prefix: 'KYC0', digits: 4), isNull);
      expect(await settings.findFormatConflict(prefix: 'KYC', digits: 5), isNull);
    });

    test('バックアップの日時を記録する', () async {
      await settings.markBackedUp(DateTime(2026, 10, 4, 9));
      expect((await settings.read()).lastBackupAt, DateTime(2026, 10, 4, 9));
    });
  });

  group('保存', () {
    setUp(() async {
      await settings.initializeCatalog(122);
      await settings.setCollectorName('Kaoru Yoshihara');
    });

    test('作成数15で、1つの採集に連番の標本15件がぶら下がる', () async {
      expect(await records.previewCatalogRange(15), 'KYC00123〜KYC00137');

      final result = await records.save(input(count: 15));

      expect(result.catalogRange, 'KYC00123〜KYC00137');
      expect(result.specimenIds, hasLength(15));
      final specimens = await db.select(db.specimens).get();
      expect(specimens.map((s) => s.catalogText),
          [for (var n = 123; n <= 137; n++) 'KYC00$n']);
      expect(specimens.map((s) => s.collectionEventId).toSet(),
          {result.collectionEventId});
      expect(await db.select(db.collectionEvents).get(), hasLength(1));
      expect(await db.select(db.localities).get(), hasLength(1));
      expect((await settings.read()).nextCatalogNumber, 138);
    });

    test('採集者名と入力値(前後の空白を除く)が採集に入る', () async {
      final result = await records.save(input());
      final event = await (db.select(db.collectionEvents)
            ..where((e) => e.id.equals(result.collectionEventId)))
          .getSingle();
      expect(event.collector, 'Kaoru Yoshihara');
      expect(event.habitat, 'ブナ林');
      expect(event.samplingMethod, SamplingMethod.sweeping);
    });

    test('標高・地名が未取得なら、取得待ちにして補完キューに入れる', () async {
      final result = await records.save(input());
      final locality = await (db.select(db.localities)
            ..where((l) => l.id.equals(result.localityId)))
          .getSingle();
      expect(locality.elevationStatus, FetchStatus.pending);
      expect(locality.placeStatus, FetchStatus.pending);
      expect(locality.latE4, 369447);
      expect(locality.accuracyMeters, 8);

      final queue = await db.select(db.enrichmentQueue).get();
      expect(queue.map((t) => t.kind).toSet(),
          {EnrichmentKind.elevation, EnrichmentKind.place});
    });

    test('取得済みの標高・地名を渡したら、補完キューに入れない', () async {
      await records.save(input(
        position: const NewPosition(
          latitude: 36.9447,
          longitude: 139.2426,
          elevationMeters: 1388.4,
          place: PlaceInfo(
            municipalityCode: '15225',
            municipalityJa: '魚沼市',
            localityJa: '下折立',
            localityEn: 'Shimooritate',
          ),
        ),
      ));
      expect(await db.select(db.enrichmentQueue).get(), isEmpty);

      // 手入力した大字のローマ字は辞書に溜まる
      final dict = await db.select(db.placeRomajiDict).getSingle();
      expect(dict.localityEn, 'Shimooritate');
      expect(dict.useCount, 1);
    });

    test('手動で補正した位置は、精度を記録しない', () async {
      final result = await records.save(input(
        position: const NewPosition(
          latitude: 36.9447,
          longitude: 139.2426,
          accuracyMeters: 45,
          isManual: true,
        ),
      ));
      final locality = await (db.select(db.localities)
            ..where((l) => l.id.equals(result.localityId)))
          .getSingle();
      expect(locality.isManualPosition, isTrue);
      expect(locality.accuracyMeters, isNull);
    });

    test('切り捨てて小数4桁が同じ位置は、同じ地点を使う', () async {
      // 既定の位置は 36.94471, 139.24258 → 36.9447, 139.2425
      final first = await records.save(input());
      final second = await records.save(input(
        position: const NewPosition(latitude: 36.94479, longitude: 139.24251),
      ));
      expect(second.localityId, first.localityId);
      expect(await db.select(db.localities).get(), hasLength(1));
    });

    test('「この地点に追加」は既存の地点を使い、番号は続きから', () async {
      final first = await records.save(input(count: 3));
      final second =
          await records.save(input(position: ExistingLocality(first.localityId)));
      expect(second.localityId, first.localityId);
      expect(second.catalogRange, 'KYC00126');
      expect(second.collectionEventId, isNot(first.collectionEventId));
    });

    test('途中で失敗したら全部取り消され、番号も進まない', () async {
      // 次に発行する番号を、手入力で先に使っておく(重複させる)
      final event = await records.save(input());
      await db.into(db.specimens).insert(SpecimensCompanion.insert(
        collectionEventId: event.collectionEventId,
        catalogNumber: 126,
        catalogText: 'KYC00126',
      ));
      final before = await db.select(db.specimens).get();
      final eventsBefore = await db.select(db.collectionEvents).get();

      // 124, 125 は入るが 126 で重複 → 全部取り消し
      await expectLater(
        records.save(input(count: 3)),
        throwsA(isA<SqliteException>()),
      );

      expect(await db.select(db.specimens).get(), hasLength(before.length));
      expect(await db.select(db.collectionEvents).get(),
          hasLength(eventsBefore.length));
      expect((await settings.read()).nextCatalogNumber, 124);
    });

    test('存在しない地点を指定したら保存しない', () async {
      await expectLater(
        records.save(input(position: const ExistingLocality(9999))),
        throwsA(isA<StateError>()),
      );
      expect((await settings.read()).nextCatalogNumber, 123);
    });

    test('接頭辞と桁数を変えても、既存の番号は変わらない', () async {
      await records.save(input());
      await settings.setCatalogFormat(prefix: 'ABC', digits: 4);
      await records.save(input());

      final texts = (await db.select(db.specimens).get()).map((s) => s.catalogText);
      expect(texts, ['KYC00123', 'ABC0124']);
    });

    test('下書きから保存したら、下書きを消す', () async {
      final drafts = DraftService(db);
      final draftId = await drafts.save({'habitat': 'ブナ林'});

      await records.save(input(draftId: draftId));

      expect(await drafts.load(draftId), isNull);
    });
  });
}
