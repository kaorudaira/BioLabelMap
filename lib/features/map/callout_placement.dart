import 'dart:ui';

/// 吹き出しを置く位置。ピンの上に、画面の中に収まるように置く。
class CalloutPlacement {
  const CalloutPlacement({required this.shiftX, required this.below});

  /// 吹き出しを、ピンの真上から横にずらす量(右が正)。画面の端のピンで、吹き出しが画面の外に出ないようにする。
  /// 吹き出しの先(三角)は、ずらさず、ピンを指したままにする。
  final double shiftX;

  /// ピンの上に収まらないとき(画面の上の端のピン)は、ピンの下に置く。
  final bool below;

  @override
  bool operator ==(Object other) => other is CalloutPlacement && other.shiftX == shiftX && other.below == below;

  @override
  int get hashCode => Object.hash(shiftX, below);

  @override
  String toString() => 'CalloutPlacement(shiftX: $shiftX, below: $below)';
}

/// 吹き出しの置き場所を決める。
///
/// - [pin]:ピンの、画面上の位置。
/// - [screen]:地図の画面の大きさ。
/// - [width]・[height]:吹き出し(先の三角を含まない)の大きさ。高さは、収まるか調べるための見積もり。
/// - [topInset]:画面の上の、地図の操作ボタンなどが占める高さ。吹き出しは、この下に置く。
/// - [pinRadius]:ピンの大きさの半分。吹き出しは、ピンに重ならないよう、これだけ離す。
/// - [tail]:吹き出しの先の三角の高さ。
CalloutPlacement placeCallout({
  required Offset pin,
  required Size screen,
  double width = 220,
  double height = 150,
  double topInset = 0,
  double bottomInset = 0,
  double margin = 8,
  double pinRadius = 22,
  double tail = 8,
}) {
  // 横:吹き出しの中心をピンに合わせ、画面の左右の端から margin 以上離す
  final idealLeft = pin.dx - width / 2;
  final maxLeft = screen.width - margin - width;
  final left = maxLeft < margin ? (screen.width - width) / 2 : idealLeft.clamp(margin, maxLeft).toDouble();
  final shiftX = left - idealLeft;

  // 縦:上に収まれば上。収まらなければ、下に収まるかで決める(どちらも収まらなければ、広いほう)
  final need = height + tail + pinRadius;
  final above = pin.dy - topInset - margin;
  final below = screen.height - bottomInset - pin.dy - margin;
  final putBelow = above < need && below > above;
  return CalloutPlacement(shiftX: shiftX, below: putBelow);
}

