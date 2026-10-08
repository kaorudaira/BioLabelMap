import 'dart:io';

import 'package:biolabelmap/domain/species_catalog.dart';
import 'package:biolabelmap/domain/species_name.dart';
import 'package:flutter_test/flutter_test.dart';

const _csv = '''﻿和名,学名\r
"クボタヒメハネカクシ","Atheta (Atheta) transfuga (Sharp, 1874)"\r
"カラカネナカボソタマムシ　基亜種","Coraebus ignotus ignotus E. Saunders, 1873"\r
"カラカネナカボソタマムシ　奄美亜種","Coraebus ignotus shibatai Y. Kurosawa, 1963"\r
"ザウターカレキハネカクシ","Chledophila sauteri (Bernhauer, 1907)"\r
"ヒメヒゲナガハナノミ","Drupeus laetabilis Lewis, 1895"\r
"ヒメヒゲナガハナノミ","Drupeus laetabilis Lewis, 1895"\r
"和名無し　沖縄島亜種","Himaloconnus klapperichianus okinawanus Jałoszyński, 2020"\r
"オガサワラアオゴミムシ","Platynus (?) ikedai (Kasahara, 1991)"\r
"ヒゲブトアリヅカムシ上族","Supertribe CLAVIGERITAE Leach, 1815"\r
"42): 61-66.","永幡嘉之, 1995. 鳥取県気高郡の灯火で採集したコガネムシ類に関する若干の知見. すかしば, (41"\r
"39):26.","中山紘一, 1980. 西熊山のカミキリムシ3種. げんせい, (38"\r
"ケシキスイ","Sandalus sauteri van Emden, 1924"\r
"ニセモノ","Genus species"\r
''';

void main() {
  _fieldSearchTests();
  _compareTests();
  final catalog = SpeciesCatalog.parseCsv(_csv);

  CatalogEntry find(String genus, String species, [String? subspecies]) =>
      catalog.entries.singleWhere((e) => e.genus == genus && e.species == species && e.subspecies == subspecies);

  group('取り込み', () {
    test('BOM・見出し・CRLF を読み飛ばし、学名の形でない行は捨てる', () {
      final names = catalog.entries.map((e) => '${e.genus} ${e.species}').toList();
      expect(names, isNot(contains('Supertribe CLAVIGERITAE')));
      expect(catalog.entries.every((e) => e.vernacularBase == null || !e.vernacularBase!.contains(RegExp(r'[0-9,]'))), isTrue);
      // 文献一覧の崩れた行、上位分類、命名者と年が無い行は入らない
      expect(catalog.entries, hasLength(8));
    });

    test('同じ和名・学名の重複は1件にする', () {
      expect(catalog.entries.where((e) => e.species == 'laetabilis'), hasLength(1));
    });

    test('亜属は学名に含めず、括弧つきの命名者・年はそのまま保持する', () {
      final e = find('Atheta', 'transfuga');
      expect(e.subgenus, 'Atheta');
      expect(e.authorship, '(Sharp, 1874)');
      expect(e.toSpeciesName().scientific, 'Atheta transfuga');
    });

    test('亜属が「?」の行も読む', () {
      final e = find('Platynus', 'ikedai');
      expect(e.subgenus, isNull);
      expect(e.authorship, '(Kasahara, 1991)');
    });

    test('亜種の注記は、基亜種も含めて、全角の空白でつないで和名に残す', () {
      expect(find('Coraebus', 'ignotus', 'ignotus').vernacular, 'カラカネナカボソタマムシ　基亜種');
      final other = find('Coraebus', 'ignotus', 'shibatai');
      expect(other.vernacular, 'カラカネナカボソタマムシ　奄美亜種');
      expect(other.vernacularBase, 'カラカネナカボソタマムシ');
    });

    test('「和名無し」は和名なしにする', () {
      final e = find('Himaloconnus', 'klapperichianus', 'okinawanus');
      expect(e.vernacular, isNull);
      expect(e.authorship, 'Jałoszyński, 2020');
    });

    test('命名者の頭の van などを、亜種と取り違えない', () {
      final e = find('Sandalus', 'sauteri');
      expect(e.subspecies, isNull);
      expect(e.authorship, 'van Emden, 1924');
    });
  });

  group('検索', () {
    test('和名・属・種のどれでも探せ、先頭が合うものが先に出る', () {
      expect(catalog.search('クボタ').single.species, 'transfuga');
      expect(catalog.search('atheta transfuga').single.species, 'transfuga');
      expect(catalog.search('sauteri').map((e) => e.genus), ['Chledophila', 'Sandalus']);
      expect(catalog.search('  '), isEmpty);
      expect(catalog.search('zzz'), isEmpty);
      expect(catalog.search('ignotus', limit: 1), hasLength(1));
    });
  });

  group('自動入力のための一致', () {
    test('和名が1つの種に一致すれば、その種を返す', () {
      expect(catalog.uniqueMatch(SpeciesName(vernacular: 'クボタヒメハネカクシ'))!.species, 'transfuga');
    });

    test('属と種が一致すれば返す。大文字小文字は区別しない', () {
      expect(catalog.uniqueMatch(SpeciesName(genus: 'chledophila', species: 'SAUTERI'))!.vernacular, 'ザウターカレキハネカクシ');
    });

    test('入力した項目が目録と食い違えば一致しない', () {
      expect(catalog.uniqueMatch(SpeciesName(vernacular: 'クボタヒメハネカクシ', genus: 'Atheta', species: 'other')), isNull);
    });

    test('属だけ・種だけ、何も無いときは一致させない', () {
      expect(catalog.uniqueMatch(SpeciesName(genus: 'Atheta')), isNull);
      expect(catalog.uniqueMatch(SpeciesName(species: 'transfuga')), isNull);
      expect(catalog.uniqueMatch(SpeciesName()), isNull);
    });

    test('亜種が複数ある和名・学名は、1つに決まらないので一致させない', () {
      expect(catalog.uniqueMatch(SpeciesName(vernacular: 'カラカネナカボソタマムシ')), isNull);
      expect(catalog.uniqueMatch(SpeciesName(genus: 'Coraebus', species: 'ignotus')), isNull);
    });

    test('亜種まで入力すれば一致する', () {
      final m = catalog.uniqueMatch(SpeciesName(genus: 'Coraebus', species: 'ignotus', subspecies: 'shibatai'))!;
      expect(m.authorship, 'Y. Kurosawa, 1963');
    });

    test('目録は亜種まで決まっているのに、入力に亜種が無いときは、亜種を決めつけない', () {
      final only = SpeciesCatalog.parseCsv('"和名無し　沖縄島亜種","Himaloconnus klapperichianus okinawanus Jałoszyński, 2020"');
      expect(only.uniqueMatch(SpeciesName(genus: 'Himaloconnus', species: 'klapperichianus')), isNull);
    });

    test('空の目録は何にも一致しない', () {
      expect(SpeciesCatalog.empty.uniqueMatch(SpeciesName(vernacular: 'x')), isNull);
    });
  });

  test('同梱の目録は、ほぼ全ての行を読める', () {
    // assets の実データ。読み込めない行は文献一覧などで、数百行に収まる
    final real = SpeciesCatalog.parseCsv(_readAsset());
    expect(real.entries.length, greaterThan(13000));
  });
}

String _readAsset() => File('assets/data/beetles_master.csv').readAsStringSync();

void _compareTests() {
  group('和名の50音順', () {
    List<String?> sorted(List<SpeciesName> list) =>
        (list..sort(compareByVernacular)).map((n) => n.vernacular ?? n.scientific).toList();

    test('ひらがなはカタカナとして比べ、和名の無い種は最後に回す', () {
      expect(
        sorted([
          SpeciesName(genus: 'Zeta', species: 'a'),
          SpeciesName(vernacular: 'ヒメハナ', genus: 'A', species: 'a'),
          SpeciesName(vernacular: 'あかむし', genus: 'B', species: 'b'),
          SpeciesName(vernacular: 'オサムシ', genus: 'C', species: 'c'),
          SpeciesName(vernacular: 'アオムシ', genus: 'D', species: 'd'),
        ]),
        ['アオムシ', 'あかむし', 'オサムシ', 'ヒメハナ', 'Zeta a'],
      );
    });

    test('濁音は清音の直後、注記つきは注記なしの前後で安定して並ぶ', () {
      expect(
        sorted([
          SpeciesName(vernacular: 'ガ', genus: 'A', species: 'a'),
          SpeciesName(vernacular: 'キ', genus: 'A', species: 'b'),
          SpeciesName(vernacular: 'カ', genus: 'A', species: 'c'),
        ]),
        ['カ', 'ガ', 'キ'],
      );
    });

    test('同じ和名は、学名の順にする', () {
      final list = [
        SpeciesName(vernacular: 'ア', genus: 'B', species: 'x'),
        SpeciesName(vernacular: 'ア', genus: 'A', species: 'y'),
      ]..sort(compareByVernacular);
      expect(list.map((n) => n.genus), ['A', 'B']);
    });
  });
}

void _fieldSearchTests() {
  group('欄ごとの検索', () {
    final catalog = SpeciesCatalog.parseCsv(
      '"ア","Carabus ignotus Bates, 1883"\n'
      '"イ","Another carabus Bates, 1883"\n'
      '"カラバス","Third species Bates, 1883"\n'
      '"ウ　奄美亜種","Coraebus ignotus shibatai Kurosawa, 1963"',
    );
    List<String> genera(SpeciesNameQuery q) => catalog.searchFields(q, limit: null).map((e) => e.genus).toList();

    test('属名は属名だけ、種小名は種小名だけ、亜種名は亜種名だけ、和名は和名だけを探す', () {
      expect(genera(const SpeciesNameQuery(genus: 'carabus')), ['Carabus']);
      expect(genera(const SpeciesNameQuery(species: 'carabus')), ['Another']);
      expect(genera(const SpeciesNameQuery(subspecies: 'shiba')), ['Coraebus']);
      expect(genera(const SpeciesNameQuery(vernacular: 'カラバス')), ['Third']);
      expect(genera(const SpeciesNameQuery(vernacular: 'carabus')), isEmpty);
    });

    test('入力した欄は、すべて条件になる(別の欄に打った文字とも合うものだけ)', () {
      expect(genera(const SpeciesNameQuery(genus: 'co', species: 'ignotus')), ['Coraebus']);
      expect(genera(const SpeciesNameQuery(genus: 'car', species: 'ignotus')), ['Carabus']);
      expect(genera(const SpeciesNameQuery(genus: 'zzz', species: 'ignotus')), isEmpty);
    });

    test('条件が空なら何も返さない。大文字小文字は区別せず、前後の空白は無視する', () {
      expect(const SpeciesNameQuery().isEmpty, isTrue);
      expect(const SpeciesNameQuery(genus: '  ').isEmpty, isTrue);
      expect(catalog.searchFields(const SpeciesNameQuery()), isEmpty);
      expect(genera(const SpeciesNameQuery(genus: ' CARABUS ')), ['Carabus']);
    });

    test('先頭が合うものを先に並べる', () {
      final c = SpeciesCatalog.parseCsv(
        '"ア","Xcarabus one Bates, 1883"\n'
        '"イ","Carabus two Bates, 1883"',
      );
      expect(c.searchFields(const SpeciesNameQuery(genus: 'carabus'), limit: null).map((e) => e.genus), ['Carabus', 'Xcarabus']);
    });
  });
}
