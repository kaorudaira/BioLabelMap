/// 同一地点の判定キー。緯度経度を小数4桁で切り捨てて一致すれば同じ地点とみなす
/// (要件定義 S-01・第12章)。小数4桁は約10m。ラベルの座標も同じ値で印字する。
///
/// 浮動小数の比較を避けるため、1万倍した整数で持つ。DB の索引にも使う。
class LocalityKey {
  const LocalityKey(this.latE4, this.lonE4);

  factory LocalityKey.fromCoordinates(double latitude, double longitude) =>
      LocalityKey(truncateE4(latitude), truncateE4(longitude));

  final int latE4;
  final int lonE4;

  /// 小数4桁で切り捨て(0 の方向へ)、1万倍した整数にする。36.94479 → 369447。
  ///
  /// `(value * 10000).truncate()` は2進数の誤差で 0.0003 を 2 にしてしまう
  /// (0.0003 * 10000 = 2.9999…)。そのため、Dart が出力する10進の文字列
  /// (元の double に戻る最短の表現)の桁を切り捨てる。
  static int truncateE4(double value) {
    if (!value.isFinite) {
      throw ArgumentError.value(value, 'value', '有限の値が必要です');
    }
    final text = value.abs().toString();
    // 1e-7 のような指数表記になるのは、絶対値が 1e-6 未満のときだけ(座標では 0 になる)
    if (text.contains('e')) return 0;

    final [integer, ...rest] = text.split('.');
    // ↑ リストの分割代入(パターン)。Java にはない書き方で、先頭と残りを一度に取り出す。
    final fraction = (rest.isEmpty ? '' : rest.first).padRight(4, '0');
    final magnitude = int.parse(integer) * 10000 + int.parse(fraction.substring(0, 4));
    return value.isNegative ? -magnitude : magnitude;
  }

  @override
  bool operator ==(Object other) =>
      other is LocalityKey && other.latE4 == latE4 && other.lonE4 == lonE4;

  @override
  int get hashCode => Object.hash(latE4, lonE4);

  @override
  String toString() => 'LocalityKey($latE4, $lonE4)';
}
