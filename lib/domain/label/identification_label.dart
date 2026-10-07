import '../species_name.dart';
import 'data_label_layout.dart';

/// 同定ラベルの1つの文字の並び。学名はイタリック体で、それ以外は立体。
class LabelRun {
  const LabelRun(this.text, {this.italic = false});

  final String text;
  final bool italic;

  @override
  bool operator ==(Object other) => other is LabelRun && other.text == text && other.italic == italic;

  @override
  int get hashCode => Object.hash(text, italic);

  @override
  String toString() => italic ? '/$text/' : text;
}

/// 立体とイタリック体の幅を測る。アプリでは、PDF に埋め込むフォントの寸法で測る。
abstract interface class StyledTextMeasurer implements TextMeasurer {
  /// [text] をイタリック体で書いたときの幅(pt)。
  double italicWidthOf(String text, double fontSizePt);
}

/// 同定ラベルの材料(要件定義 第5章「同定ラベル」)。
class IdentificationLabelSource {
  const IdentificationLabelSource({required this.name, this.identifiedBy});

  final SpeciesName name;

  /// 同定者。空なら `det.` ごと省く。
  final String? identifiedBy;

  /// 和名も学名も無い(未同定)なら、ラベルを作らない。
  bool get isLabelable => !name.isEmpty;
}

/// 割り付けた同定ラベル。
class IdentificationLabelLayout {
  const IdentificationLabelLayout({required this.lines, required this.fontSizePt, required this.overflows});

  /// 改行後の各行。
  final List<List<LabelRun>> lines;
  final double fontSizePt;

  /// 最小の文字サイズでも、枠からはみ出す。
  final bool overflows;

  String get plainText => lines.map((l) => l.map((r) => r.text).join()).join('\n');
}

/// 同定ラベルの文字サイズ。大きいほうから試し、収まる最初の大きさにする。
const identificationLabelMaxPt = 3.5;
const identificationLabelMinPt = 2.5;
const identificationLabelStepPt = 0.5;

/// ラベルに印字する語の並び。`{和名} {学名} {命名者・年} det. {同定者}`。学名のみイタリック体。
/// 命名者・年は、括弧の有無を含めて入力どおり。和名の注記(全角の空白)や、語の間の空白で区切る。
List<LabelRun> identificationLabelWords(IdentificationLabelSource source) {
  final name = source.name;
  List<String> split(String s) => s.split(RegExp(r'[\s　]+')).where((w) => w.isNotEmpty).toList();
  final by = source.identifiedBy?.trim();
  return [
    for (final w in split(name.vernacular ?? '')) LabelRun(w),
    for (final w in split(name.scientific ?? '')) LabelRun(w, italic: true),
    for (final w in split(name.authorship ?? '')) LabelRun(w),
    if (by != null && by.isNotEmpty) ...[const LabelRun('det.'), for (final w in split(by)) LabelRun(w)],
  ];
}

/// 同定ラベルを、15×10mm の枠に割り付ける。
///
/// 語の区切りで改行し、1語が幅に入らないときは文字の途中で折り返す。
/// 3.5pt から 0.5pt ずつ小さくして、枠(高さ)に収まる最初の大きさにする。
/// 2.5pt でも収まらなければ、はみ出しの警告のために [IdentificationLabelLayout.overflows] を立てる。
IdentificationLabelLayout layoutIdentificationLabel(
  IdentificationLabelSource source, {
  required StyledTextMeasurer measurer,
  DataLabelLayoutSpec spec = const DataLabelLayoutSpec(),
}) {
  final words = identificationLabelWords(source);
  IdentificationLabelLayout? last;
  for (var pt = identificationLabelMaxPt; pt >= identificationLabelMinPt - 1e-9; pt -= identificationLabelStepPt) {
    final lines = _wrap(words, pt, measurer, spec.wrapWidthPt);
    final fits = lines.length * pt * spec.lineHeightFactor <= spec.contentHeightPt && lines.length <= spec.maxLines;
    last = IdentificationLabelLayout(lines: lines, fontSizePt: pt, overflows: !fits);
    if (fits) return last;
  }
  return last!;
}

List<List<LabelRun>> _wrap(List<LabelRun> words, double pt, StyledTextMeasurer m, double maxWidth) {
  double width(LabelRun r) => r.italic ? m.italicWidthOf(r.text, pt) : m.widthOf(r.text, pt);
  final space = m.widthOf(' ', pt);

  final lines = <List<LabelRun>>[];
  var line = <LabelRun>[];
  var lineWidth = 0.0;

  void add(LabelRun piece, {required bool withSpace}) {
    final text = withSpace ? ' ${piece.text}' : piece.text;
    // 同じ書体が続くときは、1つの並びにまとめる
    if (line.isNotEmpty && line.last.italic == piece.italic) {
      line[line.length - 1] = LabelRun('${line.last.text}$text', italic: piece.italic);
    } else {
      line.add(LabelRun(text, italic: piece.italic));
    }
    lineWidth += width(piece) + (withSpace ? space : 0);
  }

  void newLine() {
    if (line.isNotEmpty) lines.add(line);
    line = <LabelRun>[];
    lineWidth = 0;
  }

  for (final word in words) {
    final w = width(word);
    if (line.isNotEmpty && lineWidth + space + w <= maxWidth) {
      add(word, withSpace: true);
      continue;
    }
    if (line.isNotEmpty) newLine();
    if (w <= maxWidth) {
      add(word, withSpace: false);
      continue;
    }
    // 1語が幅に入らない。文字の途中で折り返す
    var chunk = '';
    for (final rune in word.text.runes) {
      final next = '$chunk${String.fromCharCode(rune)}';
      final nextWidth = word.italic ? m.italicWidthOf(next, pt) : m.widthOf(next, pt);
      if (nextWidth > maxWidth && chunk.isNotEmpty) {
        add(LabelRun(chunk, italic: word.italic), withSpace: false);
        newLine();
        chunk = String.fromCharCode(rune);
      } else {
        chunk = next;
      }
    }
    if (chunk.isNotEmpty) add(LabelRun(chunk, italic: word.italic), withSpace: false);
  }
  newLine();
  return lines;
}
