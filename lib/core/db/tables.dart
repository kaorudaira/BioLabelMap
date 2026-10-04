import 'package:drift/drift.dart';

import '../../domain/elevation_rounding.dart';
import '../../domain/sampling_method.dart';
import '../../domain/status.dart';
import 'converters.dart';

// Drift のテーブル定義(要件定義 第12章)。
// JPA の @Entity に近いが、ここに書くのはスキーマだけで、行のクラス(Locality など)と
// 挿入用のクラス(LocalitiesCompanion など)は build_runner が database.g.dart に生成する。
// `IntColumn get id => integer()...();` の末尾の `()` は、列の定義を確定させる呼び出し。

/// 地点。緯度経度が小数4桁で同じなら同じ地点として再利用する。
@TableIndex(name: 'idx_localities_key', columns: {#latE4, #lonE4})
class Localities extends Table {
  IntColumn get id => integer().autoIncrement()();

  // 測地系は WGS84 固定。
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();

  /// 同一地点の判定キー(LocalityKey)。
  IntColumn get latE4 => integer()();
  IntColumn get lonE4 => integer()();

  /// GPS の精度(m)。手動で補正したときは null。
  RealColumn get accuracyMeters => real().nullable()();
  BoolColumn get isManualPosition =>
      boolean().withDefault(const Constant(false))();

  /// 標高(m)。丸める前の値を持ち、ラベル出力時に丸める。
  RealColumn get elevationMeters => real().nullable()();
  TextColumn get elevationStatus => textEnum<FetchStatus>()();

  TextColumn get country => text().withDefault(const Constant('JAPAN'))();

  /// 自治体コード(逆ジオコーダの muniCd)。県・市町村の英語名の変換に使う。
  TextColumn get municipalityCode => text().nullable()();
  TextColumn get prefectureJa => text().nullable()();

  /// 郡(町村のみ)。
  TextColumn get countyJa => text().nullable()();
  TextColumn get municipalityJa => text().nullable()();

  /// 大字(逆ジオコーダの lv01Nm)。
  TextColumn get localityJa => text().nullable()();
  TextColumn get prefectureEn => text().nullable()();
  TextColumn get countyEn => text().nullable()();
  TextColumn get municipalityEn => text().nullable()();

  /// 大字のローマ字。手入力し、辞書で補完する。
  TextColumn get localityEn => text().nullable()();
  TextColumn get placeStatus => textEnum<FetchStatus>()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// 採集。どの地点で、いつ、どうやって採ったか。複数の標本が同じ採集を共有する。
class CollectionEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get localityId => integer().references(Localities, #id)();

  /// 採集日。1日のみのときは endDate と同じ値を入れる。
  TextColumn get startDate => text().map(const CalendarDateConverter())();
  TextColumn get endDate => text().map(const CalendarDateConverter())();

  /// 記録した日時(端末時刻)。
  DateTimeColumn get recordedAt => dateTime()();

  TextColumn get samplingMethod => textEnum<SamplingMethod>()();

  /// 「その他」を選んだときの自由入力。
  TextColumn get samplingMethodOther => text().nullable()();
  TextColumn get lightSource => text().nullable()();
  TextColumn get bait => text().nullable()();
  TextColumn get habitat => text().nullable()();
  TextColumn get hostPlant => text().nullable()();

  /// 採集者名(英語表記、整形前)。
  TextColumn get collector => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// 標本。1標本=1レコード。個体数は1固定のため列を持たない。
class Specimens extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get collectionEventId =>
      integer().references(CollectionEvents, #id)();

  /// 標本番号の数値部分。
  IntColumn get catalogNumber => integer()();

  /// 作成時の書式で作った標本番号(`KYC00123`)。接頭辞を変えても変わらない。
  /// ごみ箱の中も含めて重複させない。
  TextColumn get catalogText => text().unique()();

  TextColumn get sex => textEnum<Sex>().nullable()();
  TextColumn get remarks => text().nullable()();

  /// ラベル(データ+コレクション)を印刷済みにした日時。
  DateTimeColumn get printedAt => dateTime().nullable()();

  /// 印刷時に印字した標高と地名。補完や修正で食い違ったら「ラベルと不一致」にする。
  TextColumn get printedElevation => text().nullable()();
  TextColumn get printedPlace => text().nullable()();

  /// ごみ箱に移した日時。null なら有効な標本。
  DateTimeColumn get deletedAt => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// 同定。標本ごとに履歴として積み、上書きしない。ラベルには最新を使う。
class Identifications extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get specimenId => integer().references(Specimens, #id)();

  TextColumn get vernacularName => text().nullable()();
  TextColumn get genus => text().nullable()();
  TextColumn get species => text().nullable()();
  TextColumn get subspecies => text().nullable()();

  /// 命名者・年。括弧の有無を含めて入力どおり保持する。
  TextColumn get authorship => text().nullable()();
  TextColumn get identifiedBy => text().nullable()();
  TextColumn get dateIdentified =>
      text().map(const CalendarDateConverter()).nullable()();
  TextColumn get status => textEnum<IdentificationStatus>()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// 補完待ち。標高・地名が未取得の地点と、その種類(要件定義 第13章)。
@DataClassName('EnrichmentTask')
class EnrichmentQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get localityId => integer().references(Localities, #id)();
  TextColumn get kind => textEnum<EnrichmentKind>()();

  /// 通信エラーで失敗した回数。3回まで自動で再試行する。
  IntColumn get attempts => integer().withDefault(const Constant(0))();

  /// 次に再試行してよい日時。null ならすぐ実行してよい。
  DateTimeColumn get nextAttemptAt => dateTime().nullable()();
  TextColumn get lastError => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  // Java の `@Table(uniqueConstraints = ...)` に相当。
  @override
  List<Set<Column>> get uniqueKeys => [
    {localityId, kind},
  ];
}

/// 下書き。記録画面のフォームを JSON で丸ごと持ち、標本番号は持たない。
class Drafts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get formJson => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// 設定。1行だけのテーブル(id は常に1)。
@DataClassName('AppSettingsRow')
class AppSettings extends Table {
  // check() の中の `id` は、Drift が列として解釈する(再帰呼び出しにはならない)。
  IntColumn get id =>
      // ignore: recursive_getters
      integer().withDefault(const Constant(1)).check(id.equals(1))();

  /// 採集者名(英語表記)。
  TextColumn get collectorName => text().nullable()();

  /// 同定者名の既定(最後に入力した名前)。
  TextColumn get lastIdentifier => text().nullable()();

  TextColumn get catalogPrefix => text().withDefault(const Constant('KYC'))();
  IntColumn get catalogDigits => integer().withDefault(const Constant(5))();

  /// 次に発行する標本番号。null の間は初回設定が済んでおらず、記録できない。
  IntColumn get nextCatalogNumber => integer().nullable()();

  TextColumn get elevationRounding => textEnum<ElevationRounding>().withDefault(
    Constant(ElevationRounding.tenMeters.name),
  )();

  /// 最後にバックアップを書き出した日時(スキーマ 2 で追加)。
  DateTimeColumn get lastBackupAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 大字のローマ字の辞書。自治体コード+和文の大字ごとに1件。
@DataClassName('PlaceRomajiEntry')
class PlaceRomajiDict extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get municipalityCode => text()();
  TextColumn get localityJa => text()();
  TextColumn get localityEn => text()();
  IntColumn get useCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
    {municipalityCode, localityJa},
  ];
}
