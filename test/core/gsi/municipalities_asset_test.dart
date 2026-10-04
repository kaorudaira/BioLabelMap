import 'dart:io';

import 'package:biolabelmap/core/gsi/municipality_directory.dart';
import 'package:flutter_test/flutter_test.dart';

/// 同梱している対応表(assets/data/municipalities.json)の中身を確かめる。
void main() {
  final directory = JsonMunicipalityDirectory.parse(
    File('assets/data/municipalities.json').readAsStringSync(),
  );

  test('要件定義の例(魚沼市)', () {
    final names = directory.lookup('15225')!;
    expect(names.prefectureJa, '新潟県');
    expect(names.municipalityJa, '魚沼市');
    expect(names.prefectureEn, 'Niigata-ken');
    expect(names.municipalityEn, 'Uonuma-shi');
    expect(names.verified, isTrue);
  });

  test('要件定義のマクロンの例', () {
    expect(directory.lookup('13101')!.prefectureEn, 'Tōkyō-to');
    expect(directory.lookup('27100')!.prefectureEn, 'Ōsaka-fu');
    expect(directory.lookup('28100')!.prefectureEn, 'Hyōgo-ken');
    expect(directory.lookup('01202')!.prefectureEn, 'Hokkaidō');
  });

  test('政令指定都市の区と市', () {
    expect(directory.lookup('01101')!.municipalityEn, 'Sapporo-shi Chūō-ku');
    expect(directory.lookup('01100')!.municipalityEn, 'Sapporo-shi');
    expect(directory.lookup('28100')!.municipalityEn, 'Kōbe-shi');
  });

  test('町村は郡を分けて持つ', () {
    final yuzawa = directory.lookup('15461')!;
    expect(yuzawa.municipalityEn, 'Yuzawa-machi');
    expect(yuzawa.countyEn, 'Minamiuonuma-gun');
    expect(yuzawa.countyJa, '南魚沼郡');
  });
}
