import 'dart:convert';

/// 自治体コードに対応する県・市町村の名前(和・英)。
class MunicipalityNames {
  const MunicipalityNames({
    required this.prefectureJa,
    required this.municipalityJa,
    required this.prefectureEn,
    required this.municipalityEn,
  });

  final String prefectureJa;
  final String municipalityJa;

  /// 英語表記(マクロン付き)。例: `Niigata-ken`、`Tōkyō-to`。
  final String prefectureEn;
  final String municipalityEn;
}

/// 自治体コード → 県・市町村の名前の対応表(要件定義 第5章)。
///
/// `abstract interface class` は、実装だけを許して継承を許さない型。Java の interface に相当する。
abstract interface class MunicipalityDirectory {
  MunicipalityNames? lookup(String municipalityCode);
}

/// JSON の対応表。アプリでは assets/data/municipalities.json から読み込む。
///
/// 形式: `{"15225": {"prefJa": "新潟県", "muniJa": "魚沼市",
///                   "prefEn": "Niigata-ken", "muniEn": "Uonuma-shi"}, ...}`
class JsonMunicipalityDirectory implements MunicipalityDirectory {
  JsonMunicipalityDirectory(this._entries);

  factory JsonMunicipalityDirectory.parse(String source) {
    final decoded = jsonDecode(source) as Map<String, dynamic>;
    return JsonMunicipalityDirectory({
      for (final MapEntry(:key, :value) in decoded.entries)
        key.padLeft(5, '0'): MunicipalityNames(
          prefectureJa: value['prefJa'] as String,
          municipalityJa: value['muniJa'] as String,
          prefectureEn: value['prefEn'] as String,
          municipalityEn: value['muniEn'] as String,
        ),
    });
    // `{for (...) key: value}` はコレクション for。Java の Collectors.toMap に相当する。
  }

  final Map<String, MunicipalityNames> _entries;

  @override
  MunicipalityNames? lookup(String municipalityCode) =>
      _entries[municipalityCode.padLeft(5, '0')];
}
