import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:regex_helper/data/poe2_regex_data.dart';
import 'package:regex_helper/services/poe2_regex_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('自定义词条可保存并重新加载', () async {
    final store = Poe2RegexStore();
    await store.save([
      const Poe2RegexItem(
        id: 'custom_1',
        label: '新词缀 X%',
        cn: r'.*[0-9.]+%新词缀',
        tc: r'新詞綴',
        group: '后缀',
        category: 'maps',
      ),
    ]);

    final loaded = await store.load();
    expect(loaded, hasLength(1));
    expect(loaded.first.label, '新词缀 X%');
    expect(loaded.first.cn, r'.*[0-9.]+%新词缀');
    expect(loaded.first.tc, '新詞綴');
    expect(loaded.first.category, 'maps');
    expect(loaded.first.isCustom, isTrue);
  });

  test('Poe2RegexItem JSON 序列化往返', () {
    const item = Poe2RegexItem(
      id: 'custom_2',
      label: '测试词条',
      cn: r'测试.*[0-9]+',
      tc: '',
      category: 'mechanics',
    );
    final restored = Poe2RegexItem.fromJson(item.toJson());
    expect(restored.id, item.id);
    expect(restored.cn, item.cn);
    expect(restored.tc, isNull);
  });
}
