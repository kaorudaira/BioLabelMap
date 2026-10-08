import 'package:biolabelmap/core/db/database.dart';
import 'package:biolabelmap/domain/models/calendar_date.dart';
import 'package:biolabelmap/domain/models/collection_period.dart';
import 'package:biolabelmap/domain/models/place_info.dart';
import 'package:biolabelmap/domain/sampling_method.dart';
import 'package:biolabelmap/domain/specimen_list.dart';
import 'package:biolabelmap/domain/species_name.dart';
import 'package:biolabelmap/domain/status.dart';
import 'package:biolabelmap/features/specimen/specimen_detail_screen.dart';
import 'package:biolabelmap/features/specimen/specimen_list_screen.dart';
import 'package:biolabelmap/services/record_service.dart';
import 'package:biolabelmap/services/service_providers.dart';
import 'package:biolabelmap/services/settings_service.dart';
import 'package:biolabelmap/services/specimen_service.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

SpecimenListItem item(int n, {SpeciesName species = SpeciesName.unidentified, bool printed = false}) =>
    SpecimenListItem(
      id: n,
      catalogNumber: n,
      catalogText: 'KYC${n.toString().padLeft(5, '0')}',
      localityId: 1,
      period: CollectionPeriod.singleDay(CalendarDate(2026, 6, 20)),
      method: SamplingMethod.sweeping,
      methodLabel: 'スウィーピング',
      species: species,
      status: species.isEmpty ? IdentificationStatus.unidentified : IdentificationStatus.provisional,
      placeJa: '新潟県魚沼市下折立',
      placeEn: 'Shimooritate',
      printed: printed,
    );

void main() {
  group('標本一覧', () {
    final carabus = SpeciesName(vernacular: 'オサムシ', genus: 'Carabus', species: 'insulicola');

    Future<GoRouter> pumpList(WidgetTester tester, List<SpecimenListItem> items) async {
      final router = GoRouter(
        initialLocation: '/specimens',
        routes: [
          GoRoute(path: '/specimens', builder: (_, _) => const SpecimenListScreen()),
          GoRoute(path: '/specimens/:id', builder: (_, s) => Text('詳細 ${s.pathParameters['id']}')),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [specimenItemsProvider.overrideWith((ref) => Stream.value(items))],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();
      return router;
    }

    testWidgets('同じ種・採集日・場所の標本を1行にまとめ、件数と番号の範囲を出す', (tester) async {
      await pumpList(tester, [
        item(120, species: carabus),
        item(121, species: carabus),
        item(122, species: carabus),
        item(123, printed: true),
      ]);
      expect(find.text('オサムシ Carabus insulicola'), findsOneWidget);
      expect(find.text('×3  KYC00120〜122'), findsOneWidget);
      expect(find.text('未同定'), findsOneWidget);
      expect(find.text('標本 4件(2行)'), findsOneWidget);
      // 未印刷の行にだけマークが付く
      expect(find.byIcon(Icons.print_disabled), findsOneWidget);
    });

    testWidgets('標本が無いときは案内を出す', (tester) async {
      await pumpList(tester, []);
      expect(find.text('標本はまだありません'), findsOneWidget);
    });

    testWidgets('検索で絞り込み、合うものが無ければ案内を出す', (tester) async {
      await pumpList(tester, [item(1, species: carabus), item(2)]);
      await tester.tap(find.byIcon(Icons.search));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'carabus');
      await tester.pump();
      expect(find.text('標本 1件(1行)'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pump();
      expect(find.text('条件に合う標本はありません'), findsOneWidget);
    });

    testWidgets('1件の行をタップすると標本詳細を開く', (tester) async {
      await pumpList(tester, [item(7, species: carabus)]);
      await tester.tap(find.text('オサムシ Carabus insulicola'));
      await tester.pumpAndSettle();
      expect(find.text('詳細 7'), findsOneWidget);
    });

    testWidgets('複数の行をタップすると、開く標本を選べる', (tester) async {
      await pumpList(tester, [item(7, species: carabus), item(8, species: carabus)]);
      await tester.tap(find.text('オサムシ Carabus insulicola'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('KYC00008'));
      await tester.pumpAndSettle();
      expect(find.text('詳細 8'), findsOneWidget);
    });

    testWidgets('絞り込みシートで条件を決めると、条件が画面上部に出る', (tester) async {
      await pumpList(tester, [item(1, printed: true), item(2)]);
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();
      await tester.tap(find.text('未印刷のみ'));
      await tester.pump();
      await tester.tap(find.text('適用'));
      await tester.pumpAndSettle();
      expect(find.text('未印刷のみ'), findsOneWidget);
      expect(find.text('標本 1件(1行)'), findsOneWidget);

      await tester.tap(find.text('解除'));
      await tester.pump();
      // 同じ種・日付・場所の2件は、1行にまとまる
      expect(find.text('標本 2件(1行)'), findsOneWidget);
    });
  });

  group('標本詳細', () {
    late AppDatabase db;

    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    Future<SpecimenDetail> seed(WidgetTester tester) async {
      final detail = await tester.runAsync(() async {
        await SettingsService(db).initializeCatalog(0);
        final r = await RecordService(db).save(
          RecordInput(
            position: const NewPosition(
              latitude: 36.94471,
              longitude: 139.24258,
              accuracyMeters: 8,
              elevationMeters: 1390.4,
              place: PlaceInfo(prefectureJa: '新潟県', municipalityJa: '魚沼市', localityJa: '下折立', localityEn: 'Shimooritate'),
            ),
            period: CollectionPeriod(CalendarDate(2026, 6, 19), CalendarDate(2026, 6, 20)),
            recordedAt: DateTime(2026, 6, 20, 10, 30),
            samplingMethod: SamplingMethod.sweeping,
            habitat: 'ブナ林',
            remarks: '朝霧',
            sex: Sex.female,
          ),
        );
        final id = r.specimenIds.single;
        for (final species in ['old', 'insulicola']) {
          await db.into(db.identifications).insert(
            IdentificationsCompanion.insert(
              specimenId: id,
              status: IdentificationStatus.provisional,
              vernacularName: const Value('オサムシ'),
              genus: const Value('Carabus'),
              species: Value(species),
              identifiedBy: const Value('K. Yoshihara'),
            ),
          );
        }
        return SpecimenService(db).detail(id);
      });
      return detail!;
    }

    testWidgets('同定・標本・採集・地点・同定履歴を、上から読める順に出す', (tester) async {
      final d = await seed(tester);
      // 全ての項目を一度に描画できるよう、縦長の画面にする
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [specimenDetailProvider(d.specimen.id).overrideWith((ref) => Stream.value(d))],
          child: MaterialApp(home: SpecimenDetailScreen(specimenId: d.specimen.id)),
        ),
      );
      await tester.pump();

      expect(find.text('KYC00001'), findsWidgets);
      expect(find.text('同定(最新)'), findsOneWidget);
      expect(find.text('Carabus insulicola'), findsOneWidget);
      expect(find.text('仮同定'), findsOneWidget);
      expect(find.text('♀'), findsOneWidget);
      expect(find.text('朝霧'), findsOneWidget);
      expect(find.text('未印刷'), findsOneWidget);
      expect(find.text('2026/6/19〜20'), findsOneWidget);
      expect(find.text('スウィーピング'), findsOneWidget);
      expect(find.text('新潟県魚沼市下折立'), findsOneWidget);
      expect(find.text('±8 m'), findsOneWidget);
      expect(find.text('1390 m'), findsOneWidget);
      // 履歴は新しい順に、最新と古いものの両方が並ぶ
      expect(find.textContaining('Carabus old'), findsOneWidget);
      expect(find.text('同地点で追加'), findsOneWidget);
    });

    testWidgets('無い標本には案内を出す', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [specimenDetailProvider(99).overrideWith((ref) => Stream.value(null))],
          child: const MaterialApp(home: SpecimenDetailScreen(specimenId: 99)),
        ),
      );
      await tester.pump();
      expect(find.text('標本が見つかりません'), findsOneWidget);
    });
  });
}
