import 'package:flutter_test/flutter_test.dart';
import 'package:link_keeper/core/utils/categorizer.dart';
import 'package:link_keeper/core/constants.dart';

void main() {
  group('LinkCategorizer.categorize', () {
    test('should categorize Amazon links as Shopping', () {
      final result = LinkCategorizer.categorize('https://www.amazon.com/dp/B08N5WRWNW');
      expect(result.category, AppConstants.categoryShopping);
    });

    test('should categorize Flipkart links as Shopping', () {
      final result = LinkCategorizer.categorize('https://www.flipkart.com/product/123');
      expect(result.category, AppConstants.categoryShopping);
    });

    test('should categorize YouTube links as Video', () {
      final result = LinkCategorizer.categorize('https://www.youtube.com/watch?v=dQw4w9WgXcQ');
      expect(result.category, AppConstants.categoryVideo);
    });

    test('should categorize GitHub links as Development', () {
      final result = LinkCategorizer.categorize('https://github.com/flutter/flutter');
      expect(result.category, AppConstants.categoryDevelopment);
    });

    test('should categorize StackOverflow links as Development', () {
      final result = LinkCategorizer.categorize('https://stackoverflow.com/questions/123');
      expect(result.category, AppConstants.categoryDevelopment);
    });

    test('should categorize Twitter/X links as Social Media', () {
      final result = LinkCategorizer.categorize('https://twitter.com/user/status/123');
      expect(result.category, AppConstants.categorySocial);
    });

    test('should categorize Instagram links as Social Media', () {
      final result = LinkCategorizer.categorize('https://www.instagram.com/p/abc123');
      expect(result.category, AppConstants.categorySocial);
    });

    test('should categorize LinkedIn links as Social Media', () {
      final result = LinkCategorizer.categorize('https://www.linkedin.com/in/johndoe');
      expect(result.category, AppConstants.categorySocial);
    });

    test('should categorize Spotify links as Music', () {
      final result = LinkCategorizer.categorize('https://open.spotify.com/track/abc');
      expect(result.category, AppConstants.categoryMusic);
    });

    test('should categorize Coursera links as Education', () {
      final result = LinkCategorizer.categorize('https://www.coursera.org/learn/flutter');
      expect(result.category, AppConstants.categoryEducation);
    });

    test('should categorize BBC links as News', () {
      final result = LinkCategorizer.categorize('https://www.bbc.com/news/world');
      expect(result.category, AppConstants.categoryNews);
    });

    test('should categorize unknown domains as General', () {
      final result = LinkCategorizer.categorize('https://randomsite.xyz/page');
      expect(result.category, AppConstants.categoryGeneral);
    });

    test('should detect product sub-categories from URL keywords', () {
      final result = LinkCategorizer.categorize('https://www.amazon.com/shoes/nike-airmax');
      expect(result.category, AppConstants.categoryShopping);
      expect(result.subCategory, 'Shoes');
    });

    test('should detect electronics sub-category', () {
      final result = LinkCategorizer.categorize('https://www.flipkart.com/laptop/dell-inspiron');
      expect(result.subCategory, 'Electronics');
    });

    test('should handle URLs with shoe keywords for unknown domains', () {
      final result = LinkCategorizer.categorize('https://someshoestore.com/sneaker/nike');
      // Should be categorized as Shopping because of the 'sneaker' keyword
      expect(result.category, AppConstants.categoryShopping);
      expect(result.subCategory, 'Shoes');
    });
  });

  group('LinkCategorizer.iconForCategory', () {
    test('should return correct icon names for categories', () {
      expect(LinkCategorizer.iconForCategory(AppConstants.categoryShopping), 'shopping_bag');
      expect(LinkCategorizer.iconForCategory(AppConstants.categoryVideo), 'play_circle');
      expect(LinkCategorizer.iconForCategory(AppConstants.categoryDevelopment), 'code');
      expect(LinkCategorizer.iconForCategory(AppConstants.categoryGeneral), 'folder');
    });
  });
}
