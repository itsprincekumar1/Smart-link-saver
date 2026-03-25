import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../data/models/folder_model.dart';
import '../data/models/link_model.dart';
import '../providers/providers.dart';

/// Service to handle extracting and formatting a folder's entire contents for outward sharing.
class FolderShareService {
  FolderShareService._();

  /// Recursively collects all links within a [folder] and shares them as formatted text.
  static Future<void> shareFolder(FolderModel folder, WidgetRef ref) async {
    final linkRepo = ref.read(linkRepositoryProvider);
    final folderRepo = ref.read(folderRepositoryProvider);

    final List<LinkModel> allLinks = [];

    // Recursive helper to grab all links inside subfolders
    void collectLinks(String folderId) {
      allLinks.addAll(linkRepo.getLinksByFolder(folderId));
      for (final sub in folderRepo.getSubfolders(folderId)) {
        collectLinks(sub.id);
      }
    }

    collectLinks(folder.id);

    // If there's nothing to share, fail silently (UI can optionally check before calling this)
    if (allLinks.isEmpty) {
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln('📁 ${folder.name}');
    buffer.writeln('-------------------');
    buffer.writeln();

    for (final link in allLinks) {
      // Prefer the user's note or generated title, fallback to the raw domain if empty
      final title = link.note.isNotEmpty ? link.note.trim() : link.domain;
      
      buffer.writeln('• $title');
      buffer.writeln('  ${link.url}');
      buffer.writeln();
    }

    // Share the formatted text to standard OS sheet
    await Share.share(
      buffer.toString().trim(),
      subject: '${folder.name} Links'
    );
  }
}
