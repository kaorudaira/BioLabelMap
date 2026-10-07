import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/gsi/tile_layers.dart';
import '../map/offline_tile_layer.dart';

/// 位置の補正(要件定義 F-06・S-02)。地図を動かし、画面中央の十字を合わせて決める。
/// 決めた位置を返す。やめたときは null。
class PositionPickerScreen extends StatefulWidget {
  const PositionPickerScreen({super.key, required this.initial});

  final LatLng initial;

  @override
  State<PositionPickerScreen> createState() => _PositionPickerScreenState();
}

class _PositionPickerScreenState extends State<PositionPickerScreen> {
  late LatLng _center = widget.initial;
  var _layer = GsiTileLayer.standard;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('位置を補正'),
        actions: [
          PopupMenuButton<GsiTileLayer>(
            icon: const Icon(Icons.layers),
            tooltip: '地図の種類',
            onSelected: (v) => setState(() => _layer = v),
            itemBuilder: (_) => [
              for (final l in GsiTileLayer.values) PopupMenuItem(value: l, child: Text(l.label)),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: widget.initial,
              initialZoom: 17,
              maxZoom: 20,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onPositionChanged: (camera, _) => _center = camera.center,
            ),
            children: [
              GsiTileLayerWidget(layer: _layer),
            ],
          ),
          const IgnorePointer(child: Center(child: Icon(Icons.add, size: 40, color: Colors.red))),
          Align(
            alignment: Alignment.bottomLeft,
            child: Container(
              margin: const EdgeInsets.only(left: 8, bottom: 80),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              color: Colors.white.withValues(alpha: 0.8),
              child: const Text(gsiAttribution, style: TextStyle(fontSize: 11)),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('やめる')),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, _center),
                  child: const Text('この位置にする'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
