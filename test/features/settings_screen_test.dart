import 'package:biolabelmap/core/db/database.dart';
import 'package:biolabelmap/core/db/database_provider.dart';
import 'package:biolabelmap/features/settings/settings_screen.dart';
import 'package:biolabelmap/services/service_providers.dart';
import 'package:biolabelmap/services/settings_service.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  /// 0: 採集者名、1: 接頭辞、2: 桁数
  Finder field(int index) => find.byType(TextFormField).at(index);

  Future<void> pumpSettings(WidgetTester tester) async {
    final row = await tester.runAsync(() async {
      final settings = SettingsService(db);
      await settings.setCollectorName('Kaoru Yoshihara');
      await settings.initializeCatalog(122);
      return settings.read();
    });
    // drift のストリームはテストの仮の時計と相性が悪いので、読んだ値を固定で流す
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          settingsProvider.overrideWith((ref) => Stream.value(row!)),
        ],
        child: MaterialApp(
          home: Consumer(
            // 設定を読み込んでから開く(アプリでは初回設定の後にしか開けない)
            builder: (context, ref, _) => ref.watch(settingsProvider).hasValue
                ? const SettingsScreen()
                : const SizedBox(),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('今の設定と次の番号を表示し、書式を変えると次の番号の表示が変わる', (tester) async {
    await pumpSettings(tester);

    expect(find.text('ラベルには「K. YOSHIHARA」と印字します'), findsOneWidget);
    expect(find.text('次の標本は KYC00123 になります'), findsOneWidget);
    expect(find.text('次の番号: 123'), findsOneWidget);

    await tester.enterText(field(1), 'ABC');
    await tester.enterText(field(2), '4');
    await tester.pump();
    expect(find.text('次の標本は ABC0123 になります'), findsOneWidget);

    await tester.enterText(field(0), 'Taro Yamada');
    await tester.pump();
    await tester.tap(find.text('保存'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump();

    final saved = await tester.runAsync(() => SettingsService(db).read());
    expect(saved!.catalogPrefix, 'ABC');
    expect(saved.catalogDigits, 4);
    expect(saved.collectorName, 'Taro Yamada');
    expect(saved.nextCatalogNumber, 123);
  });

  testWidgets('空の採集者名と範囲外の桁数は保存しない', (tester) async {
    await pumpSettings(tester);

    await tester.enterText(field(2), '11');
    await tester.pump();
    await tester.enterText(field(0), ' ');
    await tester.pump();
    await tester.tap(find.text('保存'));
    await tester.pump();

    expect(find.text('採集者名を入力してください'), findsOneWidget);
    expect(find.text('1〜10'), findsOneWidget);
    final saved = await tester.runAsync(() => SettingsService(db).read());
    expect(saved!.catalogDigits, 5);
  });
}
