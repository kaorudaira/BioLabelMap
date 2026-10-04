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
