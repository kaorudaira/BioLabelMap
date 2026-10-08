import 'package:biolabelmap/core/db/database.dart';
import 'package:biolabelmap/domain/dictionary.dart';
import 'package:biolabelmap/domain/models/calendar_date.dart';
import 'package:biolabelmap/domain/models/collection_period.dart';
import 'package:biolabelmap/domain/sampling_method.dart';
import 'package:biolabelmap/domain/species_name.dart';
import 'package:biolabelmap/domain/status.dart';
import 'package:biolabelmap/services/dictionary_service.dart';
import 'package:biolabelmap/services/identification_service.dart';
import 'package:biolabelmap/services/record_service.dart';
import 'package:biolabelmap/services/settings_service.dart';
import 'package:biolabelmap/services/specimen_service.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DictionaryService dict;
  late IdentificationService identification;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    dict = DictionaryService(db);
    identification = IdentificationService(db, dict);
    await SettingsService(db).initializeCatalog(0);
  });

  tearDown(() => db.close());

  Future<RecordResult> save({int count = 1, String? habitat, String? hostPlant}) => RecordService(db).save(
    RecordInput(
      position: const NewPosition(latitude: 36.94471, longitude: 139.24258),
      period: CollectionPeriod.singleDay(CalendarDate(2026, 6, 20)),
      recordedAt: DateTime(2026, 6, 20, 10, 30),
      samplingMethod: SamplingMethod.sweeping,
      habitat: habitat,
      hostPlant: hostPlant,
      count: count,
    ),
  );

  final carabus = SpeciesName(vernacular: 'オサムシ', genus: 'Carabus', species: 'insulicola', authorship: 'Chaudoir, 1869');

  group('同定の追加', () {
    test('選んだ標本すべてに追加し、上書きせず履歴に積む', () async {
      final r = await save(count: 2);
      await identification.add(r.specimenIds, name: carabus, status: IdentificationStatus.provisional);
      await identification.add(
        [r.specimenIds[0]],
        name: SpeciesName(genus: 'Carabus', species: 'arrowianus'),
        status: IdentificationStatus.verified,
        identifiedBy: ' K. Yoshihara ',
        dateIdentified: CalendarDate(2026, 7, 1),
      );

      final specimens = SpecimenService(db);
      final first = (await specimens.detail(r.specimenIds[0]))!;
      expect(first.history, hasLength(2));
      expect(first.latest!.species, 'arrowianus');
      expect(first.latest!.status, IdentificationStatus.verified);
      expect(first.latest!.identifiedBy, 'K. Yoshihara');
      expect(first.latest!.dateIdentified, CalendarDate(2026, 7, 1));
      final second = (await specimens.detail(r.specimenIds[1]))!;
      expect(second.history, hasLength(1));
      expect(second.latest!.vernacularName, 'オサムシ');
    });

    test('同定者は、次回の既定として設定に覚える。入力が無ければ変えない', () async {
      final r = await save();
      await identification.add(r.specimenIds, name: carabus, status: IdentificationStatus.provisional, identifiedBy: 'A');
      expect((await SettingsService(db).read()).lastIdentifier, 'A');
      await identification.add(r.specimenIds, name: carabus, status: IdentificationStatus.provisional, identifiedBy: '  ');
      expect((await SettingsService(db).read()).lastIdentifier, 'A');
    });

    test('種名が空なら、渡された状態によらず未同定にする', () async {
      final r = await save();
      await identification.add(r.specimenIds, name: SpeciesName(), status: IdentificationStatus.verified);
      expect((await SpecimenService(db).detail(r.specimenIds.single))!.latest!.status, IdentificationStatus.unidentified);
      expect(await db.select(db.speciesDict).get(), isEmpty);
    });

    test('状態は半自動: 種名があれば仮同定、確定したら同定済み、空なら未同定', () {
      expect(IdentificationService.statusFor(carabus), IdentificationStatus.provisional);
      expect(IdentificationService.statusFor(carabus, confirmed: true), IdentificationStatus.verified);
      expect(IdentificationService.statusFor(SpeciesName(), confirmed: true), IdentificationStatus.unidentified);
    });

    test('標本を選ばないと追加できない', () {
      expect(
        () => identification.add([], name: carabus, status: IdentificationStatus.provisional),
        throwsArgumentError,
      );
    });

    test('途中で失敗したら、全部取り消す', () async {
      final r = await save();
      await expectLater(
        identification.add([r.specimenIds.single, 9999], name: carabus, status: IdentificationStatus.provisional),
        throwsA(anything),
      );
      expect((await SpecimenService(db).detail(r.specimenIds.single))!.history, isEmpty);
      expect(await db.select(db.speciesDict).get(), isEmpty);
    });
  });

  group('種の候補', () {
    test('同定した種名が溜まり、同じ種名なら使用回数が増える', () async {
      final r = await save();
      await identification.add(r.specimenIds, name: carabus, status: IdentificationStatus.provisional);
      await identification.add(r.specimenIds, name: carabus, status: IdentificationStatus.provisional);
      final rows = await db.select(db.speciesDict).get();
      expect(rows, hasLength(1));
      expect(rows.single.useCount, 2);
    });

    test('和名・属・種・亜種のどれにも合い、よく使う順に返す', () async {
      await dict.rememberSpecies(SpeciesName(genus: 'Carabus', species: 'arrowianus'));
      await dict.rememberSpecies(carabus);
      await dict.rememberSpecies(carabus);

      expect((await dict.suggestSpecies('carabus')).map((n) => n.species), ['insulicola', 'arrowianus']);
      expect((await dict.suggestSpecies('オサ')).single.genus, 'Carabus');
      expect((await dict.suggestSpecies('CARABUS arrow')).single.species, 'arrowianus');
      expect(await dict.suggestSpecies('  '), isEmpty);
      expect(await dict.suggestSpecies('zzz'), isEmpty);
      expect(await dict.suggestSpecies('carabus', limit: 1), hasLength(1));
    });

    test('候補は命名者・年を括弧の有無ごと保持する', () async {
      await dict.rememberSpecies(SpeciesName(genus: 'Carabus', species: 'x', authorship: '(Linnaeus, 1758)'));
      expect((await dict.suggestSpecies('x')).single.authorship, '(Linnaeus, 1758)');
    });
  });

  group('環境・寄主植物の候補', () {
    test('記録を保存すると、種別ごとに溜まる', () async {
      await save(habitat: ' ブナ林 ', hostPlant: 'スゲ属');
      await save(habitat: 'ブナ林');
      await save();

      expect(await dict.suggestText(DictTextKind.habitat, 'ブナ'), ['ブナ林']);
      expect(await dict.suggestText(DictTextKind.hostPlant, ''), ['スゲ属']);
      expect(await dict.suggestText(DictTextKind.hostPlant, 'ブナ'), isEmpty);
      final habitat = await db.select(db.textDict).get();
      expect(habitat.firstWhere((t) => t.kind == DictTextKind.habitat).useCount, 2);
    });

    test('入力と完全に同じ候補は、出さない', () async {
      await dict.rememberText(DictTextKind.habitat, 'ブナ林');
      await dict.rememberText(DictTextKind.habitat, 'ブナ林の林縁');
      expect(await dict.suggestText(DictTextKind.habitat, 'ブナ林'), ['ブナ林の林縁']);
    });
  });

  group('辞書管理', () {
    test('種: 追加・編集・削除。重複する内容にはできない', () async {
      await dict.addSpecies(SpeciesName(genus: 'Carabus', species: 'a'));
      await dict.addSpecies(SpeciesName(genus: 'Carabus', species: 'b'));
      await expectLater(
        dict.addSpecies(SpeciesName(genus: 'Carabus', species: 'a')),
        throwsA(isA<DictionaryConflictException>()),
      );
      final rows = await dict.watchSpecies().first;
      expect(rows.map((r) => r.entry.species), ['a', 'b']);

      await expectLater(
        dict.updateSpecies(rows[1].entry.id, SpeciesName(genus: 'Carabus', species: 'a')),
        throwsA(isA<DictionaryConflictException>()),
      );
      await dict.updateSpecies(rows[1].entry.id, SpeciesName(genus: 'Carabus', species: 'c'));
      await dict.deleteSpecies(rows[0].entry.id);
      expect((await dict.watchSpecies().first).map((r) => r.entry.species), ['c']);
      expect(() => dict.addSpecies(SpeciesName()), throwsArgumentError);
    });

    test('種: 使用している標本の件数を数え、ごみ箱の標本は数えない', () async {
      final r = await save(count: 3);
      await identification.add(r.specimenIds, name: carabus, status: IdentificationStatus.provisional);
      // 1件は別の種に再同定する。最新の同定で数える
      await identification.add(
        [r.specimenIds[0]],
        name: SpeciesName(genus: 'Carabus', species: 'other'),
        status: IdentificationStatus.provisional,
      );
      await (db.update(db.specimens)..where((s) => s.id.equals(r.specimenIds[1])))
          .write(SpecimensCompanion(deletedAt: Value(DateTime(2026, 7, 1))));

      final rows = await dict.watchSpecies().first;
      final byName = {for (final row in rows) row.entry.species: row.usedBy};
      expect(byName['insulicola'], 1);
      expect(byName['other'], 1);
    });

    test('種: 統合すると使用回数を合算して、統合された候補を消す。標本の同定は変わらない', () async {
      final r = await save();
      await identification.add(r.specimenIds, name: SpeciesName(genus: 'Carabus', species: 'a'), status: IdentificationStatus.provisional);
      await dict.rememberSpecies(SpeciesName(genus: 'Carabus', species: 'a'));
      await dict.rememberSpecies(SpeciesName(genus: 'Carabus', species: 'a '));
      await dict.addSpecies(SpeciesName(genus: 'Carabus', species: 'b'));
      await dict.addSpecies(SpeciesName(genus: 'Carabus', species: 'c'));
      final rows = await dict.watchSpecies().first;
      final keep = rows.firstWhere((r) => r.entry.species == 'a').entry;
      final others = rows.where((r) => r.entry.species != 'a').map((r) => r.entry.id);

      await dict.mergeSpecies(keep.id, [...others, keep.id]);

      final after = await db.select(db.speciesDict).get();
      expect(after.single.species, 'a');
      expect(after.single.useCount, keep.useCount);
      expect((await SpecimenService(db).detail(r.specimenIds.single))!.latest!.species, 'a');
    });

    test('環境・寄主植物: 種別ごとに追加・編集・統合・削除と、使用件数', () async {
      await save(count: 2, habitat: 'ブナ林');
      await save(habitat: 'ブナ林 ');
      await dict.addText(DictTextKind.habitat, 'ブナ林の林縁');
      await dict.addText(DictTextKind.hostPlant, 'ブナ林');
      await expectLater(dict.addText(DictTextKind.habitat, 'ブナ林'), throwsA(isA<DictionaryConflictException>()));

      var rows = await dict.watchTexts(DictTextKind.habitat).first;
      expect(rows.map((r) => (r.entry.value, r.usedBy)), [('ブナ林', 3), ('ブナ林の林縁', 0)]);
      expect((await dict.watchTexts(DictTextKind.hostPlant).first).single.usedBy, 0);

      await expectLater(dict.updateText(rows[1].entry.id, 'ブナ林'), throwsA(isA<DictionaryConflictException>()));
      await dict.mergeTexts(rows[0].entry.id, [rows[1].entry.id]);
      rows = await dict.watchTexts(DictTextKind.habitat).first;
      expect(rows.single.entry.value, 'ブナ林');
      expect(rows.single.entry.useCount, 2);

      await dict.updateText(rows.single.entry.id, 'ブナ林(林縁)');
      await dict.deleteText(rows.single.entry.id);
      expect(await dict.watchTexts(DictTextKind.habitat).first, isEmpty);
      // 辞書を変えても、保存済みの採集は変わらない
      expect((await db.select(db.collectionEvents).get()).first.habitat, 'ブナ林');
    });

    test('地名: ローマ字を直す・削除。使用件数は、その大字の標本の数', () async {
      await db.into(db.localities).insert(
        LocalitiesCompanion.insert(
          latitude: 36.9,
          longitude: 139.2,
          latE4: 369000,
          lonE4: 1392000,
          elevationStatus: FetchStatus.fetched,
          placeStatus: FetchStatus.fetched,
          municipalityCode: const Value('15225'),
          localityJa: const Value('下折立'),
        ),
      );
      final r = await RecordService(db).save(
        RecordInput(
          position: const ExistingLocality(1),
          period: CollectionPeriod.singleDay(CalendarDate(2026, 6, 20)),
          recordedAt: DateTime(2026, 6, 20),
          samplingMethod: SamplingMethod.general,
          count: 2,
        ),
      );
      expect(r.specimenIds, hasLength(2));
      await db.into(db.placeRomajiDict).insert(
        PlaceRomajiDictCompanion.insert(municipalityCode: '15225', localityJa: '下折立', localityEn: 'Shimoorityu'),
      );

      var rows = await dict.watchPlaces().first;
      expect(rows.single.usedBy, 2);
      await dict.updatePlaceRomaji(rows.single.entry.id, ' Shimooritate ');
      rows = await dict.watchPlaces().first;
      expect(rows.single.entry.localityEn, 'Shimooritate');
      // 保存済みの地点は変わらない
      expect((await db.select(db.localities).get()).single.localityEn, isNull);
      expect(() => dict.updatePlaceRomaji(rows.single.entry.id, ' '), throwsArgumentError);

      await dict.deletePlace(rows.single.entry.id);
      expect(await dict.watchPlaces().first, isEmpty);
    });
  });
}
