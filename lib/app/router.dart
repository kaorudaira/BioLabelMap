import 'package:go_router/go_router.dart';

import '../features/map/map_screen.dart';
import '../features/record/record_screen.dart';

/// 画面の道筋(要件定義 第9章)。段階1は地図と記録のみ。
GoRouter buildRouter() => GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const MapScreen()),
    GoRoute(
      path: '/record',
      // `extra` で渡した RecordArgs を受け取る(URL には載せない)
      builder: (context, state) => RecordScreen(args: state.extra! as RecordArgs),
    ),
  ],
);
