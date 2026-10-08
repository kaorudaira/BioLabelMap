import 'package:biolabelmap/core/db/database.dart';
import 'package:biolabelmap/domain/models/calendar_date.dart';
import 'package:biolabelmap/domain/models/collection_period.dart';
import 'package:biolabelmap/domain/sampling_method.dart';
import 'package:biolabelmap/domain/specimen_list.dart';
import 'package:biolabelmap/domain/species_name.dart';
import 'package:biolabelmap/domain/status.dart';
import 'package:biolabelmap/features/identification/identify_screen.dart';
import 'package:biolabelmap/features/specimen/locality_detail_screen.dart';
import 'package:biolabelmap/features/specimen/specimen_list_screen.dart';
import 'package:biolabelmap/services/service_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

SpecimenListItem item(int n, {SpeciesName species = SpeciesName.unidentified, int day = 20, bool printed = false}) =>
    SpecimenListItem(
      id: n,
      catalogNumber: n,
      catalogText: 'KYC${n.toString().padLeft(5, '0')}',
      localityId: 1,
      period: CollectionPeriod.singleDay(CalendarDate(2026, 6, day)),
      method: SamplingMethod.sweeping,
      methodLabel: 'スウィーピング',
      species: species,
      status: IdentificationStatus.unidentified,
      placeJa: '新潟県魚沼市下折立',
      placeEn: 'Shimooritate',
      printed: printed,
      latE4: 369447,
      lonE4: 1392425,
    );

final _locality = Locality(
  id: 1,
  latitude: 36.94471,
  longitude: 139.24258,
  latE4: 369447,
  lonE4: 1392425,
  isManualPosition: false,
  elevationMeters: 1390,
  elevationStatus: FetchStatus.fetched,
  country: 'JAPAN',
  prefectureJa: '新潟県',
  municipalityJa: '魚沼市',
  localityJa: '下折立',
  placeStatus: FetchStatus.fetched,
  createdAt: DateTime(2026, 6, 20),
);

void main() {
  final carabus = SpeciesName(vernacular: 'オサムシ', genus: 'Carabus', species: 'a');
  final identifyCalls = <List<int>>[];

  /// 同じ点(地点)に、5件の未同定の標本と、別の種の1件。
  final items = [for (var n = 1; n <= 5; n++) item(n), item(6, species: carabus)];

  Future<void> pump(WidgetTester tester, {required bool locality}) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    identifyCalls.clear();
    final router = GoRouter(
      initialLocation: locality ? '/localities/1' : '/specimens',
      routes: [
        GoRoute(path: '/localities/:id', builder: (_, _) => const LocalityDetailScreen(localityId: 1)),
        GoRoute(path: '/specimens', builder: (_, _) => const SpecimenListScreen()),
        GoRoute(path: '/specimens/:id', builder: (_, s) => Text('詳細 ${s.pathParameters['id']}')),
        GoRoute(
          path: '/identify',
          builder: (_, s) {
            identifyCalls.add((s.extra! as IdentifyArgs).specimenIds);
            return const Text('同定入力');
          },
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localityProvider(1).overrideWith((ref) => Stream.value(_locality)),
          specimenItemsProvider.overrideWith((ref) => Stream.value(items)),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.tap(find.byTooltip('選択'));
    await tester.pump();
  }

  for (final locality in [true, false]) {
    final screen = locality ? '地点詳細' : '標本一覧';

    group(screen, () {
      testWidgets('5件の行を展開して、2件だけ選び、その2件に同定を追加できる', (tester) async {
        await pump(tester, locality: locality);
        expect(find.text('標本を選んでください'), findsOneWidget);

        // 5件の行だけに展開ボタンがある(1件の行にはない)
        expect(find.byTooltip('標本を1件ずつ選ぶ'), findsOneWidget);
        await tester.tap(find.byTooltip('標本を1件ずつ選ぶ'));
        await tester.pump();
        for (var n = 1; n <= 5; n++) {
          expect(find.text('KYC0000$n'), findsOneWidget);
        }

        await tester.tap(find.text('KYC00002'));
        await tester.pump();
        await tester.tap(find.text('KYC00004'));
        await tester.pump();
        expect(find.text('2件を選択'), findsOneWidget);
        // 行は「一部を選択」の表示
        expect(find.byIcon(Icons.remove_circle), findsOneWidget);

        await tester.tap(find.text('同定を追加'));
        await tester.pumpAndSettle();
        expect(find.text('同定入力'), findsOneWidget);
        expect(identifyCalls, [
          [2, 4],
        ]);
      });

      testWidgets('行をタップして全部選び、展開して1件だけ外せる', (tester) async {
        await pump(tester, locality: locality);
        await tester.tap(find.textContaining('×5'));
        await tester.pump();
        expect(find.text('5件を選択'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsOneWidget);

        await tester.tap(find.byTooltip('標本を1件ずつ選ぶ'));
        await tester.pump();
        await tester.tap(find.text('KYC00003'));
        await tester.pump();
        expect(find.text('4件を選択'), findsOneWidget);
        expect(find.byIcon(Icons.remove_circle), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsNothing);

        // 外した1件を選び直すと、行は「全部選択」に戻る
        await tester.tap(find.text('KYC00003'));
        await tester.pump();
        expect(find.text('5件を選択'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
      });

      testWidgets('一部だけ選んだ行をタップすると、その行の全部を選ぶ', (tester) async {
        await pump(tester, locality: locality);
        await tester.tap(find.byTooltip('標本を1件ずつ選ぶ'));
        await tester.pump();
        await tester.tap(find.text('KYC00001'));
        await tester.pump();
        expect(find.text('1件を選択'), findsOneWidget);

        await tester.tap(find.textContaining('×5'));
        await tester.pump();
        expect(find.text('5件を選択'), findsOneWidget);
      });

      testWidgets('展開したままでも、全て選択・全て解除ができる(展開していない行も含む)', (tester) async {
        await pump(tester, locality: locality);
        await tester.tap(find.byTooltip('標本を1件ずつ選ぶ'));
        await tester.pump();
        await tester.tap(find.text('全て選択'));
        await tester.pump();
        expect(find.text('6件を選択'), findsOneWidget);
        await tester.tap(find.text('全て解除'));
        await tester.pump();
        expect(find.text('標本を選んでください'), findsOneWidget);
      });

      testWidgets('展開した標本の「詳細を開く」で、その標本の詳細に進める', (tester) async {
        await pump(tester, locality: locality);
        await tester.tap(find.byTooltip('標本を1件ずつ選ぶ'));
        await tester.pump();
        await tester.tap(find.byTooltip('KYC00003の詳細を開く'));
        await tester.pumpAndSettle();
        expect(find.text('詳細 3'), findsOneWidget);
      });

      testWidgets('何も選んでいないときは、操作を押せない。選択を閉じると、通常の表示に戻る', (tester) async {
        await pump(tester, locality: locality);
        final inkWell = find.ancestor(of: find.text('同定を追加'), matching: find.byType(InkWell));
        expect(tester.widget<InkWell>(inkWell).onTap, isNull);

        await tester.tap(find.byTooltip('選択を解除'));
        await tester.pump();
        expect(find.text('同定を追加'), findsNothing);
        expect(find.byTooltip('標本を1件ずつ選ぶ'), findsNothing);
      });
    });
  }

  testWidgets('地点詳細:選択モードでは、画面下は選択の操作になる。通常は「この地点で追加」', (tester) async {
    await pump(tester, locality: true);
    expect(find.text('この地点で追加'), findsNothing);
    expect(find.text('ラベル出力'), findsOneWidget);

    await tester.tap(find.byTooltip('選択を解除'));
    await tester.pump();
    expect(find.text('この地点で追加'), findsOneWidget);
  });

  testWidgets('地点詳細:標本が無い地点には、選択ボタンを出さない', (tester) async {
    final router = GoRouter(
      initialLocation: '/localities/1',
      routes: [GoRoute(path: '/localities/:id', builder: (_, _) => const LocalityDetailScreen(localityId: 1))],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localityProvider(1).overrideWith((ref) => Stream.value(_locality)),
          specimenItemsProvider.overrideWith((ref) => Stream.value(const <SpecimenListItem>[])),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    expect(find.byTooltip('選択'), findsNothing);
  });
}
