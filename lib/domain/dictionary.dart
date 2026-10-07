/// 環境・寄主植物の辞書の種別(要件定義 S-10)。DB には `name` で保存する。
enum DictTextKind {
  habitat('環境'),
  hostPlant('寄主植物');

  const DictTextKind(this.label);
  final String label;
}
