import 'dart:ui';

import 'package:biolabelmap/features/map/callout_placement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const screen = Size(360, 800);

  CalloutPlacement place(Offset pin, {double topInset = 80, double bottomInset = 220}) =>
      placeCallout(pin: pin, screen: screen, width: 220, height: 150, topInset: topInset, bottomInset: bottomInset);

  group('吹き出しの横', () {
    test('画面の中ほどのピンは、ずらさない(ピンの真上)', () {
      expect(place(const Offset(180, 400)).shiftX, 0);
    });

    test('左の端のピンは、吹き出しの左端が画面の左端(余白8)に合うまで、右へずらす', () {
      // ピン x=10:ふつうは 左端 = 10-110 = -100 → 8 にそろえる(右へ108)
      expect(place(const Offset(10, 400)).shiftX, 108);
      // ずらしたあとの吹き出しの左端は、余白の位置
      expect(10 - 110 + place(const Offset(10, 400)).shiftX, 8);
    });

    test('右の端のピンは、吹き出しの右端が画面の右端(余白8)に合うまで、左へずらす', () {
      // ピン x=350:右端 = 350+110 = 460 → 352 にそろえる(左へ108)
      expect(place(const Offset(350, 400)).shiftX, -108);
    });

    test('端から少し離れたピンは、必要な分だけずらす', () {
      // 吹き出しの左端が、余白の内側(8)に入る境目: ピン x=118 → ぴったり。x=100 なら右へ18
      expect(place(const Offset(118, 400)).shiftX, 0);
      expect(place(const Offset(100, 400)).shiftX, 18);
      expect(place(const Offset(242, 400)).shiftX, 0);
      expect(place(const Offset(260, 400)).shiftX, -18);
    });

    test('ずらしても、吹き出しはどのピンでも画面の中に収まる', () {
      for (var x = 0.0; x <= 360; x += 5) {
        final left = x - 110 + place(Offset(x, 400)).shiftX;
        expect(left, greaterThanOrEqualTo(8 - 1e-9), reason: 'x=$x');
        expect(left + 220, lessThanOrEqualTo(360 - 8 + 1e-9), reason: 'x=$x');
      }
    });

    test('画面が吹き出しより狭いときは、中央にそろえる', () {
      final p = placeCallout(pin: const Offset(10, 400), screen: const Size(200, 800), width: 220);
      expect(10 - 110 + p.shiftX, (200 - 220) / 2);
    });
  });

  group('吹き出しの縦', () {
    test('上に収まるなら、ピンの上', () {
      expect(place(const Offset(180, 400)).below, isFalse);
    });

    test('画面の上の端(操作ボタンの下に収まらない)のピンは、ピンの下', () {
      expect(place(const Offset(180, 100)).below, isTrue);
      // 収まる境目:上の余白 = pin.dy - topInset - margin ≥ 高さ150 + 先8 + ピン22 = 180 → pin.dy ≥ 268
      expect(place(const Offset(180, 268)).below, isFalse);
      expect(place(const Offset(180, 267)).below, isTrue);
    });

    test('上にも下にも収まらないときは、広いほう', () {
      final small = Size(360, 400);
      expect(placeCallout(pin: const Offset(180, 150), screen: small, topInset: 80, bottomInset: 150).below, isTrue);
      expect(placeCallout(pin: const Offset(180, 300), screen: small, topInset: 80, bottomInset: 150).below, isFalse);
    });

    test('左上の角のピンは、右にずらして、下に置く', () {
      final p = place(const Offset(5, 90));
      expect(p.below, isTrue);
      expect(p.shiftX, greaterThan(0));
    });
  });
}
