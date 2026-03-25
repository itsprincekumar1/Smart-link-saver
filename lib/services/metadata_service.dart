import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;

/// Service to fetch metadata (like preview images) from a given URL.
class MetadataService {
  MetadataService._();

  /// Fetches the Open Graph or Twitter preview image URL from a given [url].
  /// Returns null if the request fails or no main image is found.
  static Future<String?> fetchImageUrl(String url) async {
    try {
      final uri = Uri.tryParse(url);
      if (uri == null) return null;

      final response = await http.get(
        uri,
        headers: {
          // Use a common User-Agent to prevent basic 403 Forbidden blocks from some sites
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
              '(KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml',
        },
      ).timeout(const Duration(seconds: 8)); // Don't hang indefinitely

      if (response.statusCode != 200) return null;

      final document = parser.parse(response.body);

      // 1. Try og:image
      final ogImage = document.querySelector('meta[property="og:image"]');
      if (ogImage != null && ogImage.attributes.containsKey('content')) {
        return _ensureAbsoluteUrl(ogImage.attributes['content']!, uri);
      }

      // 2. Try twitter:image
      final twitterImage = document.querySelector('meta[name="twitter:image"]');
      if (twitterImage != null && twitterImage.attributes.containsKey('content')) {
        return _ensureAbsoluteUrl(twitterImage.attributes['content']!, uri);
      }

      // 3. Fallbacks for Amazon/Flipkart specific product pages if OG tags are missing
      final amzImage = document.querySelector('img#landingImage') ??
          document.querySelector('img#imgBlkFront') ??
          document.querySelector('img._396cs4'); // Flipkart main image class

      if (amzImage != null) {
        final src = amzImage.attributes['src'] ?? amzImage.attributes['data-old-hires'];
        if (src != null) {
           return _ensureAbsoluteUrl(src, uri);
        }
      }

      return null;
    } catch (_) {
      // Ignore network or parsing errors to not crash the app
      return null;
    }
  }

  /// Ensures the extracted URL is absolute, using the base URI if it's relative.
  static String _ensureAbsoluteUrl(String extracted, Uri baseUri) {
    if (extracted.startsWith('http://') || extracted.startsWith('https://')) {
      return extracted;
    }
    if (extracted.startsWith('//')) {
      return '${baseUri.scheme}:$extracted';
    }
    // Handle relative path
    return baseUri.resolve(extracted).toString();
  }
}
