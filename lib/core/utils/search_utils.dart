/// Fuzzy search utility for searching links across URLs, notes, and folder names.
class SearchUtils {
  SearchUtils._();

  /// Performs a fuzzy search on a list of [items] using the [query].
  ///
  /// Each item is scored based on how well the query matches the provided
  /// searchable text. Returns items sorted by relevance (highest first).
  ///
  /// [textExtractor] should return all searchable text for an item.
  static List<T> fuzzySearch<T>({
    required String query,
    required List<T> items,
    required List<String> Function(T item) textExtractor,
    double threshold = 0.3,
  }) {
    if (query.trim().isEmpty) return items;

    final queryLower = query.toLowerCase().trim();
    final queryWords = queryLower.split(RegExp(r'\s+'));

    final scored = <_ScoredItem<T>>[];

    for (final item in items) {
      final texts = textExtractor(item);
      double bestScore = 0.0;

      for (final text in texts) {
        final score = _calculateScore(queryLower, queryWords, text.toLowerCase());
        if (score > bestScore) bestScore = score;
      }

      if (bestScore >= threshold) {
        scored.add(_ScoredItem(item: item, score: bestScore));
      }
    }

    // Sort by score descending
    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.map((s) => s.item).toList();
  }

  /// Calculates a relevance score between 0.0 and 1.0.
  static double _calculateScore(
    String query,
    List<String> queryWords,
    String text,
  ) {
    if (text.isEmpty) return 0.0;

    double score = 0.0;

    // Exact match gets highest score
    if (text == query) return 1.0;

    // Contains full query
    if (text.contains(query)) {
      score = 0.9;
      // Earlier match = slightly higher score
      final index = text.indexOf(query);
      score += (1.0 - (index / text.length)) * 0.1;
      return score.clamp(0.0, 1.0);
    }

    // Word-by-word matching
    int matchedWords = 0;
    for (final word in queryWords) {
      if (word.isEmpty) continue;
      if (text.contains(word)) {
        matchedWords++;
      } else {
        // Partial word match (substring within words of the text)
        final textWords = text.split(RegExp(r'[\s\-_/.:]+'));
        for (final tw in textWords) {
          if (tw.contains(word) || word.contains(tw)) {
            matchedWords++;
            break;
          }
        }
      }
    }

    if (queryWords.isNotEmpty) {
      score = (matchedWords / queryWords.length) * 0.7;
    }

    return score.clamp(0.0, 1.0);
  }
}

class _ScoredItem<T> {
  final T item;
  final double score;
  const _ScoredItem({required this.item, required this.score});
}
