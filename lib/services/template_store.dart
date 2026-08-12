import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/regex_template.dart';

class TemplateStore {
  static const _kKey = 'custom_templates';

  Future<List<RegexTemplate>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => RegexTemplate.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<RegexTemplate>> add(RegexTemplate template) async {
    final templates = await load();
    templates.add(template);
    await _save(templates);
    return templates;
  }

  Future<List<RegexTemplate>> remove(RegexTemplate template) async {
    final templates = await load();
    templates.removeWhere((t) =>
        t.name == template.name &&
        t.pattern == template.pattern &&
        t.explanation == template.explanation);
    await _save(templates);
    return templates;
  }

  Future<void> _save(List<RegexTemplate> templates) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kKey,
      jsonEncode(templates.map((t) => t.toJson()).toList()),
    );
  }
}
