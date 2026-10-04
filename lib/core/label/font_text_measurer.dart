import 'dart:typed_data';

import 'package:pdf/pdf.dart';

import '../../domain/label/data_label_layout.dart';

/// 同梱したフォントの寸法で、文字列の幅を測る。
///
/// PDF では欧文フォント(Fira Sans Condensed)を基本にし、字形が無い文字(かな・漢字)は
/// 和文フォント(BIZ UDPゴシック)で描く。ここでも同じ規則で文字ごとにフォントを選ぶので、
/// 印刷結果と同じ幅になる(カーニングは含めない)。
class FontTextMeasurer implements TextMeasurer {
  FontTextMeasurer({required ByteData latinFont, required ByteData japaneseFont})
    : _latin = TtfParser(latinFont),
      _japanese = TtfParser(japaneseFont);

  final TtfParser _latin;
  final TtfParser _japanese;

  @override
  double widthOf(String text, double fontSizePt) {
    var em = 0.0;
    for (final rune in text.runes) {
      em += _advanceOf(rune);
    }
    return em * fontSizePt;
  }

  /// どちらかのフォントに字形があるか(マクロン付きの文字などの確認用)。
  bool hasGlyph(int rune) =>
      _latin.charToGlyphIndexMap.containsKey(rune) ||
      _japanese.charToGlyphIndexMap.containsKey(rune);

  double _advanceOf(int rune) {
    for (final font in [_latin, _japanese]) {
      final glyph = font.charToGlyphIndexMap[rune];
      // advanceWidth は 1em を 1 とした値
      if (glyph != null) return font.glyphInfoMap[glyph]?.advanceWidth ?? 0;
    }
    throw ArgumentError('フォントに字形がありません: ${String.fromCharCode(rune)} '
        '(U+${rune.toRadixString(16).toUpperCase().padLeft(4, '0')})');
  }
}
