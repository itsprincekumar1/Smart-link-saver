import '../constants.dart';
import 'url_utils.dart';

/// Result of categorizing a link.
class CategoryResult {
  final String category;
  final String subCategory;
  final String tertiaryCategory;

  const CategoryResult({
    required this.category,
    this.subCategory = '',
    this.tertiaryCategory = '',
  });

  @override
  String toString() {
    if (tertiaryCategory.isNotEmpty) {
      return '$category / $subCategory / $tertiaryCategory';
    }
    return subCategory.isNotEmpty ? '$category / $subCategory' : category;
  }
}

/// Categorizes links based on domain name and URL keywords.
class LinkCategorizer {
  LinkCategorizer._();

  /// Domain-to-category mapping table.
  static const Map<String, String> _domainCategoryMap = {
    // Shopping / Products
    'amazon': AppConstants.categoryShopping,
    'flipkart': AppConstants.categoryShopping,
    'ebay': AppConstants.categoryShopping,
    'walmart': AppConstants.categoryShopping,
    'alibaba': AppConstants.categoryShopping,
    'etsy': AppConstants.categoryShopping,
    'shopify': AppConstants.categoryShopping,
    'myntra': AppConstants.categoryShopping,
    'ajio': AppConstants.categoryShopping,
    'meesho': AppConstants.categoryShopping,
    'nike': AppConstants.categoryShopping,
    'adidas': AppConstants.categoryShopping,
    'zara': AppConstants.categoryShopping,

    // Video
    'youtube': AppConstants.categoryVideo,
    'youtu': AppConstants.categoryVideo,
    'vimeo': AppConstants.categoryVideo,
    'dailymotion': AppConstants.categoryVideo,
    'twitch': AppConstants.categoryVideo,
    'netflix': AppConstants.categoryVideo,
    'hotstar': AppConstants.categoryVideo,
    'primevideo': AppConstants.categoryVideo,

    // Music
    'spotify': AppConstants.categoryMusic,
    'soundcloud': AppConstants.categoryMusic,
    'music.apple': AppConstants.categoryMusic,
    'gaana': AppConstants.categoryMusic,
    'jiosaavn': AppConstants.categoryMusic,

    // Development
    'github': AppConstants.categoryDevelopment,
    'gitlab': AppConstants.categoryDevelopment,
    'bitbucket': AppConstants.categoryDevelopment,
    'stackoverflow': AppConstants.categoryDevelopment,
    'dev.to': AppConstants.categoryDevelopment,
    'npmjs': AppConstants.categoryDevelopment,
    'pub.dev': AppConstants.categoryDevelopment,
    'codepen': AppConstants.categoryDevelopment,
    'medium': AppConstants.categoryArticle,
    'hashnode': AppConstants.categoryDevelopment,

    // Social Media
    'twitter': AppConstants.categorySocial,
    'x': AppConstants.categorySocial,
    'facebook': AppConstants.categorySocial,
    'instagram': AppConstants.categorySocial,
    'linkedin': AppConstants.categorySocial,
    'reddit': AppConstants.categorySocial,
    'pinterest': AppConstants.categorySocial,
    'tiktok': AppConstants.categorySocial,
    'snapchat': AppConstants.categorySocial,
    'threads': AppConstants.categorySocial,

    // News
    'bbc': AppConstants.categoryNews,
    'cnn': AppConstants.categoryNews,
    'reuters': AppConstants.categoryNews,
    'theguardian': AppConstants.categoryNews,
    'nytimes': AppConstants.categoryNews,
    'ndtv': AppConstants.categoryNews,
    'timesofindia': AppConstants.categoryNews,
    'hindustantimes': AppConstants.categoryNews,

    // Education
    'coursera': AppConstants.categoryEducation,
    'udemy': AppConstants.categoryEducation,
    'edx': AppConstants.categoryEducation,
    'khanacademy': AppConstants.categoryEducation,
    'skillshare': AppConstants.categoryEducation,
    'pluralsight': AppConstants.categoryEducation,

    // Finance
    'moneycontrol': AppConstants.categoryFinance,
    'zerodha': AppConstants.categoryFinance,
    'groww': AppConstants.categoryFinance,
    'paypal': AppConstants.categoryFinance,
    'stripe': AppConstants.categoryFinance,

    // Travel
    'booking': AppConstants.categoryTravel,
    'airbnb': AppConstants.categoryTravel,
    'makemytrip': AppConstants.categoryTravel,
    'tripadvisor': AppConstants.categoryTravel,
    'expedia': AppConstants.categoryTravel,
    'goibibo': AppConstants.categoryTravel,

    // Food
    'zomato': AppConstants.categoryFood,
    'swiggy': AppConstants.categoryFood,
    'ubereats': AppConstants.categoryFood,
    'doordash': AppConstants.categoryFood,

    // Health
    'practo': AppConstants.categoryHealth,
    'webmd': AppConstants.categoryHealth,
    'healthline': AppConstants.categoryHealth,
  };

  /// URL keyword-to-subcategory mapping for product links.
  static const Map<String, String> _productSubCategories = {
    'shoe': 'Shoes',
    'sneaker': 'Shoes',
    'sandal': 'Shoes',
    'boot': 'Shoes',
    'electronics': 'Electronics',
    'phone': 'Electronics',
    'laptop': 'Electronics',
    'computer': 'Electronics',
    'tablet': 'Electronics',
    'headphone': 'Electronics',
    'earphone': 'Electronics',
    'earbuds': 'Electronics',
    'clothing': 'Clothing',
    'shirt': 'Clothing',
    'pant': 'Clothing',
    'dress': 'Clothing',
    'jacket': 'Clothing',
    'jeans': 'Clothing',
    'tshirt': 'Clothing',
    't-shirt': 'Clothing',
    'book': 'Books',
    'kindle': 'Books',
    'furniture': 'Home & Furniture',
    'sofa': 'Home & Furniture',
    'table': 'Home & Furniture',
    'chair': 'Home & Furniture',
    'kitchen': 'Home & Kitchen',
    'appliance': 'Home & Kitchen',
    'beauty': 'Beauty',
    'skincare': 'Beauty',
    'makeup': 'Beauty',
    'toy': 'Toys & Games',
    'game': 'Toys & Games',
    'sport': 'Sports',
    'fitness': 'Sports',
    'grocery': 'Grocery',
    'food': 'Grocery',
  };

  /// Categorizes a [url] and returns a [CategoryResult].
  static CategoryResult categorize(String url) {
    final shortDomain = UrlUtils.extractShortDomain(url).toLowerCase();
    final fullDomain = UrlUtils.extractDomain(url).toLowerCase();
    final fullUrl = url.toLowerCase();

    // 1) Check domain mapping
    String category = AppConstants.categoryGeneral;
    for (final entry in _domainCategoryMap.entries) {
      if (entry.key.length <= 2) {
        if (shortDomain == entry.key) {
          category = entry.value;
          break;
        }
      } else if (shortDomain.contains(entry.key) ||
                 fullDomain.contains(entry.key)) {
        category = entry.value;
        break;
      }
    }

    // 2) Detect product sub-category from URL keywords
    String itemType = '';
    if (category == AppConstants.categoryShopping ||
        category == AppConstants.categoryGeneral) {
      for (final entry in _productSubCategories.entries) {
        if (fullUrl.contains(entry.key)) {
          itemType = entry.value;
          if (category == AppConstants.categoryGeneral) {
            category = AppConstants.categoryShopping;
          }
          break;
        }
      }
    }

    String subCategory = '';
    String tertiaryCategory = '';

    if (category == AppConstants.categoryShopping) {
      // For shopping, subCategory is the platform (e.g. Myntra), tertiary is the item type (e.g. Shoes)
      String vendor = '';
      for (final entry in _domainCategoryMap.entries) {
        if (entry.value == AppConstants.categoryShopping && 
            (shortDomain.contains(entry.key) || fullDomain.contains(entry.key))) {
          vendor = entry.key[0].toUpperCase() + entry.key.substring(1);
          break;
        }
      }
      if (vendor.isEmpty && shortDomain.isNotEmpty) {
        vendor = shortDomain[0].toUpperCase() + shortDomain.substring(1);
      }
      
      subCategory = vendor;
      tertiaryCategory = itemType;
    } else {
      // For non-shopping, keep the old behavior
      subCategory = itemType;
    }

    return CategoryResult(
      category: category,
      subCategory: subCategory,
      tertiaryCategory: tertiaryCategory,
    );
  }

  /// Returns an icon name string for a given category.
  static String iconForCategory(String category) {
    return switch (category) {
      AppConstants.categoryShopping => 'shopping_bag',
      AppConstants.categoryVideo => 'play_circle',
      AppConstants.categoryMusic => 'music_note',
      AppConstants.categoryNews => 'newspaper',
      AppConstants.categoryArticle => 'article',
      AppConstants.categoryDevelopment => 'code',
      AppConstants.categorySocial => 'people',
      AppConstants.categoryEducation => 'school',
      AppConstants.categoryFinance => 'account_balance',
      AppConstants.categoryTravel => 'flight',
      AppConstants.categoryFood => 'restaurant',
      AppConstants.categoryHealth => 'health_and_safety',
      _ => 'folder',
    };
  }
}
