import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../domain/status.dart';

/// 同定の状態の印。和名(和名が無ければ学名)の左に付ける。
/// 同定済みは緑のチェックマーク、仮同定は三角の中にビックリマーク。未同定は何も付けない。
class StatusMark extends StatelessWidget {
  const StatusMark(this.status, {super.key, this.size = 20});

  final IdentificationStatus status;
  final double size;

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = switch (status) {
      IdentificationStatus.verified => (Icons.check_circle, verifiedColor, '同定済み'),
      IdentificationStatus.provisional => (Icons.warning_rounded, provisionalColor, '仮同定'),
      IdentificationStatus.unidentified => (null, null, null),
    };
    if (icon == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Icon(icon, size: size, color: color, semanticLabel: label),
    );
  }
}
