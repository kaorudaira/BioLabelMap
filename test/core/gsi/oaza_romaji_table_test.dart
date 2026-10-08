import 'dart:convert';
import 'dart:io';

import 'package:biolabelmap/core/db/database.dart';
import 'package:biolabelmap/core/gsi/gsi_api.dart';
import 'package:biolabelmap/core/gsi/municipality_directory.dart';
import 'package:biolabelmap/core/gsi/oaza_romaji_table.dart';
import 'package:biolabelmap/domain/oaza_name.dart';
import 'package:biolabelmap/services/locality_lookup_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeOazaName', () {
    test('先頭の「大字」「字」と末尾の丁目を除き、空白と小さいヶをそろえる', () {
      expect(normalizeOazaName('大字土樽'), '土樽');
      expect(normalizeOazaName('字青山'), '青山');
      expect(normalizeOazaName('旭ヶ丘 一丁目'), '旭ケ丘');
      expect(normalizeOazaName('本町１丁目'), '本町');
      expect(normalizeOazaName('下折立'), '下折立');
    });

    test('名前が「大字」「字」だけのときは除かない', () {
      expect(normalizeOazaName('字'), '字');
      expect(normalizeOazaName('大字'), '大字');
    });
  });

  group('applyChoSuffixRule', () {
    test('末尾の chō の前にハイフンを入れ、マクロンは残す', () {
      expect(applyChoSuffixRule('Tondenchō'), 'Tonden-chō');
      expect(applyChoSuffixRule('Okadamachō'), 'Okadama-chō');
      expect(applyChoSuffixRule('HAGIWARACHŌ'), 'HAGIWARA-CHŌ');
    });

    test('すでにハイフンがあるときや、名前が chō だけのときは変えない', () {
      expect(applyChoSuffixRule('Higashi-chō'), 'Higashi-chō');
      expect(applyChoSuffixRule('Chō'), 'Chō');
    });

    test('末尾でない chō や、ほかの長音、マクロンのない cho は変えない', () {
      expect(applyChoSuffixRule('Chōnai'), 'Chōnai');
      expect(applyChoSuffixRule('Shimōritate'), 'Shimōritate');
      expect(applyChoSuffixRule('Nakajimakōen'), 'Nakajimakōen');
      expect(applyChoSuffixRule('Tsuchidaru'), 'Tsuchidaru');
      expect(applyChoSuffixRule('Tondencho'), 'Tondencho');
    });

    test('マクロンが残るので、確認が要る', () {
      final table = OazaRomajiTable.parse(jsonEncode({'01102': {'屯田町': 'Tondenchō'}}));
      final tonden = table.lookup('01102', '屯田町')!;
      expect(tonden.value, 'Tonden-chō');
      expect(tonden.needsConfirmation, isTrue);
    });

    test('同梱の対応表でも、末尾の chō の前にハイフンが入る', () {
      final bundled = OazaRomajiTable.parse(File('assets/data/oaza_romaji.json').readAsStringSync());
      expect(bundled.lookup('01102', '屯田町')?.value, 'Tonden-chō');
      expect(bundled.lookup('01103', '丘珠町')?.value, 'Okadama-chō');
    });
  });

  /// 同梱している対応表(assets/data/oaza_romaji.json)。
  group('同梱の対応表', () {
    final table = OazaRomajiTable.parse(File('assets/data/oaza_romaji.json').readAsStringSync());

    test('マクロンを含まない綴りは、そのまま使ってよい', () {
      final tsuchidaru = table.lookup('15461', '土樽')!;
      expect(tsuchidaru.value, 'Tsuchidaru');
      expect(tsuchidaru.needsConfirmation, isFalse);
      // 逆ジオコーダが「大字」付きや丁目付きで返しても引ける
      expect(table.lookup('15461', '大字土樽')?.value, 'Tsuchidaru');
    });

    test('マクロンを含む綴りは、確認が要る(語の境目の oo を長音にしていることがある)', () {
      final shimooritate = table.lookup('15225', '下折立')!;
      expect(shimooritate.value, 'Shimōritate');
      expect(shimooritate.needsConfirmation, isTrue);
    });

    test('2つのデータで綴りが違うときは、読みと合うほうを採る', () {
      // 町字マスターは Otano、郵便番号データは ODANO。読みはオダノ
      expect(table.lookup('08225', '小田野')?.value, 'Odano');
    });

    test('表に無い大字や自治体は null', () {
      expect(table.lookup('15225', '存在しない大字'), isNull);
      expect(table.lookup('99999', '下折立'), isNull);
      expect(table.lookup(null, '下折立'), isNull);
    });
  });

  group('buildPlaceInfo の大字のローマ字', () {
    late AppDatabase db;
    final directory = JsonMunicipalityDirectory.parse(jsonEncode({
      '15225': {'prefJa': '新潟県', 'muniJa': '魚沼市', 'prefEn': 'Niigata-ken', 'muniEn': 'Uonuma-shi'},
    }));
    final table = OazaRomajiTable.parse(jsonEncode({
      '15225': {'下折立': 'Shimōritate', '大白川': 'Oshirakawa'},
    }));
    const shimooritate = GsiAddress(municipalityCode: '15225', localityJa: '下折立');
    const oshirakawa = GsiAddress(municipalityCode: '15225', localityJa: '大白川');

    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('マクロンを含まない公的データの綴りは自動で入り、含むものは入れない', () async {
      expect((await buildPlaceInfo(db, directory, oshirakawa, oaza: table)).localityEn, 'Oshirakawa');
      expect((await buildPlaceInfo(db, directory, shimooritate, oaza: table)).localityEn, isNull);
    });

    test('手入力 > 辞書 > 公的データ の順に使う', () async {
      await rememberPlaceRomaji(db, municipalityCode: '15225', localityJa: '大白川', localityEn: 'Ōshirakawa');
      expect((await buildPlaceInfo(db, directory, oshirakawa, oaza: table)).localityEn, 'Ōshirakawa');
      expect(
        (await buildPlaceInfo(db, directory, oshirakawa, oaza: table, currentLocalityEn: 'Manual')).localityEn,
        'Manual',
      );
    });
  });
}
