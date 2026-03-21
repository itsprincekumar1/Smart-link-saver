import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants.dart';
import '../../core/utils/categorizer.dart';
import '../models/folder_model.dart';

/// Repository for CRUD operations on folders using Hive.
class FolderRepository {
  late Box<FolderModel> _box;
  final _uuid = const Uuid();

  /// Initializes the repository by opening the Hive box.
  Future<void> init() async {
    _box = await Hive.openBox<FolderModel>(AppConstants.foldersBox);
  }

  /// Returns all top-level folders (no parent), ordered by name.
  List<FolderModel> getAllFolders() {
    final folders = _box.values
        .where((f) => f.parentId == null)
        .toList();
    folders.sort((a, b) => a.name.compareTo(b.name));
    return folders;
  }

  /// Returns subfolders of a given parent folder.
  List<FolderModel> getSubfolders(String parentId) {
    final folders = _box.values
        .where((f) => f.parentId == parentId)
        .toList();
    folders.sort((a, b) => a.name.compareTo(b.name));
    return folders;
  }

  /// Returns a folder by its ID.
  FolderModel? getFolderById(String id) {
    return _box.get(id);
  }

  /// Finds a folder by name (case-insensitive), optionally within a parent.
  FolderModel? findByName(String name, {String? parentId}) {
    try {
      return _box.values.firstWhere(
        (f) =>
            f.name.toLowerCase() == name.toLowerCase() &&
            f.parentId == parentId,
      );
    } catch (_) {
      return null;
    }
  }

  /// Gets or creates a folder by name. If it doesn't exist, creates it.
  /// Returns the folder.
  Future<FolderModel> getOrCreate(
    String name, {
    String? parentId,
    String? iconName,
  }) async {
    final existing = findByName(name, parentId: parentId);
    if (existing != null) {
      // Update the timestamp
      existing.updatedAt = DateTime.now();
      await existing.save();
      return existing;
    }

    final now = DateTime.now();
    final folder = FolderModel(
      id: _uuid.v4(),
      name: name,
      parentId: parentId,
      createdAt: now,
      updatedAt: now,
      iconName: iconName ?? LinkCategorizer.iconForCategory(name),
    );
    await _box.put(folder.id, folder);
    return folder;
  }

  /// Creates a new folder.
  Future<FolderModel> createFolder({
    required String name,
    String? parentId,
    String iconName = 'folder',
  }) async {
    final now = DateTime.now();
    final folder = FolderModel(
      id: _uuid.v4(),
      name: name,
      parentId: parentId,
      createdAt: now,
      updatedAt: now,
      iconName: iconName,
    );
    await _box.put(folder.id, folder);
    return folder;
  }

  /// Updates a folder.
  Future<void> updateFolder(FolderModel folder) async {
    folder.updatedAt = DateTime.now();
    await _box.put(folder.id, folder);
  }

  /// Deletes a folder and all its subfolders.
  Future<List<String>> deleteFolder(String id) async {
    final deletedIds = <String>[id];

    // Recursively collect subfolder IDs
    void collectSubfolders(String parentId) {
      final subs = _box.values.where((f) => f.parentId == parentId);
      for (final sub in subs) {
        deletedIds.add(sub.id);
        collectSubfolders(sub.id);
      }
    }

    collectSubfolders(id);

    // Delete all collected folders
    for (final folderId in deletedIds) {
      await _box.delete(folderId);
    }

    return deletedIds;
  }

  /// Returns all folders as a list (for export).
  List<Map<String, dynamic>> exportAll() {
    return _box.values.map((folder) => folder.toJson()).toList();
  }

  /// Imports folders from JSON list.
  Future<int> importAll(List<dynamic> jsonList) async {
    int count = 0;
    for (final json in jsonList) {
      try {
        final folder = FolderModel.fromJson(json as Map<String, dynamic>);
        if (_box.get(folder.id) == null) {
          await _box.put(folder.id, folder);
          count++;
        }
      } catch (_) {
        // Skip invalid entries
      }
    }
    return count;
  }
}
