// カナから、マクロン付きのヘボン式ローマ字を作る(自治体の対応表の生成用)。
//
// 長音かどうかはカナだけでは決められない(東京=トウキョウは長音、小浦=コウラは長音でない)。
// そこで、長音の候補をすべて展開し、日本郵便のローマ字(長音を省いた綴り)と
// 一致するものだけを残す。日本郵便が u や o を省いていれば長音、残していれば長音でない。

/// 半角カナを全角カナにする(濁点・半濁点は1文字にまとめる)。
String halfToFullKatakana(String input) {
  const half =
      'ｦｧｨｩｪｫｬｭｮｯｰｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜﾝ';
  const full =
      'ヲァィゥェォャュョッーアイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワン';
  final out = StringBuffer();
  final chars = input.runes.map(String.fromCharCode).toList();
  for (var i = 0; i < chars.length; i++) {
    final index = half.indexOf(chars[i]);
    if (index < 0) {
      out.write(chars[i]);
      continue;
    }
    var c = full[index];
    final next = i + 1 < chars.length ? chars[i + 1] : '';
    if (next == 'ﾞ') {
      c = c == 'ウ' ? 'ヴ' : String.fromCharCode(c.codeUnitAt(0) + 1);
      i++;
    } else if (next == 'ﾟ') {
      c = String.fromCharCode(c.codeUnitAt(0) + 2);
      i++;
    }
    out.write(c);
  }
  return out.toString();
}

const _digraphs = {
  'キャ': 'kya', 'キュ': 'kyu', 'キョ': 'kyo',
  'ギャ': 'gya', 'ギュ': 'gyu', 'ギョ': 'gyo',
  'シャ': 'sha', 'シュ': 'shu', 'ショ': 'sho', 'シェ': 'she',
  'ジャ': 'ja', 'ジュ': 'ju', 'ジョ': 'jo', 'ジェ': 'je',
  'チャ': 'cha', 'チュ': 'chu', 'チョ': 'cho', 'チェ': 'che',
  'ヂャ': 'ja', 'ヂュ': 'ju', 'ヂョ': 'jo',
  'ニャ': 'nya', 'ニュ': 'nyu', 'ニョ': 'nyo',
  'ヒャ': 'hya', 'ヒュ': 'hyu', 'ヒョ': 'hyo',
  'ビャ': 'bya', 'ビュ': 'byu', 'ビョ': 'byo',
  'ピャ': 'pya', 'ピュ': 'pyu', 'ピョ': 'pyo',
  'ミャ': 'mya', 'ミュ': 'myu', 'ミョ': 'myo',
  'リャ': 'rya', 'リュ': 'ryu', 'リョ': 'ryo',
  'ファ': 'fa', 'フィ': 'fi', 'フェ': 'fe', 'フォ': 'fo',
  'ティ': 'ti', 'ディ': 'di', 'ヴァ': 'va',
};

const _monographs = {
  'ア': 'a', 'イ': 'i', 'ウ': 'u', 'エ': 'e', 'オ': 'o',
  'カ': 'ka', 'キ': 'ki', 'ク': 'ku', 'ケ': 'ke', 'コ': 'ko',
  'ガ': 'ga', 'ギ': 'gi', 'グ': 'gu', 'ゲ': 'ge', 'ゴ': 'go',
  'サ': 'sa', 'シ': 'shi', 'ス': 'su', 'セ': 'se', 'ソ': 'so',
  'ザ': 'za', 'ジ': 'ji', 'ズ': 'zu', 'ゼ': 'ze', 'ゾ': 'zo',
  'タ': 'ta', 'チ': 'chi', 'ツ': 'tsu', 'テ': 'te', 'ト': 'to',
  'ダ': 'da', 'ヂ': 'ji', 'ヅ': 'zu', 'デ': 'de', 'ド': 'do',
  'ナ': 'na', 'ニ': 'ni', 'ヌ': 'nu', 'ネ': 'ne', 'ノ': 'no',
  'ハ': 'ha', 'ヒ': 'hi', 'フ': 'fu', 'ヘ': 'he', 'ホ': 'ho',
  'バ': 'ba', 'ビ': 'bi', 'ブ': 'bu', 'ベ': 'be', 'ボ': 'bo',
  'パ': 'pa', 'ピ': 'pi', 'プ': 'pu', 'ペ': 'pe', 'ポ': 'po',
  'マ': 'ma', 'ミ': 'mi', 'ム': 'mu', 'メ': 'me', 'モ': 'mo',
  'ヤ': 'ya', 'ユ': 'yu', 'ヨ': 'yo',
  'ラ': 'ra', 'リ': 'ri', 'ル': 'ru', 'レ': 're', 'ロ': 'ro',
  'ワ': 'wa', 'ヰ': 'i', 'ヱ': 'e', 'ヲ': 'o', 'ヴ': 'vu',
  'ァ': 'a', 'ィ': 'i', 'ゥ': 'u', 'ェ': 'e', 'ォ': 'o',
};

const _macron = {'a': 'ā', 'i': 'ī', 'u': 'ū', 'e': 'ē', 'o': 'ō'};
const _plain = {'ā': 'a', 'ī': 'i', 'ū': 'u', 'ē': 'e', 'ō': 'o'};

/// マクロンを外す。
String stripMacrons(String s) =>
    s.split('').map((c) => _plain[c] ?? _plain[c.toLowerCase()]?.toUpperCase() ?? c).join();

/// カナ(全角)を、ありうるローマ字の候補すべてに展開する(小文字)。
///
/// 展開するもの:
/// - 長音の候補(オウ・オオ・ウウ、および長音符ー): マクロンにするか、そのまま並べるか
/// - 撥音ン(b・m・p の前): n か m
/// - 促音ッ(ch の前): t か c
Set<String> romajiCandidates(String katakana) {
  final morae = _toMorae(katakana);
  var results = <String>{''};

  for (var i = 0; i < morae.length; i++) {
    final mora = morae[i];
    final next = i + 1 < morae.length ? morae[i + 1] : null;
    final nextRomaji = next == null ? '' : (_romajiOf(next) ?? '');

    List<String> options;
    if (mora == 'ッ') {
      if (nextRomaji.isEmpty) {
        options = [''];
      } else if (nextRomaji.startsWith('ch')) {
        options = ['t', 'c'];
      } else {
        options = [nextRomaji[0]];
      }
    } else if (mora == 'ン') {
      options = (nextRomaji.startsWith(RegExp('[bmp]'))) ? ['n', 'm'] : ['n'];
    } else if (mora == 'ー') {
      options = ['<LONG>'];
    } else {
      final r = _romajiOf(mora);
      if (r == null) {
        throw FormatException('ローマ字にできないカナです', katakana);
      }
      options = [r];
    }

    final grown = <String>{};
    for (final prefix in results) {
      for (final option in options) {
        if (option == '<LONG>') {
          grown.add(_lengthenLast(prefix));
          continue;
        }
        grown.add(prefix + option);
        // 長音の候補: 直前が o で今が ウ/オ、直前が u で今が ウ
        final last = prefix.isEmpty ? '' : prefix[prefix.length - 1];
        final isLongCandidate =
            (last == 'o' && (mora == 'ウ' || mora == 'オ')) ||
            (last == 'u' && mora == 'ウ');
        if (isLongCandidate) grown.add(_lengthenLast(prefix));
      }
    }
    results = grown;
  }
  return results;
}

String _lengthenLast(String s) {
  if (s.isEmpty) return s;
  final last = s[s.length - 1];
  final long = _macron[last];
  return long == null ? s : s.substring(0, s.length - 1) + long;
}

String? _romajiOf(String mora) => _digraphs[mora] ?? _monographs[mora];

List<String> _toMorae(String katakana) {
  final chars = katakana.runes.map(String.fromCharCode).toList();
  final morae = <String>[];
  for (var i = 0; i < chars.length; i++) {
    if (i + 1 < chars.length && _digraphs.containsKey(chars[i] + chars[i + 1])) {
      morae.add(chars[i] + chars[i + 1]);
      i++;
    } else {
      morae.add(chars[i]);
    }
  }
  return morae;
}

/// 照合の結果。
class RomanizeResult {
  RomanizeResult.matched(this.value) : candidates = const [], reason = null;

  /// 値は作れたが、人の確認が要るもの。
  RomanizeResult.tentative(this.value, this.reason) : candidates = const [];
  RomanizeResult.failed(this.reason, {this.candidates = const []}) : value = null;

  /// 日本郵便の綴りに空白を戻した、マクロン付きの表記(大文字)。
  final String? value;

  /// 要確認の理由。確定したときは null。
  final String? reason;
  final List<String> candidates;

  bool get ok => value != null && reason == null;
}

/// カナと日本郵便のローマ字(例: `TOKYO TO`)から、マクロン付きの表記を作る。
///
/// 一致する候補がちょうど1つのときだけ確定する。0件・複数件は要確認にする。
/// 日本郵便の綴りが途中で切れているとき(`YAMATSURI MACH`)は、前方一致で補い、要確認にする。
RomanizeResult romanizeWithReference(String katakana, String reference) {
  final target = reference.replaceAll(' ', '');
  final List<String> candidates;
  try {
    candidates = romajiCandidates(katakana).map((c) => c.toUpperCase()).toSet().toList();
  } on FormatException catch (e) {
    return RomanizeResult.failed(e.message);
  }

  final exact = candidates.where((c) => stripMacrons(c) == target).toList();
  if (exact.length == 1) {
    return RomanizeResult.matched(_restoreSpaces(exact.single, reference));
  }
  if (exact.length > 1) {
    return RomanizeResult.failed('長音の位置が一通りに決まらない', candidates: exact);
  }

  final truncated = candidates.where((c) => stripMacrons(c).startsWith(target)).toList();
  if (truncated.length == 1) {
    final full = truncated.single;
    final head = _restoreSpaces(full.substring(0, target.length), reference);
    return RomanizeResult.tentative(
      _splitTrailingSuffix(head + full.substring(target.length)),
      '日本郵便の綴りが途中で切れている($reference)。カナから補った',
    );
  }
  if (truncated.length > 1) {
    return RomanizeResult.failed('日本郵便の綴りが途中で切れていて、長音の位置が決まらない',
        candidates: truncated);
  }
  return RomanizeResult.failed('日本郵便の綴りと一致する候補がない');
}

/// 参照する綴りが無いとき、カナだけから作る。長音の候補が無い(一通りに決まる)ときだけ値を返す。
/// 接尾辞(村・町など)の区切りは、末尾の1つだけ補う。
RomanizeResult romanizeWithoutReference(String katakana) {
  final candidates = romajiCandidates(katakana).map((c) => c.toUpperCase()).toSet();
  if (candidates.length != 1) {
    return RomanizeResult.failed('参照する綴りが無く、長音の位置が決まらない',
        candidates: candidates.toList());
  }
  return RomanizeResult.tentative(
    _splitTrailingSuffix(candidates.single),
    '参照する綴りが無い。カナから作った',
  );
}

/// 日本郵便の綴りと同じ位置に空白を戻す(マクロンの有無を除けば1文字ずつ対応する)。
String _restoreSpaces(String compact, String reference) {
  final out = StringBuffer();
  var j = 0;
  for (final c in reference.split('')) {
    if (j >= compact.length) break;
    out.write(c == ' ' ? ' ' : compact[j++]);
  }
  return out.toString();
}

/// 最後の語の末尾が接尾辞なら、空白で区切る。`ICHIKAWAMISATOCHŌ` → `ICHIKAWAMISATO CHŌ`。
String _splitTrailingSuffix(String upper) {
  final words = upper.split(' ');
  final last = words.last;
  for (final suffix in const ['MACHI', 'CHŌ', 'MURA', 'SON', 'SHI', 'KU']) {
    if (last.length > suffix.length && last.endsWith(suffix)) {
      words[words.length - 1] =
          '${last.substring(0, last.length - suffix.length)} $suffix';
      break;
    }
  }
  return words.join(' ');
}

/// 小書きのカナを大書きにする(総務省のカナは「シヨウ」のように大書きで書かれている)。
String toLargeKana(String katakana) {
  const small = 'ァィゥェォッャュョヮ';
  const large = 'アイウエオツヤユヨワ';
  return katakana.split('').map((c) {
    final i = small.indexOf(c);
    return i < 0 ? c : large[i];
  }).join();
}

const _suffixes = {'TO', 'DO', 'FU', 'KEN', 'SHI', 'KU', 'GUN', 'MACHI', 'CHŌ', 'CHO', 'MURA', 'SON'};

/// `MINAMIUONUMA GUN YUZAWA MACHI` → `Minamiuonuma-gun Yuzawa-machi`。
/// `TŌKYŌ TO` → `Tōkyō-to`。接尾辞(県・市・郡・町など)はハイフンでつなぎ、小文字にする。
String toLabelCase(String upper) {
  final tokens = upper.split(' ').where((t) => t.isNotEmpty).toList();
  final words = <String>[];
  for (final token in tokens) {
    if (_suffixes.contains(token) && words.isNotEmpty) {
      words[words.length - 1] = '${words.last}-${token.toLowerCase()}';
    } else {
      words.add(token[0] + token.substring(1).toLowerCase());
    }
  }
  return words.join(' ');
}
