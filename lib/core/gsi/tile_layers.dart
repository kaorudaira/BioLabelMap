/// 地理院タイルの種類(要件定義 F-01・第7章)。
///
/// 最大ズームは要件定義の目安の値(要確認)。これを超えてズームしたときは、
/// 最大ズームの画像を拡大して表示する(flutter_map の maxNativeZoom)。
enum GsiTileLayer {
  standard('標準地図', 'std', 'png', 18),
  pale('淡色地図', 'pale', 'png', 18),
  photo('写真', 'seamlessphoto', 'jpg', 18),
  hillshade('陰影起伏図', 'hillshademap', 'png', 16),
  relief('色別標高図', 'relief', 'png', 15);

  const GsiTileLayer(this.label, this.id, this.extension, this.maxNativeZoom);

  final String label;
  final String id;
  final String extension;
  final int maxNativeZoom;

  String get urlTemplate =>
      'https://cyberjapandata.gsi.go.jp/xyz/$id/{z}/{x}/{y}.$extension';
}

/// 地図画面に常時表示する出典(地理院タイルの利用規約)。
const gsiAttribution = '出典: 国土地理院(地理院タイル)';
