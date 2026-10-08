import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../domain/status.dart';

/// 同定の状態の印。和名(和名が無ければ学名)の左に付ける。
/// 同定済みは緑のチェックマーク、仮同定は三角の中にビックリマーク。未同定は何も付けない。
class StatusMark extends StatelessWidget {
  const StatusMark(this.status, {super.key, this.size = 20});

  final IdentificationStatus status;
  final double size;

  static const _gap = 4.0;

  /// 印の幅(印と文字の間を含む)。印の無い行も、この幅を空けて文字の開始位置をそろえる。
  static double slotWidth(double size) => size + _gap;

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = switch (status) {
      IdentificationStatus.verified => (Icons.check_circle, verifiedColor, '同定済み'),
      IdentificationStatus.provisional => (Icons.warning_rounded, provisionalColor, '仮同定'),
      IdentificationStatus.unidentified => (null, null, null),
    };
    // 印が無い状態(未同定)でも、同じ幅を空けて、他の項目と文字の開始位置をそろえる
    if (icon == null) return SizedBox(width: slotWidth(size));
    return Padding(
      padding: const EdgeInsets.only(right: _gap),
      child: Icon(icon, size: size, color: color, semanticLabel: label),
    );
  }
}
