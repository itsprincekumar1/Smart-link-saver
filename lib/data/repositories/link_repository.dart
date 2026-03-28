import 'package:hive/hive.dart';
import '../../core/constants.dart';
import '../models/link_model.dart';

/// Repository for CRUD operations on links using Hive.
class LinkRepository {
  late Box<LinkModel> _box;

  /// Initializes the repository by opening the Hive box.
  Future<void> init() async {
    _box = await Hive.openBox<LinkModel>(AppConstants.linksBox);
  }

  /// Returns all links, ordered by creation date (newest first).
  List<LinkModel> getAllLinks() {
    final links = _box.values.toList();
    links.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return links;
  }

  /// Returns links belonging to a specific folder.
  List<LinkModel> getLinksByFolder(String folderId) {
    final links = _box.values
        .where((link) => link.folderId == folderId)
        .toList();
    links.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return links;
  }

  /// Returns links marked as history (not saved to any folder yet).
  List<LinkModel> getHistoryLinks() {
    final links = _box.values
        .where((link) => link.isFromHistory)
        .toList();
    links.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return links;
  }

  /// Counts links in a specific folder.
  int getLinkCountByFolder(String folderId) {
    return _box.values
        .where((link) => link.folderId == folderId)
        .length;
  }

  /// Checks if a URL already exists in the database.
  bool isDuplicate(String url) {
    return _box.values.any((link) => link.url == url);
  }

  /// Returns the existing link if the URL already exists.
  LinkModel? findByUrl(String url) {
    try {
      return _box.values.firstWhere((link) => link.url == url);
    } catch (_) {
      return null;
    }
  }

  /// Adds a new link.
  Future<void> addLink(LinkModel link) async {
    await _box.put(link.id, link);
  }

  /// Updates an existing link.
  Future<void> updateLink(LinkModel link) async {
    await _box.put(link.id, link);
  }

  /// Deletes a link by its ID.
  Future<void> deleteLink(String id) async {
    await _box.delete(id);
  }

  /// Deletes all links belonging to a folder.
  Future<void> deleteLinksByFolder(String folderId) async {
    final keys = _box.values
        .where((link) => link.folderId == folderId)
        .map((link) => link.id)
        .toList();
    for (final key in keys) {
      await _box.delete(key);
    }
  }

  /// Searches links by query across URL, note, and category.
  List<LinkModel> searchLinks(String query) {
    if (query.trim().isEmpty) return getAllLinks();
    final q = query.toLowerCase();
    final results = _box.values.where((link) {
      return link.url.toLowerCase().contains(q) ||
          link.note.toLowerCase().contains(q) ||
          link.category.toLowerCase().contains(q) ||
          link.domain.toLowerCase().contains(q);
    }).toList();
    results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return results;
  }

  /// Clears all history links.
  Future<void> clearHistory() async {
    final historyLinks = _box.values
        .where((link) => link.isVisibleInHistory)
        .toList();
    for (final link in historyLinks) {
      if (link.folderId == null) {
        await _box.delete(link.id);
      } else {
        final updated = link.copyWith(isVisibleInHistory: false);
        await _box.put(link.id, updated);
      }
    }
  }

  /// Returns all links as a list (for export).
  List<Map<String, dynamic>> exportAll() {
    return _box.values.map((link) => link.toJson()).toList();
  }

  /// Imports links from JSON list.
  Future<int> importAll(List<dynamic> jsonList) async {
    int count = 0;
    for (final json in jsonList) {
      try {
        final link = LinkModel.fromJson(json as Map<String, dynamic>);
        if (!isDuplicate(link.url)) {
          await _box.put(link.id, link);
          count++;
        }
      } catch (_) {
        // Skip invalid entries
      }
    }
    return count;
  }
}
