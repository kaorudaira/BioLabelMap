import 'dart:io';

import 'package:biolabelmap/core/db/database.dart';
import 'package:biolabelmap/core/gsi/tile_layers.dart';
import 'package:biolabelmap/core/tiles/offline_tile_store.dart';
import 'package:biolabelmap/domain/tiles/offline_plan.dart';
import 'package:biolabelmap/domain/tiles/tile_math.dart';
import 'package:biolabelmap/services/offline_map_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late AppDatabase db;
  late Directory dir;
  late OfflineTileStore store;
  final requested = <String>[];

  // 小さな範囲(ズーム6〜10 で数十枚)
  const bounds = GeoBounds(south: 37.0, west: 139.0, north: 37.05, east: 139.05);

  OfflineMapService service(http.Client client) =>
      OfflineMapService(db, store, client, interval: Duration.zero);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    dir = await Directory.systemTemp.createTemp('offline_tiles_test');
    store = OfflineTileStore(dir);
    requested.clear();
  });

  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });

  http.Client okClient() => MockClient((request) async {
    requested.add(request.url.path);
    return http.Response.bytes(List.filled(100, 1), 200);
  });

  test('保存すると、すべてのタイルをファイルに置き、完了にする', () async {
    final s = service(okClient());
    final id = await s.create(name: 'テスト', bounds: bounds, layers: {GsiTileLayer.standard}, maxZoom: 13);
    final expected = countTiles(bounds, offlineMinZoom, 13);

    expect(await s.download(id), isTrue);

    final area = await (db.select(db.offlineAreas)..where((a) => a.id.equals(id))).getSingle();
    expect(area.status, 'complete');
    expect(area.tileCount, expected);
    expect(area.downloadedCount, expected);
    expect(area.bytes, expected * 100);
    expect(area.completedAt, isNotNull);
    expect(requested.length, expected);
    expect(requested.any((p) => p.startsWith('/xyz/std/6/')), isTrue);
    expect(store.fileFor(id, GsiTileLayer.standard, tileAt(37.02, 139.02, 13)).existsSync(), isTrue);
    expect(await s.usedBytes(), expected * 100);
  });

  test('通信できなくなったら止まり、再開すると保存済みを飛ばして続きから取る', () async {
    var calls = 0;
    final flaky = MockClient((request) async {
      if (++calls > 5) throw const SocketException('圏外');
      return http.Response.bytes(List.filled(100, 1), 200);
    });
    final s = service(flaky);
    final id = await s.create(name: 'テスト', bounds: bounds, layers: {GsiTileLayer.standard}, maxZoom: 14);
    final expected = countTiles(bounds, offlineMinZoom, 14);

    expect(await s.download(id), isFalse);
    var area = await (db.select(db.offlineAreas)..where((a) => a.id.equals(id))).getSingle();
    expect(area.status, 'downloading');
    expect(area.downloadedCount, lessThan(expected));

    // 再開: 取得済みの分は通信しない
    final resumed = service(okClient());
    expect(await resumed.download(id), isTrue);
    expect(requested.length, expected - 5);
    area = await (db.select(db.offlineAreas)..where((a) => a.id.equals(id))).getSingle();
    expect(area.status, 'complete');
    expect(area.downloadedCount, expected);
  });

  test('地理院にタイルがない(404)ものは、保存せずに数える', () async {
    final s = service(MockClient((_) async => http.Response('', 404)));
    final id = await s.create(name: 'テスト', bounds: bounds, layers: {GsiTileLayer.standard}, maxZoom: 8);
    expect(await s.download(id), isTrue);
    final area = await (db.select(db.offlineAreas)..where((a) => a.id.equals(id))).getSingle();
    expect(area.downloadedCount, area.tileCount);
    expect(area.bytes, 0);
  });

  test('取得を始めるとき、前回残った一時ファイルを消し、保存済みのタイルは残す', () async {
    final s = service(okClient());
    final id = await s.create(name: 'テスト', bounds: bounds, layers: {GsiTileLayer.standard}, maxZoom: 8);
    final done = store.fileFor(id, GsiTileLayer.standard, tileAt(37.02, 139.02, 7))..createSync(recursive: true);
    done.writeAsBytesSync([1, 2, 3]);
    final leftover = File('${done.path}.tmp')..writeAsBytesSync([9]);

    expect(await store.cleanTempFiles(id), 1);
    expect(leftover.existsSync(), isFalse);
    expect(done.existsSync(), isTrue);

    // download() も同じ掃除をする
    File('${done.path}.tmp').writeAsBytesSync([9]);
    await s.download(id);
    expect(File('${done.path}.tmp').existsSync(), isFalse);
  });

  test('エリアのフォルダがなくても、掃除は何もしない', () async {
    expect(await store.cleanTempFiles(999), 0);
  });

  test('削除すると、ファイルと登録を消す', () async {
    final s = service(okClient());
    final id = await s.create(name: 'テスト', bounds: bounds, layers: {GsiTileLayer.standard}, maxZoom: 8);
    await s.download(id);
    expect(Directory('${dir.path}/area_$id').existsSync(), isTrue);

    await s.delete(id);

    expect(Directory('${dir.path}/area_$id').existsSync(), isFalse);
    expect(await db.select(db.offlineAreas).get(), isEmpty);
  });

  test('1エリアの上限を超える保存は、登録しない', () async {
    final s = service(okClient());
    const wide = GeoBounds(south: 36.0, west: 138.0, north: 38.0, east: 140.0);
    await expectLater(
      s.create(name: '広すぎる', bounds: wide, layers: {GsiTileLayer.standard}, maxZoom: 18),
      throwsA(isA<OfflineMapException>()),
    );
    expect(await db.select(db.offlineAreas).get(), isEmpty);
  });

  test('地図の種類を選ばないと登録しない', () async {
    final s = service(okClient());
    await expectLater(
      s.create(name: 'x', bounds: bounds, layers: {}, maxZoom: 10),
      throwsA(isA<OfflineMapException>()),
    );
  });

  test('半年たったエリアは「更新」の対象', () async {
    final s = service(okClient());
    final id = await s.create(name: 'テスト', bounds: bounds, layers: {GsiTileLayer.standard}, maxZoom: 8);
    await s.download(id);
    final area = await (db.select(db.offlineAreas)..where((a) => a.id.equals(id))).getSingle();
    final now = DateTime.now();
    expect(OfflineMapService.isStale(area, now), isFalse);
    expect(OfflineMapService.isStale(area, now.add(const Duration(days: 200))), isTrue);
  });
}
