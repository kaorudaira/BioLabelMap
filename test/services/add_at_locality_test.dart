import 'package:biolabelmap/core/db/database.dart';
import 'package:biolabelmap/domain/models/calendar_date.dart';
import 'package:biolabelmap/domain/models/collection_period.dart';
import 'package:biolabelmap/domain/sampling_method.dart';
import 'package:biolabelmap/features/specimen/add_at_locality.dart';
import 'package:biolabelmap/services/record_service.dart';
import 'package:biolabelmap/services/settings_service.dart';
import 'package:biolabelmap/services/specimen_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late SpecimenService service;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    service = SpecimenService(db);
    await SettingsService(db).initializeCatalog(0);
  });

  tearDown(() => db.close());

  Future<RecordResult> save({int day = 20, SamplingMethod method = SamplingMethod.sweeping, int? localityId, String? habitat}) =>
      RecordService(db).save(
        RecordInput(
          position: localityId != null ? ExistingLocality(localityId) : const NewPosition(latitude: 36.94471, longitude: 139.24258),
          period: CollectionPeriod.singleDay(CalendarDate(2026, 6, day)),
          recordedAt: DateTime(2026, 6, day),
          samplingMethod: method,
          habitat: habitat,
          confirmNow: true,
        ),
      );

  Future<(Locality, List<dynamic>)> here(int localityId) async {
    final locality = await (db.select(db.localities)..where((l) => l.id.equals(localityId))).getSingle();
    final items = await service.watchItems().first;
    return (locality, specimensAtLocality(items, locality));
  }

  test('その地点でいちばん新しい採集の、日付・採集方法・環境をコピーした記録の初期値を作る', () async {
    final first = await save(day: 20, method: SamplingMethod.sweeping, habitat: 'ブナ林');
    await save(day: 25, method: SamplingMethod.looking, localityId: first.localityId, habitat: '草地');
    await save(day: 22, method: SamplingMethod.general, localityId: first.localityId);

    final (locality, items) = await here(first.localityId);
    final form = (await recordFormForLocality(service, locality, items.cast()))!;

    expect(form.existingLocalityId, first.localityId);
    expect(form.startDate, CalendarDate(2026, 6, 25));
    expect(form.samplingMethod, SamplingMethod.looking);
    expect(form.habitat, '草地');
    // 標本の項目は、引き継がない
    expect(form.count, 1);
    expect(form.remarks, '');
  });

  test('標本が無い地点は、地点だけを使う', () async {
    final r = await save();
    final locality = await (db.select(db.localities)..where((l) => l.id.equals(r.localityId))).getSingle();
    final form = (await recordFormForLocality(service, locality, const []))!;
    expect(form.existingLocalityId, r.localityId);
    expect(form.latitude, closeTo(36.94471, 1e-9));
    expect(form.samplingMethod, SamplingMethod.general); // 既定
  });

  test('同じ場所(判定キーが同じ)の標本だけを集める。地点の行が複製されていても、まとめる', () async {
    final a = await save();
    final b = await save(day: 21, localityId: a.localityId);
    // 別の場所
    await RecordService(db).save(
      RecordInput(
        position: const NewPosition(latitude: 35.0, longitude: 139.0),
        period: CollectionPeriod.singleDay(CalendarDate(2026, 6, 20)),
        recordedAt: DateTime(2026, 6, 20),
        samplingMethod: SamplingMethod.sweeping,
        confirmNow: true,
      ),
    );
    final (locality, items) = await here(a.localityId);
    expect(items, hasLength(2));
    expect(b.specimenIds, hasLength(1));
  });
}
