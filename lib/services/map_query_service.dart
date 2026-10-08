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
  /// 同じ場所(緯度経度を小数4桁で切り捨てたキーが同じ)の標本は、地点の行が複数あっても、
  /// 1つのピンにまとめる。地名の修正で標本の一部だけを別の地点に付け替えると、同じ座標に地点の行が
  /// 増えるが、ピンが重なって隠れないようにするため。ピンの地点は、その場所のいちばん古い地点にする。
  /// 未同定は「最新の同定が、仮同定・同定済みのいずれでもない(同定が無い、または未同定)」標本。
  Stream<List<LocalityPin>> watchPins() => _db
      .customSelect(
        '''
        SELECT r.id AS id, r.latitude AS latitude, r.longitude AS longitude,
               t.specimen_count AS specimen_count, t.unidentified_count AS unidentified_count
        FROM (
          SELECT MIN(l.id) AS rep_id,
                 COUNT(s.id) AS specimen_count,
                 SUM(CASE WHEN EXISTS (
                       SELECT 1 FROM identifications i
                       WHERE i.specimen_id = s.id
                         AND i.id = (SELECT MAX(x.id) FROM identifications x WHERE x.specimen_id = s.id)
                         AND i.status <> 'unidentified'
                     ) THEN 0 ELSE 1 END) AS unidentified_count
          FROM localities l
          JOIN collection_events e ON e.locality_id = l.id
          JOIN specimens s ON s.collection_event_id = e.id
          WHERE s.deleted_at IS NULL
          GROUP BY l.lat_e4, l.lon_e4
        ) t
        JOIN localities r ON r.id = t.rep_id
        ORDER BY r.id
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
