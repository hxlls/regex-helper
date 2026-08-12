import 'package:flutter_test/flutter_test.dart';

import 'package:regex_helper/main.dart';

void main() {
  testWidgets('app starts and renders home', (WidgetTester tester) async {
    await tester.pumpWidget(const RegexHelperApp());
    expect(find.text('正则助手'), findsOneWidget);
    expect(find.text('用中文描述你的需求'), findsOneWidget);
    expect(find.text('生成正则'), findsOneWidget);
  });
}
