import 'data_label_layout.dart';
import 'identification_label.dart';

/// 用紙とラベルの寸法(要件定義 S-07「用紙とラベルの寸法」)。
/// 1ページの枚数は、用紙とラベルの寸法から自動で決める。
class LabelSheetSpec {
  const LabelSheetSpec({
    this.paperWidthMm = 100,
    this.paperHeightMm = 148,
    this.labelWidthMm = 15,
    this.labelHeightMm = 10,
    this.marginXMm = 5,
    this.marginYMm = 4,
  });

  /// はがき(100×148mm)、15×10mm、6列×14行=84枚。
  static const postcard = LabelSheetSpec();

  final double paperWidthMm;
  final double paperHeightMm;
  final double labelWidthMm;
  final double labelHeightMm;

  /// 左右・上下それぞれの余白。
  final double marginXMm;
  final double marginYMm;

  int get columns => ((paperWidthMm - marginXMm * 2) / labelWidthMm).floor();
  int get rows => ((paperHeightMm - marginYMm * 2) / labelHeightMm).floor();
  int get perPage => columns * rows;

  int pagesFor(int labelCount) => labelCount == 0 ? 0 : (labelCount / perPage).ceil();
}

/// ラベルの種類。
enum LabelKind { data, identification, collection }

/// 印刷単位(要件定義 第5章「印刷」)。
enum LabelUnit {
  /// データラベルとコレクションラベル。
  dataAndCollection('データ+コレクション'),

  /// 同定ラベルだけ。
  identificationOnly('同定のみ'),

  /// データ・同定・コレクションの3種すべて。
  all('3種すべて');

  const LabelUnit(this.label);
  final String label;

  bool get hasData => this != identificationOnly;
  bool get hasCollection => this != identificationOnly;
  bool get hasIdentification => this != dataAndCollection;
}

/// 並べ方(要件定義 第5章「印刷」)。
enum LabelArrangement {
  /// 標本ごとに並べる(取り違え防止)。データ・コレクション・同定のラベルが隣り合う。
  bySpecimen,

  /// 種類ごとにまとめる(データラベルをすべて、次にコレクションラベルをすべて、次に同定ラベルをすべて)。
  byKind,
}

/// 印刷する標本1件分の材料。
class SpecimenLabels {
  const SpecimenLabels({
    required this.specimenId,
    required this.catalogText,
    required this.dataLabel,
    this.identificationLabel,
  });

  final int specimenId;

  /// コレクションラベルに印字する標本番号(`KYC00123`)。
  final String catalogText;

  /// 割り付け済みのデータラベル。
  final DataLabelLayout dataLabel;

  /// 割り付け済みの同定ラベル。未同定の標本は null(同定ラベルは出さない)。
  final IdentificationLabelLayout? identificationLabel;
}

/// 用紙に置く1枚。
class PlacedLabel {
  const PlacedLabel(this.kind, this.specimen);

  final LabelKind kind;
  final SpecimenLabels specimen;
}

/// ラベルを並べる順に並べる。標本は呼び出し側で標本番号順にしておく
/// (同地点・同日の標本は、同じデータラベルと連番のコレクションラベルが並ぶ)。
/// 同定ラベルは、同定した標本の分だけ並べる(未同定の標本には出さない)。
List<PlacedLabel> arrangeLabels(
  List<SpecimenLabels> specimens,
  LabelArrangement arrangement, {
  LabelUnit unit = LabelUnit.dataAndCollection,
}) {
  List<PlacedLabel> of(LabelKind kind, Iterable<SpecimenLabels> list) => [for (final s in list) PlacedLabel(kind, s)];
  final identified = [for (final s in specimens) if (s.identificationLabel != null) s];
  return switch (arrangement) {
    LabelArrangement.bySpecimen => [
      for (final s in specimens) ...[
        if (unit.hasData) PlacedLabel(LabelKind.data, s),
        if (unit.hasCollection) PlacedLabel(LabelKind.collection, s),
        if (unit.hasIdentification && s.identificationLabel != null) PlacedLabel(LabelKind.identification, s),
      ],
    ],
    LabelArrangement.byKind => [
      if (unit.hasData) ...of(LabelKind.data, specimens),
      if (unit.hasCollection) ...of(LabelKind.collection, specimens),
      if (unit.hasIdentification) ...of(LabelKind.identification, identified),
    ],
  };
}
