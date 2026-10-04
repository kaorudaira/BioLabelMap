import 'package:drift/drift.dart';

import '../../domain/models/calendar_date.dart';

/// `CalendarDate` を `2026-06-20` 形式の文字列で保存する。
///
/// Drift の DateTime 列は時刻込みで保存されるため、採集日には使わない。
/// JPA の `AttributeConverter` に相当する。
class CalendarDateConverter extends TypeConverter<CalendarDate, String> {
  const CalendarDateConverter();

  @override
  CalendarDate fromSql(String fromDb) => CalendarDate.parse(fromDb);

  @override
  String toSql(CalendarDate value) => value.toIso();
}
