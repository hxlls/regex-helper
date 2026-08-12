import 'package:flutter_test/flutter_test.dart';

import 'package:regex_helper/utils/number_range.dart';

void main() {
  RegExp re(String p) => RegExp(p);

  void checkRange(String desc, String pattern, int lo, int hi) {
    test(desc, () {
      final r = re(pattern);
      for (var i = lo; i <= hi; i++) {
        expect(r.hasMatch('$i'), isTrue, reason: '$i 应在范围内 ($pattern)');
      }
      if (lo > 0) {
        expect(r.hasMatch('${lo - 1}'), isFalse,
            reason: '${lo - 1} 不应匹配');
      }
      expect(r.hasMatch('${hi + 1}'), isFalse, reason: '${hi + 1} 不应匹配');
      // 更大数字中的子串不应误匹配
      expect(r.hasMatch('1${hi + 1}'), isFalse, reason: '子串不应匹配');
    });
  }

  checkRange('exact(50)', NumberRangeRegex.exact(50), 50, 50);
  checkRange('between(20,120)', NumberRangeRegex.between(20, 120), 20, 120);
  checkRange('lte(50)', NumberRangeRegex.lte(50), 0, 50);

  test('gt(50) 匹配 51 及以上', () {
    final r = re(NumberRangeRegex.gt(50));
    for (var i = 51; i <= 130; i++) {
      expect(r.hasMatch('$i'), isTrue, reason: '$i');
    }
    expect(r.hasMatch('1000'), isTrue);
    expect(r.hasMatch('50'), isFalse);
    expect(r.hasMatch('49'), isFalse);
  });

  test('gte(50) 匹配 50 及以上', () {
    final r = re(NumberRangeRegex.gte(50));
    expect(r.hasMatch('50'), isTrue);
    expect(r.hasMatch('49'), isFalse);
    expect(r.hasMatch('999'), isTrue);
  });

  test('lt(50) 匹配 0-49', () {
    final r = re(NumberRangeRegex.lt(50));
    expect(r.hasMatch('0'), isTrue);
    expect(r.hasMatch('49'), isTrue);
    expect(r.hasMatch('50'), isFalse);
  });

  test('lte(50) 匹配 0-50', () {
    final r = re(NumberRangeRegex.lte(50));
    expect(r.hasMatch('50'), isTrue);
    expect(r.hasMatch('51'), isFalse);
    expect(r.hasMatch('12'), isTrue);
  });

  test('byOperator', () {
    expect(re(NumberRangeRegex.byOperator('>', 20)).hasMatch('21'), isTrue);
    expect(re(NumberRangeRegex.byOperator('>', 20)).hasMatch('20'), isFalse);
    expect(re(NumberRangeRegex.byOperator('>=', 20)).hasMatch('20'), isTrue);
    expect(re(NumberRangeRegex.byOperator('<', 20)).hasMatch('19'), isTrue);
    expect(re(NumberRangeRegex.byOperator('<', 20)).hasMatch('20'), isFalse);
    expect(re(NumberRangeRegex.byOperator('<=', 20)).hasMatch('20'), isTrue);
    expect(re(NumberRangeRegex.byOperator('=', 20)).hasMatch('20'), isTrue);
    expect(re(NumberRangeRegex.byOperator('=', 20)).hasMatch('21'), isFalse);
  });
}
