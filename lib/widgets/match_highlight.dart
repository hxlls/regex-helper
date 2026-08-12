import 'package:flutter/material.dart';

class MatchHighlight extends StatelessWidget {
  final String text;
  final String? pattern;
  final bool caseInsensitive;
  final bool anchored;
  final bool global;
  final int maxMatches;
  final TextStyle baseStyle;
  final TextStyle matchStyle;

  const MatchHighlight({
    super.key,
    required this.text,
    required this.pattern,
    this.caseInsensitive = false,
    this.anchored = false,
    this.global = true,
    this.maxMatches = 2000,
    this.baseStyle = const TextStyle(fontSize: 14),
    this.matchStyle = const TextStyle(
      fontSize: 14,
      color: Colors.black,
      backgroundColor: Colors.yellow,
      fontWeight: FontWeight.bold,
    ),
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

    final spans = <TextSpan>[];
    int cursor = 0;
    int count = 0;

    if (!global) {
      final match = regex.firstMatch(text);
      if (match != null) {
        if (match.start > 0) {
          spans.add(TextSpan(text: text.substring(0, match.start)));
        }
        spans.add(TextSpan(text: match.group(0), style: matchStyle));
        cursor = match.end;
      }
    } else {
      for (final match in regex.allMatches(text)) {
        if (count >= maxMatches) break;
        if (match.start > cursor) {
          spans.add(TextSpan(text: text.substring(cursor, match.start)));
        }
        spans.add(TextSpan(text: match.group(0), style: matchStyle));
        cursor = match.end;
        count++;
      }
    }

    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }

    return RichText(
      text: TextSpan(children: spans, style: baseStyle),
      textScaler: MediaQuery.textScalerOf(context),
    );
  }
}
