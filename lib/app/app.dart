import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/onboarding/onboarding_screen.dart';
import '../services/service_providers.dart';
import 'router.dart';
import 'theme.dart';

/// アプリの入口。初回設定が済むまでは初回設定画面だけを出す(要件定義 第14章)。
class BioLabelMapApp extends ConsumerStatefulWidget {
  const BioLabelMapApp({super.key});

  @override
  ConsumerState<BioLabelMapApp> createState() => _BioLabelMapAppState();
}

class _BioLabelMapAppState extends ConsumerState<BioLabelMapApp> {
  late final GoRouter _router = buildRouter();
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // アプリを開いたとき・前面に戻ったときに、補完待ちを取得する(要件定義 第13章)
    _lifecycle = AppLifecycleListener(onResume: _enrich);
    WidgetsBinding.instance.addPostFrameCallback((_) => _enrich());
  }

  void _enrich() => unawaited(ref.read(enrichmentSchedulerProvider).trigger());

  @override
  void dispose() {
    _lifecycle.dispose();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final initialized = settings.value?.nextCatalogNumber != null;

    const localizations = [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ];
    const locales = [Locale('ja')];

    if (!settings.hasValue) {
      return MaterialApp(
        theme: buildTheme(),
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }
    if (!initialized) {
      return MaterialApp(
        title: 'BioLabelMap',
        theme: buildTheme(),
        localizationsDelegates: localizations,
        supportedLocales: locales,
        home: const OnboardingScreen(),
      );
    }
    return MaterialApp.router(
      title: 'BioLabelMap',
      theme: buildTheme(),
      localizationsDelegates: localizations,
      supportedLocales: locales,
      routerConfig: _router,
    );
  }
}
