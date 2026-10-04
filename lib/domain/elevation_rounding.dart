/// 標高の丸め(要件定義 F-04)。既定は10m。
///
/// Dart の enum はフィールドとコンストラクタを持てる(拡張 enum)。
/// Java の enum に値を持たせる書き方とほぼ同じ。
/// DB には `name`(`oneMeter` など)で保存するので、名前を変えるときは移行が要る。
enum ElevationRounding {
  oneMeter(1),
  tenMeters(10);

  const ElevationRounding(this.step);

  final int step;

  /// 四捨五入して丸める(1385 → 1390、1384.9 → 1380)。
  int apply(double meters) => (meters / step).round() * step;
}
