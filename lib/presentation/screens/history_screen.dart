import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/link_model.dart';
import '../../providers/providers.dart';
import '../widgets/link_tile.dart';
import '../widgets/save_link_dialog.dart';

/// Screen showing recently detected clipboard links (history).
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyLinks = ref.watch(historyLinksProvider);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          if (historyLinks.isNotEmpty)
            IconButton(
              tooltip: 'Clear History',
              icon: const Icon(Icons.delete_sweep_rounded),
              onPressed: () => _clearHistory(context, ref),
            ),
        ],
      ),
      body: historyLinks.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 48,
                    color: colors.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No link history yet',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Detected links will appear here',
                    style: TextStyle(
                      color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: historyLinks.length,
              itemBuilder: (context, index) {
                final link = historyLinks[index];
                return LinkTile(
                  link: link,
                  onDelete: () {
                    ref.read(linkListProvider.notifier).deleteLink(link.id);
                  },
                  onSaveToFolder: () {
                    _saveToFolder(context, ref, link);
                  },
                  onEdit: () => _editNote(context, ref, link),
                );
              },
            ),
    );
  }

  Future<void> _clearHistory(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Delete all history links?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final linkRepo = ref.read(linkRepositoryProvider);
      await linkRepo.clearHistory();
      ref.read(linkListProvider.notifier).refresh();
    }
  }

  void _saveToFolder(BuildContext context, WidgetRef ref, LinkModel link) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SaveLinkDialog(url: link.url),
    ).then((saved) {
      if (saved == true) {
        // Remove from history once saved to a folder
        ref.read(linkListProvider.notifier).deleteLink(link.id);
      }
    });
  }

  Future<void> _editNote(
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
          decoration: const InputDecoration(hintText: 'Enter a note...'),
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
}
