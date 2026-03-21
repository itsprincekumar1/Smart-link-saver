import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../services/export_import_service.dart';

/// Settings screen with export/import and app preferences.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMonitoring = ref.watch(clipboardMonitoringProvider);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // ─── Clipboard Section ────────────────────
          _SectionHeader(title: 'Clipboard'),
          SwitchListTile(
            title: const Text('Clipboard Monitoring'),
            subtitle: const Text(
              'Automatically detect links from clipboard while app is open',
            ),
            value: isMonitoring,
            onChanged: (value) {
              ref.read(clipboardMonitoringProvider.notifier).state = value;
            },
          ),
          const Divider(),

          // ─── Data Section ─────────────────────────
          _SectionHeader(title: 'Data'),
          ListTile(
            leading: const Icon(Icons.upload_rounded),
            title: const Text('Export Data'),
            subtitle: const Text('Save all links and folders as JSON'),
            onTap: () => _exportData(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.download_rounded),
            title: const Text('Import Data'),
            subtitle: const Text('Restore from a JSON backup file'),
            onTap: () => _importData(context, ref),
          ),
          const Divider(),

          // ─── About Section ────────────────────────
          _SectionHeader(title: 'About'),
          ListTile(
            leading: Container(
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
            title: const Text('Smart Link Keeper'),
            subtitle: const Text('Version 1.0.0'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Automatically capture, organize, and retrieve links intelligently.',
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    try {
      final service = ExportImportService(
        linkRepository: ref.read(linkRepositoryProvider),
        folderRepository: ref.read(folderRepositoryProvider),
      );
      final path = await service.exportData();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Data exported to:\n$path'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _importData(BuildContext context, WidgetRef ref) async {
    try {
      // Use a simple file picker approach - read from a known path
      // For a full implementation, you'd use file_picker package
      final controller = TextEditingController();
      final jsonString = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Import Data'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Paste the contents of your backup JSON file below:',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 8,
                decoration: const InputDecoration(
                  hintText: 'Paste JSON here...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text('Import'),
            ),
          ],
        ),
      );
      controller.dispose();

      if (jsonString == null || jsonString.trim().isEmpty) return;

      final service = ExportImportService(
        linkRepository: ref.read(linkRepositoryProvider),
        folderRepository: ref.read(folderRepositoryProvider),
      );

      final result = await service.importData(jsonString);

      // Refresh providers
      ref.read(folderListProvider.notifier).refresh();
      ref.read(linkListProvider.notifier).refresh();

      if (context.mounted) {
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Imported ${result.foldersImported} folders and ${result.linksImported} links',
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Import failed: ${result.error}')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import error: $e')),
        );
      }
    }
  }
}

/// Simple section header widget.
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
