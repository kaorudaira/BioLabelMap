import 'dart:math' as math;

/// 標本番号の書式(接頭辞+ゼロ埋めの桁数)。例: `KYC` + 5桁 → `KYC00123`。
///
/// 接頭辞と桁数は設定で後から変えられるが、既存の標本番号は変えない。
/// そのため DB には、数値と、作成時の書式で作った文字列の両方を保存する。
class CatalogNumberFormat {
  // `const` コンストラクタは、コンパイル時定数としてインスタンスを作れる。
  // 同じ値の const インスタンスは1つに共有される(Java には直接の対応なし)。
  const CatalogNumberFormat({this.prefix = 'KYC', this.digits = 5})
    : assert(digits > 0);
  // `{}` で囲んだ引数は名前付き引数。呼び出し側は
  // `CatalogNumberFormat(prefix: 'ABC', digits: 4)` のように名前で渡す。

  final String prefix;
  final int digits;

  /// 番号を文字列にする。桁数を超える番号は切り詰めずにそのまま出す。
  String format(int number) {
    if (number < 0) {
      throw ArgumentError.value(number, 'number', '負の番号は使えません');
    }
    return '$prefix${number.toString().padLeft(digits, '0')}';
  }

  /// 発行予定の範囲(記録画面用)。例: `KYC00123〜KYC00137`。1件なら `KYC00123`。
  String formatRange(int first, int count) {
    _checkCount(count);
    if (count == 1) return format(first);
    return '${format(first)}〜${format(first + count - 1)}';
  }

  /// 一覧用の短い範囲。例: `KYC00120〜122`。1件なら `KYC00120`。
  String formatCompactRange(int first, int last) {
    if (last < first) {
      throw ArgumentError('範囲の終わり ($last) が始め ($first) より前です');
    }
    if (first == last) return format(first);
    return '${format(first)}〜$last';
  }
}

/// 番号を指定して登録したあとの「次の番号」(要件定義 S-02)。
///
/// 指定した番号の範囲が自動の次の番号以上に及ぶときは、その続きまで進める。
/// 小さいとき(過去標本の登録)は、次の番号を変えない。
int nextNumberAfterManual({
  required int currentNext,
  required int specifiedFirst,
  required int count,
}) {
  // `required` は必須の名前付き引数。
  _checkCount(count);
  return math.max(currentNext, specifiedFirst + count);
}

void _checkCount(int count) {
  if (count < 1) {
    throw ArgumentError.value(count, 'count', '作成数は1以上です');
  }
}
