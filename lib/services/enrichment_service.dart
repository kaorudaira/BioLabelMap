import 'package:drift/drift.dart';

import '../core/db/database.dart';
import '../core/gsi/gsi_api.dart';
import '../core/gsi/municipality_directory.dart';
import '../domain/status.dart';

/// 補完を1回実行した結果。
class EnrichmentRunSummary {
  const EnrichmentRunSummary({
    this.fetched = 0,
    this.unavailable = 0,
    this.failed = 0,
  });

  /// 取得できた件数。
  final int fetched;

  /// 通信は成功したがデータが無かった件数(「取得不可」にした)。
  final int unavailable;

  /// 通信エラーで失敗した件数(再試行を予約した)。
  final int failed;
}

/// 補完待ちの標高・地名を、通信が戻ったときに取得する(要件定義 第13章)。
///
/// いつ実行するかは呼び出し側が決める。
/// - きっかけ(アプリを開いた・前面に戻った・通信が戻った・「今すぐ補完」): `run(triggered: true)`
/// - 再試行の予約時刻が来た: `run(triggered: false)`。予約時刻は [nextScheduledAttempt] で取れる
class EnrichmentService {
  EnrichmentService(
    this._db,
    this._api,
    this._directory, {
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;
  // `DateTime Function()` は「引数なしで DateTime を返す関数」の型。
  // Java の `Supplier<LocalDateTime>` に相当し、テストで時刻を固定するために受け取る。

  final AppDatabase _db;
  final GsiApi _api;
  final MunicipalityDirectory _directory;
  final DateTime Function() _clock;

  /// 通信エラー後の自動再試行の間隔。3回までで、その後は次のきっかけを待つ。
  static const retryDelays = [
    Duration(minutes: 1),
    Duration(minutes: 5),
    Duration(minutes: 30),
  ];

  /// 実行中に重ねて呼ばれたときは、同じ実行を待つ。
  Future<EnrichmentRunSummary>? _running;

  /// 補完待ちの地点の数(地図画面の表示用)。
  Stream<int> watchPendingLocalityCount() {
    final count = _db.enrichmentQueue.localityId.count(distinct: true);
    return (_db.selectOnly(_db.enrichmentQueue)..addColumns([count]))
        .map((row) => row.read(count) ?? 0)
        .watchSingle();
  }

  /// 次に自動で再試行する時刻。予約が無ければ null。
  Future<DateTime?> nextScheduledAttempt() async {
    final earliest = _db.enrichmentQueue.nextAttemptAt.min();
    final row = await (_db.selectOnly(_db.enrichmentQueue)
          ..addColumns([earliest]))
        .getSingle();
    return row.read(earliest);
  }

  /// 補完を実行する。地理院への負荷を抑えるため、1件ずつ順に呼ぶ。
  Future<EnrichmentRunSummary> run({required bool triggered}) {
    // `??=` は「null なら代入する」。実行中なら、その Future をそのまま返す。
    return _running ??= _run(triggered).whenComplete(() => _running = null);
  }

  Future<EnrichmentRunSummary> _run(bool triggered) async {
    final now = _clock();
    final query = _db.select(_db.enrichmentQueue)
      ..orderBy([(t) => OrderingTerm.asc(t.id)]);
    if (!triggered) {
      query.where(
        (t) => t.nextAttemptAt.isNotNull() & t.nextAttemptAt.isSmallerOrEqualValue(now),
      );
    }
    final tasks = await query.get();

    var fetched = 0, unavailable = 0, failed = 0;
    for (final task in tasks) {
      // きっかけによる実行は、再試行の回数を数え直す
      final attemptsBefore = triggered ? 0 : task.attempts;
      try {
        final outcome = await _process(task);
        if (outcome) {
          fetched++;
        } else {
          unavailable++;
        }
      } on GsiNetworkException catch (e) {
        failed++;
        await _scheduleRetry(task, attemptsBefore + 1, e.message);
      }
    }
    return EnrichmentRunSummary(
      fetched: fetched,
      unavailable: unavailable,
      failed: failed,
    );
  }

  /// 1件を処理する。取得できたら true、データが無ければ false。
  /// 通信エラーは GsiNetworkException のまま投げる。
  Future<bool> _process(EnrichmentTask task) async {
    final locality = await (_db.select(_db.localities)
          ..where((l) => l.id.equals(task.localityId)))
        .getSingle();

    switch (task.kind) {
      case EnrichmentKind.elevation:
        // 手入力した値は上書きしない
        if (locality.elevationStatus == FetchStatus.manual) {
          await _complete(task, null);
          return true;
        }
        final outcome = await _api.fetchElevation(
          locality.latitude,
          locality.longitude,
        );
        await _complete(
          task,
          switch (outcome) {
            Found(:final value) => LocalitiesCompanion(
              elevationMeters: Value(value),
              elevationStatus: const Value(FetchStatus.fetched),
            ),
            NotAvailable() => const LocalitiesCompanion(
              elevationStatus: Value(FetchStatus.unavailable),
            ),
          },
        );
        return outcome is Found;

      case EnrichmentKind.place:
        if (locality.placeStatus == FetchStatus.manual) {
          await _complete(task, null);
          return true;
        }
        final outcome = await _api.fetchAddress(
          locality.latitude,
          locality.longitude,
        );
        await _complete(
          task,
          switch (outcome) {
            Found(:final value) => await _placeUpdate(locality, value),
            NotAvailable() => const LocalitiesCompanion(
              placeStatus: Value(FetchStatus.unavailable),
            ),
          },
        );
        return outcome is Found;
    }
  }

  Future<LocalitiesCompanion> _placeUpdate(
    Locality locality,
    GsiAddress address,
  ) async {
    final names = _directory.lookup(address.municipalityCode);

    // 大字のローマ字がまだ無ければ、辞書から補う
    var localityEn = locality.localityEn;
    if (localityEn == null && address.localityJa != null) {
      final entry = await (_db.select(_db.placeRomajiDict)
            ..where(
              (d) =>
                  d.municipalityCode.equals(address.municipalityCode) &
                  d.localityJa.equals(address.localityJa!),
            ))
          .getSingleOrNull();
      localityEn = entry?.localityEn;
    }

    return LocalitiesCompanion(
      municipalityCode: Value(address.municipalityCode),
      prefectureJa: Value(names?.prefectureJa),
      countyJa: Value(names?.countyJa),
      municipalityJa: Value(names?.municipalityJa),
      localityJa: Value(address.localityJa),
      prefectureEn: Value(names?.prefectureEn),
      countyEn: Value(names?.countyEn),
      municipalityEn: Value(names?.municipalityEn),
      localityEn: Value(localityEn),
      placeStatus: const Value(FetchStatus.fetched),
    );
  }

  /// 地点を更新し、キューから消す。
  Future<void> _complete(EnrichmentTask task, LocalitiesCompanion? update) {
    return _db.transaction(() async {
      if (update != null) {
        await (_db.update(_db.localities)
              ..where((l) => l.id.equals(task.localityId)))
            .write(update);
      }
      await (_db.delete(_db.enrichmentQueue)
            ..where((t) => t.id.equals(task.id)))
          .go();
    });
  }

  Future<void> _scheduleRetry(EnrichmentTask task, int attempts, String error) {
    // 3回を超えたら予約しない(次のきっかけを待つ)
    final next = attempts <= retryDelays.length
        ? _clock().add(retryDelays[attempts - 1])
        : null;
    return (_db.update(_db.enrichmentQueue)..where((t) => t.id.equals(task.id)))
        .write(
          EnrichmentQueueCompanion(
            attempts: Value(attempts),
            nextAttemptAt: Value(next),
            lastError: Value(error),
          ),
        );
  }
}
