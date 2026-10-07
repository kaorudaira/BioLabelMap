import 'package:biolabelmap/domain/macron_notice.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('判断が分かれる自治体名は、注意の対象', () {
    expect(ambiguousMacronName(municipalityEn: 'Ōmu-chō'), 'Ōmu-chō');
    expect(ambiguousMacronName(municipalityEn: 'Ōme-shi'), 'Ōme-shi');
    expect(ambiguousMacronName(countyEn: 'Ōra-gun', municipalityEn: 'Ōizumi-machi'), 'Ōra-gun');
    expect(ambiguousMacronName(countyEn: 'Kudō-gun', municipalityEn: 'Setana-chō'), 'Kudō-gun');
  });

  test('それ以外は対象外', () {
    expect(ambiguousMacronName(municipalityEn: 'Ōizumi-machi'), isNull);
    expect(ambiguousMacronName(), isNull);
  });
}
