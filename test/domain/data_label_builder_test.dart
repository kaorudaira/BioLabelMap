import 'package:biolabelmap/domain/elevation_rounding.dart';
import 'package:biolabelmap/domain/label/collector_name_format.dart';
import 'package:biolabelmap/domain/label/data_label_builder.dart';
import 'package:biolabelmap/domain/locality_key.dart';
import 'package:biolabelmap/domain/models/calendar_date.dart';
import 'package:biolabelmap/domain/models/collection_period.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 要件定義 第5章の例
  final example = DataLabelSource(
    prefectureEn: 'Niigata-ken',
    municipalityEn: 'Uonuma-shi',
    localityEn: 'Shimooritate',
    elevationMeters: 1390,
    latitude: 36.94471,
    longitude: 139.24262,
    period: CollectionPeriod.singleDay(CalendarDate(2026, 6, 20)),
    collector: 'K. YOSHIHARA',
    municipalityJa: '魚沼市',
    localityJa: '下折立',
  );

  group('buildDataLabel', () {
    test('改行は、県・詳細住所の最後・標高・緯度経度・日付と採集者の後', () {
      expect(buildDataLabel(example), const [
        DataLabelLine('JAPAN: Niigata-ken', DataLabelLineRole.header),
        DataLabelLine('Uonuma-shi, Shimooritate', DataLabelLineRole.address),
        DataLabelLine('(alt. 1390 m)', DataLabelLineRole.elevation),
        DataLabelLine('36.9447°N 139.2426°E', DataLabelLineRole.body),
        DataLabelLine('20. VI. 2026, K. YOSHIHARA', DataLabelLineRole.body),
        DataLabelLine('魚沼市下折立', DataLabelLineRole.japanese),
      ]);
    });

    test('1行にまとめると要件定義の書式例と一致する', () {
      expect(
        dataLabelAsSingleLine(buildDataLabel(example)),
        'JAPAN: Niigata-ken, Uonuma-shi, Shimooritate, (alt. 1390 m), '
        '36.9447°N 139.2426°E, 20. VI. 2026, K. YOSHIHARA, 魚沼市下折立',
      );
    });

    test('郡・市町村・大字は、ひと続きの詳細住所にする', () {
      final lines = buildDataLabel(DataLabelSource(
        prefectureEn: 'Niigata-ken',
        countyEn: 'Minamiuonuma-gun',
        municipalityEn: 'Yuzawa-machi',
        localityEn: 'Tsuchitaru',
        elevationMeters: 700,
        latitude: 36.8834,
        longitude: 138.8205,
        period: CollectionPeriod.singleDay(CalendarDate(2026, 7, 5)),
        collector: 'K. YOSHIHARA',
        countyJa: '南魚沼郡',
        municipalityJa: '湯沢町',
        localityJa: '土樽',
      ));
      expect(lines, hasLength(6));
      expect(lines[1], const DataLabelLine(
          'Minamiuonuma-gun, Yuzawa-machi, Tsuchitaru', DataLabelLineRole.address));
      expect(lines.last, const DataLabelLine(
          '南魚沼郡湯沢町土樽', DataLabelLineRole.japanese));
      expect(
        dataLabelAsSingleLine(lines),
        'JAPAN: Niigata-ken, Minamiuonuma-gun, Yuzawa-machi, Tsuchitaru, '
        '(alt. 700 m), 36.8834°N 138.8205°E, 5. VII. 2026, K. YOSHIHARA, '
        '南魚沼郡湯沢町土樽',
      );
    });

    test('標高・地名が補完待ち(null)なら行ごと省き、空欄を残さない', () {
      final lines = buildDataLabel(DataLabelSource(
        latitude: 36.9447,
        longitude: 139.2426,
        period: CollectionPeriod.singleDay(CalendarDate(2026, 6, 20)),
        collector: 'K. YOSHIHARA',
      ));
      expect(lines.map((l) => l.text), [
        'JAPAN',
        '36.9447°N 139.2426°E',
        '20. VI. 2026, K. YOSHIHARA',
      ]);
    });

    test('空白だけの値も未入力として扱う', () {
      final lines = buildDataLabel(DataLabelSource(
        prefectureEn: 'Niigata-ken',
        municipalityEn: 'Uonuma-shi',
        localityEn: '  ',
        latitude: 36.9447,
        longitude: 139.2426,
        period: CollectionPeriod.singleDay(CalendarDate(2026, 6, 20)),
        collector: '',
        municipalityJa: '魚沼市',
      ));
      expect(lines.map((l) => l.text), [
        'JAPAN: Niigata-ken',
        'Uonuma-shi',
        '36.9447°N 139.2426°E',
        '20. VI. 2026',
        '魚沼市',
      ]);
    });

    test('期間は第5章の書式で入る', () {
      final lines = buildDataLabel(DataLabelSource(
        latitude: 36.9447,
        longitude: 139.2426,
        period: CollectionPeriod(
            CalendarDate(2026, 5, 30), CalendarDate(2026, 6, 2)),
        collector: 'K. YOSHIHARA',
      ));
      expect(lines.last.text, '30. V.-2. VI. 2026, K. YOSHIHARA');
    });

    test('マクロン付きの地名をそのまま出す', () {
      final lines = buildDataLabel(DataLabelSource(
        prefectureEn: 'Tōkyō-to',
        latitude: 35.6812,
        longitude: 139.7671,
        period: CollectionPeriod.singleDay(CalendarDate(2026, 6, 20)),
      ));
      expect(lines.first.text, 'JAPAN: Tōkyō-to');
    });
  });

  group('DataLabelStyle', () {
    test('既定の文字サイズは 4 / 3 / 3.5 pt', () {
      const style = DataLabelStyle();
      expect(style.sizeOf(DataLabelLineRole.header), 4);
      expect(style.sizeOf(DataLabelLineRole.address), 3);
      expect(style.sizeOf(DataLabelLineRole.body), 3);
      expect(style.sizeOf(DataLabelLineRole.japanese), 3.5);
    });

    test('詳細住所(郡と市町村・大字・日本語の地名)だけを1段階(0.5pt)小さくする', () {
      final reduced = const DataLabelStyle().withReducedDetailAddress();
      expect(reduced.sizeOf(DataLabelLineRole.header), 4);
      expect(reduced.sizeOf(DataLabelLineRole.address), 2.5);
      expect(reduced.sizeOf(DataLabelLineRole.body), 3);
      expect(reduced.sizeOf(DataLabelLineRole.japanese), 3);
    });
  });

  group('formatCoordinates', () {
    test('小数4桁で切り捨てる(四捨五入しない)', () {
      expect(formatCoordinates(36.94479, 139.24259), '36.9447°N 139.2425°E');
    });

    test('同一地点の判定(LocalityKey)と同じ値になる', () {
      final key = LocalityKey.fromCoordinates(36.94479, 139.24259);
      expect(key, const LocalityKey(369447, 1392425));
    });

    test('小数部のゼロを埋める', () {
      expect(formatCoordinates(35.0005, 139.05), '35.0005°N 139.0500°E');
    });

    test('南緯・西経は 0 の方向へ切り捨てる', () {
      expect(formatCoordinates(-12.34569, -45.25), '12.3456°S 45.2500°W');
    });
  });

  group('formatCollectorName', () {
    test('名 姓 → 頭文字+大文字の姓', () {
      expect(formatCollectorName('Kaoru Yoshihara'), 'K. YOSHIHARA');
    });

    test('頭文字で入力済みなら姓だけ大文字にする', () {
      expect(formatCollectorName('K. Yoshihara'), 'K. YOSHIHARA');
    });

    test('余分な空白を無視する', () {
      expect(formatCollectorName('  Kaoru   Yoshihara '), 'K. YOSHIHARA');
    });

    test('1語だけなら大文字にする', () {
      expect(formatCollectorName('Yoshihara'), 'YOSHIHARA');
    });

    test('マクロン付きの姓も大文字にする', () {
      expect(formatCollectorName('Taro Ōno'), 'T. ŌNO');
    });
  });

  group('ElevationRounding', () {
    test('10m で四捨五入', () {
      expect(ElevationRounding.tenMeters.apply(1385), 1390);
      expect(ElevationRounding.tenMeters.apply(1384.9), 1380);
    });

    test('1m で四捨五入', () {
      expect(ElevationRounding.oneMeter.apply(1384.5), 1385);
      expect(ElevationRounding.oneMeter.apply(1384.4), 1384);
    });
  });

  group('LocalityKey', () {
    test('切り捨てて小数4桁が同じなら同じ地点', () {
      expect(LocalityKey.fromCoordinates(36.94470, 139.24260),
          LocalityKey.fromCoordinates(36.94479, 139.24269));
    });

    test('切り捨てて小数4桁が異なれば別の地点(四捨五入なら同じになる値)', () {
      expect(LocalityKey.fromCoordinates(36.94469, 139.2426),
          isNot(LocalityKey.fromCoordinates(36.94471, 139.2426)));
    });

    test('2進数の誤差で桁を落とさない', () {
      // 0.0003 * 10000 は 2.9999… になり、単純な truncate では 2 になる
      expect(LocalityKey.truncateE4(0.0003), 3);
      expect(LocalityKey.truncateE4(36.9447), 369447);
      expect(LocalityKey.truncateE4(35.0005), 350005);
    });

    test('整数・小数1桁・負の値・ごく小さい値', () {
      expect(LocalityKey.truncateE4(139.0), 1390000);
      expect(LocalityKey.truncateE4(43.1), 431000);
      expect(LocalityKey.truncateE4(-12.34569), -123456);
      expect(LocalityKey.truncateE4(1e-7), 0);
    });
  });
}
