import '../core/db/database.dart';

/// 地図に立てる、過去の採集地点のピン(要件定義 F-02)。
class LocalityPin {
  const LocalityPin({
    required this.localityId,
    required this.latitude,
    required this.longitude,
    required this.specimenCount,
    required this.unidentifiedCount,
  });

  final int localityId;
  final double latitude;
  final double longitude;

  /// この地点の標本の数(ごみ箱を除く)。
  final int specimenCount;

  /// そのうち未同定の数。1件でもあればピンの色を変える。
  final int unidentifiedCount;
}

/// 地図画面で使う問い合わせ。
class MapQueryService {
  MapQueryService(this._db);

  final AppDatabase _db;

  /// 標本がある地点を、件数付きで返す。DB が変わるたびに流れ直す。
  ///
  /// 同じ地点の標本は1つのピンにまとめる(地点のテーブルが小数4桁で同一地点をまとめている)。
  /// 未同定は「仮同定・同定済みの同定が1件も無い」標本。
  Stream<List<LocalityPin>> watchPins() => _db
      .customSelect(
        '''
        SELECT l.id AS id, l.latitude AS latitude, l.longitude AS longitude,
               COUNT(s.id) AS specimen_count,
               SUM(CASE WHEN EXISTS (
                     SELECT 1 FROM identifications i
                     WHERE i.specimen_id = s.id AND i.status <> 'unidentified'
                   ) THEN 0 ELSE 1 END) AS unidentified_count
        FROM localities l
        JOIN collection_events e ON e.locality_id = l.id
        JOIN specimens s ON s.collection_event_id = e.id
        WHERE s.deleted_at IS NULL
        GROUP BY l.id
        ''',
        readsFrom: {
          _db.localities,
          _db.collectionEvents,
          _db.specimens,
          _db.identifications,
        },
      )
      .watch()
      .map(
        (rows) => [
          for (final row in rows)
            LocalityPin(
              localityId: row.read<int>('id'),
              latitude: row.read<double>('latitude'),
              longitude: row.read<double>('longitude'),
              specimenCount: row.read<int>('specimen_count'),
              unidentifiedCount: row.read<int>('unidentified_count'),
            ),
        ],
      );
}
