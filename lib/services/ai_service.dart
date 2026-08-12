import 'dart:convert';

import 'package:http/http.dart' as http;

class AiResult {
  final String pattern;
  final String explanation;

  const AiResult({required this.pattern, required this.explanation});
}

class AiService {
  final String apiBase;
  final String apiKey;
  final String model;

  AiService({required this.apiBase, required this.apiKey, required this.model});

  Future<AiResult> generate(String description) async {
    final url = '${apiBase.replaceAll(RegExp(r'/+$'), '')}/chat/completions';
    final systemPrompt = '你是正则表达式专家。用户会用中文描述需求，请生成正则表达式。'
        '只返回 JSON，格式：{"pattern":"正则字符串","explanation":"简短中文说明"}\n'
        '规则：匹配/校验/验证类需求用完整锚定（开头尖号和结尾尖号）；'
        '提取/查找类需求不加锚点。只输出 JSON，不要其他文字。';

    final body = jsonEncode({
      'model': model,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': description},
      ],
      'temperature': 0.2,
    });

    final response = await http
        .post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            if (apiKey.isNotEmpty) 'Authorization': 'Bearer $apiKey',
          },
          body: body,
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode != 200) {
      throw Exception('API 错误 (${response.statusCode}): ${response.body}');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    final content =
        (data['choices'] as List).first['message']['content'] as String;
    return _parseContent(content);
  }

  AiResult _parseContent(String content) {
    final trimmed = content.trim();
    final jsonStart = trimmed.indexOf('{');
    final jsonEnd = trimmed.lastIndexOf('}');
    if (jsonStart >= 0 && jsonEnd > jsonStart) {
      final jsonStr = trimmed.substring(jsonStart, jsonEnd + 1);
      try {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        return AiResult(
          pattern: (map['pattern'] ?? '').toString(),
          explanation: (map['explanation'] ?? '由 AI 生成').toString(),
        );
      } catch (_) {
        // fall through to raw extraction
      }
    }
    // 直接提取第一个正则字符串
    final raw = trimmed.replaceAll(RegExp(r'[\r\n]+'), ' ');
    return AiResult(pattern: raw, explanation: '由 AI 生成');
  }
}
