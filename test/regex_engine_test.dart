import 'package:flutter_test/flutter_test.dart';

import 'package:regex_helper/engine/regex_engine.dart';

void main() {
  group('RegexEngine', () {
    test('匹配11位手机号', () {
      final r = RegexEngine.generate('匹配11位手机号')!;
      expect(r.pattern, contains('1[3-9]'));
      expect(r.anchored, isTrue);
    });

    test('提取邮箱', () {
      final r = RegexEngine.generate('提取邮箱地址')!;
      expect(r.pattern, contains('@'));
      expect(r.anchored, isFalse);
    });

    test('校验身份证', () {
      final r = RegexEngine.generate('校验18位身份证号')!;
      expect(r.pattern, contains(r'\d{17}'));
      expect(r.anchored, isTrue);
    });

    test('IP地址', () {
      final r = RegexEngine.generate('匹配IP地址')!;
      expect(r.pattern, contains('25[0-5]'));
    });

    test('纯数字6位', () {
      final r = RegexEngine.generate('6位纯数字')!;
      expect(r.pattern, r'\d{6}');
      expect(r.anchored, isTrue);
    });

    test('6-16位字母数字', () {
      final r = RegexEngine.generate('6-16位字母和数字')!;
      expect(r.pattern, r'[a-zA-Z0-9]{6,16}');
    });

    test('提取日期', () {
      final r = RegexEngine.generate('提取日期')!;
      expect(r.pattern, contains(r'\d{4}'));
    });

    test('中文', () {
      final r = RegexEngine.generate('匹配中文')!;
      expect(r.pattern, contains('u4e00'));
    });

    test('空描述返回null', () {
      expect(RegexEngine.generate(''), isNull);
      expect(RegexEngine.generate('   '), isNull);
    });

    test('兜底字面量', () {
      final r = RegexEngine.generate('匹配abc123')!;
      expect(r.pattern, contains('abc123'));
    });

    test('POE2 匹配崇高石', () {
      final r = RegexEngine.generate('匹配崇高石')!;
      expect(r.pattern, contains('崇高石'));
    });

    test('POE2 匹配通货', () {
      final r = RegexEngine.generate('提取所有通货')!;
      expect(r.pattern, contains('混沌石'));
      expect(r.pattern, contains('神圣石'));
    });

    test('POE2 未切割宝石', () {
      final r = RegexEngine.generate('匹配未切割宝石')!;
      expect(r.pattern, contains('未切割'));
      expect(r.anchored, isTrue);
    });

    test('POE2 石碑地图', () {
      final r = RegexEngine.generate('提取石碑')!;
      expect(r.pattern, contains('石碑'));
    });
  });
}
