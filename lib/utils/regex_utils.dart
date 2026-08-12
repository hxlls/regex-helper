class RegexCheck {
  final bool valid;
  final String? error;

  const RegexCheck._(this.valid, [this.error]);

  static RegexCheck validate(String pattern,
      {bool caseInsensitive = false, bool multiLine = false}) {
    if (pattern.isEmpty) return const RegexCheck._(true);
    try {
      RegExp(pattern, caseSensitive: !caseInsensitive, multiLine: multiLine);
      return const RegexCheck._(true);
    } on FormatException catch (e) {
      return RegexCheck._(false, e.message);
    }
  }
}

int countMatches(String text, String pattern,
    {bool caseInsensitive = false, bool multiLine = false}) {
  if (pattern.isEmpty || text.isEmpty) return 0;
  try {
    final regex =
        RegExp(pattern, caseSensitive: !caseInsensitive, multiLine: multiLine);
    return regex.allMatches(text).length;
  } catch (_) {
    return 0;
  }
}
