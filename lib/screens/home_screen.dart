import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../engine/regex_engine.dart';
import '../models/regex_template.dart';
import '../services/ai_service.dart';
import '../services/settings_service.dart';
import '../services/template_store.dart';
import 'settings_screen.dart';
import 'templates_screen.dart';
import 'poe2_affix_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _descriptionController = TextEditingController();
  final _service = SettingsService();
  AppSettings _settings = const AppSettings();
  GenerationResult? _result;
  bool _aiLoading = false;
  String? _aiError;

  static const _quickExamples = [
    '匹配11位手机号',
    '提取邮箱地址',
    '校验18位身份证号',
    '匹配日期 2024-01-01',
    '6-16位字母和数字',
    '提取网址',
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final settings = await _service.load();
    if (mounted) setState(() => _settings = settings);
  }

  void _generateLocal() {
    FocusScope.of(context).unfocus();
    final result = RegexEngine.generate(_descriptionController.text);
    setState(() {
      _result = result;
      _aiError = null;
    });
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入描述，例如：匹配11位手机号')),
      );
      return;
    }
    if (_settings.autoTest) {
      _openTester(result.pattern);
    }
  }

  Future<void> _generateWithAi() async {
    FocusScope.of(context).unfocus();
    final desc = _descriptionController.text.trim();
    if (desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先输入描述')),
      );
      return;
    }
    if (!_settings.hasAiConfig) {
      _openSettings();
      return;
    }
    setState(() {
      _aiLoading = true;
      _aiError = null;
    });
    try {
      final ai = AiService(
        apiBase: _settings.apiBase,
        apiKey: _settings.apiKey,
        model: _settings.model,
      );
      final result = await ai.generate(desc);
      if (!mounted) return;
      setState(() {
        _result = GenerationResult(
          pattern: result.pattern,
          explanation: result.explanation,
        );
        _aiLoading = false;
      });
      if (_settings.autoTest) _openTester(result.pattern);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _aiLoading = false;
        _aiError = 'AI 生成失败：$e';
      });
    }
  }

  void _openTester([String? pattern]) {
    Navigator.pushNamed(context, '/tester', arguments: pattern ?? '');
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SettingsScreen(settings: _settings)),
    ).then((_) => _loadSettings());
  }

  void _openTemplates() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TemplatesScreen()),
    );
  }

  void _openPoe2Affixes() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const Poe2AffixScreen()),
    );
  }

  void _copyResult() {
    if (_result == null) return;
    Clipboard.setData(ClipboardData(text: _result!.pattern));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制到剪贴板')),
    );
  }

  Future<void> _saveToLibrary() async {
    final result = _result;
    if (result == null) return;

    final nameController = TextEditingController();
    final descController = TextEditingController();
    final explanationController = TextEditingController(text: result.explanation);

    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('保存到模板库'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: '模板名称',
                  hintText: '例如：AI 生成的自定义模板',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: '描述（可选）',
                  hintText: '这个正则的用途',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  result.pattern,
                  style: const TextStyle(
                      fontFamily: 'monospace', fontSize: 14),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: explanationController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: '说明（可选）',
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
      description: descController.text.trim(),
      pattern: result.pattern,
      category: '自定义模板',
      example: '',
      explanation: explanationController.text.trim(),
    ));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已保存「$name」到模板库'),
        action: SnackBarAction(
          label: '查看',
          onPressed: _openTemplates,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('正则助手'),
        actions: [
          IconButton(
            icon: const Icon(Icons.style),
            tooltip: 'POE2 词条库',
            onPressed: _openPoe2Affixes,
          ),
          IconButton(
            icon: const Icon(Icons.library_books),
            tooltip: '模板库',
            onPressed: _openTemplates,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: '设置',
            onPressed: _openSettings,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _descriptionController,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: '用中文描述你的需求',
              hintText: '例如：匹配11位手机号\n或：提取文本中的所有网址',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.translate),
            ),
            onSubmitted: (_) => _generateLocal(),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                icon: const Icon(Icons.auto_fix_high),
                label: const Text('生成正则'),
                onPressed: _generateLocal,
              ),
              if (_settings.hasAiConfig)
                FilledButton.tonalIcon(
                  icon: _aiLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.smart_toy),
                  label: Text(_aiLoading ? 'AI 生成中...' : 'AI 生成'),
                  onPressed: _aiLoading ? null : _generateWithAi,
                ),
            ],
          ),
          if (_aiError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _aiError!,
                style: TextStyle(color: Colors.red.shade700, fontSize: 13),
              ),
            ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final example in _quickExamples)
                ActionChip(
                  label: Text(example, style: const TextStyle(fontSize: 12)),
                  onPressed: () {
                    _descriptionController.text = example;
                    _descriptionController.selection =
                        TextSelection.collapsed(offset: example.length);
                    setState(() {});
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.deepOrange.shade700,
              side: BorderSide(color: Colors.deepOrange.shade200),
            ),
            icon: const Icon(Icons.style, size: 18),
            label: const Text('POE2 词条库（附加伤害/抗性/属性等）'),
            onPressed: _openPoe2Affixes,
          ),
          const SizedBox(height: 16),
          if (_result != null)
            _ResultCard(
              result: _result!,
              onCopy: _copyResult,
              onTest: () => _openTester(_result!.pattern),
              onSave: _saveToLibrary,
            ),
          const SizedBox(height: 32),
          if (_result == null)
            Card(
              color: Colors.grey.withValues(alpha: 0.08),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('支持的说法',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary)),
                    const SizedBox(height: 8),
                    const Text('· 匹配 / 校验 / 验证 + 类型：手机号、邮箱、身份证、IP、网址、日期、时间…\n'
                        '· 提取 / 查找：从文本中找出所有匹配项\n'
                        '· 长度约束：11位、6-16位、至少8位\n'
                        '· 字符类型：纯数字、字母、中文、字母数字组合\n'
                        '· 兜底：未识别类型时按字面内容生成\n'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final GenerationResult result;
  final VoidCallback onCopy;
  final VoidCallback onTest;
  final VoidCallback onSave;

  const _ResultCard({
    required this.result,
    required this.onCopy,
    required this.onTest,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('生成结果',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: SelectableText(
                result.pattern,
                style: const TextStyle(
                    fontFamily: 'monospace', fontSize: 17),
              ),
            ),
            const SizedBox(height: 10),
            Text(result.explanation,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('复制'),
                  onPressed: onCopy,
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.science, size: 18),
                  label: const Text('测试'),
                  onPressed: onTest,
                ),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                  label: const Text('存模板'),
                  onPressed: onSave,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
