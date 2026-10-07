import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;

import '../core/db/database.dart';
import '../core/gsi/tile_layers.dart';
import '../core/tiles/offline_tile_store.dart';
import '../domain/tiles/offline_plan.dart';
import '../domain/tiles/tile_math.dart';

/// 保存できない理由(容量の上限など)。メッセージは画面にそのまま出せる。
class OfflineMapException implements Exception {
  OfflineMapException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// オフライン地図の保存・再開・削除(要件定義 第7章・S-08)。
///
/// 地理院への負荷を抑えるため、並列数を絞り、1枚ごとに間隔を空けて取得する。
class OfflineMapService {
  OfflineMapService(
    this._db,
    this._store,
    this._client, {
    this.concurrency = 4,
    this.interval = const Duration(milliseconds: 50),
  });

  final AppDatabase _db;
  final OfflineTileStore _store;
  final http.Client _client;
  final int concurrency;
  final Duration interval;

  /// 取得中のエリアと、その中断フラグ。
  final _running = <int, _Job>{};

  Stream<List<OfflineArea>> watchAll() => (_db.select(
    _db.offlineAreas,
  )..orderBy([(a) => OrderingTerm.desc(a.createdAt)])).watch();

  bool isRunning(int id) => _running.containsKey(id);

  /// 全エリアの使用容量(バイト)。
  Future<int> usedBytes() async {
    final sum = _db.offlineAreas.bytes.sum();
    final row = await (_db.selectOnly(
      _db.offlineAreas,
    )..addColumns([sum])).getSingle();
    return row.read(sum) ?? 0;
  }

  /// エリアを登録する。取得は [download] で始める。上限を超えるときは [OfflineMapException]。
  Future<int> create({
    required String name,
    required GeoBounds bounds,
    required Set<GsiTileLayer> layers,
    required int maxZoom,
  }) async {
    if (layers.isEmpty) throw OfflineMapException('地図の種類を選んでください');
    if (!bounds.isValid) throw OfflineMapException('範囲が正しくありません');
    final estimate = estimateOffline(bounds, layers, maxZoom);
    if (estimate.exceedsAreaLimit()) {
      throw OfflineMapException(
        '1エリアの上限(${offlineAreaLimitBytes ~/ (1024 * 1024)}MB)を超えます。範囲を狭めるか、ズームを下げてください',
      );
    }
    if (await usedBytes() + estimate.bytes > offlineTotalLimitBytes) {
      throw OfflineMapException(
        '全体の上限(${offlineTotalLimitBytes ~/ (1024 * 1024 * 1024)}GB)を超えます。不要なエリアを削除してください',
      );
    }
    final orderedLayers = GsiTileLayer.values
        .where(layers.contains)
        .map((l) => l.name)
        .join(',');
    return _db
        .into(_db.offlineAreas)
        .insert(
          OfflineAreasCompanion.insert(
            name: name.trim().isEmpty ? '無題のエリア' : name.trim(),
            south: bounds.south,
            west: bounds.west,
            north: bounds.north,
            east: bounds.east,
            layers: orderedLayers,
            minZoom: offlineMinZoom,
            maxZoom: maxZoom,
            tileCount: estimate.tileCount,
          ),
        );
  }

  /// 取得する。保存済みのタイルは飛ばすので、中断したあとの再開にも使う。
  /// 通信できなくなったら止まり(状態は「取得中」のまま)、false を返す。完了で true。
  Future<bool> download(int id) async {
    if (_running.containsKey(id)) return false;
    final area = await (_db.select(
      _db.offlineAreas,
    )..where((a) => a.id.equals(id))).getSingle();
    final job = _running[id] = _Job();
    try {
      // 前回、書き込み途中で終了して残った一時ファイルを消す
      await _store.cleanTempFiles(id);
      final layers = {
        for (final n in area.layers.split(',')) GsiTileLayer.values.byName(n),
      };
      final bounds = GeoBounds(
        south: area.south,
        west: area.west,
        north: area.north,
        east: area.east,
      );
      final tiles = tilesToDownload(bounds, layers, area.maxZoom).iterator;

      var done = 0;
      var bytes = 0;
      var sinceSave = 0;
      Future<void> save() =>
          (_db.update(_db.offlineAreas)..where((a) => a.id.equals(id))).write(
            OfflineAreasCompanion(
              downloadedCount: Value(done),
              bytes: Value(bytes),
            ),
          );

      Future<void> worker() async {
        while (!job.stop && !job.failed) {
          // イテレータはワーカー間で共有する。moveNext から取り出しまで await を挟まないので安全
          if (!tiles.moveNext()) return;
          final (layer, t) = tiles.current;
          final file = _store.fileFor(id, layer, t);
          int? size;
          if (await file.exists()) {
            size = await file.length();
          } else {
            size = await _fetch(layer, t, file, job);
            if (size == null) return; // 通信できない: 止める
            await Future<void>.delayed(interval);
          }
          done++;
          bytes += size;
          if (++sinceSave >= 25) {
            sinceSave = 0;
            await save();
          }
        }
      }

      await Future.wait([for (var i = 0; i < concurrency; i++) worker()]);
      await save();
      if (job.stop || job.failed) return false;
      await (_db.update(_db.offlineAreas)..where((a) => a.id.equals(id))).write(
        OfflineAreasCompanion(
          status: const Value('complete'),
          completedAt: Value(DateTime.now()),
        ),
      );
      return true;
    } finally {
      _running.remove(id);
    }
  }

  /// タイル1枚を取って保存し、サイズを返す。地理院にタイルがない(404)ときは 0。
  /// 通信できないときは null を返し、取得全体を止める。
  Future<int?> _fetch(
    GsiTileLayer layer,
    TileCoord t,
    File file,
    _Job job,
  ) async {
    try {
      final response = await _client.get(
        Uri.parse(
          'https://cyberjapandata.gsi.go.jp/xyz/${layer.id}/${t.z}/${t.x}/${t.y}.${layer.extension}',
        ),
      );
      if (response.statusCode == 404) return 0;
      if (response.statusCode != 200) {
        job.failed = true;
        return null;
      }
      await file.parent.create(recursive: true);
      // 書き込み途中のファイルを読まれないよう、一時ファイルに書いてから置き換える
      final temp = File('${file.path}.tmp');
      await temp.writeAsBytes(response.bodyBytes, flush: true);
      await temp.rename(file.path);
      return response.bodyBytes.length;
    } catch (_) {
      job.failed = true;
      return null;
    }
  }

  /// 保存し直す(半年たったエリアの再取得)。保存済みのファイルを消して、最初から取る。
  Future<bool> refresh(int id) async {
    if (_running.containsKey(id)) return false;
    await _store.deleteArea(id);
    await (_db.update(_db.offlineAreas)..where((a) => a.id.equals(id))).write(
      const OfflineAreasCompanion(
        status: Value('downloading'),
        downloadedCount: Value(0),
        bytes: Value(0),
        completedAt: Value(null),
      ),
    );
    return download(id);
  }

  /// 取得を中断する(続きから再開できる)。
  void pause(int id) => _running[id]?.stop = true;

  /// エリアを削除する。取得中なら止めてから、ファイルごと消す。
  Future<void> delete(int id) async {
    final job = _running[id];
    if (job != null) {
      job.stop = true;
      // 取得が止まるのを待つ
      while (_running.containsKey(id)) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    }
    await _store.deleteArea(id);
    await (_db.delete(_db.offlineAreas)..where((a) => a.id.equals(id))).go();
  }

  /// 保存から半年たっているか(再取得を促す)。
  static bool isStale(OfflineArea a, DateTime now) {
    final completed = a.completedAt;
    return completed != null &&
        now.difference(completed).inDays >= offlineStaleDays;
  }
}

class _Job {
  var stop = false;
  var failed = false;
}
