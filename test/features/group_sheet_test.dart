import 'package:biolabelmap/core/db/database.dart';
import 'package:biolabelmap/domain/models/calendar_date.dart';
import 'package:biolabelmap/domain/models/collection_period.dart';
import 'package:biolabelmap/domain/sampling_method.dart';
import 'package:biolabelmap/domain/specimen_list.dart';
import 'package:biolabelmap/domain/species_name.dart';
import 'package:biolabelmap/domain/status.dart';
import 'package:biolabelmap/features/specimen/bulk_edit_screen.dart';
import 'package:biolabelmap/features/specimen/locality_detail_screen.dart';
import 'package:biolabelmap/services/record_service.dart';
import 'package:biolabelmap/services/service_providers.dart';
import 'package:biolabelmap/services/settings_service.dart';
import 'package:biolabelmap/services/specimen_service.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// 標本の詳細は、あらかじめ作ったものを返す。
class _FakeSpecimens extends SpecimenService {
  _FakeSpecimens(super.db, this.details);

  final Map<int, SpecimenDetail> details;

  @override
  Future<SpecimenDetail?> detail(int specimenId) async => details[specimenId];
}

SpecimenListItem item(int n, {SpeciesName species = SpeciesName.unidentified}) => SpecimenListItem(
  id: n,
  catalogNumber: n,
  catalogText: 'KYC${n.toString().padLeft(5, '0')}',
  localityId: 1,
  period: CollectionPeriod.singleDay(CalendarDate(2026, 6, 20)),
  method: SamplingMethod.sweeping,
  methodLabel: 'スウィーピング',
  species: species,
  status: IdentificationStatus.unidentified,
  placeJa: '新潟県魚沼市下折立',
  placeEn: 'Shimooritate',
  printed: n.isEven,
  latE4: 369447,
  lonE4: 1392425,
);

void main() {
  late AppDatabase db;
  final editCalls = <String>[];

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  final locality = Locality(
    id: 1,
    latitude: 36.94471,
    longitude: 139.24258,
    latE4: 369447,
    lonE4: 1392425,
    isManualPosition: false,
    elevationMeters: 1390,
    elevationStatus: FetchStatus.fetched,
    country: 'JAPAN',
    placeStatus: FetchStatus.fetched,
    createdAt: DateTime(2026, 6, 20),
  );

  /// 地点詳細に、未同定の3件の行を出し、行をタップしてシートを開く。
  Future<void> openSheet(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    editCalls.clear();

    // 編集画面に渡す、標本の詳細(実際のDBから作る)
    final details = (await tester.runAsync(() async {
      await SettingsService(db).initializeCatalog(0);
      final r = await RecordService(db).save(
        RecordInput(
          position: const NewPosition(latitude: 36.94471, longitude: 139.24258),
          period: CollectionPeriod.singleDay(CalendarDate(2026, 6, 20)),
          recordedAt: DateTime(2026, 6, 20),
          samplingMethod: SamplingMethod.sweeping,
          count: 3,
          confirmNow: true,
        ),
      );
      final service = SpecimenService(db);
      return {for (final id in r.specimenIds) id: (await service.detail(id))!};
    }))!;

    final router = GoRouter(
      initialLocation: '/localities/1',
      routes: [
        GoRoute(path: '/localities/:id', builder: (_, _) => const LocalityDetailScreen(localityId: 1)),
        GoRoute(path: '/specimens/:id', builder: (_, s) => Text('詳細 ${s.pathParameters['id']}')),
        GoRoute(
          path: '/bulk-edit',
          builder: (_, s) {
            final args = s.extra! as BulkEditArgs;
            editCalls.add('${args.specimenIds}:${args.initial != null}');
            return const Text('編集画面');
          },
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localityProvider(1).overrideWith((ref) => Stream.value(locality)),
          specimenItemsProvider.overrideWith((ref) => Stream.value([item(1), item(2), item(3)])),
          specimenServiceProvider.overrideWithValue(_FakeSpecimens(db, details)),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.tap(find.textContaining('×3'));
    await tester.pumpAndSettle();
  }

  testWidgets('シートの各行の右端に「この標本を編集」ボタン、見出しの右に「全てまとめて編集」「選んで編集」を置く', (tester) async {
    await openSheet(tester);
    for (final n in [1, 2, 3]) {
      expect(find.byTooltip('KYC0000$nを編集'), findsOneWidget);
    }
    expect(find.text('全てまとめて編集'), findsOneWidget);
    expect(find.text('選んで編集'), findsOneWidget);
    // 見出しは「未同定 ×3」
    expect(find.textContaining('未同定 ×3'), findsOneWidget);
    // 編集ボタンは各行の右端、見出しのボタンは見出しの行にある(標本の行より上)
    expect(tester.getTopLeft(find.text('全てまとめて編集')).dy, lessThan(tester.getTopLeft(find.text('KYC00001')).dy));
    expect(tester.getTopRight(find.byTooltip('KYC00001を編集')).dx, greaterThan(tester.getTopRight(find.text('KYC00001')).dx));
  });

  testWidgets('行の「編集」で、その標本の編集画面を、いまの内容つきで開く', (tester) async {
    await openSheet(tester);
    await tester.tap(find.byTooltip('KYC00002を編集'));
    await tester.pumpAndSettle();
    expect(find.text('編集画面'), findsOneWidget);
    expect(editCalls, ['[2]:true']);
  });

  testWidgets('「全てまとめて編集」で、行の全部の標本の一括編集を開く', (tester) async {
    await openSheet(tester);
    await tester.tap(find.text('全てまとめて編集'));
    await tester.pumpAndSettle();
    expect(editCalls, ['[1, 2, 3]:false']);
  });

  testWidgets('「選んで編集」で標本を選び、選んだ標本の一括編集を開く。選ぶまでは押せない', (tester) async {
    await openSheet(tester);
    await tester.tap(find.text('選んで編集'));
    await tester.pump();
    // 選択中:各行にチェック、行の編集ボタンは隠れる
    expect(find.text('編集する標本を選んでください'), findsOneWidget);
    expect(find.byType(Checkbox), findsNWidgets(3));
    expect(find.byTooltip('KYC00001を編集'), findsNothing);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, '編集(0件)')).onPressed, isNull);

    await tester.tap(find.text('KYC00001'));
    await tester.pump();
    await tester.tap(find.byType(Checkbox).last);
    await tester.pump();
    expect(find.text('編集(2件)'), findsOneWidget);
    await tester.tap(find.text('編集(2件)'));
    await tester.pumpAndSettle();
    expect(editCalls, ['[1, 3]:false']);
  });

  testWidgets('「選んで編集」を「やめる」と、選びを消して、元の表示に戻る', (tester) async {
    await openSheet(tester);
    await tester.tap(find.text('選んで編集'));
    await tester.pump();
    await tester.tap(find.text('KYC00001'));
    await tester.pump();
    await tester.tap(find.text('やめる'));
    await tester.pump();
    expect(find.byType(Checkbox), findsNothing);
    expect(find.byTooltip('KYC00001を編集'), findsOneWidget);

    await tester.tap(find.text('選んで編集'));
    await tester.pump();
    expect(find.text('編集(0件)'), findsOneWidget); // 選びは消えている
  });

  testWidgets('行の本体をタップすると、これまでどおり標本の詳細を開く', (tester) async {
    await openSheet(tester);
    await tester.tap(find.text('KYC00003'));
    await tester.pumpAndSettle();
    expect(find.text('詳細 3'), findsOneWidget);
  });
}
