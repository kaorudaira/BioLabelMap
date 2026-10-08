import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/gsi/tile_layers.dart';
import '../../core/tiles/offline_tile_store.dart';
import '../../services/service_providers.dart';

/// 地理院タイルの層。保存済みのオフライン地図があればそれを使い、なければ通信で取る。
/// 保存範囲の外で圏外のときは、タイルが読めず灰色になる(要件定義 S-01)。
class GsiTileLayerWidget extends ConsumerWidget {
  const GsiTileLayerWidget({super.key, required this.layer});

  final GsiTileLayer layer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 保存済みエリアの一覧が読めるまでは、何も描かない。読む前にタイルを要求すると、
    // 保存済みのタイルを使えず、圏外では灰色のまま残る(flutter_map は提供元が変わっても
    // 読み込み済み・失敗済みのタイルを読み直さない)
    final areas = ref.watch(offlineAreasProvider).value;
    if (areas == null) return const SizedBox.shrink();

    return TileLayer(
      // エリアの構成か地図の種類が変わったら、層ごと作り直して、タイルを読み直す。
      // タイル提供元は、層が破棄されるときに flutter_map が片付ける
      key: ValueKey((layer, areas.map((a) => a.id).join(','))),
      urlTemplate: layer.urlTemplate,
      maxNativeZoom: layer.maxNativeZoom,
      userAgentPackageName: 'com.example.biolabelmap',
      tileProvider: OfflineFirstTileProvider(
        store: ref.read(offlineTileStoreProvider),
        areas: areas,
        layer: layer,
      ),
      // 読み込みに失敗したタイルを記録する(一部だけ灰色のままになる不具合の切り分け用)
      errorTileCallback: (tile, error, stackTrace) => debugPrint('タイル読み込み失敗 ${tile.coordinates}: $error'),
    );
  }
}
