/// 印刷時に残す、ラベルに載せた元の値(要件定義 第13章「印刷済みラベルとの食い違い」)。
///
/// 改行や、日本語の地名の省略を経る前の値を残す。印字した文字列で比べると、
/// 日本語の地名を省いただけで「不一致」になってしまうため。
class PrintedLabelValues {
  const PrintedLabelValues({required this.elevation, required this.place});

  /// 地名の項目を区切る文字。この文字を含む値を、新しい形式とみなす(古い形式の値と見分ける)。
  static const placeSeparator = '\u0001';

  /// 丸めた標高(m)の文字。標高が無ければ空。
  final String elevation;

  /// 国・県・郡・市町村・大字の英語表記と、郡・市町村・大字の和文を、区切り文字でつないだもの。
  final String place;

  factory PrintedLabelValues.of({
    required double? elevationRoundedMeters,
    String? country,
    String? prefectureEn,
    String? countyEn,
    String? municipalityEn,
    String? localityEn,
    String? countyJa,
    String? municipalityJa,
    String? localityJa,
  }) => PrintedLabelValues(
    elevation: elevationRoundedMeters == null ? '' : '${elevationRoundedMeters.round()}',
    place: [
      country,
      prefectureEn,
      countyEn,
      municipalityEn,
      localityEn,
      countyJa,
      municipalityJa,
      localityJa,
    ].map((e) => e?.trim() ?? '').join(placeSeparator),
  );

  @override
  bool operator ==(Object other) =>
      other is PrintedLabelValues && other.elevation == elevation && other.place == place;

  @override
  int get hashCode => Object.hash(elevation, place);
}

/// 印刷したラベルと、いまの値が食い違っているか(「ラベルと不一致」)。
///
/// - 印刷していない標本は、食い違いようがない。
/// - 標高は、丸めた値で比べる。
/// - 地名は、新しい形式で残した値だけ比べる。古い形式(印字した文字列)の値は、
///   元の値が分からないので、比べない(食い違いとしない)。
bool isLabelMismatch({
  required DateTime? printedAt,
  required String? printedElevation,
  required String? printedPlace,
  required PrintedLabelValues current,
}) {
  if (printedAt == null) return false;
  if ((printedElevation ?? '') != current.elevation) return true;
  final place = printedPlace;
  if (place == null || !place.contains(PrintedLabelValues.placeSeparator)) return false;
  return place != current.place;
}
