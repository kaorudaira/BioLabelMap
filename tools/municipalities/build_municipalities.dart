// 自治体コード → 県・市区町村の名前(和・英)の対応表を作る。
//
// 実行(プロジェクトのルートで):
//   dart run tools/municipalities/build_municipalities.dart
//
// 入力(tools/municipalities/source/ に置く。Git には入れない):
//   soumu_code.xlsx   総務省「全国地方公共団体コード」 https://www.soumu.go.jp/denshijiti/code.html
//   KEN_ALL.CSV       日本郵便 郵便番号データ(読み仮名・小書き、自治体コード付き)
//   KEN_ALL_ROME.CSV  日本郵便 郵便番号データ(ローマ字)
//   取得元は tools/municipalities/README.md を参照。
//
// 出力:
//   assets/data/municipalities.json   アプリに同梱する対応表
//   tools/municipalities/review.csv   要確認の一覧
//
// 方針(要件定義 第5章):
//   名前とカナは総務省、ローマ字の綴りは日本郵便に従う。日本郵便は長音を省くので、
//   カナから作った候補のうち、マクロンを外すと日本郵便の綴りに一致するものを採る。
//   一通りに決まらないものは要確認にし、日本郵便の綴り(マクロンなし)を仮に入れる。
//   確認した結果は tools/municipalities/overrides.json に書き、最優先で使う。

import 'dart:convert';
import 'dart:io';

import 'package:charset/charset.dart';

import 'romanize.dart';
import 'xlsx_reader.dart';

const _sourceDir = 'tools/municipalities/source';
const _outputJson = 'assets/data/municipalities.json';
const _reviewCsv = 'tools/municipalities/review.csv';
const _overridesJson = 'tools/municipalities/overrides.json';

/// 要確認の1行。
class _Review {
  _Review(this.code, this.name, this.kana, this.reference, this.reason);
  final String code;
  final String name;
  final String kana;
  final String reference;
  final String reason;
}

void main() {
  final soumu = _readSoumu();
  final post = _readPost();
  final overrides = _readOverrides();
  final reviews = <_Review>[];

  // 1. 都道府県
  final prefEn = <String, String>{};
  for (final pref in soumu.where((e) => e.isPrefecture)) {
    final kana = halfToFullKatakana(pref.prefKana);
    final reference = post.prefRomajiByPrefCode[pref.prefCode];
    if (reference == null) {
      prefEn[pref.prefCode] = pref.prefJa;
      reviews.add(_Review(pref.code, pref.prefJa, kana, '', '日本郵便のローマ字が無い'));
      continue;
    }
    final result = romanizeWithReference(kana, reference);
    prefEn[pref.prefCode] = toLabelCase(result.value ?? reference);
    if (!result.ok) {
      reviews.add(_Review(pref.code, pref.prefJa, kana, reference, _reasonOf(result)));
    }
  }

  // 2. 市区町村
  final output = <String, Map<String, Object>>{};
  final missing = <_SoumuEntry>[];
  for (final muni in soumu.where((e) => !e.isPrefecture)) {
    final entry = <String, Object>{
      'prefJa': muni.prefJa,
      'muniJa': muni.muniJa,
      'prefEn': prefEn[muni.prefCode] ?? muni.prefJa,
    };
    output[muni.code] = entry;
    final soumuKana = halfToFullKatakana(muni.muniKana);

    final names = post.byCode[muni.code];
    if (names == null) {
      missing.add(muni);
      continue;
    }
    if (names.romaji.length != 1 || names.kana.length != 1) {
      entry['muniEn'] = muni.muniJa;
      entry['unverified'] = true;
      reviews.add(_Review(muni.code, muni.muniJa, soumuKana, names.romaji.join(' / '),
          '日本郵便のローマ字・カナが複数ある'));
      continue;
    }

    final reference = names.romaji.single;
    final kana = halfToFullKatakana(names.kana.single);
    final result = romanizeWithReference(kana, reference);
    if (!result.ok) {
      entry['unverified'] = true;
      reviews.add(_Review(muni.code, muni.muniJa, kana, reference, _reasonOf(result)));
    }
    // 値が作れなかったときは、日本郵便の綴り(マクロンなし)を仮に入れる

    // 郡を分ける: 「Minamiuonuma-gun Yuzawa-machi」→ 郡と町
    final words = toLabelCase(result.value ?? reference).split(' ');
    final gunIndex = words.lastIndexWhere((w) => w.endsWith('-gun'));
    entry['muniEn'] = words.sublist(gunIndex + 1).join(' ');
    if (gunIndex >= 0) {
      entry['gunEn'] = words.sublist(0, gunIndex + 1).join(' ');
      final fullJa = names.kanji.single;
      if (fullJa.endsWith(muni.muniJa)) {
        entry['gunJa'] = fullJa.substring(0, fullJa.length - muni.muniJa.length);
      }
    }

    // 郡を除いたカナが総務省と一致するか(同じ自治体を指しているか)。
    // 総務省のカナは小書きを大書きで書く(ショウ → シヨウ)ので、そろえて比べる。
    if (!toLargeKana(kana).endsWith(toLargeKana(soumuKana))) {
      entry['unverified'] = true;
      reviews.add(_Review(muni.code, muni.muniJa, soumuKana, reference,
          '総務省と日本郵便でカナが異なる(日本郵便: $kana)'));
    }
  }

  // 3. 日本郵便に無い自治体。政令指定都市の市は、区のローマ字から「◯◯-shi」を取る。
  //    (逆ジオコーダは区のコードを返すので、市そのものが引かれることはほぼ無い)
  for (final city in missing) {
    final entry = output[city.code]!;
    final wardEn = output.values
        .where((e) =>
            e['prefJa'] == city.prefJa &&
            e['muniJa'] != city.muniJa &&
            (e['muniJa'] as String).startsWith(city.muniJa) &&
            e['unverified'] != true)
        .map((e) => e['muniEn'] as String?)
        .firstWhere((en) => en != null && en.contains('-shi '), orElse: () => null);
    if (wardEn != null) {
      entry['muniEn'] = wardEn.substring(0, wardEn.indexOf('-shi ') + '-shi'.length);
      continue;
    }

    // それ以外(北方領土の村など)は、カナだけから作って要確認にする
    final kana = halfToFullKatakana(city.muniKana);
    final result = romanizeWithoutReference(kana);
    entry['muniEn'] = result.value == null ? city.muniJa : toLabelCase(result.value!);
    entry['unverified'] = true;
    reviews.add(_Review(city.code, city.muniJa, kana, '',
        '日本郵便のデータに無い。${_reasonOf(result)}'));
  }

  // 4. 確認済みの上書き。県のコード(上2桁+000)なら、その県の全件の prefEn を変える。
  for (final MapEntry(key: code, value: values) in overrides.entries) {
    if (code.endsWith('000') && values['prefEn'] is String) {
      for (final MapEntry(:key, :value) in output.entries) {
        if (key.startsWith(code.substring(0, 2))) value['prefEn'] = values['prefEn']!;
      }
      reviews.removeWhere((r) => r.code == code);
    } else if (output[code] case final entry?) {
      entry
        ..addAll(values)
        ..remove('unverified');
      reviews.removeWhere((r) => r.code == code);
    }
  }

  _writeOutputs(output, reviews);
}

String _reasonOf(RomanizeResult r) => [
  ?r.reason,
  if (r.candidates.isNotEmpty) '候補: ${r.candidates.join(' / ')}',
].join(' ');

void _writeOutputs(Map<String, Map<String, Object>> output, List<_Review> reviews) {
  final sorted = Map.fromEntries(
    output.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
  );
  File(_outputJson)
    ..createSync(recursive: true)
    ..writeAsStringSync('${const JsonEncoder.withIndent(' ').convert(sorted)}\n');

  String q(String v) => '"${v.replaceAll('"', '""')}"';
  final csv = StringBuffer('﻿code,name,kana,japan_post,current,reason\n');
  for (final r in reviews..sort((a, b) => a.code.compareTo(b.code))) {
    final current = r.code.endsWith('000') && !output.containsKey(r.code)
        ? ''
        : (output[r.code]?['muniEn'] as String? ?? '');
    csv.writeln([r.code, r.name, r.kana, r.reference, current, r.reason].map(q).join(','));
  }
  File(_reviewCsv).writeAsStringSync(csv.toString());

  final unverified = sorted.values.where((v) => v['unverified'] == true).length;
  stdout.writeln('自治体: ${sorted.length}件(要確認 $unverified件)');
  stdout.writeln('出力: $_outputJson, $_reviewCsv(${reviews.length}行)');
}

// ---- 入力の読み込み ----

class _SoumuEntry {
  _SoumuEntry(this.code, this.prefJa, this.muniJa, this.prefKana, this.muniKana);

  /// 5桁(検査数字を除く)。
  final String code;
  final String prefJa;
  final String muniJa;
  final String prefKana;
  final String muniKana;

  String get prefCode => code.substring(0, 2);
  bool get isPrefecture => muniJa.isEmpty;
}

/// 総務省の一覧。シート1が市区町村、シート2が政令指定都市の区。
List<_SoumuEntry> _readSoumu() {
  final path = '$_sourceDir/soumu_code.xlsx';
  final byCode = <String, _SoumuEntry>{};
  for (final sheet in [1, 2]) {
    for (final row in readXlsxSheet(path, sheet).skip(1)) {
      final code = row['A'] ?? '';
      if (!RegExp(r'^\d{6}$').hasMatch(code)) continue;
      byCode[code.substring(0, 5)] = _SoumuEntry(
        code.substring(0, 5),
        row['B'] ?? '',
        row['C'] ?? '',
        row['D'] ?? '',
        row['E'] ?? '',
      );
    }
  }
  return byCode.values.toList();
}

class _PostNames {
  final romaji = <String>{};
  final kana = <String>{};
  final kanji = <String>{};
}

class _PostData {
  final byCode = <String, _PostNames>{};
  final prefRomajiByPrefCode = <String, String>{};
}

/// 日本郵便のカナ版(自治体コード付き)とローマ字版を、郵便番号と市区町村名で結び付ける。
_PostData _readPost() {
  String readSjis(String name) =>
      shiftJis.decode(File('$_sourceDir/$name').readAsBytesSync());
  String compact(String s) => s.replaceAll(RegExp(r'[\s　]'), '');

  // `(String, String)` はレコード型。`.$1` `.$2` で取り出す(Java の record に近い)。
  final romeByKey = <String, (String, String)>{};
  for (final f in _parseCsv(readSjis('KEN_ALL_ROME.CSV'))) {
    romeByKey['${f[0]}|${compact(f[2])}'] = (f[4].trim(), f[5].trim());
  }

  final data = _PostData();
  for (final f in _parseCsv(readSjis('KEN_ALL.CSV'))) {
    final code = f[0].padLeft(5, '0');
    final rome = romeByKey['${f[2]}|${compact(f[7])}'];
    if (rome == null) continue;
    data.byCode.putIfAbsent(code, _PostNames.new)
      ..romaji.add(rome.$2)
      ..kana.add(f[4])
      ..kanji.add(f[7]);
    data.prefRomajiByPrefCode[code.substring(0, 2)] = rome.$1;
  }
  return data;
}

Map<String, Map<String, Object>> _readOverrides() {
  final file = File(_overridesJson);
  if (!file.existsSync()) return {};
  final decoded = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  return decoded.map((k, v) => MapEntry(k, Map<String, Object>.from(v as Map)));
}

/// ダブルクォートで囲まれたフィールドを含む CSV を読む(改行を含むフィールドは扱わない)。
List<List<String>> _parseCsv(String content) {
  final rows = <List<String>>[];
  for (final line in const LineSplitter().convert(content)) {
    if (line.isEmpty) continue;
    final fields = <String>[];
    final buf = StringBuffer();
    var quoted = false;
    for (var i = 0; i < line.length; i++) {
      final c = line[i];
      if (quoted) {
        if (c == '"' && i + 1 < line.length && line[i + 1] == '"') {
          buf.write('"');
          i++;
        } else if (c == '"') {
          quoted = false;
        } else {
          buf.write(c);
        }
      } else if (c == '"') {
        quoted = true;
      } else if (c == ',') {
        fields.add(buf.toString());
        buf.clear();
      } else {
        buf.write(c);
      }
    }
    fields.add(buf.toString());
    rows.add(fields);
  }
  return rows;
}
