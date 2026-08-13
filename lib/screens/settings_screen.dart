import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  final AppSettings settings;

  const SettingsScreen({super.key, required this.settings});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _service = SettingsService();
  late bool _aiEnabled;
  late TextEditingController _apiBase;
  late TextEditingController _apiKey;
  late TextEditingController _model;
  late bool _autoTest;
  bool _saving = false;
  String _version = '';

  @override
  void initState() {
    super.initState();
    _aiEnabled = widget.settings.aiEnabled;
    _apiBase = TextEditingController(text: widget.settings.apiBase);
    _apiKey = TextEditingController(text: widget.settings.apiKey);
    _model = TextEditingController(text: widget.settings.model);
    _autoTest = widget.settings.autoTest;
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() => _version = '${info.version} (${info.buildNumber})');
      }
    } catch (_) {
      // 无法获取版本时保持空白
    }
  }

  @override
  void dispose() {
    _apiBase.dispose();
    _apiKey.dispose();
    _model.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await _service.save(AppSettings(
      aiEnabled: _aiEnabled,
      apiBase: _apiBase.text,
      apiKey: _apiKey.text,
      model: _model.text,
      autoTest: _autoTest,
    ));
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('设置已保存')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: const Text('保存'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('启用 AI 生成'),
                  subtitle: const Text('通过大模型理解更复杂的自然语言描述（需联网）'),
                  value: _aiEnabled,
                  onChanged: (v) => setState(() => _aiEnabled = v),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('支持 OpenAI 兼容接口'),
                  subtitle: const Text('可填写 OpenAI、DeepSeek、通义千问等任意兼容地址'),
                  dense: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _apiBase,
            enabled: _aiEnabled,
            decoration: const InputDecoration(
              labelText: 'API 地址',
              hintText: 'https://api.openai.com/v1',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _apiKey,
            enabled: _aiEnabled,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'API Key',
              hintText: 'sk-...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _model,
            enabled: _aiEnabled,
            decoration: const InputDecoration(
              labelText: '模型名称',
              hintText: 'gpt-4o-mini / deepseek-chat / qwen-turbo',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('生成后自动打开测试器'),
            value: _autoTest,
            onChanged: (v) => setState(() => _autoTest = v),
          ),
          const SizedBox(height: 16),
          Card(
            color: Colors.amber.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                '提示：AI Key 仅保存在本机，不会上传到任何服务器。本地规则引擎完全离线可用，无需配置。',
                style: TextStyle(fontSize: 13, color: Colors.amber.shade900),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('关于正则助手'),
            subtitle: Text(_version.isEmpty ? '版本信息加载中…' : '版本 $_version'),
            onTap: () => _showAbout(context),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('正则助手'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _version.isEmpty ? '' : '版本 $_version',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            const Text('用中文自然语言生成正则表达式，支持 Windows 和安卓。'),
            const SizedBox(height: 8),
            const Text('· 本地规则引擎：离线可用，匹配手机号、邮箱、身份证、IP、日期等 20+ 类型'),
            const SizedBox(height: 4),
            const Text('· 正则测试器：输入文本实时高亮匹配结果'),
            const SizedBox(height: 4),
            const Text('· 常用模板库：60+ 常用正则，含流放之路2（POE2）简繁模板'),
            const SizedBox(height: 4),
            const Text('· POE2 正则构建器：按词缀/石板/装备类别生成过滤正则'),
            const SizedBox(height: 4),
            const Text('· AI 生成（可选）：接入任意 OpenAI 兼容接口'),
            const SizedBox(height: 12),
            Text(
              '词条数据参考 poe2db.tw（简/繁/英三语对照）。',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}
