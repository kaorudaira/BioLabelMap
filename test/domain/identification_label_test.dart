import 'dart:io';
import 'dart:typed_data';

import 'package:biolabelmap/core/label/font_text_measurer.dart';
import 'package:biolabelmap/domain/label/data_label_builder.dart';
import 'package:biolabelmap/domain/label/data_label_layout.dart';
import 'package:biolabelmap/domain/label/identification_label.dart';
import 'package:biolabelmap/domain/label/label_sheet.dart';
import 'package:biolabelmap/domain/models/calendar_date.dart';
import 'package:biolabelmap/domain/models/collection_period.dart';
import 'package:biolabelmap/domain/species_name.dart';
import 'package:flutter_test/flutter_test.dart';

/// 全角は1em、半角は0.5em。イタリック体も同じ幅。
class _Measurer implements StyledTextMeasurer {
  @override
  double widthOf(String text, double pt) => text.runes.fold(0.0, (s, r) => s + (r > 0x2FF ? 1 : 0.5)) * pt;

  @override
  double italicWidthOf(String text, double pt) => widthOf(text, pt);
}

ByteData _font(String name) => ByteData.sublistView(File('assets/fonts/$name').readAsBytesSync());

void main() {
  final measurer = _Measurer();
  final sericea = SpeciesName(
    vernacular: 'スゲハムシ',
    genus: 'Plateumaris',
    species: 'sericea',
    authorship: '(Linnaeus 1761)',
  );

  group('語の並び', () {
    test('和名・学名(イタリック体)・命名者・年・det. 同定者の順', () {
      final words = identificationLabelWords(IdentificationLabelSource(name: sericea, identifiedBy: 'K. Yoshihara'));
      expect(words.map((w) => w.toString()).join(' '), 'スゲハムシ /Plateumaris/ /sericea/ (Linnaeus 1761) det. K. Yoshihara');
    });

    test('命名者・年は、括弧の有無を含めて入力どおり', () {
      final w = identificationLabelWords(
        IdentificationLabelSource(name: SpeciesName(genus: 'A', species: 'b', authorship: 'Lewis, 1883')),
      );
      expect(w.map((r) => r.text), ['A', 'b', 'Lewis,', '1883']);
    });

    test('同定者が空なら、det. ごと省く。和名は任意', () {
      final w = identificationLabelWords(
        IdentificationLabelSource(name: SpeciesName(genus: 'A', species: 'b'), identifiedBy: '  '),
      );
      expect(w.map((r) => r.text), ['A', 'b']);
    });

    test('和名の注記(全角の空白)は、語の区切りにする。亜種はイタリック体で並ぶ', () {
      final w = identificationLabelWords(
        IdentificationLabelSource(
          name: SpeciesName(vernacular: 'ワモン　屋久島亜種', genus: 'S', species: 'lewisi', subspecies: 'albidus'),
        ),
      );
      expect(w.map((r) => r.toString()), ['ワモン', '屋久島亜種', '/S/', '/lewisi/', '/albidus/']);
    });

    test('未同定(和名も学名も無い)はラベルにしない。命名者だけでも作らない', () {
      expect(IdentificationLabelSource(name: SpeciesName.unidentified).isLabelable, isFalse);
      expect(IdentificationLabelSource(name: SpeciesName(authorship: 'Lewis, 1883')).isLabelable, isFalse);
      expect(IdentificationLabelSource(name: SpeciesName(vernacular: 'オサムシ')).isLabelable, isTrue);
    });
  });

  group('割り付け', () {
    test('3.5pt で収まれば、そのまま。学名だけがイタリック体の並びになる', () {
      final layout = layoutIdentificationLabel(
        IdentificationLabelSource(name: SpeciesName(vernacular: 'ア', genus: 'B', species: 'c', authorship: 'D, 1900')),
        measurer: measurer,
      );
      expect(layout.fontSizePt, 3.5);
      expect(layout.overflows, isFalse);
      expect(layout.lines, hasLength(1));
      expect(layout.lines.single.map((r) => r.toString()), ['ア', '/ B c/', ' D, 1900']);
    });

    test('幅に入らなければ、語の区切りで改行する', () {
      final layout = layoutIdentificationLabel(
        IdentificationLabelSource(name: SpeciesName(genus: 'Plateumaris', species: 'sericea', authorship: '(Linnaeus 1761)')),
        measurer: measurer,
      );
      expect(layout.lines.length, greaterThan(1));
      // どの行も、使える幅を超えない
      for (final line in layout.lines) {
        final w = line.fold(0.0, (s, r) => s + measurer.widthOf(r.text, layout.fontSizePt));
        expect(w, lessThanOrEqualTo(const DataLabelLayoutSpec().wrapWidthPt + 1e-6));
      }
      expect(layout.plainText.replaceAll('\n', ' '), 'Plateumaris sericea (Linnaeus 1761)');
    });

    test('1語が幅に入らないときは、文字の途中で折り返す', () {
      final layout = layoutIdentificationLabel(
        IdentificationLabelSource(name: SpeciesName(vernacular: 'カラカネナカボソタマムシ')),
        measurer: measurer,
      );
      expect(layout.lines.length, greaterThan(1));
      expect(layout.lines.map((l) => l.map((r) => r.text).join()).join(), 'カラカネナカボソタマムシ');
    });

    test('行が増えて高さに収まらないときは、文字を0.5ptずつ小さくする', () {
      // 全角62字は、3.5ptだと7行(高さに収まらない)、3.0ptだと6行で収まる
      final layout = layoutIdentificationLabel(
        IdentificationLabelSource(name: SpeciesName(vernacular: 'あ' * 62)),
        measurer: measurer,
      );
      expect(layout.fontSizePt, 3.0);
      expect(layout.overflows, isFalse);
      expect(layout.lines, hasLength(6));
      const spec = DataLabelLayoutSpec();
      expect(layout.lines.length * layout.fontSizePt * spec.lineHeightFactor, lessThanOrEqualTo(spec.contentHeightPt));
    });

    test('2.5ptでも収まらなければ、はみ出しの警告を立てる', () {
      final layout = layoutIdentificationLabel(
        IdentificationLabelSource(
          name: SpeciesName(vernacular: 'あ' * 200, genus: 'A', species: 'b'),
          identifiedBy: 'x',
        ),
        measurer: measurer,
      );
      expect(layout.fontSizePt, 2.5);
      expect(layout.overflows, isTrue);
    });
  });

  group('実際のフォントで測る', () {
    final fira = FontTextMeasurer(
      latinFont: _font('FiraSansCondensed-Regular.ttf'),
      latinItalicFont: _font('FiraSansCondensed-Italic.ttf'),
      japaneseFont: _font('BIZUDPGothic-Regular.ttf'),
    );

    test('要件定義の例(スゲハムシ)は、枠に収まる', () {
      final layout = layoutIdentificationLabel(
        IdentificationLabelSource(name: sericea, identifiedBy: 'K. Yoshihara'),
        measurer: fira,
      );
      expect(layout.overflows, isFalse);
      expect(layout.plainText.replaceAll('\n', ' '), 'スゲハムシ Plateumaris sericea (Linnaeus 1761) det. K. Yoshihara');
    });

    test('イタリック体のフォントで測る(立体と幅が違う)', () {
      expect(fira.italicWidthOf('Plateumaris sericea', 3.5), isNot(fira.widthOf('Plateumaris sericea', 3.5)));
    });

    test('イタリック体のフォントが無ければ、立体で測る', () {
      final plain = FontTextMeasurer(
        latinFont: _font('FiraSansCondensed-Regular.ttf'),
        japaneseFont: _font('BIZUDPGothic-Regular.ttf'),
      );
      expect(plain.italicWidthOf('Carabus', 3.5), plain.widthOf('Carabus', 3.5));
    });

    test('マクロンを含む命名者も測れる', () {
      expect(fira.widthOf('Ōmu', 3), greaterThan(0));
    });
  });

  group('並べ方', () {
    final data = layoutDataLabel(
      buildDataLabel(DataLabelSource(
        latitude: 36.9,
        longitude: 139.2,
        period: CollectionPeriod.singleDay(CalendarDate(2026, 6, 20)),
      )),
      measurer: measurer,
    );
    final id = layoutIdentificationLabel(IdentificationLabelSource(name: sericea), measurer: measurer);
    // K2 は未同定
    final specimens = [
      SpecimenLabels(specimenId: 1, catalogText: 'K1', dataLabel: data, identificationLabel: id),
      SpecimenLabels(specimenId: 2, catalogText: 'K2', dataLabel: data),
      SpecimenLabels(specimenId: 3, catalogText: 'K3', dataLabel: data, identificationLabel: id),
    ];
    List<String> run(LabelArrangement a, LabelUnit u) =>
        arrangeLabels(specimens, a, unit: u).map((l) => '${l.kind.name[0]}${l.specimen.catalogText}').toList();

    test('既定(データ+コレクション)は、同定ラベルを含めない', () {
      expect(arrangeLabels(specimens, LabelArrangement.bySpecimen).length, 6);
    });

    test('3種すべて・標本ごと:データ、同定、コレクションの順。未同定の標本には同定ラベルが無い', () {
      expect(run(LabelArrangement.bySpecimen, LabelUnit.all), [
        'dK1', 'iK1', 'cK1', //
        'dK2', 'cK2',
        'dK3', 'iK3', 'cK3',
      ]);
    });

    test('3種すべて・種類ごと:データ、同定、コレクションの順にまとめる', () {
      expect(run(LabelArrangement.byKind, LabelUnit.all), [
        'dK1', 'dK2', 'dK3', //
        'iK1', 'iK3',
        'cK1', 'cK2', 'cK3',
      ]);
    });

    test('同定のみ:同定した標本の同定ラベルだけ', () {
      expect(run(LabelArrangement.bySpecimen, LabelUnit.identificationOnly), ['iK1', 'iK3']);
      expect(run(LabelArrangement.byKind, LabelUnit.identificationOnly), ['iK1', 'iK3']);
    });
  });
}
