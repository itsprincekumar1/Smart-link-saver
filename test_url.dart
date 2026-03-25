void main() {
  final _urlRegex = RegExp(
    r'https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)',
    caseSensitive: false,
  );

  String? _cleanUrl(String raw) {
    String cleaned = raw.trim().replaceAll(RegExp(r'[.,;:!?()\[\]{}"' + "'" + r' ]+$'), '');
    final uri = Uri.tryParse(cleaned);
    if (uri != null && uri.hasScheme && uri.hasAuthority) {
      return cleaned;
    }
    return null;
  }

  bool isValidUrl(String? text) {
    if (text == null || text.trim().isEmpty) return false;
    return _urlRegex.hasMatch(text.trim());
  }

  String? extractFirstValidUrl(String text) {
    if (text.trim().isEmpty) return null;

    final directUrl = _cleanUrl(text);
    if (directUrl != null && isValidUrl(directUrl)) {
      return directUrl;
    }

    final urlMatch = _urlRegex.firstMatch(text);
    if (urlMatch != null) {
      final extracted = _cleanUrl(urlMatch.group(0)!);
      if (extracted != null && isValidUrl(extracted)) {
        return extracted;
      }
    }
    return null;
  }

  final test1 = "Checkout this amazing product https://amzn.in/d/abc";
  final test2 = "Take a look at this product on Flipkart https://dl.flipkart.com/dl/xyz";
  final test3 = "Shop top fashion: https://myntra.com/shoes/123 !!";
  final test4 = "https://amazon.com";

  print('Test 1: ${extractFirstValidUrl(test1)}');
  print('Test 2: ${extractFirstValidUrl(test2)}');
  print('Test 3: ${extractFirstValidUrl(test3)}');
  print('Test 4: ${extractFirstValidUrl(test4)}');
}
