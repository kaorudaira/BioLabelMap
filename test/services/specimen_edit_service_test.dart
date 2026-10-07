import 'package:biolabelmap/core/db/database.dart';
import 'package:biolabelmap/domain/models/calendar_date.dart';
import 'package:biolabelmap/domain/models/collection_period.dart';
import 'package:biolabelmap/domain/models/place_info.dart';
import 'package:biolabelmap/domain/sampling_method.dart';
import 'package:biolabelmap/domain/status.dart';
import 'package:biolabelmap/domain/trash.dart';
import 'package:biolabelmap/services/record_service.dart';
import 'package:biolabelmap/services/settings_service.dart';
import 'package:biolabelmap/services/specimen_edit_service.dart';
import 'package:biolabelmap/services/specimen_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late SpecimenEditService edit;
  late SpecimenService specimens;
  late RecordService records;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    edit = SpecimenEditService(db);
    specimens = SpecimenService(db);
    records = RecordService(db);
    await SettingsService(db).initializeCatalog(0);
  });

  tearDown(() => db.close());

  Future<RecordResult> save({int count = 1, int? localityId, SamplingMethod method = SamplingMethod.sweeping}) =>
      records.save(
        RecordInput(
          position: localityId != null
              ? ExistingLocality(localityId)
              : const NewPosition(
                  latitude: 36.94471,
                  longitude: 139.24258,
                  place: PlaceInfo(
                    municipalityCode: '15225',
                    prefectureJa: '新潟県',
                    municipalityJa: '魚沼市',
                    localityJa: '下折立',
                    prefectureEn: 'Niigata-ken',
                    municipalityEn: 'Uonuma-shi',
                    localityEn: 'Shimooritate',
                  ),
                ),
          period: CollectionPeriod.singleDay(CalendarDate(2026, 6, 20)),
          recordedAt: DateTime(2026, 6, 20),
          samplingMethod: method,
          habitat: 'ブナ林',
          count: count,
        ),
      );

  Future<SpecimenDetail> detail(int id) async => (await specimens.detail(id))!;

  group('修正', () {
    test('採集を共有する標本の全部を選んだら、その採集を直す(複製しない)', () async {
      final r = await save(count: 3);
      await edit.apply(r.specimenIds, const SpecimenEdit(method: SamplingMethod.looking));

      expect(await db.select(db.collectionEvents).get(), hasLength(1));
      for (final id in r.specimenIds) {
        expect((await detail(id)).event.samplingMethod, SamplingMethod.looking);
      }
    });

    test('一部だけを選んだら、その標本のために採集を複製して付け替える。他の標本は変わらない', () async {
      final r = await save(count: 3);
      await edit.apply([r.specimenIds[1]], SpecimenEdit(
        method: SamplingMethod.other,
        methodOther: const Change('朽木割り'),
        period: CollectionPeriod(CalendarDate(2026, 6, 19), CalendarDate(2026, 6, 20)),
      ));

      expect(await db.select(db.collectionEvents).get(), hasLength(2));
      final changed = await detail(r.specimenIds[1]);
      expect(changed.event.samplingMethod, SamplingMethod.other);
      expect(changed.event.samplingMethodOther, '朽木割り');
      expect(changed.period.isSingleDay, isFalse);
      expect(changed.event.habitat, 'ブナ林'); // 複製なので、他の項目は引き継ぐ
      for (final i in [0, 2]) {
        final other = await detail(r.specimenIds[i]);
        expect(other.event.samplingMethod, SamplingMethod.sweeping);
        expect(other.period.isSingleDay, isTrue);
        expect(other.event.id, isNot(changed.event.id));
      }
    });

    test('複数の採集にまたがる標本を選んでも、それぞれ直る', () async {
      final a = await save(count: 2);
      final b = await save(count: 2, localityId: a.localityId, method: SamplingMethod.general);
      await edit.apply([a.specimenIds.first, ...b.specimenIds], const SpecimenEdit(habitat: Change('草地')));

      expect((await detail(a.specimenIds.first)).event.habitat, '草地');
      expect((await detail(b.specimenIds.first)).event.habitat, '草地');
      expect((await detail(a.specimenIds.last)).event.habitat, 'ブナ林');
      // bの採集は全部選んだので複製しない。aの採集は一部なので複製する
      expect(await db.select(db.collectionEvents).get(), hasLength(3));
    });

    test('空にする指定は、空文字・空白でも null になる', () async {
      final r = await save();
      await edit.apply(r.specimenIds, const SpecimenEdit(habitat: Change('  '), remarks: Change(' ')));
      expect((await detail(r.specimenIds.single)).event.habitat, isNull);
    });

    test('性別とメモは標本ごとに直し、採集は変えない', () async {
      final r = await save(count: 2);
      await edit.apply([r.specimenIds[0]], const SpecimenEdit(sex: Change(Sex.female), remarks: Change(' 朝霧 ')));
      final d = await detail(r.specimenIds[0]);
      expect(d.specimen.sex, Sex.female);
      expect(d.specimen.remarks, '朝霧');
      expect((await detail(r.specimenIds[1])).specimen.sex, isNull);
      expect(await db.select(db.collectionEvents).get(), hasLength(1));
    });

    test('地名を直すと「手入力」になり、地点を共有する他の標本は変わらない', () async {
      final a = await save(count: 2);
      final b = await save(localityId: a.localityId);
      await edit.apply(a.specimenIds, const SpecimenEdit(place: {
        PlaceField.localityJa: ' 下折立温泉 ',
        PlaceField.localityEn: 'Shimooritate-onsen',
      }));

      final changed = await detail(a.specimenIds.first);
      expect(changed.locality.localityJa, '下折立温泉');
      expect(changed.locality.localityEn, 'Shimooritate-onsen');
      expect(changed.locality.placeStatus, FetchStatus.manual);
      expect(changed.locality.municipalityJa, '魚沼市'); // 指定しなかった項目は変わらない
      expect(changed.locality.latitude, closeTo(36.94471, 1e-9));

      final untouched = await detail(b.specimenIds.single);
      expect(untouched.locality.localityJa, '下折立');
      expect(untouched.locality.placeStatus, isNot(FetchStatus.manual));
      expect(changed.locality.id, isNot(untouched.locality.id));
      expect(await db.select(db.localities).get(), hasLength(2));
    });

    test('その地点を使う採集を全部選んだら、地点そのものを直す', () async {
      final r = await save(count: 2);
      await edit.apply(r.specimenIds, const SpecimenEdit(place: {PlaceField.countyJa: '南魚沼郡'}));
      expect(await db.select(db.localities).get(), hasLength(1));
      expect((await detail(r.specimenIds.first)).locality.countyJa, '南魚沼郡');
    });

    test('地名の項目を null にすると、その項目を空にする', () async {
      final r = await save();
      await edit.apply(r.specimenIds, const SpecimenEdit(place: {PlaceField.localityEn: null}));
      expect((await detail(r.specimenIds.single)).locality.localityEn, isNull);
    });

    test('何も変えない修正は、何もしない。標本を選ばないとエラー', () async {
      final r = await save();
      await edit.apply(r.specimenIds, const SpecimenEdit());
      expect(() => edit.apply([], const SpecimenEdit(sex: Change(Sex.male))), throwsArgumentError);
      expect(() => edit.apply([9999], const SpecimenEdit(sex: Change(Sex.male))), throwsStateError);
    });
  });

  group('ごみ箱', () {
    test('ごみ箱に移すと一覧から消え、元に戻すと、元の標本番号のまま戻る', () async {
      final r = await save(count: 2);
      await edit.moveToTrash([r.specimenIds[0]], now: DateTime(2026, 7, 1));

      expect((await specimens.watchItems().first).map((i) => i.id), [r.specimenIds[1]]);
      final trashed = await specimens.watchItems(trashed: true).first;
      expect(trashed.single.catalogText, 'KYC00001');
      expect(trashed.single.deletedAt, DateTime(2026, 7, 1));

      await edit.restore([r.specimenIds[0]]);
      final back = await specimens.watchItems().first;
      expect(back.map((i) => i.catalogText), containsAll(['KYC00001', 'KYC00002']));
      expect(back.every((i) => i.deletedAt == null), isTrue);
    });

    test('完全に削除すると、標本と同定の履歴が消える。ごみ箱の外の標本は消さない', () async {
      final r = await save(count: 2);
      await db.into(db.identifications).insert(
        IdentificationsCompanion.insert(specimenId: r.specimenIds[0], status: IdentificationStatus.provisional),
      );
      await edit.moveToTrash([r.specimenIds[0]]);

      final n = await edit.deletePermanently([r.specimenIds[0], r.specimenIds[1]]);
      expect(n, 1); // ごみ箱にある1件だけ
      expect(await db.select(db.identifications).get(), isEmpty);
      expect((await db.select(db.specimens).get()).map((s) => s.id), [r.specimenIds[1]]);
      expect(await db.select(db.collectionEvents).get(), hasLength(1)); // 標本が残る採集は消さない
    });

    test('標本が無くなった採集は、いっしょに消す', () async {
      final r = await save();
      await edit.moveToTrash(r.specimenIds);
      await edit.deletePermanently(r.specimenIds);
      expect(await db.select(db.collectionEvents).get(), isEmpty);
    });

    test('完全に削除した番号は欠番のままで、次の記録は続きの番号になる', () async {
      final r = await save(count: 2);
      await edit.moveToTrash(r.specimenIds);
      await edit.deletePermanently(r.specimenIds);
      final next = await save();
      expect((await detail(next.specimenIds.single)).specimen.catalogText, 'KYC00003');
    });

    test('保持期間(30日)を過ぎた標本だけ、起動時に完全に削除する', () async {
      final r = await save(count: 3);
      await edit.moveToTrash([r.specimenIds[0]], now: DateTime(2026, 6, 1));
      await edit.moveToTrash([r.specimenIds[1]], now: DateTime(2026, 6, 25));

      final purged = await edit.purgeExpired(now: DateTime(2026, 7, 2));
      expect(purged, 1);
      final left = (await db.select(db.specimens).get()).map((s) => s.id).toSet();
      expect(left, {r.specimenIds[1], r.specimenIds[2]});
      expect(await edit.purgeExpired(now: DateTime(2026, 7, 2)), 0);
    });
  });

  group('残り日数', () {
    final deleted = DateTime(2026, 7, 1, 12);

    test('削除した日から30日で完全に削除する', () {
      expect(daysUntilPurge(deleted, deleted), 30);
      expect(daysUntilPurge(deleted, DateTime(2026, 7, 2, 11)), 30);
      expect(daysUntilPurge(deleted, DateTime(2026, 7, 2, 12)), 29);
      expect(daysUntilPurge(deleted, DateTime(2026, 7, 30, 12)), 1);
      expect(daysUntilPurge(deleted, DateTime(2026, 8, 5)), 0);
      expect(isPurgeDue(deleted, DateTime(2026, 7, 31, 11, 59)), isFalse);
      expect(isPurgeDue(deleted, DateTime(2026, 7, 31, 12)), isTrue);
    });

    test('表示', () {
      expect(purgeCountdownText(deleted, DateTime(2026, 7, 11, 12)), 'あと20日で完全に削除');
      expect(purgeCountdownText(deleted, DateTime(2026, 8, 5)), 'まもなく完全に削除');
    });
  });
}
