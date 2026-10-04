import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/gsi/municipality_directory.dart';
import 'services/service_providers.dart';

/// 自治体の対応表の場所(pubspec.yaml の assets に登録してある)。
const municipalitiesAsset = 'assets/data/municipalities.json';

// `async` な main。起動前に対応表を読み込んでから画面を出す。
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final directory = JsonMunicipalityDirectory.parse(
    await rootBundle.loadString(municipalitiesAsset),
  );

  // ProviderScope は Riverpod の Provider を保持する入れ物(Spring の ApplicationContext に近い)。
  // overrides で、起動時に作った対応表を Provider に差し込む。
  runApp(
    ProviderScope(
      overrides: [municipalityDirectoryProvider.overrideWithValue(directory)],
      child: const BioLabelMapApp(),
    ),
  );
}
