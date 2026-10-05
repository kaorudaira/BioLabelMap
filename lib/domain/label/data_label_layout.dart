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
    required this.droppedJapaneseSegments,
    required this.japaneseOmitted,
    required this.overflows,
  });

  final List<PlacedLabelLine> lines;

  /// 7行に収めるため、詳細住所の文字を1段階小さくしたか。
  final bool detailAddressReduced;

  /// 日本語の地名を1行に収めるため省いた行政区画(大きい順。例: `['南魚沼郡']`)。
  final List<String> droppedJapaneseSegments;

  /// 1段階小さくしても収まらないため、日本語の地名を省いたか。
  /// 印刷の前に警告し、省いてよいか確認する(要件定義 S-07)。
  final bool japaneseOmitted;

  /// 収まらない(行数が多すぎる、または枠より長い語がある)。プレビューで警告する。
  final bool overflows;
}

/// データラベルを割り付ける(改行と文字サイズの決定)。要件定義 第5章。
///
/// 1. 欧文の行は、余裕をもった幅([DataLabelLayoutSpec.wrapWidthPt])で改行する。
///    区切りは「, 」を優先し、次に空白、最後にハイフンの後ろ。行末のカンマは残す。
/// 2. 日本語の地名は改行しない。1行に入らなければ、大きい行政区画(郡 → 市町村)から省いて収める。
/// 3. それで [DataLabelLayoutSpec.maxLines] 行を超える、または日本語の地名が入らないときは、
///    詳細住所(郡と市町村・大字・日本語の地名)の文字を1段階小さくして、1〜2をやり直す。
/// 4. それでも収まらないときは、日本語の地名を省く([DataLabelLayout.japaneseOmitted])。
///    省いても収まらないとき、または [allowOmitJapanese] が false(省くことを断られた)ときは、
///    省かずに [DataLabelLayout.overflows] を立てる。
DataLabelLayout layoutDataLabel(
  List<DataLabelLine> lines, {
  DataLabelStyle style = const DataLabelStyle(),
  DataLabelLayoutSpec spec = const DataLabelLayoutSpec(),
  TextMeasurer measurer = const ApproximateTextMeasurer(),
  bool allowOmitJapanese = true,
}) {
  final normal = _Attempt(lines, style, spec, measurer);
  if (normal.fits) return normal.toLayout(reduced: false);

  final reducedStyle = style.withReducedDetailAddress();
  final reduced = _Attempt(lines, reducedStyle, spec, measurer);
  if (reduced.fits || !allowOmitJapanese) return reduced.toLayout(reduced: true);

  final hasJapanese = lines.any((l) => l.role == DataLabelLineRole.japanese);
  final withoutJapanese = _Attempt(
    [for (final l in lines) if (l.role != DataLabelLineRole.japanese) l],
    reducedStyle,
    spec,
    measurer,
  );
  // 省いても収まらない(長すぎる語があるなど)なら、省かずに警告だけ出す
  if (!hasJapanese || !withoutJapanese.fits) return reduced.toLayout(reduced: true);
  return withoutJapanese.toLayout(reduced: true, japaneseOmitted: true);
}

/// 1つの文字サイズで割り付けた結果。
class _Attempt {
  _Attempt(
    List<DataLabelLine> lines,
    DataLabelStyle style,
    this.spec,
    this.measurer,
  ) {
    for (final line in lines) {
      final size = style.sizeOf(line.role);
      bool fits(String s) => measurer.widthOf(s, size) <= spec.wrapWidthPt;

      if (line.role == DataLabelLineRole.japanese) {
        final segments = line.segments;
        // 大きい行政区画から省き、1行に入る最長のものを使う(最後の1区画は残す)
        var start = 0;
        while (start < segments.length - 1 && !fits(segments.sublist(start).join())) {
          start++;
        }
        final text = segments.sublist(start).join();
        dropped.addAll(segments.sublist(0, start));
        if (!fits(text)) japaneseDoesNotFit = true;
        placed.add(PlacedLabelLine(text, line.role, size));
      } else {
        for (final text in fits(line.text) ? [line.text] : _wrapLatin(line.text, fits)) {
          placed.add(PlacedLabelLine(text, line.role, size));
        }
      }
    }
  }

  final DataLabelLayoutSpec spec;
  final TextMeasurer measurer;
  final placed = <PlacedLabelLine>[];
  final dropped = <String>[];
  var japaneseDoesNotFit = false;

  bool get tooManyLines => placed.length > spec.maxLines;

  bool get anyTooWide => placed.any(
    (l) => measurer.widthOf(l.text, l.fontSizePt) > spec.contentWidthPt,
  );

  bool get fits => !tooManyLines && !japaneseDoesNotFit && !anyTooWide;

  DataLabelLayout toLayout({required bool reduced, bool japaneseOmitted = false}) =>
      DataLabelLayout(
        lines: placed,
        detailAddressReduced: reduced,
        droppedJapaneseSegments: dropped,
        japaneseOmitted: japaneseOmitted,
        overflows: !fits,
      );
}

/// 欧文の改行。語(空白区切り)を詰めていき、入らなくなったら「, 」の後ろを優先して切る。
/// 行末のカンマは残す(`Minamiuonuma-gun,` / `Yuzawa-machi`)。
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
  return result;
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
