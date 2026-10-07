import 'package:biolabelmap/core/db/database.dart';
import 'package:biolabelmap/domain/models/calendar_date.dart';
import 'package:biolabelmap/domain/models/collection_period.dart';
import 'package:biolabelmap/domain/sampling_method.dart';
import 'package:biolabelmap/domain/status.dart';
import 'package:biolabelmap/features/label/label_screen.dart';
import 'package:biolabelmap/services/label_service.dart';
import 'package:biolabelmap/services/record_service.dart';
import 'package:biolabelmap/services/service_providers.dart';
import 'package:biolabelmap/services/settings_service.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  /// 3標本を記録し、1件目だけ同定する(2件目は印刷済みにする)。
  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
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
          .write(SpecimensCompanion(printedAt: Value(DateTime(2026, 6, 21))));
      return LabelService(db).watchCandidates().first;
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [labelCandidatesProvider.overrideWith((ref) => Stream.value(candidates!))],
        child: const MaterialApp(home: LabelScreen()),
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
}
