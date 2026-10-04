import 'package:flutter_test/flutter_test.dart';

import '../../tools/municipalities/romanize.dart';

void main() {
  group('halfToFullKatakana', () {
    test('濁点・半濁点・小書きをまとめる', () {
      expect(halfToFullKatakana('ｻｯﾎﾟﾛｼﾁｭｳｵｳｸ'), 'サッポロシチュウオウク');
      expect(halfToFullKatakana('ﾐﾅﾐｳｵﾇﾏｸﾞﾝﾕｻﾞﾜﾏﾁ'), 'ミナミウオヌマグンユザワマチ');
    });
  });

  group('romanizeWithReference(日本郵便の綴りで長音を決める)', () {
    String? romanize(String kana, String reference) =>
        romanizeWithReference(kana, reference).value;

    test('日本郵便が省いた u・o は長音にする', () {
      expect(romanize('トウキョウト', 'TOKYO TO'), 'TŌKYŌ TO');
      expect(romanize('オオサカフ', 'OSAKA FU'), 'ŌSAKA FU');
      expect(romanize('ホッカイドウ', 'HOKKAIDO'), 'HOKKAIDŌ');
      expect(romanize('サッポロシチュウオウク', 'SAPPORO SHI CHUO KU'),
          'SAPPORO SHI CHŪŌ KU');
    });

    test('日本郵便が残した u・o は長音にしない', () {
      expect(romanize('コウラ', 'KOURA'), 'KOURA');
    });

    test('オオオ(大岡)は、どの o が長音か決まらないので要確認', () {
      // ŌOKA も OŌKA も、マクロンを外すと OOKA になる。語の切れ目は人が判断する
      final result = romanizeWithReference('オオオカ', 'OOKA');
      expect(result.ok, isFalse);
      expect(result.candidates, containsAll(['ŌOKA', 'OŌKA']));
    });

    test('ii・ei はそのまま', () {
      expect(romanize('ニイガタケン', 'NIIGATA KEN'), 'NIIGATA KEN');
    });

    test('ン(b・m・p の前)は日本郵便の綴りに従う', () {
      expect(romanize('グンマケン', 'GUMMA KEN'), 'GUMMA KEN');
    });

    test('長音の位置が一通りに決まらないときは要確認', () {
      final result = romanizeWithReference('ブンゴオオノシ', 'BUNGOONO SHI');
      expect(result.ok, isFalse);
      expect(result.candidates, containsAll(['BUNGOŌNOSHI', 'BUNGŌONOSHI']));
    });

    test('途中で切れた綴りはカナで補い、要確認にする', () {
      final result = romanizeWithReference(
          'ヒガシシラカワグンヤマツリマチ', 'HIGASHISHIRAKAWA GUN YAMATSURI MACH');
      expect(result.ok, isFalse);
      expect(result.value, 'HIGASHISHIRAKAWA GUN YAMATSURI MACHI');
    });

    test('綴りが合わなければ値を作らない', () {
      expect(romanizeWithReference('トウキョウト', 'KYOTO FU').value, isNull);
    });
  });

  group('toLabelCase', () {
    test('接尾辞はハイフンでつないで小文字にする', () {
      expect(toLabelCase('TŌKYŌ TO'), 'Tōkyō-to');
      expect(toLabelCase('ŌSAKA FU'), 'Ōsaka-fu');
      expect(toLabelCase('HOKKAIDŌ'), 'Hokkaidō');
      expect(toLabelCase('MINAMIUONUMA GUN YUZAWA MACHI'),
          'Minamiuonuma-gun Yuzawa-machi');
      expect(toLabelCase('SAPPORO SHI CHŪŌ KU'), 'Sapporo-shi Chūō-ku');
    });
  });

  test('toLargeKana は小書きを大書きにする', () {
    expect(toLargeKana('ショウナイマチ'), 'シヨウナイマチ');
  });
}
