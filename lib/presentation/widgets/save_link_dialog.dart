import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/utils/categorizer.dart';
import '../../core/utils/url_utils.dart';
import '../../data/models/link_model.dart';
import '../../providers/providers.dart';
import 'create_folder_dialog.dart';

/// Bottom sheet dialog shown when a new link is detected.
/// Allows the user to add a note, pick a folder, and save.
class SaveLinkDialog extends ConsumerStatefulWidget {
  final String url;

  const SaveLinkDialog({super.key, required this.url});

  @override
  ConsumerState<SaveLinkDialog> createState() => _SaveLinkDialogState();
}

class _SaveLinkDialogState extends ConsumerState<SaveLinkDialog> {
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

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.link_rounded, color: colors.primary),
              const SizedBox(width: 8),
              Text(
                'Save Link',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              // Category badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
          const SizedBox(height: 16),

          // URL display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              widget.url,
              style: TextStyle(
                fontSize: 13,
                color: colors.primary,
                fontFamily: 'monospace',
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 16),

          // Note input
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

          // Folder selector
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
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
                          child: Text('${'  ' * entry.depth}${entry.folder.name}'),
                        )),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedFolderId = value == '_auto_' ? null : value);
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'Create New Folder',
                icon: const Icon(Icons.create_new_folder_rounded),
                onPressed: _createNewFolder,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
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
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded),
                  label: const Text('Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _createNewFolder() async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const CreateFolderDialog(),
    );
    if (name != null && name.trim().isNotEmpty) {
      final folderNotifier = ref.read(folderListProvider.notifier);
      final newFolder = await folderNotifier.createFolder(name.trim());
      if (mounted) {
        setState(() {
          _selectedFolderId = newFolder.id;
        });
      }
    }
  }

  Future<void> _saveLink() async {
    setState(() => _saving = true);

    try {
      final folderNotifier = ref.read(folderListProvider.notifier);
      final linkNotifier = ref.read(linkListProvider.notifier);

      final linkRepo = ref.read(linkRepositoryProvider);
      final existing = linkRepo.findByUrl(widget.url);

      // Check for duplicate (already fully saved)
      if (existing != null && !existing.isFromHistory) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This link is already saved')),
          );
          Navigator.pop(context);
        }
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

          // Create tertiary folder if applicable
          if (_category.tertiaryCategory.isNotEmpty) {
            final tertiaryFolder = await folderNotifier.getOrCreate(
              _category.tertiaryCategory,
              parentId: folderId,
            );
            folderId = tertiaryFolder.id;
          }
        }
      }

      final combinedSubCategory = _category.tertiaryCategory.isNotEmpty 
          ? '${_category.subCategory} / ${_category.tertiaryCategory}' 
          : _category.subCategory;

      // Create the link
      if (existing != null) {
        // It was auto-saved as history, upgrade to a fully saved item
        final updated = existing.copyWith(
          note: _noteController.text.trim(),
          category: _category.category,
          subCategory: combinedSubCategory,
          folderId: folderId,
          isFromHistory: false,
        );
        linkNotifier.updateLink(updated);
      } else {
        // Create new link
        final newLink = LinkModel(
          id: const Uuid().v4(),
          url: widget.url,
          note: _noteController.text.trim(),
          category: _category.category,
          domain: _domain,
          folderId: folderId,
          createdAt: DateTime.now(),
          subCategory: combinedSubCategory,
          isFromHistory: false,
        );
        linkNotifier.addLink(newLink);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Link saved to ${_category.category}'),
            action: SnackBarAction(
              label: 'View',
              onPressed: () {
                // Could navigate to the folder
              },
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving link: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
