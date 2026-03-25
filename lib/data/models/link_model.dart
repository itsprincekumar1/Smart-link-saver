import 'package:hive/hive.dart';

part 'link_model.g.dart';

/// Hive model for a saved link.
@HiveType(typeId: 0)
class LinkModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String url;

  @HiveField(2)
  String note;

  @HiveField(3)
  final String category;

  @HiveField(4)
  final String domain;

  @HiveField(5)
  String? folderId;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  bool isFromHistory;

  @HiveField(8)
  final String subCategory;

  @HiveField(9)
  String? imageUrl;

  LinkModel({
    required this.id,
    required this.url,
    required this.note,
    required this.category,
    required this.domain,
    this.folderId,
    required this.createdAt,
    this.isFromHistory = false,
    this.subCategory = '',
    this.imageUrl,
  });

  /// Creates a copy with optional field overrides.
  LinkModel copyWith({
    String? id,
    String? url,
    String? note,
    String? category,
    String? domain,
    String? folderId,
    DateTime? createdAt,
    bool? isFromHistory,
    String? subCategory,
    String? imageUrl,
  }) {
    return LinkModel(
      id: id ?? this.id,
      url: url ?? this.url,
      note: note ?? this.note,
      category: category ?? this.category,
      domain: domain ?? this.domain,
      folderId: folderId ?? this.folderId,
      createdAt: createdAt ?? this.createdAt,
      isFromHistory: isFromHistory ?? this.isFromHistory,
      subCategory: subCategory ?? this.subCategory,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  /// Serializes to JSON map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'url': url,
        'note': note,
        'category': category,
        'domain': domain,
        'folderId': folderId,
        'createdAt': createdAt.toIso8601String(),
        'isFromHistory': isFromHistory,
        'subCategory': subCategory,
        'imageUrl': imageUrl,
      };

  /// Deserializes from JSON map.
  factory LinkModel.fromJson(Map<String, dynamic> json) => LinkModel(
        id: json['id'] as String,
        url: json['url'] as String,
        note: json['note'] as String? ?? '',
        category: json['category'] as String? ?? 'General',
        domain: json['domain'] as String? ?? '',
        folderId: json['folderId'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        isFromHistory: json['isFromHistory'] as bool? ?? false,
        subCategory: json['subCategory'] as String? ?? '',
        imageUrl: json['imageUrl'] as String?,
      );
}
