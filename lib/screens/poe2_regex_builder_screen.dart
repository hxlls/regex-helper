import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/poe2_regex_data.dart';
import '../models/regex_template.dart';
import '../services/poe2_regex_store.dart';
import '../services/template_store.dart';
import '../utils/number_range.dart';
import 'poe2_regex_manage_screen.dart';

class Poe2RegexBuilderScreen extends StatefulWidget {
  const Poe2RegexBuilderScreen({super.key});

  @override
  State<Poe2RegexBuilderScreen> createState() => _Poe2RegexBuilderScreenState();
}

class _Poe2RegexBuilderScreenState extends State<Poe2RegexBuilderScreen> {
  bool _isTc = false;
  String _search = '';
  String _affixFilter = '全部';
  final Set<String> _selected = {};
  final Set<String> _mechSelected = {};
  final Set<String> _tabletSelected = {};
  final Set<String> _classSelected = {};
  final Set<String> _specialSelected = {};
  final TextEditingController _customController = TextEditingController();
  int _mode = 0; // 0=任一(或) 1=全部(且) 2=隐藏(不含)
  final _store = Poe2RegexStore();
  List<Poe2RegexItem> _customItems = [];
  final Map<String, TextEditingController> _minControllers = {};
  final Map<String, TextEditingController> _maxControllers = {};

  @override
  void dispose() {
    _customController.dispose();
    for (final c in _minControllers.values) {
      c.dispose();
    }
    for (final c in _maxControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _minControllerOf(String id) {
    return _minControllers.putIfAbsent(id, TextEditingController.new);
  }

  TextEditingController _maxControllerOf(String id) {
    return _maxControllers.putIfAbsent(id, TextEditingController.new);
  }

  String _minOf(String id) => _minControllers[id]?.text ?? '';
  String _maxOf(String id) => _maxControllers[id]?.text ?? '';

  @override
  void initState() {
    super.initState();
    _loadCustom();
  }

  Future<void> _loadCustom() async {
    final items = await _store.load();
    if (mounted) setState(() => _customItems = items);
  }

  Set<String> _setFor(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return _selected;
      case 1:
        return _mechSelected;
      case 2:
        return _tabletSelected;
      case 3:
        return _classSelected;
      case 4:
        return _specialSelected;
      default:
        return {};
    }
  }

  List<Poe2RegexItem> _itemsFor(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return _filteredMapAffixes;
      case 1:
        return _filteredMechanicMods;
      case 2:
        return [...kPoe2Tablet, ..._customOf('tablet')];
      case 3:
        return [...kPoe2ItemClasses, ..._customOf('classes')];
      case 4:
        return [...kPoe2SpecialMods, ..._customOf('special')];
      default:
        return const [];
    }
  }

  List<Poe2RegexItem> _customOf(String category) {
    return _customItems.where((e) => e.category == category).toList();
  }

  List<Poe2RegexItem> get _filteredMapAffixes {
    var list = <Poe2RegexItem>[
      ...kPoe2MapAffixes,
      ..._customOf('maps'),
    ];
    if (_affixFilter == '前缀') {
      list = list.where((e) => e.group == '前缀').toList();
    } else if (_affixFilter == '后缀') {
      list = list.where((e) => e.group == '后缀').toList();
    }
    if (_search.isNotEmpty) {
      list = list
          .where((e) => e.label.contains(_search) || e.cn.contains(_search))
          .toList();
    }
    return list;
  }

  List<Poe2RegexItem> get _filteredMechanicMods {
    final all = <Poe2RegexItem>[
      ...kPoe2MechanicMods,
      ..._customOf('mechanics'),
    ];
    if (_search.isEmpty) return all;
    return all
        .where((e) => e.label.contains(_search) || e.cn.contains(_search))
        .toList();
  }

  String _patternOf(Poe2RegexItem item, int tabIndex) {
    if (tabIndex == 0 || tabIndex == 4) {
      return _isTc ? (item.tc?.isNotEmpty == true ? item.tc! : item.cn) : item.cn;
    }
    return item.cn;
  }

  static String _applyRange(String pattern, String minText, String maxText) {
    final minStr = minText.trim();
    final maxStr = maxText.trim();
    if (minStr.isEmpty && maxStr.isEmpty) return pattern;
    int? min = int.tryParse(minStr);
    int? max = int.tryParse(maxStr);
    if (min != null && max != null && min > max) {
      final t = min;
      min = max;
      max = t;
    }
    String numPattern;
    if (min != null && max != null) {
      numPattern = NumberRangeRegex.between(min, max);
    } else if (min != null) {
      numPattern = NumberRangeRegex.gte(min);
    } else {
      numPattern = NumberRangeRegex.lte(max!);
    }
    // 用生成的数值正则替换模式中的数字占位符 [0-9.]+ 或 [0-9]+
    final replaced =
        pattern.replaceAll(RegExp(r'\[0-9\.\]\+|\[0-9\]\+'), numPattern);
    if (replaced != pattern) return replaced;
    // 模式中没有数字占位符时，把数值正则追加在末尾（带上 %）
    return '$pattern.*$numPattern%';
  }

  String get _output {
    if (tabIndexCustom) {
      return _customController.text.trim();
    }
    final tab = _currentTab;
    final items = _itemsFor(tab);
    final selectedSet = _setFor(tab);
    final patterns = items
        .where((e) => selectedSet.contains(e.id))
        .map((e) =>
            _applyRange(_patternOf(e, tab), _minOf(e.id), _maxOf(e.id)))
        .where((p) => p.isNotEmpty)
        .toList();
    if (patterns.isEmpty) return '';
    if (_mode == 2) {
      // 隐藏：匹配不包含任何所选词条的文本
      final neg = patterns.map((p) => '(?!$p)').join('');
      return '^(?:$neg[\\s\\S])*\$';
    }
    if (_mode == 1) {
      // 跨行安全：[\s\S]* 可跨越换行，多个词条须同时存在
      return patterns.map((p) => '(?=[\\s\\S]*$p)').join('');
    }
    if (patterns.length == 1) return patterns.first;
    return '(${patterns.join('|')})';
  }

  bool get tabIndexCustom => _tabController?.index == 5;
  int get _currentTab => _tabController?.index ?? 0;
  TabController? _tabController;

  void _toggle(TabController controller, Poe2RegexItem item) {
    final set = _setFor(controller.index);
    setState(() {
      if (set.contains(item.id)) {
        set.remove(item.id);
      } else {
        set.add(item.id);
      }
    });
  }

  void _selectAll(TabController controller) {
    final set = _setFor(controller.index);
    setState(() {
      for (final e in _itemsFor(controller.index)) {
        set.add(e.id);
      }
    });
  }

  void _clearAll(TabController controller) {
    final set = _setFor(controller.index);
    setState(() => set.clear());
  }

  Future<void> _saveToTemplate() async {
    final output = _output;
    if (output.isEmpty) return;
    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('保存到模板库'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '模板名称',
            hintText: '例如：POE2 地图词缀组合',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, nameController.text.trim()),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    final store = TemplateStore();
    await store.add(RegexTemplate(
      name: name,
      description: '由 POE2 正则构建器生成',
      pattern: output,
      category: '自定义模板',
      example: '',
      explanation: 'POE2 正则构建器组合结果',
    ));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已保存到模板库')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: Builder(builder: (context) {
        final controller = DefaultTabController.of(context);
        _tabController = controller;
        return Scaffold(
          appBar: AppBar(
            title: const Text('POE2 正则构建器'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_note),
                tooltip: '管理自定义词条',
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const Poe2RegexManageScreen()),
                  );
                  _loadCustom();
                },
              ),
            ],
            bottom: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: const [
                Tab(text: '地图词缀'),
                Tab(text: '地图机制'),
                Tab(text: '石板'),
                Tab(text: '装备类别'),
                Tab(text: '特殊词缀'),
                Tab(text: '自定义'),
              ],
            ),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          isDense: true,
                          prefixIcon: Icon(Icons.search, size: 20),
                          hintText: '搜索词缀',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) => setState(() => _search = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: false, label: Text('简')),
                        ButtonSegment(value: true, label: Text('繁')),
                      ],
                      selected: {_isTc},
                      onSelectionChanged: (s) =>
                          setState(() => _isTc = s.first),
                    ),
                  ],
                ),
              ),
              if (controller.index == 0)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      for (final f in ['全部', '前缀', '后缀'])
                        ChoiceChip(
                          label: Text(f),
                          selected: _affixFilter == f,
                          onSelected: (_) => setState(() => _affixFilter = f),
                        ),
                    ],
                  ),
                ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildList(controller, 0),
                    _buildGroupedList(controller),
                    _buildList(controller, 2),
                    _buildList(controller, 3),
                    _buildList(controller, 4),
                    _buildCustom(controller),
                  ],
                ),
              ),
              _buildOutputPanel(context),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildList(TabController controller, int tabIndex) {
    final items = _itemsFor(tabIndex);
    final set = _setFor(tabIndex);
    return Column(
      children: [
        _buildToolbar(controller, set, tabIndex),
        Expanded(
          child: ListView(
            children: [
              for (final item in items)
                _ItemTile(
                  item: item,
                  selected: set.contains(item.id),
                  minController: _minControllerOf(item.id),
                  maxController: _maxControllerOf(item.id),
                  showValueInput: tabIndex == 0 || tabIndex == 1 || tabIndex == 4,
                  onToggle: (_) => _toggle(controller, item),
                  onChanged: (_) => setState(() {}),
                ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGroupedList(TabController controller) {
    final items = _filteredMechanicMods;
    final set = _setFor(1);
    final groups = <String>[];
    for (final e in items) {
      if (!groups.contains(e.group)) groups.add(e.group);
    }
    return Column(
      children: [
        _buildToolbar(controller, set, 1),
        Expanded(
          child: ListView(
            children: [
              for (final g in groups) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                  child: Text(
                    g,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                for (final item in items.where((e) => e.group == g))
                  _ItemTile(
                    item: item,
                    selected: set.contains(item.id),
                    minController: _minControllerOf(item.id),
                    maxController: _maxControllerOf(item.id),
                    showValueInput: true,
                    onToggle: (_) => _toggle(controller, item),
                    onChanged: (_) => setState(() {}),
                  ),
              ],
              const SizedBox(height: 80),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar(
      TabController controller, Set<String> set, int tabIndex) {
    final total = _itemsFor(tabIndex).length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Text('已选 ${set.length} / $total',
              style: const TextStyle(fontSize: 13)),
          const Spacer(),
          TextButton(onPressed: () => _selectAll(controller), child: const Text('全选')),
          TextButton(onPressed: () => _clearAll(controller), child: const Text('清空')),
        ],
      ),
    );
  }

  Widget _buildCustom(TabController controller) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _customController,
        onChanged: (_) => setState(() {}),
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
        decoration: const InputDecoration(
          hintText: '在这里手动输入或粘贴正则表达式…',
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildOutputPanel(BuildContext context) {
    final output = _output;
    return Material(
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('输出',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 12),
                  SegmentedButton<int>(
                    style: const ButtonStyle(
                        visualDensity: VisualDensity.compact),
                    segments: const [
                      ButtonSegment(value: 0, label: Text('任一(或)')),
                      ButtonSegment(value: 1, label: Text('全部(且)')),
                      ButtonSegment(value: 2, label: Text('隐藏(不含)')),
                    ],
                    selected: {_mode},
                    onSelectionChanged: (s) =>
                        setState(() => _mode = s.first),
                  ),
                  const Spacer(),
                  if (output.isNotEmpty)
                    Text('${output.length} 字符',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600)),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  output.isEmpty ? '（未选择任何词缀）' : output,
                  style: const TextStyle(
                      fontFamily: 'monospace', fontSize: 13),
                ),
              ),
              if (output.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _mode == 0
                        ? '任一(或)：匹配任意一个词条即可'
                        : _mode == 1
                            ? '全部(且)：一件物品需同时存在这些词条（可跨行）'
                            : '隐藏(不含)：匹配不包含这些词条的物品',
                    style: TextStyle(
                        fontSize: 11, color: Colors.blueGrey.shade600),
                  ),
                ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('复制'),
                    onPressed: output.isEmpty
                        ? null
                        : () {
                            Clipboard.setData(
                                ClipboardData(text: output));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('已复制正则')),
                            );
                          },
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.science, size: 18),
                    label: const Text('测试'),
                    onPressed: output.isEmpty
                        ? null
                        : () => Navigator.pushNamed(context, '/tester',
                            arguments: output),
                  ),
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                    label: const Text('存模板'),
                    onPressed: output.isEmpty ? null : _saveToTemplate,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final Poe2RegexItem item;
  final bool selected;
  final TextEditingController minController;
  final TextEditingController maxController;
  final bool showValueInput;
  final ValueChanged<bool> onToggle;
  final ValueChanged<String> onChanged;

  const _ItemTile({
    required this.item,
    required this.selected,
    required this.minController,
    required this.maxController,
    required this.showValueInput,
    required this.onToggle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          dense: true,
          title: Text(item.label, style: const TextStyle(fontSize: 14)),
          subtitle: item.cn.isNotEmpty
              ? Text(
                  item.cn,
                  style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: Colors.grey.shade600),
                )
              : null,
          value: selected,
          onChanged: (v) => onToggle(v ?? false),
        ),
        if (selected && showValueInput)
          Padding(
            padding: const EdgeInsets.only(left: 52, right: 16, bottom: 8),
            child: Row(
              children: [
                const Text('下限',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(width: 6),
                SizedBox(
                  width: 56,
                  child: TextField(
                    controller: minController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13),
                    onChanged: onChanged,
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: '0',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text('上限',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(width: 6),
                SizedBox(
                  width: 56,
                  child: TextField(
                    controller: maxController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13),
                    onChanged: onChanged,
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: '999',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _hint,
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String get _hint {
    if (item.cn.contains('[0-9.]+') || item.cn.contains('[0-9]+')) {
      return '填数值替换模式中的数字';
    }
    return '该词条无数字占位符';
  }
}
