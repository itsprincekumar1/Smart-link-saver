import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme/app_theme.dart';
import 'data/models/link_model.dart';
import 'data/models/folder_model.dart';
import 'data/repositories/link_repository.dart';
import 'data/repositories/folder_repository.dart';
import 'providers/providers.dart';
import 'presentation/screens/home_screen.dart';

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

  runApp(
    ProviderScope(
      overrides: [
        // Provide the initialized repositories
        linkRepositoryProvider.overrideWithValue(linkRepo),
        folderRepositoryProvider.overrideWithValue(folderRepo),
      ],
      child: const SmartLinkKeeperApp(),
    ),
  );
}

/// Root widget for the Smart Link Keeper app.
class SmartLinkKeeperApp extends StatelessWidget {
  const SmartLinkKeeperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Link Keeper',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
