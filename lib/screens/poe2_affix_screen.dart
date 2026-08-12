import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/poe2_affix_templates.dart';
import '../models/regex_template.dart';

class Poe2AffixScreen extends StatelessWidget {
  const Poe2AffixScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = <String>[];
    for (final t in kPoe2AffixTemplates) {
      if (!categories.contains(t.category)) categories.add(t.category);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('POE2 词条库'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: '使用说明',
            onPressed: () => _showHelp(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.deepOrange.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.deepOrange.shade100),
            ),
            child: Text(
              '在主页面输入词条描述（如「附加火焰伤害」「火焰抗性」「最大生命」）即可自动生成匹配词条的正则，也可直接复制下方模板。',
              style: TextStyle(
                  fontSize: 13, color: Colors.deepOrange.shade800),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                for (final category in categories) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      category,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  for (final t in kPoe2AffixTemplates
                      .where((t) => t.category == category))
                    _AffixCard(template: t),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('如何使用词条库'),
        content: const SingleChildScrollView(
          child: Text(
            '流放之路2 的词条包含可变数值，例如：\n\n'
            '  「附加 3 至 6 的火焰伤害」\n'
            '  「+15% 火焰抗性」\n'
            '  「+40 最大生命」\n\n'
            '在主页面用中文描述即可生成匹配整行词条的正则：\n'
            '· 附加火焰伤害 → 匹配附加伤害词条\n'
            '· 火焰抗性 → 匹配抗性词条\n'
            '· 最大生命 → 匹配生命词条\n'
            '· 附加火焰伤害大于10 → 还支持数值范围\n\n'
            '生成后可点「存模板」加入你的自定义模板库。',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }
}

class _AffixCard extends StatelessWidget {
  final RegexTemplate template;

  const _AffixCard({required this.template});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        title: Text(template.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                template.pattern,
                style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Colors.indigo.shade700),
              ),
              if (template.example.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text('示例：${template.example}',
                      style: TextStyle(
                          fontSize: 12, color: Colors.green.shade700)),
                ),
              if (template.explanation.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(template.explanation,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600)),
                ),
            ],
          ),
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.copy, size: 18),
              tooltip: '复制正则',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: template.pattern));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('已复制：${template.pattern}'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.science, size: 18),
              tooltip: '测试',
              onPressed: () {
                Navigator.pushNamed(context, '/tester',
                    arguments: template.pattern);
              },
            ),
          ],
        ),
      ),
    );
  }
}
