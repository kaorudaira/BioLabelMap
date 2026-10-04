import 'calendar_date.dart';

/// 採集日。1日のみ、または期間(トラップの設置〜回収など)。
class CollectionPeriod {
  /// 期間を指定する。終了日が開始日より前ならエラー。
  CollectionPeriod(this.start, this.end) {
    if (end.isBefore(start)) {
      throw ArgumentError('終了日 ($end) が開始日 ($start) より前です');
    }
  }

  // 名前付きコンストラクタ。Java ではオーバーロードで書くところを、名前で区別する。
  // `: start = date, end = date` は初期化リストで、本体より先に final フィールドを設定する。
  CollectionPeriod.singleDay(CalendarDate date) : start = date, end = date;

  final CalendarDate start;
  final CalendarDate end;

  bool get isSingleDay => start == end;

  /// CSV の eventDate 用(ISO 8601)。期間は `2026-06-19/2026-06-20`。
  String toIso() =>
      isSingleDay ? start.toIso() : '${start.toIso()}/${end.toIso()}';

  @override
  bool operator ==(Object other) =>
      other is CollectionPeriod && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => toIso();
}
