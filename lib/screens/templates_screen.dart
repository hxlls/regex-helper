import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/templates.dart';
import '../models/regex_template.dart';
import '../services/template_store.dart';

class TemplatesScreen extends StatefulWidget {
  const TemplatesScreen({super.key});

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {
  final _store = TemplateStore();
  List<RegexTemplate> _customTemplates = [];

  @override
  void initState() {
    super.initState();
    _loadCustom();
  }

  Future<void> _loadCustom() async {
    final custom = await _store.load();
    if (mounted) setState(() => _customTemplates = custom);
  }

  Future<void> _deleteTemplate(RegexTemplate template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除模板'),
        content: Text('确定删除「${template.name}」吗？'),
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
      final remaining = await _store.remove(template);
      if (mounted) {
        setState(() => _customTemplates = remaining);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('模板已删除')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = <String>[];
    for (final t in kTemplates) {
      if (!categories.contains(t.category)) categories.add(t.category);
    }

    final hasCustom = _customTemplates.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('常用正则模板')),
      body: RefreshIndicator(
        onRefresh: _loadCustom,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            if (hasCustom) ...[
              _sectionHeader(context, '自定义模板（${_customTemplates.length}）'),
              for (final t in _customTemplates)
                _TemplateCard(
                  template: t,
                  onDelete: () => _deleteTemplate(t),
                ),
            ],
            for (final category in categories) ...[
              _sectionHeader(context, category),
              for (final t in kTemplates.where((t) => t.category == category))
                _TemplateCard(template: t),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final RegexTemplate template;
  final VoidCallback? onDelete;

  const _TemplateCard({required this.template, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isCustom = template.isCustom;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ExpansionTile(
        leading: isCustom
            ? Icon(Icons.person, size: 20, color: Colors.orange.shade700)
            : null,
        title: Row(
          children: [
            Text(template.name,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                template.description,
                style:
                    TextStyle(fontSize: 12, color: Colors.grey.shade600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            template.pattern,
            style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: Colors.indigo.shade700),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (template.explanation.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('说明：${template.explanation}',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade700)),
                  ),
                if (template.example.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text('示例：${template.example}',
                        style: TextStyle(
                            fontSize: 13, color: Colors.green.shade700)),
                  ),
                Row(
                  children: [
                    FilledButton.tonalIcon(
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('复制正则'),
                      onPressed: () {
                        Clipboard.setData(
                            ClipboardData(text: template.pattern));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('已复制：${template.pattern}'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.science, size: 18),
                      label: const Text('测试'),
                      onPressed: () {
                        Navigator.pushNamed(context, '/tester',
                            arguments: template.pattern);
                      },
                    ),
                    if (onDelete != null) ...[
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.delete_outline,
                            color: Colors.red.shade400, size: 20),
                        tooltip: '删除模板',
                        onPressed: onDelete,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
