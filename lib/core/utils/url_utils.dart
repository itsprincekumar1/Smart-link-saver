/// Utility functions for URL detection, validation, and processing.
class UrlUtils {
  UrlUtils._();

  /// Regex pattern for matching URLs.
  static final RegExp _urlRegex = RegExp(
    r'https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)',
    caseSensitive: false,
  );

  /// Simple check for URL-like strings (less strict).
  static final RegExp _looseUrlRegex = RegExp(
    r'^(https?:\/\/|www\.)[^\s]+$',
    caseSensitive: false,
  );

  /// Checks if the given [text] is a valid URL.
  static bool isValidUrl(String? text) {
    if (text == null || text.trim().isEmpty) return false;
    final trimmed = text.trim();
    return _urlRegex.hasMatch(trimmed) || _looseUrlRegex.hasMatch(trimmed);
  }

  /// Extracts the domain name from a [url].
  /// e.g., "https://www.amazon.com/dp/123" → "amazon.com"
  static String extractDomain(String url) {
    try {
      final uri = Uri.parse(url.trim());
      String host = uri.host;
      // Remove 'www.' prefix
      if (host.startsWith('www.')) {
        host = host.substring(4);
      }
      return host;
    } catch (_) {
      return '';
    }
  }

  /// Extracts the short domain name (without TLD).
  /// e.g., "https://www.amazon.com/shoes" → "amazon"
  static String extractShortDomain(String url) {
    final domain = extractDomain(url);
    if (domain.isEmpty) return '';
    final parts = domain.split('.');
    return parts.isNotEmpty ? parts.first : domain;
  }

  /// Generates an auto-note from a URL by parsing path segments.
  /// e.g., "https://nike.com/shoes/airmax" → "Nike Shoes Airmax"
  static String generateAutoNote(String url) {
    try {
      final uri = Uri.parse(url.trim());
      final parts = <String>[];

      // Add the short domain name
      final shortDomain = extractShortDomain(url);
      if (shortDomain.isNotEmpty) {
        parts.add(_capitalize(shortDomain));
      }

      // Parse path segments - take meaningful ones
      for (final segment in uri.pathSegments) {
        if (segment.isEmpty) continue;
        // Skip common noise segments
        if (_isNoiseSegment(segment)) continue;
        // Clean up the segment
        final cleaned = _cleanSegment(segment);
        if (cleaned.isNotEmpty && cleaned.length > 1) {
          parts.add(_capitalize(cleaned));
        }
      }

      if (parts.isEmpty) {
        return extractDomain(url);
      }

      // Limit to first 6 meaningful parts
      return parts.take(6).join(' ');
    } catch (_) {
      return extractDomain(url);
    }
  }

  /// Checks if a segment is noise (common URL structure elements).
  static bool _isNoiseSegment(String segment) {
    const noisePatterns = [
      'dp', 'gp', 'ref', 'product', 'watch', 'v', 'p', 'id',
      'index', 'page', 'en', 'us', 'in', 'uk', 'html', 'htm',
      'php', 'asp', 'aspx', 'jsp',
    ];
    // Skip segments that are just numbers or IDs
    if (RegExp(r'^[0-9a-f\-]{8,}$', caseSensitive: false).hasMatch(segment)) {
      return true;
    }
    if (RegExp(r'^\d+$').hasMatch(segment)) return true;
    return noisePatterns.contains(segment.toLowerCase());
  }

  /// Cleans a URL segment: removes hyphens, underscores, and query-like parts.
  static String _cleanSegment(String segment) {
    // Remove query parameters and fragments
    String cleaned = segment.split('?').first.split('#').first;
    // Remove file extensions
    cleaned = cleaned.replaceAll(RegExp(r'\.\w{2,4}$'), '');
    // Replace hyphens and underscores with spaces, then collapse
    cleaned = cleaned.replaceAll(RegExp(r'[-_]+'), ' ').trim();
    return cleaned;
  }

  /// Capitalizes the first letter of a string.
  static String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  /// Ensures a URL has a scheme (prepends https:// if missing).
  static String ensureScheme(String url) {
    final trimmed = url.trim();
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      return 'https://$trimmed';
    }
    return trimmed;
  }
}
