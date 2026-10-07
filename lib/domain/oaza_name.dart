/// 大字の名前を、公的データの表を引くための見出しにそろえる。
///
/// 地理院の逆ジオコーダ(lv01Nm)、アドレス・ベース・レジストリ、郵便番号データで、
/// 同じ大字でも書き方が少しずつ違うため、次をそろえる。
/// - 前後と途中の空白を除く
/// - 先頭の「大字」「字」を除く(`大字土樽` → `土樽`、`字青山` → `青山`)
/// - 末尾の丁目を除く(`旭ケ丘一丁目` → `旭ケ丘`)。丁目のローマ字は大字と同じ
/// - 小さい「ヶ」「ヵ」を「ケ」「カ」にする
String normalizeOazaName(String name) {
  var s = name.replaceAll(RegExp(r'[\s　]'), '').replaceAll('ヶ', 'ケ').replaceAll('ヵ', 'カ');
  final prefix = oazaPrefixOf(s);
  if (prefix != null) s = s.substring(prefix.length);
  return s.replaceFirst(RegExp(r'[0-9０-９〇一二三四五六七八九十百]+丁目$'), '');
}

/// 先頭に付いた「大字」「字」。付いていなければ null。名前がそれだけのときも null。
String? oazaPrefixOf(String name) {
  for (final prefix in const ['大字', '字']) {
    if (name.startsWith(prefix) && name.length > prefix.length) return prefix;
  }
  return null;
}

/// 大字のローマ字の末尾が `chō` のとき、直前にハイフンを入れて `-chō` にする(マクロンは残す)。
/// `Tondenchō` → `Tonden-chō`。すでに `Higashi-chō` なら変えない。
/// 名前が `chō` だけのときも変えない。
String applyChoSuffixRule(String romaji) {
  final m = RegExp(r'^(.+?)-?([Cc][Hh][ōŌ])$').firstMatch(romaji);
  if (m == null) return romaji;
  return '${m.group(1)}-${m.group(2)}';
}
