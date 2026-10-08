import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../app/theme.dart';
import '../../core/db/database.dart';
import '../../core/gsi/tile_layers.dart';
import '../../core/location/location_service.dart';
import '../../services/map_query_service.dart';
import '../../services/service_providers.dart';
import '../record/record_form.dart';
import 'offline_tile_layer.dart';
import 'place_search_sheet.dart';
import '../record/record_screen.dart';

/// 精度の警告しきい値(要件定義 F-06)。
const _accuracyWarningMeters = 30.0;

/// この距離より近くに過去の地点があれば、「この地点に追加」を選べるようにする。
const _nearbyMeters = 30.0;

/// 地図(ホーム)画面(要件定義 S-01)。
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final _map = MapController();
  var _layer = GsiTileLayer.standard;

  /// 地図の回転角(度)。0 が北向き。
  var _rotation = 0.0;

  /// 地図のズームレベル(整数に丸めて表示する)。
  var _zoom = 5;

  /// 二本指での回転を許すか。既定は北固定(野外で向きを見失わないため)。
  var _rotationEnabled = false;

  /// 地図の長押しで立てた仮ピン。
  LatLng? _tempPin;

  /// 最初の測位で、現在地に地図を移したか。
  var _centered = false;

  /// 現在地に地図が追従しているか。追従中は、現在地(精度つき)で記録する。
  /// 地図を指で動かすと外れ、十字の中央(手動の位置)で記録する。
  var _following = true;

  static const _japan = LatLng(36.2, 138.25);

  @override
  Widget build(BuildContext context) {
    // 最初に位置が取れたら、現在地に地図を移す
    ref.listen(positionProvider, (previous, next) {
      final p = next.value;
      if (p == null) return;
      if (!_centered) {
        _centered = true;
        _map.move(LatLng(p.latitude, p.longitude), 15);
      } else if (_following) {
        _map.move(LatLng(p.latitude, p.longitude), _map.camera.zoom);
      }
    });

    final position = ref.watch(positionProvider);
    final pins = ref.watch(localityPinsProvider).value ?? const <LocalityPin>[];
    final current = position.value;

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: _japan,
              initialZoom: 5,
              maxZoom: 20,
              interactionOptions: InteractionOptions(
                flags: _rotationEnabled
                    ? InteractiveFlag.all
                    : InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onPositionChanged: (camera, hasGesture) {
                // 指で動かしたら、現在地への追従を外す
                if (hasGesture && _following) setState(() => _following = false);
                if (camera.zoom.round() != _zoom) setState(() => _zoom = camera.zoom.round());
                // 回転の有無が変わったときだけ描き直す(「北に戻す」ボタンの出し入れ)
                if (camera.rotation != _rotation) setState(() => _rotation = camera.rotation);
              },
              onLongPress: (_, point) => setState(() => _tempPin = point),
              onTap: (_, _) => setState(() => _tempPin = null),
            ),
            children: [
              GsiTileLayerWidget(layer: _layer),
              if (current != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: LatLng(current.latitude, current.longitude),
                      radius: current.accuracy,
                      useRadiusInMeter: true,
                      color: BlockColors.location.withValues(alpha: 0.15),
                      borderColor: BlockColors.location.withValues(alpha: 0.5),
                      borderStrokeWidth: 1,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  // 現在地は過去のピンの下に描く(ピンの件数が隠れないように)
                  if (current != null)
                    Marker(
                      point: LatLng(current.latitude, current.longitude),
                      width: 22,
                      height: 22,
                      child: const _CurrentLocationDot(),
                    ),
                  for (final pin in pins)
                    Marker(
                      point: LatLng(pin.latitude, pin.longitude),
                      width: 40,
                      height: 40,
                      child: _PinMarker(pin: pin, onTap: () => _showPin(pin)),
                    ),
                  if (_tempPin case final p?)
                    Marker(
                      point: p,
                      width: 44,
                      height: 44,
                      alignment: Alignment.topCenter,
                      child: const Icon(Icons.location_pin, size: 44, color: Colors.red),
                    ),
                ],
              ),
            ],
          ),
          // 画面中央の十字。「記録」ボタンは、追従を外しているとき、この中央の位置で記録する
          const IgnorePointer(child: Center(child: _Crosshair())),
          SafeArea(child: _topBar(position)),
          Positioned(left: 0, right: 0, bottom: 0, child: SafeArea(child: _bottomBar(current))),
        ],
      ),
    );
  }

  // ---- 上部: GPS精度、地図の切り替え、補完待ち、下書き ----

  Widget _topBar(AsyncValue<Position> position) {
    final pending = ref.watch(pendingLocalityCountProvider).value ?? 0;
    final drafts = ref.watch(draftsProvider).value ?? const <Draft>[];

    // AsyncValue は「読み込み中・値・エラー」のどれか。switch で場合分けする
    final (String label, Color color) = switch (position) {
      AsyncData(:final value) when value.accuracy > _accuracyWarningMeters =>
        ('±${value.accuracy.round()}m', warningColor),
      AsyncData(:final value) => ('±${value.accuracy.round()}m', BlockColors.location),
      AsyncError(:final error) => (error is LocationUnavailableException ? error.message : '位置情報なし', Colors.grey),
      _ => ('測位中…', Colors.grey),
    };
    // ↑ `final (String label, Color color) = ...` はレコードの分割代入(Java にはない)

    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Badge(
                text: label,
                color: color,
                icon: Icons.gps_fixed,
                // 位置が取れないときは、タップで取り直す
                onTap: position.hasError ? () => ref.invalidate(positionProvider) : null,
              ),
              const SizedBox(height: 6),
              // 地図のズームレベル(地理院タイルの Z)
              _Badge(text: 'Z$_zoom', color: Colors.black87, icon: Icons.zoom_in),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _Badge(text: '地名検索', color: Colors.black87, icon: Icons.search, onTap: _searchPlace),
              const SizedBox(height: 6),
              _Badge(
                text: _layer.label,
                color: Colors.black87,
                icon: Icons.layers,
                onTap: _chooseLayer,
              ),
              const SizedBox(height: 6),
              _CompassButton(
                rotationDegrees: _rotation,
                rotationEnabled: _rotationEnabled,
                onTap: _toggleRotation,
              ),
              if (pending > 0) ...[
                const SizedBox(height: 6),
                _Badge(text: '補完待ち $pending件', color: warningColor, icon: Icons.sync, onTap: _enrichNow),
              ],
              if (drafts.isNotEmpty) ...[
                const SizedBox(height: 6),
                _Badge(
                  text: '下書き ${drafts.length}件',
                  color: BlockColors.specimen,
                  icon: Icons.edit_note,
                  onTap: () => _showDrafts(drafts),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// 地名を検索して、選んだ場所へ地図を移す。追従は外れるので、「記録」は十字の中央になる。
  Future<void> _searchPlace() async {
    final hit = await showPlaceSearch(context);
    if (hit == null || !mounted) return;
    setState(() {
      _following = false;
      _tempPin = null;
    });
    _map.move(LatLng(hit.latitude, hit.longitude), 15);
  }

  /// 回転できるモードと、北固定のモードを切り替える。北固定にするときは北向きに戻す。
  void _toggleRotation() {
    setState(() => _rotationEnabled = !_rotationEnabled);
    if (!_rotationEnabled) _map.rotate(0);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(_rotationEnabled ? '地図の回転: オン(二本指で回せます)' : '地図の回転: オフ(北を上に固定)'),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  Future<void> _chooseLayer() async {
    final chosen = await showModalBottomSheet<GsiTileLayer>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final layer in GsiTileLayer.values)
              ListTile(
                title: Text(layer.label),
                trailing: layer == _layer ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(context, layer),
              ),
          ],
        ),
      ),
    );
    if (chosen != null) setState(() => _layer = chosen);
  }

  Future<void> _enrichNow() async {
    final summary = await ref.read(enrichmentSchedulerProvider).trigger();
    if (!mounted) return;
    final message = summary.failed > 0
        ? '通信できませんでした。あとで自動で再試行します'
        : '補完しました(取得 ${summary.fetched}件、取得不可 ${summary.unavailable}件)';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showDrafts(List<Draft> drafts) async {
    final chosen = await showModalBottomSheet<Draft>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(title: Text('下書き', style: TextStyle(fontWeight: FontWeight.bold))),
            for (final d in drafts)
              ListTile(
                leading: const Icon(Icons.edit_note),
                title: Text(_draftSummary(d)),
                subtitle: Text('保存: ${_formatTime(d.updatedAt)}'),
                onTap: () => Navigator.pop(context, d),
              ),
          ],
        ),
      ),
    );
    if (chosen == null || !mounted) return;
    final form = RecordForm.fromJson(jsonDecode(chosen.formJson) as Map<String, Object?>);
    context.push('/record', extra: RecordArgs(form, draftId: chosen.id));
  }

  String _draftSummary(Draft d) {
    final form = RecordForm.fromJson(jsonDecode(d.formJson) as Map<String, Object?>);
    final place = [form.place?.municipalityJa, form.place?.localityJa].nonNulls.join();
    return '${form.startDate.month}/${form.startDate.day} ${form.samplingMethod.nameJa}'
        '${place.isEmpty ? '' : '  $place'}';
  }

  // ---- 下部: メニュー、記録ボタン、現在地に戻る、出典 ----

  Widget _bottomBar(Position? current) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_tempPin case final p?)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    const Expanded(child: Text('長押しした位置')),
                    TextButton(onPressed: () => setState(() => _tempPin = null), child: const Text('取消')),
                    FilledButton(
                      onPressed: () {
                        setState(() => _tempPin = null);
                        // 地図で指した位置は、精度の代わりに「手動」と記録する
                        _startRecord(p.latitude, p.longitude, accuracy: null, manual: true);
                      },
                      child: const Text('ここで記録'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FloatingActionButton(
                heroTag: 'menu',
                onPressed: _showMenu,
                child: const Icon(Icons.menu),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 64,
                  child: FilledButton.icon(
                    onPressed: () => _recordHere(current),
                    icon: const Icon(Icons.add_location_alt, size: 28),
                    label: const Text('記録', style: TextStyle(fontSize: 22)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FloatingActionButton(
                heroTag: 'locate',
                onPressed: current == null
                    ? null
                    : () {
                        setState(() => _following = true);
                        _map.move(LatLng(current.latitude, current.longitude), 16);
                      },
                child: const Icon(Icons.my_location),
              ),
            ],
          ),
        ),
        // 出典は常時表示する(地理院タイルの利用規約)
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(left: 8, bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            color: Colors.white.withValues(alpha: 0.8),
            child: const Text(gsiAttribution, style: TextStyle(fontSize: 11)),
          ),
        ),
      ],
    );
  }

  Future<void> _showMenu() async {
    final route = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.list_alt),
              title: const Text('標本一覧'),
              onTap: () => Navigator.pop(context, '/specimens'),
            ),
            ListTile(
              leading: const Icon(Icons.print),
              title: const Text('ラベル出力'),
              onTap: () => Navigator.pop(context, '/labels'),
            ),
            ListTile(
              leading: const Icon(Icons.download_for_offline),
              title: const Text('オフライン地図'),
              onTap: () => Navigator.pop(context, '/offline'),
            ),
            ListTile(
              leading: const Icon(Icons.backup),
              title: const Text('バックアップ'),
              onTap: () => Navigator.pop(context, '/backup'),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('設定'),
              onTap: () => Navigator.pop(context, '/settings'),
            ),
          ],
        ),
      ),
    );
    if (route != null && mounted) context.push(route);
  }

  /// 「記録」ボタン。現在地に追従しているときは現在地(精度つき)で、
  /// 地図を動かしたあとは十字の中央(手動の位置)で、記録画面を開く。
  Future<void> _recordHere(Position? current) async {
    if (!_following) {
      final center = _map.camera.center;
      _startRecord(center.latitude, center.longitude, accuracy: null, manual: true);
      return;
    }
    if (current == null) {
      // 位置が未確定のまま記録するときは、確認を出す(地図の中心で記録する)
      final center = _map.camera.center;
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('位置が未確定です'),
          content: const Text('地図の中心の位置で記録しますか?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('やめる')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('記録する')),
          ],
        ),
      );
      if (ok == true) _startRecord(center.latitude, center.longitude, accuracy: null, manual: true);
      return;
    }
    _startRecord(current.latitude, current.longitude, accuracy: current.accuracy, manual: false);
  }

  /// 近くに過去の地点があれば「この地点に追加」か「新しい地点」かを選んでから、記録画面を開く。
  Future<void> _startRecord(double lat, double lon, {required double? accuracy, required bool manual}) async {
    final pins = ref.read(localityPinsProvider).value ?? const <LocalityPin>[];
    const distance = Distance();
    final here = LatLng(lat, lon);
    LocalityPin? nearest;
    var nearestMeters = double.infinity;
    for (final pin in pins) {
      final m = distance(here, LatLng(pin.latitude, pin.longitude));
      if (m < nearestMeters) {
        nearestMeters = m;
        nearest = pin;
      }
    }

    int? existingId;
    if (nearest != null && nearestMeters <= _nearbyMeters) {
      final choice = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('近くに過去の地点があります'),
          content: Text(
            '${nearestMeters < 5 ? 'ほぼ同じ位置' : '約${nearestMeters.round()} m 先'}に、'
            '標本 ${nearest!.specimenCount}件の地点があります。',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('新しい地点')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('この地点に追加')),
          ],
        ),
      );
      if (choice == null) return;
      if (choice) existingId = nearest.localityId;
    }
    if (!mounted) return;

    final form = existingId != null
        ? RecordForm.at(latitude: nearest!.latitude, longitude: nearest.longitude, existingLocalityId: existingId)
        : RecordForm.at(latitude: lat, longitude: lon, accuracyMeters: accuracy, isManualPosition: manual);
    context.push('/record', extra: RecordArgs(form));
  }

  /// ピンをタップしたとき。地点詳細(S-03)は段階3で作るので、いまは件数と「この地点で追加」だけ。
  Future<void> _showPin(LocalityPin pin) async {
    final add = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('標本 ${pin.specimenCount}件', style: Theme.of(context).textTheme.titleLarge),
              if (pin.unidentifiedCount > 0) Text('うち未同定 ${pin.unidentifiedCount}件'),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.add),
                label: const Text('この地点で追加'),
              ),
            ],
          ),
        ),
      ),
    );
    if (add == true && mounted) {
      context.push(
        '/record',
        extra: RecordArgs(RecordForm.at(
          latitude: pin.latitude,
          longitude: pin.longitude,
          existingLocalityId: pin.localityId,
        )),
      );
    }
  }

  static String _formatTime(DateTime t) =>
      '${t.month}/${t.day} ${t.hour}:${t.minute.toString().padLeft(2, '0')}';
}

/// 過去の採集地点のピン。件数を表示し、未同定を含む地点は色を変える。
class _PinMarker extends StatelessWidget {
  const _PinMarker({required this.pin, required this.onTap});

  final LocalityPin pin;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = pin.unidentifiedCount > 0 ? BlockColors.collecting : BlockColors.specimen;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [BoxShadow(blurRadius: 3, color: Colors.black26)],
        ),
        alignment: Alignment.center,
        child: Text(
          '${pin.specimenCount}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

/// 地図の中央の十字。白い縁を付けて、どの地図の上でも見えるようにする。
class _Crosshair extends StatelessWidget {
  const _Crosshair();

  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 36,
    height: 36,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Icon(Icons.add, size: 36, color: Colors.white),
        Icon(Icons.add, size: 30, color: Colors.black87),
      ],
    ),
  );
}

class _CurrentLocationDot extends StatelessWidget {
  const _CurrentLocationDot();

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: BlockColors.location,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 3),
      boxShadow: const [BoxShadow(blurRadius: 3, color: Colors.black38)],
    ),
  );
}

/// 地図の上に重ねる小さな表示(GPS精度、補完待ちなど)。
/// コンパス形のボタン。針は地図の回転に合わせて回り、赤い側が北。
/// タップで、回転できるモードと北固定のモードを切り替える(北固定のときは鍵を重ねる)。
class _CompassButton extends StatelessWidget {
  const _CompassButton({
    required this.rotationDegrees,
    required this.rotationEnabled,
    required this.onTap,
  });

  final double rotationDegrees;
  final bool rotationEnabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = rotationEnabled ? BlockColors.location : Colors.black54;
    return Semantics(
      button: true,
      label: rotationEnabled ? '地図の回転: オン。タップで北固定にする' : '地図の回転: オフ。タップで回転できるようにする',
      child: Material(
        color: Colors.white,
        elevation: 2,
        shape: CircleBorder(side: BorderSide(color: color, width: rotationEnabled ? 2 : 1)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.rotate(
                  angle: rotationDegrees * math.pi / 180,
                  child: CustomPaint(size: const Size(26, 26), painter: _NeedlePainter()),
                ),
                if (!rotationEnabled)
                  const Positioned(right: 4, bottom: 4, child: Icon(Icons.lock, size: 13, color: Colors.black54)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// コンパスの針。上が北(赤)、下が南(灰)。
class _NeedlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final w = size.width * 0.2;
    final h = size.height / 2;
    canvas.drawPath(
      ui.Path()
        ..moveTo(c.dx, c.dy - h)
        ..lineTo(c.dx + w, c.dy)
        ..lineTo(c.dx - w, c.dy)
        ..close(),
      Paint()..color = Colors.red.shade700,
    );
    canvas.drawPath(
      ui.Path()
        ..moveTo(c.dx, c.dy + h)
        ..lineTo(c.dx + w, c.dy)
        ..lineTo(c.dx - w, c.dy)
        ..close(),
      Paint()..color = Colors.grey.shade500,
    );
  }

  @override
  bool shouldRepaint(_NeedlePainter oldDelegate) => false;
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color, required this.icon, this.onTap});

  final String text;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 2,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
