import '../locality_key.dart';
import '../models/collection_period.dart';
import 'date_range_format.dart';

/// データラベルの行の種類。種類ごとに文字サイズが決まる(要件定義 第5章)。
enum DataLabelLineRole {
  /// 1行目(`JAPAN: 県`)。
  header,

  /// 詳細住所(郡, 市町村, 大字)。ひと続きで書き、幅に収まらないときだけ改行する。
  /// 7行に収まらないときに小さくする。
  address,

  /// 標高。詳細住所が3行以上になるときは、詳細住所の最後の行に続ける。
  elevation,

  /// 緯度経度・日付と採集者。
  body,

  /// 日本語の地名(郡+市町村+大字)。これも詳細住所として小さくする。
  japanese;

  /// 7行に収まらないときに、文字を1段階小さくする行か。
  bool get isDetailAddress => this == address || this == japanese;
}

/// 行の種類ごとの文字サイズ(pt)。既定値は要件定義 第5章のとおり。
class DataLabelStyle {
  const DataLabelStyle({
    this.headerPt = 4,
    this.addressPt = 3,
    this.bodyPt = 3,
    this.japanesePt = 3.5,
    this.reductionStepPt = 0.5,
  });

  final double headerPt;
  final double addressPt;
  final double bodyPt;
  final double japanesePt;

  /// 詳細住所を小さくするときの1段階(pt)。
  final double reductionStepPt;

  // Dart 3 の switch 式。enum の全ケースを網羅しないとコンパイルエラーになる。
  // Java 21 の switch 式(パターンマッチ)とほぼ同じ。
  double sizeOf(DataLabelLineRole role) => switch (role) {
    DataLabelLineRole.header => headerPt,
    DataLabelLineRole.address => addressPt,
    DataLabelLineRole.elevation || DataLabelLineRole.body => bodyPt,
    DataLabelLineRole.japanese => japanesePt,
  };

  /// 詳細住所を1段階小さくした文字サイズ。
  DataLabelStyle withReducedDetailAddress() => DataLabelStyle(
    headerPt: headerPt,
    addressPt: addressPt - reductionStepPt,
    bodyPt: bodyPt,
    japanesePt: japanesePt - reductionStepPt,
    reductionStepPt: reductionStepPt,
  );
}

/// データラベルの1行(改行する前の、論理的な1行)。
class DataLabelLine {
  /// [segments] は改行してよい区切り(日本語の地名の「郡・市町村・大字」など)。
  /// 省略すると、行全体を1つの区切りとして扱う。
  // `{this._segments}` は、名前付き引数 `segments` を private フィールドに代入する(最近の Dart の書き方)。
  const DataLabelLine(this.text, this.role, {this._segments});

  final String text;
  final DataLabelLineRole role;
  final List<String>? _segments;

  List<String> get segments => _segments ?? [text];

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

  /// 郡(町村のみ)。詳細住所の先頭に `Minamiuonuma-gun, Yuzawa-machi, …` の形で入る。
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
/// 改行するのは「JAPAN: 県」の後、詳細住所(郡, 市町村, 大字)の最後、標高、緯度経度、
/// 日付と採集者の後。詳細住所はひと続きで、幅に収まらないときだけ layoutDataLabel が改行する。
/// 各項目の終わりのカンマは付けない。未取得・空の項目は省き、空欄を残さない。
List<DataLabelLine> buildDataLabel(DataLabelSource s) {
  final prefecture = _blankToNull(s.prefectureEn);
  final address = [
    ?_blankToNull(s.countyEn),
    ?_blankToNull(s.municipalityEn),
    ?_blankToNull(s.localityEn),
  ].join(', ');
  // ↑ `?式` は null なら要素を入れない(Dart 3.8 の null-aware 要素)。
  final japaneseParts = [
    ?_blankToNull(s.countyJa),
    ?_blankToNull(s.municipalityJa),
    ?_blankToNull(s.localityJa),
  ];
  final japanese = japaneseParts.join();
  final collector = _blankToNull(s.collector);
  final date = formatLabelPeriod(s.period);

  // リストの中に `if` を書ける(コレクション if)。条件が偽なら要素ごと入らない。
  // Java なら add を if で囲んで書くところ。
  return [
    DataLabelLine(
      prefecture == null ? s.country : '${s.country}: $prefecture',
      DataLabelLineRole.header,
    ),
    if (address.isNotEmpty) DataLabelLine(address, DataLabelLineRole.address),
    if (s.elevationMeters case final e?)
      DataLabelLine('(alt. $e m)', DataLabelLineRole.elevation),
    DataLabelLine(
      formatCoordinates(s.latitude, s.longitude),
      DataLabelLineRole.body,
    ),
    DataLabelLine(
      collector == null ? date : '$date, $collector',
      DataLabelLineRole.body,
    ),
    if (japanese.isNotEmpty)
      DataLabelLine(japanese, DataLabelLineRole.japanese, segments: japaneseParts),
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
