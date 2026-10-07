import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../app/theme.dart';
import '../../core/db/database.dart';
import '../../core/gsi/tile_layers.dart';
import '../../domain/tiles/offline_plan.dart';
import '../../services/offline_map_service.dart';
import '../../services/service_providers.dart';
import '../map/offline_tile_layer.dart';

/// オフライン地図の一覧(要件定義 S-08)。
class OfflineMapsScreen extends ConsumerWidget {
  const OfflineMapsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final areas =
        ref.watch(offlineAreasProvider).value ?? const <OfflineArea>[];
    final service = ref.watch(offlineMapServiceProvider);
    final used = areas.fold<int>(0, (sum, a) => sum + a.bytes);

    return Scaffold(
      appBar: AppBar(title: const Text('オフライン地図')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${formatBytes(used)} / ${formatBytes(offlineTotalLimitBytes)}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: (used / offlineTotalLimitBytes).clamp(0, 1).toDouble(),
                ),
              ],
            ),
          ),
          Expanded(
            child: areas.isEmpty
                ? const Center(child: Text('保存したエリアはありません'))
                : ListView(
                    children: [
                      for (final a in areas)
                        _AreaTile(
                          area: a,
                          running: service.isRunning(a.id),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  OfflineAreaDetailScreen(areaId: a.id),
                            ),
                          ),
                          onResume: () => unawaited(service.download(a.id)),
                          onPause: () => service.pause(a.id),
                        ),
                    ],
                  ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                gsiAttribution,
                style: TextStyle(fontSize: 11, color: Colors.black54),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: FilledButton.icon(
            onPressed: () => context.push('/offline/new'),
            icon: const Icon(Icons.add),
            label: const Text('新しいエリアを保存'),
          ),
        ),
      ),
    );
  }
}

class _AreaTile extends StatelessWidget {
  const _AreaTile({
    required this.area,
    required this.running,
    required this.onTap,
    required this.onResume,
    required this.onPause,
  });

  final OfflineArea area;
  final bool running;
  final VoidCallback onTap;
  final VoidCallback onResume;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    final complete = area.status == 'complete';
    final stale = OfflineMapService.isStale(area, DateTime.now());
    final layers = area.layers
        .split(',')
        .map((n) => GsiTileLayer.values.byName(n).label)
        .join('・');
    final date = area.completedAt;

    return ListTile(
      onTap: onTap,
      title: Row(
        children: [
          Flexible(child: Text(area.name, overflow: TextOverflow.ellipsis)),
          if (stale) ...[
            const SizedBox(width: 8),
            const Text(
              '更新',
              style: TextStyle(
                color: warningColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$layers  ズーム${area.maxZoom}まで  ${formatBytes(area.bytes)}'
            '${date == null ? '' : '  ${date.year}/${date.month}/${date.day}'}',
          ),
          if (!complete) ...[
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: area.tileCount == 0
                  ? 0
                  : area.downloadedCount / area.tileCount,
            ),
            Text(
              '${area.downloadedCount} / ${area.tileCount}枚${running ? '' : '(中断中)'}',
            ),
          ],
        ],
      ),
      trailing: complete
          ? null
          : IconButton(
              icon: Icon(running ? Icons.pause : Icons.play_arrow),
              tooltip: running ? '中断' : '再開',
              onPressed: running ? onPause : onResume,
            ),
    );
  }
}

/// エリアの詳細。地図で範囲を確認し、「更新」と「削除」ができる。
class OfflineAreaDetailScreen extends ConsumerWidget {
  const OfflineAreaDetailScreen({super.key, required this.areaId});

  final int areaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final area =
        (ref.watch(offlineAreasProvider).value ?? const <OfflineArea>[])
            .where((a) => a.id == areaId)
            .firstOrNull;
    if (area == null) return Scaffold(appBar: AppBar(), body: const SizedBox());

    final service = ref.read(offlineMapServiceProvider);
    final bounds = LatLngBounds(
      LatLng(area.south, area.west),
      LatLng(area.north, area.east),
    );

    return Scaffold(
      appBar: AppBar(title: Text(area.name)),
      body: FlutterMap(
        options: MapOptions(
          initialCameraFit: CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.all(32),
          ),
          maxZoom: 20,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
          ),
        ),
        children: [
          const GsiTileLayerWidget(layer: GsiTileLayer.standard),
          PolygonLayer(
            polygons: [
              Polygon(
                points: [
                  bounds.northWest,
                  bounds.northEast,
                  bounds.southEast,
                  bounds.southWest,
                ],
                color: BlockColors.location.withValues(alpha: 0.12),
                borderColor: BlockColors.location,
                borderStrokeWidth: 3,
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final ok = await _confirm(
                      context,
                      '${area.name}を削除しますか',
                      '保存した地図(${formatBytes(area.bytes)})を端末から消します。',
                    );
                    if (!ok) return;
                    await service.delete(area.id);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  child: const Text('削除'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () async {
                    final ok = await _confirm(
                      context,
                      '${area.name}を更新しますか',
                      '保存し直します(通信が必要です)。',
                    );
                    if (!ok) return;
                    unawaited(service.refresh(area.id));
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  child: const Text('更新'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _confirm(BuildContext context, String title, String body) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('やめる'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('実行'),
          ),
        ],
      ),
    );
    return ok == true;
  }
}
