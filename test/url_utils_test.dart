import 'package:flutter_test/flutter_test.dart';
import 'package:link_keeper/core/utils/url_utils.dart';

void main() {
  group('UrlUtils.isValidUrl', () {
    test('should return true for valid HTTP URLs', () {
      expect(UrlUtils.isValidUrl('http://example.com'), isTrue);
      expect(UrlUtils.isValidUrl('https://example.com'), isTrue);
      expect(UrlUtils.isValidUrl('https://www.example.com'), isTrue);
    });

    test('should return true for URLs with paths and query params', () {
      expect(UrlUtils.isValidUrl('https://amazon.com/dp/B123456'), isTrue);
      expect(UrlUtils.isValidUrl('https://example.com/path?q=hello'), isTrue);
      expect(UrlUtils.isValidUrl('https://example.com/path#section'), isTrue);
    });

    test('should return false for plain text', () {
      expect(UrlUtils.isValidUrl('hello world'), isFalse);
      expect(UrlUtils.isValidUrl('not a url'), isFalse);
      expect(UrlUtils.isValidUrl('justtext'), isFalse);
    });

    test('should return false for null and empty strings', () {
      expect(UrlUtils.isValidUrl(null), isFalse);
      expect(UrlUtils.isValidUrl(''), isFalse);
      expect(UrlUtils.isValidUrl('   '), isFalse);
    });

    test('should handle URLs with various TLDs', () {
      expect(UrlUtils.isValidUrl('https://example.co.uk'), isTrue);
      expect(UrlUtils.isValidUrl('https://example.io'), isTrue);
      expect(UrlUtils.isValidUrl('https://example.dev'), isTrue);
    });
  });

  group('UrlUtils.extractDomain', () {
    test('should extract domain without www prefix', () {
      expect(UrlUtils.extractDomain('https://www.amazon.com/dp/123'), 'amazon.com');
      expect(UrlUtils.extractDomain('https://example.com'), 'example.com');
    });

    test('should handle URLs without www', () {
      expect(UrlUtils.extractDomain('https://github.com/user'), 'github.com');
    });

    test('should return empty string for invalid URLs', () {
      expect(UrlUtils.extractDomain('not-a-url'), isEmpty);
    });
  });

  group('UrlUtils.extractShortDomain', () {
    test('should extract short domain name', () {
      expect(UrlUtils.extractShortDomain('https://www.amazon.com/dp/123'), 'amazon');
      expect(UrlUtils.extractShortDomain('https://youtube.com/watch?v=abc'), 'youtube');
      expect(UrlUtils.extractShortDomain('https://github.com/user/repo'), 'github');
    });
  });

  group('UrlUtils.generateAutoNote', () {
    test('should generate a readable note from URL', () {
      final note = UrlUtils.generateAutoNote('https://nike.com/shoes/airmax');
      expect(note.toLowerCase(), contains('nike'));
      expect(note.toLowerCase(), contains('shoes'));
      expect(note.toLowerCase(), contains('airmax'));
    });

    test('should capitalize words in the note', () {
      final note = UrlUtils.generateAutoNote('https://example.com/flutter/widgets');
      expect(note, contains('Example'));
    });

    test('should handle URLs with only domain', () {
      final note = UrlUtils.generateAutoNote('https://google.com');
      expect(note, isNotEmpty);
    });

    test('should skip noise segments like IDs', () {
      final note = UrlUtils.generateAutoNote('https://amazon.com/dp/B08N5WRWNW');
      // Should not include the product ID as a word
      expect(note.toLowerCase(), contains('amazon'));
    });
  });

  group('UrlUtils.ensureScheme', () {
    test('should add https:// if no scheme present', () {
      expect(UrlUtils.ensureScheme('example.com'), 'https://example.com');
      expect(UrlUtils.ensureScheme('www.example.com'), 'https://www.example.com');
    });

    test('should not modify URLs that already have a scheme', () {
      expect(UrlUtils.ensureScheme('https://example.com'), 'https://example.com');
      expect(UrlUtils.ensureScheme('http://example.com'), 'http://example.com');
    });
  });
}
