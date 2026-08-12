import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/poe2_regex_data.dart';

class Poe2RegexStore {
  static const _kKey = 'poe2_regex_custom_items';

  Future<List<Poe2RegexItem>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => Poe2RegexItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save(List<Poe2RegexItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kKey,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }
}

const List<String> kPoe2RegexCategories = [
  '地图词缀',
  '地图机制',
  '石板',
  '装备词缀',
  '装备类别',
];

const Map<String, String> kPoe2RegexCategoryIds = {
  '地图词缀': 'maps',
  '地图机制': 'mechanics',
  '石板': 'tablet',
  '装备词缀': 'items',
  '装备类别': 'classes',
};

const List<String> kPoe2MapAffixGroups = ['前缀', '后缀'];
