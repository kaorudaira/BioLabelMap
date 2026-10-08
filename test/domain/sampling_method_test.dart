import 'package:biolabelmap/domain/sampling_method.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatSamplingMethod', () {
    test('「その他」は、自由入力があれば「その他：{内容}」の形にする', () {
      expect(formatSamplingMethod(SamplingMethod.other, '朽木割り'), 'その他：朽木割り');
      expect(formatSamplingMethod(SamplingMethod.other, '  朽木割り '), 'その他：朽木割り');
    });

    test('「その他」で自由入力が無ければ、「その他」だけ', () {
      expect(formatSamplingMethod(SamplingMethod.other, null), 'その他');
      expect(formatSamplingMethod(SamplingMethod.other, '  '), 'その他');
    });

    test('ほかの採集方法は、名前のまま(自由入力が残っていても使わない)', () {
      expect(formatSamplingMethod(SamplingMethod.sweeping, null), 'スウィーピング');
      expect(formatSamplingMethod(SamplingMethod.sweeping, '朽木割り'), 'スウィーピング');
    });
  });
}
