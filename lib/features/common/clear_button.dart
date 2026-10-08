import 'package:flutter/material.dart';

/// 入力欄の右端に出す「×」(入力内容をクリアする)。何も入力していないときは出さない。
/// アプリのすべての入力欄に付ける。
class ClearButton extends StatelessWidget {
  const ClearButton({super.key, required this.controller, this.onCleared});

  final TextEditingController controller;

  /// クリアしたあと。`onChanged` は文字を打ったときにしか呼ばれないので、同じ処理をここでも呼ぶ。
  final VoidCallback? onCleared;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        if (value.text.isEmpty) return const SizedBox.shrink();
        return IconButton(
          tooltip: 'クリア',
          icon: const Icon(Icons.clear, size: 20),
          visualDensity: VisualDensity.compact,
          onPressed: () {
            controller.clear();
            onCleared?.call();
          },
        );
      },
    );
  }
}

/// [decoration] の右端に、入力内容をクリアする「×」を付ける。
InputDecoration withClear(
  InputDecoration decoration,
  TextEditingController controller, {
  VoidCallback? onCleared,
}) => decoration.copyWith(suffixIcon: ClearButton(controller: controller, onCleared: onCleared));
