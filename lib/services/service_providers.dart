import 'dart:async';

import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../core/db/database.dart';
import '../core/db/database_provider.dart';
import '../core/gsi/gsi_api.dart';
import '../core/gsi/municipality_directory.dart';
import '../core/gsi/oaza_romaji_table.dart';
import '../core/label/label_pdf.dart';
import '../core/tiles/offline_tile_store.dart';
import '../domain/specimen_list.dart';
import '../domain/species_catalog.dart';
import 'backup_service.dart';
import 'dictionary_service.dart';
import 'draft_service.dart';
import 'identification_service.dart';
import 'enrichment_service.dart';
import 'label_service.dart';
import 'locality_lookup_service.dart';
import 'map_query_service.dart';
import 'offline_map_service.dart';
import 'record_service.dart';
import 'settings_service.dart';
import 'specimen_service.dart';

// サービスの Provider。`ref.watch(他の Provider)` で依存を受け取る。
// Spring のコンストラクタインジェクションと同じ考え方。

final settingsServiceProvider = Provider(
  (ref) => SettingsService(ref.watch(databaseProvider)),
);

final recordServiceProvider = Provider(
  (ref) => RecordService(ref.watch(databaseProvider)),
);

final draftServiceProvider = Provider(
  (ref) => DraftService(ref.watch(databaseProvider)),
);

final mapQueryServiceProvider = Provider(
  (ref) => MapQueryService(ref.watch(databaseProvider)),
);

final backupServiceProvider = Provider(
  (ref) => BackupService(ref.watch(databaseProvider)),
);

final labelServiceProvider = Provider(
  (ref) => LabelService(ref.watch(databaseProvider)),
);

/// ラベル用のフォント(約5MB)。ラベル出力を初めて開いたときに読み込む。
final labelFontsProvider = FutureProvider((ref) => LabelFonts.load());

final specimenServiceProvider = Provider(
  (ref) => SpecimenService(ref.watch(databaseProvider)),
);

final dictionaryServiceProvider = Provider(
  (ref) => DictionaryService(ref.watch(databaseProvider)),
);

final identificationServiceProvider = Provider(
  (ref) => IdentificationService(ref.watch(databaseProvider), ref.watch(dictionaryServiceProvider)),
);

/// 甲虫の和名・学名の目録(同定入力の自動入力に使う)。同梱の CSV を、初めて使うときに読み込む。
/// 約1.2MB で、読み込みに0.2秒ほどかかるので、別のスレッドで読む。
final speciesCatalogProvider = FutureProvider<SpeciesCatalog>((ref) async {
  final csv = await rootBundle.loadString('assets/data/beetles_master.csv');
  return compute(parseCatalogCsv, csv);
});

final gsiApiProvider = Provider((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return GsiApi(client);
});

/// 自治体の対応表。アプリ起動時に assets から読み込んで差し替える(main.dart で override する)。
final municipalityDirectoryProvider = Provider<MunicipalityDirectory>(
  (ref) => throw UnimplementedError('起動時に override してください'),
);

/// 大字のローマ字の対応表(公的データ)。アプリ起動時に assets から読み込んで差し替える。
/// 差し替えないとき(テストなど)は空の表になる。
final oazaRomajiTableProvider = Provider<OazaRomajiTable>((ref) => OazaRomajiTable.empty);

final localityLookupServiceProvider = Provider(
  (ref) => LocalityLookupService(
    ref.watch(databaseProvider),
    ref.watch(gsiApiProvider),
    ref.watch(municipalityDirectoryProvider),
    oaza: ref.watch(oazaRomajiTableProvider),
  ),
);

final enrichmentServiceProvider = Provider(
  (ref) => EnrichmentService(
    ref.watch(databaseProvider),
    ref.watch(gsiApiProvider),
    ref.watch(municipalityDirectoryProvider),
    oaza: ref.watch(oazaRomajiTableProvider),
  ),
);

// ---- 画面が監視する値(StreamProvider は DB が変わるたびに新しい値を流す) ----

final settingsProvider = StreamProvider<AppSettingsRow>(
  (ref) => ref.watch(settingsServiceProvider).watch(),
);

final pendingLocalityCountProvider = StreamProvider<int>(
  (ref) => ref.watch(enrichmentServiceProvider).watchPendingLocalityCount(),
);

final draftsProvider = StreamProvider<List<Draft>>(
  (ref) => ref.watch(draftServiceProvider).watchAll(),
);

final localityPinsProvider = StreamProvider<List<LocalityPin>>(
  (ref) => ref.watch(mapQueryServiceProvider).watchPins(),
);

final specimenItemsProvider = StreamProvider<List<SpecimenListItem>>(
  (ref) => ref.watch(specimenServiceProvider).watchItems(),
);

final localityProvider = StreamProvider.family<Locality?, int>(
  (ref, id) => ref.watch(specimenServiceProvider).watchLocality(id),
);

final specimenDetailProvider = StreamProvider.family<SpecimenDetail?, int>(
  (ref, id) => ref.watch(specimenServiceProvider).watchDetail(id),
);

final labelCandidatesProvider =StreamProvider<List<LabelCandidate>>(
  (ref) => ref.watch(labelServiceProvider).watchCandidates(),
);

/// 補完キューを動かすきっかけを管理する(要件定義 第13章)。
///
/// - アプリを開いた・前面に戻った・「今すぐ補完」・記録を保存した: [trigger]
/// - 通信エラー後の再試行(1分後・5分後・30分後): 予約時刻にタイマーで実行
class EnrichmentScheduler {
  EnrichmentScheduler(this._service);

  final EnrichmentService _service;
  Timer? _timer;

  Future<EnrichmentRunSummary> trigger() => _runAndReschedule(triggered: true);

  Future<EnrichmentRunSummary> _runAndReschedule({required bool triggered}) async {
    _timer?.cancel();
    final summary = await _service.run(triggered: triggered);
    final next = await _service.nextScheduledAttempt();
    if (next != null) {
      final delay = next.difference(DateTime.now());
      _timer = Timer(
        delay.isNegative ? Duration.zero : delay,
        () => _runAndReschedule(triggered: false),
      );
    }
    return summary;
  }

  void dispose() => _timer?.cancel();
}

final enrichmentSchedulerProvider = Provider((ref) {
  final scheduler = EnrichmentScheduler(ref.watch(enrichmentServiceProvider));
  ref.onDispose(scheduler.dispose);
  return scheduler;
});

// ---- オフライン地図(S-08) ----

/// タイルを置く場所。アプリ起動時に端末のフォルダを決めて差し替える(main.dart で override する)。
final offlineTileStoreProvider = Provider<OfflineTileStore>(
  (ref) => throw UnimplementedError('起動時に override してください'),
);

final offlineMapServiceProvider = Provider((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return OfflineMapService(ref.watch(databaseProvider), ref.watch(offlineTileStoreProvider), client);
});

final offlineAreasProvider = StreamProvider<List<OfflineArea>>(
  (ref) => ref.watch(offlineMapServiceProvider).watchAll(),
);
