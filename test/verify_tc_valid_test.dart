import 'package:flutter_test/flutter_test.dart';
import 'package:regex_helper/data/poe2_regex_data.dart';

void main() {
  test('所有词条 cn/tc 均为合法正则', () {
    var checked = 0;
    var nonEmptyTc = 0;
    void check(Poe2RegexItem e) {
      if (e.cn.isEmpty) return;
      checked++;
      try {
        RegExp(e.cn);
      } catch (_) {
        fail('${e.label} cn 非法正则: ${e.cn}');
      }
      if (e.tc != null && e.tc!.isNotEmpty) {
        nonEmptyTc++;
        try {
          RegExp(e.tc!);
        } catch (_) {
          fail('${e.label} tc 非法正则: ${e.tc}');
        }
      }
    }
    for (final e in kPoe2MapAffixes) {
      check(e);
    }
    for (final mods in kPoe2TabletMods.values) {
      for (final e in mods) {
        check(e);
      }
    }
    for (final e in kPoe2ItemModifiers) {
      check(e);
    }
    for (final e in kPoe2Tablet) {
      check(e);
    }
    for (final e in kPoe2Rarity) {
      check(e);
    }
    expect(checked, greaterThan(150));
    expect(nonEmptyTc, greaterThan(150));
    // ignore: avoid_print
    print('校验 $checked 个词条，其中 $nonEmptyTc 个有繁体');
  });

  test('地图词缀与机制词条均有繁体', () {
    for (final e in kPoe2MapAffixes) {
      expect(e.tc, isNotNull, reason: '${e.label} 缺 tc');
      expect(e.tc!.isNotEmpty, isTrue, reason: '${e.label} tc 为空');
    }
    for (final mods in kPoe2TabletMods.values) {
      for (final e in mods) {
        expect(e.tc, isNotNull, reason: '${e.label} 缺 tc');
        expect(e.tc!.isNotEmpty, isTrue, reason: '${e.label} tc 为空');
      }
    }
  });

  test('石板机制词条均有英文名称与英文正则', () {
    var total = 0;
    for (final mods in kPoe2TabletMods.values) {
      for (final e in mods) {
        total++;
        expect(e.en, isNotNull, reason: '${e.label} 缺英文名');
        expect(e.en!.isNotEmpty, isTrue, reason: '${e.label} 英文名为空');
        expect(e.enRegex, isNotNull, reason: '${e.label} 缺英文正则');
        expect(e.enRegex!.isNotEmpty, isTrue, reason: '${e.label} 英文正则为空');
        RegExp(e.enRegex!);
      }
    }
    expect(total, greaterThan(200));
    // ignore: avoid_print
    print('石板机制词条 $total 条，全部有英文名称与正则');
  });

  test('无数值词条（如冰缓地面）无数字占位符，简繁均不含', () {
    final fire = kPoe2MapAffixes.firstWhere((e) => e.id == 'ws_ignite_gnd');
    expect(fire.cn, contains('点燃地面'));
    expect(fire.tc, isNotNull);
    expect(fire.tc, isNot(contains('[0-9')));

    final ground = kPoe2MapAffixes.firstWhere((e) => e.id == 'ws_chill_gnd');
    expect(ground.cn, contains('冰缓地面'));
    expect(ground.tc, isNot(contains('[0-9')));

    // 统计无数值占位符的词条（纯文本词条，如地面/诅咒）
    var noNum = 0;
    for (final e in kPoe2MapAffixes) {
      if (!e.cn.contains('[0-9')) noNum++;
    }
    // 纯文本词条与有数值词条并存
    expect(noNum, greaterThan(5));
    expect(noNum, lessThan(40));
    // 有数值词条（怪物伤害提高等）应含占位符，支持数值输入
    final dmg = kPoe2MapAffixes.firstWhere((e) => e.id == 'ws_mon_dmg');
    expect(dmg.cn, contains('[0-9'));
  });

  test('地图词缀简体/繁体各对应不同的游戏文本（非逐字转换）', () {
    // 简体「引路石」繁体为「換界石」这类词汇级差异
    final waystone = kPoe2TabletMods['abyss']!.firstWhere((e) => e.id == 'as_waystone');
    expect(waystone.cn, contains('引路石'));
    expect(waystone.tc, contains('換界石'));
    // 简体「精华」繁体为「精髓」
    final essence = kPoe2TabletMods['breach']!.firstWhere((e) => e.id == 'bs_essence');
    expect(essence.cn, contains('精华'));
    expect(essence.tc, contains('精髓'));
  });
}
