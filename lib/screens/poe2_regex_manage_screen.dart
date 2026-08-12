import 'package:flutter/material.dart';

import '../data/poe2_regex_data.dart';
import '../services/poe2_regex_store.dart';

class Poe2RegexManageScreen extends StatefulWidget {
  const Poe2RegexManageScreen({super.key});

  @override
  State<Poe2RegexManageScreen> createState() => _Poe2RegexManageScreenState();
}

class _Poe2RegexManageScreenState extends State<Poe2RegexManageScreen> {
  final _store = Poe2RegexStore();
  List<Poe2RegexItem> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _store.load();
    if (mounted) setState(() => _items = items);
  }

  Future<void> _save() => _store.save(_items);

  Future<void> _add() async {
    final result = await _showEditor(null);
    if (result != null) {
      final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
      setState(() {
        _items.add(Poe2RegexItem(
          id: id,
          label: result.label,
          cn: result.cn,
          tc: result.tc,
          group: result.group,
          category: result.category,
        ));
      });
      await _save();
    }
  }

  Future<void> _edit(Poe2RegexItem item) async {
    final result = await _showEditor(item);
    if (result != null) {
      setState(() {
        final index = _items.indexWhere((e) => e.id == item.id);
        if (index >= 0) {
          _items[index] = Poe2RegexItem(
            id: item.id,
            label: result.label,
            cn: result.cn,
            tc: result.tc,
            group: result.group,
            category: result.category,
          );
        }
      });
      await _save();
    }
  }

  Future<void> _delete(Poe2RegexItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除词条'),
        content: Text('确定删除「${item.label}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() => _items.removeWhere((e) => e.id == item.id));
      await _save();
    }
  }

  Future<_EditorResult?> _showEditor(Poe2RegexItem? item) async {
    final labelController = TextEditingController(text: item?.label ?? '');
    final cnController = TextEditingController(text: item?.cn ?? '');
    final tcController = TextEditingController(text: item?.tc ?? '');
    String category = item?.category ?? 'maps';
    String group = item?.group ?? '前缀';

    final result = await showDialog<_EditorResult>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(item == null ? '新增词条' : '编辑词条'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(
                    labelText: '分类',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final c in kPoe2RegexCategories)
                      DropdownMenuItem(value: kPoe2RegexCategoryIds[c]!, child: Text(c)),
                  ],
                  onChanged: (v) => setDialogState(() => category = v ?? 'maps'),
                ),
                const SizedBox(height: 12),
                if (category == 'maps')
                  DropdownButtonFormField<String>(
                    value: group,
                    decoration: const InputDecoration(
                      labelText: '前后缀',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final g in kPoe2MapAffixGroups)
                        DropdownMenuItem(value: g, child: Text(g)),
                    ],
                    onChanged: (v) => setDialogState(() => group = v ?? '前缀'),
                  ),
                if (category == 'maps') const SizedBox(height: 12),
                TextField(
                  controller: labelController,
                  decoration: const InputDecoration(
                    labelText: '名称',
                    hintText: '例如：新增词缀 X%',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: cnController,
                  maxLines: 2,
                  style: const TextStyle(fontFamily: 'monospace'),
                  decoration: const InputDecoration(
                    labelText: '简体正则',
                    hintText: r'例如：.*[0-9.]+%新词缀',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: tcController,
                  maxLines: 2,
                  style: const TextStyle(fontFamily: 'monospace'),
                  decoration: const InputDecoration(
                    labelText: '繁体正则（可选）',
                    hintText: '不填则繁体时使用简体正则',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                if (labelController.text.trim().isEmpty ||
                    cnController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('名称和简体正则不能为空')),
                  );
                  return;
                }
                Navigator.pop(
                  context,
                  _EditorResult(
                    label: labelController.text.trim(),
                    cn: cnController.text.trim(),
                    tc: tcController.text.trim(),
                    category: category,
                    group: group,
                  ),
                );
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final categories = kPoe2RegexCategories
        .where((c) => _items.any((e) => e.category == kPoe2RegexCategoryIds[c]))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('管理自定义词条'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '新增词条',
            onPressed: _add,
          ),
        ],
      ),
      body: _items.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_chart,
                      size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text('还没有自定义词条\n点击右上角 + 新增',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade500)),
                ],
              ),
            )
          : ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '游戏版本更新后，可在这里新增/修改/删除词条，构建器会自动生效。',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ),
                for (final category in categories) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Text(
                      category,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  for (final item in _items
                      .where((e) => e.category == kPoe2RegexCategoryIds[category]))
                    Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: ListTile(
                        title: Text(item.label,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          item.cn,
                          style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                              color: Colors.grey.shade600),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 18),
                              tooltip: '编辑',
                              onPressed: () => _edit(item),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline,
                                  size: 18, color: Colors.red.shade400),
                              tooltip: '删除',
                              onPressed: () => _delete(item),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
                const SizedBox(height: 24),
              ],
            ),
    );
  }
}

class _EditorResult {
  final String label;
  final String cn;
  final String tc;
  final String category;
  final String group;

  const _EditorResult({
    required this.label,
    required this.cn,
    required this.tc,
    required this.category,
    required this.group,
  });
}
