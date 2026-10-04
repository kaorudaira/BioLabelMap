# 自治体の対応表(municipalities.json)

自治体コード → 県・市区町村の名前(和・英)の対応表を作る。アプリは `assets/data/municipalities.json` を同梱し、逆ジオコーダが返す自治体コードから英語表記を引く(要件定義 第5章)。

## 出典

| 役割 | データ | 取得元 |
|---|---|---|
| コード・名前・カナ | 総務省「全国地方公共団体コード」 | https://www.soumu.go.jp/denshijiti/code.html (`000925835.xlsx`) |
| 郵便番号と自治体コードの対応、カナ | 日本郵便 郵便番号データ(読み仮名・小書き) `ken_all.zip` | https://www.post.japanpost.jp/service/search/zipcode/download/kogaki-zip.html |
| ローマ字の綴り | 日本郵便 郵便番号データ(ローマ字) `KEN_ALL_ROME.zip` | https://www.post.japanpost.jp/service/search/zipcode/download/roman-zip.html |

日本郵便は郵便番号データの著作権を主張していない。

## 作り方

1. 上の3つを取得し、`tools/municipalities/source/` に置く(zip は展開して `KEN_ALL.CSV`、`KEN_ALL_ROME.CSV` にする。総務省の xlsx は `soumu_code.xlsx` に改名)。このフォルダは Git に入れない
2. プロジェクトのルートで実行する

   ```bash
   dart run tools/municipalities/build_municipalities.dart
   ```

3. `tools/municipalities/review.csv` の要確認を見て、確定した値を `overrides.json` に書き、もう一度実行する

## 変換の方針

- 名前とカナは総務省、ローマ字の綴りは日本郵便に従う
- 日本郵便の綴りは長音を省く(`TOKYO`)。カナから長音の候補を作り、マクロンを外すと日本郵便の綴りに一致するものを採る。日本郵便が u・o を省いていれば長音(`Tōkyō`)、残していれば長音でない(`Koura`)
- 接尾辞はハイフンでつなぐ(`Niigata-ken`、`Uonuma-shi`)。郡は `gunEn`・`gunJa` に分ける
- 政令指定都市の市そのもの(日本郵便のデータに無い)は、区の表記から `◯◯-shi` を取る
- 一通りに決まらないものは `"unverified": true` を付け、仮の値を入れる

## overrides.json の書き方

自治体コード(5桁)ごとに、上書きする項目だけを書く。県全体の `prefEn` は、県のコード(上2桁+`000`)に書く。

```json
{
  "44212": { "muniEn": "Bungoōno-shi" },
  "10000": { "prefEn": "Gunma-ken" }
}
```
