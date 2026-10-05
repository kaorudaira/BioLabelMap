/// 地名(和・英)。逆ジオコーダと内蔵の対応表から作る。未取得の項目は null。
class PlaceInfo {
  const PlaceInfo({
    this.municipalityCode,
    this.prefectureJa,
    this.countyJa,
    this.municipalityJa,
    this.localityJa,
    this.prefectureEn,
    this.countyEn,
    this.municipalityEn,
    this.localityEn,
  });

  /// 自治体コード(5桁)。
  final String? municipalityCode;
  final String? prefectureJa;

  /// 郡(町村のみ)。
  final String? countyJa;
  final String? municipalityJa;

  /// 大字。
  final String? localityJa;
  final String? prefectureEn;
  final String? countyEn;
  final String? municipalityEn;

  /// 大字のローマ字(手入力または辞書から)。
  final String? localityEn;

  /// 大字のローマ字だけを変えた写しを作る(記録画面での手入力用)。
  PlaceInfo withLocalityEn(String? value) => PlaceInfo(
    municipalityCode: municipalityCode,
    prefectureJa: prefectureJa,
    countyJa: countyJa,
    municipalityJa: municipalityJa,
    localityJa: localityJa,
    prefectureEn: prefectureEn,
    countyEn: countyEn,
    municipalityEn: municipalityEn,
    localityEn: value,
  );
}
