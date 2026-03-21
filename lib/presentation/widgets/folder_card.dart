import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/folder_model.dart';
import '../../providers/providers.dart';

/// A card widget representing a folder in the grid.
class FolderCard extends ConsumerWidget {
  final FolderModel folder;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const FolderCard({
    super.key,
    required this.folder,
    required this.onTap,
    this.onLongPress,
  });

  /// Maps icon name strings to actual IconData.
  static IconData _getIcon(String iconName) {
    return switch (iconName) {
      'shopping_bag' => Icons.shopping_bag_rounded,
      'play_circle' => Icons.play_circle_rounded,
      'music_note' => Icons.music_note_rounded,
      'newspaper' => Icons.newspaper_rounded,
      'article' => Icons.article_rounded,
      'code' => Icons.code_rounded,
      'people' => Icons.people_rounded,
      'school' => Icons.school_rounded,
      'account_balance' => Icons.account_balance_rounded,
      'flight' => Icons.flight_rounded,
      'restaurant' => Icons.restaurant_rounded,
      'health_and_safety' => Icons.health_and_safety_rounded,
      _ => Icons.folder_rounded,
    };
  }

  /// Maps icon name strings to colors.
  static Color _getIconColor(String iconName, ColorScheme colors) {
    return switch (iconName) {
      'shopping_bag' => const Color(0xFFE17055),
      'play_circle' => const Color(0xFFFF0000),
      'music_note' => const Color(0xFF1DB954),
      'newspaper' => const Color(0xFF636E72),
      'article' => const Color(0xFF00B894),
      'code' => const Color(0xFF6C5CE7),
      'people' => const Color(0xFF0984E3),
      'school' => const Color(0xFFFDAA5D),
      'account_balance' => const Color(0xFF00B894),
      'flight' => const Color(0xFF74B9FF),
      'restaurant' => const Color(0xFFE17055),
      'health_and_safety' => const Color(0xFFFF7675),
      _ => colors.primary,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linkCount = ref.watch(linkCountInFolderProvider(folder.id));
    final colors = Theme.of(context).colorScheme;
    final iconColor = _getIconColor(folder.iconName, colors);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Folder icon with colored background
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getIcon(folder.iconName),
                  color: iconColor,
                  size: 26,
                ),
              ),
              const SizedBox(height: 12),

              // Folder name
              Text(
                folder.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // Link count
              Text(
                '$linkCount link${linkCount == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              ),
              const Spacer(),

              // Last updated
              Text(
                _formatDate(folder.updatedAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return DateFormat.yMMMd().format(date);
  }
}
