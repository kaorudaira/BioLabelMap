/// 時刻を持たない日付(年・月・日)。Java の `LocalDate` に相当する。
///
/// Dart の `DateTime` は時刻とタイムゾーンを持つため、採集日や同定日には
/// こちらを使う。日付のずれ(UTC変換で前日になる等)を避けるのが目的。
class CalendarDate implements Comparable<CalendarDate> {
  // `this.year` のような引数は、受け取った値をそのままフィールドに代入する糖衣構文。
  // Java の `this.year = year;` を書かずに済む。`{ ... }` 部分がコンストラクタ本体。
  CalendarDate(this.year, this.month, this.day) {
    final normalized = DateTime.utc(year, month, day);
    if (normalized.year != year ||
        normalized.month != month ||
        normalized.day != day) {
      throw ArgumentError('存在しない日付です: $year-$month-$day');
    }
  }

  // `factory` は、新しいインスタンスを必ずしも作らないコンストラクタ。
  // Java の static ファクトリメソッド(`LocalDate.of(...)`)に近い。
  factory CalendarDate.fromDateTime(DateTime dateTime) =>
      CalendarDate(dateTime.year, dateTime.month, dateTime.day);

  /// `2026-06-20` 形式の文字列から作る。
  factory CalendarDate.parse(String iso) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(iso);
    if (match == null) {
      throw FormatException('日付の形式が不正です', iso);
    }
    // `!` は「null ではない」と断言する演算子(null なら実行時エラー)。
    return CalendarDate(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
  }

  final int year;
  final int month;
  final int day;

  /// `2026-06-20` 形式。DB保存と CSV の eventDate に使う。
  String toIso() => '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';

  // `bool get isX => ...` はゲッター。呼び出し側は `date.isX` とフィールドのように書く。
  bool isBefore(CalendarDate other) => compareTo(other) < 0;

  @override
  int compareTo(CalendarDate other) {
    if (year != other.year) return year.compareTo(other.year);
    if (month != other.month) return month.compareTo(other.month);
    return day.compareTo(other.day);
  }

  // Dart では `==` 演算子を直接オーバーライドする(Java の equals に相当)。
  @override
  bool operator ==(Object other) =>
      other is CalendarDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => toIso();
}
