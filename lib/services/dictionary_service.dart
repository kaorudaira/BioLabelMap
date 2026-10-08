import 'package:drift/drift.dart';

import '../core/db/database.dart';
import '../domain/dictionary.dart';
import '../domain/species_name.dart';

/// 同じ内容の候補がすでにある(編集の結果が重なる)。統合を案内する。
class DictionaryConflictException implements Exception {
  DictionaryConflictException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// 使用している標本の件数つきの辞書の候補(要件定義 S-10)。
class DictRow<T> {
  const DictRow(this.entry, this.usedBy);

  final T entry;

  /// この候補を使っている標本の数(ごみ箱を除く)。
  final int usedBy;
}

SpeciesName speciesNameOfEntry(SpeciesEntry e) => SpeciesName(
  vernacular: e.vernacular,
  genus: e.genus,
  species: e.species,
  subspecies: e.subspecies,
  authorship: e.authorship,
);

/// 地名・種・環境・寄主植物の辞書(要件定義 F-10・S-10)。
///
/// 辞書を変えても、保存済みの標本は変わらない。入力や同定のたびに候補が自動で溜まる。
class DictionaryService {
  DictionaryService(this._db);

  final AppDatabase _db;

  // ---- 候補を溜める・引く(S-02・S-06) ----

  /// 同定で入力した種名を辞書に溜める。同じ種名があれば使用回数を増やす。
  /// 和名も学名も空なら何もしない。
  Future<void> rememberSpecies(SpeciesName name) async {
    if (name.isEmpty) return;
    await _db.into(_db.speciesDict).insert(
      _speciesCompanion(name, useCount: 1),
      onConflict: DoUpdate.withExcluded(
        (old, excluded) => SpeciesDictCompanion.custom(
          useCount: old.useCount + const Constant(1),
          updatedAt: currentDateAndTime,
        ),
        target: _speciesKey,
      ),
    );
  }

  /// 環境・寄主植物の入力を辞書に溜める。空なら何もしない。
  Future<void> rememberText(DictTextKind kind, String? value) async {
    final v = value?.trim();
    if (v == null || v.isEmpty) return;
    await _db.into(_db.textDict).insert(
      TextDictCompanion.insert(kind: kind, value: v, useCount: const Value(1)),
      onConflict: DoUpdate.withExcluded(
        (old, excluded) => TextDictCompanion.custom(
          useCount: old.useCount + const Constant(1),
          updatedAt: currentDateAndTime,
        ),
        target: [_db.textDict.kind, _db.textDict.value],
      ),
    );
  }

  /// 和名・属・種・亜種のどれかに [query] を含む種名を、よく使う順に返す。
  /// [limit] が null なら、合うものを全て返す。
  /// 空白で区切った語は、すべてを含むものだけ。大文字小文字は区別しない。
  Future<List<SpeciesName>> suggestSpecies(String query, {int? limit = 5}) async {
    final words = _words(query);
    if (words.isEmpty) return const [];
    final rows =
        await (_db.select(_db.speciesDict)
              ..orderBy([(s) => OrderingTerm.desc(s.useCount), (s) => OrderingTerm.desc(s.updatedAt)]))
            .get();
    final found = [
      for (final r in rows)
        if (_matchesAll(words, [r.vernacular, r.genus, r.species, r.subspecies])) speciesNameOfEntry(r),
    ];
    return limit == null ? found : found.take(limit).toList();
  }

  /// [query] を含む環境・寄主植物を、よく使う順に返す。完全に同じものは除く。
  Future<List<String>> suggestText(DictTextKind kind, String query, {int limit = 5}) async {
    final words = _words(query);
    final rows =
        await (_db.select(_db.textDict)
              ..where((t) => t.kind.equals(kind.name))
              ..orderBy([(t) => OrderingTerm.desc(t.useCount), (t) => OrderingTerm.desc(t.updatedAt)]))
            .get();
    return [
      for (final r in rows)
        if (r.value != query.trim() && _matchesAll(words, [r.value])) r.value,
    ].take(limit).toList();
  }

  // ---- 辞書管理(S-10) ----

  Stream<void> _changes(Set<TableInfo> tables) =>
      _db.customSelect('SELECT 1', readsFrom: tables).watch();

  /// 地名のローマ字。大字の和名順。
  Stream<List<DictRow<PlaceRomajiEntry>>> watchPlaces() =>
      _changes({_db.placeRomajiDict, _db.localities, _db.specimens, _db.collectionEvents}).asyncMap((_) async {
        final rows = await (_db.select(_db.placeRomajiDict)
              ..orderBy([(p) => OrderingTerm.asc(p.municipalityCode), (p) => OrderingTerm.asc(p.localityJa)]))
            .get();
        final counts = await _db.customSelect(
          '''
          SELECT l.municipality_code AS code, l.locality_ja AS ja, COUNT(s.id) AS n
          FROM localities l
          JOIN collection_events e ON e.locality_id = l.id
          JOIN specimens s ON s.collection_event_id = e.id
          WHERE s.deleted_at IS NULL AND l.municipality_code IS NOT NULL AND l.locality_ja IS NOT NULL
          GROUP BY l.municipality_code, l.locality_ja
          ''',
          readsFrom: {_db.localities, _db.collectionEvents, _db.specimens},
        ).get();
        final byKey = {for (final c in counts) '${c.read<String>('code')}\u0000${c.read<String>('ja')}': c.read<int>('n')};
        return [for (final r in rows) DictRow(r, byKey['${r.municipalityCode}\u0000${r.localityJa}'] ?? 0)];
      });

  /// 大字のローマ字を直す。空にはできない。
  Future<void> updatePlaceRomaji(int id, String localityEn) async {
    final en = localityEn.trim();
    if (en.isEmpty) throw ArgumentError.value(localityEn, 'localityEn', 'ローマ字を入力してください');
    await (_db.update(_db.placeRomajiDict)..where((p) => p.id.equals(id))).write(
      PlaceRomajiDictCompanion(localityEn: Value(en), updatedAt: Value(DateTime.now())),
    );
  }

  Future<void> deletePlace(int id) => (_db.delete(_db.placeRomajiDict)..where((p) => p.id.equals(id))).go();

  /// 種。属・種の学名順(学名の無いものは和名順で後ろ)。使用件数は、最新の同定がその種名の標本の数。
  Stream<List<DictRow<SpeciesEntry>>> watchSpecies() =>
      _changes({_db.speciesDict, _db.identifications, _db.specimens}).asyncMap((_) async {
        final rows = await _db.select(_db.speciesDict).get();
        final latest = <int, Identification>{};
        final ids = await (_db.select(_db.identifications)..orderBy([(i) => OrderingTerm.desc(i.id)])).get();
        final alive = {
          for (final s in await (_db.select(_db.specimens)..where((s) => s.deletedAt.isNull())).get()) s.id,
        };
        for (final i in ids) {
          if (alive.contains(i.specimenId)) latest.putIfAbsent(i.specimenId, () => i);
        }
        final counts = <SpeciesName, int>{};
        for (final i in latest.values) {
          counts.update(
            SpeciesName(
              vernacular: i.vernacularName,
              genus: i.genus,
              species: i.species,
              subspecies: i.subspecies,
              authorship: i.authorship,
            ),
            (n) => n + 1,
            ifAbsent: () => 1,
          );
        }
        final result = [for (final r in rows) DictRow(r, counts[speciesNameOfEntry(r)] ?? 0)]
          ..sort((a, b) => _speciesSortKey(a.entry).compareTo(_speciesSortKey(b.entry)));
        return result;
      });

  static String _speciesSortKey(SpeciesEntry e) {
    final sci = [e.genus, e.species, e.subspecies].where((s) => s.isNotEmpty).join(' ');
    return sci.isEmpty ? '￿${e.vernacular}' : sci.toLowerCase();
  }

  /// 種を辞書に足す。同じ内容があれば [DictionaryConflictException]。
  Future<void> addSpecies(SpeciesName name) async {
    if (name.isEmpty) throw ArgumentError('和名か学名を入力してください');
    try {
      await _db.into(_db.speciesDict).insert(_speciesCompanion(name));
    } catch (e) {
      if (_isUnique(e)) throw DictionaryConflictException('同じ種がすでにあります');
      rethrow;
    }
  }

  Future<void> updateSpecies(int id, SpeciesName name) async {
    if (name.isEmpty) throw ArgumentError('和名か学名を入力してください');
    try {
      await (_db.update(_db.speciesDict)..where((s) => s.id.equals(id))).write(
        _speciesCompanion(name).copyWith(updatedAt: Value(DateTime.now())),
      );
    } catch (e) {
      if (_isUnique(e)) throw DictionaryConflictException('同じ種がすでにあります。重複しているときは「統合」を使ってください');
      rethrow;
    }
  }

  Future<void> deleteSpecies(int id) => (_db.delete(_db.speciesDict)..where((s) => s.id.equals(id))).go();

  /// [keepId] に [mergeIds] を統合する。使用回数は合算し、統合された候補は消す。
  /// 保存済みの標本の同定は変わらない。
  Future<void> mergeSpecies(int keepId, Iterable<int> mergeIds) => _db.transaction(() async {
    final ids = mergeIds.toSet()..remove(keepId);
    if (ids.isEmpty) return;
    final merged = await (_db.select(_db.speciesDict)..where((s) => s.id.isIn(ids))).get();
    final extra = merged.fold<int>(0, (sum, e) => sum + e.useCount);
    await (_db.delete(_db.speciesDict)..where((s) => s.id.isIn(ids))).go();
    await (_db.update(_db.speciesDict)..where((s) => s.id.equals(keepId))).write(
      SpeciesDictCompanion.custom(
        useCount: _db.speciesDict.useCount + Constant(extra),
        updatedAt: currentDateAndTime,
      ),
    );
  });

  /// 環境・寄主植物。値の順。使用件数は、その文字列を持つ採集に属する標本の数。
  Stream<List<DictRow<TextDictEntry>>> watchTexts(DictTextKind kind) =>
      _changes({_db.textDict, _db.collectionEvents, _db.specimens}).asyncMap((_) async {
        final rows = await (_db.select(_db.textDict)
              ..where((t) => t.kind.equals(kind.name))
              ..orderBy([(t) => OrderingTerm.asc(t.value)]))
            .get();
        final column = kind == DictTextKind.habitat ? 'habitat' : 'host_plant';
        final counts = await _db.customSelect(
          '''
          SELECT e.$column AS v, COUNT(s.id) AS n
          FROM collection_events e JOIN specimens s ON s.collection_event_id = e.id
          WHERE s.deleted_at IS NULL AND e.$column IS NOT NULL
          GROUP BY e.$column
          ''',
          readsFrom: {_db.collectionEvents, _db.specimens},
        ).get();
        final byValue = {for (final c in counts) c.read<String>('v'): c.read<int>('n')};
        return [for (final r in rows) DictRow(r, byValue[r.value] ?? 0)];
      });

  Future<void> addText(DictTextKind kind, String value) async {
    final v = value.trim();
    if (v.isEmpty) throw ArgumentError.value(value, 'value', '入力してください');
    try {
      await _db.into(_db.textDict).insert(TextDictCompanion.insert(kind: kind, value: v));
    } catch (e) {
      if (_isUnique(e)) throw DictionaryConflictException('同じ候補がすでにあります');
      rethrow;
    }
  }

  Future<void> updateText(int id, String value) async {
    final v = value.trim();
    if (v.isEmpty) throw ArgumentError.value(value, 'value', '入力してください');
    try {
      await (_db.update(_db.textDict)..where((t) => t.id.equals(id))).write(
        TextDictCompanion(value: Value(v), updatedAt: Value(DateTime.now())),
      );
    } catch (e) {
      if (_isUnique(e)) throw DictionaryConflictException('同じ候補がすでにあります。重複しているときは「統合」を使ってください');
      rethrow;
    }
  }

  Future<void> deleteText(int id) => (_db.delete(_db.textDict)..where((t) => t.id.equals(id))).go();

  Future<void> mergeTexts(int keepId, Iterable<int> mergeIds) => _db.transaction(() async {
    final ids = mergeIds.toSet()..remove(keepId);
    if (ids.isEmpty) return;
    final merged = await (_db.select(_db.textDict)..where((t) => t.id.isIn(ids))).get();
    final extra = merged.fold<int>(0, (sum, e) => sum + e.useCount);
    await (_db.delete(_db.textDict)..where((t) => t.id.isIn(ids))).go();
    await (_db.update(_db.textDict)..where((t) => t.id.equals(keepId))).write(
      TextDictCompanion.custom(
        useCount: _db.textDict.useCount + Constant(extra),
        updatedAt: currentDateAndTime,
      ),
    );
  });

  // ---- 内部 ----

  List<GeneratedColumn> get _speciesKey => [
    _db.speciesDict.vernacular,
    _db.speciesDict.genus,
    _db.speciesDict.species,
    _db.speciesDict.subspecies,
    _db.speciesDict.authorship,
  ];

  SpeciesDictCompanion _speciesCompanion(SpeciesName n, {int useCount = 0}) => SpeciesDictCompanion.insert(
    vernacular: Value(n.vernacular ?? ''),
    genus: Value(n.genus ?? ''),
    species: Value(n.species ?? ''),
    subspecies: Value(n.subspecies ?? ''),
    authorship: Value(n.authorship ?? ''),
    useCount: Value(useCount),
  );

  static bool _isUnique(Object e) => e.toString().contains('UNIQUE');

  static List<String> _words(String q) =>
      q.trim().toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

  static bool _matchesAll(List<String> words, List<String> fields) {
    final haystack = fields.join(' ').toLowerCase();
    return words.every(haystack.contains);
  }
}
