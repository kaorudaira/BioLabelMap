import 'package:biolabelmap/domain/models/calendar_date.dart';
import 'package:biolabelmap/domain/models/place_info.dart';
import 'package:biolabelmap/domain/sampling_method.dart';
import 'package:biolabelmap/domain/status.dart';
import 'package:biolabelmap/features/record/record_form.dart';
import 'package:biolabelmap/services/record_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  RecordForm filled() => RecordForm(
    latitude: 36.94471,
    longitude: 139.24262,
    accuracyMeters: 8,
    elevationMeters: 1388.4,
    place: const PlaceInfo(
      municipalityCode: '15225',
      prefectureJa: '新潟県',
      municipalityJa: '魚沼市',
      localityJa: '下折立',
      prefectureEn: 'Niigata-ken',
      municipalityEn: 'Uonuma-shi',
      localityEn: 'Shimooritate',
    ),
    startDate: CalendarDate(2026, 6, 19),
    endDate: CalendarDate(2026, 6, 20),
    isPeriod: true,
    recordedAt: DateTime(2026, 6, 20, 10, 30),
    samplingMethod: SamplingMethod.lightTrap,
    lightSource: 'UV LED',
    bait: '使わない(ライトトラップでは保存しない)',
    habitat: 'ブナ林',
    count: 15,
    sex: Sex.female,
    remarks: 'メモ',
  );

  test('下書きの JSON に書いて読み戻すと、同じ内容になる', () {
    final restored = RecordForm.fromJson(filled().toJson());
    expect(restored.toJson(), filled().toJson());
    expect(restored.place!.localityEn, 'Shimooritate');
    expect(restored.sex, Sex.female);
    expect(restored.period.toIso(), '2026-06-19/2026-06-20');
  });

  test('保存用の入力では、採集方法に関係ない項目(ベイト)を落とす', () {
    final input = filled().toInput(draftId: 3);
    expect(input.position, isA<NewPosition>());
    expect(input.lightSource, 'UV LED');
    expect(input.bait, isNull);
    expect(input.count, 15);
    expect(input.draftId, 3);
  });

  test('「保存して同地点で追加」は、地点・日時・採集方法・環境をコピーし、標本の項目は空にする', () {
    final next = filled().nextAtSameLocality(42);
    expect(next.existingLocalityId, 42);
    expect(next.toInput().position, isA<ExistingLocality>());
    expect(next.period.toIso(), '2026-06-19/2026-06-20');
    expect(next.samplingMethod, SamplingMethod.lightTrap);
    expect(next.habitat, 'ブナ林');
    expect(next.count, 1);
    expect(next.sex, isNull);
    expect(next.remarks, '');
  });

  test('位置を補正すると、手動になり、精度・標高・地名を取り直す', () {
    final form = filled()..correctPosition(36.9, 139.2);
    expect(form.latitude, 36.9);
    expect(form.longitude, 139.2);
    expect(form.isManualPosition, isTrue);
    expect(form.accuracyMeters, isNull);
    expect(form.elevationMeters, isNull);
    expect(form.place, isNull);
    final position = form.toInput().position as NewPosition;
    expect(position.isManual, isTrue);
  });

  test('1日のみのときは、終了日を使わない', () {
    final form = RecordForm.at(latitude: 36.9, longitude: 139.2, now: DateTime(2026, 6, 20, 9));
    expect(form.period.toIso(), '2026-06-20');
    expect(form.toInput().position, isA<NewPosition>());
  });
}
