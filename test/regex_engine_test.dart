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

    test('稀有度大于20%小于120%', () {
      final r = RegexEngine.generate('稀有度大于20%小于120%')!;
      expect(r.pattern, contains('稀有度'));
      expect(r.pattern, contains('%'));
      // 21-119 区间
      final regex = RegExp(r.pattern);
      expect(regex.hasMatch('稀有度: 85%'), isTrue);
      expect(regex.hasMatch('稀有度: 21%'), isTrue);
      expect(regex.hasMatch('稀有度: 119%'), isTrue);
      expect(regex.hasMatch('稀有度: 20%'), isFalse);
      expect(regex.hasMatch('稀有度: 120%'), isFalse);
    });

    test('大于20小于120（无类型）', () {
      final r = RegexEngine.generate('大于20小于120')!;
      expect(r.pattern, isNot(contains('稀有度')));
      final regex = RegExp(r.pattern);
      expect(regex.hasMatch('100'), isTrue);
      expect(regex.hasMatch('20'), isFalse);
      expect(regex.hasMatch('120'), isFalse);
    });

    test('物品等级大于80', () {
      final r = RegexEngine.generate('物品等级大于80')!;
      expect(r.pattern, contains('物品等级'));
      final regex = RegExp(r.pattern);
      expect(regex.hasMatch('物品等级: 90'), isTrue);
      expect(regex.hasMatch('物品等级: 80'), isFalse);
    });

    test('大于等于20小于等于120（含边界）', () {
      final r = RegexEngine.generate('大于等于20小于等于120')!;
      final regex = RegExp(r.pattern);
      expect(regex.hasMatch('20'), isTrue);
      expect(regex.hasMatch('120'), isTrue);
      expect(regex.hasMatch('19'), isFalse);
      expect(regex.hasMatch('121'), isFalse);
    });

    test('区间生成覆盖跨位数', () {
      final r = RegexEngine.generate('大于95小于105')!;
      final regex = RegExp(r.pattern);
      for (var i = 96; i <= 104; i++) {
        expect(regex.hasMatch('$i'), isTrue, reason: '$i 应在区间内');
      }
      expect(regex.hasMatch('95'), isFalse);
      expect(regex.hasMatch('105'), isFalse);
    });
  });
}
