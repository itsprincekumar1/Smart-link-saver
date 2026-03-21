import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/link_model.dart';
import '../data/models/folder_model.dart';
import '../data/repositories/link_repository.dart';
import '../data/repositories/folder_repository.dart';
import '../core/utils/search_utils.dart';

// ─── Repository Providers ────────────────────────────────────────────────────

/// Provides access to the [LinkRepository] singleton.
final linkRepositoryProvider = Provider<LinkRepository>((ref) {
  return LinkRepository();
});

/// Provides access to the [FolderRepository] singleton.
final folderRepositoryProvider = Provider<FolderRepository>((ref) {
  return FolderRepository();
});

// ─── Folder Providers ────────────────────────────────────────────────────────

/// Notifier that manages the list of all top-level folders.
class FolderListNotifier extends StateNotifier<List<FolderModel>> {
  final FolderRepository _repo;

  FolderListNotifier(this._repo) : super([]) {
    refresh();
  }

  void refresh() {
    state = _repo.getAllFolders();
  }

  Future<FolderModel> createFolder(String name, {String? parentId, String iconName = 'folder'}) async {
    final folder = await _repo.createFolder(
      name: name,
      parentId: parentId,
      iconName: iconName,
    );
    refresh();
    return folder;
  }

  Future<void> updateFolder(FolderModel folder) async {
    await _repo.updateFolder(folder);
    refresh();
  }

  Future<void> deleteFolder(String id, LinkRepository linkRepo) async {
    final deletedIds = await _repo.deleteFolder(id);
    // Delete links in all deleted folders
    for (final folderId in deletedIds) {
      await linkRepo.deleteLinksByFolder(folderId);
    }
    refresh();
  }

  Future<FolderModel> getOrCreate(String name, {String? parentId, String? iconName}) async {
    final folder = await _repo.getOrCreate(name, parentId: parentId, iconName: iconName);
    refresh();
    return folder;
  }

  List<FolderModel> getSubfolders(String parentId) {
    return _repo.getSubfolders(parentId);
  }
}

final folderListProvider =
    StateNotifierProvider<FolderListNotifier, List<FolderModel>>((ref) {
  final repo = ref.watch(folderRepositoryProvider);
  return FolderListNotifier(repo);
});

/// Provider for subfolders of a specific parent.
final subfoldersProvider = Provider.family<List<FolderModel>, String>((ref, parentId) {
  // Re-read when folder list changes
  ref.watch(folderListProvider);
  final repo = ref.watch(folderRepositoryProvider);
  return repo.getSubfolders(parentId);
});

// ─── Link Providers ──────────────────────────────────────────────────────────

/// Notifier that manages links for the whole app.
class LinkListNotifier extends StateNotifier<List<LinkModel>> {
  final LinkRepository _repo;

  LinkListNotifier(this._repo) : super([]) {
    refresh();
  }

  void refresh() {
    state = _repo.getAllLinks();
  }

  Future<void> addLink(LinkModel link) async {
    await _repo.addLink(link);
    refresh();
  }

  Future<void> updateLink(LinkModel link) async {
    await _repo.updateLink(link);
    refresh();
  }

  Future<void> deleteLink(String id) async {
    await _repo.deleteLink(id);
    refresh();
  }

  bool isDuplicate(String url) => _repo.isDuplicate(url);

  LinkModel? findByUrl(String url) => _repo.findByUrl(url);
}

final linkListProvider =
    StateNotifierProvider<LinkListNotifier, List<LinkModel>>((ref) {
  final repo = ref.watch(linkRepositoryProvider);
  return LinkListNotifier(repo);
});

/// Provider for links in a specific folder.
final linksInFolderProvider = Provider.family<List<LinkModel>, String>((ref, folderId) {
  final allLinks = ref.watch(linkListProvider);
  return allLinks.where((link) => link.folderId == folderId).toList();
});

/// Provider for link count in a folder.
final linkCountInFolderProvider = Provider.family<int, String>((ref, folderId) {
  return ref.watch(linksInFolderProvider(folderId)).length;
});

/// Provider for history links.
final historyLinksProvider = Provider<List<LinkModel>>((ref) {
  final allLinks = ref.watch(linkListProvider);
  return allLinks.where((link) => link.isFromHistory).toList();
});

// ─── Search Providers ────────────────────────────────────────────────────────

/// Holds the current search query.
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Provides search results using fuzzy matching.
final searchResultsProvider = Provider<List<LinkModel>>((ref) {
  final query = ref.watch(searchQueryProvider);
  final allLinks = ref.watch(linkListProvider);

  if (query.trim().isEmpty) return [];

  return SearchUtils.fuzzySearch<LinkModel>(
    query: query,
    items: allLinks,
    textExtractor: (link) => [
      link.url,
      link.note,
      link.category,
      link.domain,
      link.subCategory,
    ],
  );
});

// ─── Clipboard State ─────────────────────────────────────────────────────────

/// Holds the last detected URL from clipboard.
final detectedUrlProvider = StateProvider<String?>((ref) => null);

/// Whether clipboard monitoring is enabled.
final clipboardMonitoringProvider = StateProvider<bool>((ref) => true);
