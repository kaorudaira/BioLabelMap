import 'package:biolabelmap/core/db/database.dart';
import 'package:biolabelmap/core/db/database_provider.dart';
import 'package:biolabelmap/domain/models/calendar_date.dart';
import 'package:biolabelmap/domain/models/collection_period.dart';
import 'package:biolabelmap/domain/sampling_method.dart';
import 'package:biolabelmap/domain/species_catalog.dart';
import 'package:biolabelmap/domain/species_name.dart';
import 'package:biolabelmap/domain/status.dart';
import 'package:biolabelmap/features/specimen/bulk_edit_screen.dart';
import 'package:biolabelmap/services/dictionary_service.dart';
import 'package:biolabelmap/services/identification_service.dart';
import 'package:biolabelmap/services/record_service.dart';
import 'package:biolabelmap/services/service_providers.dart';
import 'package:biolabelmap/services/settings_service.dart';
import 'package:biolabelmap/services/specimen_edit_service.dart';
import 'package:biolabelmap/services/specimen_service.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  final carabus = SpeciesName(vernacular: 'オサムシ', genus: 'Carabus', species: 'insulicola', authorship: 'Chaudoir, 1869');

  group('サービス:修正と同定の追加', () {
    late List<int> ids;

    setUp(() async {
      await SettingsService(db).initializeCatalog(0);
      final r = await RecordService(db).save(
        RecordInput(
          position: const NewPosition(latitude: 36.9, longitude: 139.2),
          period: CollectionPeriod.singleDay(CalendarDate(2026, 6, 20)),
          recordedAt: DateTime(2026, 6, 20),
          samplingMethod: SamplingMethod.sweeping,
          count: 3,
          confirmNow: true,
        ),
      );
      ids = r.specimenIds;
    });

    Future<SpecimenDetail> detail(int id) async => (await SpecimenService(db).detail(id))!;

    test('選んだ標本すべてに、同定を1件ずつ追加する(上書きしない)', () async {
      final service = SpecimenEditService(db);
      await service.apply(ids, SpecimenEdit(identification: IdentificationEdit(name: carabus, status: IdentificationStatus.provisional)));
      await service.apply(
        [ids[0]],
        SpecimenEdit(
          identification: IdentificationEdit(
            name: SpeciesName(genus: 'Carabus', species: 'arrowianus'),
            identifiedBy: ' K. Yoshihara ',
            dateIdentified: CalendarDate(2026, 7, 1),
            status: IdentificationStatus.verified,
          ),
        ),
      );

      final first = await detail(ids[0]);
      expect(first.history, hasLength(2));
      expect(first.latest!.species, 'arrowianus');
      expect(first.latest!.status, IdentificationStatus.verified);
      expect(first.latest!.identifiedBy, 'K. Yoshihara');
      expect(first.history.last.species, 'insulicola');
      expect((await detail(ids[1])).history, hasLength(1));
    });

    test('地名・採集方法の修正と、同定の追加を、いっしょに書く', () async {
      await SpecimenEditService(db).apply(
        ids,
        SpecimenEdit(
          method: SamplingMethod.looking,
          place: const {PlaceField.localityJa: '下折立温泉', PlaceField.localityEn: 'Shimooritate-onsen'},
          identification: IdentificationEdit(name: carabus, status: IdentificationStatus.provisional),
        ),
      );
      for (final id in ids) {
        final d = await detail(id);
        expect(d.event.samplingMethod, SamplingMethod.looking);
        expect(d.locality.localityJa, '下折立温泉');
        expect(d.latest!.genus, 'Carabus');
      }
    });

    test('同定だけの修正でも、採集や地点を作り直さない。辞書に溜まり、同定者を覚える', () async {
      await SpecimenEditService(db).apply(
        [ids[0]],
        SpecimenEdit(identification: IdentificationEdit(name: carabus, identifiedBy: 'A', status: IdentificationStatus.provisional)),
      );
      expect(await db.select(db.collectionEvents).get(), hasLength(1));
      expect(await db.select(db.localities).get(), hasLength(1));
      expect(await db.select(db.speciesDict).get(), hasLength(1));
      expect((await SettingsService(db).read()).lastIdentifier, 'A');
    });

    test('種名が空の同定は、同定を未同定にして追加する(画面では、種名が空なら追加しない)', () async {
      await SpecimenEditService(db).apply(
        [ids[0]],
        SpecimenEdit(identification: IdentificationEdit(name: SpeciesName(), status: IdentificationStatus.verified)),
      );
      expect((await detail(ids[0])).latest!.status, IdentificationStatus.unidentified);
    });

    test('同定の追加だけでも、「何も変えない修正」ではない', () {
      expect(SpecimenEdit(identification: IdentificationEdit(name: carabus, status: IdentificationStatus.provisional)).isEmpty, isFalse);
      expect(const SpecimenEdit().isEmpty, isTrue);
    });

    test('同定を追加する標本が無ければエラー(何も変えない)', () async {
      await expectLater(
        SpecimenEditService(db).apply([9999], SpecimenEdit(identification: IdentificationEdit(name: carabus, status: IdentificationStatus.provisional))),
        throwsStateError,
      );
      expect(await db.select(db.identifications).get(), isEmpty);
    });

    test('同定のサービスは、これまでどおり複数の標本に追加できる', () async {
      await IdentificationService(db, DictionaryService(db)).add(ids, name: carabus, status: IdentificationStatus.provisional);
      expect(await db.select(db.identifications).get(), hasLength(3));
    });
  });

  group('画面:一括編集・編集の「同定を追加」', () {
    late List<int> ids;

    Future<void> seed(WidgetTester tester) async {
      ids = (await tester.runAsync(() async {
        await SettingsService(db).initializeCatalog(0);
        final r = await RecordService(db).save(
          RecordInput(
            position: const NewPosition(latitude: 36.9, longitude: 139.2),
            period: CollectionPeriod.singleDay(CalendarDate(2026, 6, 20)),
            recordedAt: DateTime(2026, 6, 20),
            samplingMethod: SamplingMethod.sweeping,
            count: 3,
            confirmNow: true,
          ),
        );
        return r.specimenIds;
      }))!;
    }

    Future<void> pump(WidgetTester tester, {required List<int> targets, bool single = false}) async {
      tester.view.physicalSize = const Size(800, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final initial = single ? (await tester.runAsync(() => SpecimenService(db).detail(targets.single))) : null;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            speciesCatalogProvider.overrideWith((ref) async => SpeciesCatalog.empty),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: FilledButton(
                  onPressed: () => Navigator.push<bool>(
                    context,
                    MaterialPageRoute(builder: (_) => BulkEditScreen(args: BulkEditArgs(targets, initial: initial))),
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

    Future<void> save(WidgetTester tester, String label) async {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 80)));
      await tester.pumpAndSettle();
    }

    Finder field(String label) => find.widgetWithText(TextField, label);

    Future<List<Identification>> history() async => (await db.select(db.identifications).get());

    testWidgets('一括編集:「同定を追加(任意)」の欄がある。種名が空なら、同定を追加しない', (tester) async {
      await seed(tester);
      await pump(tester, targets: ids);
      expect(find.text('同定を追加(任意)'), findsOneWidget);
      expect(find.textContaining('種名を入れたときだけ、選んだ3件すべてに'), findsOneWidget);
      for (final label in ['和名(任意)', '属名', '種小名', '亜種名', '命名者・年', '同定者']) {
        expect(field(label), findsOneWidget, reason: label);
      }

      // 地名だけを直す(英文も)。同定の欄は空のまま
      await tester.enterText(field('大字(和)'), '下折立温泉');
      await tester.enterText(field('大字(ローマ字)'), 'Shimooritate-onsen');
      await save(tester, '3件に反映');
      expect((await tester.runAsync(history))!, isEmpty);
    });

    testWidgets('一括編集:種名を入れると、選んだ全標本に同定を追加する。地名の修正といっしょに', (tester) async {
      await seed(tester);
      await pump(tester, targets: ids.sublist(0, 2));
      await tester.enterText(field('和名(任意)'), 'オサムシ');
      await tester.enterText(field('属名'), 'Carabus');
      await tester.enterText(field('種小名'), 'insulicola');
      await tester.enterText(field('同定者'), 'K. Yoshihara');
      await tester.enterText(field('大字(和)'), '下折立温泉');
      await tester.enterText(field('大字(ローマ字)'), 'Shimooritate-onsen');
      await save(tester, '2件に反映');

      final rows = (await tester.runAsync(history))!;
      expect(rows.map((r) => r.specimenId).toSet(), {ids[0], ids[1]});
      expect(rows.every((r) => r.genus == 'Carabus' && r.species == 'insulicola'), isTrue);
      expect(rows.first.status, IdentificationStatus.provisional);
      expect(rows.first.identifiedBy, 'K. Yoshihara');
      final d = (await tester.runAsync(() => SpecimenService(db).detail(ids[0])))!;
      expect(d.locality.localityJa, '下折立温泉');
    });

    testWidgets('編集:いまの同定が入っている。何も変えなければ、同定を追加しない', (tester) async {
      await seed(tester);
      await tester.runAsync(
        () => IdentificationService(db, DictionaryService(db)).add(
          [ids[0]],
          name: carabus,
          status: IdentificationStatus.provisional,
        ),
      );
      await pump(tester, targets: [ids[0]], single: true);
      expect(tester.widget<TextField>(field('属名')).controller!.text, 'Carabus');
      expect(tester.widget<TextField>(field('命名者・年')).controller!.text, 'Chaudoir, 1869');
      expect(find.textContaining('種名・状態・同定者・同定日のどれかを変えたときだけ'), findsOneWidget);

      // 何も変えずに、メモだけ直しても、同定は追加しない(同定者の欄に既定の名前が入っていても、変更とみなさない)
      await tester.enterText(field('メモ'), '朝霧');
      await save(tester, '保存');
      expect((await tester.runAsync(history))!, hasLength(1));
    });

    /// 同定者・同定日を指定して、同定を1件入れておく。
    Future<void> identify(int id, {String? by, CalendarDate? on, IdentificationStatus status = IdentificationStatus.provisional}) =>
        IdentificationService(db, DictionaryService(db)).add([id], name: carabus, identifiedBy: by, dateIdentified: on, status: status);

    testWidgets('編集:同定者と同定日の欄には、いまの同定の値が入っている', (tester) async {
      await seed(tester);
      await tester.runAsync(() => identify(ids[0], by: 'K. Yoshihara', on: CalendarDate(2026, 7, 1)));
      await pump(tester, targets: [ids[0]], single: true);
      expect(tester.widget<TextField>(field('同定者')).controller!.text, 'K. Yoshihara');
      expect(find.text('同定日 2026-07-01'), findsOneWidget);
    });

    testWidgets('編集:同定者を変えると、同じ種名でも、新しい同定を履歴に追加する', (tester) async {
      await seed(tester);
      await tester.runAsync(() => identify(ids[0], by: 'A', on: CalendarDate(2026, 7, 1)));
      await pump(tester, targets: [ids[0]], single: true);
      await tester.enterText(field('同定者'), 'B');
      await save(tester, '保存');

      final d = (await tester.runAsync(() => SpecimenService(db).detail(ids[0])))!;
      expect(d.history.map((i) => i.identifiedBy), ['B', 'A']);
      expect(d.latest!.species, 'insulicola');
      expect(d.latest!.dateIdentified, CalendarDate(2026, 7, 1));
    });

    testWidgets('編集:同定日を変えると、新しい同定を履歴に追加する', (tester) async {
      await seed(tester);
      await tester.runAsync(() => identify(ids[0], by: 'A', on: CalendarDate(2026, 7, 1)));
      await pump(tester, targets: [ids[0]], single: true);
      await tester.ensureVisible(find.text('同定日 2026-07-01'));
      await tester.pump();
      await tester.tap(find.text('同定日 2026-07-01'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('15'));
      await tester.pump();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('同定日 2026-07-15'), findsOneWidget);
      await save(tester, '保存');

      final d = (await tester.runAsync(() => SpecimenService(db).detail(ids[0])))!;
      expect(d.history, hasLength(2));
      expect(d.latest!.dateIdentified, CalendarDate(2026, 7, 15));
      expect(d.latest!.identifiedBy, 'A');
    });

    testWidgets('編集:同定日や同定者を触っても、元の値に戻せば、追加しない', (tester) async {
      await seed(tester);
      await tester.runAsync(() => identify(ids[0], by: 'A', on: CalendarDate(2026, 7, 1)));
      await pump(tester, targets: [ids[0]], single: true);
      await tester.enterText(field('同定者'), 'B');
      await tester.enterText(field('同定者'), 'A');
      await tester.enterText(field('メモ'), 'x');
      await save(tester, '保存');
      expect((await tester.runAsync(history))!, hasLength(1));
    });

    testWidgets('編集:同定者が空の同定で、設定の既定の名前が入っていても、触らなければ追加しない', (tester) async {
      await seed(tester);
      await tester.runAsync(() async {
        await identify(ids[0]);
        await db.update(db.appSettings).write(const AppSettingsCompanion(lastIdentifier: Value('既定の人')));
      });
      await pump(tester, targets: [ids[0]], single: true);
      expect(tester.widget<TextField>(field('同定者')).controller!.text, '既定の人');
      await tester.enterText(field('メモ'), 'x');
      await save(tester, '保存');
      expect((await tester.runAsync(history))!, hasLength(1));
    });

    testWidgets('編集:「未同定に戻す」で、未同定の同定を履歴に追加する(いまの同定は履歴に残る)', (tester) async {
      await seed(tester);
      await tester.runAsync(() => identify(ids[0], by: 'A', status: IdentificationStatus.verified));
      await pump(tester, targets: [ids[0]], single: true);
      expect(find.text('未同定に戻す'), findsOneWidget);

      await tester.tap(find.text('未同定に戻す'));
      await tester.pump();
      // 種名の欄は隠れ、戻すことを知らせる
      expect(find.text('この標本の同定を、未同定に戻します。'), findsOneWidget);
      expect(field('属名'), findsNothing);
      await save(tester, '保存');

      final d = (await tester.runAsync(() => SpecimenService(db).detail(ids[0])))!;
      expect(d.history, hasLength(2));
      expect(d.latest!.status, IdentificationStatus.unidentified);
      expect(d.latest!.genus, isNull);
      expect(d.latest!.vernacularName, isNull);
      expect(d.history.last.status, IdentificationStatus.verified); // もとの同定は、そのまま
      // 辞書は増えない
      expect((await tester.runAsync(() => db.select(db.speciesDict).get()))!, hasLength(1));
    });

    testWidgets('編集:同定が無い標本には、「未同定に戻す」を出さない', (tester) async {
      await seed(tester);
      await pump(tester, targets: [ids[1]], single: true);
      expect(find.text('未同定に戻す'), findsNothing);
    });

    testWidgets('編集:「未同定に戻す」を入れて切ると、入力欄が戻り、種名の入力も残っている', (tester) async {
      await seed(tester);
      await tester.runAsync(() => identify(ids[0]));
      await pump(tester, targets: [ids[0]], single: true);
      await tester.tap(find.text('未同定に戻す'));
      await tester.pump();
      await tester.tap(find.text('未同定に戻す'));
      await tester.pump();
      expect(field('属名'), findsOneWidget);
      expect(tester.widget<TextField>(field('属名')).controller!.text, 'Carabus');
    });

    testWidgets('一括編集:「未同定に戻す」で、選んだ全標本に、未同定の同定を追加する', (tester) async {
      await seed(tester);
      await tester.runAsync(() => identify(ids[0]));
      await pump(tester, targets: ids.sublist(0, 2));
      expect(find.text('未同定に戻す'), findsOneWidget);
      await tester.tap(find.text('未同定に戻す'));
      await tester.pump();
      expect(find.text('選んだ2件の同定を、未同定に戻します。'), findsOneWidget);
      await save(tester, '2件に反映');

      final rows = (await tester.runAsync(history))!;
      final unidentified = rows.where((r) => r.status == IdentificationStatus.unidentified).toList();
      expect(unidentified.map((r) => r.specimenId).toSet(), {ids[0], ids[1]});
      expect(rows, hasLength(3)); // もとの1件+未同定の2件
    });

    testWidgets('一括編集:「未同定に戻す」を入れなければ、種名が空のとき、何も追加しない', (tester) async {
      await seed(tester);
      await pump(tester, targets: ids);
      await tester.enterText(field('大字(和)'), 'x');
      await tester.enterText(field('大字(ローマ字)'), 'y');
      await save(tester, '3件に反映');
      expect((await tester.runAsync(history))!, isEmpty);
    });

    testWidgets('編集:種名を変えると、新しい同定を履歴に追加する(上書きしない)', (tester) async {
      await seed(tester);
      await tester.runAsync(
        () => IdentificationService(db, DictionaryService(db)).add(
          [ids[0]],
          name: carabus,
          status: IdentificationStatus.provisional,
        ),
      );
      await pump(tester, targets: [ids[0]], single: true);
      await tester.enterText(field('種小名'), 'arrowianus');
      await save(tester, '保存');

      final rows = (await tester.runAsync(history))!;
      expect(rows, hasLength(2));
      expect(rows.map((r) => r.species), containsAll(['insulicola', 'arrowianus']));
      final d = (await tester.runAsync(() => SpecimenService(db).detail(ids[0])))!;
      expect(d.latest!.species, 'arrowianus');
    });

    testWidgets('編集:状態を「同定済み」に変えると、同じ種名でも、新しい同定を追加する', (tester) async {
      await seed(tester);
      await tester.runAsync(
        () => IdentificationService(db, DictionaryService(db)).add(
          [ids[0]],
          name: carabus,
          status: IdentificationStatus.provisional,
        ),
      );
      await pump(tester, targets: [ids[0]], single: true);
      await tester.ensureVisible(find.text('同定済み'));
      await tester.pump();
      await tester.tap(find.text('同定済み'));
      await tester.pump();
      await save(tester, '保存');
      final d = (await tester.runAsync(() => SpecimenService(db).detail(ids[0])))!;
      expect(d.history, hasLength(2));
      expect(d.latest!.status, IdentificationStatus.verified);
    });

    testWidgets('編集:種名を消しても、「未同定に戻す」は行わない', (tester) async {
      await seed(tester);
      await tester.runAsync(
        () => IdentificationService(db, DictionaryService(db)).add(
          [ids[0]],
          name: carabus,
          status: IdentificationStatus.provisional,
        ),
      );
      await pump(tester, targets: [ids[0]], single: true);
      await tester.tap(find.text('クリア'));
      await tester.pump();
      await tester.enterText(field('メモ'), 'x');
      await save(tester, '保存');
      expect((await tester.runAsync(history))!, hasLength(1));
    });

    testWidgets('編集:同定がまだ無い標本は、空の欄から、種名を入れて追加できる', (tester) async {
      await seed(tester);
      await pump(tester, targets: [ids[1]], single: true);
      expect(tester.widget<TextField>(field('属名')).controller!.text, '');
      await tester.enterText(field('属名'), 'Atheta');
      await tester.enterText(field('種小名'), 'transfuga');
      await save(tester, '保存');
      final d = (await tester.runAsync(() => SpecimenService(db).detail(ids[1])))!;
      expect(d.latest!.genus, 'Atheta');
      expect(d.history, hasLength(1));
    });
  });
}

