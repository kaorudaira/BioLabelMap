import '../core/db/database.dart';
import '../domain/elevation_rounding.dart';
import '../domain/label/printed_values.dart';

/// いまの地点の値から、ラベルに載せる元の値を作る(標高は設定の丸めで丸める)。
/// 印刷時に残す値と、いまの値の比較(ラベルと不一致)の両方に使う。
PrintedLabelValues currentLabelValues(Locality l, ElevationRounding rounding) => PrintedLabelValues.of(
  elevationRoundedMeters: switch (l.elevationMeters) {
    final double e => rounding.apply(e).toDouble(),
    null => null,
  },
  country: l.country,
  prefectureEn: l.prefectureEn,
  countyEn: l.countyEn,
  municipalityEn: l.municipalityEn,
  localityEn: l.localityEn,
  countyJa: l.countyJa,
  municipalityJa: l.municipalityJa,
  localityJa: l.localityJa,
);
