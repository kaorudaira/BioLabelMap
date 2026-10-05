import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// マクロン付きの文字を入れるボタン(要件定義 第5章「ローマ字表記」)。
class MacronButtons extends StatelessWidget {
  const MacronButtons({super.key, required this.controller, required this.onInserted});

  final TextEditingController controller;
  final VoidCallback onInserted;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      children: [
        for (final c in const ['ō', 'ū', 'Ō', 'Ū'])
          ActionChip(
            label: Text(c, style: const TextStyle(fontSize: 18)),
            onPressed: () {
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
            },
          ),
      ],
    );
  }
}
