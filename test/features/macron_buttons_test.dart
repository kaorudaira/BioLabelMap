import 'package:biolabelmap/features/common/clear_button.dart';
import 'package:biolabelmap/features/record/macron_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  _foldTests();
  group('特殊文字のボタン', () {
    Future<TextEditingController> pump(WidgetTester tester, double width, {bool person = true, bool open = true}) async {
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
              child: MacronButtons(controller: c, onInserted: () {}, personNames: person, initiallyOpen: open),
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

void _foldTests() {
  group('特殊文字のボタンの開閉', () {
    testWidgets('人名用は、ふだんは閉じていて、「特殊文字」を押すと開き、もう一度押すと閉じる', (tester) async {
      final c = TextEditingController();
      addTearDown(c.dispose);
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: MacronButtons(controller: c, onInserted: () {}, personNames: true))),
      );
      expect(find.textContaining('特殊文字'), findsOneWidget);
      expect(find.text('ô'), findsNothing);
      expect(find.byIcon(Icons.expand_more), findsOneWidget);

      await tester.tap(find.textContaining('特殊文字'));
      await tester.pump();
      expect(find.text('ô'), findsOneWidget);
      expect(find.byIcon(Icons.expand_less), findsOneWidget);

      await tester.tap(find.textContaining('特殊文字'));
      await tester.pump();
      expect(find.text('ô'), findsNothing);
    });

    testWidgets('開いて文字を入れても、閉じるまで開いたまま', (tester) async {
      final c = TextEditingController();
      addTearDown(c.dispose);
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: MacronButtons(controller: c, onInserted: () {}, personNames: true))),
      );
      await tester.tap(find.textContaining('特殊文字'));
      await tester.pump();
      await tester.tap(find.text('ô'));
      await tester.tap(find.text('ä'));
      await tester.pump();
      expect(c.text, 'ôä');
      expect(find.text('ô'), findsOneWidget);
    });

    testWidgets('地名のローマ字用(ō ū Ō Ū)は、開閉せず、いつも見えている', (tester) async {
      final c = TextEditingController();
      addTearDown(c.dispose);
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: MacronButtons(controller: c, onInserted: () {}))));
      expect(find.textContaining('特殊文字'), findsNothing);
      expect(find.text('ō'), findsOneWidget);
    });

    testWidgets('二つのボタンは、別々に開閉する', (tester) async {
      final a = TextEditingController();
      final b = TextEditingController();
      addTearDown(a.dispose);
      addTearDown(b.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                MacronButtons(controller: a, onInserted: () {}, personNames: true),
                MacronButtons(controller: b, onInserted: () {}, personNames: true),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.textContaining('特殊文字').first);
      await tester.pump();
      expect(find.text('ô'), findsOneWidget);
    });
  });
}
