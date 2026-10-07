import 'species_name.dart';

/// 甲虫の目録(和名と学名)の1件。同定入力の自動入力と候補に使う(要件定義 S-06)。
class CatalogEntry {
  CatalogEntry({
    this.vernacularBase,
    this.annotation,
    required this.genus,
    this.subgenus,
    required this.species,
    this.subspecies,
    this.authorship,
  }) : _haystack = [vernacularBase, genus, subgenus, species, subspecies].whereType<String>().join(' ').toLowerCase();

  /// 和名。亜種の注記(`九州亜種` など)を除いたもの。和名が無いときは null。
  final String? vernacularBase;

  /// 和名の後ろの注記(`基亜種`、`九州亜種` など)。
  final String? annotation;
  final String genus;

  /// 亜属。ラベルには載せないので、検索の手がかりにだけ使う。
  final String? subgenus;
  final String species;
  final String? subspecies;

  /// 命名者・年。括弧の有無は目録のとおり。
  final String? authorship;

  final String _haystack;

  /// 入力欄に入れる和名。亜種の注記があれば全角の空白でつなぐ(`カワラハンミョウ　九州亜種`)。
  String? get vernacular {
    final base = vernacularBase;
    if (base == null) return null;
    final note = annotation;
    return note == null ? base : '$base　$note';
  }

  SpeciesName toSpeciesName() => SpeciesName(
    vernacular: vernacular,
    genus: genus,
    species: species,
    subspecies: subspecies,
    authorship: authorship,
  );
}

/// 甲虫の目録。CSV(和名,学名の2列)から作る。
///
/// 出典は「日本産甲虫目録」(https://japanesebeetles.jimdofree.com/)。
/// 取り込みでは、文献一覧のように学名の形をしていない行は読み飛ばす。
class SpeciesCatalog {
  SpeciesCatalog(this.entries);

  static final empty = SpeciesCatalog(const []);

  /// `和名,学名` の CSV から作る。先頭行(見出し)と BOM、読めない行は無視する。
  factory SpeciesCatalog.parseCsv(String csv) {
    final entries = <CatalogEntry>[];
    final seen = <String>{};
    for (final line in csv.replaceFirst('﻿', '').split(RegExp(r'\r?\n'))) {
      final match = _line.firstMatch(line);
      if (match == null) continue;
      final entry = parseCatalogEntry(_unquote(match.group(1)!), _unquote(match.group(2)!));
      if (entry == null) continue;
      // 同じ和名・学名の重複は1件にする
      if (seen.add('${entry.vernacular}\u0000${entry.genus} ${entry.species} ${entry.subspecies} ${entry.authorship}')) {
        entries.add(entry);
      }
    }
    return SpeciesCatalog(entries);
  }

  static final _line = RegExp(r'^"((?:[^"]|"")*)","((?:[^"]|"")*)"$');
  static String _unquote(String s) => s.replaceAll('""', '"');

  final List<CatalogEntry> entries;

  /// 和名・属・亜属・種・亜種に [query] を含む種を返す。空白で区切った語は、すべてを含むものだけ。
  /// 先頭が一致するものを先に並べる。[limit] が null なら、合うものを全て返す。
  List<CatalogEntry> search(String query, {int? limit = 8}) {
    final words = query.trim().toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return const [];
    final starts = <CatalogEntry>[];
    final contains = <CatalogEntry>[];
    for (final e in entries) {
      if (!words.every(e._haystack.contains)) continue;
      (e._haystack.startsWith(words.first) ? starts : contains).add(e);
      if (limit != null && starts.length >= limit) break;
    }
    final all = [...starts, ...contains];
    return limit == null ? all : all.take(limit).toList();
  }

  /// 入力した種名に完全に一致する種が1つだけあれば、それを返す(自動入力用)。
  ///
  /// 入力済みの項目(和名・属・種・亜種)は、すべて目録と一致していなければならない。
  /// 一致するものが複数あるとき(亜種が複数ある、同じ和名が複数の種に付くなど)は null。
  /// 入力が和名だけ、または属と種だけでも判定する。入力に無い亜種を目録の側が持つときは、
  /// 亜種まで決めつけないよう、自動入力しない。
  CatalogEntry? uniqueMatch(SpeciesName typed) {
    final vernacular = typed.vernacular;
    final hasScientific = typed.genus != null && typed.species != null;
    if (vernacular == null && !hasScientific) return null;
    if ((typed.genus != null) != (typed.species != null)) return null;

    bool same(String? a, String? b) => (a ?? '').toLowerCase() == (b ?? '').toLowerCase();
    CatalogEntry? found;
    for (final e in entries) {
      if (vernacular != null && vernacular != e.vernacular && vernacular != e.vernacularBase) continue;
      if (hasScientific && !(same(typed.genus, e.genus) && same(typed.species, e.species))) continue;
      if (typed.subspecies != null && !same(typed.subspecies, e.subspecies)) continue;
      if (found != null) return null;
      found = e;
    }
    if (found == null) return null;
    // 目録は亜種まで決まっているのに、入力に亜種が無い
    if (found.subspecies != null && typed.subspecies == null) return null;
    return found;
  }
}

/// 学名の姓名の前に付く語(`van Emden` など)。亜種名と取り違えない。
const _particles = {'van', 'von', 'de', 'der', 'den', 'du', 'la', 'le', 'di', 'da', 'del', 'dos', 'ten', 'des'};

final _scientific = RegExp(
  r'^([A-Z][a-z]+)'
  r'(?: \(([A-Z][a-z]+|\?)\))?'
  r' ([a-z][a-z-]+)'
  r'(?: ([a-z][a-z-]+))?'
  r'(?: (.+))?$',
);

/// 目録の1行(和名、学名)を読む。学名の形でなければ(文献一覧の崩れた行など) null。
CatalogEntry? parseCatalogEntry(String vernacularField, String scientificField) {
  final vernacular = vernacularField.trim();
  final scientific = scientificField.trim();
  if (vernacular.isEmpty || vernacular.contains(RegExp(r'[0-9,、.]'))) return null;
  final m = _scientific.firstMatch(scientific);
  if (m == null) return null;

  var subspecies = m.group(4);
  var authorship = m.group(5);
  // 命名者の頭の語(`van Emden` など)を、亜種と取り違えた場合は戻す
  if (subspecies != null && _particles.contains(subspecies)) {
    authorship = authorship == null ? subspecies : '$subspecies $authorship';
    subspecies = null;
  }
  // 学名には命名者と年がある。無い行は、学名の途中で切れたものとして捨てる
  if (authorship == null || !RegExp(r'\d{4}').hasMatch(authorship)) return null;

  final parts = vernacular.split('　');
  final base = parts.first.trim();
  final note = parts.skip(1).join('　').trim();
  return CatalogEntry(
    vernacularBase: base == '和名無し' || base.isEmpty ? null : base,
    annotation: note.isEmpty || base == '和名無し' ? null : note,
    genus: m.group(1)!,
    subgenus: m.group(2) == '?' ? null : m.group(2),
    species: m.group(3)!,
    subspecies: subspecies,
    authorship: authorship.trim(),
  );
}

/// [SpeciesCatalog.parseCsv] の関数版。`compute` で別のスレッドに渡すために置く。
SpeciesCatalog parseCatalogCsv(String csv) => SpeciesCatalog.parseCsv(csv);
