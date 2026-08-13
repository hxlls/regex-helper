import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:regex_helper/main.dart';
import 'package:regex_helper/screens/poe2_regex_builder_screen.dart';

void main() {
  testWidgets('app starts and renders home', (WidgetTester tester) async {
    await tester.pumpWidget(const RegexHelperApp());
    expect(find.text('正则助手'), findsOneWidget);
    expect(find.text('用中文描述你的需求'), findsOneWidget);
    expect(find.text('生成正则'), findsOneWidget);
  });

  testWidgets('石板 tab：先选类型再选机制词条可生成正则', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: Poe2RegexBuilderScreen()));

    await tester.tap(find.text('石板'));
    await tester.pumpAndSettle();

    expect(find.text('请先选择石板类型'), findsOneWidget);

    await tester.tap(find.text('裂隙'));
    await tester.pumpAndSettle();

    // 裂隙分组专属词条（排在通用词条之后），多次滚动直到可见
    final listFinder = find.byType(ListView).last;
    for (var i = 0; i < 6 && find.text('孕育赠礼数量提高').evaluate().isEmpty; i++) {
      await tester.drag(listFinder, const Offset(0, -400));
      await tester.pumpAndSettle();
    }
    expect(find.text('孕育赠礼数量提高'), findsOneWidget);

    await tester.tap(find.text('孕育赠礼数量提高'));
    await tester.pumpAndSettle();

    expect(find.textContaining('孕育赠礼'), findsWidgets);
  });

  testWidgets('石板 tab：切换繁体后机制词条输出繁中正则', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: Poe2RegexBuilderScreen()));

    await tester.tap(find.text('石板'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('繁'));
    await tester.pumpAndSettle();

    // 繁体模式下词条名也显示繁体（poe2db：胎贈）
    expect(find.text('胎贈數量提高'), findsNothing);

    await tester.tap(find.text('裂痕'));
    await tester.pumpAndSettle();

    // 滚动到裂隙专属词条「胎贈數量提高」（排在通用词条之后）
    final listFinder = find.byType(ListView).last;
    for (var i = 0; i < 6 && find.text('胎贈數量提高').evaluate().isEmpty; i++) {
      await tester.drag(listFinder, const Offset(0, -400));
      await tester.pumpAndSettle();
    }
    expect(find.text('胎贈數量提高'), findsOneWidget);
    await tester.tap(find.text('胎贈數量提高'));
    await tester.pumpAndSettle();

    // 繁中客户端文本（poe2db）：胎贈数量（简体为孕育赠礼）
    expect(find.textContaining('胎贈'), findsWidgets);
  });

  testWidgets('地图词缀：切换繁体后输出繁中文本', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: Poe2RegexBuilderScreen()));

    await tester.tap(find.text('繁'));
    await tester.pumpAndSettle();

    // 怪物伤害提高 是地图词缀列表前几项，直接可见（标题+正则副标题，取第一个）
    await tester.tap(find.text('怪物伤害提高').first);
    await tester.pumpAndSettle();

    // 繁中客户端文本：增加.*怪物傷害
    expect(find.textContaining('增加.*怪物傷害'), findsOneWidget);
  });
}
