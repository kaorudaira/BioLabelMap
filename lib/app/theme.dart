import 'package:flutter/material.dart';

/// 項目の種類を分ける4色(要件定義 第9章「画面の色分け」)。
/// 標本詳細・標本一覧・ラベル出力でも同じ色を使う。
abstract final class BlockColors {
  // `abstract final class` は、インスタンスを作れず継承もできないクラス。
  // Java の「private コンストラクタだけの final class」(定数置き場)に相当する。

  /// 地点・日時(自動入力)。
  static const location = Color(0xFF1E6FD9);

  /// 採集(方法・環境)。
  static const collecting = Color(0xFFE8833A);

  /// 標本。
  static const specimen = Color(0xFF7B4BC4);

  /// 同定。
  static const identification = Color(0xFFC2185B);
}

/// 警告色(GPS精度の警告など)。
const warningColor = Color(0xFFD84315);

ThemeData buildTheme() {
  final base = ThemeData(
    colorSchemeSeed: BlockColors.location,
    useMaterial3: true,
  );
  return base.copyWith(
    // 屋外の片手操作を想定し、ボタンを大きめにする(要件定義 第8章)
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 52),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(minimumSize: const Size(64, 52)),
    ),
  );
}

/// 同定済みの印(和名の左のチェックマーク)の色。
const verifiedColor = Color(0xFF2E7D32);

/// 仮同定の印(和名の左の、三角の中のビックリマーク)の色。
const provisionalColor = Color(0xFFF57C00);
