/// App-wide constants for Smart Link Keeper.
class AppConstants {
  AppConstants._();

  // App info
  static const String appName = 'Smart Link Keeper';
  static const String appVersion = '1.0.0';

  // Hive box names
  static const String linksBox = 'links_box';
  static const String foldersBox = 'folders_box';
  static const String settingsBox = 'settings_box';

  // Settings keys
  static const String clipboardMonitoringKey = 'clipboard_monitoring';
  static const String lastClipboardContentKey = 'last_clipboard_content';

  // Clipboard polling interval
  static const Duration clipboardPollInterval = Duration(seconds: 2);

  // Category names
  static const String categoryProduct = 'Product';
  static const String categoryShopping = 'Shopping';
  static const String categoryVideo = 'Video';
  static const String categoryMusic = 'Music';
  static const String categoryNews = 'News';
  static const String categoryArticle = 'Article';
  static const String categoryDevelopment = 'Development';
  static const String categorySocial = 'Social Media';
  static const String categoryEducation = 'Education';
  static const String categoryFinance = 'Finance';
  static const String categoryTravel = 'Travel';
  static const String categoryFood = 'Food';
  static const String categoryHealth = 'Health';
  static const String categoryGeneral = 'General';
}
