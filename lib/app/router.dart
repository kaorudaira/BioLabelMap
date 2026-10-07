import 'package:go_router/go_router.dart';

import '../features/backup/backup_screen.dart';
import '../features/dictionary/dictionary_screen.dart';
import '../features/identification/identify_screen.dart';
import '../features/label/label_screen.dart';
import '../features/map/map_screen.dart';
import '../features/offline/offline_area_new_screen.dart';
import '../features/offline/offline_maps_screen.dart';
import '../features/record/record_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/specimen/bulk_edit_screen.dart';
import '../features/specimen/locality_detail_screen.dart';
import '../features/specimen/specimen_detail_screen.dart';
import '../features/specimen/specimen_list_screen.dart';
import '../features/specimen/trash_screen.dart';

/// 画面の道筋(要件定義 第9章)。段階1は地図・記録・ラベル出力・設定・バックアップ。
GoRouter buildRouter() => GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const MapScreen()),
    GoRoute(
      path: '/labels',
      // `extra` に標本の ID の一覧を渡すと、その標本だけを対象にする
      builder: (context, state) => LabelScreen(specimenIds: (state.extra as List<int>?)?.toSet()),
    ),
    GoRoute(
      path: '/bulk-edit',
      builder: (context, state) => BulkEditScreen(args: state.extra! as BulkEditArgs),
    ),
    GoRoute(path: '/trash', builder: (context, state) => const TrashScreen()),
    GoRoute(path: '/dictionary', builder: (context, state) => const DictionaryScreen()),
    GoRoute(
      path: '/identify',
      builder: (context, state) => IdentifyScreen(args: state.extra! as IdentifyArgs),
    ),
    GoRoute(
      path: '/localities/:id',
      builder: (context, state) => LocalityDetailScreen(localityId: int.parse(state.pathParameters['id']!)),
    ),
    GoRoute(path: '/specimens', builder: (context, state) => const SpecimenListScreen()),
    GoRoute(
      path: '/specimens/:id',
      builder: (context, state) => SpecimenDetailScreen(specimenId: int.parse(state.pathParameters['id']!)),
    ),
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
