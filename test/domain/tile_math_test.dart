import 'package:biolabelmap/core/gsi/tile_layers.dart';
import 'package:biolabelmap/domain/tiles/offline_plan.dart';
import 'package:biolabelmap/domain/tiles/tile_math.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('tileAt', () {
    test('ズーム0は世界で1枚', () {
      expect(tileAt(36, 139, 0), const TileCoord(0, 0, 0));
    });

    test('赤道と本初子午線の交点は、ズーム1で南東のタイル', () {
      expect(tileAt(0, 0, 1), const TileCoord(1, 1, 1));
    });

    test('範囲の外は端のタイルに丸める', () {
      expect(tileAt(89, -190, 2), const TileCoord(2, 0, 0));
      expect(tileAt(-89, 190, 2), const TileCoord(2, 3, 3));
    });

    test('東京駅の周辺(ズーム15)', () {
      // 国土地理院の解説にある計算式どおりの値
      expect(tileAt(35.681, 139.767, 15), const TileCoord(15, 29105, 12903));
    });
  });

  group('枚数と見積もり', () {
    // 約20km四方(緯度で0.18°、経度で0.22°)。魚沼市あたり。
    const area = GeoBounds(south: 37.0, west: 139.0, north: 37.18, east: 139.22);

    test('範囲が逆なら無効', () {
      expect(const GeoBounds(south: 1, west: 1, north: 0, east: 2).isValid, isFalse);
      expect(area.isValid, isTrue);
    });

    test('数えた枚数と、列挙した枚数が一致する', () {
      expect(tilesIn(area, 6, 12).length, countTiles(area, 6, 12));
    });

    test('列挙したタイルは、すべて範囲に含まれる', () {
      for (final t in tilesIn(area, 10, 13)) {
        expect(coversTile(area, 6, 13, t), isTrue, reason: '$t');
      }
      expect(coversTile(area, 6, 13, const TileCoord(14, 0, 0)), isFalse);
      expect(coversTile(area, 6, 13, const TileCoord(10, 0, 0)), isFalse);
    });

    test('約20km四方・標準地図・ズーム16は、要件定義の目安(約2,300枚・約50MB)に近い', () {
      final e = estimateOffline(area, {GsiTileLayer.standard}, 16);
      expect(e.tileCount, inInclusiveRange(1500, 2600));
      expect(e.bytes / (1024 * 1024), inInclusiveRange(30, 55));
      expect(e.exceedsAreaLimit(), isFalse);
    });

    test('ズーム18は1エリアの上限(200MB)を超える', () {
      final e = estimateOffline(area, {GsiTileLayer.standard}, 18);
      expect(e.exceedsAreaLimit(), isTrue);
    });

    test('最大ズームは、地図の種類ごとの上限で切って数える', () {
      final relief = estimateOffline(area, {GsiTileLayer.relief}, 18);
      final reliefAt15 = estimateOffline(area, {GsiTileLayer.relief}, 15);
      expect(relief.tileCount, reliefAt15.tileCount);
      expect(maxZoomFor({GsiTileLayer.standard, GsiTileLayer.relief}), 15);
    });

    test('地図の種類を増やすと、枚数と容量が増える', () {
      final one = estimateOffline(area, {GsiTileLayer.standard}, 14);
      final two = estimateOffline(area, {GsiTileLayer.standard, GsiTileLayer.photo}, 14);
      expect(two.tileCount, one.tileCount * 2);
      expect(two.bytes, greaterThan(one.bytes));
    });
  });
}
