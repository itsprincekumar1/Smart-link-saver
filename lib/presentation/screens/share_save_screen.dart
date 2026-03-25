import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/utils/categorizer.dart';
import '../../core/utils/url_utils.dart';
import '../../data/models/link_model.dart';
import '../../providers/providers.dart';

/// A standalone screen shown when the app is launched via a share intent.
///
/// Displays a centered card dialog over a translucent background.
/// On save or dismiss, returns the user to the app they shared from
/// (e.g. Chrome) using [SystemNavigator.pop].
class ShareSaveScreen extends ConsumerStatefulWidget {
  final String url;

  const ShareSaveScreen({super.key, required this.url});

  @override
  ConsumerState<ShareSaveScreen> createState() => _ShareSaveScreenState();
}

class _ShareSaveScreenState extends ConsumerState<ShareSaveScreen> {
  late final TextEditingController _noteController;
  late final CategoryResult _category;
  late final String _domain;
  String? _selectedFolderId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _domain = UrlUtils.extractDomain(widget.url);
    _category = LinkCategorizer.categorize(widget.url);
    _noteController = TextEditingController(
      text: UrlUtils.generateAutoNote(widget.url),
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final allFolderEntries = ref.watch(allFoldersProvider);

    return Scaffold(
      backgroundColor: Colors.black54,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 12,
              shadowColor: colors.primary.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── Header ──────────────────────
                    Row(
                      children: [
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
                          child: const Icon(Icons.link_rounded,
                              color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Save Link',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        // Category badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: colors.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _category.toString(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: colors.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ─── URL display ─────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        widget.url,
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.primary,
                          fontFamily: 'monospace',
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ─── Note input ──────────────────
                    TextField(
                      controller: _noteController,
                      decoration: const InputDecoration(
                        labelText: 'Note',
                        hintText: 'Add a note for this link...',
                        prefixIcon: Icon(Icons.note_rounded),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),

                    // ─── Folder selector ─────────────
                    DropdownButtonFormField<String>(
                      initialValue: _selectedFolderId ?? '_auto_',
                      decoration: const InputDecoration(
                        labelText: 'Save to folder',
                        prefixIcon: Icon(Icons.folder_rounded),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: '_auto_',
                          child: Text('Auto-create folder'),
                        ),
                        ...allFolderEntries.map((entry) => DropdownMenuItem(
                              value: entry.folder.id,
                              child: Text(
                                  '${'  ' * entry.depth}${entry.folder.name}'),
                            )),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedFolderId =
                            value == '_auto_' ? null : value);
                      },
                    ),
                    const SizedBox(height: 24),

                    // ─── Action buttons ──────────────
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _dismiss,
                            child: const Text('Dismiss'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: FilledButton.icon(
                            onPressed: _saving ? null : _saveLink,
                            icon: _saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.save_rounded),
                            label: const Text('Save'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveLink() async {
    setState(() => _saving = true);

    try {
      final folderNotifier = ref.read(folderListProvider.notifier);
      final linkNotifier = ref.read(linkListProvider.notifier);

      // Check for duplicate
      if (linkNotifier.isDuplicate(widget.url)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This link is already saved')),
          );
        }
        // Small delay so user sees the snackbar, then exit
        await Future.delayed(const Duration(milliseconds: 800));
        _exitToSourceApp();
        return;
      }

      // Determine folder
      String folderId;
      if (_selectedFolderId != null) {
        folderId = _selectedFolderId!;
      } else {
        // Auto-create folder based on category
        final folder = await folderNotifier.getOrCreate(
          _category.category,
          iconName: LinkCategorizer.iconForCategory(_category.category),
        );
        folderId = folder.id;

        // Create subfolder if applicable
        if (_category.subCategory.isNotEmpty) {
          final subFolder = await folderNotifier.getOrCreate(
            _category.subCategory,
            parentId: folderId,
          );
          folderId = subFolder.id;
        }
      }

      // Create the link
      final note = _noteController.text.trim().isEmpty
          ? UrlUtils.generateAutoNote(widget.url)
          : _noteController.text.trim();

      final link = LinkModel(
        id: const Uuid().v4(),
        url: widget.url,
        note: note,
        category: _category.category,
        domain: _domain,
        folderId: folderId,
        createdAt: DateTime.now(),
        subCategory: _category.subCategory,
      );

      await linkNotifier.addLink(link);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Link saved to ${_category.category}'),
            duration: const Duration(milliseconds: 1200),
          ),
        );
      }

      // Brief delay so user sees confirmation, then return to source app
      await Future.delayed(const Duration(milliseconds: 800));
      _exitToSourceApp();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving link: $e')),
        );
        setState(() => _saving = false);
      }
    }
  }

  void _dismiss() {
    _exitToSourceApp();
  }

  /// Returns to the app the user shared from (e.g. Chrome).
  void _exitToSourceApp() {
    // If this screen was pushed onto an existing navigator, pop it.
    // Otherwise (cold start), use SystemNavigator to go back.
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      SystemNavigator.pop();
    }
  }
}
