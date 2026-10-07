import 'dart:async';
import 'dart:convert';

import 'package:biolabelmap/core/gsi/gsi_api.dart';
import 'package:biolabelmap/core/gsi/municipality_directory.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  GsiApi apiReturning(Object body, {int status = 200}) => GsiApi(
    MockClient((_) async => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
    )),
  );

  group('fetchElevation', () {
    test('数値の標高を返す', () async {
      final outcome = await apiReturning({'elevation': 1390, 'hsrc': '5m'})
          .fetchElevation(36.9447, 139.2426);
      expect(outcome, isA<Found<double>>());
      expect((outcome as Found<double>).value, 1390.0);
    });

    test('「-----」はデータ無し', () async {
      final outcome = await apiReturning({'elevation': '-----'})
          .fetchElevation(35.0, 140.5);
      expect(outcome, isA<NotAvailable<double>>());
    });

    test('緯度・経度をクエリに入れる', () async {
      late Uri requested;
      final api = GsiApi(MockClient((request) async {
        requested = request.url;
        return http.Response('{"elevation": 1}', 200);
      }));
      await api.fetchElevation(36.9447, 139.2426);
      expect(requested.queryParameters,
          {'lon': '139.2426', 'lat': '36.9447', 'outtype': 'JSON'});
    });
  });

  group('fetchAddress', () {
    test('自治体コードと大字を返す', () async {
      final outcome = await apiReturning({
        'results': {'muniCd': '15225', 'lv01Nm': '下折立'},
      }).fetchAddress(36.9447, 139.2426);
      final address = (outcome as Found<GsiAddress>).value;
      expect(address.municipalityCode, '15225');
      expect(address.localityJa, '下折立');
    });

    test('4桁の自治体コードは5桁にゼロ埋めする', () async {
      final outcome = await apiReturning({
        'results': {'muniCd': '1101', 'lv01Nm': '－'},
      }).fetchAddress(43.06, 141.35);
      final address = (outcome as Found<GsiAddress>).value;
      expect(address.municipalityCode, '01101');
      expect(address.localityJa, isNull);
    });

    test('結果が空ならデータ無し', () async {
      expect(await apiReturning({}).fetchAddress(35.0, 140.5),
          isA<NotAvailable<GsiAddress>>());
    });
  });

  group('通信エラー', () {
    test('接続できない', () {
      final api = GsiApi(MockClient((_) async => throw http.ClientException('x')));
      expect(api.fetchElevation(0, 0), throwsA(isA<GsiNetworkException>()));
    });

    test('タイムアウト', () {
      final api = GsiApi(
        MockClient((_) => Completer<http.Response>().future),
        timeout: const Duration(milliseconds: 10),
      );
      expect(api.fetchElevation(0, 0), throwsA(isA<GsiNetworkException>()));
    });

    test('サーバーエラー', () {
      expect(apiReturning({}, status: 503).fetchAddress(0, 0),
          throwsA(isA<GsiNetworkException>()));
    });

    test('JSON でない応答', () {
      final api = GsiApi(MockClient((_) async => http.Response('<html>', 200)));
      expect(api.fetchElevation(0, 0), throwsA(isA<GsiNetworkException>()));
    });
  });

  group('searchPlaces', () {
    Map<String, Object?> feature(String title, double lon, double lat) => {
      'type': 'Feature',
      'geometry': {'type': 'Point', 'coordinates': [lon, lat]},
      'properties': {'title': title, 'addressCode': ''},
    };

    test('名前と座標を取り出し、検索語と同じ名前を先に並べる', () async {
      final hits = await apiReturning([
        feature('神奈川県横須賀市武', 139.65, 35.22),
        feature('武尊山', 139.1326, 36.8052),
      ]).searchPlaces('武尊山');
      expect(hits.map((h) => h.title), ['武尊山', '神奈川県横須賀市武']);
      expect(hits.first.latitude, closeTo(36.8052, 1e-9));
      expect(hits.first.longitude, closeTo(139.1326, 1e-9));
    });

    test('検索語をクエリに入れる。空の検索語は通信しない', () async {
      var calls = 0;
      late Uri requested;
      final api = GsiApi(MockClient((request) async {
        calls++;
        requested = request.url;
        return http.Response('[]', 200);
      }));
      expect(await api.searchPlaces('   '), isEmpty);
      expect(calls, 0);
      await api.searchPlaces('尾瀬ヶ原');
      expect(requested.queryParameters, {'q': '尾瀬ヶ原'});
    });

    test('形が違う項目は読み飛ばし、結果が配列でなければ空', () async {
      final hits = await apiReturning([
        {'geometry': {}, 'properties': {}},
        feature('谷川岳', 138.93, 36.83),
      ]).searchPlaces('谷川岳');
      expect(hits.map((h) => h.title), ['谷川岳']);
      expect(await apiReturning({'error': 1}).searchPlaces('x'), isEmpty);
    });

    test('同じ名前で同じ場所の結果は1件にまとめ、離れた同名は残す', () async {
      final hits = await apiReturning([
        feature('みずがき湖', 138.5009, 35.8592),
        feature('みずがき湖', 138.50091, 35.85921),
        feature('みずがき湖', 139.0, 36.0),
      ]).searchPlaces('みずがき');
      expect(hits.length, 2);
    });

    test('最大件数で切る', () async {
      final hits = await apiReturning([
        for (var i = 0; i < 50; i++) feature('地名$i', 139, 36),
      ]).searchPlaces('地名', maxResults: 30);
      expect(hits.length, 30);
    });

    test('通信エラーは GsiNetworkException', () async {
      await expectLater(
        apiReturning([], status: 500).searchPlaces('x'),
        throwsA(isA<GsiNetworkException>()),
      );
    });
  });

  group('JsonMunicipalityDirectory', () {
    final directory = JsonMunicipalityDirectory.parse(jsonEncode({
      '1101': {
        'prefJa': '北海道',
        'muniJa': '札幌市中央区',
        'prefEn': 'Hokkaidō',
        'muniEn': 'Sapporo-shi Chūō-ku',
      },
    }));

    test('コードの桁がそろっていなくても引ける', () {
      expect(directory.lookup('01101')?.prefectureEn, 'Hokkaidō');
      expect(directory.lookup('1101')?.municipalityJa, '札幌市中央区');
    });

    test('無いコードは null', () {
      expect(directory.lookup('99999'), isNull);
    });
  });
}
