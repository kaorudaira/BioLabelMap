// 自治体コード+大字 → 大字のローマ字の対応表を作る。
//
// 実行(プロジェクトのルートで):
//   dart run tools/municipalities/build_oaza.dart
//
// 入力(tools/municipalities/source/ に置く。Git には入れない):
//   mt_town_all.csv   デジタル庁 アドレス・ベース・レジストリ「町字マスター」(全国)
//   KEN_ALL.CSV       日本郵便 郵便番号データ(読み仮名・小書き、自治体コード付き)
//   KEN_ALL_ROME.CSV  日本郵便 郵便番号データ(ローマ字)
//   取得元は tools/municipalities/README.md を参照。
//
// 出力:
//   assets/data/oaza_romaji.json                 アプリに同梱する対応表
//   tools/municipalities/source/oaza_review.csv  採らなかったものの一覧(Git に入れない)
//
// 方針(要件定義 第5章):
//   綴りはアドレス・ベース・レジストリと日本郵便の公的な綴りに従う。どちらも長音を省くので、
//   県・市町村と同じく、カナから作った候補のうち、マクロンを外すと公的な綴りに一致するものを採る。
//   2つのデータで綴りが違うときは、読み(カナ)と合うほうを採る。
//   一通りに決まらないものは採らず、アプリでは手入力にする。

import 'dart:convert';
import 'dart:io';

import 'package:biolabelmap/domain/oaza_name.dart';
import 'package:charset/charset.dart';

import 'csv.dart';
import 'romanize.dart';

const _sourceDir = 'tools/municipalities/source';
const _outputJson = 'assets/data/oaza_romaji.json';
const _reviewCsv = '$_sourceDir/oaza_review.csv';

/// 1つの大字について、2つのデータから集めた読みと綴り。
class _Oaza {
  _Oaza(this.code, this.name);

  final String code;
  final String name;
  final abrKana = <String>{};
  final abrRoma = <String>{};
  final postKana = <String>{};
  final postRoma = <String>{};
}

/// 採否の理由。
enum _Outcome {
  agreed('2つのデータで一致'),
  abrOnly('アドレス・ベース・レジストリのみ'),
  postOnly('郵便番号データのみ'),
  resolved('綴りが違い、読みと合うほうを採った'),
  conflict('綴りが違い、どちらとも決まらない'),
  ambiguous('長音の位置が一通りに決まらない'),
  noMatch('読みと綴りが合わない'),
  noRoma('ローマ字が無い');

  const _Outcome(this.label);
  final String label;

  bool get adopted => index <= resolved.index;
}

void main() {
  final oaza = <String, _Oaza>{};
  _Oaza entry(String code, String name) =>
      oaza.putIfAbsent('$code|$name', () => _Oaza(code, name));

  _readAbr(entry);
  _readPost(entry);

  final output = <String, Map<String, String>>{};
  final counts = <_Outcome, int>{};
  final reviews = <List<String>>[];
  for (final o in oaza.values) {
    final (outcome, value, note) = _decide(o);
    counts[outcome] = (counts[outcome] ?? 0) + 1;
    if (outcome.adopted) {
      output.putIfAbsent(o.code, () => {})[o.name] = value!;
    } else {
      reviews.add([
        o.code,
        o.name,
        o.abrKana.join('/'),
        o.abrRoma.join('/'),
        o.postKana.join('/'),
        o.postRoma.join('/'),
        outcome.label,
        note ?? '',
      ]);
    }
  }

  final sorted = {
    for (final code in output.keys.toList()..sort())
      code: {for (final name in output[code]!.keys.toList()..sort()) name: output[code]![name]!},
  };
  File(_outputJson).writeAsStringSync('${jsonEncode(sorted)}\n');

  String q(String v) => '"${v.replaceAll('"', '""')}"';
  final csv = StringBuffer('﻿code,name,abr_kana,abr_roma,post_kana,post_roma,outcome,note\n');
  for (final r in reviews..sort((a, b) => '${a[0]}${a[1]}'.compareTo('${b[0]}${b[1]}'))) {
    csv.writeln(r.map(q).join(','));
  }
  File(_reviewCsv).writeAsStringSync(csv.toString());

  final adopted = counts.entries.where((e) => e.key.adopted).fold(0, (a, e) => a + e.value);
  stdout.writeln('大字: ${oaza.length}件 → 採用 $adopted件');
  for (final o in _Outcome.values) {
    stdout.writeln('  ${o.adopted ? '採用' : '不採用'} ${o.label}: ${counts[o] ?? 0}');
  }
  stdout.writeln('出力: $_outputJson(${File(_outputJson).lengthSync()} bytes), $_reviewCsv');
}

/// 採否と、採るときの表記(`Shimōritate`)、採らないときの補足。
(_Outcome, String?, String?) _decide(_Oaza o) {
  // 綴りは空白・ハイフン・大文字小文字を除いて比べる。同じ綴りなら、アドレス・ベース・レジストリの書き方を使う
  final references = <String, String>{};
  for (final r in [...o.abrRoma, ...o.postRoma]) {
    references.putIfAbsent(_compact(r), () => r);
  }
  if (references.isEmpty) return (_Outcome.noRoma, null, null);

  // 読みは両方のデータから集め、どれか1つでも綴りと合えばよい(片方の読みの誤りを補う)
  final kanas = {...o.abrKana, ...o.postKana};
  if (kanas.isEmpty) return (_Outcome.noRoma, null, '読みが無い');

  final valuesByReference = <String, Set<String>>{};
  final notes = <String>{};
  for (final reference in references.values) {
    for (final kana in kanas) {
      final (value, note) = _romanize(kana, reference);
      if (value != null) {
        valuesByReference.putIfAbsent(reference, () => {}).add(value);
      } else if (note != null) {
        notes.add(note);
      }
    }
  }

  if (valuesByReference.isEmpty) {
    final ambiguous = notes.any((n) => n.contains('一通りに決まらない'));
    return (ambiguous ? _Outcome.ambiguous : _Outcome.noMatch, null, notes.join(' / '));
  }
  if (valuesByReference.length > 1) {
    return (_Outcome.conflict, null, valuesByReference.values.expand((v) => v).join(' / '));
  }
  final values = valuesByReference.values.single;
  if (values.length > 1) {
    return (_Outcome.ambiguous, null, values.join(' / '));
  }

  final Set<String> fromAbr = {for (final r in o.abrRoma) _compact(r)};
  final Set<String> fromPost = {for (final r in o.postRoma) _compact(r)};
  final adopted = _compact(valuesByReference.keys.single);
  final _Outcome outcome;
  if (references.length > 1) {
    outcome = _Outcome.resolved;
  } else if (fromAbr.contains(adopted) && fromPost.contains(adopted)) {
    outcome = _Outcome.agreed;
  } else {
    outcome = fromAbr.contains(adopted) ? _Outcome.abrOnly : _Outcome.postOnly;
  }
  return (outcome, values.single, null);
}

/// カナと公的な綴りから、マクロン付きの表記を作る。作れなければ理由を返す。
///
/// 綴りの空白・ハイフンはそのまま残し、語頭だけ大文字にする。数字(北海道の `1-Jo` など)を
/// 含むものは、カナから長音を決められないので、公的な綴りをそのまま使う。
(String?, String?) _romanize(String kana, String reference) {
  if (RegExp(r'[0-9]').hasMatch(reference)) return (reference, null);

  // ハイフンは空白として照合し、あとで同じ位置に戻す
  final spaced = reference.toUpperCase().replaceAll('-', ' ');
  final result = romanizeWithReference(kana, spaced);
  String? upper = result.ok ? result.value : null;

  // 語の境目をまたいで長音の候補が2つ出たとき(`HAGIWARACHO UWAMURA` の チョウ|ウ)は、
  // 語頭に長音が来ないほう(`Hagiwarachō Uwamura`)を採る
  if (upper == null && result.candidates.length > 1 && result.reason == '長音の位置が一通りに決まらない') {
    final restored = [for (final c in result.candidates) _restoreSeparators(c, spaced)];
    final plausible = restored.where((c) => !c.split(' ').any((w) => w.isNotEmpty && 'ĀĪŪĒŌ'.contains(w[0]))).toList();
    if (plausible.length == 1) upper = plausible.single;
  }
  if (upper == null) {
    return (null, [?result.reason, if (result.candidates.isNotEmpty) '候補: ${result.candidates.join(' / ')}'].join(' '));
  }

  final out = StringBuffer();
  var startOfWord = true;
  for (var i = 0; i < upper.length; i++) {
    final separator = reference[i];
    if (separator == ' ' || separator == '-') {
      out.write(separator);
      startOfWord = true;
      continue;
    }
    out.write(startOfWord ? upper[i] : upper[i].toLowerCase());
    startOfWord = false;
  }
  return (out.toString(), null);
}

/// 空白を除いた候補に、綴りと同じ位置で空白を戻す。
String _restoreSeparators(String compact, String spaced) {
  final out = StringBuffer();
  var j = 0;
  for (final c in spaced.split('')) {
    if (j >= compact.length) break;
    out.write(c == ' ' ? ' ' : compact[j++]);
  }
  return out.toString();
}

/// 綴りを比べるために、大文字にして空白とハイフンを除く。
String _compact(String roma) => roma.toUpperCase().replaceAll(RegExp(r'[\s-]'), '');

/// 名前から「大字」「字」を除いたとき、読みからも「オオアザ」「アザ」を除く。
String _stripPrefixKana(String rawName, String kana) => switch (oazaPrefixOf(rawName)) {
  '大字' when kana.startsWith('オオアザ') => kana.substring(4),
  '字' when kana.startsWith('アザ') => kana.substring(2),
  _ => kana,
};

// ---- 入力の読み込み ----

/// 町字マスター。大字(oaza_cho)ごとに、カナとローマ字を集める。廃止された町字は除く。
void _readAbr(_Oaza Function(String, String) entry) {
  final rows = parseCsv(File('$_sourceDir/mt_town_all.csv').readAsStringSync());
  final header = rows.first;
  int col(String name) => header.indexOf(name);
  final lgCode = col('lg_code');
  final name = col('oaza_cho');
  final kana = col('oaza_cho_kana');
  final roma = col('oaza_cho_roma');
  final ablt = col('ablt_date');

  for (final f in rows.skip(1)) {
    final oaza = f[name].trim();
    if (oaza.isEmpty || f[ablt].isNotEmpty) continue;
    final e = entry(f[lgCode].substring(0, 5), normalizeOazaName(oaza));
    final k = _stripPrefixKana(oaza, f[kana].trim());
    if (k.isNotEmpty) e.abrKana.add(k);
    if (f[roma].trim().isNotEmpty) e.abrRoma.add(f[roma].trim());
  }
}

/// 郵便番号データ。町域を大字とみなし、カナ版とローマ字版を郵便番号と町域名で結び付ける。
/// 「以下に掲載がない場合」や、複数の町域をまとめた行(「、」を含む)、
/// 長い町域を複数行に分けた続きの行は除く。括弧書きは除いてから使う。
void _readPost(_Oaza Function(String, String) entry) {
  String readSjis(String name) => shiftJis.decode(File('$_sourceDir/$name').readAsBytesSync());
  String stripParen(String s) => s.replaceAll(RegExp(r'[（(].*?[）)]|[（(].*$'), '').trim();
  bool usable(String raw, String town) =>
      town.isNotEmpty &&
      !town.contains('以下に掲載がない場合') &&
      !town.contains('の次に番地がくる場合') &&
      !town.endsWith('一円') &&
      !town.contains('、') &&
      // 続きの行は、閉じ括弧だけを含む
      !(raw.contains(RegExp(r'[）)]')) && !raw.contains(RegExp(r'[（(]')));

  final romeByKey = <String, String>{};
  for (final f in parseCsv(readSjis('KEN_ALL_ROME.CSV'))) {
    romeByKey['${f[0]}|${normalizeOazaName(stripParen(f[3]))}'] = stripParen(f[6]);
  }
  for (final f in parseCsv(readSjis('KEN_ALL.CSV'))) {
    final town = stripParen(f[8]);
    if (!usable(f[8], town)) continue;
    final name = normalizeOazaName(town);
    final e = entry(f[0].padLeft(5, '0'), name);
    final kana = _stripPrefixKana(town, halfToFullKatakana(stripParen(f[5])));
    if (kana.isNotEmpty) e.postKana.add(kana);
    final roma = romeByKey['${f[2]}|$name'];
    if (roma != null && roma.isNotEmpty) e.postRoma.add(roma);
  }
}
