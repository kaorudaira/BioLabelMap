# 自治体と大字の対応表(municipalities.json・oaza_romaji.json)

自治体コード → 県・市区町村の名前(和・英)の対応表を作る。アプリは `assets/data/municipalities.json` を同梱し、逆ジオコーダが返す自治体コードから英語表記を引く(要件定義 第5章)。

## 出典

| 役割 | データ | 取得元 |
|---|---|---|
| コード・名前・カナ | 総務省「全国地方公共団体コード」 | https://www.soumu.go.jp/denshijiti/code.html (`000925835.xlsx`) |
| 郵便番号と自治体コードの対応、カナ | 日本郵便 郵便番号データ(読み仮名・小書き) `ken_all.zip` | https://www.post.japanpost.jp/service/search/zipcode/download/kogaki-zip.html |
| ローマ字の綴り | 日本郵便 郵便番号データ(ローマ字) `KEN_ALL_ROME.zip` | https://www.post.japanpost.jp/service/search/zipcode/download/roman-zip.html |
| 大字のカナ・ローマ字 | デジタル庁 アドレス・ベース・レジストリ「町字マスター」(全国) `mt_town_all.csv.zip` | https://dataset.address-br.digital.go.jp/ (ファイルは https://gov-csv-export-public.s3.ap-northeast-1.amazonaws.com/mt_town/mt_town_all.csv.zip ) |

日本郵便は郵便番号データの著作権を主張していない。アドレス・ベース・レジストリは CC BY 4.0(利用規約 https://www.digital.go.jp/policies/base_registry_address_tos)。アプリの設定画面に出典と加工した旨を載せている。

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

## 大字のローマ字(oaza_romaji.json)

自治体コード(5桁)+大字 → 大字のローマ字の表。アプリは逆ジオコーダの大字名(lv01Nm)で引く。

1. 上の `mt_town_all.csv.zip` を展開して `tools/municipalities/source/mt_town_all.csv` にする(`KEN_ALL.CSV`・`KEN_ALL_ROME.CSV` も使う)
2. プロジェクトのルートで実行する

   ```bash
   dart run tools/municipalities/build_oaza.dart
   ```

3. 件数の内訳が表示される。採らなかったものは `source/oaza_review.csv` に出る(Git には入れない)

変換の方針:

- 大字名は `lib/domain/oaza_name.dart` の `normalizeOazaName` でそろえる(先頭の「大字」「字」、末尾の丁目を除く)。アプリも同じ関数で引く
- 綴りはアドレス・ベース・レジストリと日本郵便に従う。2つのデータで綴りが違うときは、読み(カナ)と合うほうを採る。読みは両方のデータから集め、片方の読みの誤りを補う
- 長音は県・市町村と同じくカナからマクロンを補う。語の境目をまたいで候補が2つ出たとき(`HAGIWARACHO UWAMURA`)は、語頭に長音が来ないほうを採る
- 数字を含む綴り(北海道の `1-Jo` など)は、公的な綴りをそのまま使う
- 一通りに決まらないものは採らない(アプリでは手入力)
- 公的データは語の境目の「oo」「ou」も長音として省く(下折立=SHIMORITATE)ため、マクロンを含む値は誤っていることがある。アプリはマクロンを含む値を自動では入れず、候補として示す
