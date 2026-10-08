import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// API の結果。値が取れたか、通信は成功したがデータが無いか(海上など)。
///
/// `sealed class` は、サブクラスをこのファイル内に限定する。
/// Java 17 の `sealed interface ... permits ...` と同じで、switch で全ケースを網羅できる。
sealed class FetchOutcome<T> {
  const FetchOutcome();
}

final class Found<T> extends FetchOutcome<T> {
  const Found(this.value);
  final T value;
}

final class NotAvailable<T> extends FetchOutcome<T> {
  const NotAvailable();
}

/// 通信エラー(圏外、タイムアウト、サーバーエラー)。補完キューで再試行する。
class GsiNetworkException implements Exception {
  GsiNetworkException(this.message);
  final String message;

  @override
  String toString() => 'GsiNetworkException: $message';
}

/// 逆ジオコーダの結果。
class GsiAddress {
  const GsiAddress({required this.municipalityCode, this.localityJa});

  /// 自治体コード(5桁にゼロ埋め済み)。
  final String municipalityCode;

  /// 大字。無いときは null。
  final String? localityJa;
}

/// 地名検索の1件。
class PlaceHit {
  const PlaceHit({required this.title, required this.latitude, required this.longitude});

  final String title;
  final double latitude;
  final double longitude;
}

/// 国土地理院の標高API・逆ジオコーダ・地名検索。
///
/// 利用規約の確認が取れるまでは、呼び出し側で1件ずつ順に呼ぶ(並列にしない)。
class GsiApi {
  // `http.Client` を外から渡せるようにして、テストでは MockClient に差し替える。
  GsiApi(this._client, {this.timeout = const Duration(seconds: 10)});

  final http.Client _client;
  final Duration timeout;

  static final _elevationUrl = Uri.parse(
    'https://cyberjapandata2.gsi.go.jp/general/dem/scripts/getelevation.php',
  );
  static final _searchUrl = Uri.parse('https://msearch.gsi.go.jp/address-search/AddressSearch');
  static final _reverseGeocoderUrl = Uri.parse(
    'https://mreversegeocoder.gsi.go.jp/reverse-geocoder/LonLatToAddress',
  );

  /// 標高(m)。データが無い地点では `-----` が返り、NotAvailable にする。
  Future<FetchOutcome<double>> fetchElevation(
    double latitude,
    double longitude,
  ) async {
    final json = await _getJson(
      _elevationUrl.replace(
        queryParameters: {
          'lon': '$longitude',
          'lat': '$latitude',
          'outtype': 'JSON',
        },
      ),
    );
    // Dart 3 のパターンマッチ。Map の中身の型を確かめながら取り出す。
    return switch (json) {
      {'elevation': final num e} => Found(e.toDouble()),
      _ => const NotAvailable(),
    };
  }

  /// 自治体コードと大字。海上などでは結果が空になり、NotAvailable にする。
  Future<FetchOutcome<GsiAddress>> fetchAddress(
    double latitude,
    double longitude,
  ) async {
    final json = await _getJson(
      _reverseGeocoderUrl.replace(
        queryParameters: {'lat': '$latitude', 'lon': '$longitude'},
      ),
    );
    if (json case {'results': {'muniCd': final String code}}
        when code.trim().isNotEmpty) {
      final lv01 = switch (json) {
        {'results': {'lv01Nm': final String name}} => name.trim(),
        _ => '',
      };
      return Found(
        GsiAddress(
          municipalityCode: code.trim().padLeft(5, '0'),
          // 大字が無いときは「－」などの記号が返ることがある
          localityJa: (lv01.isEmpty || lv01 == '－' || lv01 == '-') ? null : lv01,
        ),
      );
    }
    return const NotAvailable();
  }

  /// 地名・住所の検索(地理院の地名検索API)。住所・山や川などの自然地名・施設名が引ける。
  /// 名前が検索語とそっくり同じものを先に並べ、あとは API の順。最大 [maxResults] 件。
  Future<List<PlaceHit>> searchPlaces(String query, {int maxResults = 30}) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final json = await _getJson(_searchUrl.replace(queryParameters: {'q': q}));
    if (json is! List) return const [];

    final hits = <PlaceHit>[];
    for (final item in json) {
      if (item case {
        'geometry': {'coordinates': [final num lon, final num lat]},
        'properties': {'title': final String title},
      }) {
        hits.add(PlaceHit(title: title, latitude: lat.toDouble(), longitude: lon.toDouble()));
      }
    }
    // sort は安定ではないので、完全一致を先にするときは分けて並べる
    final exact = hits.where((h) => h.title == q);
    final others = hits.where((h) => h.title != q);
    return [...exact, ...others].take(maxResults).toList();
  }

  Future<Object?> _getJson(Uri url) async {
    final http.Response response;
    try {
      response = await _client.get(url).timeout(timeout);
    } on TimeoutException {
      // `on 型` は Java の catch (型 e) に相当する。
      throw GsiNetworkException('タイムアウト');
    } on SocketException catch (e) {
      throw GsiNetworkException('接続できません: ${e.message}');
    } on http.ClientException catch (e) {
      throw GsiNetworkException('接続できません: ${e.message}');
    }

    if (response.statusCode != 200) {
      throw GsiNetworkException('HTTP ${response.statusCode}');
    }
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw GsiNetworkException('応答を読めません');
    }
  }
}
