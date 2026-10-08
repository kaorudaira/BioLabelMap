import 'package:biolabelmap/domain/label/printed_values.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  PrintedLabelValues values({double? elevation = 1390, String localityEn = 'Shimooritate', String? localityJa = '下折立'}) =>
      PrintedLabelValues.of(
        elevationRoundedMeters: elevation,
        country: 'JAPAN',
        prefectureEn: 'Niigata-ken',
        municipalityEn: 'Uonuma-shi',
        localityEn: localityEn,
        municipalityJa: '魚沼市',
        localityJa: localityJa,
      );

  final printed = DateTime(2026, 6, 21);

  bool mismatch(PrintedLabelValues was, PrintedLabelValues now, {DateTime? at}) => isLabelMismatch(
    printedAt: at ?? printed,
    printedElevation: was.elevation,
    printedPlace: was.place,
    current: now,
  );

  group('ラベルに載せる元の値', () {
    test('標高は丸めた値の文字。無ければ空', () {
      expect(values().elevation, '1390');
      expect(values(elevation: null).elevation, '');
      expect(values(elevation: -5).elevation, '-5');
    });

    test('地名は、省略前の英語・日本語の項目を、区切り文字でつなぐ。無い項目は空', () {
      expect(
        values().place.split(PrintedLabelValues.placeSeparator),
        ['JAPAN', 'Niigata-ken', '', 'Uonuma-shi', 'Shimooritate', '', '魚沼市', '下折立'],
      );
    });

    test('前後の空白は無視する', () {
      expect(values(localityEn: ' Shimooritate '), values());
    });
  });

  group('ラベルと不一致', () {
    test('同じ値なら不一致ではない', () => expect(mismatch(values(), values()), isFalse));

    test('印刷していない標本は、不一致にならない', () {
      expect(isLabelMismatch(printedAt: null, printedElevation: null, printedPlace: null, current: values()), isFalse);
      expect(mismatch(values(), values(elevation: 1)), isTrue);
    });

    test('標高が変われば不一致。標高が補完で入っても不一致', () {
      expect(mismatch(values(), values(elevation: 1400)), isTrue);
      expect(mismatch(values(elevation: null), values()), isTrue);
      expect(mismatch(values(), values(elevation: null)), isTrue);
    });

    test('英語の地名が変われば不一致。日本語の地名が補完で入っても不一致', () {
      expect(mismatch(values(), values(localityEn: 'Other')), isTrue);
      expect(mismatch(values(localityJa: null), values()), isTrue);
    });

    test('古い形式(印字した文字列)の地名は比べない。標高は比べる', () {
      bool old({double? now = 1390}) => isLabelMismatch(
        printedAt: printed,
        printedElevation: '1390',
        printedPlace: 'JAPAN: Niigata-ken Uonuma-shi, Shimooritate 魚沼市下折立',
        current: values(elevation: now, localityEn: 'Changed'),
      );
      expect(old(), isFalse);
      expect(old(now: 1500), isTrue);
    });

    test('元の値が残っていない(null)ときは、標高が空のものとして比べる', () {
      expect(
        isLabelMismatch(printedAt: printed, printedElevation: null, printedPlace: null, current: values(elevation: null)),
        isFalse,
      );
      expect(isLabelMismatch(printedAt: printed, printedElevation: null, printedPlace: null, current: values()), isTrue);
    });
  });
}
