import 'dart:math' as math;

/// 地理院タイル(Web メルカトルの XYZ タイル)の計算。要件定義 第7章。

/// Web メルカトルで扱える北緯・南緯の限界。
const _maxLatitude = 85.0511287798;

class TileCoord {
  const TileCoord(this.z, this.x, this.y);

  final int z;
  final int x;
  final int y;

  @override
  bool operator ==(Object other) => other is TileCoord && other.z == z && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(z, x, y);

  @override
  String toString() => '$z/$x/$y';
}

/// 緯度経度の矩形(南西と北東の角)。
class GeoBounds {
  const GeoBounds({required this.south, required this.west, required this.north, required this.east});

  final double south;
  final double west;
  final double north;
  final double east;

  bool get isValid => south < north && west < east;
}

/// 緯度経度を、ズーム [z] のタイル番号にする。範囲の外は端に丸める。
TileCoord tileAt(double latitude, double longitude, int z) {
  final n = 1 << z;
  final lat = latitude.clamp(-_maxLatitude, _maxLatitude);
  final lon = longitude.clamp(-180.0, 180.0);
  final latRad = lat * math.pi / 180;
  final x = ((lon + 180) / 360 * n).floor();
  final y = ((1 - math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi) / 2 * n).floor();
  return TileCoord(z, x.clamp(0, n - 1), y.clamp(0, n - 1));
}

/// 矩形に掛かるタイルの範囲(ズーム [z])。
({int x0, int x1, int y0, int y1}) tileRange(GeoBounds bounds, int z) {
  final nw = tileAt(bounds.north, bounds.west, z);
  final se = tileAt(bounds.south, bounds.east, z);
  return (x0: nw.x, x1: se.x, y0: nw.y, y1: se.y);
}

/// 矩形に掛かるタイルの数(ズーム [minZoom]〜[maxZoom] の合計)。
int countTiles(GeoBounds bounds, int minZoom, int maxZoom) {
  var total = 0;
  for (var z = minZoom; z <= maxZoom; z++) {
    final r = tileRange(bounds, z);
    total += (r.x1 - r.x0 + 1) * (r.y1 - r.y0 + 1);
  }
  return total;
}

/// 矩形に掛かるタイルを、ズームの低い順に1つずつ返す。
Iterable<TileCoord> tilesIn(GeoBounds bounds, int minZoom, int maxZoom) sync* {
  for (var z = minZoom; z <= maxZoom; z++) {
    final r = tileRange(bounds, z);
    for (var x = r.x0; x <= r.x1; x++) {
      for (var y = r.y0; y <= r.y1; y++) {
        yield TileCoord(z, x, y);
      }
    }
  }
}

/// タイル [t] が、保存範囲([bounds]、ズーム [minZoom]〜[maxZoom])に含まれるか。
bool coversTile(GeoBounds bounds, int minZoom, int maxZoom, TileCoord t) {
  if (t.z < minZoom || t.z > maxZoom) return false;
  final r = tileRange(bounds, t.z);
  return t.x >= r.x0 && t.x <= r.x1 && t.y >= r.y0 && t.y <= r.y1;
}
