import 'dart:typed_data';

import 'package:pdf/pdf.dart';

import '../../domain/label/identification_label.dart';

/// 同梱したフォントの寸法で、文字列の幅を測る。
///
/// PDF では欧文フォント(Fira Sans Condensed)を基本にし、字形が無い文字(かな・漢字)は
/// 和文フォント(BIZ UDPゴシック)で描く。ここでも同じ規則で文字ごとにフォントを選ぶので、
/// 印刷結果と同じ幅になる(カーニングは含めない)。
/// 同定ラベルの学名はイタリック体で、欧文のイタリック体フォントの寸法で測る。
class FontTextMeasurer implements StyledTextMeasurer {
  FontTextMeasurer({required ByteData latinFont, required ByteData japaneseFont, ByteData? latinItalicFont})
    : _latin = TtfParser(latinFont),
      _latinItalic = latinItalicFont == null ? null : TtfParser(latinItalicFont),
      _japanese = TtfParser(japaneseFont);

  final TtfParser _latin;

  /// イタリック体。無ければ立体で測る。
  final TtfParser? _latinItalic;
  final TtfParser _japanese;

  @override
  double widthOf(String text, double fontSizePt) => _width(text, fontSizePt, _latin);

  @override
  double italicWidthOf(String text, double fontSizePt) => _width(text, fontSizePt, _latinItalic ?? _latin);

  double _width(String text, double fontSizePt, TtfParser latin) {
    var em = 0.0;
    for (final rune in text.runes) {
      em += _advanceOf(rune, latin);
    }
    return em * fontSizePt;
  }

  /// どちらかのフォントに字形があるか(マクロン付きの文字などの確認用)。
  bool hasGlyph(int rune) =>
      _latin.charToGlyphIndexMap.containsKey(rune) ||
      _japanese.charToGlyphIndexMap.containsKey(rune);

  double _advanceOf(int rune, TtfParser latin) {
    for (final font in [latin, _japanese]) {
      final glyph = font.charToGlyphIndexMap[rune];
      // advanceWidth は 1em を 1 とした値
      if (glyph != null) return font.glyphInfoMap[glyph]?.advanceWidth ?? 0;
    }
    throw ArgumentError('フォントに字形がありません: ${String.fromCharCode(rune)} '
        '(U+${rune.toRadixString(16).toUpperCase().padLeft(4, '0')})');
  }
}
