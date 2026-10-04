/// 同一地点の判定キー。緯度経度を小数4桁で丸めて一致すれば同じ地点とみなす
/// (要件定義 S-01・第12章)。小数4桁は約10m。
///
/// 浮動小数の比較を避けるため、1万倍した整数で持つ。DB の索引にも使う。
class LocalityKey {
  const LocalityKey(this.latE4, this.lonE4);

  factory LocalityKey.fromCoordinates(double latitude, double longitude) =>
      LocalityKey((latitude * 10000).round(), (longitude * 10000).round());

  final int latE4;
  final int lonE4;

  @override
  bool operator ==(Object other) =>
      other is LocalityKey && other.latE4 == latE4 && other.lonE4 == lonE4;

  @override
  int get hashCode => Object.hash(latE4, lonE4);

  @override
  String toString() => 'LocalityKey($latE4, $lonE4)';
}
