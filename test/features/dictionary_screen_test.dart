import 'package:biolabelmap/core/db/database.dart';
import 'package:biolabelmap/core/db/database_provider.dart';
import 'package:biolabelmap/domain/dictionary.dart';
import 'package:biolabelmap/features/dictionary/dictionary_screen.dart';
import 'package:biolabelmap/services/dictionary_service.dart';
import 'package:biolabelmap/services/service_providers.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// 一覧は固定の値を流し(drift のストリームはテストの仮の時計と相性が悪い)、
/// 変更の呼び出しは記録する。
class _FakeDictionary extends DictionaryService {
  _FakeDictionary(super.db);

  final calls = <String>[];

  static final _now = DateTime(2026, 7, 1);

  @override
  Stream<List<DictRow<PlaceRomajiEntry>>> watchPlaces() => Stream.value([
    DictRow(PlaceRomajiEntry(id: 1, municipalityCode: '15225', localityJa: '下折立', localityEn: 'Shimooritate', useCount: 2, updatedAt: _now), 4),
  ]);

  @override
  Stream<List<DictRow<SpeciesEntry>>> watchSpecies() => Stream.value([
    DictRow(SpeciesEntry(id: 1, vernacular: 'オサムシ', genus: 'Carabus', species: 'insulicola', subspecies: '', authorship: 'Chaudoir, 1869', useCount: 3, updatedAt: _now), 5),
    DictRow(SpeciesEntry(id: 2, vernacular: '', genus: 'Damaster', species: 'blaptoides', subspecies: '', authorship: '', useCount: 1, updatedAt: _now), 0),
  ]);

  @override
  Stream<List<DictRow<TextDictEntry>>> watchTexts(DictTextKind kind) => Stream.value([
    DictRow(TextDictEntry(id: 1, kind: kind, value: kind == DictTextKind.habitat ? 'ブナ林' : 'スゲ属', useCount: 1, updatedAt: _now), 2),
    DictRow(TextDictEntry(id: 2, kind: kind, value: kind == DictTextKind.habitat ? 'ブナ林の林縁' : 'ササ属', useCount: 1, updatedAt: _now), 0),
  ]);

  @override
  Future<void> updatePlaceRomaji(int id, String localityEn) async => calls.add('place:$id:$localityEn');

  @override
  Future<void> deleteSpecies(int id) async => calls.add('deleteSpecies:$id');

  @override
  Future<void> addText(DictTextKind kind, String value) async => calls.add('add:${kind.name}:$value');

  @override
  Future<void> updateText(int id, String value) async {
    calls.add('update:$id:$value');
    throw DictionaryConflictException('同じ候補がすでにあります');
  }

  @override
  Future<void> mergeTexts(int keepId, Iterable<int> mergeIds) async => calls.add('merge:$keepId:${mergeIds.toList()}');
}

void main() {
  late AppDatabase db;
  late _FakeDictionary dict;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dict = _FakeDictionary(db);
  });
  tearDown(() => db.close());

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db), dictionaryServiceProvider.overrideWithValue(dict)],
        child: const MaterialApp(home: DictionaryScreen()),
      ),
    );
    await tester.pump();
  }

  Future<void> openTab(WidgetTester tester, String name) async {
    await tester.tap(find.widgetWithText(Tab, name));
    await tester.pumpAndSettle();
  }

  testWidgets('地名: 自治体コードの対応表が無くても開け、ローマ字と使用件数を出す', (tester) async {
    await pumpScreen(tester);
    expect(find.text('15225 下折立'), findsOneWidget);
    expect(find.text('Shimooritate'), findsOneWidget);
    expect(find.text('4件'), findsOneWidget);
  });

  testWidgets('地名: 行をタップしてローマ字を直せる(ō のボタンつき)', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.text('15225 下折立'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Shimo');
    await tester.tap(find.text('ō'));
    await tester.pump();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(dict.calls, ['place:1:Shimoō']);
  });

  testWidgets('種: 和名と学名を並べ、使用件数を出す。検索で絞り込める', (tester) async {
    await pumpScreen(tester);
    await openTab(tester, '種');
    expect(find.textContaining('Carabus insulicola', findRichText: true), findsOneWidget);
    expect(find.text('Chaudoir, 1869'), findsOneWidget);
    expect(find.text('5件'), findsOneWidget);
    expect(find.text('未使用'), findsWidgets);

    await tester.enterText(find.widgetWithText(TextField, '検索').last, 'damaster');
    await tester.pump();
    expect(find.textContaining('Carabus', findRichText: true), findsNothing);
    expect(find.textContaining('Damaster blaptoides', findRichText: true), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, '検索').last, 'zzz');
    await tester.pump();
    expect(find.text('合う候補はありません'), findsOneWidget);
  });

  testWidgets('種: 長押しで選んで削除すると、確認してから消す。標本は変わらないと案内する', (tester) async {
    await pumpScreen(tester);
    await openTab(tester, '種');
    await tester.longPress(find.textContaining('Damaster', findRichText: true));
    await tester.pump();
    expect(find.text('1件を選択'), findsOneWidget);
    await tester.tap(find.text('削除'));
    await tester.pumpAndSettle();
    expect(find.text('保存済みの標本は変わりません。'), findsOneWidget);
    expect(dict.calls, isEmpty);
    await tester.tap(find.widgetWithText(FilledButton, '削除'));
    await tester.pumpAndSettle();
    expect(dict.calls, ['deleteSpecies:2']);
  });

  testWidgets('環境: 追加できる', (tester) async {
    await pumpScreen(tester);
    await openTab(tester, '環境');
    await tester.tap(find.byTooltip('追加'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '渓流沿い');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(dict.calls, ['add:habitat:渓流沿い']);
  });

  testWidgets('寄主植物: 2件選んで、残す候補を決めて統合する', (tester) async {
    await pumpScreen(tester);
    await openTab(tester, '寄主植物');
    await tester.longPress(find.text('スゲ属'));
    await tester.pump();
    await tester.tap(find.text('ササ属'));
    await tester.pump();
    await tester.tap(find.text('統合'));
    await tester.pumpAndSettle();
    expect(find.text('どれに統合しますか'), findsOneWidget);
    await tester.tap(find.text('スゲ属(2件)'));
    await tester.pumpAndSettle();
    expect(dict.calls, ['merge:1:[1, 2]']);
  });

  testWidgets('統合は、2件以上選ぶまで押せない。地名には統合が無い', (tester) async {
    await pumpScreen(tester);
    await openTab(tester, '環境');
    await tester.longPress(find.text('ブナ林'));
    await tester.pump();
    expect(tester.widget<TextButton>(find.widgetWithText(TextButton, '統合')).onPressed, isNull);

    await openTab(tester, '地名');
    await tester.longPress(find.text('15225 下折立'));
    await tester.pump();
    expect(find.text('統合'), findsNothing);
  });

  testWidgets('編集の結果が重なるときは、理由を知らせる', (tester) async {
    await pumpScreen(tester);
    await openTab(tester, '環境');
    await tester.tap(find.text('ブナ林の林縁'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'ブナ林');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('同じ候補がすでにあります'), findsOneWidget);
  });
}
