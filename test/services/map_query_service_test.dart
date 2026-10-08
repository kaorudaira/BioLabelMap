import 'package:biolabelmap/core/db/database.dart';
import 'package:biolabelmap/domain/models/calendar_date.dart';
import 'package:biolabelmap/domain/models/collection_period.dart';
import 'package:biolabelmap/domain/sampling_method.dart';
import 'package:biolabelmap/domain/status.dart';
import 'package:biolabelmap/services/map_query_service.dart';
import 'package:biolabelmap/services/record_service.dart';
import 'package:biolabelmap/services/settings_service.dart';
import 'package:biolabelmap/services/specimen_edit_service.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late MapQueryService map;
  late SpecimenEditService edit;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    map = MapQueryService(db);
    edit = SpecimenEditService(db);
    await SettingsService(db).initializeCatalog(0);
  });

  tearDown(() => db.close());

  Future<RecordResult> save({int count = 1, double lat = 36.94471, double lon = 139.24258, int? localityId}) =>
      RecordService(db).save(
        RecordInput(
          position: localityId != null ? ExistingLocality(localityId) : NewPosition(latitude: lat, longitude: lon),
          period: CollectionPeriod.singleDay(CalendarDate(2026, 6, 20)),
          recordedAt: DateTime(2026, 6, 20),
          samplingMethod: SamplingMethod.sweeping,
          count: count,
        ),
      );

  Future<List<(int, int, int)>> pins() async =>
      [for (final p in await map.watchPins().first) (p.localityId, p.specimenCount, p.unidentifiedCount)];

  test('標本がある場所に、件数つきのピンを1つ立てる。未同定の数も数える', () async {
    final r = await save(count: 5);
    expect(await pins(), [(r.localityId, 5, 5)]);
    await db.into(db.identifications).insert(
      IdentificationsCompanion.insert(specimenId: r.specimenIds.first, status: IdentificationStatus.provisional),
    );
    expect(await pins(), [(r.localityId, 5, 4)]);
  });

  test('最新の同定が「未同定」なら、未同定として数える', () async {
    final r = await save();
    for (final status in [IdentificationStatus.verified, IdentificationStatus.unidentified]) {
      await db.into(db.identifications).insert(IdentificationsCompanion.insert(specimenId: r.specimenIds.single, status: status));
    }
    expect(await pins(), [(r.localityId, 1, 1)]);
  });

  test('標本の一部の地名を直して、同じ座標に地点が複製されても、ピンは1つにまとまる(隠れない)', () async {
    final r = await save(count: 5);
    await edit.apply([r.specimenIds[0], r.specimenIds[1]], const SpecimenEdit(place: {PlaceField.localityJa: '下折立温泉'}));

    expect(await db.select(db.localities).get(), hasLength(2)); // 地点の行は複製される
    expect(await pins(), [(r.localityId, 5, 5)]); // ピンは1つで、5件
  });

  test('座標を別の場所に直した標本は、別のピンになる。残りは元のピンに残る', () async {
    final r = await save(count: 5);
    await edit.apply([r.specimenIds[0]], const SpecimenEdit(position: (latitude: 35.0, longitude: 139.0)));
    final result = await pins();
    expect(result, hasLength(2));
    expect(result.first, (r.localityId, 4, 4));
    expect(result.last.$2, 1);
  });

  test('ごみ箱の標本は数えない。全部ごみ箱なら、ピンが消える', () async {
    final r = await save(count: 2);
    await edit.moveToTrash([r.specimenIds.first]);
    expect(await pins(), [(r.localityId, 1, 1)]);
    await edit.moveToTrash([r.specimenIds.last]);
    expect(await pins(), isEmpty);
  });

  group('座標を直す操作で、地点を増やさない', () {
    test('座標が変わらないとき(地図を動かさずに決めた)は、何も変えない。標高・地名を取り直さない', () async {
      final r = await save(count: 3);
      await edit.apply([r.specimenIds.first], const SpecimenEdit(position: (latitude: 36.94471, longitude: 139.24258)));

      expect(await db.select(db.localities).get(), hasLength(1));
      expect(await db.select(db.collectionEvents).get(), hasLength(1));
      final l = await db.select(db.localities).getSingle();
      expect(l.isManualPosition, isFalse);
      expect(l.elevationStatus, FetchStatus.pending); // 記録時のまま(補完待ち)。取り直しの指示は出していない
      expect(await pins(), [(r.localityId, 3, 3)]);
    });

    test('同じ場所(小数4桁が同じ)の範囲内の微調整は、座標だけ直し、標高と地名はそのまま', () async {
      final r = await save(count: 2);
      await db.update(db.localities).write(
        const LocalitiesCompanion(
          elevationMeters: Value<double?>(1388.4),
          elevationStatus: Value(FetchStatus.fetched),
          localityJa: Value<String?>('下折立'),
          placeStatus: Value(FetchStatus.fetched),
        ),
      );
      await db.delete(db.enrichmentQueue).go();
      await edit.apply(r.specimenIds, const SpecimenEdit(position: (latitude: 36.94475, longitude: 139.24259)));

      final l = await db.select(db.localities).getSingle();
      expect(l.latitude, 36.94475);
      expect(l.isManualPosition, isTrue);
      expect(l.elevationMeters, 1388.4);
      expect(l.localityJa, '下折立');
      expect(await db.select(db.enrichmentQueue).get(), isEmpty);
      expect(await pins(), [(r.localityId, 2, 2)]);
    });

    test('微調整でも、一部の標本だけを選んだ場合は、座標を共有する他の標本が動かないよう、地点を複製する。ピンは1つ', () async {
      final r = await save(count: 3);
      await edit.apply([r.specimenIds.first], const SpecimenEdit(position: (latitude: 36.94475, longitude: 139.24259)));

      expect(await db.select(db.localities).get(), hasLength(2));
      expect(await pins(), [(r.localityId, 3, 3)]);
    });
  });
}
