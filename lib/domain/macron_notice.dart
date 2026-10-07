/// 語の境目か長音か判断が分かれる自治体名。表記は長音で確定しているが、
/// 自動入力のときに「確かめてください」と注意を出す(要件定義 第5章)。
const _ambiguousMacronNames = {'Ōmu-chō', 'Ōra-gun', 'Ōra-machi', 'Ōme-shi', 'Kudō-gun'};

/// 郡・市町村の英語表記のうち、注意を出すものを返す。なければ null。
String? ambiguousMacronName({String? countyEn, String? municipalityEn}) {
  for (final name in [countyEn, municipalityEn]) {
    if (name != null && _ambiguousMacronNames.contains(name)) return name;
  }
  return null;
}
