import 'package:biolabelmap/core/db/database.dart';
import 'package:biolabelmap/core/db/database_provider.dart';
import 'package:biolabelmap/domain/models/calendar_date.dart';
import 'package:biolabelmap/domain/models/collection_period.dart';
import 'package:biolabelmap/domain/sampling_method.dart';
import 'package:biolabelmap/domain/species_catalog.dart';
import 'package:biolabelmap/domain/species_name.dart';
import 'package:biolabelmap/domain/status.dart';
import 'package:biolabelmap/features/identification/identify_screen.dart';
import 'package:biolabelmap/features/specimen/species_name_text.dart';
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
    // 画面の下の方の項目も描画されるよう、縦長の画面にする
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
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
    await tester.enterText(field('属名'), 'cara');
    await settle(tester);
    expect(find.text('オサムシ Carabus insulicola'), findsOneWidget);

    await tester.tap(find.text('オサムシ Carabus insulicola'));
    await tester.pump();
    expect(tester.widget<TextField>(field('和名(任意)')).controller!.text, 'オサムシ');
    expect(tester.widget<TextField>(field('属名')).controller!.text, 'Carabus');
    expect(tester.widget<TextField>(field('種小名')).controller!.text, 'insulicola');
    expect(tester.widget<TextField>(field('命名者・年')).controller!.text, 'Chaudoir, 1869');
    await settle(tester);
    // 候補を入れたあとは、候補の一覧を閉じる
    expect(find.textContaining('候補 '), findsNothing);
  });

  testWidgets('種名を入れて保存すると仮同定で履歴に加わり、同定者を覚える', (tester) async {
    await pumpScreen(tester);
    await tester.enterText(field('属名'), 'Carabus');
    await tester.enterText(field('種小名'), 'arrowianus');
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
    await tester.enterText(field('種小名'), 'x');
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
    await tester.enterText(field('種小名'), 'x');
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
    expect(tester.widget<TextField>(field('種小名')).controller!.text, 'old');
    expect(tester.widget<TextField>(field('命名者・年')).controller!.text, '(L., 1758)');
  });

  testWidgets('ō のボタンは、触っていた欄に文字を入れる', (tester) async {
    await pumpScreen(tester);
    await tester.tap(field('命名者・年'));
    await tester.pump();
    await tester.tap(find.text('ō').first);
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
      expect(text(tester, '属名'), 'Atheta');
      expect(text(tester, '種小名'), 'transfuga');
      expect(text(tester, '命名者・年'), '(Sharp, 1874)');
      expect(find.textContaining('目録から入力しました'), findsOneWidget);
    });

    testWidgets('属と種を入力したら、和名と命名者・年が自動で入る。入力済みの欄は書き換えない', (tester) async {
      await pumpScreen(tester, catalog: catalog);
      await tester.enterText(field('命名者・年'), '自分の入力');
      await tester.enterText(field('属名'), 'atheta');
      await tester.enterText(field('種小名'), 'transfuga');
      await tester.pump();
      expect(text(tester, '和名(任意)'), 'クボタヒメハネカクシ');
      expect(text(tester, '命名者・年'), '自分の入力');
      expect(text(tester, '属名'), 'atheta');
    });

    testWidgets('自動入力のあとに消した欄は、同じ種に一致している間は入れ直さない', (tester) async {
      await pumpScreen(tester, catalog: catalog);
      await tester.enterText(field('属名'), 'Atheta');
      await tester.enterText(field('種小名'), 'transfuga');
      await tester.pump();
      expect(text(tester, '命名者・年'), '(Sharp, 1874)');

      await tester.enterText(field('命名者・年'), '');
      await tester.enterText(field('和名(任意)'), 'クボタヒメハネカクシ');
      await tester.pump();
      expect(text(tester, '命名者・年'), '');
    });

    testWidgets('亜種が複数ある種は、1つに決まらないので自動入力しない', (tester) async {
      await pumpScreen(tester, catalog: catalog);
      await tester.enterText(field('属名'), 'Coraebus');
      await tester.enterText(field('種小名'), 'ignotus');
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
      expect(text(tester, '亜種名'), 'shibatai');
      expect(text(tester, '命名者・年'), 'Y. Kurosawa, 1963');
    });

    testWidgets('属を入れてから種を打つと、両方に合う候補だけに絞り込む', (tester) async {
      await pumpScreen(
        tester,
        catalog: SpeciesCatalog.parseCsv(
          '"A","Coraebus ignotus ignotus E. Saunders, 1873"\n'
          '"B","Coraebus ignotus shibatai Y. Kurosawa, 1963"\n'
          '"C","Coraebus other Bates, 1888"\n'
          '"D","Another ignotus Bates, 1888"',
        ),
      );
      await tester.enterText(field('属名'), 'Coraebus');
      await settle(tester);
      expect(find.text('目録'), findsNWidgets(3));

      await tester.enterText(field('種小名'), 'ignotus');
      await settle(tester);
      expect(find.text('目録'), findsNWidgets(2));
      expect(find.textContaining('Another'), findsNothing);
    });

    testWidgets('自動入力した欄を、少しずつ消していって全部消し切っても、入れ直さない', (tester) async {
      await pumpScreen(tester, catalog: catalog);
      await tester.enterText(field('和名(任意)'), 'クボタヒメハネカクシ');
      await tester.pump();
      expect(text(tester, '属名'), 'Atheta');

      // 和名を1文字ずつ消す。途中も、消し切ったときも、勝手に入り直さない
      var v = 'クボタヒメハネカクシ';
      while (v.isNotEmpty) {
        v = v.substring(0, v.length - 1);
        await tester.enterText(field('和名(任意)'), v);
        await tester.pump();
      }
      expect(text(tester, '和名(任意)'), '');

      // 命名者・年も、全部消せる
      await tester.enterText(field('命名者・年'), '');
      await tester.pump();
      expect(text(tester, '命名者・年'), '');
    });

    testWidgets('クリアで種名の入力をすべて消し、そのあと同じ種を打てば、また自動入力される', (tester) async {
      await pumpScreen(tester, catalog: catalog);
      await tester.enterText(field('和名(任意)'), 'クボタヒメハネカクシ');
      await tester.pump();
      expect(find.textContaining('目録から入力しました'), findsOneWidget);

      await tester.tap(find.text('クリア'));
      await tester.pump();
      for (final label in ['和名(任意)', '属名', '種小名', '亜種名', '命名者・年']) {
        expect(text(tester, label), '', reason: label);
      }
      expect(find.textContaining('目録から入力しました'), findsNothing);
      expect(find.text('仮同定'), findsNothing);

      await tester.enterText(field('和名(任意)'), 'クボタヒメハネカクシ');
      await tester.pump();
      expect(text(tester, '属名'), 'Atheta');
    });

    testWidgets('何も入力していないとき、クリアは押せない。同定者と同定日は消さない', (tester) async {
      await pumpScreen(tester, catalog: catalog, lastIdentifier: 'K. Yoshihara');
      expect(tester.widget<TextButton>(find.widgetWithText(TextButton, 'クリア')).onPressed, isNull);
      await tester.enterText(field('種小名'), 'x');
      await tester.pump();
      await tester.tap(find.text('クリア'));
      await tester.pump();
      expect(text(tester, '同定者'), 'K. Yoshihara');
    });

    testWidgets('候補は全件を出し、5件ぶんの高さでスクロールする', (tester) async {
      final many = SpeciesCatalog.parseCsv(
        [for (var i = 0; i < 12; i++) '"種${String.fromCharCode(0x30A2 + i * 2)}","Carabus species${String.fromCharCode(97 + i)} Bates, 1888"'].join('\n'),
      );
      await pumpScreen(tester, catalog: many);
      await tester.enterText(field('属名'), 'carabus');
      await settle(tester);

      expect(find.text('候補 13件(選ぶとまとめて入ります)'), findsOneWidget);
      expect(find.text('目録'), findsNWidgets(4)); // 辞書の1件+目録の4件
      expect(find.text('目録'), findsNWidgets(4)); // 辞書の1件+目録の4件
      expect(find.textContaining('speciesl'), findsNothing);
      await tester.drag(find.byType(ListView).last, const Offset(0, -1000));
      await tester.pump();
      expect(find.textContaining('speciesl'), findsOneWidget);
    });

    testWidgets('候補は最大20件で、和名の50音順に並べる。多いときは、絞り込めると案内する', (tester) async {
      final many = SpeciesCatalog.parseCsv(
        [
          // 並びが入力順に依らないよう、和名を逆順に入れる
          for (var i = 29; i >= 0; i--)
            '"${String.fromCharCode(0x30A2 + i)}","Carabus species${String.fromCharCode(97 + i % 26)}${String.fromCharCode(97 + i ~/ 26)} Bates, 1888"',
        ].join('\n'),
      );
      await pumpScreen(tester, catalog: many);
      await tester.enterText(field('属名'), 'carabus');
      await settle(tester);

      expect(find.text('候補 31件のうち、和名の50音順で 20件(さらに入力すると絞り込めます)'), findsOneWidget);
      // 先頭は ア。辞書の「オサムシ」も、和名の順(オの位置)に入る
      final titles = tester.widgetList<ListTile>(find.byType(ListTile)).map((t) => (t.title! as SpeciesNameText).name.label).toList();
      expect(titles.first, startsWith('ア '));
      expect(titles.map((t) => t.split(' ').first).toList(), [...titles.map((t) => t.split(' ').first)]..sort());
    });

    testWidgets('属名の欄に打った文字は属名だけを、種小名の欄に打った文字は種小名だけを探す', (tester) async {
      final fields = SpeciesCatalog.parseCsv(
        '"ア","Carabus ignotus Bates, 1883"\n'
        '"イ","Another carabus Bates, 1883"\n'
        '"カラバス","Third species Bates, 1883"',
      );
      await pumpScreen(tester, catalog: fields);

      // 属名の欄:属名に carabus を含む種だけ(種小名や和名に含まれるものは出ない)
      await tester.enterText(field('属名'), 'carabus');
      await settle(tester);
      expect(find.textContaining('Carabus ignotus'), findsOneWidget);
      expect(find.textContaining('Another carabus'), findsNothing);
      expect(find.text('カラバス Third species'), findsNothing);

      // 属名を消して、種小名の欄に同じ文字:種小名に carabus を含む種だけ
      await tester.tap(find.text('クリア'));
      await tester.pump();
      await tester.enterText(field('種小名'), 'carabus');
      await settle(tester);
      expect(find.textContaining('Another carabus'), findsOneWidget);
      expect(find.textContaining('Carabus ignotus'), findsNothing);
    });

    testWidgets('亜種名の欄に打った文字は、亜種名だけを探す', (tester) async {
      final subs = SpeciesCatalog.parseCsv(
        '"ア　基亜種","Coraebus ignotus ignotus Saunders, 1873"\n'
        '"ア　奄美亜種","Coraebus ignotus shibatai Kurosawa, 1963"\n'
        '"イ","Another shibatai Bates, 1883"',
      );
      await pumpScreen(tester, catalog: subs);
      await tester.enterText(field('亜種名'), 'shiba');
      await settle(tester);
      expect(find.textContaining('Coraebus ignotus shibatai'), findsOneWidget);
      expect(find.textContaining('Coraebus ignotus ignotus'), findsNothing);
      // 亜種名を持たない種(2番目の語が種小名)は、亜種名の検索では出ない
      expect(find.textContaining('Another shibatai'), findsNothing);
    });

    testWidgets('候補の名前が長くても、折り返して全体を表示する(省略しない)', (tester) async {
      tester.view.physicalSize = const Size(360, 1800);
      tester.view.devicePixelRatio = 1;
      final long = SpeciesCatalog.parseCsv(
        '"ワモンヒョウタンゾウムシ　屋久島亜種","Sympiezomias lewisi albidus Nakamura & Morimoto, 2015"',
      );
      await pumpScreen(tester, catalog: long);
      await tester.enterText(field('属名'), 'Sympiezomias');
      await settle(tester);

      final tile = find.ancestor(of: find.textContaining('ワモンヒョウタンゾウムシ'), matching: find.byType(ListTile));
      expect(tile, findsOneWidget);
      final title = tester.widget<ListTile>(tile).title! as SpeciesNameText;
      expect(title.name.label, contains('Sympiezomias lewisi albidus'));
      // 省略(…)にせず、折り返す:Text に行数の上限が無い
      final rich = tester.widget<RichText>(find.descendant(of: tile, matching: find.byType(RichText)).first);
      expect(rich.maxLines, isNull);
      expect(rich.overflow, isNot(TextOverflow.ellipsis));
      expect(tester.takeException(), isNull);
    });

    testWidgets('同定者の欄の下にも、特殊文字のボタンがあり、同定者の欄に入る(種名の下のボタンは入らない)', (tester) async {
      await pumpScreen(tester);
      await tester.tap(field('同定者'));
      await tester.pump();
      // 種名の下と、同定者の下に1組ずつ
      expect(find.text('ô'), findsNWidgets(2));
      await tester.tap(find.text('ô').last);
      await tester.pump();
      expect(text(tester, '同定者'), 'ô');
      expect(text(tester, '命名者・年'), '');

      // 種名の欄を触っていれば、種名の下のボタンは、その欄に入る
      await tester.tap(field('命名者・年'));
      await tester.pump();
      await tester.tap(find.text('ç').first);
      await tester.pump();
      expect(text(tester, '命名者・年'), 'ç');
      expect(text(tester, '同定者'), 'ô');
    });

    testWidgets('人名の特殊文字は、マクロンのほか、アクセントなどの文字を含む', (tester) async {
      await pumpScreen(tester);
      for (final c in ['ō', 'ū', 'Ō', 'Ū', 'ā', 'ô', 'û', 'ä', 'ö', 'ü', 'ß', 'é', 'è', 'ñ', 'ø', 'å', 'ł', 'š']) {
        expect(find.text(c), findsNWidgets(2), reason: c);
      }
    });

    testWidgets('自分が使った種(辞書)を先に出し、同じ種は目録と重ねて出さない', (tester) async {
      await pumpScreen(
        tester,
        catalog: SpeciesCatalog.parseCsv(
          '"オサムシ","Carabus insulicola Chaudoir, 1869"\n'
          '"オサムシモドキ","Carabus insulicolax Chaudoir, 1869"',
        ),
      );
      await tester.enterText(field('属名'), 'carabus');
      await settle(tester);
      final titles = tester.widgetList<ListTile>(find.byType(ListTile)).map((t) => (t.title! as SpeciesNameText).name.label).toList();
      expect(titles, ['オサムシ Carabus insulicola', 'オサムシモドキ Carabus insulicolax']);
      expect(find.text('目録'), findsOneWidget);
    });
  });
}
