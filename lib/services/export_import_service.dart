import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../data/repositories/link_repository.dart';
import '../data/repositories/folder_repository.dart';

/// Service for exporting and importing app data as JSON.
class ExportImportService {
  final LinkRepository linkRepository;
  final FolderRepository folderRepository;

  ExportImportService({
    required this.linkRepository,
    required this.folderRepository,
  });

  /// Exports all data to a JSON file and returns the file path.
  Future<String> exportData() async {
    final data = {
      'appName': 'Smart Link Keeper',
      'exportDate': DateTime.now().toIso8601String(),
      'version': '1.0',
      'folders': folderRepository.exportAll(),
      'links': linkRepository.exportAll(),
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(data);
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${directory.path}/smart_link_keeper_backup_$timestamp.json');
    await file.writeAsString(jsonString);

    return file.path;
  }

  /// Imports data from a JSON string. Returns a summary of imported items.
  Future<ImportResult> importData(String jsonString) async {
    try {
      final data = json.decode(jsonString) as Map<String, dynamic>;

      int foldersImported = 0;
      int linksImported = 0;

      // Import folders first (so links can reference them)
      if (data.containsKey('folders')) {
        foldersImported = await folderRepository.importAll(
          data['folders'] as List<dynamic>,
        );
      }

      // Import links
      if (data.containsKey('links')) {
        linksImported = await linkRepository.importAll(
          data['links'] as List<dynamic>,
        );
      }

      return ImportResult(
        success: true,
        foldersImported: foldersImported,
        linksImported: linksImported,
      );
    } catch (e) {
      return ImportResult(
        success: false,
        error: e.toString(),
      );
    }
  }
}

/// Result of an import operation.
class ImportResult {
  final bool success;
  final int foldersImported;
  final int linksImported;
  final String? error;

  const ImportResult({
    required this.success,
    this.foldersImported = 0,
    this.linksImported = 0,
    this.error,
  });
}
