import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme/app_theme.dart';
import 'data/models/link_model.dart';
import 'data/models/folder_model.dart';
import 'data/repositories/link_repository.dart';
import 'data/repositories/folder_repository.dart';
import 'providers/providers.dart';
import 'services/share_intent_service.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/share_save_screen.dart';

/// Entry point for Smart Link Keeper.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register type adapters
  Hive.registerAdapter(LinkModelAdapter());
  Hive.registerAdapter(FolderModelAdapter());

  // Initialize repositories (opens Hive boxes)
  final linkRepo = LinkRepository();
  final folderRepo = FolderRepository();
  await linkRepo.init();
  await folderRepo.init();

  // Check if launched via a share intent
  final shareService = ShareIntentService();
  final initialUrl = await shareService.getInitialSharedUrl();

  runApp(
    ProviderScope(
      overrides: [
        // Provide the initialized repositories
        linkRepositoryProvider.overrideWithValue(linkRepo),
        folderRepositoryProvider.overrideWithValue(folderRepo),
      ],
      child: SmartLinkKeeperApp(
        shareIntentService: shareService,
        initialSharedUrl: initialUrl,
      ),
    ),
  );
}

/// Root widget for the Smart Link Keeper app.
class SmartLinkKeeperApp extends StatefulWidget {
  final ShareIntentService shareIntentService;
  final String? initialSharedUrl;

  const SmartLinkKeeperApp({
    super.key,
    required this.shareIntentService,
    this.initialSharedUrl,
  });

  @override
  State<SmartLinkKeeperApp> createState() => _SmartLinkKeeperAppState();
}

class _SmartLinkKeeperAppState extends State<SmartLinkKeeperApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final StreamSubscription<String> _shareSub;

  @override
  void initState() {
    super.initState();

    // Start listening for share intents while the app is in memory
    widget.shareIntentService.startListening();
    _shareSub = widget.shareIntentService.sharedUrlStream.listen((url) {
      // Push the save screen when a new URL is shared while app is running
      _navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => ShareSaveScreen(url: url),
        ),
      );
    });
  }

  @override
  void dispose() {
    _shareSub.cancel();
    widget.shareIntentService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Link Keeper',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      navigatorKey: _navigatorKey,
      home: widget.initialSharedUrl != null
          ? ShareSaveScreen(url: widget.initialSharedUrl!)
          : const HomeScreen(),
    );
  }
}
