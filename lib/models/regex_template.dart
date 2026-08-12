class RegexTemplate {
  final String name;
  final String description;
  final String pattern;
  final String category;
  final String example;
  final String explanation;

  const RegexTemplate({
    required this.name,
    required this.description,
    required this.pattern,
    required this.category,
    required this.example,
    required this.explanation,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'pattern': pattern,
        'category': category,
        'example': example,
        'explanation': explanation,
      };

  factory RegexTemplate.fromJson(Map<String, dynamic> json) => RegexTemplate(
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        pattern: json['pattern'] as String? ?? '',
        category: json['category'] as String? ?? '自定义模板',
        example: json['example'] as String? ?? '',
        explanation: json['explanation'] as String? ?? '',
      );

  bool get isCustom => category == '自定义模板' || category == '自定义模板（AI）';
}

class GenerationResult {
  final String pattern;
  final String explanation;
  final bool anchored;
  final bool caseInsensitive;
  final bool global;

  const GenerationResult({
    required this.pattern,
    required this.explanation,
    this.anchored = false,
    this.caseInsensitive = false,
    this.global = true,
  });

  String get flags {
    final buffer = StringBuffer('g');
    if (caseInsensitive) buffer.write('i');
    if (anchored) buffer.write('m');
    return buffer.toString();
  }
}
