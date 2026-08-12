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
