import 'data_label_builder.dart';

/// 1mm を pt に換算する係数(1pt = 1/72 インチ)。
const ptPerMm = 72 / 25.4;

/// 文字列の幅を測る。PDF に埋め込むフォントの寸法で測るのが本来の形。
///
/// `abstract interface class` は Java の interface に相当する。
/// フォントを同梱したら、pdf パッケージのフォント寸法を使う実装に差し替える。
abstract interface class TextMeasurer {
  /// [text] を [fontSizePt] で書いたときの幅(pt)。
  double widthOf(String text, double fontSizePt);
}

/// 文字の種類ごとの幅で見積もる(フォントを同梱するまでの仮の実装)。
///
/// 値は Condensed 系の欧文書体を想定した目安で、やや広めにとってある。
/// 和文(かな・漢字・全角)は 1文字 1em。実際のフォントの寸法とは異なるので、
/// フォントを同梱したら、フォントの寸法で測る実装に差し替える。
class ApproximateTextMeasurer implements TextMeasurer {
  const ApproximateTextMeasurer();

  static const _upperEm = 0.55;
  static const _lowerEm = 0.45;
  static const _digitEm = 0.5;
  static const _narrowEm = 0.22; // . , : ; ' ( )
  static const _spaceEm = 0.2;
  static const _otherEm = 0.5; // - ° など
  static const _wideEm = 1.0;

  @override
  double widthOf(String text, double fontSizePt) {
    var em = 0.0;
    for (final char in text.runes.map(String.fromCharCode)) {
      em += switch (char) {
        _ when char.runes.first >= 0x3000 => _wideEm,
        ' ' => _spaceEm,
        '.' || ',' || ':' || ';' || "'" || '(' || ')' => _narrowEm,
        _ when RegExp(r'[0-9]').hasMatch(char) => _digitEm,
        _ when char != char.toLowerCase() => _upperEm,
        _ when char != char.toUpperCase() => _lowerEm,
        _ => _otherEm,
      };
      // ↑ `_ when 条件` はガード付きのパターン。Java 21 の `case X x when 条件 ->` に相当する。
    }
    return em * fontSizePt;
  }
}

/// ラベルの寸法と、改行・縮小の決まり。
class DataLabelLayoutSpec {
  const DataLabelLayoutSpec({
    this.labelWidthMm = 15,
    this.paddingMm = 0.5,
    this.safetyRatio = 0.9,
    this.maxLines = 7,
  });

  final double labelWidthMm;

  /// 左右それぞれの余白。
  final double paddingMm;

  /// 改行する幅の割合。0.9 なら、使える幅の 90% を超える前に改行する(余裕をもたせる)。
  final double safetyRatio;

  /// 1枚に入れる最大の行数。
  final int maxLines;

  /// 文字を置ける幅(pt)。これを超えると、枠からはみ出す。
  double get contentWidthPt => (labelWidthMm - paddingMm * 2) * ptPerMm;

  /// 改行する幅(pt)。
  double get wrapWidthPt => contentWidthPt * safetyRatio;
}

/// 改行後の1行。
class PlacedLabelLine {
  const PlacedLabelLine(this.text, this.role, this.fontSizePt);

  final String text;
  final DataLabelLineRole role;
  final double fontSizePt;

  @override
  bool operator ==(Object other) =>
      other is PlacedLabelLine &&
      other.text == text &&
      other.role == role &&
      other.fontSizePt == fontSizePt;

  @override
  int get hashCode => Object.hash(text, role, fontSizePt);

  @override
  String toString() => '[$role ${fontSizePt}pt] $text';
}

/// 割り付けの結果。
class DataLabelLayout {
  const DataLabelLayout({
    required this.lines,
    required this.detailAddressReduced,
    required this.overflows,
  });

  final List<PlacedLabelLine> lines;

  /// 7行に収めるため、詳細住所の文字を1段階小さくしたか。
  final bool detailAddressReduced;

  /// 小さくしても収まらない(行数が多すぎる、または枠より長い語がある)。
  /// プレビューで警告する(要件定義 S-07)。
  final bool overflows;
}

/// データラベルを割り付ける(改行と文字サイズの決定)。
///
/// 1. 各行を、余裕をもった幅([DataLabelLayoutSpec.wrapWidthPt])で改行する。
///    区切りは「, 」を優先し、次に空白、最後にハイフンの後ろで切る。行末のカンマは省く。
/// 2. それで [DataLabelLayoutSpec.maxLines] 行を超えたら、詳細住所(郡と市町村・大字・
///    日本語の地名)の文字を1段階小さくして、もう一度改行する。
/// 3. それでも超えるときは、小さくした割り付けを返し、[DataLabelLayout.overflows] を立てる。
DataLabelLayout layoutDataLabel(
  List<DataLabelLine> lines, {
  DataLabelStyle style = const DataLabelStyle(),
  DataLabelLayoutSpec spec = const DataLabelLayoutSpec(),
  TextMeasurer measurer = const ApproximateTextMeasurer(),
}) {
  final normal = _place(lines, style, spec, measurer);
  if (normal.length <= spec.maxLines) {
    return DataLabelLayout(
      lines: normal,
      detailAddressReduced: false,
      overflows: _anyTooWide(normal, spec, measurer),
    );
  }

  final reduced = _place(lines, style.withReducedDetailAddress(), spec, measurer);
  return DataLabelLayout(
    lines: reduced,
    detailAddressReduced: true,
    overflows:
        reduced.length > spec.maxLines || _anyTooWide(reduced, spec, measurer),
  );
}

List<PlacedLabelLine> _place(
  List<DataLabelLine> lines,
  DataLabelStyle style,
  DataLabelLayoutSpec spec,
  TextMeasurer measurer,
) => [
  for (final line in lines)
    for (final text in _wrapLine(line, style.sizeOf(line.role), spec, measurer))
      PlacedLabelLine(text, line.role, style.sizeOf(line.role)),
];
// ↑ コレクション for の入れ子。Java なら2重ループで add するところ。

bool _anyTooWide(
  List<PlacedLabelLine> lines,
  DataLabelLayoutSpec spec,
  TextMeasurer measurer,
) => lines.any(
  (l) => measurer.widthOf(l.text, l.fontSizePt) > spec.contentWidthPt,
);

List<String> _wrapLine(
  DataLabelLine line,
  double sizePt,
  DataLabelLayoutSpec spec,
  TextMeasurer measurer,
) {
  bool fits(String s) => measurer.widthOf(s, sizePt) <= spec.wrapWidthPt;

  if (fits(line.text)) return [line.text];
  return line.role == DataLabelLineRole.japanese
      ? _wrapJapanese(line.segments, fits)
      : _wrapLatin(line.text, fits);
}

/// 欧文の改行。語(空白区切り)を詰めていき、入らなくなったら「, 」の後ろを優先して切る。
List<String> _wrapLatin(String text, bool Function(String) fits) {
  final words = [
    for (final word in text.split(' '))
      if (word.isNotEmpty) ..._splitLongWord(word, fits),
  ];
  final result = <String>[];
  var current = <String>[];

  for (final word in words) {
    if (current.isEmpty || fits([...current, word].join(' '))) {
      current.add(word);
      continue;
    }
    // 入らない。行の途中に「,」で終わる語があれば、その後ろで切る
    final comma = current.lastIndexWhere((w) => w.endsWith(','));
    final moved = (comma >= 0 && comma < current.length - 1)
        ? current.sublist(comma + 1)
        : <String>[];
    if (moved.isNotEmpty && fits([...moved, word].join(' '))) {
      result.add(current.sublist(0, comma + 1).join(' '));
      current = [...moved, word];
    } else {
      result.add(current.join(' '));
      current = [word];
    }
  }
  if (current.isNotEmpty) result.add(current.join(' '));

  // 行末のカンマは省く
  return [for (final l in result) l.endsWith(',') ? l.substring(0, l.length - 1) : l];
}

/// 1語で幅を超えるときは、ハイフンの後ろで切る(`Higashishirakawa-` / `gun,`)。
/// 切れる場所が無ければそのまま返す(はみ出しとして警告される)。
/// 切った前半と後半は、元の1語が1行に入らない以上、必ず別の行になる。
List<String> _splitLongWord(String word, bool Function(String) fits) {
  if (fits(word)) return [word];
  for (var i = word.lastIndexOf('-'); i > 0; i = word.lastIndexOf('-', i - 1)) {
    final head = word.substring(0, i + 1);
    if (fits(head)) return [head, ..._splitLongWord(word.substring(i + 1), fits)];
  }
  return [word];
}

/// 日本語の地名の改行。郡・市町村・大字の区切りを優先し、それでも長ければ文字単位で切る。
List<String> _wrapJapanese(List<String> segments, bool Function(String) fits) {
  final result = <String>[];
  var current = '';
  for (final segment in segments) {
    if (fits(current + segment)) {
      current += segment;
      continue;
    }
    if (current.isNotEmpty) result.add(current);
    current = '';
    // runes で1文字ずつ(サロゲートペアの漢字を割らないため。Java の codePoints() に相当)
    for (final char in segment.runes.map(String.fromCharCode)) {
      if (current.isNotEmpty && !fits(current + char)) {
        result.add(current);
        current = '';
      }
      current += char;
    }
  }
  if (current.isNotEmpty) result.add(current);
  return result;
}
