/// 地名(和・英)。逆ジオコーダと内蔵の対応表から作る。未取得の項目は null。
class PlaceInfo {
  const PlaceInfo({
    this.municipalityCode,
    this.prefectureJa,
    this.municipalityJa,
    this.localityJa,
    this.prefectureEn,
    this.municipalityEn,
    this.localityEn,
  });

  /// 自治体コード(5桁)。
  final String? municipalityCode;
  final String? prefectureJa;
  final String? municipalityJa;

  /// 大字。
  final String? localityJa;
  final String? prefectureEn;
  final String? municipalityEn;

  /// 大字のローマ字(手入力または辞書から)。
  final String? localityEn;
}
