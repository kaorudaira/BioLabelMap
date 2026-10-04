import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  // ProviderScope は Riverpod の Provider を保持する入れ物(Spring の ApplicationContext に近い)。
  runApp(const ProviderScope(child: BioLabelMapApp()));
}

/// 画面は次の段階で作る。いまは起動確認用の仮の画面。
class BioLabelMapApp extends StatelessWidget {
  const BioLabelMapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'BioLabelMap',
      home: Scaffold(body: Center(child: Text('BioLabelMap'))),
    );
  }
}
