import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/templates.dart';
import '../models/regex_template.dart';

class TemplatesScreen extends StatelessWidget {
  const TemplatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = <String>[];
    for (final t in kTemplates) {
      if (!categories.contains(t.category)) categories.add(t.category);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('常用正则模板')),
      body: ListView(
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
            for (final t in kTemplates.where((t) => t.category == category))
              _TemplateCard(template: t),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final RegexTemplate template;

  const _TemplateCard({required this.template});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ExpansionTile(
        title: Row(
          children: [
            Text(template.name,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                template.description,
                style: TextStyle(
                    fontSize: 12, color: Colors.grey.shade600),
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
