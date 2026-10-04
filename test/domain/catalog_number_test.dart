import 'package:biolabelmap/domain/catalog_number.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const kyc = CatalogNumberFormat();

  group('CatalogNumberFormat', () {
    test('既定は KYC+5桁のゼロ埋め', () {
      expect(kyc.format(123), 'KYC00123');
      expect(kyc.format(0), 'KYC00000');
    });

    test('接頭辞と桁数を変えられる', () {
      expect(const CatalogNumberFormat(prefix: 'ABC', digits: 3).format(7),
          'ABC007');
    });

    test('桁数を超える番号は切り詰めない', () {
      expect(kyc.format(123456), 'KYC123456');
    });

    test('負の番号はエラー', () {
      expect(() => kyc.format(-1), throwsArgumentError);
    });

    test('発行予定の範囲(記録画面)', () {
      expect(kyc.formatRange(123, 15), 'KYC00123〜KYC00137');
      expect(kyc.formatRange(123, 1), 'KYC00123');
      expect(() => kyc.formatRange(123, 0), throwsArgumentError);
    });

    test('一覧用の短い範囲', () {
      expect(kyc.formatCompactRange(120, 122), 'KYC00120〜122');
      expect(kyc.formatCompactRange(120, 120), 'KYC00120');
    });
  });

  group('nextNumberAfterManual', () {
    test('過去標本(小さい番号)を登録しても次の番号は変えない', () {
      expect(
        nextNumberAfterManual(currentNext: 200, specifiedFirst: 50, count: 3),
        200,
      );
    });

    test('次の番号より大きい番号を指定したら、その続きに進める', () {
      expect(
        nextNumberAfterManual(currentNext: 200, specifiedFirst: 300, count: 3),
        303,
      );
    });

    test('範囲が次の番号をまたぐときも、その続きに進める', () {
      expect(
        nextNumberAfterManual(currentNext: 200, specifiedFirst: 198, count: 5),
        203,
      );
    });
  });
}
