/// 同定の種名(和名・学名・命名者)。標本一覧で「同じ種」をまとめる単位にもなる。
class SpeciesName {
  const SpeciesName._({this.vernacular, this.genus, this.species, this.subspecies, this.authorship});

  /// 空白だけの項目は、無いものとして扱う。
  factory SpeciesName({
    String? vernacular,
    String? genus,
    String? species,
    String? subspecies,
    String? authorship,
  }) => SpeciesName._(
    vernacular: _clean(vernacular),
    genus: _clean(genus),
    species: _clean(species),
    subspecies: _clean(subspecies),
    authorship: _clean(authorship),
  );

  static const unidentified = SpeciesName._();

  static String? _clean(String? s) {
    final t = s?.trim();
    return t == null || t.isEmpty ? null : t;
  }

  final String? vernacular;
  final String? genus;
  final String? species;
  final String? subspecies;

  /// 命名者・年。括弧の有無は入力どおり。
  final String? authorship;

  /// 和名も学名も無い。
  bool get isEmpty => vernacular == null && scientific == null;

  /// 学名(属・種・亜種を空白でつないだもの)。無ければ null。
  String? get scientific {
    final parts = [genus, species, subspecies].whereType<String>();
    return parts.isEmpty ? null : parts.join(' ');
  }

  /// 一覧に出す名前。和名と学名の両方があれば並べ、無ければ「未同定」。
  String get label {
    if (isEmpty) return '未同定';
    return [vernacular, scientific].whereType<String>().join(' ');
  }

  /// 同じ種かどうかの判定用。命名者も含める。
  String get key => [vernacular, genus, species, subspecies, authorship].map((e) => e ?? '').join('\u0000');

  @override
  bool operator ==(Object other) => other is SpeciesName && other.key == key;

  @override
  int get hashCode => key.hashCode;
}

/// 和名の50音順に並べる比較(候補の一覧用)。ひらがなはカタカナとして比べる。
/// 和名の無い種は最後に回し、同じ和名(または和名なし)どうしは学名の順にする。
int compareByVernacular(SpeciesName a, SpeciesName b) {
  final x = a.vernacular, y = b.vernacular;
  if (x == null || y == null) {
    if (x != null) return -1;
    if (y != null) return 1;
  } else {
    final c = _kanaKey(x).compareTo(_kanaKey(y));
    if (c != 0) return c;
  }
  return (a.scientific ?? '').toLowerCase().compareTo((b.scientific ?? '').toLowerCase());
}

String _kanaKey(String s) => String.fromCharCodes([
  for (final c in s.runes) c >= 0x3041 && c <= 0x3096 ? c + 0x60 : c,
]);

/// 種名の検索条件。入力した項目だけが条件になり、候補の同じ項目に含まれていなければならない
/// (属名の欄に打った文字は属名だけを、種小名の欄に打った文字は種小名だけを探す)。
/// 大文字小文字は区別しない。
class SpeciesNameQuery {
  const SpeciesNameQuery({this.vernacular = '', this.genus = '', this.species = '', this.subspecies = ''});

  final String vernacular;
  final String genus;
  final String species;
  final String subspecies;

  bool get isEmpty =>
      vernacular.trim().isEmpty && genus.trim().isEmpty && species.trim().isEmpty && subspecies.trim().isEmpty;

  /// 条件の文字(空白を除いた小文字)が、候補の同じ項目に含まれているか。
  bool matchesFields({String? vernacular, String? genus, String? species, String? subspecies}) =>
      _has(vernacular, this.vernacular) &&
      _has(genus, this.genus) &&
      _has(species, this.species) &&
      _has(subspecies, this.subspecies);

  bool matches(SpeciesName n) => matchesFields(
    vernacular: n.vernacular,
    genus: n.genus,
    species: n.species,
    subspecies: n.subspecies,
  );

  static bool _has(String? field, String query) {
    final q = query.trim().toLowerCase();
    return q.isEmpty || (field ?? '').toLowerCase().contains(q);
  }
}
