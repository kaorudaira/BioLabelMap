import 'dart:typed_data';

import 'package:pdf/pdf.dart';

import '../../domain/label/data_label_layout.dart';

/// 同梱した欧文フォント(Fira Sans Condensed)の寸法で、文字列の幅を測る。
///
/// PDF に埋め込むフォントと同じファイルを読むので、印刷結果と同じ幅になる(カーニングは含めない)。
/// 和文(かな・漢字・全角)は、和文フォントを選ぶまで 1文字 1em として扱う。
class FontTextMeasurer implements TextMeasurer {
  FontTextMeasurer(ByteData latinFont) : _ttf = TtfParser(latinFont);

  final TtfParser _ttf;

  static const _wideEm = 1.0;

  @override
  double widthOf(String text, double fontSizePt) {
    var em = 0.0;
    for (final rune in text.runes) {
      em += rune >= 0x3000 ? _wideEm : _advanceOf(rune);
    }
    return em * fontSizePt;
  }

  /// フォントに字形があるか(マクロン付きの文字などの確認用)。
  bool hasGlyph(int rune) => _ttf.charToGlyphIndexMap.containsKey(rune);

  double _advanceOf(int rune) {
    final glyph = _ttf.charToGlyphIndexMap[rune];
    if (glyph == null) {
      throw ArgumentError('フォントに字形がありません: ${String.fromCharCode(rune)} '
          '(U+${rune.toRadixString(16).toUpperCase().padLeft(4, '0')})');
    }
    // advanceWidth は 1em を 1 とした値
    return _ttf.glyphInfoMap[glyph]?.advanceWidth ?? 0;
  }
}
