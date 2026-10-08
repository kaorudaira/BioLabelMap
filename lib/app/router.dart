import 'package:go_router/go_router.dart';

import '../features/backup/backup_screen.dart';
import '../features/label/label_screen.dart';
import '../features/map/map_screen.dart';
import '../features/offline/offline_area_new_screen.dart';
import '../features/offline/offline_maps_screen.dart';
import '../features/record/record_screen.dart';
import '../features/settings/settings_screen.dart';

/// 画面の道筋(要件定義 第9章)。段階1は地図・記録・ラベル出力・設定・バックアップ。
GoRouter buildRouter() => GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const MapScreen()),
    GoRoute(path: '/labels', builder: (context, state) => const LabelScreen()),
    GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
    GoRoute(path: '/backup', builder: (context, state) => const BackupScreen()),
    GoRoute(path: '/offline', builder: (context, state) => const OfflineMapsScreen()),
    GoRoute(path: '/offline/new', builder: (context, state) => const OfflineAreaNewScreen()),
    GoRoute(
      path: '/record',
      // `extra` で渡した RecordArgs を受け取る(URL には載せない)
      builder: (context, state) => RecordScreen(args: state.extra! as RecordArgs),
    ),
  ],
);
