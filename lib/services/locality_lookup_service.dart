import 'package:drift/drift.dart';

import '../core/db/database.dart';
import '../core/gsi/gsi_api.dart';
import '../core/gsi/municipality_directory.dart';
import '../core/gsi/oaza_romaji_table.dart';
import '../domain/models/place_info.dart';

/// 逆ジオコーダの結果から、地名(和・英)を作る。
///
/// 県・郡・市町村は内蔵の対応表から引く。大字のローマ字は、次の順で決める。
/// 1. [currentLocalityEn](手入力済み)
/// 2. 辞書(これまでに手入力した綴り)
/// 3. 公的データの対応表([oaza])。マクロンを含むものは確認が要るため、ここでは入れない
Future<PlaceInfo> buildPlaceInfo(
  AppDatabase db,
  MunicipalityDirectory directory,
  GsiAddress address, {
  String? currentLocalityEn,
  OazaRomajiTable oaza = OazaRomajiTable.empty,
}) async {
  final names = directory.lookup(address.municipalityCode);

  var localityEn = currentLocalityEn;
  if (localityEn == null && address.localityJa != null) {
    final entry = await (db.select(db.placeRomajiDict)
          ..where(
            (d) =>
                d.municipalityCode.equals(address.municipalityCode) &
                d.localityJa.equals(address.localityJa!),
          ))
        .getSingleOrNull();
    localityEn = entry?.localityEn;
  }
  if (localityEn == null) {
    final public = oaza.lookup(address.municipalityCode, address.localityJa);
    if (public != null && !public.needsConfirmation) localityEn = public.value;
  }

  return PlaceInfo(
    municipalityCode: address.municipalityCode,
    prefectureJa: names?.prefectureJa,
    countyJa: names?.countyJa,
    municipalityJa: names?.municipalityJa,
    localityJa: address.localityJa,
    prefectureEn: names?.prefectureEn,
    countyEn: names?.countyEn,
    municipalityEn: names?.municipalityEn,
    localityEn: localityEn,
  );
}

/// 手入力した大字のローマ字を辞書に溜める。同じ大字がすでにあれば、新しい綴りで置き換える。
Future<void> rememberPlaceRomaji(
  AppDatabase db, {
  required String municipalityCode,
  required String localityJa,
  required String localityEn,
}) => db.into(db.placeRomajiDict).insert(
  PlaceRomajiDictCompanion.insert(
    municipalityCode: municipalityCode,
    localityJa: localityJa,
    localityEn: localityEn,
    useCount: const Value(1),
  ),
  onConflict: DoUpdate.withExcluded(
    (old, excluded) => PlaceRomajiDictCompanion.custom(
      localityEn: excluded.localityEn,
      useCount: old.useCount + const Constant(1),
      updatedAt: currentDateAndTime,
    ),
    target: [db.placeRomajiDict.municipalityCode, db.placeRomajiDict.localityJa],
  ),
);

/// 記録画面での取得結果。取れなかったものは null(保存すると補完キューに入る)。
class LookupResult {
  const LookupResult({this.elevationMeters, this.place, this.offline = false});

  final double? elevationMeters;
  final PlaceInfo? place;

  /// 通信できなかった(圏外)。
  final bool offline;
}

/// 記録画面を開いたときに、標高と地名をその場で取得する(要件定義 F-04)。
/// 圏外なら何も取れず、保存後に補完キューで取得する(F-05)。
class LocalityLookupService {
  LocalityLookupService(this._db, this._api, this._directory, {this._oaza = OazaRomajiTable.empty});

  final AppDatabase _db;
  final GsiApi _api;
  final MunicipalityDirectory _directory;
  final OazaRomajiTable _oaza;

  Future<LookupResult> lookup(double latitude, double longitude) async {
    try {
      final elevation = await _api.fetchElevation(latitude, longitude);
      final address = await _api.fetchAddress(latitude, longitude);
      return LookupResult(
        elevationMeters: switch (elevation) {
          Found(:final value) => value,
          NotAvailable() => null,
        },
        place: switch (address) {
          Found(:final value) => await buildPlaceInfo(_db, _directory, value, oaza: _oaza),
          NotAvailable() => null,
        },
      );
    } on GsiNetworkException {
      return const LookupResult(offline: true);
    }
  }
}
