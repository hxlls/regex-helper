import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:regex_helper/models/regex_template.dart';
import 'package:regex_helper/services/template_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('模板可保存并重新加载', () async {
    final store = TemplateStore();
    await store.add(const RegexTemplate(
      name: '测试模板',
      description: '由 AI 生成',
      pattern: r'^\d{6}$',
      category: '自定义模板',
      example: '',
      explanation: '测试',
    ));

    final loaded = await store.load();
    expect(loaded, hasLength(1));
    expect(loaded.first.name, '测试模板');
    expect(loaded.first.pattern, r'^\d{6}$');
    expect(loaded.first.isCustom, isTrue);
  });

  test('模板可删除', () async {
    final store = TemplateStore();
    const template = RegexTemplate(
      name: '待删模板',
      description: '',
      pattern: r'abc',
      category: '自定义模板',
      example: '',
      explanation: '',
    );
    await store.add(template);
    await store.remove(template);

    final loaded = await store.load();
    expect(loaded, isEmpty);
  });

  test('RegexTemplate JSON 序列化往返', () {
    const t = RegexTemplate(
      name: '邮箱',
      description: '邮箱格式',
      pattern: r'^[\w.+-]+@[\w-]+(?:\.[\w-]+)+$',
      category: '联系方式',
      example: 'a@b.com',
      explanation: '标准邮箱',
    );
    final restored = RegexTemplate.fromJson(t.toJson());
    expect(restored.name, t.name);
    expect(restored.pattern, t.pattern);
    expect(restored.category, t.category);
    expect(restored.isCustom, isFalse);
  });
}
