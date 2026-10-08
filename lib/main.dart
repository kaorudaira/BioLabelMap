import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'app/app.dart';
import 'core/gsi/municipality_directory.dart';
import 'core/gsi/oaza_romaji_table.dart';
import 'core/tiles/offline_tile_store.dart';
import 'services/service_providers.dart';

/// 自治体の対応表の場所(pubspec.yaml の assets に登録してある)。
const municipalitiesAsset = 'assets/data/municipalities.json';

/// 大字のローマ字の対応表(公的データ)の場所。
const oazaRomajiAsset = 'assets/data/oaza_romaji.json';

// `async` な main。起動前に対応表を読み込んでから画面を出す。
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final directory = JsonMunicipalityDirectory.parse(
    await rootBundle.loadString(municipalitiesAsset),
  );
  // 大字の表は約3MBあるので、画面を止めないよう別の Isolate(Java のスレッドに近い)で読む
  final oazaSource = await rootBundle.loadString(oazaRomajiAsset);
  final oaza = await Isolate.run(() => OazaRomajiTable.parse(oazaSource));

  // オフライン地図のタイルは、端末のアプリ専用フォルダに置く
  final support = await getApplicationSupportDirectory();
  final tileStore = OfflineTileStore(Directory('${support.path}/offline_tiles'));

  // ProviderScope は Riverpod の Provider を保持する入れ物(Spring の ApplicationContext に近い)。
  // overrides で、起動時に作った対応表を Provider に差し込む。
  runApp(
    ProviderScope(
      overrides: [
        municipalityDirectoryProvider.overrideWithValue(directory),
        oazaRomajiTableProvider.overrideWithValue(oaza),
        offlineTileStoreProvider.overrideWithValue(tileStore),
      ],
      child: const BioLabelMapApp(),
    ),
  );
}
