import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 地名のローマ字に使う文字(要件定義 第5章「ローマ字表記」)。
const placeNameCharacters = ['ō', 'ū', 'Ō', 'Ū'];

/// 人名(命名者・同定者)に使う文字。マクロンのほか、昆虫の命名者の表記に出る
/// アクセント付きの文字(Chûjô、Itô、Candèze、Jałoszyński など)を並べる。
/// 2行に収めるため、小さなボタンで並べる。
const personNameCharacters = [
  // マクロン(日本人の名前)
  'ō', 'ū', 'Ō', 'Ū', 'ā', 'ē', 'ī',
  // サーカムフレックス(古い表記の日本人の名前:Chûjô、Itô)
  'ô', 'û', 'Ô', 'Û', 'â', 'ê', 'î',
  // ウムラウト・エスツェット(ドイツ語圏の名前)
  'ä', 'ö', 'ü', 'ß',
  // アクセント・セディーユ・チルダ(フランス語・スペイン語など)
  'é', 'è', 'ç', 'ñ',
  // 北欧・東欧の文字
  'ø', 'å', 'ł', 'š',
];

/// マクロン付きの文字などを入れるボタン(要件定義 第5章「ローマ字表記」)。
/// [personNames] を true にすると、人名に使う文字も並べる(小さなボタンで2行に収める)。
class MacronButtons extends StatelessWidget {
  const MacronButtons({
    super.key,
    required this.controller,
    required this.onInserted,
    this.personNames = false,
  });

  final TextEditingController controller;
  final VoidCallback onInserted;

  /// 人名(命名者・同定者)の欄用。地名のローマ字の欄は、false のまま(ō ū Ō Ū のみ)。
  final bool personNames;

  void _insert(String c) {
    final sel = controller.selection;
    final text = controller.text;
    final start = sel.isValid ? sel.start : text.length;
    final end = sel.isValid ? sel.end : text.length;
    controller.value = TextEditingValue(
      text: text.replaceRange(start, end, c),
      selection: TextSelection.collapsed(offset: start + c.length),
    );
    HapticFeedback.selectionClick();
    onInserted();
  }

  @override
  Widget build(BuildContext context) {
    if (!personNames) {
      return Wrap(
        spacing: 6,
        children: [
          for (final c in placeNameCharacters)
            ActionChip(
              label: Text(c, style: const TextStyle(fontSize: 18)),
              onPressed: () => _insert(c),
            ),
        ],
      );
    }
    // 小さなボタン。2行に収まるよう、幅に合わせて1つの幅を決める(最小20、最大32)
    const spacing = 2.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final perRow = (personNameCharacters.length / 2).ceil();
        final fit = (constraints.maxWidth - spacing * (perRow - 1)) / perRow;
        final width = fit.isFinite
            ? fit.clamp(20.0, 32.0).floorToDouble()
            : 24.0;
        return Wrap(
          spacing: spacing,
          runSpacing: 2,
          children: [
            for (final c in personNameCharacters)
              SizedBox(
                width: width,
                height: 32,
                child: OutlinedButton(
                  onPressed: () => _insert(c),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(fontSize: 15),
                  ),
                  child: Text(c),
                ),
              ),
          ],
        );
      },
    );
  }
}
