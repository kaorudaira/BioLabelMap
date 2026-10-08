import 'dart:convert';

import '../../domain/oaza_name.dart';

/// 公的データから作った大字のローマ字。
class OazaRomaji {
  const OazaRomaji(this.value);

  /// 例: `Tsuchidaru`、`Shimōritate`。
  final String value;

  /// マクロンを含む(確認が要る)。
  ///
  /// 公的データは長音を省いて書くため、マクロンはカナから補っている。語の境目の「ou」「oo」
  /// (丸の内=マルノウチ、下折立=シモオリタテ)まで長音にしてしまうことがあるので、
  /// 自動では入れず、候補として出して確かめてもらう(要件定義 第5章)。
  bool get needsConfirmation => RegExp('[āīūēōĀĪŪĒŌ]').hasMatch(value);
}

/// 自治体コード+大字 → 大字のローマ字の対応表(要件定義 第5章)。
///
/// アドレス・ベース・レジストリ(デジタル庁)と郵便番号データ(日本郵便)から
/// `tools/municipalities/build_oaza.dart` で作り、assets/data/oaza_romaji.json に同梱する。
/// 形式: `{"15225": {"下折立": "Shimōritate", ...}, ...}`
class OazaRomajiTable {
  const OazaRomajiTable(this._byCode);

  /// 表が無いとき(テストなど)。何も引けない。
  static const empty = OazaRomajiTable({});

  factory OazaRomajiTable.parse(String source) {
    final decoded = jsonDecode(source) as Map<String, dynamic>;
    return OazaRomajiTable({
      for (final MapEntry(:key, :value) in decoded.entries)
        key: (value as Map<String, dynamic>).cast<String, String>(),
    });
  }

  final Map<String, Map<String, String>> _byCode;

  /// 逆ジオコーダの自治体コード(5桁)と大字(lv01Nm)で引く。
  OazaRomaji? lookup(String? municipalityCode, String? localityJa) {
    if (municipalityCode == null || localityJa == null) return null;
    final value = _byCode[municipalityCode.padLeft(5, '0')]?[normalizeOazaName(localityJa)];
    return value == null ? null : OazaRomaji(value);
  }
}
