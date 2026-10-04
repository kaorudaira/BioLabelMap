import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../core/db/database_provider.dart';
import '../core/gsi/gsi_api.dart';
import '../core/gsi/municipality_directory.dart';
import 'draft_service.dart';
import 'enrichment_service.dart';
import 'record_service.dart';
import 'settings_service.dart';

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

final gsiApiProvider = Provider((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return GsiApi(client);
});

/// 自治体の対応表。アプリ起動時に assets から読み込んで差し替える(main.dart で override する)。
final municipalityDirectoryProvider = Provider<MunicipalityDirectory>(
  (ref) => throw UnimplementedError('起動時に override してください'),
);

final enrichmentServiceProvider = Provider(
  (ref) => EnrichmentService(
    ref.watch(databaseProvider),
    ref.watch(gsiApiProvider),
    ref.watch(municipalityDirectoryProvider),
  ),
);
