import 'data_label_layout.dart';

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

/// ラベルの種類。同定ラベルは段階3で加える。
enum LabelKind { data, collection }

/// 並べ方(要件定義 第5章「印刷」)。
enum LabelArrangement {
  /// 標本ごとに並べる(取り違え防止)。データラベルとコレクションラベルが隣り合う。
  bySpecimen,

  /// 種類ごとにまとめる(データラベルをすべて、次にコレクションラベルをすべて)。
  byKind,
}

/// 印刷する標本1件分の材料。
class SpecimenLabels {
  const SpecimenLabels({
    required this.specimenId,
    required this.catalogText,
    required this.dataLabel,
  });

  final int specimenId;

  /// コレクションラベルに印字する標本番号(`KYC00123`)。
  final String catalogText;

  /// 割り付け済みのデータラベル。
  final DataLabelLayout dataLabel;
}

/// 用紙に置く1枚。
class PlacedLabel {
  const PlacedLabel(this.kind, this.specimen);

  final LabelKind kind;
  final SpecimenLabels specimen;
}

/// ラベルを並べる順に並べる。標本は呼び出し側で標本番号順にしておく
/// (同地点・同日の標本は、同じデータラベルと連番のコレクションラベルが並ぶ)。
List<PlacedLabel> arrangeLabels(List<SpecimenLabels> specimens, LabelArrangement arrangement) =>
    switch (arrangement) {
      LabelArrangement.bySpecimen => [
        for (final s in specimens) ...[
          PlacedLabel(LabelKind.data, s),
          PlacedLabel(LabelKind.collection, s),
        ],
      ],
      LabelArrangement.byKind => [
        for (final s in specimens) PlacedLabel(LabelKind.data, s),
        for (final s in specimens) PlacedLabel(LabelKind.collection, s),
      ],
    };
