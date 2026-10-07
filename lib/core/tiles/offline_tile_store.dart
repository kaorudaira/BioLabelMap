import 'dart:io';

import 'package:flutter/painting.dart' show FileImage, ImageProvider;
import 'package:flutter_map/flutter_map.dart';

import '../../domain/tiles/tile_math.dart';
import '../db/database.dart';
import '../gsi/tile_layers.dart';

/// オフライン地図のタイルを置く場所。`<root>/area_<id>/<地図の種類>/<z>/<x>/<y>.<拡張子>`。
///
/// エリアごとにフォルダを分けるので、エリアの削除はフォルダごと消すだけで済み、
/// エリアごとの容量も数えやすい(重なるエリアは重複して持つ)。
class OfflineTileStore {
  OfflineTileStore(this.root);

  final Directory root;

  File fileFor(int areaId, GsiTileLayer layer, TileCoord t) => File(
    '${root.path}/area_$areaId/${layer.id}/${t.z}/${t.x}/${t.y}.${layer.extension}',
  );

  /// 書き込み途中で終了して残った一時ファイル(`.tmp`)を消す。取得を始める前に呼ぶ。
  Future<int> cleanTempFiles(int areaId) async {
    final dir = Directory('${root.path}/area_$areaId');
    if (!await dir.exists()) return 0;
    var removed = 0;
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File && entity.path.endsWith('.tmp')) {
        await entity.delete();
        removed++;
      }
    }
    return removed;
  }

  Future<void> deleteArea(int areaId) async {
    final dir = Directory('${root.path}/area_$areaId');
    if (await dir.exists()) await dir.delete(recursive: true);
  }
}

/// 保存済みのタイルを先に読み、なければ通信で取る。圏外で保存範囲の外なら、読めずに灰色になる。
class OfflineFirstTileProvider extends NetworkTileProvider {
  OfflineFirstTileProvider({required this.store, required this.areas, required this.layer})
    : super(headers: {'User-Agent': 'BioLabelMap'});

  final OfflineTileStore store;
  final List<OfflineArea> areas;
  final GsiTileLayer layer;

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final t = TileCoord(coordinates.z, coordinates.x, coordinates.y);
    for (final a in areas) {
      if (!a.layers.split(',').contains(layer.name)) continue;
      final bounds = GeoBounds(south: a.south, west: a.west, north: a.north, east: a.east);
      if (!coversTile(bounds, a.minZoom, a.maxZoom, t)) continue;
      final file = store.fileFor(a.id, layer, t);
      if (file.existsSync()) return FileImage(file);
    }
    return super.getImage(coordinates, options);
  }
}
