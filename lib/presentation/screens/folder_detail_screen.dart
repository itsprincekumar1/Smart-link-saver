import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/folder_model.dart';
import '../../data/models/link_model.dart';
import '../../providers/providers.dart';
import '../widgets/link_tile.dart';
import '../widgets/create_folder_dialog.dart';

/// Screen showing all links inside a specific folder.
class FolderDetailScreen extends ConsumerWidget {
  final FolderModel folder;

  const FolderDetailScreen({super.key, required this.folder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final links = ref.watch(linksInFolderProvider(folder.id));
    final subfolders = ref.watch(subfoldersProvider(folder.id));
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(folder.name),
        actions: [
          // Add subfolder
          IconButton(
            tooltip: 'Add Subfolder',
            icon: const Icon(Icons.create_new_folder_rounded),
            onPressed: () => _createSubfolder(context, ref),
          ),
          // Folder options
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'rename':
                  _renameFolder(context, ref);
                case 'delete':
                  _deleteFolder(context, ref);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'rename', child: Text('Rename')),
              const PopupMenuItem(value: 'delete', child: Text('Delete Folder')),
            ],
          ),
        ],
      ),
      body: (links.isEmpty && subfolders.isEmpty)
          ? _buildEmptyState(context, colors)
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Subfolders section
                if (subfolders.isNotEmpty) ...[
                  Text(
                    'Subfolders',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  ...subfolders.map((sub) => Card(
                        child: ListTile(
                          leading: Icon(Icons.folder_rounded, color: colors.primary),
                          title: Text(sub.name),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FolderDetailScreen(folder: sub),
                              ),
                            );
                          },
                        ),
                      )),
                  const SizedBox(height: 16),
                ],

                // Links section
                if (links.isNotEmpty) ...[
                  Text(
                    'Links (${links.length})',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  ...links.map((link) => LinkTile(
                        link: link,
                        onEdit: () => _editLinkNote(context, ref, link),
                        onDelete: () =>
                            ref.read(linkListProvider.notifier).deleteLink(link.id),
                        onMove: () => _moveLink(context, ref, link),
                      )),
                ],
              ],
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ColorScheme colors) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.link_off_rounded,
            size: 48,
            color: colors.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            'No links in this folder',
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Future<void> _createSubfolder(BuildContext context, WidgetRef ref) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const CreateFolderDialog(title: 'Create Subfolder'),
    );
    if (name != null && name.isNotEmpty) {
      ref.read(folderListProvider.notifier).createFolder(
            name,
            parentId: folder.id,
          );
    }
  }

  Future<void> _renameFolder(BuildContext context, WidgetRef ref) async {
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
  }

  Future<void> _deleteFolder(BuildContext context, WidgetRef ref) async {
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
    if (confirm == true && context.mounted) {
      final linkRepo = ref.read(linkRepositoryProvider);
      ref.read(folderListProvider.notifier).deleteFolder(folder.id, linkRepo);
      Navigator.pop(context);
    }
  }

  Future<void> _editLinkNote(
    BuildContext context,
    WidgetRef ref,
    LinkModel link,
  ) async {
    final controller = TextEditingController(text: link.note);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Note'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter a note...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (result != null) {
      final updated = link.copyWith(note: result);
      ref.read(linkListProvider.notifier).updateLink(updated);
    }
  }

  Future<void> _moveLink(
    BuildContext context,
    WidgetRef ref,
    LinkModel link,
  ) async {
    final folders = ref.read(folderListProvider);
    final selectedFolderId = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Move to Folder'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: folders.length,
            itemBuilder: (_, index) {
              final f = folders[index];
              return ListTile(
                leading: const Icon(Icons.folder_rounded),
                title: Text(f.name),
                selected: f.id == link.folderId,
                onTap: () => Navigator.pop(ctx, f.id),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedFolderId != null && selectedFolderId != link.folderId) {
      final updated = link.copyWith(folderId: selectedFolderId);
      ref.read(linkListProvider.notifier).updateLink(updated);
    }
  }
}
