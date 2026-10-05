import '../locality_key.dart';
import '../models/collection_period.dart';
import 'date_range_format.dart';

/// データラベルの行の種類。種類ごとに文字サイズが決まる(要件定義 第5章)。
enum DataLabelLineRole {
  /// 1行目(`JAPAN: 県`)。
  header,

  /// 2〜6行目(郡と市町村・大字・標高・緯度経度・日付と採集者)。
  body,

  /// 7行目(日本語の地名)。
  japanese,
}

/// 行の種類ごとの文字サイズ(pt)。既定値は要件定義 第5章のとおり。
class DataLabelStyle {
  const DataLabelStyle({
    this.headerPt = 4,
    this.bodyPt = 3,
    this.japanesePt = 3.5,
  });

  final double headerPt;
  final double bodyPt;
  final double japanesePt;

  // Dart 3 の switch 式。enum の全ケースを網羅しないとコンパイルエラーになる。
  // Java 21 の switch 式(パターンマッチ)とほぼ同じ。
  double sizeOf(DataLabelLineRole role) => switch (role) {
    DataLabelLineRole.header => headerPt,
    DataLabelLineRole.body => bodyPt,
    DataLabelLineRole.japanese => japanesePt,
  };
}

/// データラベルの1行。
class DataLabelLine {
  const DataLabelLine(this.text, this.role);

  final String text;
  final DataLabelLineRole role;

  @override
  bool operator ==(Object other) =>
      other is DataLabelLine && other.text == text && other.role == role;

  @override
  int get hashCode => Object.hash(text, role);

  @override
  String toString() => '[$role] $text';
}

/// データラベルの元になる値。未取得の項目は null にする。
///
/// 地名・標高は補完待ちのまま印刷されることがある(要件定義 第13章)。
/// 標高の丸めと採集者名の整形は、呼び出す前に済ませておく。
class DataLabelSource {
  const DataLabelSource({
    this.country = 'JAPAN',
    this.prefectureEn,
    this.countyEn,
    this.municipalityEn,
    this.localityEn,
    this.elevationMeters,
    required this.latitude,
    required this.longitude,
    required this.period,
    this.collector,
    this.countyJa,
    this.municipalityJa,
    this.localityJa,
  });

  final String country;
  // `String?` は null を許す型。`String` は null にできない(コンパイラが検査する)。
  // Java の @Nullable / Optional を型システムで強制するイメージ。
  final String? prefectureEn;

  /// 郡(町村のみ)。市町村と同じ行に `Minamiuonuma-gun, Yuzawa-machi` の形で入る。
  final String? countyEn;
  final String? municipalityEn;
  final String? localityEn;
  final int? elevationMeters;
  final double latitude;
  final double longitude;
  final CollectionPeriod period;

  /// ラベル用に整形済みの採集者名(`K. YOSHIHARA`)。
  final String? collector;
  final String? countyJa;
  final String? municipalityJa;
  final String? localityJa;
}

/// データラベルの行を組み立てる(要件定義 第5章)。
///
/// 項目ごとに改行し、最大7行で構成する。行末のカンマは付けない。
/// 郡は市町村と同じ行に入れ、行数を増やさない(10mm の高さに収めるため)。
/// 未取得・空の項目は行ごと省き、空欄を残さない。
List<DataLabelLine> buildDataLabel(DataLabelSource s) {
  final prefecture = _blankToNull(s.prefectureEn);
  final municipality = [
    ?_blankToNull(s.countyEn),
    ?_blankToNull(s.municipalityEn),
  ].join(', ');
  // ↑ `?式` は null なら要素を入れない(Dart 3.8 の null-aware 要素)。
  final japanese = [
    ?_blankToNull(s.countyJa),
    ?_blankToNull(s.municipalityJa),
    ?_blankToNull(s.localityJa),
  ].join();
  final collector = _blankToNull(s.collector);
  final date = formatLabelPeriod(s.period);

  // リストの中に `if` を書ける(コレクション if)。条件が偽なら要素ごと入らない。
  // Java なら add を if で囲んで書くところ。
  return [
    DataLabelLine(
      prefecture == null ? s.country : '${s.country}: $prefecture',
      DataLabelLineRole.header,
    ),
    if (municipality.isNotEmpty)
      DataLabelLine(municipality, DataLabelLineRole.body),
    if (_blankToNull(s.localityEn) case final l?)
      DataLabelLine(l, DataLabelLineRole.body),
    if (s.elevationMeters case final e?)
      DataLabelLine('(alt. $e m)', DataLabelLineRole.body),
    DataLabelLine(
      formatCoordinates(s.latitude, s.longitude),
      DataLabelLineRole.body,
    ),
    DataLabelLine(
      collector == null ? date : '$date, $collector',
      DataLabelLineRole.body,
    ),
    if (japanese.isNotEmpty)
      DataLabelLine(japanese, DataLabelLineRole.japanese),
  ];
  // `if (x case final v?)` は「x が null でなければ v に束縛する」パターン。
  // Java の `if (x instanceof String v)` に近い。
}

/// 1行にまとめた形。要件定義 第5章の書式例と同じになる。
/// `JAPAN: Niigata-ken, Uonuma-shi, ..., 魚沼市下折立`
String dataLabelAsSingleLine(List<DataLabelLine> lines) =>
    lines.map((l) => l.text).join(', ');

/// 緯度経度をラベル用にする。小数4桁で切り捨て。`36.9447°N 139.2426°E`
///
/// LocalityKey と同じ整数化を使い、同一地点の判定とラベルの値を必ず一致させる。
String formatCoordinates(double latitude, double longitude) {
  final key = LocalityKey.fromCoordinates(latitude, longitude);
  final ns = key.latE4 < 0 ? 'S' : 'N';
  final ew = key.lonE4 < 0 ? 'W' : 'E';
  return '${_formatE4(key.latE4.abs())}°$ns ${_formatE4(key.lonE4.abs())}°$ew';
}

/// 1万倍した整数を小数4桁の文字列にする(369447 → 36.9447)。
String _formatE4(int value) =>
    '${value ~/ 10000}.${(value % 10000).toString().padLeft(4, '0')}';
// `~/` は整数の割り算(Java の int 同士の `/`)。Dart の `/` は常に double を返す。

String? _blankToNull(String? value) {
  // `?.` は null なら呼び出さずに null を返す。`??` は左が null のときに右を使う。
  final trimmed = value?.trim();
  return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
}
