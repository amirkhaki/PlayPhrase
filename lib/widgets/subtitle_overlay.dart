import 'package:flutter/material.dart';
import '../models/phrase.dart';

class SubtitleOverlay extends StatelessWidget {
  final Phrase phrase;
  final Duration currentPosition;

  const SubtitleOverlay({
    super.key,
    required this.phrase,
    required this.currentPosition,
  });

  @override
  Widget build(BuildContext context) {
    final currentMs = currentPosition.inMilliseconds;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: const TextStyle(
            fontSize: 20,
            color: Colors.white,
            height: 1.4,
          ),
          children: _buildTextSpans(currentMs),
        ),
      ),
    );
  }

  List<TextSpan> _buildTextSpans(int currentMs) {
    final spans = <TextSpan>[];
    
    for (int i = 0; i < phrase.words.length; i++) {
      final word = phrase.words[i];
      final isCurrentWord = currentMs >= word.start && currentMs <= word.end;
      final isSearchedWord = word.searched;
      
      TextStyle style = const TextStyle(color: Colors.white);
      
      if (isSearchedWord && isCurrentWord) {
        style = const TextStyle(
          color: Colors.yellow,
          fontWeight: FontWeight.bold,
          decoration: TextDecoration.underline,
          decorationColor: Colors.yellow,
          decorationThickness: 2,
        );
      } else if (isSearchedWord) {
        style = const TextStyle(
          color: Colors.yellow,
          fontWeight: FontWeight.bold,
        );
      } else if (isCurrentWord) {
        style = const TextStyle(
          color: Colors.white,
          decoration: TextDecoration.underline,
          decorationColor: Colors.white,
          decorationThickness: 2,
        );
      }
      
      spans.add(TextSpan(text: word.text, style: style));
      
      if (i < phrase.words.length - 1) {
        spans.add(const TextSpan(text: ' '));
      }
    }
    
    return spans;
  }
}

/// Subtitle overlay that parses embedded subtitle text with <u> tags
class EmbeddedSubtitleOverlay extends StatelessWidget {
  final String subtitleText;
  final String searchQuery;

  const EmbeddedSubtitleOverlay({
    super.key,
    required this.subtitleText,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    if (subtitleText.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: const TextStyle(
            fontSize: 20,
            color: Colors.white,
            height: 1.4,
          ),
          children: _parseSubtitle(),
        ),
      ),
    );
  }

  List<TextSpan> _parseSubtitle() {
    final spans = <TextSpan>[];
    final searchLower = searchQuery.toLowerCase();
    
    // Parse text with <u> tags
    final regex = RegExp(r'<u>([^<]+)</u>|([^<]+)');
    final matches = regex.allMatches(subtitleText);
    
    for (final match in matches) {
      final underlinedText = match.group(1);
      final normalText = match.group(2);
      
      if (underlinedText != null) {
        // This is the current word (underlined)
        final isSearched = searchLower.split(' ').any(
          (term) => underlinedText.toLowerCase().contains(term)
        );
        
        spans.add(TextSpan(
          text: underlinedText,
          style: TextStyle(
            color: isSearched ? Colors.yellow : Colors.white,
            fontWeight: isSearched ? FontWeight.bold : FontWeight.normal,
            decoration: TextDecoration.underline,
            decorationColor: isSearched ? Colors.yellow : Colors.white,
            decorationThickness: 2,
          ),
        ));
      } else if (normalText != null) {
        // Parse normal text for search terms
        _addHighlightedText(spans, normalText, searchLower);
      }
    }
    
    return spans;
  }

  void _addHighlightedText(List<TextSpan> spans, String text, String searchLower) {
    final searchTerms = searchLower.split(' ').where((t) => t.isNotEmpty).toList();
    
    if (searchTerms.isEmpty) {
      spans.add(TextSpan(text: text));
      return;
    }

    // Build pattern to match any search term (case insensitive)
    final pattern = RegExp(
      '(${searchTerms.map((t) => RegExp.escape(t)).join('|')})',
      caseSensitive: false,
    );
    
    int lastEnd = 0;
    for (final match in pattern.allMatches(text)) {
      // Add text before match
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }
      // Add highlighted match
      spans.add(TextSpan(
        text: match.group(0),
        style: const TextStyle(
          color: Colors.yellow,
          fontWeight: FontWeight.bold,
        ),
      ));
      lastEnd = match.end;
    }
    
    // Add remaining text
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }
  }
}
