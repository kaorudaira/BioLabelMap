import 'package:biolabelmap/features/common/clear_button.dart';
import 'package:biolabelmap/features/record/macron_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('特殊文字のボタン', () {
    Future<TextEditingController> pump(WidgetTester tester, double width, {bool person = true}) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final c = TextEditingController();
      addTearDown(c.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              // 入力欄のブロックの余白ぶん(左 32、右 24)
              padding: const EdgeInsets.fromLTRB(32, 12, 24, 12),
              child: MacronButtons(controller: c, onInserted: () {}, personNames: person),
            ),
          ),
        ),
      );
      return c;
    }

    for (final width in [360.0, 390.0, 412.0, 600.0]) {
      testWidgets('人名用のボタンは、画面幅 $width でも2行以内に収まる', (tester) async {
        await pump(tester, width);
        final rows = {for (final ch in personNameCharacters) tester.getTopLeft(find.text(ch)).dy};
        expect(rows.length, lessThanOrEqualTo(2));
      });
    }

    testWidgets('人名用のボタンは、マクロンのほか、サーカムフレックスやウムラウトなどを含む', (tester) async {
      await pump(tester, 390);
      for (final c in ['ō', 'ū', 'Ō', 'Ū', 'ā', 'ē', 'ī', 'ô', 'û', 'ä', 'ö', 'ü', 'ß', 'é', 'è', 'ç', 'ñ', 'ø', 'å', 'ł', 'š']) {
        expect(find.text(c), findsOneWidget, reason: c);
      }
      expect(personNameCharacters.toSet(), hasLength(personNameCharacters.length)); // 重複なし
    });

    testWidgets('押すと、カーソルの位置に文字が入る。選択中の文字は置き換える', (tester) async {
      final c = await pump(tester, 390);
      c.value = const TextEditingValue(text: 'Chjo', selection: TextSelection.collapsed(offset: 2));
      await tester.tap(find.text('û'));
      await tester.pump();
      expect(c.text, 'Chûjo');
      expect(c.selection.baseOffset, 3);

      c.value = const TextEditingValue(text: 'Ito', selection: TextSelection(baseOffset: 2, extentOffset: 3));
      await tester.tap(find.text('ô'));
      await tester.pump();
      expect(c.text, 'Itô');
    });

    testWidgets('地名のローマ字用は、ō ū Ō Ū だけ', (tester) async {
      await pump(tester, 390, person: false);
      for (final c in placeNameCharacters) {
        expect(find.text(c), findsOneWidget);
      }
      expect(find.text('ô'), findsNothing);
    });
  });

  group('入力欄の「×」(クリア)', () {
    testWidgets('入力があるときだけ出て、押すと内容を消し、クリア後の処理を呼ぶ', (tester) async {
      final c = TextEditingController();
      addTearDown(c.dispose);
      var cleared = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextField(
              controller: c,
              decoration: withClear(const InputDecoration(labelText: '名前'), c, onCleared: () => cleared++),
            ),
          ),
        ),
      );
      expect(find.byTooltip('クリア'), findsNothing);

      await tester.enterText(find.byType(TextField), 'Kaoru');
      await tester.pump();
      expect(find.byTooltip('クリア'), findsOneWidget);

      await tester.tap(find.byTooltip('クリア'));
      await tester.pump();
      expect(c.text, '');
      expect(cleared, 1);
      expect(find.byTooltip('クリア'), findsNothing);
    });
  });
}
