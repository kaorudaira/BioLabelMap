import 'dart:async';
import 'dart:io';

import 'package:biolabelmap/core/db/database.dart';
import 'package:biolabelmap/core/gsi/tile_layers.dart';
import 'package:biolabelmap/core/tiles/offline_tile_store.dart';
import 'package:biolabelmap/domain/tiles/tile_math.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory dir;
  late OfflineTileStore store;

  // 木賊峠の周辺(ズーム6〜18)
  const lat = 35.8308;
  const lon = 138.5666;
  final area = OfflineArea(
    id: 7,
    name: '木賊峠周辺',
    south: 35.82,
    west: 138.55,
    north: 35.84,
    east: 138.58,
    layers: 'standard',
    minZoom: 6,
    maxZoom: 18,
    tileCount: 1,
    downloadedCount: 1,
    bytes: 1,
    status: 'complete',
    createdAt: DateTime(2026, 10, 7),
    completedAt: DateTime(2026, 10, 7),
  );

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('offline_provider_test');
    store = OfflineTileStore(dir);
  });

  tearDown(() => dir.delete(recursive: true));

  OfflineFirstTileProvider provider({GsiTileLayer layer = GsiTileLayer.standard}) =>
      OfflineFirstTileProvider(store: store, areas: [area], layer: layer);

  TileCoordinates coords(int z) {
    final t = tileAt(lat, lon, z);
    return TileCoordinates(t.x, t.y, z);
  }

  /// flutter_map の TileLayer が、タイルごとにやっている呼び分け(tile_layer.dart の _createTileImage)。
  ImageProvider imageFor(OfflineFirstTileProvider p, TileCoordinates c) {
    final options = TileLayer(urlTemplate: GsiTileLayer.standard.urlTemplate);
    return p.supportsCancelLoading
        ? p.getImageWithCancelLoadingSupport(c, options, Completer<void>().future)
        : p.getImage(c, options);
  }

  test('保存済みのタイルは、タイル層が呼ぶ経路でファイルから読む(ズーム18)', () async {
    final c = coords(18);
    store.fileFor(7, GsiTileLayer.standard, TileCoord(18, c.x, c.y))
      ..createSync(recursive: true)
      ..writeAsBytesSync([1, 2, 3]);

    final image = imageFor(provider(), c);

    expect(image, isA<FileImage>());
    expect((image as FileImage).file.path, store.fileFor(7, GsiTileLayer.standard, TileCoord(18, c.x, c.y)).path);
  });

  test('ズーム6から18まで、保存済みなら読む', () {
    for (var z = 6; z <= 18; z++) {
      final c = coords(z);
      store.fileFor(7, GsiTileLayer.standard, TileCoord(z, c.x, c.y))
        ..createSync(recursive: true)
        ..writeAsBytesSync([1]);
      expect(imageFor(provider(), c), isA<FileImage>(), reason: 'z$z');
    }
  });

  test('保存していないタイルは、通信で取る', () {
    expect(imageFor(provider(), coords(18)), isNot(isA<FileImage>()));
  });

  test('保存範囲の外のタイルは、ファイルがあっても読まない', () {
    final c = coords(18);
    final far = TileCoordinates(c.x + 5000, c.y, 18);
    store.fileFor(7, GsiTileLayer.standard, TileCoord(18, far.x, far.y))
      ..createSync(recursive: true)
      ..writeAsBytesSync([1]);
    expect(imageFor(provider(), far), isNot(isA<FileImage>()));
  });

  test('保存していない地図の種類は、読まない', () {
    final c = coords(18);
    store.fileFor(7, GsiTileLayer.standard, TileCoord(18, c.x, c.y))
      ..createSync(recursive: true)
      ..writeAsBytesSync([1]);
    expect(imageFor(provider(layer: GsiTileLayer.photo), c), isNot(isA<FileImage>()));
  });
}
