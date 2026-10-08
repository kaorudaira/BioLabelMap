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
