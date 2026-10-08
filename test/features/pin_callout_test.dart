import 'package:biolabelmap/core/db/database.dart';
import 'package:biolabelmap/domain/models/calendar_date.dart';
import 'package:biolabelmap/domain/models/collection_period.dart';
import 'package:biolabelmap/domain/sampling_method.dart';
import 'package:biolabelmap/domain/specimen_list.dart';
import 'package:biolabelmap/domain/species_name.dart';
import 'package:biolabelmap/domain/status.dart';
import 'package:biolabelmap/features/map/pin_callout.dart';
import 'package:biolabelmap/services/service_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

SpecimenListItem item(int n, {SpeciesName species = SpeciesName.unidentified, bool atSpot = true}) => SpecimenListItem(
  id: n,
  catalogNumber: n,
  catalogText: 'KYC${n.toString().padLeft(5, '0')}',
  localityId: 1,
  period: CollectionPeriod.singleDay(CalendarDate(2026, 6, 20)),
  method: SamplingMethod.sweeping,
  methodLabel: 'スウィーピング',
  species: species,
  status: IdentificationStatus.unidentified,
  placeJa: '',
  placeEn: '',
  printed: false,
  latE4: atSpot ? 369447 : 350000,
  lonE4: atSpot ? 1392425 : 1390000,
);

Locality locality({String? prefecture = '新潟県', String? municipality = '魚沼市', String? place = '下折立', FetchStatus placeStatus = FetchStatus.fetched}) => Locality(
  id: 1,
  latitude: 36.94471,
  longitude: 139.24258,
  latE4: 369447,
  lonE4: 1392425,
  isManualPosition: false,
  elevationStatus: FetchStatus.fetched,
  country: 'JAPAN',
  prefectureJa: prefecture,
  municipalityJa: municipality,
  localityJa: place,
  placeStatus: placeStatus,
  createdAt: DateTime(2026, 6, 20),
);

void main() {
  final carabus = SpeciesName(vernacular: 'オサムシ', genus: 'Carabus', species: 'a');
  final atheta = SpeciesName(vernacular: 'クボタヒメハネカクシ', genus: 'Atheta', species: 'b');
  final noVernacular = SpeciesName(genus: 'Zeta', species: 'c');

  Future<void> pumpBubble(WidgetTester tester, Locality l, List<SpecimenListItem> items) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localityProvider(1).overrideWith((ref) => Stream.value(l)),
          specimenItemsProvider.overrideWith((ref) => Stream.value(items)),
        ],
        child: const MaterialApp(home: Scaffold(body: Center(child: PinBubble(localityId: 1)))),
      ),
    );
    await tester.pump();
  }

  group('吹き出し', () {
    testWidgets('日本語の住所と、登録されている和名(件数つき)を出す', (tester) async {
      await pumpBubble(tester, locality(), [
        item(1, species: carabus),
        item(2, species: carabus),
        item(3, species: atheta),
        item(4),
        item(5),
        item(6, atSpot: false, species: noVernacular), // 別の場所の標本は出さない
      ]);
      expect(find.text('新潟県魚沼市下折立'), findsOneWidget);
      expect(find.text('オサムシ ×2'), findsOneWidget);
      expect(find.text('クボタヒメハネカクシ'), findsOneWidget);
      expect(find.text('未同定 ×2'), findsOneWidget);
      expect(find.textContaining('Zeta'), findsNothing);
    });

    testWidgets('和名が無い種は学名を出す', (tester) async {
      await pumpBubble(tester, locality(), [item(1, species: noVernacular)]);
      expect(find.text('Zeta c'), findsOneWidget);
    });

    testWidgets('地名が取得前のときは、その旨を出す', (tester) async {
      await pumpBubble(
        tester,
        locality(prefecture: null, municipality: null, place: null, placeStatus: FetchStatus.pending),
        [item(1)],
      );
      expect(find.text('地名 取得待ち'), findsOneWidget);
    });

    testWidgets('標本が無ければ、その旨を出す', (tester) async {
      await pumpBubble(tester, locality(), const []);
      expect(find.text('標本はありません'), findsOneWidget);
    });
  });

  group('ウィンドウ', () {
    testWidgets('「この地点で追加」「詳細をひらく」を出し、押すとそれぞれの動作を呼ぶ。×で閉じる', (tester) async {
      final calls = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PinActionCard(
              onAdd: () => calls.add('追加'),
              onOpenDetail: () => calls.add('詳細'),
              onClose: () => calls.add('閉じる'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('この地点で追加'));
      await tester.tap(find.text('詳細をひらく'));
      await tester.tap(find.byTooltip('閉じる'));
      expect(calls, ['追加', '詳細', '閉じる']);
    });
  });

  group('和名の一覧(speciesSummaryLines)', () {
    List<SpecimenListItem> many(int species) => [
      for (var i = 0; i < species; i++) item(i + 1, species: SpeciesName(vernacular: 'ア${String.fromCharCode(0x30A2 + i * 2)}', genus: 'G$i', species: 's')),
    ];

    test('件数の多い順。同じ件数は和名の50音順。未同定は最後', () {
      final lines = speciesSummaryLines([
        item(1, species: atheta),
        item(2),
        item(3, species: carabus),
        item(4, species: carabus),
        item(5, species: SpeciesName(vernacular: 'アカ', genus: 'A', species: 'a')),
      ]);
      expect(lines, ['オサムシ ×2', 'アカ', 'クボタヒメハネカクシ', '未同定']);
    });

    test('入りきらない種は「ほかN種」にまとめる(未同定の行は残す)', () {
      expect(speciesSummaryLines(many(7)), ['アア', 'アイ', 'アウ', 'ほか4種']);
      expect(speciesSummaryLines([...many(7), item(100)]), ['アア', 'アイ', 'ほか5種', '未同定']);
    });

    test('ちょうど入るときは、まとめない', () {
      expect(speciesSummaryLines(many(4)), hasLength(4));
      expect(speciesSummaryLines(many(4)).any((l) => l.startsWith('ほか')), isFalse);
    });

    test('標本が無ければ空', () => expect(speciesSummaryLines(const []), isEmpty));
  });
}
