# BioLabelMap

昆虫標本ラベル記録アプリ。圏外の山間部でもGPSで採集地点を記録し、標本ラベルの印刷とデータ管理までをスマートフォン1台で完結させる(iPhone / Android、Flutter)。

要件は [docs/requirements.md](docs/requirements.md) を参照。

## 開発

```bash
flutter pub get
dart run build_runner build   # Drift の database.g.dart を生成(テーブルを変えたら再実行)
flutter test
```
