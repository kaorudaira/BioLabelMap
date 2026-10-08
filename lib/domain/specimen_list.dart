import 'models/calendar_date.dart';
import 'models/collection_period.dart';
import 'sampling_method.dart';
import 'species_name.dart';
import 'status.dart';

/// 標本一覧(要件定義 S-04)に並べる標本1件。画面と DB に依存しない形にしてある。
class SpecimenListItem {
  const SpecimenListItem({
    required this.id,
    required this.catalogNumber,
    required this.catalogText,
    required this.localityId,
    required this.period,
    required this.method,
    required this.methodLabel,
    required this.species,
    required this.status,
    required this.placeJa,
    required this.placeEn,
    required this.printed,
    this.deletedAt,
    this.labelMismatch = false,
    this.latE4 = 0,
    this.lonE4 = 0,
  });

  final int id;
  /// 標本番号。null は番号未確定(仮)で、確定の操作で付ける(要件定義 第14章)。
  final int? catalogNumber;
  final String? catalogText;

  bool get provisional => catalogNumber == null;

  /// 画面に出す標本番号。仮は「番号未確定」。
  String get catalogDisplay => catalogText ?? provisionalLabel;

  /// 保存した順に並べるための値。確定済みは番号の順、仮は確定済みの後ろで、保存した順(ID)。
  (int, int) get orderKey => (catalogNumber == null ? 1 : 0, catalogNumber ?? id);
  final int localityId;
  final CollectionPeriod period;
  final SamplingMethod method;

  /// 「その他」のときは自由入力の名前。
  final String methodLabel;

  /// 最新の同定の種名。同定が無ければ [SpeciesName.unidentified]。
  final SpeciesName species;
  final IdentificationStatus status;

  /// 県・市町村・大字を続けた和文の地名。取得前は空。
  final String placeJa;
  final String placeEn;
  final bool printed;

  /// ごみ箱に移した日時。ごみ箱の外の標本は null。
  final DateTime? deletedAt;

  /// 印刷したラベルの標高・地名が、いまの値と食い違っている(要件定義 第13章)。
  final bool labelMismatch;

  /// 地点の判定キー(緯度経度を小数4桁で切り捨てて1万倍した整数)。同じキーの地点は、同じ場所として1つのピンにまとめる。
  final int latE4;
  final int lonE4;
}

/// 番号が未確定(仮)の標本の表示(要件定義 第14章)。
const provisionalLabel = '番号未確定';

int _byOrderKey(SpecimenListItem a, SpecimenListItem b) {
  final x = a.orderKey, y = b.orderKey;
  return x.$1 != y.$1 ? x.$1.compareTo(y.$1) : x.$2.compareTo(y.$2);
}

/// 種・採集日・場所・採集方法が同じ標本を1行にまとめたもの。
class SpecimenGroup {
  SpecimenGroup(List<SpecimenListItem> items)
    : assert(items.isNotEmpty),
      items = List.unmodifiable(<SpecimenListItem>[...items]..sort(_byOrderKey));

  /// 標本番号順。番号が未確定(仮)の標本は、確定済みの後ろに、保存した順に並べる。
  final List<SpecimenListItem> items;

  SpecimenListItem get first => items.first;
  int get count => items.length;

  /// 標本番号を、連続する範囲ごとにまとめた表示。例: `KYC00120〜122, KYC00125`。
  /// 番号は標本ごとに作成時の書式で保存してあるので、その文字列から作る
  /// (接頭辞を後で変えても、既存の標本は元の番号で表示する)。
  /// 番号が未確定の標本は、最後に「番号未確定 N件」と添える。
  String get catalogRuns {
    final runs = <List<SpecimenListItem>>[];
    for (final item in items.where((i) => !i.provisional)) {
      if (runs.isNotEmpty && runs.last.last.catalogNumber! + 1 == item.catalogNumber) {
        runs.last.add(item);
      } else {
        runs.add([item]);
      }
    }
    final parts = runs.map((run) {
      final first = run.first;
      final last = run.last;
      if (identical(first, last)) return first.catalogText!;
      // 同じ接頭辞なら、終わりは数字だけにして短くする(`KYC00120〜122`)
      String prefixOf(String text) => text.replaceFirst(RegExp(r'\d+$'), '');
      final samePrefix = prefixOf(first.catalogText!) == prefixOf(last.catalogText!);
      return '${first.catalogText}〜${samePrefix ? '${last.catalogNumber}' : last.catalogText}';
    }).toList()
      ..addAll([if (provisionalCount > 0) provisionalCount == count ? provisionalLabel : '$provisionalLabel $provisionalCount件']);
    return parts.join(', ');
  }

  /// 番号が未確定(仮)の標本の数。
  int get provisionalCount => items.where((i) => i.provisional).length;

  /// 1件でも未印刷があれば、その行に未印刷のマークを付ける。
  bool get hasUnprinted => items.any((i) => !i.printed);

  /// 1件でも「ラベルと不一致」があれば、その行に印を付ける。
  bool get hasLabelMismatch => items.any((i) => i.labelMismatch);
}

/// 同じ種・採集日(期間)・地点・採集方法の標本を1つにまとめる。
/// 行の並びは、各グループの最初の標本が現れた順。
List<SpecimenGroup> groupSpecimens(Iterable<SpecimenListItem> items) {
  final groups = <String, List<SpecimenListItem>>{};
  for (final item in items) {
    final key = [
      item.localityId,
      item.period.toIso(),
      item.methodLabel,
      item.species.key,
      item.status.name,
    ].join('\u0001');
    (groups[key] ??= []).add(item);
  }
  return [for (final list in groups.values) SpecimenGroup(list)];
}

/// 標本一覧の並び(要件定義 S-04)。
enum SpecimenSort {
  dateDesc('採集日(新しい順)'),
  catalog('標本番号順'),
  species('種ごと'),
  place('場所順');

  const SpecimenSort(this.label);
  final String label;
}

/// 検索と絞り込み(要件定義 S-04)。空の条件は無視する。
class SpecimenFilter {
  const SpecimenFilter({
    this.query = '',
    this.place = '',
    this.from,
    this.to,
    this.methods = const {},
    this.statuses = const {},
    this.unprintedOnly = false,
    this.mismatchOnly = false,
  });

  /// 種名・地名・標本番号を横断して探す。
  final String query;

  /// 地名で絞り込む。
  final String place;

  /// 採集日の範囲。標本の期間が、この範囲に少しでも重なれば残す。
  final CalendarDate? from;
  final CalendarDate? to;
  final Set<SamplingMethod> methods;
  final Set<IdentificationStatus> statuses;
  final bool unprintedOnly;

  /// 「ラベルと不一致」の標本だけ。
  final bool mismatchOnly;

  /// 検索語以外の絞り込み条件が1つでもあるか(画面上部に条件を示すかの判定)。
  bool get hasConditions =>
      place.trim().isNotEmpty ||
      from != null ||
      to != null ||
      methods.isNotEmpty ||
      statuses.isNotEmpty ||
      unprintedOnly ||
      mismatchOnly;

  bool get isActive => hasConditions || query.trim().isNotEmpty;

  SpecimenFilter copyWith({
    String? query,
    String? place,
    Object? from = _keep,
    Object? to = _keep,
    Set<SamplingMethod>? methods,
    Set<IdentificationStatus>? statuses,
    bool? unprintedOnly,
    bool? mismatchOnly,
  }) => SpecimenFilter(
    query: query ?? this.query,
    place: place ?? this.place,
    from: identical(from, _keep) ? this.from : from as CalendarDate?,
    to: identical(to, _keep) ? this.to : to as CalendarDate?,
    methods: methods ?? this.methods,
    statuses: statuses ?? this.statuses,
    unprintedOnly: unprintedOnly ?? this.unprintedOnly,
    mismatchOnly: mismatchOnly ?? this.mismatchOnly,
  );

  static const _keep = Object();

  bool matches(SpecimenListItem item) {
    if (unprintedOnly && item.printed) return false;
    if (mismatchOnly && !item.labelMismatch) return false;
    if (methods.isNotEmpty && !methods.contains(item.method)) return false;
    if (statuses.isNotEmpty && !statuses.contains(item.status)) return false;
    if (from != null && item.period.end.isBefore(from!)) return false;
    if (to != null && to!.isBefore(item.period.start)) return false;
    if (!_contains('${item.placeJa} ${item.placeEn}', place)) return false;
    return _matchesQuery(item);
  }

  /// 空白で区切った語は、すべてに合致する標本だけを残す。
  bool _matchesQuery(SpecimenListItem item) {
    final words = query.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    if (words.isEmpty) return true;
    final haystack = [
      item.species.vernacular,
      item.species.scientific,
      item.placeJa,
      item.placeEn,
      item.catalogText,
      if (item.provisional) provisionalLabel,
    ].whereType<String>().join(' ').toLowerCase();
    return words.every((w) => haystack.contains(w.toLowerCase()));
  }

  static bool _contains(String text, String word) {
    final w = word.trim().toLowerCase();
    return w.isEmpty || text.toLowerCase().contains(w);
  }
}

/// 絞り込んだ標本をまとめ、指定の並びにする。同じ並びの中は、標本番号の小さい順。
List<SpecimenGroup> arrangeSpecimens(
  Iterable<SpecimenListItem> items, {
  SpecimenFilter filter = const SpecimenFilter(),
  SpecimenSort sort = SpecimenSort.dateDesc,
}) {
  final groups = groupSpecimens(items.where(filter.matches));
  int byCatalog(SpecimenGroup a, SpecimenGroup b) => _byOrderKey(a.first, b.first);
  int byDateDesc(SpecimenGroup a, SpecimenGroup b) {
    final c = b.first.period.end.compareTo(a.first.period.end);
    return c != 0 ? c : b.first.period.start.compareTo(a.first.period.start);
  }

  int compare(SpecimenGroup a, SpecimenGroup b) {
    final primary = switch (sort) {
      SpecimenSort.dateDesc => byDateDesc(a, b),
      SpecimenSort.catalog => 0,
      // 未同定は最後に回す
      SpecimenSort.species => _speciesOrder(a).compareTo(_speciesOrder(b)),
      SpecimenSort.place => a.first.placeJa.compareTo(b.first.placeJa),
    };
    return primary != 0 ? primary : byCatalog(a, b);
  }

  return groups..sort(compare);
}

String _speciesOrder(SpecimenGroup g) {
  final s = g.first.species;
  if (s.isEmpty) return '￿';
  return s.scientific ?? s.vernacular!;
}

/// 採集日の表示。1日なら `2026/6/20`、期間なら `2026/6/19〜20`(月や年をまたぐときは終わりも補う)。
/// [withYear] を false にすると、年を省く(`6/19〜20`)。
String formatPeriodText(CollectionPeriod period, {bool withYear = true}) {
  final s = period.start;
  final e = period.end;
  String md(CalendarDate d) => '${d.month}/${d.day}';
  String ymd(CalendarDate d) => '${d.year}/${md(d)}';
  final head = withYear ? ymd(s) : md(s);
  if (period.isSingleDay) return head;
  if (s.year != e.year) return withYear ? '$head〜${ymd(e)}' : '$head〜${md(e)}';
  if (s.month != e.month) return '$head〜${md(e)}';
  return '$head〜${e.day}';
}

/// 県・郡・市町村・大字を続けた和文の地名。取得前の項目は飛ばす。
String formatPlaceJa({String? prefecture, String? county, String? municipality, String? locality}) =>
    [prefecture, county, municipality, locality]
        .whereType<String>()
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .join();

/// 標本の採集日の範囲(いちばん早い開始日〜いちばん遅い終了日)。標本が無ければ null。
CollectionPeriod? periodSpanOf(Iterable<SpecimenListItem> items) {
  CalendarDate? start, end;
  for (final i in items) {
    if (start == null || i.period.start.isBefore(start)) start = i.period.start;
    if (end == null || end.isBefore(i.period.end)) end = i.period.end;
  }
  return start == null ? null : CollectionPeriod(start, end!);
}

/// ローマ字の住所。県から順に並べる(県, 郡, 市町村, 大字)。取得前の項目は飛ばす。
String formatPlaceEn({String? prefecture, String? county, String? municipality, String? locality}) =>
    [prefecture, county, municipality, locality]
        .whereType<String>()
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .join(', ');

/// 緯度経度の表示。北緯・南緯は °N・°S、東経・西経は °E・°W をつける(例:`36.94471°N 139.24258°E`)。
String formatLatLon(double latitude, double longitude, {int digits = 5}) =>
    '${latitude.abs().toStringAsFixed(digits)}°${latitude < 0 ? 'S' : 'N'} '
    '${longitude.abs().toStringAsFixed(digits)}°${longitude < 0 ? 'W' : 'E'}';

/// 地図の吹き出しに出す、登録されている和名の一覧(件数つき)。
///
/// 同じ種は1行にまとめ、件数の多い順(同じなら和名の50音順)に並べる。和名が無い種は学名を、
/// 同定が無い標本は「未同定」を、最後にまとめる。[maxLines] を超える種は、「ほかN種」にまとめる。
List<String> speciesSummaryLines(Iterable<SpecimenListItem> items, {int maxLines = 4}) {
  final bySpecies = <SpeciesName, int>{};
  var unidentified = 0;
  for (final i in items) {
    if (i.species.isEmpty) {
      unidentified++;
    } else {
      bySpecies.update(i.species, (n) => n + 1, ifAbsent: () => 1);
    }
  }
  final species = bySpecies.entries.toList()
    ..sort((a, b) {
      final c = b.value.compareTo(a.value);
      return c != 0 ? c : compareByVernacular(a.key, b.key);
    });
  String line(String name, int n) => n > 1 ? '$name ×$n' : name;
  final lines = [for (final e in species) line(e.key.vernacular ?? e.key.scientific!, e.value)];
  final tail = unidentified > 0 ? line('未同定', unidentified) : null;

  final room = tail == null ? maxLines : maxLines - 1;
  if (lines.length <= room) return [...lines, ?tail];
  // 入りきらない種は「ほかN種」にまとめる(その行も、1行に数える)
  final shown = room - 1;
  return [...lines.take(shown), 'ほか${lines.length - shown}種', ?tail];
}
