import 'package:biolabelmap/core/db/database.dart';
import 'package:biolabelmap/domain/models/calendar_date.dart';
import 'package:biolabelmap/domain/models/collection_period.dart';
import 'package:biolabelmap/domain/sampling_method.dart';
import 'package:biolabelmap/domain/status.dart';
import 'package:biolabelmap/features/label/label_screen.dart';
import 'package:biolabelmap/services/catalog_number_service.dart';
import 'package:biolabelmap/services/label_service.dart';
import 'package:biolabelmap/services/record_service.dart';
import 'package:biolabelmap/services/service_providers.dart';
import 'package:biolabelmap/services/settings_service.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// 番号の確定の呼び出しを記録する(確定そのものはしない)。
class _RecordingNumbers extends CatalogNumberService {
  _RecordingNumbers(super.db, this.calls);

  final List<List<int>> calls;

  @override
  Future<ConfirmResult> confirm(Iterable<int> specimenIds) async {
    calls.add(specimenIds.toList());
    return ConfirmResult(count: specimenIds.length);
  }
}

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  /// 3標本を記録し、1件目だけ同定する(2件目は印刷済みにする)。
  Future<void> pumpScreen(
    WidgetTester tester, {
    Set<int> Function(List<LabelCandidate>)? pick,
    bool mismatchSecond = false,
    List<List<int>>? confirmCalls,
  }) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    late final AppSettingsRow settings;
    final candidates = await tester.runAsync(() async {
      await SettingsService(db).initializeCatalog(0);
      final r = await RecordService(db).save(
        RecordInput(
          position: const NewPosition(latitude: 36.9, longitude: 139.2),
          period: CollectionPeriod.singleDay(CalendarDate(2026, 6, 20)),
          recordedAt: DateTime(2026, 6, 20),
          samplingMethod: SamplingMethod.sweeping,
          count: 3,
        ),
      );
      await db.into(db.identifications).insert(
        IdentificationsCompanion.insert(
          specimenId: r.specimenIds.first,
          status: IdentificationStatus.provisional,
          genus: const Value('Carabus'),
          species: const Value('insulicola'),
        ),
      );
      await (db.update(db.specimens)..where((s) => s.id.equals(r.specimenIds[1])))
          .write(SpecimensCompanion(
            printedAt: Value(DateTime(2026, 6, 21)),
            // 印刷したときの標高が、いまの値(無し)と食い違う
            printedElevation: Value(mismatchSecond ? '9999' : ''),
          ));
      settings = await SettingsService(db).read();
      return LabelService(db).watchCandidates().first;
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          labelCandidatesProvider.overrideWith((ref) => Stream.value(candidates!)),
          settingsProvider.overrideWith((ref) => Stream.value(settings)),
          if (confirmCalls != null) catalogNumberServiceProvider.overrideWithValue(_RecordingNumbers(db, confirmCalls)),
        ],
        child: MaterialApp(home: LabelScreen(specimenIds: pick?.call(candidates!))),
      ),
    );
    await tester.pump();
  }

  testWidgets('既定は「データ+コレクション」。未印刷のみで、印刷済みを除く', (tester) async {
    await pumpScreen(tester);
    // 未印刷の2件×(データ+コレクション)
    expect(find.text('PDFを作成(4枚・1ページ)'), findsOneWidget);
    expect(find.textContaining('同定ラベルを出しません'), findsNothing);
  });

  testWidgets('「同定のみ」は、同定した標本の同定ラベルだけ。未同定の件数を知らせる', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.text('同定のみ'));
    await tester.pump();
    // 同定ラベルだけのときは、印刷状態で絞らない(3標本のうち、同定した1件)
    expect(find.text('PDFを作成(1枚・1ページ)'), findsOneWidget);
    expect(find.text('未同定の標本 2件には、同定ラベルを出しません'), findsOneWidget);
    expect(tester.widget<SwitchListTile>(find.widgetWithText(SwitchListTile, '未印刷のみ')).onChanged, isNull);
  });

  testWidgets('「3種すべて」は、データ・コレクションと同定ラベルを合わせた枚数', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.text('3種すべて'));
    await tester.pump();
    // 未印刷の2件(うち同定は1件)= データ2+コレクション2+同定1
    expect(find.text('PDFを作成(5枚・1ページ)'), findsOneWidget);
    expect(find.text('未同定の標本 1件には、同定ラベルを出しません'), findsOneWidget);
  });

  testWidgets('同定ラベルだけに切り替えて、また戻すと、未印刷のみの絞り込みが効く', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.text('同定のみ'));
    await tester.pump();
    await tester.tap(find.text('データ+コレクション'));
    await tester.pump();
    expect(find.text('PDFを作成(4枚・1ページ)'), findsOneWidget);
  });

  testWidgets('標本を選んで開いたときは、その標本だけが対象で、印刷済みも含める', (tester) async {
    // 1件目(未印刷)と2件目(印刷済み)を選んで開く
    await pumpScreen(tester, pick: (c) => {c[0].specimen.id, c[1].specimen.id});
    expect(find.text('PDFを作成(4枚・1ページ)'), findsOneWidget);
    expect(find.text('印刷済み'), findsOneWidget);
    expect(find.textContaining('KYC00003'), findsNothing);
    expect(tester.widget<SwitchListTile>(find.widgetWithText(SwitchListTile, '未印刷のみ')).value, isFalse);
  });

  testWidgets('印刷したあとに標高や地名が変わった標本は「ラベルと不一致」と出て、未印刷のみでも再印刷の対象になる', (tester) async {
    await pumpScreen(tester, mismatchSecond: true);
    expect(find.text('ラベルと不一致'), findsOneWidget);
    // 未印刷の2件に、不一致の1件を加えた3件 × (データ+コレクション)
    expect(find.text('PDFを作成(6枚・1ページ)'), findsOneWidget);
  });

  testWidgets('食い違いが無ければ、印刷済みの標本は「未印刷のみ」で除く', (tester) async {
    await pumpScreen(tester);
    expect(find.text('ラベルと不一致'), findsNothing);
    expect(find.text('PDFを作成(4枚・1ページ)'), findsOneWidget);
  });

  testWidgets('番号が未確定の標本があるとき、コレクションラベルに番号が要るので、確定してから出力するか案内する。やめれば、確定しない', (tester) async {
    final calls = <List<int>>[];
    await pumpScreen(tester, confirmCalls: calls);
    await tester.tap(find.textContaining('PDFを作成'));
    // 作成中は進行表示が回り続けるので、pumpAndSettle は使えない
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    // 未印刷の2件(印刷済みの1件は対象外)が、番号未確定
    expect(find.text('番号が未確定の標本が2件あります'), findsOneWidget);
    expect(find.textContaining('確定した番号は戻せません'), findsOneWidget);
    expect(find.text('番号を確定して出力'), findsOneWidget);

    await tester.tap(find.text('やめる'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(calls, isEmpty);
  });

  testWidgets('同定ラベルだけを出力するときは、番号が要らないので、確定の案内を出さない', (tester) async {
    final calls = <List<int>>[];
    await pumpScreen(tester, confirmCalls: calls);
    await tester.tap(find.text('同定のみ'));
    await tester.pump();
    await tester.tap(find.textContaining('PDFを作成'));
    await tester.pump();
    expect(find.textContaining('番号が未確定の標本が'), findsNothing);
    expect(calls, isEmpty);
  });
}
