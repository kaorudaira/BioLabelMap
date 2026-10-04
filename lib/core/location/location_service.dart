import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// 位置情報の権限が無い、または端末の位置情報がオフ。
class LocationUnavailableException implements Exception {
  LocationUnavailableException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// 端末の GPS(geolocator のラッパー)。
class LocationService {
  /// 権限を確認し、必要なら求める。使えなければ例外。
  Future<void> ensureAvailable() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw LocationUnavailableException('端末の位置情報がオフです');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw LocationUnavailableException('位置情報の利用が許可されていません');
    }
  }

  /// 現在地の流れ。精度は最高にし、少しでも動いたら通知する。
  ///
  /// Android は Google Play 開発者サービス(Fused Location)を使わず、OS の GPS を直接使う。
  /// Fused Location は Google の「位置情報の精度」への同意を求める画面を出し、断ると止まるため。
  /// 圏外の山間部で必要なのは GPS なので、OS の GPS で足りる。
  Stream<Position> positions() => Geolocator.getPositionStream(
    locationSettings: defaultTargetPlatform == TargetPlatform.android
        ? AndroidSettings(accuracy: LocationAccuracy.best, forceLocationManager: true)
        : const LocationSettings(accuracy: LocationAccuracy.best),
  );
}

final locationServiceProvider = Provider((ref) => LocationService());

/// 現在地。画面からは `ref.watch(positionProvider)` で受け取る。
///
/// `async*` と `yield*` は、Stream を返す関数の書き方(Java の Flux.concat に近い)。
/// 失敗しても自動では再試行しない(権限の確認が繰り返し出てしまうため)。
/// 画面から `ref.invalidate(positionProvider)` で取り直す。
final positionProvider = StreamProvider<Position>(
  (ref) async* {
    final service = ref.watch(locationServiceProvider);
    await service.ensureAvailable();
    yield* service.positions();
  },
  retry: (retryCount, error) => null,
);
