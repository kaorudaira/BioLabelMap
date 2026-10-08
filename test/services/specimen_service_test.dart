import 'package:biolabelmap/core/db/database.dart';
import 'package:biolabelmap/domain/models/calendar_date.dart';
import 'package:biolabelmap/domain/models/collection_period.dart';
import 'package:biolabelmap/domain/models/place_info.dart';
import 'package:biolabelmap/domain/elevation_rounding.dart';
import 'package:biolabelmap/domain/sampling_method.dart';
import 'package:biolabelmap/domain/specimen_list.dart';
import 'package:biolabelmap/domain/status.dart';
import 'package:biolabelmap/services/label_service.dart';
import 'package:biolabelmap/services/printed_label_values.dart';
import 'package:biolabelmap/services/record_service.dart';
import 'package:biolabelmap/services/settings_service.dart';
import 'package:biolabelmap/services/specimen_service.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late RecordService records;
  late SpecimenService service;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    records = RecordService(db);
    service = SpecimenService(db);
    await SettingsService(db).initializeCatalog(0);
  });

  tearDown(() => db.close());

  Future<RecordResult> save({
    int count = 1,
    SamplingMethod method = SamplingMethod.sweeping,
    String? other,
    int? localityId,
  }) => records.save(
    RecordInput(
      position: localityId != null
          ? ExistingLocality(localityId)
          : const NewPosition(
              latitude: 36.94471,
              longitude: 139.24258,
              accuracyMeters: 8,
              place: PlaceInfo(
                prefectureJa: '新潟県',
                municipalityJa: '魚沼市',
                localityJa: '下折立',
                prefectureEn: 'Niigata-ken',
                municipalityEn: 'Uonuma-shi',
                localityEn: 'Shimooritate',
              ),
            ),
      period: CollectionPeriod.singleDay(CalendarDate(2026, 6, 20)),
      recordedAt: DateTime(2026, 6, 20, 10, 30),
      samplingMethod: method,
      confirmNow: true,
      samplingMethodOther: other,
      count: count,
    ),
  );

  Future<void> identify(int specimenId, {String? genus, String? species, IdentificationStatus? status}) =>
      db.into(db.identifications).insert(
        IdentificationsCompanion.insert(
          specimenId: specimenId,
          status: status ?? IdentificationStatus.provisional,
          genus: Value(genus),
          species: Value(species),
        ),
      );

  test('標本ごとに、最新の同定を種名にする', () async {
    final r = await save(count: 2);
    await identify(r.specimenIds[0], genus: 'Carabus', species: 'old');
    await identify(r.specimenIds[0], genus: 'Carabus', species: 'new', status: IdentificationStatus.verified);

    final items = await service.watchItems().first;
    final byId = {for (final i in items) i.id: i};
    expect(byId[r.specimenIds[0]]!.species.label, 'Carabus new');
    expect(byId[r.specimenIds[0]]!.status, IdentificationStatus.verified);
    expect(byId[r.specimenIds[1]]!.species.label, '未同定');
    expect(byId[r.specimenIds[1]]!.status, IdentificationStatus.unidentified);
  });

  test('地名・採集日・採集方法・標本番号を一覧の項目にする', () async {
    await save(method: SamplingMethod.other, other: '朽木割り');
    final item = (await service.watchItems().first).single;
    expect(item.placeJa, '新潟県魚沼市下折立');
    expect(item.placeEn, 'Niigata-ken, Uonuma-shi, Shimooritate');
    expect(item.methodLabel, 'その他：朽木割り');
    expect(item.catalogText, 'KYC00001');
    expect(item.printed, isFalse);
  });

  test('ごみ箱の標本は、有効な一覧に出さず、ごみ箱の一覧にだけ出す', () async {
    final r = await save(count: 2);
    await (db.update(db.specimens)..where((s) => s.id.equals(r.specimenIds[0])))
        .write(SpecimensCompanion(deletedAt: Value(DateTime(2026, 7, 1))));

    expect((await service.watchItems().first).map((i) => i.id), [r.specimenIds[1]]);
    expect((await service.watchItems(trashed: true).first).map((i) => i.id), [r.specimenIds[0]]);
  });

  test('同定を追加すると、流れ直して最新の種名になる', () async {
    final r = await save();
    final emitted = <String>[];
    final sub = service.watchItems().listen((items) => emitted.add(items.single.species.label));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await identify(r.specimenIds.single, genus: 'Carabus', species: 'x');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await sub.cancel();
    expect(emitted.first, '未同定');
    expect(emitted.last, 'Carabus x');
  });

  test('詳細は、同定履歴を新しい順に持つ', () async {
    final r = await save();
    final id = r.specimenIds.single;
    await identify(id, genus: 'A', species: 'first');
    await identify(id, genus: 'B', species: 'second');

    final d = (await service.detail(id))!;
    expect(d.history.map((i) => i.species), ['second', 'first']);
    expect(d.latest!.species, 'second');
    expect(d.period.isSingleDay, isTrue);
    expect(d.locality.localityJa, '下折立');
  });

  test('印刷したあとに標高や地名が変わった標本は、一覧も詳細も「ラベルと不一致」になる', () async {
    final r = await save(count: 2);
    // 1件目だけ印刷する
    final locality = (await service.detail(r.specimenIds.first))!.locality;
    await LabelService(db).markPrinted({
      r.specimenIds.first: currentLabelValues(locality, ElevationRounding.tenMeters),
    });

    Future<Map<int, bool>> flags() async => {for (final i in await service.watchItems().first) i.id: i.labelMismatch};
    expect((await flags()).values, everyElement(isFalse));

    // 補完で、標高が入った
    await (db.update(db.localities)).write(const LocalitiesCompanion(elevationMeters: Value(1420)));
    expect(await flags(), {r.specimenIds.first: true, r.specimenIds.last: false}); // 印刷していない標本は、不一致にならない
    expect((await service.detail(r.specimenIds.first))!.labelMismatch, isTrue);
    expect((await service.detail(r.specimenIds.last))!.labelMismatch, isFalse);

    final items = await service.watchItems().first;
    expect(arrangeSpecimens(items, filter: const SpecimenFilter(mismatchOnly: true)).map((g) => g.first.id), [r.specimenIds.first]);
  });

  test('設定の標高の丸めを変えると、印刷した標本は「ラベルと不一致」になる', () async {
    final r = await save();
    await (db.update(db.localities)).write(const LocalitiesCompanion(elevationMeters: Value(1388.4)));
    final locality = (await service.detail(r.specimenIds.single))!.locality;
    await LabelService(db).markPrinted({r.specimenIds.single: currentLabelValues(locality, ElevationRounding.tenMeters)});
    expect((await service.watchItems().first).single.labelMismatch, isFalse);

    await (db.update(db.appSettings)).write(AppSettingsCompanion(elevationRounding: Value(ElevationRounding.oneMeter)));
    expect((await service.watchItems().first).single.labelMismatch, isTrue);
  });

  test('詳細は、無い標本なら null', () async {
    expect(await service.detail(999), isNull);
  });
}
