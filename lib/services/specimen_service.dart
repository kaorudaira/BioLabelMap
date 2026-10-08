import 'package:drift/drift.dart';

import '../core/db/database.dart';
import '../domain/models/collection_period.dart';
import '../domain/sampling_method.dart';
import '../domain/specimen_list.dart';
import '../domain/species_name.dart';
import '../domain/status.dart';

/// 標本詳細(要件定義 S-05)に出す、標本・採集・地点・同定履歴のひとまとまり。
class SpecimenDetail {
  const SpecimenDetail({
    required this.specimen,
    required this.event,
    required this.locality,
    required this.history,
  });

  final Specimen specimen;
  final CollectionEvent event;
  final Locality locality;

  /// 同定履歴。新しい順。上書きはせず積んでいくので、先頭が最新。
  final List<Identification> history;

  Identification? get latest => history.isEmpty ? null : history.first;

  CollectionPeriod get period => CollectionPeriod(event.startDate, event.endDate);
}

/// 同定の行から種名を作る。
SpeciesName speciesNameOf(Identification? i) => i == null
    ? SpeciesName.unidentified
    : SpeciesName(
        vernacular: i.vernacularName,
        genus: i.genus,
        species: i.species,
        subspecies: i.subspecies,
        authorship: i.authorship,
      );

/// 標本一覧・標本詳細のための問い合わせ(要件定義 S-04・S-05)。
class SpecimenService {
  SpecimenService(this._db);

  final AppDatabase _db;

  /// 標本・採集・地点・同定のどれかが変わるたびに、流れ直す合図。
  Stream<void> get _changes => _db
      .customSelect(
        'SELECT 1',
        readsFrom: {_db.specimens, _db.collectionEvents, _db.localities, _db.identifications},
      )
      .watch();

  /// 標本一覧に並べる標本。[trashed] が true ならごみ箱の中、false なら有効な標本。
  Stream<List<SpecimenListItem>> watchItems({bool trashed = false}) =>
      _changes.asyncMap((_) => _loadItems(trashed: trashed));

  /// 地点1件。見つからなければ null。
  Stream<Locality?> watchLocality(int localityId) => _db
      .customSelect('SELECT 1', readsFrom: {_db.localities})
      .watch()
      .asyncMap((_) => (_db.select(_db.localities)..where((l) => l.id.equals(localityId))).getSingleOrNull());

  /// 標本1件の詳細。見つからなければ null。
  Stream<SpecimenDetail?> watchDetail(int specimenId) => _changes.asyncMap((_) => _loadDetail(specimenId));

  /// 標本1件の詳細を、その時点の値で1回だけ読む。
  Future<SpecimenDetail?> detail(int specimenId) => _loadDetail(specimenId);

  Future<List<SpecimenListItem>> _loadItems({required bool trashed}) async {
    final query = _db.select(_db.specimens).join([
      innerJoin(_db.collectionEvents, _db.collectionEvents.id.equalsExp(_db.specimens.collectionEventId)),
      innerJoin(_db.localities, _db.localities.id.equalsExp(_db.collectionEvents.localityId)),
    ])..where(trashed ? _db.specimens.deletedAt.isNotNull() : _db.specimens.deletedAt.isNull());
    final rows = await query.get();

    // 最新の同定だけ使う。id の大きい順に読み、標本ごとに最初の1件を取る。
    final latest = <int, Identification>{};
    final ids = await (_db.select(_db.identifications)..orderBy([(i) => OrderingTerm.desc(i.id)])).get();
    for (final i in ids) {
      latest.putIfAbsent(i.specimenId, () => i);
    }

    return [
      for (final row in rows)
        _toItem(
          row.readTable(_db.specimens),
          row.readTable(_db.collectionEvents),
          row.readTable(_db.localities),
          latest[row.readTable(_db.specimens).id],
        ),
    ];
  }

  Future<SpecimenDetail?> _loadDetail(int specimenId) async {
    final query = _db.select(_db.specimens).join([
      innerJoin(_db.collectionEvents, _db.collectionEvents.id.equalsExp(_db.specimens.collectionEventId)),
      innerJoin(_db.localities, _db.localities.id.equalsExp(_db.collectionEvents.localityId)),
    ])..where(_db.specimens.id.equals(specimenId));
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    final history =
        await (_db.select(_db.identifications)
              ..where((i) => i.specimenId.equals(specimenId))
              ..orderBy([(i) => OrderingTerm.desc(i.id)]))
            .get();
    return SpecimenDetail(
      specimen: row.readTable(_db.specimens),
      event: row.readTable(_db.collectionEvents),
      locality: row.readTable(_db.localities),
      history: history,
    );
  }

  SpecimenListItem _toItem(Specimen s, CollectionEvent e, Locality l, Identification? latest) {
    final method = e.samplingMethod;
    final other = e.samplingMethodOther?.trim();
    return SpecimenListItem(
      id: s.id,
      catalogNumber: s.catalogNumber,
      catalogText: s.catalogText,
      localityId: l.id,
      period: CollectionPeriod(e.startDate, e.endDate),
      method: method,
      methodLabel: (method == SamplingMethod.other && other != null && other.isNotEmpty) ? other : method.nameJa,
      species: speciesNameOf(latest),
      status: latest?.status ?? IdentificationStatus.unidentified,
      placeJa: formatPlaceJa(
        prefecture: l.prefectureJa,
        county: l.countyJa,
        municipality: l.municipalityJa,
        locality: l.localityJa,
      ),
      placeEn: [l.localityEn, l.municipalityEn, l.countyEn, l.prefectureEn].whereType<String>().join(' '),
      printed: s.printedAt != null,
    );
  }
}
