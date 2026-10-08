import 'package:drift/drift.dart';

import '../core/db/database.dart';
import '../domain/locality_key.dart';
import '../domain/models/collection_period.dart';
import '../domain/sampling_method.dart';
import '../domain/status.dart';
import '../domain/trash.dart';

/// 値を変えるか(変えるなら、新しい値。null で空にする)。「変えない」は、この箱ごと null にして表す。
class Change<T> {
  const Change(this.value);

  final T value;
}

/// 地名の項目。県・郡・市町村・大字の和文と英語表記。
enum PlaceField {
  prefectureJa('県(和)'),
  countyJa('郡(和)'),
  municipalityJa('市町村(和)'),
  localityJa('大字(和)'),
  prefectureEn('県(英)'),
  countyEn('郡(英)'),
  municipalityEn('市町村(英)'),
  localityEn('大字(ローマ字)');

  const PlaceField(this.label);
  final String label;
}

/// 標本の修正内容(要件定義 S-04「一括編集」・S-05「編集」)。null の項目は変えない。
class SpecimenEdit {
  const SpecimenEdit({
    this.period,
    this.method,
    this.methodOther,
    this.lightSource,
    this.bait,
    this.habitat,
    this.hostPlant,
    this.sex,
    this.remarks,
    this.place = const {},
    this.position,
  });

  // 採集に属する項目(同じ採集を共有する標本は、いっしょに変わる。一部だけ直すときは採集を複製する)
  final CollectionPeriod? period;
  final SamplingMethod? method;
  final Change<String?>? methodOther;
  final Change<String?>? lightSource;
  final Change<String?>? bait;
  final Change<String?>? habitat;
  final Change<String?>? hostPlant;

  // 標本に属する項目
  final Change<Sex?>? sex;
  final Change<String?>? remarks;

  /// 地名。入っている項目だけ変える(値が null か空なら、その項目を空にする)。
  final Map<PlaceField, String?> place;

  /// 座標。直すと、標高と地名は取り直す(補完待ちに入れる)。地名も同時に直したときは、その地名を残す。
  final ({double latitude, double longitude})? position;

  bool get changesEvent =>
      period != null ||
      method != null ||
      methodOther != null ||
      lightSource != null ||
      bait != null ||
      habitat != null ||
      hostPlant != null;

  bool get changesSpecimen => sex != null || remarks != null;

  bool get isEmpty => !changesEvent && !changesSpecimen && place.isEmpty && position == null;
}

/// 修正・ごみ箱・完全な削除(要件定義 S-04・S-05・第12章)。
class SpecimenEditService {
  SpecimenEditService(this._db);

  final AppDatabase _db;

  static String? _clean(String? s) {
    final t = s?.trim();
    return t == null || t.isEmpty ? null : t;
  }

  // ---- 修正 ----

  /// 選んだ標本に [edit] を反映する。1つのトランザクションで書く。
  ///
  /// 採集は、選んだ標本が採集を共有する標本の全部なら、その採集を直す。一部だけなら、
  /// 選んだ標本のために採集を複製して付け替え、複製のほうを直す(他の標本は変わらない)。
  /// 地名も同じで、選んでいない採集が使っている地点は、複製して付け替える。
  /// 手で直した地名は「手入力」にして、補完で上書きしない。
  Future<void> apply(Iterable<int> specimenIds, SpecimenEdit edit) {
    final ids = specimenIds.toSet();
    if (ids.isEmpty) throw ArgumentError('標本を選んでください');
    if (edit.isEmpty) return Future.value();

    return _db.transaction(() async {
      final specimens = await (_db.select(_db.specimens)..where((s) => s.id.isIn(ids))).get();
      if (specimens.length != ids.length) throw StateError('見つからない標本があります');

      if (edit.changesSpecimen) {
        await (_db.update(_db.specimens)..where((s) => s.id.isIn(ids))).write(
          SpecimensCompanion(
            sex: edit.sex == null ? const Value.absent() : Value(edit.sex!.value),
            remarks: edit.remarks == null ? const Value.absent() : Value(_clean(edit.remarks!.value)),
          ),
        );
      }
      if (!edit.changesEvent && edit.place.isEmpty && edit.position == null) return;

      // 1. 採集ごとに、直す採集(そのまま、または複製)を決める
      final editedEvents = <int>{};
      for (final eventId in {for (final s in specimens) s.collectionEventId}) {
        final selected = [for (final s in specimens) if (s.collectionEventId == eventId) s.id];
        final all = await (_db.select(_db.specimens)..where((s) => s.collectionEventId.equals(eventId))).get();
        if (all.length == selected.length) {
          editedEvents.add(eventId);
          continue;
        }
        final original = await (_db.select(_db.collectionEvents)..where((e) => e.id.equals(eventId))).getSingle();
        final copyId = await _db.into(_db.collectionEvents).insert(original.toCompanion(false).copyWith(
          id: const Value.absent(),
          createdAt: Value(DateTime.now()),
        ));
        await (_db.update(_db.specimens)..where((s) => s.id.isIn(selected))).write(
          SpecimensCompanion(collectionEventId: Value(copyId)),
        );
        editedEvents.add(copyId);
      }

      // 2. 採集の項目を直す
      if (edit.changesEvent) {
        await (_db.update(_db.collectionEvents)..where((e) => e.id.isIn(editedEvents))).write(
          CollectionEventsCompanion(
            startDate: edit.period == null ? const Value.absent() : Value(edit.period!.start),
            endDate: edit.period == null ? const Value.absent() : Value(edit.period!.end),
            samplingMethod: edit.method == null ? const Value.absent() : Value(edit.method!),
            samplingMethodOther: _text(edit.methodOther),
            lightSource: _text(edit.lightSource),
            bait: _text(edit.bait),
            habitat: _text(edit.habitat),
            hostPlant: _text(edit.hostPlant),
          ),
        );
      }

      // 3. 地名・座標を直す。選んでいない採集が使っている地点は、複製して付け替える
      if (edit.place.isNotEmpty || edit.position != null) {
        final events = await (_db.select(_db.collectionEvents)..where((e) => e.id.isIn(editedEvents))).get();
        for (final localityId in {for (final e in events) e.localityId}) {
          final users = await (_db.select(_db.collectionEvents)..where((e) => e.localityId.equals(localityId))).get();
          final mine = [for (final e in events) if (e.localityId == localityId) e.id];
          var target = localityId;
          if (users.length != mine.length) {
            final original = await (_db.select(_db.localities)..where((l) => l.id.equals(localityId))).getSingle();
            target = await _db.into(_db.localities).insert(original.toCompanion(false).copyWith(
              id: const Value.absent(),
              createdAt: Value(DateTime.now()),
            ));
            await (_db.update(_db.collectionEvents)..where((e) => e.id.isIn(mine))).write(
              CollectionEventsCompanion(localityId: Value(target)),
            );
          }
          await (_db.update(_db.localities)..where((l) => l.id.equals(target))).write(_localityCompanion(edit));
          if (edit.position != null) {
            await _enqueue(target, EnrichmentKind.elevation);
            if (edit.place.isEmpty) await _enqueue(target, EnrichmentKind.place);
          }
        }
      }
    });
  }

  Value<String?> _text(Change<String?>? c) => c == null ? const Value.absent() : Value(_clean(c.value));

  Future<void> _enqueue(int localityId, EnrichmentKind kind) => _db.into(_db.enrichmentQueue).insert(
    EnrichmentQueueCompanion.insert(localityId: localityId, kind: kind),
    mode: InsertMode.insertOrIgnore,
  );

  /// 地点に書く内容。座標を直したときは、標高と(地名を直していなければ)地名を空にして、取り直しに回す。
  LocalitiesCompanion _localityCompanion(SpecimenEdit edit) {
    var companion = edit.place.isEmpty ? const LocalitiesCompanion() : _placeCompanion(edit.place);
    if (edit.position case final p?) {
      final key = LocalityKey.fromCoordinates(p.latitude, p.longitude);
      companion = companion.copyWith(
        latitude: Value(p.latitude),
        longitude: Value(p.longitude),
        latE4: Value(key.latE4),
        lonE4: Value(key.lonE4),
        isManualPosition: const Value(true),
        accuracyMeters: const Value(null),
        elevationMeters: const Value(null),
        elevationStatus: const Value(FetchStatus.pending),
        // 地名を直していなければ、新しい座標で取り直す
        prefectureJa: edit.place.isEmpty ? const Value(null) : companion.prefectureJa,
        countyJa: edit.place.isEmpty ? const Value(null) : companion.countyJa,
        municipalityJa: edit.place.isEmpty ? const Value(null) : companion.municipalityJa,
        localityJa: edit.place.isEmpty ? const Value(null) : companion.localityJa,
        prefectureEn: edit.place.isEmpty ? const Value(null) : companion.prefectureEn,
        countyEn: edit.place.isEmpty ? const Value(null) : companion.countyEn,
        municipalityEn: edit.place.isEmpty ? const Value(null) : companion.municipalityEn,
        localityEn: edit.place.isEmpty ? const Value(null) : companion.localityEn,
        municipalityCode: edit.place.isEmpty ? const Value(null) : const Value.absent(),
        placeStatus: edit.place.isEmpty ? const Value(FetchStatus.pending) : companion.placeStatus,
      );
    }
    return companion;
  }

  LocalitiesCompanion _placeCompanion(Map<PlaceField, String?> place) {
    Value<String?> v(PlaceField f) => place.containsKey(f) ? Value(_clean(place[f])) : const Value.absent();
    return LocalitiesCompanion(
      prefectureJa: v(PlaceField.prefectureJa),
      countyJa: v(PlaceField.countyJa),
      municipalityJa: v(PlaceField.municipalityJa),
      localityJa: v(PlaceField.localityJa),
      prefectureEn: v(PlaceField.prefectureEn),
      countyEn: v(PlaceField.countyEn),
      municipalityEn: v(PlaceField.municipalityEn),
      localityEn: v(PlaceField.localityEn),
      // 手で直した地名は、補完で上書きしない
      placeStatus: const Value(FetchStatus.manual),
    );
  }

  /// 採集の、番号が未確定(仮)の標本の数を、[count] 件にそろえる(要件定義 第14章)。
  /// 増やすときは、仮の標本を足す。減らすときは、保存した順の新しいほうから、仮の標本を削除する
  /// (番号を使っていないので欠番にならず、ごみ箱にも入れない)。[keepSpecimenId] の標本と、
  /// 同定の履歴がある標本は、減らさない。減らしきれないときは、何も変えずにエラーにする。
  Future<void> setProvisionalCount(int eventId, int count, {int? keepSpecimenId}) {
    if (count < 1) throw ArgumentError.value(count, 'count', '個体数は1以上です');
    return _db.transaction(() async {
      final provisional =
          await (_db.select(_db.specimens)
                ..where((s) => s.collectionEventId.equals(eventId) & s.catalogNumber.isNull() & s.deletedAt.isNull())
                ..orderBy([(s) => OrderingTerm.asc(s.id)]))
              .get();
      if (count > provisional.length) {
        for (var i = provisional.length; i < count; i++) {
          await _db.into(_db.specimens).insert(SpecimensCompanion.insert(collectionEventId: eventId));
        }
        return;
      }
      final withHistory = {
        for (final i in await _db.select(_db.identifications).get()) i.specimenId,
      };
      final removable = [
        for (final s in provisional.reversed)
          if (s.id != keepSpecimenId && !withHistory.contains(s.id)) s.id,
      ];
      final needed = provisional.length - count;
      if (removable.length < needed) {
        throw StateError('同定の入力がある標本は減らせません。先に、その標本をごみ箱に移してください');
      }
      await (_db.delete(_db.specimens)..where((s) => s.id.isIn(removable.take(needed)))).go();
    });
  }

  // ---- ごみ箱 ----

  /// 標本をごみ箱に移す。標本番号はそのまま残る。
  Future<void> moveToTrash(Iterable<int> specimenIds, {DateTime? now}) =>
      (_db.update(_db.specimens)..where((s) => s.id.isIn(specimenIds.toSet())))
          .write(SpecimensCompanion(deletedAt: Value(now ?? DateTime.now())));

  /// ごみ箱から、元の標本番号のまま戻す。
  Future<void> restore(Iterable<int> specimenIds) =>
      (_db.update(_db.specimens)..where((s) => s.id.isIn(specimenIds.toSet())))
          .write(const SpecimensCompanion(deletedAt: Value(null)));

  /// ごみ箱の標本を完全に削除する(ごみ箱の外の標本は消さない)。
  /// 同定の履歴と、標本が無くなった採集も消す。標本番号は欠番になり、再利用しない
  /// (次の番号は増える一方なので、番号が戻ることはない)。
  Future<int> deletePermanently(Iterable<int> specimenIds) => _db.transaction(() async {
    final trashed = await (_db.select(_db.specimens)
          ..where((s) => s.id.isIn(specimenIds.toSet()) & s.deletedAt.isNotNull()))
        .get();
    if (trashed.isEmpty) return 0;
    final ids = [for (final s in trashed) s.id];
    final events = {for (final s in trashed) s.collectionEventId};
    await (_db.delete(_db.identifications)..where((i) => i.specimenId.isIn(ids))).go();
    await (_db.delete(_db.specimens)..where((s) => s.id.isIn(ids))).go();
    for (final eventId in events) {
      final rest = await (_db.select(_db.specimens)..where((s) => s.collectionEventId.equals(eventId))).get();
      if (rest.isEmpty) await (_db.delete(_db.collectionEvents)..where((e) => e.id.equals(eventId))).go();
    }
    return ids.length;
  });

  /// 保持期間を過ぎた標本を、完全に削除する。アプリを開いたときに呼ぶ。削除した件数を返す。
  Future<int> purgeExpired({DateTime? now, int retentionDays = trashRetentionDays}) async {
    final at = now ?? DateTime.now();
    final trashed = await (_db.select(_db.specimens)..where((s) => s.deletedAt.isNotNull())).get();
    final due = [for (final s in trashed) if (isPurgeDue(s.deletedAt!, at, retentionDays: retentionDays)) s.id];
    return due.isEmpty ? 0 : deletePermanently(due);
  }
}
