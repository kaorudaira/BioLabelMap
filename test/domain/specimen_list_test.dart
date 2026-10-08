import 'package:biolabelmap/domain/models/calendar_date.dart';
import 'package:biolabelmap/domain/models/collection_period.dart';
import 'package:biolabelmap/domain/sampling_method.dart';
import 'package:biolabelmap/domain/specimen_list.dart';
import 'package:biolabelmap/domain/species_name.dart';
import 'package:biolabelmap/domain/status.dart';
import 'package:flutter_test/flutter_test.dart';

SpecimenListItem item(
  int number, {
  int localityId = 1,
  CollectionPeriod? period,
  SamplingMethod method = SamplingMethod.sweeping,
  String? methodLabel,
  SpeciesName species = SpeciesName.unidentified,
  IdentificationStatus status = IdentificationStatus.unidentified,
  String placeJa = '新潟県魚沼市下折立',
  String placeEn = 'Shimooritate Uonuma-shi Niigata-ken',
  bool printed = false,
  String prefix = 'KYC',
}) => SpecimenListItem(
  id: number,
  catalogNumber: number,
  catalogText: '$prefix${number.toString().padLeft(5, '0')}',
  localityId: localityId,
  period: period ?? CollectionPeriod.singleDay(CalendarDate(2026, 6, 20)),
  method: method,
  methodLabel: methodLabel ?? method.nameJa,
  species: species,
  status: status,
  placeJa: placeJa,
  placeEn: placeEn,
  printed: printed,
);

void main() {
  final carabus = SpeciesName(vernacular: 'オサムシ', genus: 'Carabus', species: 'insulicola');

  group('SpeciesName', () {
    test('空白だけの項目は無いものとして扱う', () {
      final n = SpeciesName(vernacular: '  ', genus: ' Carabus ', species: '');
      expect(n.vernacular, isNull);
      expect(n.scientific, 'Carabus');
    });

    test('表示は和名と学名を並べ、何も無ければ未同定', () {
      expect(carabus.label, 'オサムシ Carabus insulicola');
      expect(SpeciesName(genus: 'Carabus', species: 'a', subspecies: 'b').label, 'Carabus a b');
      expect(SpeciesName(vernacular: 'オサムシ').label, 'オサムシ');
      expect(SpeciesName.unidentified.label, '未同定');
      expect(SpeciesName(authorship: 'Linnaeus, 1758').isEmpty, isTrue);
    });

    test('命名者が違えば別の種として扱う', () {
      final a = SpeciesName(genus: 'Carabus', species: 'x', authorship: '(Linnaeus, 1758)');
      final b = SpeciesName(genus: 'Carabus', species: 'x', authorship: 'Linnaeus, 1758');
      expect(a, isNot(b));
      expect(a, SpeciesName(genus: 'Carabus', species: 'x', authorship: '(Linnaeus, 1758)'));
    });
  });

  group('グループ化', () {
    test('種・日付・地点・採集方法が同じ標本を1行にまとめる', () {
      final groups = groupSpecimens([
        item(120, species: carabus),
        item(121, species: carabus),
        item(122, species: carabus),
        item(123), // 未同定
        item(124, species: carabus, localityId: 2),
        item(125, species: carabus, period: CollectionPeriod.singleDay(CalendarDate(2026, 6, 21))),
        item(126, species: carabus, method: SamplingMethod.looking),
      ]);
      expect(groups.map((g) => g.count), [3, 1, 1, 1, 1]);
    });

    test('「その他」は、自由入力の名前が違えば別の行になる', () {
      final groups = groupSpecimens([
        item(1, method: SamplingMethod.other, methodLabel: '灯火'),
        item(2, method: SamplingMethod.other, methodLabel: '朽木割り'),
      ]);
      expect(groups, hasLength(2));
    });

    test('標本番号は連続する範囲ごとにまとめ、順序が乱れていても番号順に並べる', () {
      final group = SpecimenGroup([item(122), item(120), item(121), item(125)]);
      expect(group.catalogRuns, 'KYC00120〜122, KYC00125');
      expect(group.items.map((i) => i.catalogNumber), [120, 121, 122, 125]);
    });

    test('接頭辞を後で変えても、既存の標本は元の番号のまま表示する', () {
      final group = SpecimenGroup([item(9, prefix: 'OLD'), item(10, prefix: 'NEW')]);
      expect(group.catalogRuns, 'OLD00009〜NEW00010');
      expect(SpecimenGroup([item(1)]).catalogRuns, 'KYC00001');
    });

    test('1件でも未印刷があれば、行に未印刷のマークを付ける', () {
      expect(SpecimenGroup([item(1, printed: true), item(2)]).hasUnprinted, isTrue);
      expect(SpecimenGroup([item(1, printed: true)]).hasUnprinted, isFalse);
    });
  });

  group('検索と絞り込み', () {
    final items = [
      item(1, species: carabus, status: IdentificationStatus.provisional, printed: true),
      item(2, placeJa: '長野県松本市', placeEn: 'Matsumoto-shi Nagano-ken', method: SamplingMethod.lightTrap),
      item(
        3,
        period: CollectionPeriod(CalendarDate(2026, 6, 28), CalendarDate(2026, 7, 3)),
        method: SamplingMethod.pitfallTrap,
      ),
    ];

    List<int> ids(SpecimenFilter f) => arrangeSpecimens(items, filter: f, sort: SpecimenSort.catalog).map((g) => g.first.id).toList();

    test('条件が無ければ全て', () {
      expect(ids(const SpecimenFilter()), [1, 2, 3]);
      expect(const SpecimenFilter().isActive, isFalse);
    });

    test('検索は種名・地名(和・英)・標本番号を横断し、大文字小文字を区別しない', () {
      expect(ids(const SpecimenFilter(query: 'carabus')), [1]);
      expect(ids(const SpecimenFilter(query: 'オサムシ')), [1]);
      expect(ids(const SpecimenFilter(query: '松本')), [2]);
      expect(ids(const SpecimenFilter(query: 'nagano')), [2]);
      expect(ids(const SpecimenFilter(query: '00003')), [3]);
    });

    test('空白で区切った語は、すべてに合致するものだけ', () {
      expect(ids(const SpecimenFilter(query: 'carabus 魚沼')), [1]);
      expect(ids(const SpecimenFilter(query: 'carabus 松本')), isEmpty);
    });

    test('採集日の範囲に少しでも重なる期間を残す', () {
      expect(ids(SpecimenFilter(from: CalendarDate(2026, 7, 1))), [3]);
      expect(ids(SpecimenFilter(to: CalendarDate(2026, 6, 27))), [1, 2]);
      expect(ids(SpecimenFilter(from: CalendarDate(2026, 6, 21), to: CalendarDate(2026, 6, 27))), isEmpty);
    });

    test('採集方法・同定状態・印刷状態・地名で絞る', () {
      expect(ids(const SpecimenFilter(methods: {SamplingMethod.lightTrap})), [2]);
      expect(ids(const SpecimenFilter(statuses: {IdentificationStatus.provisional})), [1]);
      expect(ids(const SpecimenFilter(unprintedOnly: true)), [2, 3]);
      expect(ids(const SpecimenFilter(place: '長野')), [2]);
      expect(const SpecimenFilter(unprintedOnly: true).hasConditions, isTrue);
      expect(const SpecimenFilter(query: 'a').hasConditions, isFalse);
    });

    test('copyWith は、日付を null にして解除できる', () {
      final f = SpecimenFilter(from: CalendarDate(2026, 1, 1));
      expect(f.copyWith(query: 'x').from, CalendarDate(2026, 1, 1));
      expect(f.copyWith(from: null).from, isNull);
    });
  });

  group('並び', () {
    final a = item(1, period: CollectionPeriod.singleDay(CalendarDate(2026, 5, 1)), species: SpeciesName(genus: 'Zeta'), placeJa: 'ろ');
    final b = item(2, period: CollectionPeriod.singleDay(CalendarDate(2026, 7, 1)), placeJa: 'は');
    final c = item(3, period: CollectionPeriod.singleDay(CalendarDate(2026, 6, 1)), species: SpeciesName(genus: 'Alpha'), placeJa: 'い');
    List<int> order(SpecimenSort s) => arrangeSpecimens([a, b, c], sort: s).map((g) => g.first.id).toList();

    test('採集日は新しい順が既定', () => expect(order(SpecimenSort.dateDesc), [2, 3, 1]));
    test('標本番号順', () => expect(order(SpecimenSort.catalog), [1, 2, 3]));
    test('種ごとは学名順で、未同定は最後', () => expect(order(SpecimenSort.species), [3, 1, 2]));
    test('場所順', () => expect(order(SpecimenSort.place), [3, 2, 1]));
  });

  group('表示の整形', () {
    test('採集日', () {
      CollectionPeriod p(CalendarDate s, CalendarDate e) => CollectionPeriod(s, e);
      expect(formatPeriodText(CollectionPeriod.singleDay(CalendarDate(2026, 6, 20))), '2026/6/20');
      expect(formatPeriodText(p(CalendarDate(2026, 6, 19), CalendarDate(2026, 6, 20))), '2026/6/19〜20');
      expect(formatPeriodText(p(CalendarDate(2026, 6, 19), CalendarDate(2026, 6, 20)), withYear: false), '6/19〜20');
      expect(formatPeriodText(p(CalendarDate(2026, 6, 28), CalendarDate(2026, 7, 3))), '2026/6/28〜7/3');
      expect(formatPeriodText(p(CalendarDate(2025, 12, 30), CalendarDate(2026, 1, 2))), '2025/12/30〜2026/1/2');
    });

    test('和文の地名は、取得できた項目だけをつなぐ', () {
      expect(formatPlaceJa(prefecture: '新潟県', municipality: '魚沼市', locality: '下折立'), '新潟県魚沼市下折立');
      expect(formatPlaceJa(prefecture: '長野県', county: '北安曇郡', municipality: '白馬村'), '長野県北安曇郡白馬村');
      expect(formatPlaceJa(), '');
    });
  });
}
