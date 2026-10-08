import 'package:biolabelmap/core/db/database.dart';
import 'package:biolabelmap/domain/models/calendar_date.dart';
import 'package:biolabelmap/domain/models/collection_period.dart';
import 'package:biolabelmap/domain/sampling_method.dart';
import 'package:biolabelmap/domain/specimen_list.dart';
import 'package:biolabelmap/domain/species_name.dart';
import 'package:biolabelmap/domain/status.dart';
import 'package:biolabelmap/features/specimen/locality_detail_screen.dart';
import 'package:biolabelmap/services/service_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

SpecimenListItem item(
  int n, {
  int localityId = 1,
  SpeciesName species = SpeciesName.unidentified,
  CollectionPeriod? period,
  SamplingMethod method = SamplingMethod.sweeping,
}) => SpecimenListItem(
  id: n,
  catalogNumber: n,
  catalogText: 'KYC${n.toString().padLeft(5, '0')}',
  localityId: localityId,
  period: period ?? CollectionPeriod.singleDay(CalendarDate(2026, 6, 20)),
  method: method,
  methodLabel: method.nameJa,
  species: species,
  status: species.isEmpty ? IdentificationStatus.unidentified : IdentificationStatus.provisional,
  placeJa: '新潟県魚沼市下折立',
  placeEn: 'Shimooritate',
  printed: false,
);

final _locality = Locality(
  id: 1,
  latitude: 36.94471,
  longitude: 139.24258,
  latE4: 369447,
  lonE4: 1392425,
  isManualPosition: false,
  elevationMeters: 1390.4,
  elevationStatus: FetchStatus.fetched,
  country: 'JAPAN',
  prefectureJa: '新潟県',
  municipalityJa: '魚沼市',
  localityJa: '下折立',
  prefectureEn: 'Niigata-ken',
  municipalityEn: 'Uonuma-shi',
  localityEn: 'Shimooritate',
  placeStatus: FetchStatus.fetched,
  createdAt: DateTime(2026, 6, 20),
);

void main() {
  final carabus = SpeciesName(vernacular: 'オサムシ', genus: 'Carabus', species: 'insulicola');
  final atheta = SpeciesName(vernacular: 'クボタ', genus: 'Atheta', species: 'transfuga');

  Future<void> pump(WidgetTester tester, List<SpecimenListItem> items, {Locality? locality}) async {
    final router = GoRouter(
      initialLocation: '/localities/1',
      routes: [
        GoRoute(path: '/localities/:id', builder: (_, _) => const LocalityDetailScreen(localityId: 1)),
        GoRoute(path: '/specimens/:id', builder: (_, s) => Text('詳細 ${s.pathParameters['id']}')),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localityProvider(1).overrideWith((ref) => Stream.value(locality ?? _locality)),
          specimenItemsProvider.overrideWith((ref) => Stream.value(items)),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
  }

  testWidgets('ヘッダーに、地名(和・英)・緯度経度・標高・件数と採集日の範囲を出す', (tester) async {
    await pump(tester, [
      item(1, species: carabus),
      item(2, species: carabus, period: CollectionPeriod(CalendarDate(2026, 6, 19), CalendarDate(2026, 6, 20))),
      item(3, species: atheta, period: CollectionPeriod.singleDay(CalendarDate(2026, 7, 2))),
      item(9, localityId: 2), // 別の地点の標本は数えない
    ]);
    expect(find.text('新潟県魚沼市下折立'), findsWidgets);
    expect(find.text('Niigata-ken, Uonuma-shi, Shimooritate'), findsOneWidget);
    expect(find.text('36.94471°N 139.24258°E  標高 1390 m'), findsOneWidget);
    expect(find.text('3件、2026/6/19〜7/2'), findsOneWidget);
  });

  testWidgets('行は、同じ場所なので地名を出さず、採集日は年も出す', (tester) async {
    await pump(tester, [
      item(1, species: carabus, period: CollectionPeriod(CalendarDate(2026, 6, 19), CalendarDate(2026, 6, 20))),
      item(2, species: carabus, period: CollectionPeriod(CalendarDate(2026, 6, 19), CalendarDate(2026, 6, 20))),
    ]);
    expect(find.text('2026/6/19〜20'), findsOneWidget);
    expect(find.text('×2  KYC00001〜2'), findsOneWidget);
    expect(find.textContaining('新潟県魚沼市下折立  '), findsNothing);
  });

  testWidgets('並びは日付順(新しい日から)が既定で、「種ごと」に切り替えられる', (tester) async {
    await pump(tester, [
      item(1, species: carabus, period: CollectionPeriod.singleDay(CalendarDate(2026, 7, 1))),
      item(2, species: atheta, period: CollectionPeriod.singleDay(CalendarDate(2026, 5, 1))),
    ]);
    double y(String text) => tester.getTopLeft(find.textContaining(text)).dy;
    expect(y('オサムシ'), lessThan(y('クボタ'))); // 7月が先

    await tester.tap(find.text('種ごと'));
    await tester.pump();
    expect(y('クボタ'), lessThan(y('オサムシ'))); // 学名順: Atheta, Carabus
    await tester.tap(find.text('日付順'));
    await tester.pump();
    expect(y('オサムシ'), lessThan(y('クボタ')));
  });

  testWidgets('標本が無い地点は、案内を出す', (tester) async {
    await pump(tester, []);
    expect(find.text('この地点の標本はありません'), findsOneWidget);
    expect(find.text('この地点で追加'), findsOneWidget);
  });

  testWidgets('地点が見つからなければ案内を出す', (tester) async {
    final router = GoRouter(
      initialLocation: '/localities/1',
      routes: [GoRoute(path: '/localities/:id', builder: (_, _) => const LocalityDetailScreen(localityId: 1))],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localityProvider(1).overrideWith((ref) => Stream.value(null)),
          specimenItemsProvider.overrideWith((ref) => Stream.value(const [])),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    expect(find.text('地点が見つかりません'), findsOneWidget);
  });

  testWidgets('行をタップすると標本詳細を開く', (tester) async {
    await pump(tester, [item(4, species: carabus)]);
    await tester.tap(find.textContaining('オサムシ'));
    await tester.pumpAndSettle();
    expect(find.text('詳細 4'), findsOneWidget);
  });
}
