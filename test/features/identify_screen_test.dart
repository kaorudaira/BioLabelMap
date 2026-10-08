import 'package:biolabelmap/core/db/database.dart';
import 'package:biolabelmap/core/db/database_provider.dart';
import 'package:biolabelmap/domain/models/calendar_date.dart';
import 'package:biolabelmap/domain/models/collection_period.dart';
import 'package:biolabelmap/domain/sampling_method.dart';
import 'package:biolabelmap/domain/species_catalog.dart';
import 'package:biolabelmap/domain/species_name.dart';
import 'package:biolabelmap/domain/status.dart';
import 'package:biolabelmap/features/identification/identify_screen.dart';
import 'package:biolabelmap/services/dictionary_service.dart';
import 'package:biolabelmap/services/record_service.dart';
import 'package:biolabelmap/services/service_providers.dart';
import 'package:biolabelmap/services/settings_service.dart';
import 'package:biolabelmap/services/specimen_service.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late List<int> ids;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  /// DB を使う処理は、テストの仮の時計の外で動かす。
  Future<T> real<T>(WidgetTester tester, Future<T> Function() f) async => (await tester.runAsync(f)) as T;

  /// 候補の検索など、DB に問い合わせる非同期処理が終わるのを待つ。
  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 80)));
    await tester.pump();
  }

  Future<void> pumpScreen(WidgetTester tester, {int count = 1, SpeciesName? initial, String? lastIdentifier, SpeciesCatalog? catalog}) async {
    final row = await real(tester, () async {
      await SettingsService(db).initializeCatalog(0);
      final r = await RecordService(db).save(
        RecordInput(
          position: const NewPosition(latitude: 36.94471, longitude: 139.24258),
          period: CollectionPeriod.singleDay(CalendarDate(2026, 6, 20)),
          recordedAt: DateTime(2026, 6, 20),
          samplingMethod: SamplingMethod.sweeping,
          count: count,
        ),
      );
      ids = r.specimenIds;
      await DictionaryService(db).rememberSpecies(
        SpeciesName(vernacular: 'オサムシ', genus: 'Carabus', species: 'insulicola', authorship: 'Chaudoir, 1869'),
      );
      if (lastIdentifier != null) {
        await db.update(db.appSettings).write(AppSettingsCompanion(lastIdentifier: Value(lastIdentifier)));
      }
      return SettingsService(db).read();
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          settingsProvider.overrideWith((ref) => Stream.value(row)),
          speciesCatalogProvider.overrideWith((ref) async => catalog ?? SpeciesCatalog.empty),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () async {
                    final saved = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(builder: (_) => IdentifyScreen(args: IdentifyArgs(ids, initial: initial))),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('結果: $saved')));
                    }
                  },
                  child: const Text('開く'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('開く'));
    await tester.pumpAndSettle();
    await settle(tester);
  }

  Finder field(String label) => find.widgetWithText(TextField, label);

  testWidgets('属を打つと辞書の候補が出て、選ぶと和名・学名・命名者がまとめて入る', (tester) async {
    await pumpScreen(tester);
    await tester.enterText(field('属'), 'cara');
    await settle(tester);
    expect(find.text('オサムシ Carabus insulicola'), findsOneWidget);

    await tester.tap(find.text('オサムシ Carabus insulicola'));
    await tester.pump();
    expect(tester.widget<TextField>(field('和名(任意)')).controller!.text, 'オサムシ');
    expect(tester.widget<TextField>(field('属')).controller!.text, 'Carabus');
    expect(tester.widget<TextField>(field('種')).controller!.text, 'insulicola');
    expect(tester.widget<TextField>(field('命名者・年')).controller!.text, 'Chaudoir, 1869');
    await settle(tester);
    // 候補を入れたあとは、候補の一覧を閉じる
    expect(find.text('候補(選ぶとまとめて入ります)'), findsNothing);
  });

  testWidgets('種名を入れて保存すると仮同定で履歴に加わり、同定者を覚える', (tester) async {
    await pumpScreen(tester);
    await tester.enterText(field('属'), 'Carabus');
    await tester.enterText(field('種'), 'arrowianus');
    await tester.enterText(field('同定者'), 'K. Yoshihara');
    await settle(tester);
    await tester.tap(find.text('同定を追加'));
    await tester.pumpAndSettle();
    await settle(tester);

    expect(find.text('結果: true'), findsOneWidget);
    final d = (await real(tester, () => SpecimenService(db).detail(ids.single)))!;
    expect(d.latest!.genus, 'Carabus');
    expect(d.latest!.status, IdentificationStatus.provisional);
    expect(d.latest!.identifiedBy, 'K. Yoshihara');
    expect(d.latest!.dateIdentified, CalendarDate.fromDateTime(DateTime.now()));
    expect((await real(tester, () => SettingsService(db).read())).lastIdentifier, 'K. Yoshihara');
  });

  testWidgets('「同定済み」に切り替えて保存すると、同定済みになる', (tester) async {
    await pumpScreen(tester);
    await tester.enterText(field('種'), 'x');
    await tester.pump();
    await tester.ensureVisible(find.text('同定済み'));
    await tester.pump();
    await tester.tap(find.text('同定済み'));
    await tester.pump();
    await tester.tap(find.text('同定を追加'));
    await tester.pumpAndSettle();
    await settle(tester);

    final d = (await real(tester, () => SpecimenService(db).detail(ids.single)))!;
    expect(d.latest!.status, IdentificationStatus.verified);
  });

  testWidgets('種名が空なら状態は未同定になり、切り替えは出ない', (tester) async {
    await pumpScreen(tester);
    expect(find.textContaining('種名が空のときは未同定'), findsOneWidget);
    expect(find.text('仮同定'), findsNothing);
    await tester.enterText(field('和名(任意)'), 'オサムシ');
    await tester.pump();
    expect(find.text('仮同定'), findsOneWidget);
    expect(find.textContaining('種名が空のときは未同定'), findsNothing);
  });

  testWidgets('同定者は、最後に入力した名前が既定で入る', (tester) async {
    await pumpScreen(tester, lastIdentifier: 'K. Yoshihara');
    expect(tester.widget<TextField>(field('同定者')).controller!.text, 'K. Yoshihara');
  });

  testWidgets('複数の標本を選んだときは、全てに同じ同定を追加する', (tester) async {
    await pumpScreen(tester, count: 3);
    expect(find.text('同定入力(3件)'), findsOneWidget);
    await tester.enterText(field('種'), 'x');
    await tester.pump();
    await tester.tap(find.text('3件に同定を追加'));
    await tester.pumpAndSettle();
    await settle(tester);

    for (final id in ids) {
      final d = (await real(tester, () => SpecimenService(db).detail(id)))!;
      expect(d.history.single.species, 'x');
    }
  });

  testWidgets('直前の同定を初期値にして、手直しできる', (tester) async {
    await pumpScreen(tester, initial: SpeciesName(genus: 'Carabus', species: 'old', authorship: '(L., 1758)'));
    expect(tester.widget<TextField>(field('種')).controller!.text, 'old');
    expect(tester.widget<TextField>(field('命名者・年')).controller!.text, '(L., 1758)');
  });

  testWidgets('ō のボタンは、触っていた欄に文字を入れる', (tester) async {
    await pumpScreen(tester);
    await tester.tap(field('命名者・年'));
    await tester.pump();
    await tester.tap(find.text('ō'));
    await tester.pump();
    expect(tester.widget<TextField>(field('命名者・年')).controller!.text, 'ō');
  });

  group('甲虫の目録', () {
    final catalog = SpeciesCatalog.parseCsv(
      '"クボタヒメハネカクシ","Atheta (Atheta) transfuga (Sharp, 1874)"\n'
      '"カラカネナカボソタマムシ　基亜種","Coraebus ignotus ignotus E. Saunders, 1873"\n'
      '"カラカネナカボソタマムシ　奄美亜種","Coraebus ignotus shibatai Y. Kurosawa, 1963"',
    );

    String text(WidgetTester tester, String label) => tester.widget<TextField>(field(label)).controller!.text;

    testWidgets('和名が目録の1つの種に一致したら、学名と命名者・年が自動で入る', (tester) async {
      await pumpScreen(tester, catalog: catalog);
      await tester.enterText(field('和名(任意)'), 'クボタヒメハネカクシ');
      await tester.pump();
      expect(text(tester, '属'), 'Atheta');
      expect(text(tester, '種'), 'transfuga');
      expect(text(tester, '命名者・年'), '(Sharp, 1874)');
      expect(find.textContaining('目録から入力しました'), findsOneWidget);
    });

    testWidgets('属と種を入力したら、和名と命名者・年が自動で入る。入力済みの欄は書き換えない', (tester) async {
      await pumpScreen(tester, catalog: catalog);
      await tester.enterText(field('命名者・年'), '自分の入力');
      await tester.enterText(field('属'), 'atheta');
      await tester.enterText(field('種'), 'transfuga');
      await tester.pump();
      expect(text(tester, '和名(任意)'), 'クボタヒメハネカクシ');
      expect(text(tester, '命名者・年'), '自分の入力');
      expect(text(tester, '属'), 'atheta');
    });

    testWidgets('自動入力のあとに消した欄は、同じ種に一致している間は入れ直さない', (tester) async {
      await pumpScreen(tester, catalog: catalog);
      await tester.enterText(field('属'), 'Atheta');
      await tester.enterText(field('種'), 'transfuga');
      await tester.pump();
      expect(text(tester, '命名者・年'), '(Sharp, 1874)');

      await tester.enterText(field('命名者・年'), '');
      await tester.enterText(field('和名(任意)'), 'クボタヒメハネカクシ');
      await tester.pump();
      expect(text(tester, '命名者・年'), '');
    });

    testWidgets('亜種が複数ある種は、1つに決まらないので自動入力しない', (tester) async {
      await pumpScreen(tester, catalog: catalog);
      await tester.enterText(field('属'), 'Coraebus');
      await tester.enterText(field('種'), 'ignotus');
      await tester.pump();
      expect(text(tester, '和名(任意)'), '');
      expect(find.textContaining('目録から入力しました'), findsNothing);
    });

    testWidgets('打っている途中の文字には、目録の候補を出し、選ぶとまとめて入る', (tester) async {
      await pumpScreen(tester, catalog: catalog);
      await tester.enterText(field('和名(任意)'), 'カラカネ');
      await settle(tester);
      expect(find.text('目録'), findsNWidgets(2));

      await tester.tap(find.textContaining('奄美亜種'));
      await tester.pump();
      expect(text(tester, '亜種'), 'shibatai');
      expect(text(tester, '命名者・年'), 'Y. Kurosawa, 1963');
    });

    testWidgets('自分が使った種(辞書)を先に出し、同じ種は目録と重ねて出さない', (tester) async {
      await pumpScreen(
        tester,
        catalog: SpeciesCatalog.parseCsv(
          '"オサムシ","Carabus insulicola Chaudoir, 1869"\n'
          '"オサムシモドキ","Carabus insulicolax Chaudoir, 1869"',
        ),
      );
      await tester.enterText(field('属'), 'carabus');
      await settle(tester);
      final titles = tester.widgetList<ListTile>(find.byType(ListTile)).map((t) => (t.title! as Text).data).toList();
      expect(titles, ['オサムシ Carabus insulicola', 'オサムシモドキ Carabus insulicolax']);
      expect(find.text('目録'), findsOneWidget);
    });
  });
}
