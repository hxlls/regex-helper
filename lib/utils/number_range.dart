/// 数值区间/比较运算符 → 正则 工具。
/// 生成匹配满足条件（大于/小于/等于/区间）的整数的正则，带数字边界守卫。
class NumberRangeRegex {
  static int _pow10(int n) {
    var v = 1;
    for (var i = 0; i < n; i++) {
      v *= 10;
    }
    return v;
  }

  static String _anyDigits(int n) => n <= 0 ? '' : '\\d{$n}';

  static String _digitRange(int a, int b) => a == b ? '$a' : '[$a-$b]';

  /// 构造等宽字符串 min/max 的区间正则（a.length == b.length）。
  static String _subRangeStr(String a, String b) {
    int i = 0;
    while (i < a.length && a[i] == b[i]) {
      i++;
    }
    final prefix = a.substring(0, i);
    if (i == a.length) return a;
    final rem = a.length - i;
    final da = int.parse(a[i]);
    final db = int.parse(b[i]);
    final tailLen = rem - 1;
    if (tailLen == 0) {
      return '$prefix[$da-$db]';
    }
    final parts = <String>[];
    if (db - da > 1) {
      parts.add('$prefix${_digitRange(da + 1, db - 1)}${_anyDigits(tailLen)}');
    }
    final minTail = a.substring(i + 1);
    final maxTail = b.substring(i + 1);
    final hi9 = '9' * tailLen;
    final lo0 = '0' * tailLen;
    parts.add('$prefix$da${_subRangeStr(minTail, hi9)}');
    parts.add('$prefix$db${_subRangeStr(lo0, maxTail)}');
    return '(?:${parts.join('|')})';
  }

  /// 匹配 [min, max] 区间内的整数（含边界）。
  static String _range(int min, int max) {
    if (min == max) return '$min';
    final chunks = <String>[];
    var lo = min;
    while (lo <= max) {
      final len = lo.toString().length;
      final upper = _pow10(len) - 1;
      if (upper < max) {
        chunks.add(_subRangeStr('$lo', '$upper'));
        lo = upper + 1;
      } else {
        chunks.add(_subRangeStr('$lo', '$max'));
        lo = max + 1;
      }
    }
    return chunks.length == 1 ? chunks.first : '(?:${chunks.join('|')})';
  }

  static String _guarded(String inner) => '(?<!\\d)(?:$inner)(?!\\d)';

  /// 大于等于 min（上不封顶）。
  static String _openFrom(int min) {
    if (min <= 0) return _guarded('0|([1-9]\\d*)');
    final len = min.toString().length;
    final upTo9 = _pow10(len) - 1;
    final inner = '(?:${_subRangeStr('$min', '$upTo9')}|\\d{${len + 1},})';
    return _guarded(inner);
  }

  /// 恰好等于 value。
  static String exact(int value) => _guarded('$value');

  /// 大于 value（不含边界）。
  static String gt(int value) => _openFrom(value + 1);

  /// 大于等于 value。
  static String gte(int value) => _openFrom(value);

  /// 小于 value（不含边界）。
  static String lt(int value) => value <= 0 ? _guarded('') : _guarded(_range(0, value - 1));

  /// 小于等于 value。
  static String lte(int value) => value < 0 ? _guarded('') : _guarded(_range(0, value));

  /// 在 [min, max] 区间内。
  static String between(int min, int max) => _guarded(_range(min, max));

  /// 根据比较运算符与数值生成正则。
  /// op: '>' '>=' '<' '<=' '=' 或为空（默认等于）。
  static String byOperator(String op, int value) {
    switch (op) {
      case '>':
        return gt(value);
      case '>=':
        return gte(value);
      case '<':
        return lt(value);
      case '<=':
        return lte(value);
      default:
        return exact(value);
    }
  }
}
