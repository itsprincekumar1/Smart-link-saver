import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/utils/categorizer.dart';
import '../../core/utils/url_utils.dart';
import '../../data/models/link_model.dart';
import '../../providers/providers.dart';
import '../../services/clipboard_service.dart';
import '../widgets/folder_card.dart';
import '../widgets/clipboard_popup.dart';
import '../widgets/create_folder_dialog.dart';
import '../widgets/save_link_dialog.dart';
import 'folder_detail_screen.dart';
import 'history_screen.dart';
import 'search_results_screen.dart';
import 'settings_screen.dart';
import '../../services/folder_share_service.dart';

/// The main home screen of Smart Link Keeper.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  late final ClipboardService _clipboardService;
  final _searchController = TextEditingController();
  String? _popupUrl;
  String _popupCategory = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _clipboardService = ClipboardService(
      onNewUrl: _onNewUrlDetected,
    );

    // Start monitoring after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(clipboardMonitoringProvider)) {
        _clipboardService.startMonitoring();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clipboardService.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (ref.read(clipboardMonitoringProvider)) {
        _clipboardService.startMonitoring();
        // Also check clipboard once on resume
        _clipboardService.checkClipboardOnce();
      }
    } else if (state == AppLifecycleState.paused) {
      _clipboardService.stopMonitoring();
    }
  }

  void _onNewUrlDetected(String url) {
    // Check for duplicates
    final linkNotifier = ref.read(linkListProvider.notifier);
    if (linkNotifier.isDuplicate(url)) return;

    final category = LinkCategorizer.categorize(url);
    
    // Auto-save silently to history so it isn't lost if the user dismisses the popup
    final newHistoryLink = LinkModel(
      id: const Uuid().v4(),
      url: url,
      note: UrlUtils.generateAutoNote(url),
      category: category.category,
      domain: UrlUtils.extractDomain(url),
      createdAt: DateTime.now(),
      isFromHistory: true,
      subCategory: category.subCategory,
    );
    linkNotifier.addLink(newHistoryLink);

    setState(() {
      _popupUrl = url;
      _popupCategory = category.category;
    });
  }

  @override
  Widget build(BuildContext context) {
    final folders = ref.watch(folderListProvider);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // ─── Custom Top Bar ─────────────────────────────
                _buildTopBar(context, colors),

                // ─── Folder Grid ────────────────────────────────
                Expanded(
                  child: folders.isEmpty
                      ? _buildEmptyState(context, colors)
                      : _buildFolderGrid(context, folders),
                ),
              ],
            ),

            // ─── Clipboard Popup ──────────────────────────────
            if (_popupUrl != null)
              Positioned(
                top: 0,
                left: 16,
                right: 16,
                child: AnimatedSlide(
                  offset: _popupUrl != null ? Offset.zero : const Offset(0, -1),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  child: ClipboardPopup(
                    url: _popupUrl!,
                    category: _popupCategory,
                    onSave: () => _showSaveLinkSheet(_popupUrl!),
                    onDismiss: _dismissPopup,
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pasteAndSave,
        icon: const Icon(Icons.content_paste_rounded),
        label: const Text('Paste Link'),
      ),
    );
  }

  /// Builds the custom top bar with logo, search, and action buttons.
  Widget _buildTopBar(BuildContext context, ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Column(
        children: [
          Row(
            children: [
              // App logo/icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colors.primary, colors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.link_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 10),
              Text(
                'Link Keeper',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const Spacer(),
              // New folder button
              IconButton(
                tooltip: 'New Folder',
                icon: const Icon(Icons.create_new_folder_rounded),
                onPressed: _createFolder,
              ),
              // History button
              IconButton(
                tooltip: 'History',
                icon: const Icon(Icons.history_rounded),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HistoryScreen()),
                  );
                },
              ),
              // Settings button
              IconButton(
                tooltip: 'Settings',
                icon: const Icon(Icons.settings_rounded),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search bar
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchResultsScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, color: colors.onSurfaceVariant, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Search links, notes, folders...',
                    style: TextStyle(
                      color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the folder grid.
  Widget _buildFolderGrid(BuildContext context, List<dynamic> folders) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.95,
        ),
        itemCount: folders.length,
        itemBuilder: (context, index) {
          final folder = folders[index];
          return FolderCard(
            folder: folder,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FolderDetailScreen(folder: folder),
                ),
              );
            },
            onLongPress: () => _showFolderOptions(folder),
          );
        },
      ),
    );
  }

  /// Builds the empty state when there are no folders.
  Widget _buildEmptyState(BuildContext context, ColorScheme colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colors.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.folder_off_rounded,
                size: 40,
                color: colors.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Folders Yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Copy a link to your clipboard and it will be\nautomatically detected and organized!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _createFolder,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create First Folder'),
            ),
          ],
        ),
      ),
    );
  }

  /// Creates a new folder via dialog.
  Future<void> _createFolder() async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const CreateFolderDialog(),
    );
    if (name != null && name.isNotEmpty) {
      ref.read(folderListProvider.notifier).createFolder(name);
    }
  }

  /// Shows folder edit/delete options.
  void _showFolderOptions(dynamic folder) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.share_rounded),
            title: const Text('Share Folder'),
            onTap: () {
              Navigator.pop(ctx);
              FolderShareService.shareFolder(folder, ref);
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit_rounded),
            title: const Text('Rename'),
            onTap: () async {
              Navigator.pop(ctx);
              final name = await showDialog<String>(
                context: context,
                builder: (_) => CreateFolderDialog(
                  initialName: folder.name,
                  title: 'Rename Folder',
                ),
              );
              if (name != null && name.isNotEmpty) {
                folder.name = name;
                ref.read(folderListProvider.notifier).updateFolder(folder);
              }
            },
          ),
          ListTile(
            leading: Icon(Icons.delete_rounded, color: Theme.of(context).colorScheme.error),
            title: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () async {
              Navigator.pop(ctx);
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Folder'),
                  content: Text(
                    'Delete "${folder.name}" and all its links? This cannot be undone.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                final linkRepo = ref.read(linkRepositoryProvider);
                ref.read(folderListProvider.notifier).deleteFolder(folder.id, linkRepo);
              }
            },
          ),
        ],
      ),
    );
  }

  /// Reads clipboard and opens save dialog.
  Future<void> _pasteAndSave() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final content = data?.text?.trim() ?? '';

      if (content.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Clipboard is empty')),
          );
        }
        return;
      }

      final extractedUrl = UrlUtils.extractFirstValidUrl(content);
      if (extractedUrl == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Clipboard does not contain a valid URL')),
          );
        }
        return;
      }

      _clipboardService.setLastContent(content);
      _showSaveLinkSheet(extractedUrl);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not access clipboard')),
        );
      }
    }
  }

  /// Shows the save link bottom sheet.
  void _showSaveLinkSheet(String url) {
    _dismissPopup();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SaveLinkDialog(url: url),
    );
  }

  void _dismissPopup() {
    setState(() => _popupUrl = null);
  }
}
