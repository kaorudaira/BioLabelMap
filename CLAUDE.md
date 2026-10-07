# BioLabelMap

昆虫標本ラベル記録アプリ(Flutter、iPhone / Android)。圏外でもGPSで採集地点を記録し、標本ラベルのPDF出力までを端末内で完結させる。

## 仕様と進捗

- 仕様の正本は [docs/requirements.md](docs/requirements.md)。機能は F-xx、画面は S-xx の番号で呼ぶ
- requirements.md は毎回は読まない(大きいので)。バグ修正・小さな変更・質問はコードと `git log` だけで進める
- 読むのは次のときだけ。該当する節(F-xx / S-xx)だけを Grep か offset 指定で読み、全文は読まない
  - 新しい機能・画面を作る、または仕様に関わる判断をするとき → 関係する節
  - 次の段階に進むとき、現在地を知りたいとき → 「11. 開発の段階」の表と `git log`
- 段階を終えたら、§11 の表の状態を更新する。決まっていないことは「10. 未決事項」に書く
- 仕様を変えたり決めたりしたときは、コードと一緒に要件定義も直す

## コマンド

```bash
flutter pub get
dart run build_runner build   # Drift の database.g.dart を生成(lib/core/db/tables.dart を変えたら再実行)
flutter analyze
flutter test
```

自治体の対応表 `assets/data/municipalities.json` は `tools/municipalities/` で生成する(手順は同フォルダの README)。

## 構成

- `lib/app/` ルーター・テーマ
- `lib/core/` DB(Drift)、地理院API・タイル、ラベルPDF、位置情報
- `lib/domain/` 標本番号・丸め・地名などの純粋なロジック(テストはここを厚く)
- `lib/services/` 保存・補完キュー・下書き・ラベル・バックアップなどの処理。Riverpod で提供(`service_providers.dart`)
- `lib/features/` 画面ごとのUI
- `test/` は `lib/` と同じ構成

## 約束事

- 応答・ドキュメント・コミットメッセージ・PR のブランチ名、タイトル、本文は日本語。コミットメッセージには関係する S-xx / F-xx を書く
- オフラインが最重要。記録・保存・PDF出力は通信なしで動くこと
- ラベルの文字はアプリ同梱のフォント(Fira Sans Condensed、BIZ UDPゴシック)で測って組む
