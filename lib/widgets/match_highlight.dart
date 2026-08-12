import 'package:flutter/material.dart';

class MatchHighlight extends StatelessWidget {
  final String text;
  final String? pattern;
  final bool caseInsensitive;
  final bool anchored;
  final bool global;
  final int maxMatches;
  final TextStyle baseStyle;
  final Color matchBackground;
  final Color matchForeground;

  const MatchHighlight({
    super.key,
    required this.text,
    required this.pattern,
    this.caseInsensitive = false,
    this.anchored = false,
    this.global = true,
    this.maxMatches = 2000,
    this.baseStyle = const TextStyle(fontSize: 14),
    this.matchBackground = const Color(0xFFFFC107),
    this.matchForeground = const Color(0xFF000000),
  });

  @override
  Widget build(BuildContext context) {
    if (pattern == null || pattern!.isEmpty || text.isEmpty) {
      return Text(text, style: baseStyle);
    }

    RegExp? regex;
    try {
      regex = RegExp(
        pattern!,
        caseSensitive: !caseInsensitive,
        multiLine: anchored,
      );
    } catch (_) {
      return Text(text, style: baseStyle);
    }

    final matchStyle = baseStyle.copyWith(
      color: matchForeground,
      fontWeight: FontWeight.bold,
    );

    final spans = <InlineSpan>[];
    int cursor = 0;
    int count = 0;

    void addMatchSpan(String matched) {
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 1),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: matchBackground,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(matched, style: matchStyle),
          ),
        ),
      );
    }

    Iterable<RegExpMatch> matches;
    if (global) {
      matches = regex.allMatches(text).take(maxMatches);
    } else {
      final first = regex.firstMatch(text);
      matches = first == null ? const [] : [first];
    }

    for (final match in matches) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, match.start)));
      }
      addMatchSpan(match.group(0) ?? '');
      cursor = match.end;
      count++;
    }

    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(children: spans, style: baseStyle),
          textScaler: MediaQuery.textScalerOf(context),
        ),
        if (count > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '共匹配 $count 处',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.green.shade800,
              ),
            ),
          ),
      ],
    );
  }
}
