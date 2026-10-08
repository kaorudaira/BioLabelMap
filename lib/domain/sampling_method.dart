/// 採集方法の区分(要件定義 第6章)。
enum SamplingCategory { general, light, trap, other }

/// 採集方法のプリセット(要件定義 第6章)。
///
/// 段階1は固定のリスト。設定での追加・並べ替え(段階4)は、DB のテーブルに移す。
/// DB には `name`(`sweeping` など)で保存する。
enum SamplingMethod {
  general('任意採集', 'General collecting', SamplingCategory.general),
  looking('ルッキング', 'Looking', SamplingCategory.general),
  sweeping('スウィーピング', 'Sweeping', SamplingCategory.general),
  streetLight('外灯', 'At street light', SamplingCategory.light),
  lightTrap('ライトトラップ', 'Light trap', SamplingCategory.trap,
      hasLightSource: true),
  lightFit('ライトFIT', 'Light FIT', SamplingCategory.trap,
      hasLightSource: true),
  bananaTrap('バナナトラップ', 'Banana trap', SamplingCategory.trap),
  pitfallTrap('ピットフォールトラップ', 'Pitfall trap', SamplingCategory.trap,
      hasBait: true),

  /// 「その他(自由入力)」。名前は採集の記録側に持つ。
  other('その他', 'Other', SamplingCategory.other);

  const SamplingMethod(
    this.nameJa,
    this.nameEn,
    this.category, {
    this.hasLightSource = false,
    this.hasBait = false,
  });

  final String nameJa;

  /// CSV の samplingProtocol に出す英語名。
  final String nameEn;
  final SamplingCategory category;
  final bool hasLightSource;
  final bool hasBait;

  /// トラップ系は設置〜回収の期間を入力する。
  bool get usesPeriod => category == SamplingCategory.trap;
}

/// 採集方法の表示。「その他」を選び、自由入力があれば `その他：{自由入力}` の形にする。
String formatSamplingMethod(SamplingMethod method, String? other) {
  final text = other?.trim();
  if (method == SamplingMethod.other && text != null && text.isNotEmpty) return 'その他：$text';
  return method.nameJa;
}
