import 'package:biolabelmap/core/db/database.dart';
import 'package:biolabelmap/core/db/database_provider.dart';
import 'package:biolabelmap/domain/models/calendar_date.dart';
import 'package:biolabelmap/domain/models/collection_period.dart';
import 'package:biolabelmap/domain/sampling_method.dart';
import 'package:biolabelmap/domain/specimen_list.dart';
import 'package:biolabelmap/domain/species_name.dart';
import 'package:biolabelmap/domain/status.dart';
import 'package:biolabelmap/features/specimen/bulk_edit_screen.dart';
import 'package:biolabelmap/features/specimen/specimen_detail_screen.dart';
import 'package:biolabelmap/features/specimen/specimen_list_screen.dart';
import 'package:biolabelmap/services/catalog_number_service.dart';
import 'package:biolabelmap/services/record_service.dart';
import 'package:biolabelmap/services/service_providers.dart';
import 'package:biolabelmap/services/settings_service.dart';
import 'package:biolabelmap/services/specimen_service.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// 番号の確定の呼び出しを記録する。
class _RecordingNumbers extends CatalogNumberService {
  _RecordingNumbers(super.db);

  final calls = <List<int>>[];

  @override
  Future<ConfirmResult> confirm(Iterable<int> specimenIds) async {
    calls.add(specimenIds.toList());
    return ConfirmResult(count: specimenIds.length, range: 'KYC00123〜KYC00124');
  }
}

SpecimenListItem item(int n, {SpeciesName species = SpeciesName.unidentified, bool provisional = false}) =>
    SpecimenListItem(
      id: n,
      catalogNumber: provisional ? null : n,
      catalogText: provisional ? null : 'KYC${n.toString().padLeft(5, '0')}',
      localityId: 1,
      period: CollectionPeriod.singleDay(CalendarDate(2026, 6, 20)),
      method: SamplingMethod.sweeping,
      methodLabel: 'スウィーピング',
      species: species,
      status: IdentificationStatus.unidentified,
      placeJa: '新潟県魚沼市下折立',
      placeEn: 'Shimooritate',
      printed: false,
    );

void main() {
  late AppDatabase db;
  late _RecordingNumbers numbers;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    numbers = _RecordingNumbers(db);
  });
  tearDown(() => db.close());

  final carabus = SpeciesName(vernacular: 'オサムシ', genus: 'Carabus', species: 'a');

  Future<void> pumpList(WidgetTester tester, List<SpecimenListItem> items) async {
    final router = GoRouter(
      initialLocation: '/specimens',
      routes: [GoRoute(path: '/specimens', builder: (_, _) => const SpecimenListScreen())],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          specimenItemsProvider.overrideWith((ref) => Stream.value(items)),
          catalogNumberServiceProvider.overrideWithValue(numbers),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
  }

  /// 3標本を、番号が未確定(仮)のまま保存する。
  Future<List<int>> seedProvisional(WidgetTester tester) async => (await tester.runAsync(() async {
    await SettingsService(db).initializeCatalog(122);
    final r = await RecordService(db).save(
      RecordInput(
        position: const NewPosition(latitude: 36.9, longitude: 139.2),
        period: CollectionPeriod.singleDay(CalendarDate(2026, 6, 20)),
        recordedAt: DateTime(2026, 6, 20),
        samplingMethod: SamplingMethod.sweeping,
        count: 3,
      ),
    );
    return r.specimenIds;
  }))!;

  group('標本一覧', () {
    testWidgets('番号が未確定の標本の行は、「番号未確定」と出す', (tester) async {
      await pumpList(tester, [item(1, species: carabus, provisional: true), item(2, species: carabus, provisional: true)]);
      expect(find.textContaining('×2  番号未確定'), findsOneWidget);
    });

    testWidgets('選んだ標本の番号を確定する。確認してから、確定した番号の範囲を知らせる', (tester) async {
      await pumpList(tester, [
        item(1, species: carabus, provisional: true),
        item(2, species: carabus, provisional: true),
        item(3),
      ]);
      await tester.tap(find.byTooltip('選択'));
      await tester.pump();
      await tester.tap(find.textContaining('オサムシ'));
      await tester.pump();
      await tester.tap(find.text('番号確定'));
      await tester.pumpAndSettle();
      expect(find.text('2件の番号を確定しますか'), findsOneWidget);
      expect(find.textContaining('確定した番号は戻せません'), findsOneWidget);
      expect(numbers.calls, isEmpty);

      await tester.tap(find.text('番号を確定'));
      await tester.pumpAndSettle();
      expect(numbers.calls, [
        [1, 2],
      ]);
      expect(find.text('2件の番号を確定しました(KYC00123〜KYC00124)'), findsOneWidget);
    });

    testWidgets('選んだ標本が全部確定済みなら、確認せずに案内だけ出す', (tester) async {
      await pumpList(tester, [item(1, species: carabus)]);
      await tester.tap(find.byTooltip('選択'));
      await tester.pump();
      await tester.tap(find.textContaining('オサムシ'));
      await tester.pump();
      await tester.tap(find.text('番号確定'));
      await tester.pumpAndSettle();
      expect(find.text('選んだ標本に、番号が未確定のものはありません'), findsOneWidget);
      expect(numbers.calls, isEmpty);
    });
  });

  group('標本詳細', () {
    testWidgets('番号が未確定の標本に「番号を確定」を出し、この標本だけか、採集の全部かを選べる', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final ids = await seedProvisional(tester);
      final detail = (await tester.runAsync(() => SpecimenService(db).detail(ids[1])))!;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            specimenDetailProvider(ids[1]).overrideWith((ref) => Stream.value(detail)),
            catalogNumberServiceProvider.overrideWithValue(numbers),
          ],
          child: MaterialApp(home: SpecimenDetailScreen(specimenId: ids[1])),
        ),
      );
      await tester.pump();
      expect(find.text('番号未確定'), findsWidgets);

      await tester.tap(find.text('番号を確定'));
      await tester.pumpAndSettle();
      expect(find.text('この標本だけ'), findsOneWidget);
      expect(find.text('この採集の未確定の標本すべて(3件)'), findsOneWidget);

      await tester.tap(find.text('この採集の未確定の標本すべて(3件)'));
      await tester.pumpAndSettle();
      expect(numbers.calls, [ids]);

      await tester.tap(find.text('番号を確定'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('この標本だけ'));
      await tester.pumpAndSettle();
      expect(numbers.calls.last, [ids[1]]);
    });

    testWidgets('確定済みの標本には、「番号を確定」を出さない', (tester) async {
      final ids = await seedProvisional(tester);
      await tester.runAsync(() => CatalogNumberService(db).confirm([ids[0]]));
      final detail = (await tester.runAsync(() => SpecimenService(db).detail(ids[0])))!;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [specimenDetailProvider(ids[0]).overrideWith((ref) => Stream.value(detail))],
          child: MaterialApp(home: SpecimenDetailScreen(specimenId: ids[0])),
        ),
      );
      await tester.pump();
      expect(find.text('番号を確定'), findsNothing);
    });
  });

  group('編集', () {
    Future<void> pumpEdit(WidgetTester tester, SpecimenDetail d) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: FilledButton(
                  onPressed: () => Navigator.push<bool>(
                    context,
                    MaterialPageRoute(builder: (_) => BulkEditScreen(args: BulkEditArgs([d.specimen.id], initial: d))),
                  ),
                  child: const Text('開く'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('開く'));
      await tester.pumpAndSettle();
    }

    Future<void> settle(WidgetTester tester) async {
      await tester.pumpAndSettle();
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();
    }

    testWidgets('番号が未確定の標本は、個体数を減らせる。他の項目は変えなくても保存できる', (tester) async {
      final ids = await seedProvisional(tester);
      final detail = (await tester.runAsync(() => SpecimenService(db).detail(ids.first)))!;
      await pumpEdit(tester, detail);
      expect(find.text('個体数(番号が未確定の標本)'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.remove));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.remove));
      await tester.pump();
      expect(find.text('1'), findsOneWidget);
      expect(tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.remove)).onPressed, isNull);
      await tester.tap(find.text('保存'));
      await settle(tester);

      final left = (await tester.runAsync(() => db.select(db.specimens).get()))!;
      expect(left.map((s) => s.id), [ids.first]);
    });

    testWidgets('個体数を増やせる', (tester) async {
      final ids = await seedProvisional(tester);
      final detail = (await tester.runAsync(() => SpecimenService(db).detail(ids.first)))!;
      await pumpEdit(tester, detail);
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      expect(find.text('4'), findsOneWidget);
      await tester.tap(find.text('保存'));
      await settle(tester);
      expect((await tester.runAsync(() => db.select(db.specimens).get()))!, hasLength(4));
    });

    testWidgets('番号が確定した標本には、個体数の欄を出さない', (tester) async {
      final ids = await seedProvisional(tester);
      await tester.runAsync(() => CatalogNumberService(db).confirm([ids.first]));
      final detail = (await tester.runAsync(() => SpecimenService(db).detail(ids.first)))!;
      await pumpEdit(tester, detail);
      expect(find.text('個体数(番号が未確定の標本)'), findsNothing);
    });
  });
}
