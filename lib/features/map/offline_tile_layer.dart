import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/gsi/tile_layers.dart';
import '../../core/tiles/offline_tile_store.dart';
import '../../services/service_providers.dart';

/// 地理院タイルの層。保存済みのオフライン地図があればそれを使い、なければ通信で取る。
/// 保存範囲の外で圏外のときは、タイルが読めず灰色になる(要件定義 S-01)。
class GsiTileLayerWidget extends ConsumerStatefulWidget {
  const GsiTileLayerWidget({super.key, required this.layer});

  final GsiTileLayer layer;

  @override
  ConsumerState<GsiTileLayerWidget> createState() => _GsiTileLayerWidgetState();
}

class _GsiTileLayerWidgetState extends ConsumerState<GsiTileLayerWidget> {
  OfflineFirstTileProvider? _provider;
  Object? _providerKey;

  @override
  void dispose() {
    _provider?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final areas = ref.watch(offlineAreasProvider).value ?? const [];
    // 地図の種類かエリアの構成が変わったときだけ作り直す(取得の進み具合では作り直さない)
    final key = (widget.layer, areas.map((a) => a.id).join(','));
    if (_provider == null || _providerKey != key) {
      _provider?.dispose();
      _providerKey = key;
      _provider = OfflineFirstTileProvider(
        store: ref.read(offlineTileStoreProvider),
        areas: areas,
        layer: widget.layer,
      );
    }

    return TileLayer(
      urlTemplate: widget.layer.urlTemplate,
      maxNativeZoom: widget.layer.maxNativeZoom,
      userAgentPackageName: 'com.example.biolabelmap',
      tileProvider: _provider,
      // 読み込みに失敗したタイルを記録する(一部だけ灰色のままになる不具合の切り分け用)
      errorTileCallback: (tile, error, stackTrace) => debugPrint('タイル読み込み失敗 ${tile.coordinates}: $error'),
    );
  }
}
