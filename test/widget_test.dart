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
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: Poe2RegexBuilderScreen()));

    await tester.tap(find.text('石板'));
    await tester.pumpAndSettle();

    expect(find.text('请先选择石板类型'), findsOneWidget);

    await tester.tap(find.text('裂隙'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('孕育赠礼数量提高'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('孕育赠礼数量提高'), findsOneWidget);
    expect(find.text('引路石数量提高'), findsOneWidget);

    await tester.tap(find.text('孕育赠礼数量提高'));
    await tester.pumpAndSettle();

    expect(find.textContaining('孕育赠礼'), findsWidgets);
  });
}
