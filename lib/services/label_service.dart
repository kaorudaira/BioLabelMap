import 'package:drift/drift.dart';

import '../core/db/database.dart';
import '../domain/elevation_rounding.dart';
import '../domain/label/collector_name_format.dart';
import '../domain/label/data_label_builder.dart';
import '../domain/label/data_label_layout.dart';
import '../domain/label/identification_label.dart';
import '../domain/models/collection_period.dart';
import '../domain/status.dart';
import 'locality_lookup_service.dart';
import 'specimen_service.dart' show speciesNameOf;

/// ラベル出力の候補になる標本1件(標本・採集・地点をまとめたもの)。
class LabelCandidate {
  const LabelCandidate(this.specimen, this.event, this.locality, [this.identification]);

  final Specimen specimen;
  final CollectionEvent event;
  final Locality locality;

  /// 最新の同定。未同定なら null。
  final Identification? identification;

  /// 同定ラベルの材料。種名(和名か学名)が無い、未同定の標本は null。
  IdentificationLabelSource? get identificationSource {
    final source = IdentificationLabelSource(
      name: speciesNameOf(identification),
      identifiedBy: identification?.identifiedBy,
    );
    return source.isLabelable ? source : null;
  }

  bool get printed => specimen.printedAt != null;

  /// 標高か地名が、まだ取得できていない(補完待ち)。
  bool get pendingEnrichment =>
      locality.elevationStatus == FetchStatus.pending ||
      locality.placeStatus == FetchStatus.pending;

  /// 大字は取得できたが、そのローマ字が未入力。
  /// 圏外で記録して、あとから地名を補完した初めての場所で起きる。
  bool get missingLocalityRomaji =>
      (locality.localityJa?.trim().isNotEmpty ?? false) &&
      (locality.localityEn?.trim().isEmpty ?? true);

  /// データラベルの材料。標高は設定の丸めで丸め、採集者名は `K. YOSHIHARA` の形にする。
  DataLabelSource toSource(ElevationRounding rounding) => DataLabelSource(
    country: locality.country,
    prefectureEn: locality.prefectureEn,
    countyEn: locality.countyEn,
    municipalityEn: locality.municipalityEn,
    localityEn: locality.localityEn,
    elevationMeters: switch (locality.elevationMeters) {
      final double e => rounding.apply(e),
      null => null,
    },
    latitude: locality.latitude,
    longitude: locality.longitude,
    period: CollectionPeriod(event.startDate, event.endDate),
    collector: switch (event.collector) {
      final String c when c.trim().isNotEmpty => formatCollectorName(c),
      _ => null,
    },
    countyJa: locality.countyJa,
    municipalityJa: locality.municipalityJa,
    localityJa: locality.localityJa,
  );
}

/// ラベル出力(要件定義 S-07)のための問い合わせと、印刷済みの記録。
class LabelService {
  LabelService(this._db);

  final AppDatabase _db;

  /// ごみ箱を除く標本を、標本番号順に返す。DB が変わるたびに流れ直す。
  Stream<List<LabelCandidate>> watchCandidates() => _db
      .changesOf({_db.specimens, _db.collectionEvents, _db.localities, _db.identifications})
      .asyncMap((_) => _load());

  Future<List<LabelCandidate>> _load() async {
    final query = _db.select(_db.specimens).join([
      innerJoin(_db.collectionEvents, _db.collectionEvents.id.equalsExp(_db.specimens.collectionEventId)),
      innerJoin(_db.localities, _db.localities.id.equalsExp(_db.collectionEvents.localityId)),
    ])
      ..where(_db.specimens.deletedAt.isNull())
      ..orderBy([OrderingTerm.asc(_db.specimens.catalogNumber)]);
    // ↑ join は SQL の JOIN。readTable で各テーブルの行を取り出す(JPA の Tuple に近い)
    final rows = await query.get();

    // 同定ラベルには、標本ごとの最新の同定を使う(id の大きい順に読み、最初の1件を取る)
    final latest = <int, Identification>{};
    final ids = await (_db.select(_db.identifications)..orderBy([(i) => OrderingTerm.desc(i.id)])).get();
    for (final i in ids) {
      latest.putIfAbsent(i.specimenId, () => i);
    }
    return [
      for (final row in rows)
        LabelCandidate(
          row.readTable(_db.specimens),
          row.readTable(_db.collectionEvents),
          row.readTable(_db.localities),
          latest[row.readTable(_db.specimens).id],
        ),
    ];
  }

  /// 大字のローマ字を入れる。辞書にも溜め、同じ大字でローマ字が未入力の
  /// ほかの地点にも同じ綴りを入れる(辞書があれば補完で入るのと同じ結果にする)。
  Future<void> setLocalityRomaji(int localityId, String localityEn) {
    final en = localityEn.trim();
    if (en.isEmpty) {
      throw ArgumentError.value(localityEn, 'localityEn', 'ローマ字を入力してください');
    }
    return _db.transaction(() async {
      final locality = await (_db.select(_db.localities)..where((l) => l.id.equals(localityId))).getSingle();
      final code = locality.municipalityCode;
      final ja = locality.localityJa;

      await (_db.update(_db.localities)..where((l) => l.id.equals(localityId)))
          .write(LocalitiesCompanion(localityEn: Value(en)));
      if (code == null || ja == null) return;

      await rememberPlaceRomaji(_db, municipalityCode: code, localityJa: ja, localityEn: en);
      await (_db.update(_db.localities)
            ..where(
              (l) =>
                  l.municipalityCode.equals(code) &
                  l.localityJa.equals(ja) &
                  (l.localityEn.isNull() | l.localityEn.trim().equals('')),
            ))
          .write(LocalitiesCompanion(localityEn: Value(en)));
    });
  }

  /// 印刷済みにする。印字した標高と地名を標本ごとに残し、
  /// のちに補完や修正で値が変わったら「ラベルと不一致」にできるようにする(要件定義 第13章)。
  Future<void> markPrinted(Map<int, DataLabelLayout> printedLabels, {DateTime? now}) {
    final printedAt = now ?? DateTime.now();
    return _db.transaction(() async {
      for (final MapEntry(key: specimenId, value: layout) in printedLabels.entries) {
        await (_db.update(_db.specimens)..where((s) => s.id.equals(specimenId))).write(
          SpecimensCompanion(
            printedAt: Value(printedAt),
            printedElevation: Value(printedElevationOf(layout)),
            printedPlace: Value(printedPlaceOf(layout)),
          ),
        );
      }
    });
  }
}

/// 印字した標高(`(alt. 1390 m)`)。印字していなければ空文字。
String printedElevationOf(DataLabelLayout layout) {
  final match = RegExp(r'\(alt\. (-?\d+) m\)').firstMatch(layout.lines.map((l) => l.text).join(' '));
  return match?.group(1) ?? '';
}

/// 印字した地名(県・詳細住所・日本語の地名)。
String printedPlaceOf(DataLabelLayout layout) => layout.lines
    .where((l) => switch (l.role) {
      DataLabelLineRole.header || DataLabelLineRole.address || DataLabelLineRole.japanese => true,
      _ => false,
    })
    .map((l) => l.text)
    .join(' ');
