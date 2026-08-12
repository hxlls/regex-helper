import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/regex_utils.dart';
import '../widgets/match_highlight.dart';

class TesterScreen extends StatefulWidget {
  final String initialPattern;

  const TesterScreen({super.key, this.initialPattern = ''});

  @override
  State<TesterScreen> createState() => _TesterScreenState();
}

class _TesterScreenState extends State<TesterScreen> {
  late final TextEditingController _patternController;
  final TextEditingController _textController = TextEditingController(
    text: '测试文本示例：\n我的手机号是13812345678，邮箱 user@example.com，\n网址 https://example.com，时间是 14:30:00。',
  );
  bool _caseInsensitive = false;
  bool _multiLine = false;

  @override
  void initState() {
    super.initState();
    _patternController = TextEditingController(text: widget.initialPattern);
  }

  @override
  void dispose() {
    _patternController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _pastePattern() async {
    final data = await Clipboard.getData('text/plain');
    final text = data?.text;
    if (text != null && text.isNotEmpty) {
      setState(() => _patternController.text = text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pattern = _patternController.text;
    final check = RegexCheck.validate(pattern,
        caseInsensitive: _caseInsensitive, multiLine: _multiLine);

    return Scaffold(
      appBar: AppBar(title: const Text('正则测试器'), actions: [
        IconButton(
          icon: const Icon(Icons.paste),
          tooltip: '从剪贴板粘贴正则',
          onPressed: _pastePattern,
        ),
        IconButton(
          icon: const Icon(Icons.clear),
          tooltip: '清空',
          onPressed: () => setState(() => _patternController.clear()),
        ),
      ]),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _patternController,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 16),
            decoration: InputDecoration(
              labelText: '正则表达式',
              hintText: r'例如：1[3-9]\d{9}',
              border: const OutlineInputBorder(),
              errorText: check.valid ? null : '正则语法错误：${check.error}',
              suffixIcon: IconButton(
                icon: const Icon(Icons.copy),
                tooltip: '复制正则',
                onPressed: () =>
                    Clipboard.setData(ClipboardData(text: pattern)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('忽略大小写'),
              Switch(
                value: _caseInsensitive,
                onChanged: (v) => setState(() => _caseInsensitive = v),
              ),
              const SizedBox(width: 24),
              const Text('多行模式'),
              Switch(
                value: _multiLine,
                onChanged: (v) => setState(() => _multiLine = v),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _textController,
            onChanged: (_) => setState(() {}),
            maxLines: 8,
            minLines: 5,
            decoration: const InputDecoration(
              labelText: '测试文本',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          if (check.valid) ...[
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                '匹配结果实时预览（黄色为匹配项）',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.blueGrey,
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: MatchHighlight(
                text: _textController.text,
                pattern: pattern,
                caseInsensitive: _caseInsensitive,
                anchored: _multiLine,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
