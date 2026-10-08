import 'dart:async';
import 'dart:ui' as ui;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../app/theme.dart';
import '../../core/gsi/tile_layers.dart';
import '../../core/location/location_service.dart';
import '../../domain/tiles/offline_plan.dart';
import '../../domain/tiles/tile_math.dart';
import '../../services/offline_map_service.dart';
import '../../services/service_providers.dart';
import '../map/offline_tile_layer.dart';

/// 新しいエリアの保存(要件定義 S-08)。
///
/// 地図を動かし、画面中央の枠の角をドラッグして範囲を決める。地図の種類・最大ズームを選ぶと、
/// 枚数と容量の見積もりが変わる。
class OfflineAreaNewScreen extends ConsumerStatefulWidget {
  const OfflineAreaNewScreen({super.key});

  @override
  ConsumerState<OfflineAreaNewScreen> createState() =>
      _OfflineAreaNewScreenState();
}

class _OfflineAreaNewScreenState extends ConsumerState<OfflineAreaNewScreen> {
  static const _margin = 32.0;
  static const _minFrame = 96.0;
  static const _minSliderZoom = 10;

  final _map = MapController();
  final _name = TextEditingController();
  var _nameEdited = false;
  Timer? _nameTimer;

  var _layers = {GsiTileLayer.standard};
  var _maxZoom = offlineDefaultMaxZoom;

  /// 枠の余白(地図の四辺から)。左上と右下の角をドラッグして変える。
  var _left = _margin;
  var _top = _margin;
  var _right = _margin;
  var _bottom = _margin;
  var _mapSize = Size.zero;
  GeoBounds? _bounds;
  var _saving = false;

  @override
  void dispose() {
    _nameTimer?.cancel();
    _name.dispose();
    super.dispose();
  }

  int get _sliderMax =>
      maxZoomFor(_layers.isEmpty ? {GsiTileLayer.standard} : _layers)
          .clamp(_minSliderZoom, 20);

  Rect get _frame => Rect.fromLTRB(
    _left,
    _top,
    _mapSize.width - _right,
    _mapSize.height - _bottom,
  );

  /// 枠の四隅を、地図の緯度経度にして範囲を求める。
  void _recompute() {
    if (_mapSize.isEmpty) return;
    final MapCamera camera;
    try {
      camera = _map.camera;
    } catch (_) {
      return; // 地図がまだ描かれていない
    }
    final f = _frame;
    final nw = camera.screenOffsetToLatLng(f.topLeft);
    final se = camera.screenOffsetToLatLng(f.bottomRight);
    final bounds = GeoBounds(
      south: se.latitude,
      west: nw.longitude,
      north: nw.latitude,
      east: se.longitude,
    );
    if (!mounted) return;
    setState(() => _bounds = bounds);
    _scheduleName(
      LatLng(
        (nw.latitude + se.latitude) / 2,
        (nw.longitude + se.longitude) / 2,
      ),
    );
  }

  /// 地名から名前を付ける(例: 魚沼市周辺)。編集済みなら触らない。圏外なら付けない。
  void _scheduleName(LatLng center) {
    if (_nameEdited) return;
    _nameTimer?.cancel();
    _nameTimer = Timer(const Duration(milliseconds: 800), () async {
      final result = await ref
          .read(localityLookupServiceProvider)
          .lookup(center.latitude, center.longitude);
      final municipality = result.place?.municipalityJa;
      if (!mounted || _nameEdited || municipality == null) return;
      _name.text = '$municipality周辺';
    });
  }

  void _goToCurrent() {
    final p = ref.read(positionProvider).value;
    if (p == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('現在地が取得できていません')));
      return;
    }
    setState(() {
      _left = _top = _right = _bottom = _margin;
    });
    _map.move(LatLng(p.latitude, p.longitude), 13);
    WidgetsBinding.instance.addPostFrameCallback((_) => _recompute());
  }

  Future<void> _save() async {
    final bounds = _bounds;
    if (bounds == null) return;
    // Wi-Fi でないときは、確認を出す(モバイル回線の通信量が大きくなるため)
    final connection = await Connectivity().checkConnectivity();
    final onWifi =
        connection.contains(ConnectivityResult.wifi) ||
        connection.contains(ConnectivityResult.ethernet);
    if (!onWifi && mounted) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Wi-Fi に接続していません'),
          content: const Text('モバイル回線で保存すると、通信量が大きくなります。保存しますか?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('やめる'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('保存する'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    if (!mounted) return;

    setState(() => _saving = true);
    final service = ref.read(offlineMapServiceProvider);
    try {
      final id = await service.create(
        name: _name.text,
        bounds: bounds,
        layers: _layers,
        maxZoom: _maxZoom.clamp(_minSliderZoom, _sliderMax),
      );
      // 画面を閉じても取得は続く(進み具合は一覧で見る)
      unawaited(service.download(id));
      if (mounted) context.pop();
    } on OfflineMapException catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bounds = _bounds;
    final maxZoom = _maxZoom.clamp(_minSliderZoom, _sliderMax);
    final estimate = bounds != null && bounds.isValid && _layers.isNotEmpty
        ? estimateOffline(bounds, _layers, maxZoom)
        : null;
    final tooBig = estimate?.exceedsAreaLimit() ?? false;
    final start = ref.read(positionProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('新しいエリアを保存')),
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = Size(constraints.maxWidth, constraints.maxHeight);
                if (size != _mapSize) {
                  _mapSize = size;
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => _recompute(),
                  );
                }
                final f = _frame;
                return Stack(
                  children: [
                    FlutterMap(
                      mapController: _map,
                      options: MapOptions(
                        initialCenter: start == null
                            ? const LatLng(36.2, 138.25)
                            : LatLng(start.latitude, start.longitude),
                        initialZoom: start == null ? 6 : 13,
                        maxZoom: 20,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                        ),
                        onMapReady: () => WidgetsBinding.instance
                            .addPostFrameCallback((_) => _recompute()),
                        onPositionChanged: (_, _) => WidgetsBinding.instance
                            .addPostFrameCallback((_) => _recompute()),
                      ),
                      children: [
                        GsiTileLayerWidget(
                          layer: _layers.firstOrNull ?? GsiTileLayer.standard,
                        ),
                      ],
                    ),
                    // 枠(外側を暗くする)。タッチは地図に通す
                    IgnorePointer(
                      child: CustomPaint(
                        size: size,
                        painter: _FramePainter(
                          f,
                          tooBig ? Colors.red : BlockColors.location,
                        ),
                      ),
                    ),
                    _handle(f.topLeft, (d) {
                      setState(() {
                        _left = (_left + d.dx).clamp(
                          0,
                          _mapSize.width - _right - _minFrame,
                        );
                        _top = (_top + d.dy).clamp(
                          0,
                          _mapSize.height - _bottom - _minFrame,
                        );
                      });
                    }),
                    _handle(f.bottomRight, (d) {
                      setState(() {
                        _right = (_right - d.dx).clamp(
                          0,
                          _mapSize.width - _left - _minFrame,
                        );
                        _bottom = (_bottom - d.dy).clamp(
                          0,
                          _mapSize.height - _top - _minFrame,
                        );
                      });
                    }),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: FilledButton.tonalIcon(
                        onPressed: _goToCurrent,
                        icon: const Icon(Icons.my_location, size: 18),
                        label: const Text('現在地の周辺'),
                      ),
                    ),
                    const Positioned(
                      left: 8,
                      bottom: 4,
                      child: ColoredBox(
                        color: Color(0xCCFFFFFF),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          child: Text(
                            gsiAttribution,
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          _panel(estimate, tooBig, maxZoom),
        ],
      ),
    );
  }

  /// 枠の角のつまみ。ドラッグで枠を広げ縮めする。
  Widget _handle(Offset center, void Function(Offset delta) onDrag) =>
      Positioned(
        left: center.dx - 24,
        top: center.dy - 24,
        child: GestureDetector(
          onPanUpdate: (d) {
            onDrag(d.delta);
            _recompute();
          },
          child: Container(
            width: 48,
            height: 48,
            color: Colors.transparent,
            alignment: Alignment.center,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: BlockColors.location, width: 3),
              ),
            ),
          ),
        ),
      );

  Widget _panel(OfflineEstimate? estimate, bool tooBig, int maxZoom) {
    return Material(
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                children: [
                  for (final layer in GsiTileLayer.values)
                    FilterChip(
                      label: Text(layer.label),
                      selected: _layers.contains(layer),
                      onSelected: (on) => setState(() {
                        _layers = {..._layers};
                        on ? _layers.add(layer) : _layers.remove(layer);
                      }),
                    ),
                ],
              ),
              Row(
                children: [
                  Text('最大ズーム $maxZoom'),
                  Expanded(
                    child: Slider(
                      value: maxZoom.toDouble(),
                      min: _minSliderZoom.toDouble(),
                      max: _sliderMax.toDouble(),
                      divisions: (_sliderMax - _minSliderZoom).clamp(1, 20),
                      onChanged: (v) => setState(() => _maxZoom = v.round()),
                    ),
                  ),
                ],
              ),
              Text(
                estimate == null
                    ? '範囲を決めてください'
                    : '約${estimate.tileCount}枚、約${formatBytes(estimate.bytes)}'
                          '${tooBig ? '(1エリアの上限 ${formatBytes(offlineAreaLimitBytes)} を超えています。範囲を狭めるか、ズームを下げてください)' : ''}',
                style: TextStyle(
                  color: tooBig ? Colors.red : null,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _name,
                      decoration: const InputDecoration(
                        labelText: '名前',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (_) => _nameEdited = true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: estimate == null || tooBig || _saving
                        ? null
                        : _save,
                    child: const Text('保存'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 保存範囲の枠。外側を薄く暗くして、枠線を引く。
class _FramePainter extends CustomPainter {
  _FramePainter(this.frame, this.color);

  final Rect frame;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final outside = ui.Path()
      ..fillType = ui.PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRect(frame);
    canvas.drawPath(
      outside,
      Paint()..color = Colors.black.withValues(alpha: 0.25),
    );
    canvas.drawRect(
      frame,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(_FramePainter old) =>
      old.frame != frame || old.color != color;
}
