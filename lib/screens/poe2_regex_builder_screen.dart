import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/poe2_regex_data.dart';
import '../models/regex_template.dart';
import '../services/poe2_regex_store.dart';
import '../services/template_store.dart';
import '../utils/number_range.dart';
import 'poe2_regex_manage_screen.dart';

class _WaystoneStat {
  final String id;
  final String cn;
  final String tc;
  final bool isPercent;
  const _WaystoneStat(this.id, this.cn, this.tc, this.isPercent);
}

const List<_WaystoneStat> _kWaystoneStats = [
  _WaystoneStat('pack', '怪物群规模', '怪群大小', true),
  _WaystoneStat('rarity', '物品稀有度', '物品稀有度', true),
  _WaystoneStat('drop', '引路石掉落几率', '換界石掉落機率', true),
  _WaystoneStat('monRarity', '怪物稀有度', '怪物稀有度', true),
  _WaystoneStat('eff', '怪物效能', '怪物效.{0,2}', true),
  _WaystoneStat('magic', '更多地图', '更多地圖', true),
  _WaystoneStat('rare', '更多圣甲虫', '更多聖甲蟲', true),
];

class Poe2RegexBuilderScreen extends StatefulWidget {
  const Poe2RegexBuilderScreen({super.key});

  @override
  State<Poe2RegexBuilderScreen> createState() => _Poe2RegexBuilderScreenState();
}

class _Poe2RegexBuilderScreenState extends State<Poe2RegexBuilderScreen> {
  String _lang = 'cn'; // cn 简体 / tc 繁体 / en 英文
  bool get _isTc => _lang == 'tc';
  bool get _isEn => _lang == 'en';
  String _search = '';
  String _affixFilter = '全部';
  final Set<String> _selected = {};
  String? _tabletType;
  final Set<String> _tabletSelected = {};
  final Set<String> _itemModSelected = {};
  final Set<String> _classSelected = {};
  final TextEditingController _customController = TextEditingController();
  int _mode = 0; // 0=任一(或) 1=全部(且) 2=隐藏(不含)
  final _store = Poe2RegexStore();
  List<Poe2RegexItem> _customItems = [];
  final Map<String, TextEditingController> _minControllers = {};
  final Map<String, TextEditingController> _maxControllers = {};
  final Map<String, TextEditingController> _wsControllers = {};
  final Set<String> _tabletRarities = {};
  final Set<String> _mapRarities = {};
  final TextEditingController _tierMin = TextEditingController();
  final TextEditingController _tierMax = TextEditingController();
  final TextEditingController _tabletUseMin = TextEditingController();
  final TextEditingController _tabletUseMax = TextEditingController();
  String? _corrupted; // null=不限 corrupted=已腐化 clean=非腐化

  @override
  void dispose() {
    _customController.dispose();
    for (final c in _minControllers.values) {
      c.dispose();
    }
    for (final c in _maxControllers.values) {
      c.dispose();
    }
    for (final c in _wsControllers.values) {
      c.dispose();
    }
    _tierMin.dispose();
    _tierMax.dispose();
    _tabletUseMin.dispose();
    _tabletUseMax.dispose();
    super.dispose();
  }

  TextEditingController _minControllerOf(String id) {
    return _minControllers.putIfAbsent(id, TextEditingController.new);
  }

  TextEditingController _maxControllerOf(String id) {
    return _maxControllers.putIfAbsent(id, TextEditingController.new);
  }

  TextEditingController _wsControllerOf(String id) {
    return _wsControllers.putIfAbsent(id, TextEditingController.new);
  }

  String _minOf(String id) => _minControllers[id]?.text ?? '';
  String _maxOf(String id) => _maxControllers[id]?.text ?? '';
  String _wsOf(String id) => _wsControllers[id]?.text ?? '';

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
        return _tabletSelected;
      case 2:
        return _itemModSelected;
      case 3:
        return _classSelected;
      default:
        return {};
    }
  }

  List<Poe2RegexItem> _itemsFor(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return _filteredMapAffixes;
      case 1:
        return _tabletMods;
      case 2:
        return _filteredItemMods;
      case 3:
        return [...kPoe2ItemClasses, ..._customOf('classes')];
      default:
        return const [];
    }
  }

  List<Poe2RegexItem> _customOf(String category) {
    return _customItems.where((e) => e.category == category).toList();
  }

  /// 搜索词是否匹配词条（同时匹配简/繁/英的名称与正则）。
  bool _matches(Poe2RegexItem e, String q) {
    if (e.label.contains(q)) return true;
    if (e.labelTc?.contains(q) ?? false) return true;
    if (e.en?.contains(q) ?? false) return true;
    if (e.cn.contains(q)) return true;
    if (e.tc?.contains(q) ?? false) return true;
    if (e.enRegex?.contains(q) ?? false) return true;
    return false;
  }

  List<Poe2RegexItem> get _filteredMapAffixes {
    var list = <Poe2RegexItem>[
      ...kPoe2MapAffixes,
      ..._customOf('maps'),
    ];
    if (_search.isNotEmpty) {
      list = list.where((e) => _matches(e, _search)).toList();
    }
    return list;
  }

  List<Poe2RegexItem> get _filteredItemMods {
    var list = <Poe2RegexItem>[
      ...kPoe2ItemModifiers,
      ..._customOf('items'),
    ];
    if (_affixFilter == '前缀') {
      list = list.where((e) => e.group == '前缀').toList();
    } else if (_affixFilter == '后缀') {
      list = list.where((e) => e.group == '后缀').toList();
    }
    if (_search.isNotEmpty) {
      list = list.where((e) => _matches(e, _search)).toList();
    }
    return list;
  }

  /// 当前选中石板类型的机制词条（内置 + 自定义），支持简繁搜索。
  List<Poe2RegexItem> get _tabletMods {
    final type = _tabletType;
    if (type == null) return const [];
    final builtin = kPoe2TabletMods[type] ?? const <Poe2RegexItem>[];
    final group = _tabletGroupOf(type);
    final custom = group == null
        ? const <Poe2RegexItem>[]
        : _customOf('mechanics')
            .where((e) => e.group == group)
            .toList();
    var all = [...builtin, ...custom];
    if (_search.isNotEmpty) {
      all = all.where((e) => _matches(e, _search)).toList();
    }
    return all;
  }

  /// 石板类型 → 机制词条分组名（用于关联自定义词条）。
  static String? _tabletGroupOf(String tabletTypeId) {
    const map = {
      'precursor': '能量辐照',
      'breach': '裂隙',
      'expedition': '先祖秘藏',
      'delirium': '惊悸迷雾',
      'ritual': '驱灵仪式',
      'domination': '霸主',
      'abyss': '深渊',
      'temple': '瓦尔灯塔',
    };
    return map[tabletTypeId];
  }

  String _patternOf(Poe2RegexItem item, int tabIndex) {
    // 英文模式：用英文正则（无则回退简体）
    if (_isEn) {
      final er = item.enRegex;
      if (er != null && er.isNotEmpty) return er;
      return item.cn;
    }
    // 繁体模式：用繁体正则（无则回退简体）
    if (_isTc) {
      final tc = item.tc;
      if (tc != null && tc.isNotEmpty) return tc;
    }
    return item.cn;
  }

  /// 石板类型 chip 显示名：英文用英文名（去 Tablet），繁体去掉「碑牌」，简体去掉「先驱石板」。
  String _tabletChipName(Poe2RegexItem t) {
    if (_isEn) return (t.en ?? t.label).replaceAll(' Tablet', '');
    return t.displayName(isTc: _isTc, isEn: false)
        .replaceAll(_isTc ? '碑牌' : '先驱石板', '');
  }

  static String _applyRange(String pattern, String minText, String maxText) {
    final minStr = minText.trim();
    final maxStr = maxText.trim();
    // 模式中没有数字占位符的词条（如冰缓地面）不支持填数值
    final hasPlaceholder = pattern.contains('[0-9.]+') || pattern.contains('[0-9]+');
    if (!hasPlaceholder || (minStr.isEmpty && maxStr.isEmpty)) return pattern;
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
    return pattern.replaceAll(RegExp(r'\[0-9\.\]\+|\[0-9\]\+'), numPattern);
  }

  String get _output {
    if (tabIndexCustom) {
      return _customController.text.trim();
    }
    final tab = _currentTab;
    final items = _itemsFor(tab);
    final selectedSet = _setFor(tab);
    final patterns = <String>[
      ..._extraPatterns(tab),
      ...items
          .where((e) => selectedSet.contains(e.id))
          .map((e) =>
              _applyRange(_patternOf(e, tab), _minOf(e.id), _maxOf(e.id)))
          .where((p) => p.isNotEmpty),
    ];
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

  /// 地图/石板标签页的附加参数（地图阶级、腐化、引路石属性、使用次数、稀有度）。
  List<String> _extraPatterns(int tab) {
    final result = <String>[];
    if (tab == 0) {
      // 地图阶级
      final tMin = _tierMin.text.trim();
      final tMax = _tierMax.text.trim();
      if (tMin.isNotEmpty || tMax.isNotEmpty) {
        final lo = int.tryParse(tMin) ?? 1;
        final hi = int.tryParse(tMax) ?? 16;
        final range = NumberRangeRegex.between(lo, hi);
        result.add(_isTc ? '（ *階級 *$range' : '（ *$range *阶');
      }
      // 腐化
      if (_corrupted == 'corrupted') {
        result.add(_isTc ? '已汙' : '已腐');
      }
      // 引路石基础属性
      for (final ws in _kWaystoneStats) {
        final v = _wsOf(ws.id);
        if (v.trim().isNotEmpty) {
          final num = int.tryParse(v.trim());
          if (num != null) {
            final range = NumberRangeRegex.gte(num);
            final label = _isTc ? ws.tc : ws.cn;
            result.add(ws.isPercent
                ? '$label:.*\\+?$range%'
                : '$label:.*\\+?$range');
          }
        }
      }
      // 地图稀有度（普通/魔法/稀有 三选一）
      if (_mapRarities.isNotEmpty && _mapRarities.length < 3) {
        final map = {
          'rare': '稀有',
          'magic': '魔法',
          'normal': '普通',
        };
        final s = _mapRarities.map((e) => map[e] ?? '').where((e) => e.isNotEmpty).toList();
        if (s.isNotEmpty) {
          result.add('稀有度: (${s.join('|')})');
        }
      }
    } else if (tab == 1) {
      // 选中石板类型本身：匹配石板名称（如 裂隙先驱石板）
      final type = _tabletType;
      if (type != null) {
        for (final t in [...kPoe2Tablet, ..._customOf('tablet')]) {
          if (t.id == type) {
            final p = _isTc && t.tc?.isNotEmpty == true ? t.tc! : t.cn;
            if (p.isNotEmpty) result.add(p);
            break;
          }
        }
      }
      // 石板使用次数
      final uMin = _tabletUseMin.text.trim();
      final uMax = _tabletUseMax.text.trim();
      if (uMin.isNotEmpty || uMax.isNotEmpty) {
        final lo = int.tryParse(uMin);
        final hi = int.tryParse(uMax);
        String range;
        if (lo != null && hi != null) {
          range = NumberRangeRegex.between(lo, hi);
        } else if (lo != null) {
          range = NumberRangeRegex.gte(lo);
        } else {
          range = NumberRangeRegex.lte(hi!);
        }
        result.add(_isTc ? '剩餘 *$range *次' : '剩余次数： *$range');
      }
      // 石板稀有度
      if (_tabletRarities.isNotEmpty && _tabletRarities.length < 3) {
        final map = {
          'rare': '稀有',
          'magic': '魔法',
          'normal': '普通',
        };
        final s = _tabletRarities.map((e) => map[e] ?? '').where((e) => e.isNotEmpty).toList();
        if (s.isNotEmpty) {
          result.add('稀有度: (${s.join('|')})');
        }
      }
    }
    return result;
  }

  bool get tabIndexCustom => _tabController?.index == 4;
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
      length: 5,
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
                Tab(text: '石板'),
                Tab(text: '装备词缀'),
                Tab(text: '装备类别'),
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
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'cn', label: Text('简')),
                        ButtonSegment(value: 'tc', label: Text('繁')),
                        ButtonSegment(value: 'en', label: Text('英')),
                      ],
                      selected: {_lang},
                      onSelectionChanged: (s) =>
                          setState(() => _lang = s.first),
                    ),
                  ],
                ),
              ),
              if (controller.index == 2)
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
                    _buildTabletTab(controller),
                    _buildList(controller, 2),
                    _buildList(controller, 3),
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
              if (tabIndex == 0) _buildMapParams(),
              for (final item in items)
                _ItemTile(
                  item: item,
                  selected: set.contains(item.id),
                  lang: _lang,
                  minController: _minControllerOf(item.id),
                  maxController: _maxControllerOf(item.id),
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

  Widget _paramHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildMapParams() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _paramHeader('地图阶级'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text('最低', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 6),
              SizedBox(
                width: 52,
                child: TextField(
                  controller: _tierMin,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: '1',
                    hintStyle: TextStyle(fontSize: 13, color: Color(0xFFE0E0E0)),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text('~', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 10),
              const Text('最高', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 6),
              SizedBox(
                width: 52,
                child: TextField(
                  controller: _tierMax,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: '16',
                    hintStyle: TextStyle(fontSize: 13, color: Color(0xFFE0E0E0)),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
        ),
        _paramHeader('腐化'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            children: [
              for (final c in [
                ('不限', null),
                ('已腐化', 'corrupted'),
                ('非腐化', 'clean'),
              ])
                ChoiceChip(
                  label: Text(c.$1),
                  selected: _corrupted == c.$2,
                  onSelected: (_) => setState(() => _corrupted = c.$2),
                ),
            ],
          ),
        ),
        _paramHeader('地图稀有度（三选一）'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            children: [
              for (final r in ['rare', 'magic', 'normal'])
                FilterChip(
                  label: Text(r == 'rare'
                      ? '稀有'
                      : r == 'magic'
                          ? '魔法'
                          : '普通'),
                  selected: _mapRarities.contains(r),
                  onSelected: (sel) => setState(() {
                    if (sel) {
                      _mapRarities.add(r);
                    } else {
                      _mapRarities.remove(r);
                    }
                  }),
                ),
            ],
          ),
        ),
        _paramHeader('引路石基础属性（≥）'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              for (final ws in _kWaystoneStats)
                SizedBox(
                  width: 120,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(_isTc ? ws.tc : ws.cn,
                            style: const TextStyle(fontSize: 11),
                            overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 4),
                      SizedBox(
                        width: 56,
                        child: TextField(
                          controller: _wsControllerOf(ws.id),
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12),
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            isDense: true,
                            hintText: '0',
                            hintStyle: TextStyle(fontSize: 13, color: Color(0xFFE0E0E0)),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabletParams() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _paramHeader('使用次数（剩余）'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text('最低', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 6),
              SizedBox(
                width: 52,
                child: TextField(
                  controller: _tabletUseMin,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: '0',
                    hintStyle: TextStyle(fontSize: 13, color: Color(0xFFE0E0E0)),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text('~', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 10),
              const Text('最高', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 6),
              SizedBox(
                width: 52,
                child: TextField(
                  controller: _tabletUseMax,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: '999',
                    hintStyle: TextStyle(fontSize: 13, color: Color(0xFFE0E0E0)),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
        ),
        _paramHeader('稀有度'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            children: [
              for (final r in ['rare', 'magic', 'normal'])
                FilterChip(
                  label: Text(r == 'rare'
                      ? '稀有'
                      : r == 'magic'
                          ? '魔法'
                          : '普通'),
                  selected: _tabletRarities.contains(r),
                  onSelected: (sel) => setState(() {
                    if (sel) {
                      _tabletRarities.add(r);
                    } else {
                      _tabletRarities.remove(r);
                    }
                  }),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// 石板标签页：先选石板类型，再选该类型的机制词条（与 cnpoe 一致）。
  Widget _buildTabletTab(TabController controller) {
    final set = _tabletSelected;
    final items = _tabletMods;
    return Column(
      children: [
        _buildToolbar(controller, set, 1),
        Expanded(
          child: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _paramHeader('石板类型'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        for (final t in [...kPoe2Tablet, ..._customOf('tablet')])
                          ChoiceChip(
                            label: Text(
                              _tabletChipName(t),
                              style: const TextStyle(fontSize: 12),
                            ),
                            selected: _tabletType == t.id,
                            onSelected: (_) => setState(() {
                              _tabletType = _tabletType == t.id ? null : t.id;
                              _tabletSelected.clear();
                            }),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              _buildTabletParams(),
              if (_tabletType == null)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      '请先选择石板类型',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ),
                ),
              if (_tabletType != null && items.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      '该石板类型暂无词条',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ),
                ),
              if (_tabletType != null)
                for (final item in items)
                  _ItemTile(
                    item: item,
                    selected: set.contains(item.id),
                    lang: _lang,
                    minController: _minControllerOf(item.id),
                    maxController: _maxControllerOf(item.id),
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
  final String lang;
  final TextEditingController minController;
  final TextEditingController maxController;
  final ValueChanged<bool> onToggle;
  final ValueChanged<String> onChanged;

  const _ItemTile({
    required this.item,
    required this.selected,
    this.lang = 'cn',
    required this.minController,
    required this.maxController,
    required this.onToggle,
    required this.onChanged,
  });

  /// 词条正则是否含数字占位符（[0-9]+ / [0-9.]+），决定是否显示数值输入。
  bool get _hasNumeric =>
      (item.cn.contains('[0-9]+') || item.cn.contains('[0-9.]+')) ||
      (item.tc?.contains('[0-9]+') ?? false) ||
      (item.tc?.contains('[0-9.]+') ?? false);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          dense: true,
          title: Text(
            item.displayName(isTc: lang == 'tc', isEn: lang == 'en'),
            style: const TextStyle(fontSize: 14),
          ),
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
        if (selected && _hasNumeric)
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
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                    onChanged: onChanged,
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: '0',
                      hintStyle: TextStyle(fontSize: 13, color: Color(0xFFE0E0E0)),
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
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                    onChanged: onChanged,
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: '999',
                      hintStyle: TextStyle(fontSize: 13, color: Color(0xFFE0E0E0)),
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
    if (_hasNumeric) {
      return '填数值替换模式中的数字';
    }
    return '该词条无数字占位符';
  }
}
