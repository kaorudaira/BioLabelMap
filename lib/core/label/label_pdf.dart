import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/label/data_label_layout.dart';
import '../../domain/label/label_sheet.dart';
import 'font_text_measurer.dart';

/// ラベル用のフォント。PDF への埋め込みと幅の測定に同じファイルを使う。
class LabelFonts {
  LabelFonts({required ByteData latin, required ByteData japanese})
    : latinFont = pw.Font.ttf(latin),
      japaneseFont = pw.Font.ttf(japanese),
      measurer = FontTextMeasurer(latinFont: latin, japaneseFont: japanese);

  /// assets から読み込む。
  static Future<LabelFonts> load() async => LabelFonts(
    latin: await rootBundle.load('assets/fonts/FiraSansCondensed-Regular.ttf'),
    japanese: await rootBundle.load('assets/fonts/BIZUDPGothic-Regular.ttf'),
  );

  final pw.Font latinFont;
  final pw.Font japaneseFont;
  final FontTextMeasurer measurer;

  /// 欧文フォントを基本にし、字形が無い文字(かな・漢字)は和文フォントで描く。
  pw.TextStyle style(double sizePt) => pw.TextStyle(
    font: latinFont,
    fontFallback: [japaneseFont],
    fontSize: sizePt,
    lineSpacing: 0,
  );
}

/// ラベルの PDF を作る(要件定義 S-07)。ラベルPDFには地図を載せない。
Future<Uint8List> buildLabelPdf({
  required List<PlacedLabel> labels,
  required LabelFonts fonts,
  LabelSheetSpec sheet = LabelSheetSpec.postcard,
  DataLabelLayoutSpec dataSpec = const DataLabelLayoutSpec(),
  bool cutLines = true,
  double collectionLabelPt = 4,
}) async {
  const mm = PdfPageFormat.mm;
  final doc = pw.Document(title: 'BioLabelMap labels', creator: 'BioLabelMap');
  final format = PdfPageFormat(sheet.paperWidthMm * mm, sheet.paperHeightMm * mm, marginAll: 0);

  for (var start = 0; start < labels.length; start += sheet.perPage) {
    final page = labels.sublist(start, (start + sheet.perPage).clamp(0, labels.length));
    doc.addPage(
      pw.Page(
        pageFormat: format,
        build: (context) => pw.Stack(
          children: [
            for (var i = 0; i < page.length; i++)
              pw.Positioned(
                left: (sheet.marginXMm + (i % sheet.columns) * sheet.labelWidthMm) * mm,
                top: (sheet.marginYMm + (i ~/ sheet.columns) * sheet.labelHeightMm) * mm,
                child: pw.Container(
                  width: sheet.labelWidthMm * mm,
                  height: sheet.labelHeightMm * mm,
                  // 切り取り線は細い灰色の枠
                  decoration: cutLines
                      ? pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400, width: 0.2))
                      : null,
                  padding: pw.EdgeInsets.symmetric(
                    horizontal: dataSpec.paddingMm * mm,
                    vertical: dataSpec.verticalPaddingMm * mm,
                  ),
                  child: _labelContent(page[i], fonts, dataSpec, collectionLabelPt),
                ),
              ),
          ],
        ),
      ),
    );
  }
  return doc.save();
}

pw.Widget _labelContent(
  PlacedLabel label,
  LabelFonts fonts,
  DataLabelLayoutSpec spec,
  double collectionLabelPt,
) {
  switch (label.kind) {
    case LabelKind.data:
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          for (final line in label.specimen.dataLabel.lines)
            pw.SizedBox(
              height: line.fontSizePt * spec.lineHeightFactor,
              child: pw.Text(line.text, style: fonts.style(line.fontSizePt), maxLines: 1, softWrap: false),
            ),
        ],
      );
    case LabelKind.collection:
      // 標本番号の1行のみ。右と下は将来の QR コード用に空けておく
      return pw.Align(
        alignment: pw.Alignment.topLeft,
        child: pw.Text(label.specimen.catalogText, style: fonts.style(collectionLabelPt)),
      );
  }
}
