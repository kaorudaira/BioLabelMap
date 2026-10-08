import 'package:biolabelmap/core/db/database.dart';
import 'package:biolabelmap/core/db/database_provider.dart';
import 'package:biolabelmap/domain/models/calendar_date.dart';
import 'package:biolabelmap/domain/models/collection_period.dart';
import 'package:biolabelmap/domain/models/place_info.dart';
import 'package:biolabelmap/domain/sampling_method.dart';
import 'package:biolabelmap/domain/specimen_list.dart';
import 'package:biolabelmap/domain/species_name.dart';
import 'package:biolabelmap/domain/status.dart';
import 'package:biolabelmap/features/specimen/bulk_edit_screen.dart';
import 'package:biolabelmap/features/specimen/specimen_detail_screen.dart';
import 'package:biolabelmap/features/specimen/specimen_list_screen.dart';
import 'package:biolabelmap/features/specimen/trash_screen.dart';
import 'package:biolabelmap/services/record_service.dart';
import 'package:biolabelmap/services/service_providers.dart';
import 'package:biolabelmap/services/settings_service.dart';
import 'package:biolabelmap/services/specimen_edit_service.dart';
import 'package:biolabelmap/services/specimen_service.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// 変更の呼び出しを記録する。
class _RecordingEdit extends SpecimenEditService {
  _RecordingEdit(super.db);

  final calls = <String>[];

  @override
  Future<void> moveToTrash(Iterable<int> specimenIds, {DateTime? now}) async => calls.add('trash:${specimenIds.toList()}');

  @override
  Future<void> restore(Iterable<int> specimenIds) async => calls.add('restore:${specimenIds.toList()}');

  @override
  Future<int> deletePermanently(Iterable<int> specimenIds) async {
    calls.add('delete:${specimenIds.toList()}');
    return specimenIds.length;
  }
}

SpecimenListItem item(
  int n, {
  SpeciesName species = SpeciesName.unidentified,
  DateTime? deletedAt,
  int day = 20,
}) => SpecimenListItem(
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
  printed: false,
  deletedAt: deletedAt,
);

void main() {
  _detailActionTests();
  late AppDatabase db;
  late _RecordingEdit edit;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    edit = _RecordingEdit(db);
  });
  tearDown(() => db.close());

  group('標本一覧の選択モード', () {
    final carabus = SpeciesName(vernacular: 'オサムシ', genus: 'Carabus', species: 'a');
    final atheta = SpeciesName(vernacular: 'クボタ', genus: 'Atheta', species: 'b');
    final pushed = <String>[];

    Future<void> pump(WidgetTester tester, List<SpecimenListItem> items) async {
      pushed.clear();
      final router = GoRouter(
        initialLocation: '/specimens',
        routes: [
          GoRoute(path: '/specimens', builder: (_, _) => const SpecimenListScreen()),
          GoRoute(
            path: '/labels',
            builder: (_, s) {
              pushed.add('labels:${s.extra}');
              return const Text('ラベル画面');
            },
          ),
          GoRoute(path: '/trash', builder: (_, _) => const Text('ごみ箱画面')),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            specimenItemsProvider.overrideWith((ref) => Stream.value(items)),
            specimenEditServiceProvider.overrideWithValue(edit),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();
    }

    testWidgets('行を長押しすると選択モードに入り、画面下に操作が出る', (tester) async {
      await pump(tester, [item(1, species: carabus), item(2, species: carabus), item(3, species: atheta)]);
      expect(find.text('ラベル出力'), findsNothing);

      await tester.longPress(find.textContaining('オサムシ'));
      await tester.pump();
      // 行はまとまりなので、行の標本2件をまとめて選ぶ
      expect(find.text('2件を選択'), findsOneWidget);
      for (final label in ['ラベル出力', '一括編集', '同定を追加', '削除']) {
        expect(find.text(label), findsOneWidget, reason: label);
      }

      // 選択モード中は、タップで行を足したり外したりする
      await tester.tap(find.textContaining('クボタ'));
      await tester.pump();
      expect(find.text('3件を選択'), findsOneWidget);
      await tester.tap(find.textContaining('オサムシ'));
      await tester.pump();
      expect(find.text('1件を選択'), findsOneWidget);
      // 全部外しても、選択モードのまま。何も選んでいないときは、操作を押せない
      await tester.tap(find.textContaining('クボタ'));
      await tester.pump();
      expect(find.text('標本を選んでください'), findsOneWidget);
      final inkWells = find.ancestor(of: find.text('ラベル出力'), matching: find.byType(InkWell));
      expect(tester.widget<InkWell>(inkWells).onTap, isNull);
      await tester.tap(find.byTooltip('選択を解除'));
      await tester.pump();
      expect(find.text('標本一覧'), findsOneWidget);
      expect(find.text('ラベル出力'), findsNothing);
    });

    testWidgets('上部の「選択」ボタンで選択モードに入り、行をタップして選ぶ', (tester) async {
      await pump(tester, [item(1, species: carabus), item(3, species: atheta)]);
      expect(find.text('ラベル出力'), findsNothing);
      await tester.tap(find.byTooltip('選択'));
      await tester.pump();
      expect(find.text('標本を選んでください'), findsOneWidget);
      expect(find.text('ラベル出力'), findsOneWidget);

      await tester.tap(find.textContaining('クボタ'));
      await tester.pump();
      expect(find.text('1件を選択'), findsOneWidget);
      expect(tester.widget<InkWell>(find.ancestor(of: find.text('ラベル出力'), matching: find.byType(InkWell))).onTap, isNotNull);
    });

    testWidgets('全て選択・全て解除と、選択を閉じるボタン', (tester) async {
      await pump(tester, [item(1, species: carabus), item(3, species: atheta)]);
      await tester.longPress(find.textContaining('オサムシ'));
      await tester.pump();
      await tester.tap(find.text('全て選択'));
      await tester.pump();
      expect(find.text('2件を選択'), findsOneWidget);
      await tester.tap(find.text('全て解除'));
      await tester.pump();
      expect(find.text('0件を選択'), findsNothing);
      expect(find.text('標本を選んでください'), findsOneWidget);

      await tester.longPress(find.textContaining('クボタ'));
      await tester.pump();
      await tester.tap(find.byTooltip('選択を解除'));
      await tester.pump();
      expect(find.text('標本一覧'), findsOneWidget);
    });

    testWidgets('ラベル出力は、選んだ標本の ID を渡して開く', (tester) async {
      await pump(tester, [item(1, species: carabus), item(2, species: carabus), item(3, species: atheta)]);
      await tester.longPress(find.textContaining('オサムシ'));
      await tester.pump();
      await tester.tap(find.text('ラベル出力'));
      await tester.pumpAndSettle();
      expect(find.text('ラベル画面'), findsOneWidget);
      expect(pushed, ['labels:[1, 2]']);
    });

    testWidgets('削除は、確認してからごみ箱に移す', (tester) async {
      await pump(tester, [item(1, species: carabus), item(3, species: atheta)]);
      await tester.longPress(find.textContaining('クボタ'));
      await tester.pump();
      await tester.tap(find.text('削除'));
      await tester.pumpAndSettle();
      expect(find.text('1件をごみ箱に移しますか'), findsOneWidget);
      expect(edit.calls, isEmpty);

      await tester.tap(find.text('ごみ箱に移す'));
      await tester.pumpAndSettle();
      expect(edit.calls, ['trash:[3]']);
      expect(find.text('標本一覧'), findsOneWidget); // 選択モードを抜ける
    });

    testWidgets('右上のメニューから、ごみ箱を開く', (tester) async {
      await pump(tester, [item(1)]);
      await tester.tap(find.byTooltip('メニュー'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ごみ箱'));
      await tester.pumpAndSettle();
      expect(find.text('ごみ箱画面'), findsOneWidget);
    });
  });

  group('ごみ箱', () {
    final now = DateTime(2026, 7, 11, 12);

    Future<void> pump(WidgetTester tester, List<SpecimenListItem> items) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trashedItemsProvider.overrideWith((ref) => Stream.value(items)),
            specimenEditServiceProvider.overrideWithValue(edit),
          ],
          child: MaterialApp(home: TrashScreen(now: now)),
        ),
      );
      await tester.pump();
    }

    final items = [
      item(1, deletedAt: DateTime(2026, 7, 1, 12)),
      item(2, deletedAt: DateTime(2026, 7, 10, 12)),
      item(3, deletedAt: DateTime(2026, 6, 1)),
    ];

    testWidgets('削除日の新しい順に並べ、各行に完全に削除するまでの日数を出す', (tester) async {
      await pump(tester, items);
      expect(find.text('あと29日で完全に削除'), findsOneWidget);
      expect(find.text('あと20日で完全に削除'), findsOneWidget);
      expect(find.text('まもなく完全に削除'), findsOneWidget);
      double y(String t) => tester.getTopLeft(find.textContaining(t)).dy;
      expect(y('KYC00002'), lessThan(y('KYC00001')));
      expect(y('KYC00001'), lessThan(y('KYC00003')));
    });

    testWidgets('ごみ箱が空なら案内を出す', (tester) async {
      await pump(tester, []);
      expect(find.text('ごみ箱は空です'), findsOneWidget);
    });

    testWidgets('長押しで選ぶと「元に戻す」と「今すぐ完全に削除」が出て、元に戻せる', (tester) async {
      await pump(tester, items);
      expect(find.text('元に戻す'), findsNothing);
      await tester.longPress(find.textContaining('KYC00001'));
      await tester.pump();
      await tester.tap(find.textContaining('KYC00002'));
      await tester.pump();
      expect(find.text('2件を選択'), findsOneWidget);

      await tester.tap(find.text('元に戻す'));
      await tester.pumpAndSettle();
      expect(edit.calls, ['restore:[1, 2]']);
    });

    testWidgets('今すぐ完全に削除は、元に戻せないと確認してから行う', (tester) async {
      await pump(tester, items);
      await tester.longPress(find.textContaining('KYC00003'));
      await tester.pump();
      await tester.tap(find.text('今すぐ完全に削除'));
      await tester.pumpAndSettle();
      expect(find.textContaining('元に戻せません'), findsOneWidget);
      expect(edit.calls, isEmpty);

      await tester.tap(find.widgetWithText(FilledButton, '完全に削除'));
      await tester.pumpAndSettle();
      expect(edit.calls, ['delete:[3]']);
    });
  });

  group('一括編集・編集', () {
    late List<int> ids;

    /// 3標本を1つの採集に記録する。
    Future<SpecimenDetail> seed(WidgetTester tester) async => (await tester.runAsync(() async {
      await SettingsService(db).initializeCatalog(0);
      final r = await RecordService(db).save(
        RecordInput(
          position: const NewPosition(
            latitude: 36.9,
            longitude: 139.2,
            place: PlaceInfo(prefectureJa: '新潟県', municipalityJa: '魚沼市', localityJa: '下折立', localityEn: 'Shimooritate'),
          ),
          period: CollectionPeriod.singleDay(CalendarDate(2026, 6, 20)),
          recordedAt: DateTime(2026, 6, 20),
          samplingMethod: SamplingMethod.sweeping,
          habitat: 'ブナ林',
          count: 3,
        ),
      );
      ids = r.specimenIds;
      return SpecimenService(db).detail(ids.first);
    }))!;

    Future<void> pump(WidgetTester tester, BulkEditArgs args) async {
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
                  onPressed: () async {
                    final done = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(builder: (_) => BulkEditScreen(args: args)),
                    );
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('結果: $done')));
                  },
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

    Finder field(String label) => find.widgetWithText(TextField, label);

    testWidgets('一括編集:採集方法と地名を、選んだ標本にまとめて反映する。空欄は変えない', (tester) async {
      await seed(tester);
      await pump(tester, BulkEditArgs(ids.sublist(0, 2)));
      expect(find.text('一括編集(2件)'), findsOneWidget);
      expect(find.text('変更しない'), findsOneWidget);

      await tester.tap(find.text('変更しない'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ルッキング').last);
      await tester.pumpAndSettle();
      await tester.enterText(field('大字(和)'), '下折立温泉');
      await tester.enterText(field('大字(ローマ字)'), 'Shimooritate-onsen');
      await tester.tap(find.text('2件に反映'));
      await tester.pumpAndSettle();
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();

      expect(find.text('2件を修正しました'), findsOneWidget);
      final changed = (await tester.runAsync(() => SpecimenService(db).detail(ids[0])))!;
      expect(changed.event.samplingMethod, SamplingMethod.looking);
      expect(changed.locality.localityJa, '下折立温泉');
      expect(changed.locality.municipalityJa, '魚沼市'); // 空欄は変わらない
      // 選ばなかった標本は、元のまま
      final untouched = (await tester.runAsync(() => SpecimenService(db).detail(ids[2])))!;
      expect(untouched.event.samplingMethod, SamplingMethod.sweeping);
      expect(untouched.locality.localityJa, '下折立');
    });

    testWidgets('一括編集:何も入力しなければ、何も変えずに閉じる', (tester) async {
      await seed(tester);
      await pump(tester, BulkEditArgs(ids));
      await tester.tap(find.text('3件に反映'));
      await tester.pumpAndSettle();
      expect(find.text('結果: false'), findsOneWidget);
      expect(await tester.runAsync(() => db.select(db.collectionEvents).get()), hasLength(1));
    });

    testWidgets('地名の和文だけを変えるときは、確認を出す。「戻る」なら保存しない', (tester) async {
      await seed(tester);
      await pump(tester, BulkEditArgs(ids));
      await tester.enterText(field('大字(和)'), '下折立温泉');
      await tester.tap(find.text('3件に反映'));
      await tester.pumpAndSettle();
      expect(find.text('和文の地名だけを変更します'), findsOneWidget);
      expect(find.textContaining('英文(ローマ字)の地名は変わりません'), findsOneWidget);

      await tester.tap(find.text('戻る'));
      await tester.pumpAndSettle();
      expect(find.text('一括編集(3件)'), findsOneWidget); // 編集画面に残る
      final unchanged = (await tester.runAsync(() => SpecimenService(db).detail(ids[0])))!;
      expect(unchanged.locality.localityJa, '下折立');
    });

    testWidgets('地名の英文だけを変えるときも、確認を出す。「そのまま保存」なら保存する', (tester) async {
      await seed(tester);
      await pump(tester, BulkEditArgs(ids));
      await tester.enterText(field('大字(ローマ字)'), 'Shimooritate-onsen');
      await tester.tap(find.text('3件に反映'));
      await tester.pumpAndSettle();
      expect(find.text('英文の地名だけを変更します'), findsOneWidget);

      await tester.tap(find.text('そのまま保存'));
      await tester.pumpAndSettle();
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();
      final changed = (await tester.runAsync(() => SpecimenService(db).detail(ids[0])))!;
      expect(changed.locality.localityEn, 'Shimooritate-onsen');
      expect(changed.locality.localityJa, '下折立');
    });

    testWidgets('和文と英文の両方を変えるときは、確認を出さない', (tester) async {
      await seed(tester);
      await pump(tester, BulkEditArgs(ids));
      await tester.enterText(field('大字(和)'), '下折立温泉');
      await tester.enterText(field('大字(ローマ字)'), 'Shimooritate-onsen');
      await tester.tap(find.text('3件に反映'));
      await tester.pumpAndSettle();
      expect(find.textContaining('だけを変更します'), findsNothing);
      expect(find.text('3件を修正しました'), findsOneWidget);
    });

    testWidgets('採集方法だけを変えるときは、地名の確認を出さない', (tester) async {
      await seed(tester);
      await pump(tester, BulkEditArgs(ids));
      await tester.tap(find.text('変更しない'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ルッキング').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('3件に反映'));
      await tester.pumpAndSettle();
      expect(find.textContaining('だけを変更します'), findsNothing);
    });

    testWidgets('編集:座標を、いまの座標を表示して「地図で座標を直す」から選び直せる', (tester) async {
      final d = await seed(tester);
      await pump(tester, BulkEditArgs([ids.first], initial: d));
      expect(find.text('36.90000°N 139.20000°E'), findsOneWidget);
      expect(find.text('地図で座標を直す'), findsOneWidget);
    });

    testWidgets('一括編集では、座標は直せない', (tester) async {
      await seed(tester);
      await pump(tester, BulkEditArgs(ids));
      expect(find.text('地図で座標を直す'), findsNothing);
    });

    testWidgets('編集:いまの値が入っている。1件だけ直すと、その標本のために採集を複製する', (tester) async {
      final d = await seed(tester);
      await pump(tester, BulkEditArgs([ids.first], initial: d));
      expect(find.text('編集 KYC00001'), findsOneWidget);
      expect(tester.widget<TextField>(field('環境')).controller!.text, 'ブナ林');
      expect(tester.widget<TextField>(field('大字(和)')).controller!.text, '下折立');

      await tester.enterText(field('環境'), '草地');
      await tester.enterText(field('メモ'), '朝霧');
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();

      expect(find.text('1件を修正しました'), findsOneWidget);
      final changed = (await tester.runAsync(() => SpecimenService(db).detail(ids[0])))!;
      expect(changed.event.habitat, '草地');
      expect(changed.specimen.remarks, '朝霧');
      final other = (await tester.runAsync(() => SpecimenService(db).detail(ids[1])))!;
      expect(other.event.habitat, 'ブナ林');
      expect(other.specimen.remarks, isNull);
      expect(await tester.runAsync(() => db.select(db.collectionEvents).get()), hasLength(2));
    });

    testWidgets('編集:何も変えずに保存すると、採集を複製しない', (tester) async {
      final d = await seed(tester);
      await pump(tester, BulkEditArgs([ids.first], initial: d));
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      expect(find.text('結果: false'), findsOneWidget);
      expect(await tester.runAsync(() => db.select(db.collectionEvents).get()), hasLength(1));
    });

    testWidgets('編集:地名の欄を空にすると、その項目を空にする', (tester) async {
      final d = await seed(tester);
      await pump(tester, BulkEditArgs(ids, initial: d));
      await tester.enterText(field('大字(ローマ字)'), '');
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      // 英文だけを変えるので、確認が出る
      await tester.tap(find.text('そのまま保存'));
      await tester.pumpAndSettle();
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();
      final changed = (await tester.runAsync(() => SpecimenService(db).detail(ids[0])))!;
      expect(changed.locality.localityEn, isNull);
      expect(changed.locality.localityJa, '下折立');
    });
  });
}

void _detailActionTests() {
  group('標本詳細の操作', () {
    late AppDatabase db;
    late _RecordingEdit edit;
    final pushed = <String>[];

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      edit = _RecordingEdit(db);
      pushed.clear();
    });
    tearDown(() => db.close());

    Future<void> pump(WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final detail = (await tester.runAsync(() async {
        await SettingsService(db).initializeCatalog(0);
        final r = await RecordService(db).save(
          RecordInput(
            position: const NewPosition(latitude: 36.9, longitude: 139.2),
            period: CollectionPeriod.singleDay(CalendarDate(2026, 6, 20)),
            recordedAt: DateTime(2026, 6, 20),
            samplingMethod: SamplingMethod.sweeping,
          ),
        );
        return SpecimenService(db).detail(r.specimenIds.single);
      }))!;
      final router = GoRouter(
        initialLocation: '/specimens',
        routes: [
          GoRoute(path: '/specimens', builder: (_, _) => const Text('一覧')),
          GoRoute(path: '/specimens/:id', builder: (_, _) => SpecimenDetailScreen(specimenId: detail.specimen.id)),
          GoRoute(
            path: '/labels',
            builder: (_, s) {
              pushed.add('labels:${s.extra}');
              return const Text('ラベル画面');
            },
          ),
          GoRoute(
            path: '/bulk-edit',
            builder: (_, s) {
              final args = s.extra! as BulkEditArgs;
              pushed.add('edit:${args.specimenIds}:${args.initial != null}');
              return const Text('編集画面');
            },
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            specimenDetailProvider(detail.specimen.id).overrideWith((ref) => Stream.value(detail)),
            specimenEditServiceProvider.overrideWithValue(edit),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      router.push('/specimens/${detail.specimen.id}');
      await tester.pumpAndSettle();
    }

    testWidgets('画面下に、編集・同地点で追加・ラベル出力・削除が並ぶ', (tester) async {
      await pump(tester);
      for (final label in ['編集', '同地点で追加', 'ラベル出力', '削除']) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
    });

    testWidgets('編集は、この1件のいまの内容を渡して編集画面を開く', (tester) async {
      await pump(tester);
      await tester.tap(find.text('編集'));
      await tester.pumpAndSettle();
      expect(find.text('編集画面'), findsOneWidget);
      expect(pushed.single, startsWith('edit:['));
      expect(pushed.single, endsWith(':true'));
    });

    testWidgets('ラベル出力は、この1件でラベル出力を開く', (tester) async {
      await pump(tester);
      await tester.tap(find.text('ラベル出力'));
      await tester.pumpAndSettle();
      expect(find.text('ラベル画面'), findsOneWidget);
      expect(pushed.single, startsWith('labels:['));
    });

    testWidgets('削除は、確認してからごみ箱に移し、一覧に戻る', (tester) async {
      await pump(tester);
      await tester.tap(find.text('削除'));
      await tester.pumpAndSettle();
      expect(find.textContaining('をごみ箱に移しますか'), findsOneWidget);
      expect(edit.calls, isEmpty);

      await tester.tap(find.text('ごみ箱に移す'));
      await tester.pumpAndSettle();
      expect(edit.calls.single, startsWith('trash:['));
      expect(find.text('一覧'), findsOneWidget);
    });
  });
}
