import 'package:biolabelmap/domain/label/date_range_format.dart';
import 'package:biolabelmap/domain/models/calendar_date.dart';
import 'package:biolabelmap/domain/models/collection_period.dart';
import 'package:flutter_test/flutter_test.dart';

// group / test は JUnit 5 の @Nested / @Test に相当する。
void main() {
  CollectionPeriod period(String start, String end) =>
      CollectionPeriod(CalendarDate.parse(start), CalendarDate.parse(end));

  group('romanMonth', () {
    test('1〜12月をローマ数字にする', () {
      expect(
        List.generate(12, (i) => romanMonth(i + 1)),
        ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X', 'XI', 'XII'],
      );
    });

    test('範囲外はエラー', () {
      expect(() => romanMonth(0), throwsRangeError);
      expect(() => romanMonth(13), throwsRangeError);
    });
  });

  group('formatLabelPeriod(要件定義 第5章の例)', () {
    test('1日のみ', () {
      expect(
        formatLabelPeriod(CollectionPeriod.singleDay(CalendarDate(2026, 6, 20))),
        '20. VI. 2026',
      );
    });

    test('開始日と終了日が同じなら1日のみとして扱う', () {
      expect(formatLabelPeriod(period('2026-06-20', '2026-06-20')),
          '20. VI. 2026');
    });

    test('同じ月', () {
      expect(formatLabelPeriod(period('2026-06-19', '2026-06-20')),
          '19-20. VI. 2026');
    });

    test('月をまたぐ', () {
      expect(formatLabelPeriod(period('2026-05-30', '2026-06-02')),
          '30. V.-2. VI. 2026');
    });

    test('年をまたぐ', () {
      expect(formatLabelPeriod(period('2025-12-30', '2026-01-02')),
          '30. XII. 2025-2. I. 2026');
    });
  });

  group('CollectionPeriod', () {
    test('ISO 形式(CSV の eventDate)', () {
      expect(period('2026-06-19', '2026-06-20').toIso(),
          '2026-06-19/2026-06-20');
      expect(CollectionPeriod.singleDay(CalendarDate(2026, 6, 20)).toIso(),
          '2026-06-20');
    });

    test('終了日が開始日より前ならエラー', () {
      expect(() => period('2026-06-20', '2026-06-19'), throwsArgumentError);
    });
  });

  group('CalendarDate', () {
    test('存在しない日付はエラー', () {
      expect(() => CalendarDate(2026, 2, 29), throwsArgumentError);
      expect(() => CalendarDate(2026, 13, 1), throwsArgumentError);
    });

    test('うるう日は作れる', () {
      expect(CalendarDate(2028, 2, 29).toIso(), '2028-02-29');
    });

    test('文字列との往復', () {
      expect(CalendarDate.parse('2026-06-20'), CalendarDate(2026, 6, 20));
      expect(() => CalendarDate.parse('2026/06/20'), throwsFormatException);
    });
  });
}
