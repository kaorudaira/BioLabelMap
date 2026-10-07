import '../../core/gsi/tile_layers.dart';
import 'tile_math.dart';

/// 保存するズームの下限。これより広い範囲は保存しない(枚数を抑える)。
const offlineMinZoom = 6;

/// 保存するときの最大ズームの既定(要件定義 第7章)。
const offlineDefaultMaxZoom = 16;

/// 1エリアの容量の上限(バイト)。設定で変えられるのは段階4。
const offlineAreaLimitBytes = 200 * 1024 * 1024;

/// 全体の容量の上限(バイト)。設定で変えられるのは段階4。
const offlineTotalLimitBytes = 1024 * 1024 * 1024;

/// 保存から、再取得を促すまでの日数(半年)。
const offlineStaleDays = 183;

/// 地図の種類ごとの、1タイルの平均サイズ(バイト)の目安。実測ではなく概算。
/// 標準地図は要件定義の「1タイル約20KB」。写真は大きいので多めに見る。
int estimatedTileBytes(GsiTileLayer layer) => switch (layer) {
  GsiTileLayer.standard => 20 * 1024,
  GsiTileLayer.pale => 15 * 1024,
  GsiTileLayer.photo => 50 * 1024,
  GsiTileLayer.hillshade => 25 * 1024,
  GsiTileLayer.relief => 20 * 1024,
};

/// 地図の種類ごとの、保存できる最大ズーム(上限は地図ごとに決まる)。
int maxZoomFor(Iterable<GsiTileLayer> layers) =>
    layers.map((l) => l.maxNativeZoom).reduce((a, b) => a < b ? a : b);

/// 保存の見積もり。
class OfflineEstimate {
  const OfflineEstimate({required this.tileCount, required this.bytes});

  /// 全ての地図の種類を合わせた枚数。
  final int tileCount;
  final int bytes;

  bool exceedsAreaLimit([int limit = offlineAreaLimitBytes]) => bytes > limit;
}

/// 範囲・地図の種類・最大ズームから、枚数と容量を見積もる。
///
/// 地図の種類ごとに最大ズームの上限が違うので、種類ごとに上限で切って数える。
OfflineEstimate estimateOffline(GeoBounds bounds, Set<GsiTileLayer> layers, int maxZoom) {
  var tiles = 0;
  var bytes = 0;
  for (final layer in layers) {
    final top = maxZoom < layer.maxNativeZoom ? maxZoom : layer.maxNativeZoom;
    final n = countTiles(bounds, offlineMinZoom, top);
    tiles += n;
    bytes += n * estimatedTileBytes(layer);
  }
  return OfflineEstimate(tileCount: tiles, bytes: bytes);
}

/// 容量の表示(例: 320MB、1.2GB、800KB)。
String formatBytes(int bytes) {
  const kb = 1024;
  const mb = 1024 * 1024;
  const gb = 1024 * 1024 * 1024;
  if (bytes >= gb) return '${(bytes / gb).toStringAsFixed(1)}GB';
  if (bytes >= mb) return '${(bytes / mb).round()}MB';
  return '${(bytes / kb).round()}KB';
}

/// 保存するタイル(地図の種類+タイル番号)を、1つずつ返す。数は [estimateOffline] の枚数と一致する。
Iterable<(GsiTileLayer, TileCoord)> tilesToDownload(
  GeoBounds bounds,
  Set<GsiTileLayer> layers,
  int maxZoom,
) sync* {
  for (final layer in layers) {
    final top = maxZoom < layer.maxNativeZoom ? maxZoom : layer.maxNativeZoom;
    for (final t in tilesIn(bounds, offlineMinZoom, top)) {
      yield (layer, t);
    }
  }
}
