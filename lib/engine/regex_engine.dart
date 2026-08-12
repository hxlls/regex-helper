import '../models/regex_template.dart';

class _Rule {
  final String id;
  final String name;
  final List<String> keywords;
  final String Function() basePattern;

  const _Rule({
    required this.id,
    required this.name,
    required this.keywords,
    required this.basePattern,
  });
}

class _Length {
  final int min;
  final int? max;

  const _Length(this.min, [this.max]);

  String get quantifier => max == null ? '{$min}' : '{$min,$max}';

  @override
  String toString() => max == null ? '$min' : '$min-$max';
}

class RegexEngine {
  static final List<_Rule> _rules = [
    _Rule(
      id: 'mobile',
      name: '手机号',
      keywords: ['手机号', '手机号码', '手机', '移动电话', '11位电话'],
      basePattern: () => r'1[3-9]\d{9}',
    ),
    _Rule(
      id: 'landline',
      name: '固定电话',
      keywords: ['座机', '固定电话', '固话', '座机电话'],
      basePattern: () => r'0\d{2,3}-?\d{7,8}',
    ),
    _Rule(
      id: 'email',
      name: '邮箱',
      keywords: ['邮箱', 'email', '电子邮件', '邮件地址', '邮箱地址', '邮件'],
      basePattern: () => r'[\w.+-]+@[\w-]+(?:\.[\w-]+)+',
    ),
    _Rule(
      id: 'idcard',
      name: '身份证号',
      keywords: ['身份证', '身份证号', '居民身份证', '18位身份证'],
      basePattern: () => r'\d{17}[\dXx]',
    ),
    _Rule(
      id: 'ipv4',
      name: 'IPv4 地址',
      keywords: ['ip地址', 'ipv4', 'ip', '互联网地址'],
      basePattern: () =>
          r'(?:25[0-5]|2[0-4]\d|1?\d?\d)\.(?:25[0-5]|2[0-4]\d|1?\d?\d)\.(?:25[0-5]|2[0-4]\d|1?\d?\d)\.(?:25[0-5]|2[0-4]\d|1?\d?\d)',
    ),
    _Rule(
      id: 'url',
      name: '网址',
      keywords: ['网址', 'url', '链接', '网页地址', '网络地址', '超链接'],
      basePattern: () => r'https?://[^\s<>"`{}|\\^\[\]]+',
    ),
    _Rule(
      id: 'domain',
      name: '域名',
      keywords: ['域名', 'domain'],
      basePattern: () =>
          r'(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,63}',
    ),
    _Rule(
      id: 'date',
      name: '日期',
      keywords: ['日期', '年月日', 'date', '生日'],
      basePattern: () => r'\d{4}[-/年]\d{1,2}[-/月]\d{1,2}日?|(?:\d{1,2}月\d{1,2}日)',
    ),
    _Rule(
      id: 'time',
      name: '时间',
      keywords: ['时间', '时分秒', 'time', '时刻'],
      basePattern: () => r'(?:[01]\d|2[0-3]):[0-5]\d(?::[0-5]\d)?',
    ),
    _Rule(
      id: 'amount',
      name: '金额',
      keywords: ['金额', '价格', '价钱', '人民币', 'money'],
      basePattern: () => r'(?:人民币|¥|￥|RMB)?\s?\d+(?:\.\d{1,2})?(?:元)?',
    ),
    _Rule(
      id: 'qq',
      name: 'QQ 号',
      keywords: ['qq号', 'qq号码', 'qq'],
      basePattern: () => r'[1-9]\d{4,11}',
    ),
    _Rule(
      id: 'wechat',
      name: '微信号',
      keywords: ['微信号', '微信'],
      basePattern: () => r'[a-zA-Z][a-zA-Z0-9_-]{5,19}',
    ),
    _Rule(
      id: 'plate',
      name: '车牌号',
      keywords: ['车牌', '车牌号', '汽车牌照'],
      basePattern: () =>
          r'[京津沪渝冀豫云辽黑湘皖鲁新苏浙赣鄂桂甘晋蒙陕吉闽贵粤青藏川宁琼使领][A-HJ-NP-Z][A-HJ-NP-Z0-9]{5}',
    ),
    _Rule(
      id: 'postcode',
      name: '邮政编码',
      keywords: ['邮编', '邮政编码', 'zip', 'postal'],
      basePattern: () => r'[1-9]\d{5}',
    ),
    _Rule(
      id: 'username',
      name: '用户名',
      keywords: ['用户名', '账号', 'username', '用户账号', '昵称'],
      basePattern: () => r'[a-zA-Z][a-zA-Z0-9_]{2,15}',
    ),
    _Rule(
      id: 'password',
      name: '密码',
      keywords: ['密码', 'password'],
      basePattern: () => r'(?=.*[a-zA-Z])(?=.*\d)[a-zA-Z0-9!@#\$%^&*_.-]{6,20}',
    ),
    _Rule(
      id: 'hex',
      name: '十六进制',
      keywords: ['十六进制', 'hex', '16进制'],
      basePattern: () => r'0[xX][0-9a-fA-F]+|[0-9a-fA-F]+',
    ),
    _Rule(
      id: 'binary',
      name: '二进制',
      keywords: ['二进制', '2进制', 'binary'],
      basePattern: () => r'[01]+',
    ),
    _Rule(
      id: 'hexcolor',
      name: '颜色代码',
      keywords: ['颜色', 'hex颜色', '颜色代码', '色值'],
      basePattern: () => r'#(?:[0-9a-fA-F]{3}|[0-9a-fA-F]{6})\b',
    ),
    _Rule(
      id: 'int',
      name: '整数',
      keywords: ['整数', '整型'],
      basePattern: () => r'[+-]?\d+',
    ),
    _Rule(
      id: 'decimal',
      name: '小数/浮点数',
      keywords: ['小数', '浮点数', 'decimal', 'double', '带小数'],
      basePattern: () => r'[+-]?\d+\.\d+',
    ),
    _Rule(
      id: 'chinese',
      name: '中文/汉字',
      keywords: ['中文', '汉字', '中文字符', '中文字', '纯中文'],
      basePattern: () => r'[\u4e00-\u9fa5]',
    ),
    _Rule(
      id: 'letter',
      name: '英文字母',
      keywords: ['英文', '字母', 'english', '英文单词'],
      basePattern: () => r'[a-zA-Z]',
    ),
    _Rule(
      id: 'number',
      name: '数字',
      keywords: ['数字', 'number', '数码'],
      basePattern: () => r'\d',
    ),
    _Rule(
      id: 'whitespace',
      name: '空白字符',
      keywords: ['空白', '空格', '空白字符', 'whitespace'],
      basePattern: () => r'\s',
    ),
    _Rule(
      id: 'poe_currency',
      name: '流放之路2通货',
      keywords: [
        '崇高石',
        '混沌石',
        '神圣石',
        '通货',
        '点金石',
        '瓦尔宝珠',
        '崇高',
        '蜕变石',
        '重铸石',
        '后悔石'
      ],
      basePattern: () =>
          r'崇高石|混沌石|神圣石|富豪石|点金石|蜕变石|增幅石|改造石|重铸石|后悔石|瓦尔宝珠|磨刀石|护甲片|磨砺石|智慧卷轴|传送卷轴|神聖石|蛻變石|重鑄石|後悔石|瓦爾寶珠|護甲片|磨礪石|智慧卷軸|傳送卷軸',
    ),
    _Rule(
      id: 'poe_uncut',
      name: '未切割宝石',
      keywords: ['未切割'],
      basePattern: () => r'未切割(?:宝石|寶石)',
    ),
    _Rule(
      id: 'poe_skillgem',
      name: '技能宝石',
      keywords: ['技能宝石', '技能寶石', '技能石'],
      basePattern: () => r'技能(?:宝石|寶石)',
    ),
    _Rule(
      id: 'poe_rune',
      name: '符文',
      keywords: ['符文', '灵魂核心', '靈魂核心'],
      basePattern: () =>
          r'(?:铁符文|钢符文|灵魂符文|风符文|雷符文|鐵符文|鋼符文|靈魂符文|風符文|雷符文|灵魂核心|靈魂核心)',
    ),
    _Rule(
      id: 'poe_waystone',
      name: '石碑(地图)',
      keywords: ['石碑', '地图', '地圖'],
      basePattern: () => r'石碑|地图|地圖',
    ),
  ];

  static const Map<String, String> _typeWords = {
    '数字': r'\d',
    '数码': r'\d',
    '字母': '[a-zA-Z]',
    '英文': '[a-zA-Z]',
    '小写字母': '[a-z]',
    '大写字母': '[A-Z]',
    '中文': r'[\u4e00-\u9fa5]',
    '汉字': r'[\u4e00-\u9fa5]',
    '任意字符': '.',
    '任何字符': '.',
  };

  static const Map<String, String> _typeLabels = {
    r'\d': '数字',
    '[a-zA-Z]': '字母',
    '[a-z]': '小写字母',
    '[A-Z]': '大写字母',
    r'[\u4e00-\u9fa5]': '中文',
    '.': '任意字符',
  };

  static GenerationResult? generate(String description) {
    final text = description.trim();
    if (text.isEmpty) return null;

    final lower = text.toLowerCase();
    final action = _detectAction(lower);
    final length = _parseLength(text);
    final anchoredHint = _hasAnchorWord(lower);

    final matchedRule = _matchRule(lower);
    final matchedTypes = _matchTypes(lower);

    // A) 存在明确的字符类型词（数字/字母/中文等）→ 通用组合构建
    if (matchedTypes.isNotEmpty) {
      final generic = _buildGeneric(matchedTypes, length, action, anchoredHint);
      if (generic != null) return generic;
    }

    // B) 规则命中的明确实体（手机号/邮箱/身份证等）
    if (matchedRule != null) {
      final pattern = matchedRule.basePattern();
      final explanation =
          '匹配${matchedRule.name}${length != null ? '（长度 $length 位）' : ''}';
      return GenerationResult(
        pattern: pattern,
        explanation: explanation,
        anchored: action == 'match' || anchoredHint,
        caseInsensitive: _hasEnglish(lower),
      );
    }

    // C) 兜底：字面量转义
    final pattern = _escapeLiteral(text);
    return GenerationResult(
      pattern: pattern,
      explanation: '未识别到已知类型，按字面内容生成（可尝试更具体的描述）',
      anchored: action == 'match' || anchoredHint,
      caseInsensitive: _hasEnglish(lower),
    );
  }

  static _Rule? _matchRule(String lower) {
    _Rule? best;
    int bestLen = 0;
    for (final rule in _rules) {
      for (final kw in rule.keywords) {
        if (lower.contains(kw) && kw.length > bestLen) {
          best = rule;
          bestLen = kw.length;
        }
      }
    }
    return best;
  }

  static List<String> _matchTypes(String lower) {
    final found = <String>[];
    final sorted = _typeWords.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final key in sorted) {
      final pattern = _typeWords[key]!;
      if (lower.contains(key) && !found.contains(pattern)) {
        found.add(pattern);
      }
    }
    return found;
  }

  static GenerationResult? _buildGeneric(
      List<String> types, _Length? length, String action, bool anchoredHint) {
    String core;
    final normalized = types.map((p) => p == r'\d' ? '0-9' : p).toList();
    if (types.length == 1) {
      core = types.first;
    } else if (normalized.every((p) => p.startsWith('['))) {
      final chars = StringBuffer();
      for (final p in normalized) {
        chars.write(p.substring(1, p.length - 1));
      }
      core = '[$chars]';
    } else if (types.length == 2 &&
        types.contains(r'\d') &&
        types.contains('[a-zA-Z]')) {
      core = '[a-zA-Z0-9]';
    } else {
      core = '(?:${types.join('|')})';
    }

    final quantifier = length?.quantifier ?? '+';
    final pattern = '$core$quantifier';

    final labels = types
        .map((p) => _typeLabels[p] ?? '字符')
        .where((l) => l != '字符' || types.length == 1)
        .toList();

    String label;
    if (types.length == 1) {
      label = labels.first;
    } else if (labels.every((l) => l != '任意字符')) {
      label = labels.join('、');
    } else {
      label = '字符';
    }

    final explanation = '匹配$label（${length != null ? '长度 $length 位' : '任意长度'}）';

    return GenerationResult(
      pattern: pattern,
      explanation: explanation,
      anchored: action == 'match' || anchoredHint,
      caseInsensitive: lowerContainsEnglish(labels),
    );
  }

  static bool lowerContainsEnglish(List<String> labels) {
    return labels.contains('字母') ||
        labels.contains('小写字母') ||
        labels.contains('大写字母');
  }

  static String _detectAction(String lower) {
    if (lower.contains('匹配') ||
        lower.contains('校验') ||
        lower.contains('验证') ||
        lower.contains('判断') ||
        lower.contains('检查') ||
        lower.contains('是不是') ||
        lower.contains('是否符合')) {
      return 'match';
    }
    if (lower.contains('提取') ||
        lower.contains('找出') ||
        lower.contains('查找') ||
        lower.contains('搜索') ||
        lower.contains('截取') ||
        lower.contains('抓取')) {
      return 'extract';
    }
    return 'extract';
  }

  static bool _hasAnchorWord(String lower) {
    return lower.contains('开头') ||
        lower.contains('结尾') ||
        lower.contains('必须') ||
        lower.contains('完全') ||
        lower.contains('精确') ||
        lower.contains('纯') ||
        lower.contains('只能') ||
        lower.contains('只允许');
  }

  static bool _hasEnglish(String lower) {
    return RegExp(r'[a-z]').hasMatch(lower);
  }

  static _Length? _parseLength(String text) {
    final range = RegExp(r'(\d{1,3})\s*[到至\-~]\s*(\d{1,3})\s*位').firstMatch(text);
    if (range != null) {
      final min = int.parse(range.group(1)!);
      final max = int.parse(range.group(2)!);
      return _Length(min, max);
    }
    final direct = RegExp(r'(\d{1,3})\s*位').firstMatch(text);
    if (direct != null) return _Length(int.parse(direct.group(1)!));
    final char = RegExp(r'(\d{1,3})\s*(?:个字符|个字|个长度)').firstMatch(text);
    if (char != null) return _Length(int.parse(char.group(1)!));
    return null;
  }

  static String _escapeLiteral(String text) {
    final buffer = StringBuffer();
    for (final ch in text.split('')) {
      if (RegExp(r'[.*+?^${}()|\[\]\\]').hasMatch(ch)) {
        buffer.write('\\$ch');
      } else {
        buffer.write(ch);
      }
    }
    return buffer.toString();
  }
}
