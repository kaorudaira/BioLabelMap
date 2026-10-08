import 'package:drift/drift.dart';

import '../core/db/database.dart';
import '../domain/dictionary.dart';
import '../domain/locality_key.dart';
import '../domain/models/collection_period.dart';
import '../domain/models/place_info.dart';
import '../domain/sampling_method.dart';
import '../domain/status.dart';
import 'catalog_number_service.dart';
import 'dictionary_service.dart';
import 'locality_lookup_service.dart';
import 'settings_service.dart';

/// 記録の地点。既存の地点を使うか、新しい位置か。
sealed class RecordPosition {
  const RecordPosition();
}

/// 「この地点に追加」。既存の地点をそのまま使い、座標のずれを防ぐ。
final class ExistingLocality extends RecordPosition {
  const ExistingLocality(this.localityId);
  final int localityId;
}

/// 新しい位置。標高・地名は、記録画面の時点で取れていれば渡す。
/// null なら「取得待ち」として補完キューに入れる。
final class NewPosition extends RecordPosition {
  const NewPosition({
    required this.latitude,
    required this.longitude,
    this.accuracyMeters,
    this.isManual = false,
    this.elevationMeters,
    this.place,
  });

  final double latitude;
  final double longitude;
  final double? accuracyMeters;

  /// 十字で位置を補正した。精度は記録しない。
  final bool isManual;
  final double? elevationMeters;
  final PlaceInfo? place;
}

/// 記録画面で入力された内容。
class RecordInput {
  const RecordInput({
    required this.position,
    required this.period,
    required this.recordedAt,
    required this.samplingMethod,
    this.samplingMethodOther,
    this.lightSource,
    this.bait,
    this.habitat,
    this.hostPlant,
    this.count = 1,
    this.sex,
    this.remarks,
    this.draftId,
    this.confirmNow = false,
  });

  final RecordPosition position;
  final CollectionPeriod period;
  final DateTime recordedAt;
  final SamplingMethod samplingMethod;
  final String? samplingMethodOther;
  final String? lightSource;
  final String? bait;
  final String? habitat;
  final String? hostPlant;

  /// 作成数。標本を連番でこの件数だけ作る。各標本の個体数は1。
  final int count;
  final Sex? sex;
  final String? remarks;

  /// 下書きから保存するときの下書き ID。保存できたら下書きを消す。
  final int? draftId;

  /// 保存と同時に番号を確定する。ふつうは false(仮の標本として保存し、個体数などを直してから確定する)。
  final bool confirmNow;
}

/// 保存の結果。
class RecordResult {
  const RecordResult({
    required this.localityId,
    required this.collectionEventId,
    required this.specimenIds,
    this.catalogRange,
  });

  final int localityId;
  final int collectionEventId;
  final List<int> specimenIds;

  /// 確定した標本番号。例: `KYC00123〜KYC00137`。番号は確定の操作で付けるので、確定しなかったときは null。
  final String? catalogRange;
}

/// 記録の保存と採番(要件定義 第12章・第14章)。
class RecordService {
  RecordService(this._db);

  final AppDatabase _db;

  /// 保存する。地点・採集・標本(作成数ぶん)を1つのトランザクションで書く。
  /// 途中で失敗したら、全部が無かったことになる。
  /// 標本には番号を付けない(仮)。番号は、個体数などを直してから、確定の操作で付ける(第14章)。
  Future<RecordResult> save(RecordInput input) {
    if (input.count < 1) {
      throw ArgumentError.value(input.count, 'count', '作成数は1以上です');
    }

    return _db.transaction(() async {
      final settings = await _db.select(_db.appSettings).getSingle();
      // 初回設定(開始番号)が済んでいなければ、記録できない
      if (settings.nextCatalogNumber == null) throw CatalogNotInitializedException();

      final localityId = await _resolveLocality(input.position);

      final eventId = await _db.into(_db.collectionEvents).insert(
        CollectionEventsCompanion.insert(
          localityId: localityId,
          startDate: input.period.start,
          endDate: input.period.end,
          recordedAt: input.recordedAt,
          samplingMethod: input.samplingMethod,
          samplingMethodOther: Value(_clean(input.samplingMethodOther)),
          lightSource: Value(_clean(input.lightSource)),
          bait: Value(_clean(input.bait)),
          habitat: Value(_clean(input.habitat)),
          hostPlant: Value(_clean(input.hostPlant)),
          collector: Value(settings.collectorName),
        ),
      );

      // 環境・寄主植物は、次回から候補に出す
      final dictionary = DictionaryService(_db);
      await dictionary.rememberText(DictTextKind.habitat, input.habitat);
      await dictionary.rememberText(DictTextKind.hostPlant, input.hostPlant);

      final specimenIds = <int>[];
      for (var i = 0; i < input.count; i++) {
        specimenIds.add(
          await _db.into(_db.specimens).insert(
            SpecimensCompanion.insert(
              collectionEventId: eventId,
              sex: Value(input.sex),
              remarks: Value(_clean(input.remarks)),
            ),
          ),
        );
      }
      final confirmed = input.confirmNow ? await CatalogNumberService.confirmWithin(_db, specimenIds) : null;

      if (input.draftId case final id?) {
        await (_db.delete(_db.drafts)..where((d) => d.id.equals(id))).go();
      }

      return RecordResult(
        localityId: localityId,
        collectionEventId: eventId,
        specimenIds: specimenIds,
        catalogRange: confirmed?.range,
      );
    });
  }

  Future<int> _resolveLocality(RecordPosition position) async {
    switch (position) {
      case ExistingLocality(:final localityId):
        // 存在しない ID なら getSingle が例外を投げ、トランザクションごと取り消される
        await (_db.select(_db.localities)
              ..where((l) => l.id.equals(localityId)))
            .getSingle();
        return localityId;

      case NewPosition():
        final key = LocalityKey.fromCoordinates(
          position.latitude,
          position.longitude,
        );
        // 小数4桁が同じ地点がすでにあれば、それを使う(同じ地点として扱う)
        final existing =
            await (_db.select(_db.localities)
                  ..where(
                    (l) => l.latE4.equals(key.latE4) & l.lonE4.equals(key.lonE4),
                  )
                  ..limit(1))
                .getSingleOrNull();
        if (existing != null) return existing.id;
        return _insertLocality(position, key);
    }
  }

  Future<int> _insertLocality(NewPosition p, LocalityKey key) async {
    final place = p.place;
    final hasPlace = place?.municipalityCode != null;

    final id = await _db.into(_db.localities).insert(
      LocalitiesCompanion.insert(
        latitude: p.latitude,
        longitude: p.longitude,
        latE4: key.latE4,
        lonE4: key.lonE4,
        accuracyMeters: Value(p.isManual ? null : p.accuracyMeters),
        isManualPosition: Value(p.isManual),
        elevationMeters: Value(p.elevationMeters),
        elevationStatus: p.elevationMeters == null
            ? FetchStatus.pending
            : FetchStatus.fetched,
        municipalityCode: Value(place?.municipalityCode),
        prefectureJa: Value(place?.prefectureJa),
        countyJa: Value(place?.countyJa),
        municipalityJa: Value(place?.municipalityJa),
        localityJa: Value(_clean(place?.localityJa)),
        prefectureEn: Value(place?.prefectureEn),
        countyEn: Value(place?.countyEn),
        municipalityEn: Value(place?.municipalityEn),
        localityEn: Value(_clean(place?.localityEn)),
        placeStatus: hasPlace ? FetchStatus.fetched : FetchStatus.pending,
      ),
    );

    if (p.elevationMeters == null) await _enqueue(id, EnrichmentKind.elevation);
    if (!hasPlace) await _enqueue(id, EnrichmentKind.place);
    if (place != null) await _rememberRomaji(place);
    return id;
  }

  Future<void> _enqueue(int localityId, EnrichmentKind kind) =>
      _db.into(_db.enrichmentQueue).insert(
        EnrichmentQueueCompanion.insert(localityId: localityId, kind: kind),
        mode: InsertMode.insertOrIgnore,
      );

  /// 手入力した大字のローマ字を辞書に溜める。
  Future<void> _rememberRomaji(PlaceInfo place) async {
    final code = place.municipalityCode;
    final ja = _clean(place.localityJa);
    final en = _clean(place.localityEn);
    if (code == null || ja == null || en == null) return;
    await rememberPlaceRomaji(_db, municipalityCode: code, localityJa: ja, localityEn: en);
  }

  static String? _clean(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}
