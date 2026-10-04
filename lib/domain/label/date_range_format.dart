import '../models/calendar_date.dart';
import '../models/collection_period.dart';

// Dart ではクラスに属さない関数・定数をファイルの直下に置ける。
// Java の static メソッドだけを集めたユーティリティクラスの代わりになる。
// 名前が `_` で始まるものはこのファイル(ライブラリ)の外から見えない(Java の private)。
const _romanMonths = [
  'I', 'II', 'III', 'IV', 'V', 'VI', //
  'VII', 'VIII', 'IX', 'X', 'XI', 'XII',
];

/// 月をローマ数字にする(1 → I、12 → XII)。
String romanMonth(int month) {
  if (month < 1 || month > 12) {
    throw RangeError.range(month, 1, 12, 'month');
  }
  return _romanMonths[month - 1];
}

/// ラベル用の日付。`20. VI. 2026`
String formatLabelDate(CalendarDate date) =>
    '${date.day}. ${romanMonth(date.month)}. ${date.year}';

/// ラベル用の採集日(要件定義 第5章)。
///
/// - 1日のみ: `20. VI. 2026`
/// - 同じ月: `19-20. VI. 2026`
/// - 月をまたぐ: `30. V.-2. VI. 2026`
/// - 年をまたぐ: `30. XII. 2025-2. I. 2026`
///
/// ハイフンの前後にスペースは入れない。
String formatLabelPeriod(CollectionPeriod period) {
  final start = period.start;
  final end = period.end;

  if (period.isSingleDay) {
    return formatLabelDate(start);
  }
  if (start.year != end.year) {
    return '${formatLabelDate(start)}-${formatLabelDate(end)}';
  }
  if (start.month != end.month) {
    return '${start.day}. ${romanMonth(start.month)}.-${formatLabelDate(end)}';
  }
  return '${start.day}-${formatLabelDate(end)}';
}
