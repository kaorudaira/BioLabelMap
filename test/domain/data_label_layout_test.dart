import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:biolabelmap/core/label/font_text_measurer.dart';
import 'package:biolabelmap/domain/label/data_label_builder.dart';
import 'package:biolabelmap/domain/label/data_label_layout.dart';
import 'package:biolabelmap/domain/models/calendar_date.dart';
import 'package:biolabelmap/domain/models/collection_period.dart';
import 'package:flutter_test/flutter_test.dart';

/// 1文字 = 文字サイズの 0.5 倍(pt)。改行の動きを数えやすくするためのテスト用。
/// 3pt の1文字 = 1.5pt、2.5pt = 1.25pt、3.5pt = 1.75pt、4pt = 2pt。
class _HalfEmMeasurer implements TextMeasurer {
  const _HalfEmMeasurer();

  @override
  double widthOf(String text, double fontSizePt) =>
      text.runes.length * fontSizePt * 0.5;
}

/// 改行する幅(wrapWidthPt)が [wrapPt] になる寸法。
/// wrapWidthPt = (幅 - 余白×2) × ptPerMm × 0.9 なので、余白0として幅を逆算する。
DataLabelLayoutSpec specWrapAt(double wrapPt) =>
    DataLabelLayoutSpec(labelWidthMm: wrapPt / 0.9 / ptPerMm, paddingMm: 0);

/// 改行する幅を「3pt の文字で N 文字ぶん」にする。
DataLabelLayoutSpec specFor3ptChars(int chars) => specWrapAt(chars * 1.5 + 0.01);

DataLabelLine japanese(List<String> segments) => DataLabelLine(
  segments.join(),
  DataLabelLineRole.japanese,
  segments: segments,
);

void main() {
  const measurer = _HalfEmMeasurer();

  DataLabelLayout layout(
    List<DataLabelLine> lines,
    DataLabelLayoutSpec spec, {
    bool allowOmitJapanese = true,
  }) => layoutDataLabel(
    lines,
    spec: spec,
    measurer: measurer,
    allowOmitJapanese: allowOmitJapanese,
  );

  List<String> texts(DataLabelLayout l) => l.lines.map((x) => x.text).toList();

  group('欧文の改行', () {
    test('幅に収まる行は改行しない', () {
      final result = layout(
        const [DataLabelLine('Uonuma-shi', DataLabelLineRole.address)],
        specFor3ptChars(20),
      );
      expect(texts(result), ['Uonuma-shi']);
      expect(result.detailAddressReduced, isFalse);
      expect(result.overflows, isFalse);
    });

    test('「, 」の後ろで改行し、行末のカンマは残す', () {
      final result = layout(
        const [DataLabelLine('Minamiuonuma-gun, Yuzawa-machi', DataLabelLineRole.address)],
        specFor3ptChars(20),
      );
      expect(texts(result), ['Minamiuonuma-gun,', 'Yuzawa-machi']);
    });

    test('空白より「, 」を優先して切る(日付と採集者を分ける)', () {
      // 空白で詰めると「30. V.-2. VI. 2026, K.」/「YOSHIHARA」になるところ
      final result = layout(
        const [DataLabelLine('30. V.-2. VI. 2026, K. YOSHIHARA', DataLabelLineRole.body)],
        specFor3ptChars(22),
      );
      expect(texts(result), ['30. V.-2. VI. 2026,', 'K. YOSHIHARA']);
    });

    test('「, 」が無ければ空白で切る(緯度と経度)', () {
      final result = layout(
        const [DataLabelLine('36.9447°N 139.2426°E', DataLabelLineRole.body)],
        specFor3ptChars(12),
      );
      expect(texts(result), ['36.9447°N', '139.2426°E']);
    });

    test('1語で幅を超えるときは、ハイフンの後ろで切る', () {
      final result = layout(
        const [DataLabelLine('Higashishirakawa-gun, Yamatsuri-machi', DataLabelLineRole.address)],
        specFor3ptChars(17),
      );
      expect(texts(result), ['Higashishirakawa-', 'gun,', 'Yamatsuri-machi']);
      expect(result.overflows, isFalse);
    });
  });

  group('日本語の地名', () {
    test('1行に入れば、そのまま', () {
      final result = layout([japanese(['南魚沼郡', '湯沢町', '土樽'])], specWrapAt(9 * 1.75 + 0.01));
      expect(texts(result), ['南魚沼郡湯沢町土樽']);
      expect(result.droppedJapaneseSegments, isEmpty);
    });

    test('1行に入らなければ、一番大きい行政区画(郡)を省く。改行はしない', () {
      final result = layout([japanese(['南魚沼郡', '湯沢町', '土樽'])], specWrapAt(7 * 1.75 + 0.01));
      expect(texts(result), ['湯沢町土樽']);
      expect(result.droppedJapaneseSegments, ['南魚沼郡']);
      expect(result.detailAddressReduced, isFalse);
    });

    test('郡を省いても入らなければ、次に大きい市町村も省く', () {
      final result = layout([japanese(['南魚沼郡', '湯沢町', '土樽'])], specWrapAt(4 * 1.75 + 0.01));
      expect(texts(result), ['土樽']);
      expect(result.droppedJapaneseSegments, ['南魚沼郡', '湯沢町']);
    });

    test('郡が無い市は、市を省く', () {
      final result = layout([japanese(['魚沼市', '下折立'])], specWrapAt(4 * 1.75 + 0.01));
      expect(texts(result), ['下折立']);
      expect(result.droppedJapaneseSegments, ['魚沼市']);
    });

    test('最後の1区画も入らないときは、文字を1段階小さくする', () {
      // 3.5pt では 5文字(8.75pt)が入らず、3pt(7.5pt)なら入る
      final result = layout([japanese(['魚沼市', '大字下折立'])], specWrapAt(8.0));
      expect(result.detailAddressReduced, isTrue);
      expect(result.lines.single, const PlacedLabelLine('大字下折立', DataLabelLineRole.japanese, 3));
      expect(result.japaneseOmitted, isFalse);
    });
  });

  group('7行に収まらないとき', () {
    // 郡と市町村が改行され、全体が8行になる例
    List<DataLabelLine> eightLinesWhenWrapped() => List.of([
      const DataLabelLine('JAPAN: Niigata-ken', DataLabelLineRole.header),
      const DataLabelLine('Minamiuonuma-gun, Yuzawa-machi', DataLabelLineRole.address),
      const DataLabelLine('Tsuchitaru', DataLabelLineRole.address),
      const DataLabelLine('(alt. 700 m)', DataLabelLineRole.body),
      const DataLabelLine('36.8834°N', DataLabelLineRole.body),
      const DataLabelLine('5. VII. 2026', DataLabelLineRole.body),
      japanese(['南魚沼郡', '湯沢町', '土樽']),
    ]);

    test('詳細住所を1段階小さくして、7行に収める', () {
      // 3pt なら 26 文字、2.5pt なら 31.2 文字まで1行に入る
      final result = layout(eightLinesWhenWrapped(), specFor3ptChars(26));
      expect(result.detailAddressReduced, isTrue);
      expect(result.japaneseOmitted, isFalse);
      expect(result.overflows, isFalse);
      expect(result.lines, hasLength(7));
      expect(
        result.lines[1],
        const PlacedLabelLine('Minamiuonuma-gun, Yuzawa-machi', DataLabelLineRole.address, 2.5),
      );
      // 詳細住所以外の文字サイズは変えない
      expect(result.lines[0].fontSizePt, 4);
      expect(result.lines[3].fontSizePt, 3);
      expect(result.lines.last.fontSizePt, 3);
    });

    test('7行に収まるなら小さくしない', () {
      final lines = eightLinesWhenWrapped()..removeAt(2); // 大字なし → 改行しても7行
      final result = layout(lines, specFor3ptChars(26));
      expect(result.detailAddressReduced, isFalse);
      expect(result.lines, hasLength(7));
      expect(result.lines[1].text, 'Minamiuonuma-gun,');
      expect(result.lines[1].fontSizePt, 3);
    });

    test('1段階小さくしても収まらないときは、日本語の地名を省く(確認が要る)', () {
      // 2.5pt でも郡と市町村が2行に分かれ(37.5pt > 36pt)、8行になる。1行目は入る(36pt)
      final result = layout(eightLinesWhenWrapped(), specFor3ptChars(24));
      expect(result.detailAddressReduced, isTrue);
      expect(result.japaneseOmitted, isTrue);
      expect(result.overflows, isFalse);
      expect(result.lines, hasLength(7));
      expect(result.lines.any((l) => l.role == DataLabelLineRole.japanese), isFalse);
    });

    test('省くことを断られたら、日本語の地名を残して警告を立てる', () {
      final result = layout(eightLinesWhenWrapped(), specFor3ptChars(24),
          allowOmitJapanese: false);
      expect(result.japaneseOmitted, isFalse);
      expect(result.overflows, isTrue);
      expect(result.lines.last.role, DataLabelLineRole.japanese);
    });

    test('日本語の地名を省いても収まらないなら、省かずに警告を立てる', () {
      final result = layout(eightLinesWhenWrapped(), specFor3ptChars(10));
      expect(result.japaneseOmitted, isFalse);
      expect(result.overflows, isTrue);
    });

    test('切れない長い語が枠からはみ出すときも、警告を立てる', () {
      final result = layout(
        const [DataLabelLine('Chihayaakasakamura', DataLabelLineRole.address)],
        specFor3ptChars(8),
      );
      expect(result.overflows, isTrue);
    });
  });

  group('同梱フォント(Fira Sans Condensed)の寸法で、既定の 15mm ラベル', () {
    final fira = FontTextMeasurer(ByteData.sublistView(
      File('assets/fonts/FiraSansCondensed-Regular.ttf').readAsBytesSync(),
    ));

    DataLabelLayout layoutDefault(DataLabelSource source) =>
        layoutDataLabel(buildDataLabel(source), measurer: fira);

    DataLabelSource inPrefecture(String prefectureEn) => DataLabelSource(
      prefectureEn: prefectureEn,
      municipalityEn: 'Uonuma-shi',
      latitude: 36.9447,
      longitude: 139.2426,
      period: CollectionPeriod.singleDay(CalendarDate(2026, 6, 20)),
      collector: 'K. YOSHIHARA',
    );

    // Fira Sans Condensed の 4pt で、改行する幅(35.72pt)を超える県
    const longPrefectures = [
      'Kagoshima-ken', 'Yamanashi-ken', 'Kumamoto-ken', 'Yamaguchi-ken',
      'Tokushima-ken', 'Fukushima-ken', 'Wakayama-ken', 'Hiroshima-ken',
    ];

    test('長い県名のときだけ、1行目を1段階(3.5pt)小さくして1行に収める', () {
      for (final pref in longPrefectures) {
        final result = layoutDefault(inPrefecture(pref));
        expect(result.lines.first,
            PlacedLabelLine('JAPAN: $pref', DataLabelLineRole.header, 3.5), reason: pref);
        expect(result.headerReduced, isTrue, reason: pref);
      }
    });

    test('ほかの県は 4pt のまま', () {
      final json = jsonDecode(File('assets/data/municipalities.json').readAsStringSync())
          as Map<String, dynamic>;
      final others = json.values
          .map((v) => v['prefEn'] as String)
          .toSet()
          .difference(longPrefectures.toSet());
      expect(others, hasLength(47 - longPrefectures.length));
      for (final pref in others) {
        final result = layoutDefault(inPrefecture(pref));
        expect(result.lines.first.fontSizePt, 4, reason: pref);
        expect(result.headerReduced, isFalse, reason: pref);
      }
    });

    test('要件定義の例(魚沼市)は改行せず7行', () {
      final result = layoutDefault(DataLabelSource(
        prefectureEn: 'Niigata-ken',
        municipalityEn: 'Uonuma-shi',
        localityEn: 'Shimooritate',
        elevationMeters: 1390,
        latitude: 36.9447,
        longitude: 139.2426,
        period: CollectionPeriod.singleDay(CalendarDate(2026, 6, 20)),
        collector: 'K. YOSHIHARA',
        municipalityJa: '魚沼市',
        localityJa: '下折立',
      ));
      expect(result.lines, hasLength(7));
      expect(result.detailAddressReduced, isFalse);
      expect(result.japaneseOmitted, isFalse);
      expect(result.overflows, isFalse);
    });

    test('郡が付いて長い行は、改行すると8行になるので、詳細住所を小さくして1行に戻す', () {
      // Nakauonuma-gun, Tsunan-machi: 3pt で 40.6pt(改行)、2.5pt で 33.8pt(1行)
      final result = layoutDefault(DataLabelSource(
        prefectureEn: 'Niigata-ken',
        countyEn: 'Nakauonuma-gun',
        municipalityEn: 'Tsunan-machi',
        localityEn: 'Akiyamagō',
        elevationMeters: 700,
        latitude: 36.8834,
        longitude: 138.6205,
        period: CollectionPeriod.singleDay(CalendarDate(2026, 7, 5)),
        collector: 'K. YOSHIHARA',
        countyJa: '中魚沼郡',
        municipalityJa: '津南町',
        localityJa: '秋山郷',
      ));
      expect(result.detailAddressReduced, isTrue);
      expect(result.japaneseOmitted, isFalse);
      expect(result.overflows, isFalse);
      expect(result.lines, hasLength(7));
      expect(result.lines[1],
          const PlacedLabelLine('Nakauonuma-gun, Tsunan-machi', DataLabelLineRole.address, 2.5));
    });

    test('2.5pt でも郡と市町村が1行に入らないときは、日本語の地名を省く(確認が要る)', () {
      // Minamiuonuma-gun, Yuzawa-machi: 2.5pt で 36.4pt(改行する幅 35.7pt を超える)
      final result = layoutDefault(DataLabelSource(
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
      expect(result.japaneseOmitted, isTrue);
      expect(result.overflows, isFalse);
      expect(result.lines.map((l) => l.text), [
        'JAPAN: Niigata-ken',
        'Minamiuonuma-gun,',
        'Yuzawa-machi',
        'Tsuchitaru',
        '(alt. 700 m)',
        '36.8834°N 138.8205°E',
        '5. VII. 2026, K. YOSHIHARA',
      ]);
    });
  });
}
